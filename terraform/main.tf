resource "aws_instance" "ubuntu_ec2" {
  ami                         = "ami-053b0d53c279acc90" # Ubuntu 22.04 in us-east-1
  instance_type               = "t3.medium"
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
