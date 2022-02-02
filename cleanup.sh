#/bin/bash

cd state || exit
rm -rf .terraform
rm terraform.tfstate
rm terraform.tfstate.backup

cd ../network || exit
rm -rf .terraform