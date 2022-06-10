#!/bin/bash
LIGHTBLUE='\033[1;34m'
NO_COLOUR='\033[0m'

echo "Please specify a prefix to prepend on terraform files and aws resources: "
read PROJECT_PREFIX

echo "Please specify the AWS region you would like your app to reside in, e.g. us-east-2: "
read REGION

if [[ "$OSTYPE" == "darwin"* ]]; then
    # Insert project prefix and AWS region into state terraform file
    sed -i '' 's/{{PROJECT_PREFIX}}/'$PROJECT_PREFIX'/g' terraform/state/main.tf
    sed -i '' 's/{{AWS_REGION}}/'$REGION'/g' terraform/state/main.tf

    # Insert project prefix and AWS region into network terraform file
    sed -i '' 's/{{PROJECT_PREFIX}}/'$PROJECT_PREFIX'/g' terraform/network/main.tf
    sed -i '' 's/{{AWS_REGION}}/'$REGION'/g' terraform/network/main.tf
else
    # Insert project prefix and AWS region into state terraform file
    sed -i 's/{{PROJECT_PREFIX}}/'$PROJECT_PREFIX'/g' terraform/state/main.tf
    sed -i 's/{{AWS_REGION}}/'$REGION'/g' terraform/state/main.tf

    # Insert project prefix and AWS region into network terraform file
    sed -i 's/{{PROJECT_PREFIX}}/'$PROJECT_PREFIX'/g' terraform/network/main.tf
    sed -i 's/{{AWS_REGION}}/'$REGION'/g' terraform/network/main.tf
fi

echo -e "${LIGHTBLUE}"
echo "=============================================================="
echo "| Creating S3 bucket and Dynamo DB table for terraform state |"
echo "=============================================================="
echo -e "${NO_COLOUR}"

cd terraform/state || exit
terraform init
terraform apply -auto-approve

# Uncomment terraform block in state main.tf file
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/#//g' main.tf
else
    sed -i 's/#//g' main.tf
fi

echo -e "${LIGHTBLUE}"
echo "=========================================="
echo "| Migrating terraform state to S3 bucket |"
echo "=========================================="
echo -e "${NO_COLOUR}"

#read -p 'PRESS ANY KEY'
terraform init -force-copy

echo -e "${LIGHTBLUE}"
echo "================"
echo "| Creating VPC |"
echo "================"
echo -e "${NO_COLOUR}"

cd ../network || exit
terraform init
terraform apply -auto-approve
