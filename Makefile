export SHELL := /bin/bash

INFRA=infrastructure
TEMPLATE=template.yaml

AWS_ACCOUNTID=289782891060
AWS_REGION=us-east-1
IMAGE_REPO=greeting-app
CFN_TRUST_ROLENAME=admin-cfn-full

HELP_REGEX:=^(.+): .*\#\# (.*)

CACHE_DIR := .cache
.PHONY: help
help: ## Show this help message.
	@echo 'Usage:'
	@echo '  make [target] ...'
	@echo
	@echo 'Targets:'
	@egrep "$(HELP_REGEX)" Makefile | sed -E "s/$(HELP_REGEX)/  \1 # \2/" | column -t -c 2 -s '#'

.PHONY: init
init:
	python3 -m venv venv; \
	. venv/bin/activate; \
	pip3 install -r requirements.txt; \
	aws iam create-role --role-name admin-cfn-full --assume-role-policy-document file://admin-cfn-role-policy.json; \
	aws iam attach-role-policy --role-name admin-cfn-full --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

.PHONY: deploy-stack-cfn
deploy-stack-cfn:
	. venv/bin/activate; \
	cfn-lint ${INFRA}/cloudformation/${TEMPLATE}; \
	aws cloudformation deploy \
		--template-file ${INFRA}/cloudformation/${TEMPLATE} \
		--stack-name cloudformation \
		--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
		--role-arn arn:aws:iam::${AWS_ACCOUNTID}:role/admin-cfn-full

.PHONY: deploy-stack-storage
deploy-stack-storage:
	. venv/bin/activate; \
	cfn-lint ${INFRA}/storage/${TEMPLATE}; \
	aws cloudformation deploy \
		--template-file ${INFRA}/storage/${TEMPLATE} \
		--stack-name storage \
		--capabilities CAPABILITY_IAM \
		--s3-bucket cfn-template-${AWS_ACCOUNTID}-${AWS_REGION} \
		--role-arn arn:aws:iam::${AWS_ACCOUNTID}:role/cfn-deploy-stacks

.PHONY: deploy-stack-ecr
deploy-stack-ecr:
	. venv/bin/activate; \
	cfn-lint ${INFRA}/ecr/${TEMPLATE}; \
	aws cloudformation deploy \
		--template-file ${INFRA}/ecr/${TEMPLATE} \
		--stack-name ecr \
		--capabilities CAPABILITY_IAM \
		--s3-bucket cfn-template-${AWS_ACCOUNTID}-${AWS_REGION} \
		--role-arn arn:aws:iam::${AWS_ACCOUNTID}:role/cfn-deploy-stacks

.PHONY: deploy-stack-ccommit
deploy-stack-ccommit:
	. venv/bin/activate; \
	cfn-lint ${INFRA}/codecommit/${TEMPLATE}; \
	aws cloudformation deploy \
		--template-file ${INFRA}/codecommit/${TEMPLATE} \
		--stack-name codecommit \
		--capabilities CAPABILITY_IAM \
		--s3-bucket cfn-template-${AWS_ACCOUNTID}-${AWS_REGION} \
		--role-arn arn:aws:iam::${AWS_ACCOUNTID}:role/cfn-deploy-stacks

.PHONY: deploy-stack-cbuild
deploy-stack-cbuild:
	. venv/bin/activate; \
	cfn-lint ${INFRA}/codebuild/${TEMPLATE}; \
	aws cloudformation deploy \
		--template-file ${INFRA}/codebuild/${TEMPLATE} \
		--stack-name codebuild \
		--capabilities CAPABILITY_IAM \
		--s3-bucket cfn-template-${AWS_ACCOUNTID}-${AWS_REGION} \
		--role-arn arn:aws:iam::${AWS_ACCOUNTID}:role/cfn-deploy-stacks

.PHONY: deploy-stack-fargate
deploy-stack-fargate:
	. venv/bin/activate; \
	cfn-lint ${INFRA}/fargate/${TEMPLATE}; \
	aws cloudformation deploy \
		--template-file ${INFRA}/fargate/${TEMPLATE} \
		--stack-name fargate \
		--parameter-overrides EcrImageName=greeting-app, App=greeting-app \
		--capabilities CAPABILITY_IAM \
		--s3-bucket cfn-template-${AWS_ACCOUNTID}-${AWS_REGION} \
		--role-arn arn:aws:iam::${AWS_ACCOUNTID}:role/cfn-deploy-stacks

.PHONY: deploy-stack-network
deploy-stack-network:
	. venv/bin/activate; \
	cfn-lint ${INFRA}/network/${TEMPLATE}; \
	aws cloudformation deploy \
		--template-file ${INFRA}/network/${TEMPLATE} \
		--stack-name network \
		--capabilities CAPABILITY_IAM \
		--s3-bucket cfn-template-${AWS_ACCOUNTID}-${AWS_REGION} \
		--role-arn arn:aws:iam::${AWS_ACCOUNTID}:role/cfn-deploy-stacks


.PHONY: deploy-all-stacks # deploy all stacks
deploy-all-stacks: deploy-stack-cfn deploy-stack-storage deploy-stack-ecr deploy-stack-ccommit deploy-stack-cbuild deploy-stack-network deploy-stack-fargate

.PHONY: run-codebuild
run-codebuild:
	. venv/bin/activate; \
	aws codebuild start-build --project-name codebuild

.PHONY: ecr-pull-latest
ecr-pull-latest:
	. venv/bin/activate; \
	$$(aws ecr get-login --region ${AWS_REGION} --no-include-email); \
	docker pull ${AWS_ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_REPO}:latest

.PHONY: run-container
run-container:
	. venv/bin/activate; \
	docker run -it -d -p5000:5000 ${AWS_ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_REPO}:latest

.PHONY: install
install: deploy-all-stacks

.PHONY: build
build: run-codebuild

.PHONY: run-local
deploy: ecr-pull-latest run-container

.PHONY: delete-admin-role
delete_admin_role:
	. venv/bin/activate; \
	aws iam detach-role-policy --role-name admin-cfn-full --policy-arn arn:aws:iam::aws:policy/AdministratorAccess; \
	aws iam delete-role --role-name admin-cfn-full
