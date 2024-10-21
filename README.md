# Project Structure

The following text is an explanation of how [gkutsarov.com](https://gkutsarov.com) is configured and hosted.

# Note

**Default VPC is sufficient** - AWS provides a default VPC in each region, which comes with subnets, an internet gateway, and security groups already configured. For a simple project like hosting a website on EC2 with Apache, the default VPC offers everything you need for public internet access and security without requiring custom configurations.

**Cost Savings** - Creating a custom VPC can introduce additional services that incur costs, such as NAT gateways or VPC peering, which aren’t necessary for a small-scale project. By sticking with the default VPC, you avoid these extra costs and keep your infrastructure simple.

**High Availability** - can be done by configuring Auto Scaling Groups to ensure availability even if traffic grows.

**Load Balance** - Easily can be implemented by integrating Elastic Load Balancer (ELB) which distributes traffic across multiple EC2 instances.

# [0] Overview

The project uses GitHub Actions. Provision, Configure, changes to the website content is controlled by GitHub Actions.

# [1] Provision Infrastructure

00-Provision Infra.yml which uses **infrastructure/main.tf**

Terraform is used to provision the infrastructure of the project. Used to provision the following:
- EC2
- Security Groups
- S3 Bucket
- SSH Key Pair (used for Ansible configuration) in which the **private key** is stored as a GitHub secret



# [2] Ansible Server Configuration

01-Ansible Config.yml which uses ansible/playbook.yml

Ansible playbook is used to install essential packages to the EC2 instance and also to install apache webserver. It also creates a config file for the webpage and custom repo where webpage content will be stored. 

The Github action takes 2 inputs - ip address of the EC2 instance and a security group created in the previous step to allow the SSH connection from the GitHub Runner.

It installs ansible on the runner, make permission changes to the private key, get the runner IP address and adds it to the security group of the EC2 responsible for the SSH connection, 

- Installs Ansible on the GitHub runner
- Permission changes to the private key
- Gets and adds the IP of the Github runner to the inbound SG for SSH traffic of the EC2
- Takes the 1st input of the action (IP address of the EC2) and creates Ansible inventory file with it along with the SSH key.

# [3] Website Initial Initialization 

02-Website Initial Init.yml

Initial initialization action follows the same logic of requiring two inputs - IP address and SG to allow SSH connectivity to the EC2 from the GitHub runner.

It's copying using scp the contents of **website** repo to the **var/www/gkutsarov** on the EC2 instance.

# [4] Continious Deployment

03-Continious Website Deploy.yml

When a change is made to any file in the **website** repo and then pushed to GitHub the action activates.

It copies the modified files and uploads them to the **var/www/gkutsarov** on the EC2 instance from where the website content is served.

# [5] Destroy Infrastructure

99-Destroy Infra.yml

Used to destroy the whole infrastructure - EC2, SGs, S3 and etc.






