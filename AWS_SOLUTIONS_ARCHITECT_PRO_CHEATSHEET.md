# AWS Solutions Architect Professional Cheat Sheet

## Design Principles

### Well-Architected Framework Pillars
1. **Operational Excellence** - Run, monitor, improve
2. **Security** - Protect data, systems, assets
3. **Reliability** - Recover from failures, scale
4. **Performance Efficiency** - Use resources efficiently
5. **Cost Optimization** - Avoid unnecessary costs
6. **Sustainability** - Minimize environmental impact

### Design Patterns
- **Strangler Fig** - Gradually replace legacy systems
- **Circuit Breaker** - Prevent cascading failures
- **Bulkhead** - Isolate resources to contain failures
- **Retry with Exponential Backoff** - Handle transient failures
- **Idempotency** - Safe to retry operations

## Multi-Account Strategy

### AWS Organizations
- **SCPs** - Service Control Policies (guardrails)
- **OUs** - Organizational Units (group accounts)
- **Consolidated Billing** - Single payer account

### Account Structure
```
Root
├── Security OU (Log Archive, Security Tooling)
├── Infrastructure OU (Network, Shared Services)
├── Workloads OU
│   ├── Production
│   ├── Staging
│   └── Development
└── Sandbox OU
```

### Cross-Account Access
- **IAM Roles** - AssumeRole for cross-account
- **Resource Policies** - S3, KMS, SNS, SQS
- **RAM** - Resource Access Manager (share VPC, Transit Gateway)

## Networking

### VPC Design
- **CIDR Planning** - Non-overlapping ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
- **Subnets** - Public (IGW), Private (NAT), Isolated (no internet)
- **Route Tables** - One per subnet type minimum

### Connectivity Patterns
- **VPC Peering** - 1:1, non-transitive, same/cross-region
- **Transit Gateway** - Hub-and-spoke, transitive routing
- **PrivateLink** - Private connectivity to services (no IGW/NAT)
- **VPN** - Site-to-Site (IPSec), Client VPN (OpenVPN)
- **Direct Connect** - Dedicated 1/10/100 Gbps connection

### Hybrid DNS
- **Route 53 Resolver** - Inbound/Outbound endpoints
- **Conditional Forwarders** - Route queries to on-prem DNS

## Security

### Identity & Access
- **IAM Policies** - Identity-based, Resource-based, SCPs, Permission Boundaries
- **IAM Roles** - Service roles, Cross-account, Federated
- **STS** - Temporary credentials (AssumeRole, GetSessionToken)
- **Cognito** - User pools (authentication), Identity pools (authorization)

### Data Protection
- **KMS** - Customer Managed Keys (CMK), automatic rotation
- **CloudHSM** - FIPS 140-2 Level 3, single-tenant
- **Secrets Manager** - Automatic rotation, cross-region replication
- **ACM** - Free SSL/TLS certificates, auto-renewal

### Network Security
- **Security Groups** - Stateful, instance-level
- **NACLs** - Stateless, subnet-level
- **WAF** - Layer 7 protection (SQL injection, XSS)
- **Shield** - DDoS protection (Standard free, Advanced paid)
- **Network Firewall** - Stateful inspection, IDS/IPS

### Compliance & Governance
- **Config** - Resource inventory, compliance rules
- **CloudTrail** - API audit logs (90 days free, S3 for long-term)
- **GuardDuty** - Threat detection (VPC Flow, DNS, CloudTrail)
- **Security Hub** - Centralized security findings
- **Macie** - Discover and protect sensitive data (PII)

## Compute

### EC2 Patterns
- **Instance Types** - General (t3, m5), Compute (c5), Memory (r5), Storage (i3)
- **Placement Groups** - Cluster (low latency), Spread (HA), Partition (distributed)
- **Auto Scaling** - Target tracking, Step scaling, Scheduled
- **Launch Templates** - Versioned, immutable

### Containers
- **ECS** - AWS-native, Fargate (serverless) or EC2
- **EKS** - Managed Kubernetes, Fargate or self-managed nodes
- **ECR** - Private container registry, image scanning

### Serverless
- **Lambda** - 15min max, 10GB memory, 512MB /tmp
- **Step Functions** - Orchestration, Standard (1 year) or Express (5 min)
- **EventBridge** - Event bus, schedule, cross-account
- **API Gateway** - REST, HTTP, WebSocket

## Storage

### S3 Patterns
- **Storage Classes** - Standard, IA, One Zone-IA, Glacier, Deep Archive
- **Lifecycle Policies** - Transition, Expiration
- **Replication** - CRR (cross-region), SRR (same-region)
- **Versioning** - Protect from deletes, MFA Delete
- **Object Lock** - WORM (compliance, governance mode)

### EBS
- **Types** - gp3 (general), io2 (IOPS), st1 (throughput), sc1 (cold)
- **Snapshots** - Incremental, cross-region copy
- **Multi-Attach** - io2 only, same AZ

### EFS
- **Performance Modes** - General Purpose, Max I/O
- **Throughput Modes** - Bursting, Provisioned, Elastic
- **Storage Classes** - Standard, IA (lifecycle)

### FSx
- **FSx for Windows** - SMB, AD integration
- **FSx for Lustre** - HPC, S3 integration
- **FSx for NetApp ONTAP** - Multi-protocol (NFS, SMB, iSCSI)

