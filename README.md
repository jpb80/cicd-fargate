# Docker image build pipeline

A docker container build pipeline that builds
the image with AWS CodeBuild and deploys the image to AWS ECR. 

## Setup Requirements:
* AWS account credentials configured in `~/.aws/credentials`
* Python 3.7 installed - python3 used to create venv
* Docker installed

## Configure:
* Manually update the `Makefile` variables `AWS_ACCOUNTID`, `AWS_REGION` to be set to the desired AWS account defined in `~/.aws/credentials`.

## Install:
* `make init` creates python virtualenv, downloads dependencies, and creates an admin role in the AWS account.
* `make install` Deploys all stacks in the AWS account and uploads zipped greeting-app sourcecode to s3.

## Build:
* `make build` initiates a CodeBuild job for the greeting-app sourcecode in the CodeCommit repository. Then the new image is pushed to ECR.

## Run container:
* `make run-local` pulls the latest image from ECR then initiates docker to run the container. The greeting-app server is running on port 5000.


## Greeting App API
- Greeting message 
    * URL: localhost:5000/ 
    * METHOD: GET 
    * RESPONSE: '{"message": "Hello world!"}' 

- App healthcheck
    * URL: localhost:5000/health
    * METHOD: GET 
    * RESPONSE: '{"status": "OK"}'


## Tear down of AWS infrastructure
* Manually delete the cloudformation stacks in the following order: codebuild, codecommit, ecr,
storage, and then cloudformation stack. Some stacks will require 
deleting the resources such as s3 bucket with files in it. 
* Manually delete the admin role.


## Future
* Automate teardown of Cloudformation stacks and resources. 
* TBD

## FAQs

1. I cannot provide create-role or attach-policy IAM permissions to my AWS account user. >From within the AWS GUI console manually create the IAM role `admin-cfn-full` and then attach `AdministratorAccess` policy to the role.

2. Why does Cloudformation require AdministratoAaccess? >Cloudformation requires a role to deploy the stack resources. 
