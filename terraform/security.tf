locals {
  ssh_port     = 22
  http_port    = 80
  backend_port = 8080
}

# ---------- ALB ----------

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb"
  description = "Public entry point; HTTP/HTTPS from the internet"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Name = "${var.project}-alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_in" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from anywhere"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = local.http_port
  to_port     = local.http_port
}

# Disabled until we can have a domain
resource "aws_vpc_security_group_ingress_rule" "alb_https_in" {
  count = var.enable_https ? 1 : 0

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from anywhere"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_to_frontend" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP to the frontend instances only"

  referenced_security_group_id = aws_security_group.frontend.id
  ip_protocol                  = "tcp"
  from_port                    = local.http_port
  to_port                      = local.http_port
}

# ---------- Bastion ----------

resource "aws_security_group" "bastion" {
  name        = "${var.project}-bastion"
  description = "Jump host; SSH from the admin IP only"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Name = "${var.project}-bastion"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_in" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from the admin IP"

  # validated against 0.0.0.0/0 in variables.tf
  cidr_ipv4   = var.admin_cidr
  ip_protocol = "tcp"
  from_port   = local.ssh_port
  to_port     = local.ssh_port
}

resource "aws_vpc_security_group_egress_rule" "bastion_out" {
  security_group_id = aws_security_group.bastion.id
  description       = "All outbound: SSH to the VMs, package mirrors, DNS"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# ---------- Frontend ----------

resource "aws_security_group" "frontend" {
  name        = "${var.project}-frontend"
  description = "Web tier; HTTP from the ALB, SSH from the bastion"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Name = "${var.project}-frontend"
  }
}

resource "aws_vpc_security_group_ingress_rule" "frontend_http_from_alb" {
  security_group_id = aws_security_group.frontend.id
  description       = "HTTP from the ALB, including health checks"

  # Group reference, not a CIDR: survives any ALB IP change.
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = local.http_port
  to_port                      = local.http_port
}

resource "aws_vpc_security_group_ingress_rule" "frontend_ssh_from_bastion" {
  security_group_id = aws_security_group.frontend.id
  description       = "SSH from the bastion only"

  referenced_security_group_id = aws_security_group.bastion.id
  ip_protocol                  = "tcp"
  from_port                    = local.ssh_port
  to_port                      = local.ssh_port
}

resource "aws_vpc_security_group_egress_rule" "frontend_out" {
  security_group_id = aws_security_group.frontend.id
  description       = "All outbound via the NAT gateway"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# ---------- Backend ----------

resource "aws_security_group" "backend" {
  name        = "${var.project}-backend"
  description = "App tier; reachable from the frontend and the bastion only"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Name = "${var.project}-backend"
  }
}

resource "aws_vpc_security_group_ingress_rule" "backend_app_from_frontend" {
  security_group_id = aws_security_group.backend.id
  description       = "App port from the frontend instances"

  referenced_security_group_id = aws_security_group.frontend.id
  ip_protocol                  = "tcp"
  from_port                    = local.backend_port
  to_port                      = local.backend_port
}

resource "aws_vpc_security_group_ingress_rule" "backend_ssh_from_bastion" {
  security_group_id = aws_security_group.backend.id
  description       = "SSH from the bastion only"

  referenced_security_group_id = aws_security_group.bastion.id
  ip_protocol                  = "tcp"
  from_port                    = local.ssh_port
  to_port                      = local.ssh_port
}

resource "aws_vpc_security_group_egress_rule" "backend_out" {
  security_group_id = aws_security_group.backend.id
  description       = "All outbound via the NAT gateway"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}
