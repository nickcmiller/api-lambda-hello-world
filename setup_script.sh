#!/bin/bash

# Install dependencies
pip3 install -r requirements.txt

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> .env
# echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> .env
# echo "AWS_REGION=$AWS_REGION" >> .env
