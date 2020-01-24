# Ian Manifold Coding Exercise
author: Ian Myjer

# Deployment

## Setup
These instructions assume the following tools are installed on the machine performing the deployment:

  - `aws-cli`    
  - `terraform` version v0.11.11     
  - `bash`      

The `awscli` must also be configured with [user credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html#cli-quick-configuration). Terraform is currently assuming the "default" credentials will be used. This can be changed in the `terraform/vars.tf` file:
```terraform
variable "profile" {
  default = "default"
}
```
If a newer version of `terraform` is being used, the following line must be changed in `terraform/lambda_api.tf`
```terraform
# version 0.11.11 or older 
source_code_hash = "${base64sha256(file("../lambda.zip"))}"

# version 0.11.12 or newer
source_code_hash = "${filebase64sha256("../lambda.zip")}"
```


## REST API Deploy

The REST API can be deployed using the following code:
```bash
git clone git@github.com:enmyj/imyjer_manifold.git && cd imyjer_manifold
bash deploy.sh
```
Note: This deployment creates an AWS S3 bucket. Since buckets must have globally unique names, the bucket name may need to be changed in `terraform/vars.tf`: 
```terraform
variable "data_bucket" {
  default = "imyjer-manifold-data"
}
```

If deployment worked correctly, the restapi url should have printed to the terminal: 

```bash
base_url = https://XXXXXXXX.execute-api.us-east-1.amazonaws.com/prod
```

## REST API Test

The REST API can be tested using a GUI such as Postman, or from the command line using `curl`. Please ensure "v1.0" is appended to the restapi path. 

```bash
curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"first_name":"Bernie","last_name":"Sanders"}' \
    https://XXXXXXX.execute-api.us-east-1.amazonaws.com/prod/v1.0
```

## Rest API Data Query
Once `deploy.sh` has been run successfully and a few POST requests have been made to the REST API, the data can be queried through AWS Athena by pointing to database name: `imyjer-manifold-db` and table name: `manifold_table`


# Ian's Thoughts/Comments

### Improvements

For a proper client deployment, a few things I would likely improve are:

1. Networking - building an AWS VPC would be an important security measure for a client deployment
2. API keys - would improve the client's ability to manage users and enforce api security
3. API domain name or static IP Address - would ensure the API URL doesn't change
4. Testing/staging infrastructure - would allow us to test our infrastructure prior to production deployment
5. Handle Nested JSON data (details below)

### Handle JSON data
Per the coding challenge specifications, clients might desire the flexibility to pass top-level or nested JSON to the REST API. One simple idea to handle both types of data might be to use path or query parameters on the url that point to different handling functions. Another idea might be to ask the client to pass the data with a person's id at the top-level (even if the `id` number is a meaningless unique identifier). For example: 
```json
{
  "001": {
    "first_name": "Ian",
    "last_name": "Myjer"
  },
  "002": {
    "first_name": "Andrew",
    "last_name": "Yang",
    "zip_code": "92320"
  }
}
```
This way, if the JSON contains an `id` in the top-level key, we will know it's nested. Otherwise, we can assume it's top-level. While this approach might require the client to modify how they make requests to the API, I believe it would be easier to maintain long-term.    

Another potential approach might be to use a python function like `pandas.io.json.json_normalize` to flatten arbitrarily nested data. Then, we could parse through the column names to intuit the structure of the JSON. While this approach would be more flexible, I believe it would be harder to maintain long-term. 

### Python/Lambda

Since this REST API had relatively simple requirements, I was able to use only packages from python's standard library. However, a more complicated REST API might require external packages such as `pandas` or `s3fs`. To use external packages with AWS Lambda, I would have needed to include a virtual python environment inside the `lambda.zip` file.

I attempted this briefly and found that it added complexity to the deployment. The `zip` file including all the python packages was much larger in size. My method for deployment with a zip file of ~50 MB was to use the following flow: use `terraform` to create s3 buckets --> use `bash` and `aws-cli` to create zip and upload to s3 --> use `terraform` to create Lambda, API Gateway, and Glue resources. Furthermore, for large `zip` files, the AWS Lambda web interface no longer shows the online python file editor, which made debugging difficult. Finally, the python virtual environment must be created using the same python version as the AWS Lambda python runtime, which could cause confusion for development if not well documented. 

### AWS Glue Partitions

I was able to create an AWS Glue Crawler and Table with partitions based on the JSON data in S3 using the AWS web interface. Unfortunately, however, I was not able to replicate this using `terraform`. When I added the `partition_keys` parameter to the AWS Glue Table configuration in `terraform`, the Glue Table wouldn't find partitions and therefore would not return any data.    
To maintain the timestamp filtering functionality, I added a timestamp field to the json files in S3

### Tool Considerations

I found integrating and debugging AWS Lambda, the python code for AWS Lambda, AWS API Gateway, and `terraform` to be pretty tricky. As someone who is relatively new to AWS, I suspect there tools and tricks that I am not aware of that would have made this easier. However, during testing of my deployment I felt that the variety of tools added complexity which made it harder to nail down exactly what was failing and why.   

For similar deployments in the future, I might also consider: 

  - `zappa`
  - `fastapi` (python)
  - `docker`

I deployed a side-project `flask` application using `zappa` and found it simple to understand and easy to use. However, `terraform` offers much more flexibility than `zappa`. For this project, I would have had to use `terraform` for S3 buckets, `zappa` for python/lambda/api gateway, and `terraform` again for AWS Glue. I suspect this would be confusing and hard to maintain in the future.    

I like `fastapi` because it offers the following features (among others): auto-creation of `swagger` documentation for the API, awesome technical documentation, easy to use and deploy with `conda`, and simple path/query/body parameter configuration and validation. I believe `fastapi` could be deployed to AWS Lambda/AWS API Gateway using a similar approach to my current approach, but with `fastapi` handling the the path/query/body parsing. AWS Elastic Beanstalk also looks like a good a good option, although it seems like the cost would be higher than AWS Lambda/API Gateway. It would be interesting to compare a project that uses `terraform`, AWS Lambda, AWS API Gateway, and `fastapi` with my approach on this project.   

I like `docker` because it's super easy to work with locally, is well documented, and it behaves essentially the same when moved to a server. AWS offers a number of services for deploying `docker` containers, but the simplest seems to be AWS Fargate, Elastic Beanstalk, and Elastic Container Service (ECS). Factors I would consider in selecting one of these services include: availability of serverlessness, control of infrastructure, ease of use (especially with terraform), latency, and cost. 


# References:
https://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html#python-package-prereqs

https://rogerwelin.github.io/aws/serverless/terraform/lambda/2019/03/18/build-a-serverless-website-from-scratch-with-lambda-and-terraform.html

https://stackoverflow.com/questions/55129035/terraform-aws-athena-to-use-glue-catalog-as-db
