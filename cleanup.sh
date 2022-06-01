#!/bin/bash
LIGHTBLUE='\033[1;34m'
NO_COLOUR='\033[0m'

echo -e "${LIGHTBLUE}"
echo "==========================================="
echo "| Destroying VPC and networking resources |"
echo "==========================================="
echo -e "${NO_COLOUR}"

cd terraform/network || exit
terraform destroy -auto-approve
rm -rf .terraform

echo -e "${LIGHTBLUE}"
echo "=============================================="
echo "| Migrating terraform state from s3 to local |"
echo "=============================================="
echo -e "${NO_COLOUR}"

cd ../state || exit
# Comment out s3 backend configuration
sed -i '1,11 s/./#&/' main.tf
terraform init -force-copy

echo -e "${LIGHTBLUE}"
echo "==========================================="
echo "| Destroying s3 bucket and DynamoDB table |"
echo "==========================================="
echo -e "${NO_COLOUR}"

terraform destroy

rm -rf .terraform
rm terraform.tfstate
rm terraform.tfstate.backup
