# Terraform to create aws resource for highly available web app and DB setup
Creating a highly available web application across two Availability Zones (AZs) on AWS with a MySQL database and an Application Load Balancer (ALB) using Terraform involves several steps. Here's a high-level overview of the architecture:
``
#### Note:

This configuration provides a highly available web application using AWS resources and Terraform, distributing traffic across two Availability Zones and a MySQL RDS database in Multi-AZ mode for redundancy. Adjust the configuration according to your specific requirements and security needs.
``
### Installation Requirements
- AWS Account: You need an AWS account.
- Terraform: Install Terraform on your local machine.
- AWS CLI: Install and configure the AWS Command Line Interface.

### Architecture Overview:

We'll use two availability zones (AZs) to ensure high availability and fault tolerance.
The WordPress application will run on Nginx web servers.
The database will be hosted on an Amazon RDS MySQL instance for better scalability and management.
We will also use an Application Load Balancer (ALB) for distributing traffic to the web servers.
Amazon Elastic File System (EFS) can be used for storing WordPress files and media.
Amazon RDS Multi-AZ for database redundancy.

##### Variables (variables.tf):
Define variables for your project, including AWS region, instance type, and any custom configurations.

Providers (provider.tf):
Configure the AWS provider with your AWS access and secret key.

##### VPC and Subnets (network.tf):
Create a Virtual Private Cloud (VPC), subnets, and route tables in two different AZs.

##### RDS Instance (rds.tf):
Deploy an RDS MySQL instance with Multi-AZ enabled.

##### EC2 Instances for WordPress (main.tf):
Launch web server instances in two different AZs, using an Auto Scaling Group.

##### Application Load Balancer (alb.tf):
Create an Application Load Balancer to distribute traffic to web servers.

##### Route53 (route53.tf): Optional
Configure DNS records using Amazon Route 53 for your domain.

##### Outputs (outputs.tf):
Define outputs to display important information about your infrastructure.


-  Deployment Steps:
  
 Run `terraform init` to initialize your Terraform project.
 
 Run `terraform plan` to see the execution plan.
 
 Run `terraform apply` to create your infrastructure.

## Cost Optimization:

To optimize costs, consider the following:

Use the AWS Free Tier for resources wherever possible.
Implement auto-scaling policies to adjust the number of EC2 instances based on traffic.
Use Reserved Instances (RIs) for the EC2 instances if the application has a steady load.
Set up alarms and monitoring to optimize resource utilization.
Implement lifecycle policies for EBS volumes to delete unneeded snapshots.

--------------------------------------
#### Variable need to add in Gitlab, if we are running gitlab CI pipeline for terraform
| Variable | Description | Environment | Example |
|---|---|---|---|
| AWS_ACCESS_KEY_ID | AWS Access key-ID | both | AW$ACCE$$KEY!D |
| AWS_S3_SECRET_ACCESS_KEY | AWS Secret key | both | AW$$ECRETKEY |

or
```
expot $AWS_ACCESS_KEY_ID=
expot $AWS_S3_SECRET_ACCESS_KEY=
```


