##############################################################
# Bastion Host AZ A
##############################################################
module "globals" {
  source = "../globals"
}

#TODO: Security Group is very open - needs tightening
resource "aws_security_group" "allow_bastion_db_access" {
  name        = "allow_bastion_db_access"
  description = "Allow SSH tunneling to Databases via Bastion host"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.db_cidr_blocks
  }
}

resource "aws_instance" "bastion_host" {
  ami                         = "ami-0be057a22c63962cb"
  instance_type               = "t2.micro"
  key_name                    = "${lower(var.environment)}-bastion-key"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.allow_bastion_db_access.id]
  associate_public_ip_address = true

  tags = {
    Name        = "SCALE-EU2-${upper(var.environment)}-EC2-BASTION"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "EC2"
  }
}
