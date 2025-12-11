# AWS Solutions Architect Professional (SAP-C02) Cheatsheet

This cheatsheet provides a summary of key concepts and services to review before taking the AWS Solutions Architect Professional exam.

## Domain 1: Design for Organizational Complexity

Focuses on designing and managing multi-account AWS environments.

*   **AWS Organizations:**
    *   Centrally manage and govern your environment.
    *   Use **Organizational Units (OUs)** to group accounts.
    *   **Service Control Policies (SCPs)** to enforce permissions across accounts.
*   **Networking:**
    *   **VPC Strategy:** Design VPCs, subnets, route tables, and security groups for different environments (dev, test, prod).
    *   **Hybrid Connectivity:**
        *   **AWS Direct Connect:** Dedicated private connection from on-premises to AWS.
        *   **AWS VPN:** Secure connection over the public internet.
    *   **AWS Transit Gateway:** Connect VPCs and on-premises networks through a central hub.
    *   **Route 53:** DNS service. Understand different routing policies (simple, weighted, latency, failover, geolocation).

## Domain 2: Design for New Solutions

Focuses on designing secure, reliable, and cost-effective solutions.

*   **Security:**
    *   **IAM:** Roles, policies, and best practices (least privilege).
    *   **AWS KMS (Key Management Service):** Manage encryption keys.
    *   **AWS WAF (Web Application Firewall):** Protect against common web exploits.
    *   **Encryption:** Server-side (SSE) and client-side encryption.
*   **Reliability and Resilience:**
    *   **High Availability:** Use multiple Availability Zones (AZs) and regions.
    *   **Disaster Recovery (DR):**
        *   **RTO (Recovery Time Objective):** How quickly you need to recover.
        *   **RPO (Recovery Point Objective):** How much data you can afford to lose.
        *   Strategies: Backup & Restore, Pilot Light, Warm Standby, Multi-site Active-Active.
*   **Cost Optimization:**
    *   **EC2 Instance Types:** Choose the right instance for the workload.
    *   **Storage Tiers:** Use appropriate S3 storage classes (Standard, IA, Glacier).
    *   **Reserved Instances & Savings Plans:** For long-running workloads.

## Domain 3: Continuously Improve Existing Solutions

Focuses on optimizing and improving existing AWS workloads.

*   **Operational Excellence:**
    *   **CloudWatch:** Monitoring and logging.
    *   **CloudTrail:** API logging and governance.
    *   **Automation:** Use services like AWS Lambda and Systems Manager to automate tasks.
*   **Performance Optimization:**
    *   **EC2 Auto Scaling:** Automatically adjust compute capacity.
    *   **ElastiCache:** In-memory caching for databases.
    *   **CloudFront:** Content Delivery Network (CDN) to reduce latency.

## Domain 4: Accelerate Workload Migration and Modernization

Focuses on migrating and modernizing applications on AWS.

*   **Migration Strategies (The 6 R's):**
    *   Rehost (Lift and Shift)
    *   Replatform (Lift and Reshape)
    *   Repurchase (Drop and Shop)
    *   Refactor/Re-architect
    *   Retire
    *   Retain
*   **Migration Services:**
    *   **AWS Migration Hub:** Track migration progress.
    *   **Application Migration Service (MGN):** Automate lift-and-shift migrations.
    *   **Database Migration Service (DMS):** Migrate databases to AWS.
    *   **AWS Snowball:** For large-scale data transfers.
*   **Modernization:**
    *   **Serverless:** Use AWS Lambda and API Gateway to build serverless applications.
    *   **Containers:** Use Amazon ECS or EKS to run containerized applications.
    *   **Microservices:** Break down monolithic applications into smaller, independent services.

## Key AWS Services Quick Reference

*   **Compute:** EC2, Lambda, ECS, EKS
*   **Storage:** S3, EBS, EFS, Glacier
*   **Databases:** RDS, DynamoDB, Aurora, Redshift
*   **Networking:** VPC, Route 53, Direct Connect, VPN, Transit Gateway
*   **Security:** IAM, KMS, WAF, Shield, Macie
*   **Management & Governance:** CloudFormation, Systems Manager, Organizations, CloudWatch, CloudTrail
*   **Migration & Transfer:** DMS, SMS, Snowball, DataSync
*   **Analytics:** Athena, Kinesis, EMR
*   **Developer Tools:** CodeCommit, CodeBuild, CodeDeploy, CodePipeline
*   **Machine Learning:** SageMaker

Good luck with the exam!