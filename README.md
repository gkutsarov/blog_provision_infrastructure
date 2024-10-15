# Project Structure

The following text is an explanation of how [gkutsarov.com](https://gkutsarov.com) is configured and hosted.

# [0] Overview

The project uses GitHub Actions. Provision, Configure, changes to the website content is controlled by GitHub Actions.

# [1] Provision Infrastructure

00-Provision Infra.yml which uses **infrastructure/main.tf**

Terraform is used to provision the infrastructure of the project. Used to provision the following:
- EC2
- Security Groups
- S3 Bucket
- SSH Key Pair (used for Ansible configuration) in which the **private key** is stored as a GitHub secred



# [2] Ansible Server Configuration

01-Ansible Config.yml

Ansible playbook is used to install essential packages to the EC2 instance and also to install apache webserver. It also creates a config file for the webpage and custome repo where webpage content will be stored. 

The Github action takes 2 inputs - ip address of the EC2 instance and a security group created in the previous step to allow the SSH connection from the GitHub Runner.

It installs ansible on the runner, make permission changes to the private key, get the runner IP address and adds it to the security group of the EC2 responsible for the SSH connection, 

- Installs Ansible on the GitHub runner
- Permission changes to the private key
- Gets and adds the IP of the Github runner to the inbound SG for SSH traffic of the EC2
- Takes the 1st input of the action(IP address of the EC2) and creates Ansible inventory file with it along with the SSH key.




