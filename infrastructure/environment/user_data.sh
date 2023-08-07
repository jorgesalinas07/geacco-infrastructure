# Make sure we have all the latest updates when we launch this instance
sudo apt update

# Install postgresql
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql.service

# Install docker
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt install docker-ce

# Connect to db
sudo -u postgres psql -h geaccodbstg.ciutmnlgyney.us-east-1.rds.amazonaws.com -p 5432 -d geacco_db_stg -U geaccousername -W
# #! /bin/bash
# set -e
# # Ouput all log
# exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
# # Make sure we have all the latest updates when we launch this instance
# yum update -y && yum upgrade -y
# # Install components
# yum install -y docker amazon-ecr-credential-helper
# # Add credential helper to pull from ECR
# mkdir -p ~/.docker && chmod 0700 ~/.docker
# echo '{"credsStore": "ecr-login"}' > ~/.docker/config.json
# # Start docker now and enable auto start on boot
# service docker start && chkconfig docker on
# # Allow the ec2-user to run docker commands without sudo
# usermod -a -G docker ec2-user
# # Run application at start
# docker run --restart=always -d -p 80:5000 388813176377.dkr.ecr.us-east-1.amazonaws.com/geacco_app_stg:latest
