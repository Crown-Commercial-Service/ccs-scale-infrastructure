# ccs-scale-infra-shared

## SCALE Shared Infrastructure Provisioning

### Overview
This sub-project builds the next level of infrastructure on top of `ccs-scale-infra-network`. It is a separate set of Terraform scripts (a) to reduce the blast radius of anything going wrong as we need to protect the EIPs in the network layer, and (b) having explicit input variables, rather than references allows use of more advanced Terraform feature like loops which helps reduce duplication in this code leading to more maintainable, less error prone code.

This project will provision:

- Network Load Balancers (private & public)
- VPC Link
- VPC Endpoints
- Internet Gateway
- NAT Gateway
- Network Access Control Lists


### Bastion Host
The Bastion Host EC2 instance provisioned in this project can be used tunnel SSH connections to access the Postgres Databases.

1. You will need the pem file for the EC2 key pair - the key must match the name `{environment}-bastion-key`, e.g. `sbx1-bastion-key`.

2. You can then open a terminal and make the tunnel connection:
```
ssh -i {ENVIRONMENT}-bastion-key.pem -L 5432:{POSTGRES_DB_ENDPOINT}:5432 ubuntu@{EC2_PUBLIC_IP}
```

3. You can then access the database as if it were on localhost on your own machine
