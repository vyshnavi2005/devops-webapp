terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "web_sg" {
  name        = "devops-webapp-sg"
  description = "Security group for DevOps web application"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  vpc_security_group_ids = [
    aws_security_group.web_sg.id
  ]
  user_data = <<-EOF
            #!/bin/bash

            apt-get update -y

            # Install Docker
            apt-get install -y docker.io

            systemctl enable docker
            systemctl start docker

            usermod -aG docker ubuntu

            # Install AWS Systems Manager Agent
            snap install amazon-ssm-agent --classic
            systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
            systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
            EOF

  tags = {
    Name = "DevOps-WebApp-Server"
  }
}