#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-077769cfadde11fb1"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z04486643GN3RHKI6IXZK"
DOMAIN_NAME="devopspract.site"

#for instance in ${INSTANCES[@]}; do
for instance in $@
do
    #to get the instance id
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-077769cfadde11fb1 --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)

    if [ $instance != "frontend" ]; then #query private if not frontend
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
        #Example: RECORD_NAME=monngodb.devopspract.site
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        #query public ip the instance created is frontend
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        #As frontend is publicily accessible, devopspract.site
        RECORD_NAME=$DOMAIN_NAME
    fi
    echo "$instance ip address: $IP"

    #create/update A record sets
    aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch '
    {
        "Comment": "Creating or Updating a record set for cognito endpoint"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }'

done
