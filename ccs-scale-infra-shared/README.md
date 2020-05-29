# ccs-scale-infra-shared

## SCALE Shared Infrastructure Provisioning

### Overview
This sub-project builds the next level on infrastructure on top of `ccs-scale-infra-network`. It is a separate set of Terraform scripts (a) to reduce the blast radius of anything going wrong as we need to protect the EIPs in the network layer, and (b) having explicit input variables, rather than references allows use of more advanced Terraform feature like loops which helps reduce duplication in this code leading to more maintainable, less error prone code.

This project will provision:

- API Gateway (no methods yet - they are added in later scripts - see repo level README)
- Network Load Balancers (private & public)
- VPC Link
- VPC Endpoints
- Internet Gateway
- NAT Gateway
- Network Access Control Lists



