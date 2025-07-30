provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------
# Auto-generate SSH Key Pair for EC2
# ---------------------------------------
resource "tls_private_key" "auto_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "auto_keypair" {
  key_name   = "ubuntu-devops-key"
  public_key = tls_private_key.auto_key.public_key_openssh
}

output "private_key_pem" {
  value     = tls_private_key.auto_key.private_key_pem
  sensitive = true
}

# ---------------------------------------
# Security Group with all required ports
# ---------------------------------------
resource "aws_security_group" "devops_sg" {
  name        = "ubuntu-devops-sg"
  description = "Allow DevOps ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9323
    to_port     = 9323
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

# ---------------------------------------
# Ubuntu EC2 Instance with Java 21, Jenkins, Docker
# ---------------------------------------
resource "aws_instance" "ubuntu_ec2" {
  ami                         = "ami-0fc5d935ebf8bc3bc" # Ubuntu 22.04 in us-east-1
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.auto_keypair.key_name
  vpc_security_group_ids      = [aws_security_group.devops_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y wget gnupg curl unzip

              # Install Java 21 (OpenJDK)
              add-apt-repository ppa:openjdk-r/ppa -y
              apt-get update
              apt-get install -y openjdk-21-jdk

              # Set JAVA_HOME
              echo 'export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))' >> /etc/profile
              echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
              source /etc/profile

              # Install Docker
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
              chmod 777 /var/run/docker.sock

              # Install Jenkins
              curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | tee \
                /usr/share/keyrings/jenkins-keyring.asc > /dev/null
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                https://pkg.jenkins.io/debian binary/ | tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null

              apt-get update
              apt-get install -y jenkins
              systemctl enable jenkins
              systemctl start jenkins
              EOF

  tags = {
    Name = "Ubuntu-DevOps-Server"
  }
}