## Databases

### RDS
- **Multi-AZ** - Synchronous replication, automatic failover
- **Read Replicas** - Asynchronous, up to 5, cross-region
- **Aurora** - 6 copies across 3 AZs, 15 read replicas, Global Database

### NoSQL
- **DynamoDB** - Single-digit ms latency, Global Tables, DAX (cache)
- **DocumentDB** - MongoDB-compatible
- **Keyspaces** - Cassandra-compatible

### Data Warehouse
- **Redshift** - Columnar, MPP, Spectrum (query S3)
- **Redshift Serverless** - Auto-scaling, pay per use

### Caching
- **ElastiCache** - Redis (persistence, pub/sub), Memcached (simple)
- **DAX** - DynamoDB Accelerator, microsecond latency

## Migration

### 6 R's Strategy
1. **Rehost** - Lift-and-shift (MGN, SMS)
2. **Replatform** - Lift-tinker-shift (RDS instead of self-managed)
3. **Repurchase** - Move to SaaS
4. **Refactor** - Re-architect (serverless, containers)
5. **Retire** - Decommission
6. **Retain** - Keep on-premises

### Migration Services
- **MGN** - Application Migration Service (rehost)
- **DMS** - Database Migration Service (homogeneous/heterogeneous)
- **SCT** - Schema Conversion Tool
- **DataSync** - Online data transfer (NFS, SMB, S3, EFS, FSx)
- **Snow Family** - Offline data transfer (Snowcone, Snowball, Snowmobile)
- **Transfer Family** - SFTP/FTPS/FTP to S3/EFS

## Disaster Recovery

### RTO/RPO Strategies (Cost ↑, RTO/RPO ↓)
1. **Backup & Restore** - Hours/Days RTO, Hours RPO
2. **Pilot Light** - 10s of minutes RTO, Minutes RPO
3. **Warm Standby** - Minutes RTO, Seconds RPO
4. **Multi-Site Active/Active** - Real-time RTO, Real-time RPO

### Services
- **Backup** - Centralized backup across services
- **Elastic Disaster Recovery** - Continuous replication, fast recovery

## Analytics

### Data Lake Pattern
```
S3 (Raw) → Glue ETL → S3 (Processed) → Athena/Redshift Spectrum
                                      ↓
                                  QuickSight
```

### Services
- **Kinesis Data Streams** - Real-time, 1MB/s per shard
- **Kinesis Firehose** - Near real-time, auto-scaling, S3/Redshift/ES
- **Glue** - Serverless ETL, Data Catalog
- **Athena** - Serverless SQL on S3
- **EMR** - Managed Hadoop/Spark
- **QuickSight** - BI dashboards, SPICE in-memory

## Cost Optimization

### EC2 Pricing
- **On-Demand** - Pay per second, no commitment
- **Reserved** - 1/3 year, up to 72% savings
- **Savings Plans** - Flexible, 1/3 year, up to 72% savings
- **Spot** - Up to 90% savings, can be interrupted

### Cost Tools
- **Cost Explorer** - Visualize spending
- **Budgets** - Alerts on thresholds
- **Compute Optimizer** - Right-sizing recommendations
- **Trusted Advisor** - Best practice checks

## Exam Tips

### Common Scenarios
- **Lowest Latency** → CloudFront, Global Accelerator, Local Zones
- **Highest Throughput** → S3 Transfer Acceleration, Enhanced Networking
- **Most Cost-Effective** → S3 IA/Glacier, Spot Instances, Reserved Instances
- **Highest Availability** → Multi-AZ, Multi-Region, Route 53 health checks
- **Strongest Consistency** → DynamoDB strongly consistent reads, RDS Multi-AZ
- **Decouple Components** → SQS, SNS, EventBridge, Step Functions
- **Audit Everything** → CloudTrail, Config, VPC Flow Logs
- **Encrypt Everything** → KMS, ACM, S3 encryption, EBS encryption

### Decision Trees
**Storage:**
- Block → EBS, Instance Store
- File → EFS, FSx
- Object → S3
- Archive → Glacier

**Database:**
- OLTP → RDS, Aurora
- OLAP → Redshift
- NoSQL → DynamoDB
- Graph → Neptune
- Time-series → Timestream

**Compute:**
- Long-running → EC2
- Containers → ECS, EKS
- Event-driven → Lambda
- Batch → Batch

### Red Flags (Wrong Answers)
- ❌ Snowball for < 10TB (use DataSync)
- ❌ RDS for > 64TB (use Aurora or shard)
- ❌ Single AZ for production
- ❌ Hardcoded credentials (use IAM roles)
- ❌ Public S3 buckets (use PrivateLink, VPC endpoints)
- ❌ NAT Gateway for VPC-to-VPC (use VPC Peering, Transit Gateway)

### Time-Based Decisions
- **Seconds** → Lambda, API Gateway, DynamoDB
- **Minutes** → Step Functions, ECS/Fargate
- **Hours** → EC2, Batch
- **Days** → EMR, Glue

### Compliance Keywords
- **HIPAA** → Eligible services, BAA required
- **PCI DSS** → Validated services, responsibility matrix
- **GDPR** → Data residency, encryption, right to be forgotten
- **SOC** → Audit reports available
