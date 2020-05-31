# ccs-scale-infrastructure

## SCALE Infrastructure Project

### Overview
This repository contains a complete set of configuration files and code to provision the underlying network and shared infrastructure for the SCALE system into the AWS cloud.  The infrastructure code is written in [Terraform](https://www.terraform.io/). This project contains the following 2 standalone sub-projects

 - [ccs-scale-infra-network](ccs-scale-infra-network)- VPC, subnets, EIPs
 - [ccs-scale-infra-shared](ccs-scale-infra-shared) - API Gateway, Load Balancers, VPC Links, etc

These are separate projects to decouple them and avoid the chance of any changes in `ccs-scale-infra-shared` affecting `ccs-scale-infra-network`. Having them as separate components reduces the blast radius of anything going wrong, and also allows us of Terraform loops in the `ccs-scale-infra-shared` code, making the code much more streamlined and maintainable (for building across different AZs in different environments).

This code underpins the higher level stream specific (FaT, BaT, CaT, Shared) services which will build on top of it. These need to be executed on top of this infrastructure code - and can be found in the following repositories. Each of these can be provisioned independently after the basic infrastructure has been deployed:

- [ccs-scale-infra-services-shared](https://github.com/Crown-Commercial-Service/ccs-scale-infra-services-shared)
    - Agreements service provisioning in Fargate
- [ccs-scale-infra-services-fat](https://github.com/Crown-Commercial-Service/ccs-scale-infra-services-fat)
    - Guided Match, Decisition Tree and Lookup services provisioning in Fargate
- [ccs-scale-infra-services-bat](https://github.com/Crown-Commercial-Service/ccs-scale-infra-services-bat)
    - TDB
- [ccs-scale-infra-db-shared](https://github.com/Crown-Commercial-Service/ccs-scale-infra-db-shared)
    - Agreements service Aurora Postgres database provisioning
- [ccs-scale-infra-db-fat](https://github.com/Crown-Commercial-Service/ccs-scale-infra-db-fat)
    - Guided Match, Decisition Tree and Lookup services Aurora Postgres database provisioning in Fargate
- [ccs-scale-infra-db-bat](https://github.com/Crown-Commercial-Service/ccs-scale-infra-db-bat)
    - TBD


### Prerequisites

#### AWS
- An AWS account that has been created by TechOps in the Management account, and added to a group that has sufficient privileges to provision the necessary architecture in your chosen environment. See the SCALE [AWS Environments](https://crowncommercialservice.atlassian.net/wiki/spaces/SCALE/pages/63930385/AWS+Environments) page in Confluence for more information.

#### Terraform
- Note: these instructions are only necessary if you want to provision from your local machine. CodeBuild projects will exist in the AWS Management account to provision these automatically.
- Install Terraform (v.0.12+)

### Provision Network (ccs-scale-infra-network) in AWS

1. Change directories to the environment you are provisioning, within the project you:

        $ cd $GIT_HOME/ccs-scale-infrastructure/ccs-scale-infra-network/terraform/environments/{environment}

2. Initialize Terraform:

        $ terraform init

3. Provision infrastructure:

        $ terraform apply --auto-approve

4. Output variables will persisted in SSM Parameter Store for use in subsequent scripts


### Provision Shared Infrastructure (ccs-scale-infra-shared) in AWS

1. Change directories to the environment you are provisioning, within the project you :

        $ cd $GIT_HOME/ccs-scale-infrastructure/ccs-scale-infra-shared/terraform/environments/{environment}

2. Initialize Terraform:

        $ terraform init

3. Provision infrastructure:

        $ terraform apply --auto-approve

4. Output variables will persisted in SSM Parameter Store for use in subsequent scripts