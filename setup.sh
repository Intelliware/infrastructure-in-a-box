#/bin/bash
LIGHTBLUE='\033[1;34m'
NO_COLOUR='\033[0m'

echo "Please specify a prefix to prepend on terraform files and aws resources: "
read PROJECT_PREFIX

echo "Please specify the AWS region you would like your app to reside in, e.g. us-east-2: "
read REGION

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/{{PROJECT_PREFIX}}/'$PROJECT_PREFIX'/g' state/main.tf
    sed -i '' 's/{{AWS_REGION}}/'$REGION'/g' state/main.tf
else
    sed -i 's/{{PROJECT_PREFIX}}/'$PROJECT_PREFIX'/g' state/main.tf
    sed -i 's/{{AWS_REGION}}/'$REGION'/g' state/main.tf
fi


echo -e "${LIGHTBLUE}"
echo "=============================================================="
echo "| Creating S3 bucket and Dynamo DB table for terraform state |"
echo "=============================================================="
echo -e "${NO_COLOUR}"

cd state || exit
terraform init
terraform apply -auto-approve

sed -i 's/#//g' main.tf

echo -e "${LIGHTBLUE}"
echo "=========================================="
echo "| Migrating terraform state to S3 bucket |"
echo "=========================================="
echo -e "${NO_COLOUR}"

#read -p 'PRESS ANY KEY'
terraform init -force-copy