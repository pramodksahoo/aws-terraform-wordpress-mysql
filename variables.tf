# Define a variable for AWS Region
variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1" # Change this to your preferred region
}

# Define a list of availability zones
variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "key_name" {
  description = "SSH key pair name"
  default     = "your-key-pair-name" # Change this to your key pair name
}

variable "db_password" {
  description = "MySQL DB password"
  default     = "your-db-password" # Change this to your preferred DB password
}

# Define the AMI ID for the EC2 instances (You should replace this with the correct AMI ID)
variable "ami_id" {
  default = "ami-0123456789"
}

# Define a Instance type
variable "instance_type" {
  default = "t2.micro"
}

# ------------------------------------------
