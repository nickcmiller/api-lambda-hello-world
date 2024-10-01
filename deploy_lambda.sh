#!/bin/bash

# Navigate to the lambda directory
cd lambda

# Zip the lambda function
zip -r lambda_function.zip lambda_function.py

# Navigate back to the parent directory
cd ..

# Apply Terraform
terraform apply -auto-approve