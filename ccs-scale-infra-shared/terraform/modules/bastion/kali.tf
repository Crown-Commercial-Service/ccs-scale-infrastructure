resource "aws_instance" "kali" {
  count = var.kali_instance ? 1 : 0

  ami                         = "ami-0794045bcaf370ece"
  instance_type               = var.kali_instance_type
  key_name                    = "${lower(var.environment)}-kali-key"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.allow_bastion_db_access.id]
  associate_public_ip_address = true

  root_block_device {
    encrypted   = true
    kms_key_id  = var.bastion_kms_key_id
    volume_size = 70
  }

  tags = {
    Name        = "SCALE-EU2-${upper(var.environment)}-EC2-KALI-PEN-TEST"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "EC2"
  }
}