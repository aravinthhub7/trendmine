provider "aws" {
  region = "us-east-1"
}

# Generate SSH key pair
resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.jenkins_key.private_key_pem
  filename        = "${path.module}/jenkins_key.pem"
  file_permission = "0600"
}

# Create AWS key pair from the generated public key
resource "aws_key_pair" "auto_keypair" {
  key_name   = "jenkins-key"
  public_key = tls_private_key.jenkins_key.public_key_openssh
}

# Create a security group for SSH and HTTP access
resource "aws_security_group" "Final" {
  name        = "jenkins-sg"
  description = "Allow SSH and HTTP access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
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

# Launch EC2 instance
resource "aws_instance" "BuildEC2" {
  ami                    = "ami-053b0d53c279acc90"  # Ubuntu 22.04 LTS (us-east-1)
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.auto_keypair.key_name
  vpc_security_group_ids = [aws_security_group.Final.id]

  tags = {
    Name = "Build Server"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y openjdk-21-jdk
              sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian/jenkins.io-2023.key
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get update
              sudo apt-get install -y jenkins docker.io
              sudo systemctl start jenkins
              sudo systemctl enable jenkins
              sudo usermod -aG docker jenkins
              sudo chmod 777 /var/run/docker.sock
              EOF
}
