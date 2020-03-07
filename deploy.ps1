#!/usr/bin/env bash

### Manifold - Rest API ###
# author: Ian Myjer

# init and apply terraform code
cd terraform
terraform init 
terraform apply -auto-approve
