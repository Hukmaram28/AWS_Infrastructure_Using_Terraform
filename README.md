# AWS Infrastructure Using Terraform

## Overview

Created the following AWS resources using Terraform:

- A VPC, 2 subnets in 2 different AZs, an Internet Gateway to provide public access to both subnets, and one route table.
- One subnet group to be used for EC2 instances and an ALB.
- 2 EC2 instances in both subnets with a user data script, available under the name `user_data.sh`.
- One target group with both EC2 instances.
- An ALB with listener rules pointing to the target group.
- Also created an S3 bucket for demo purposes.

## Architecture Diagram

![Architecture Diagram](/images/Architecture.png)
