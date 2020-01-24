#!/usr/bin/env bash

### Manifold - Rest API ###
# author: Ian Myjer

# zip up python code for deployment
zip -j lambda.zip pylambda/lambda_to_s3_nopandas.py

# init and apply terraform code
cd terraform
terraform init 
terraform apply -auto-approve
