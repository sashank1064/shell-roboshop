#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0644345eb3c89c13e"
INSTANCES=("mongodb" "rabbitmq" "mysql" "redis" "catalogue" "user" "cart" "shipping"
             "payment" "dispatch" "frontend")
ZONE_ID="Z05717891IWFXUBM74UFS"
DOMAIN_NAME="daws84s.pro"

for instance in ${INSTANCES[@]}
do 

done





aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP \
  --subnet-id $SUBNET_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME}]"

  #!/bin/bash

aws ec2 run-instances \
  --image-id ami-09c813fb71547fc4f \
  --instance-type t2.micro \
  --security-group-ids sg-0644345eb3c89c13e \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=my-ec2}]'
