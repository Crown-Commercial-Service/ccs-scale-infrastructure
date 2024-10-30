#########################################################
# Bastion Host
#
# To allow SSH tunneling to Aurora databases.
#########################################################
module "globals" {
  source = "../globals"
}

resource "aws_security_group" "allow_bastion_db_access" {
  name        = "allow_bastion_db_access"
  description = "Allow SSH tunneling to Databases via Bastion host"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks_allowed_external
    description = ""
  }

  # Ansible Tower
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ansible_tower_cidr_block
    description = "Ansible Tower"
  }

  # Jumar VPN
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.jumar_vpn_cidr_block
    description = "Jumar VPN"
  }

  # For connection to Postgres and Neo4j
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.db_cidr_blocks
  }

  egress {
    from_port   = 7687
    to_port     = 7687
    protocol    = "tcp"
    cidr_blocks = var.db_cidr_blocks
  }

  # For OS updates etc
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "init" {
  template = file("${path.module}/init.sh")
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "bastion_host" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = "${lower(var.environment)}-bastion-key"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.allow_bastion_db_access.id]
  associate_public_ip_address = true
  user_data                   = data.template_file.init.rendered

  root_block_device {
    encrypted  = true
    kms_key_id = var.bastion_kms_key_id
  }

  tags = {
    Name        = "SCALE-EU2-${upper(var.environment)}-EC2-BASTION"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "EC2"
  }
}
