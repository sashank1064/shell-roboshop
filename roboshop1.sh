# #!/bin/bash

# -----------------------------
# Configurable variables
# -----------------------------
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0644345eb3c89c13e"          # Replace with your SG ID
ZONE_ID="Z05717891IWFXUBM74UFS"       # Replace with your Hosted Zone ID
DOMAIN_NAME="daws84s.pro"             # Replace with your domain

INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

# -----------------------------
# Pre-checks
# -----------------------------
command -v aws >/dev/null 2>&1 || { 
    echo >&2 "AWS CLI is not installed. Please install it first."; 
    exit 1; 
}

aws sts get-caller-identity >/dev/null 2>&1 || {
    echo >&2 "AWS CLI credentials not configured. Run 'aws configure'."
    exit 1
}

# -----------------------------
# Launch instances
# -----------------------------
for instance in "$@"; do
    echo "Launching instance: $instance ..."
    
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    echo "Instance ID: $INSTANCE_ID"

    # Wait until instance is running
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
    echo "Instance $instance is running."

    # Get IP
    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance IP address: $IP"

    # Update Route53
    CHANGE_JSON=$(cat <<EOF
{
  "Comment": "Creating or Updating a record set for $instance",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          { "Value": "$IP" }
        ]
      }
    }
  ]
}
EOF
)

    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "$CHANGE_JSON"

    echo "Route53 record updated: $RECORD_NAME -> $IP"
    echo "--------------------------------------------"
done
