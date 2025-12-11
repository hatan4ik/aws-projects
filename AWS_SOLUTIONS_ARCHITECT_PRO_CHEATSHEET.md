# AWS Solutions Architect Professional Cheat Sheet

## FAANG Grooming Board

Status flow suggestion: Backlog -> Deep Dive -> Drill -> Mock Ready. Each row points to sections below for detail.

| Track | Why it matters at FAANG | Key focus in this sheet | Drill to prove it | Status |
| --- | --- | --- | --- | --- |
| Multi-Account guardrails | Separation of duties, blast-radius control, compliance | AWS Organizations (SCPs, OUs), consolidated billing, cross-account IAM roles, RAM sharing | Design a 5-account landing zone with centralized logging and a deny-by-default SCP set | Backlog |
| Networking and connectivity | Global traffic, hybrid integration, low latency | VPC design (CIDR/subnets/RTs), peering vs Transit Gateway, PrivateLink, DX/VPN, Route 53 Resolver hybrid DNS | Sketch a multi-region, hybrid network showing TGW attachments and DNS forwarding paths | Backlog |
| Identity and security services | Least privilege, auditability, regulated workloads | IAM policies/roles/STS, KMS vs CloudHSM, Secrets Manager, SGs vs NACLs, WAF/Shield/Network Firewall, Config/CloudTrail/GuardDuty/Security Hub/Macie | Build a secure cross-account access pattern with KMS encryption and WAF on an edge entrypoint | Backlog |
| Compute and auto scaling | Cost-aware elasticity and availability | Instance families, placement groups, launch templates, ASG policies, on-demand vs RI/Savings Plans vs Spot | Choose an instance mix and scaling policy for a latency-sensitive tier with bursty load | Backlog |
| Containers and serverless | Managed orchestration and agility | ECS/EKS (Fargate vs EC2), ECR scanning, Lambda limits, Step Functions (Standard vs Express), EventBridge, API Gateway | Whiteboard an event-driven service using EventBridge, Lambda, and Step Functions; justify ECS vs EKS for another workload | Backlog |
| Storage and data protection | Durability, lifecycle efficiency, data residency | S3 classes/versioning/lifecycle/replication/object lock, EBS types/snapshots/multi-attach, EFS perf/throughput, FSx options | Pick storage backends for web, analytics, and backup tiers; include lifecycle and replication choices | Backlog |
| Databases and caching | Correct data models, consistency, scale | RDS Multi-AZ/read replicas, Aurora global, DynamoDB (global tables, DAX), DocumentDB, Keyspaces, ElastiCache | Design a multi-region read-heavy app with write-local/read-global behavior and caching strategy | Backlog |
| Analytics and streaming | Real-time + batch insights | Data lake flow (S3 -> Glue -> Athena/Redshift Spectrum), Kinesis Streams vs Firehose, EMR, QuickSight | Map an ingestion pipeline for clickstreams with partitioning, schema evolution, and consumption patterns | Backlog |
| Migration and hybrid | Pragmatic adoption and risk reduction | 6 R's, MGN, DMS + SCT, DataSync, Snow Family, Transfer Family | Plan a phased migration for a legacy database and file share, including cutover and rollback | Backlog |
| Resilience and disaster recovery | SLO adherence and customer trust | RTO/RPO strategies (backup/restore, pilot light, warm standby, active-active), AWS Backup, Elastic Disaster Recovery, Route 53 health checks | Produce a DR plan for a tiered app with target RTO/RPOs and failover testing steps | Backlog |
| Cost and performance efficiency | Operating leverage at scale | EC2 pricing models, Savings Plans vs RI vs Spot, S3 IA/Glacier, Budgets/Cost Explorer/Compute Optimizer, latency tools (CloudFront, Global Accelerator, S3 TA) | Right-size a workload with a savings plan strategy and latency optimizations for global users | Backlog |

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
- **Snow Family** - Offline data transfer (Snowcone 8TB, Snowball 80TB, Snowmobile 100PB)
- **Transfer Family** - SFTP/FTPS/FTP to S3/EFS

## Disaster Recovery

### RTO/RPO Strategies (Cost ↑, RTO/RPO ↓)
1. **Backup & Restore** - Hours/Days RTO, Hours RPO, Lowest cost
2. **Pilot Light** - 10s of minutes RTO, Minutes RPO, Core services running
3. **Warm Standby** - Minutes RTO, Seconds RPO, Scaled-down replica
4. **Multi-Site Active/Active** - Real-time RTO, Real-time RPO, Highest cost

### Services
- **AWS Backup** - Centralized backup across services
- **Elastic Disaster Recovery** - Continuous replication, fast recovery

## Analytics

### Data Lake Pattern
```
S3 (Raw) → Glue ETL → S3 (Processed) → Athena/Redshift Spectrum
                                      ↓
                                  QuickSight
```

### Services
- **Kinesis Data Streams** - Real-time, 1MB/s per shard, 24hr-365 day retention
- **Kinesis Firehose** - Near real-time (60s buffer), auto-scaling, S3/Redshift/ES/HTTP
- **Glue** - Serverless ETL, Data Catalog, crawlers
- **Athena** - Serverless SQL on S3, pay per query
- **EMR** - Managed Hadoop/Spark, transient or long-running
- **QuickSight** - BI dashboards, SPICE in-memory engine

## Cost Optimization

### EC2 Pricing
- **On-Demand** - Pay per second, no commitment
- **Reserved** - 1/3 year, up to 72% savings, specific instance type
- **Savings Plans** - 1/3 year, up to 72% savings, flexible (compute or EC2)
- **Spot** - Up to 90% savings, 2-min termination notice

### Cost Tools
- **Cost Explorer** - Visualize spending, forecast
- **Budgets** - Alerts on thresholds, RI/Savings Plan utilization
- **Compute Optimizer** - Right-sizing recommendations (ML-based)
- **Trusted Advisor** - Best practice checks (cost, performance, security, fault tolerance)

## Exam-Critical Patterns

### Service Limits (Memorize These)
- **Lambda** - 15min timeout, 10GB memory, 512MB /tmp, 6MB sync payload, 250KB async
- **API Gateway** - 29s timeout, 10MB payload
- **S3** - 5TB object max, 5GB single PUT, 100 buckets default
- **DynamoDB** - 400KB item size, 25 GSI per table
- **SQS** - 256KB message, 14 day retention, 120K in-flight (standard), 20K (FIFO)
- **SNS** - 256KB message
- **Step Functions** - 25K events, 1 year execution (Standard), 5 min (Express)
- **VPC** - 5 VPCs per region, 200 subnets per VPC, 5 EIPs

### Common Scenarios → Solutions

**Lowest Latency:**
- Global users → CloudFront + S3/ALB origin
- Static IP required → Global Accelerator
- Regional users → Local Zones, Wavelength
- Database → ElastiCache, DAX, Aurora read replicas

**Highest Throughput:**
- S3 uploads → Transfer Acceleration, multipart upload
- Network → Enhanced Networking (SR-IOV), Placement Groups (cluster)
- Database writes → DynamoDB, Aurora parallel query

**Most Cost-Effective:**
- Storage → S3 IA/Glacier, lifecycle policies
- Compute → Spot, Savings Plans, right-sizing
- Data transfer → VPC endpoints (no NAT/IGW charges), CloudFront

**Highest Availability:**
- Multi-AZ → RDS, EFS, ALB, NAT Gateway
- Multi-Region → Route 53, CloudFront, S3 CRR, DynamoDB Global Tables, Aurora Global
- Health checks → Route 53 failover, ALB target health

**Decouple Components:**
- Async → SQS (standard for throughput, FIFO for ordering)
- Pub/Sub → SNS, EventBridge
- Orchestration → Step Functions
- Streaming → Kinesis

**Audit & Compliance:**
- API calls → CloudTrail (all regions, log file validation, S3 + CloudWatch Logs)
- Resource changes → Config (rules, remediation, aggregator)
- Network traffic → VPC Flow Logs
- Threats → GuardDuty, Security Hub
- Data classification → Macie

**Encryption:**
- At rest → S3 (SSE-S3, SSE-KMS, SSE-C), EBS, RDS, DynamoDB
- In transit → TLS/SSL, VPN, CloudFront, ALB
- Key management → KMS (AWS managed, customer managed, rotation), CloudHSM (FIPS 140-2 L3)

### Decision Trees

**Storage Selection:**
```
Block storage? → EBS (persistent), Instance Store (ephemeral)
File storage? → EFS (Linux, NFS), FSx (Windows/Lustre/ONTAP)
Object storage? → S3
Archive? → Glacier (3-5hr retrieval), Deep Archive (12hr)
```

**Database Selection:**
```
Relational (OLTP)? → RDS (managed), Aurora (performance)
Relational (OLAP)? → Redshift
Key-value? → DynamoDB
Document? → DocumentDB
Graph? → Neptune
Time-series? → Timestream
Ledger? → QLDB
```

**Compute Selection:**
```
Long-running? → EC2, ECS/EKS
Event-driven? → Lambda
Batch processing? → Batch
Containers? → ECS (AWS-native), EKS (Kubernetes)
Serverless containers? → Fargate
```

### Red Flags (Wrong Answers)

❌ **Snowball for < 10TB** → Use DataSync or Direct Connect
❌ **RDS for > 64TB** → Use Aurora (128TB) or shard
❌ **Single AZ for production** → Always Multi-AZ
❌ **Hardcoded credentials** → Use IAM roles, Secrets Manager
❌ **Public S3 buckets** → Use VPC endpoints, PrivateLink, pre-signed URLs
❌ **NAT Gateway for VPC-to-VPC** → Use VPC Peering, Transit Gateway, PrivateLink
❌ **EBS for shared storage** → Use EFS (Linux) or FSx (Windows)
❌ **Kinesis Streams for simple S3 delivery** → Use Firehose
❌ **Lambda for > 15min** → Use Fargate, Batch, or Step Functions
❌ **SQS FIFO for high throughput** → Use Standard (300 msg/s FIFO vs unlimited Standard)

### Time-Based Decisions

**Real-time (< 1s):**
- Lambda, API Gateway, DynamoDB, ElastiCache, Kinesis Data Streams

**Near real-time (seconds to minutes):**
- Kinesis Firehose (60s buffer), Step Functions Express, ECS/Fargate

**Batch (minutes to hours):**
- Step Functions Standard, Batch, EMR, Glue

**Scheduled:**
- EventBridge rules, Lambda scheduled, Batch scheduled

### Multi-Region Patterns

**Active-Passive:**
- Route 53 failover routing
- Primary region serves traffic, secondary on standby
- RDS cross-region read replica (promote on failover)

**Active-Active:**
- Route 53 latency/geolocation routing
- Both regions serve traffic
- DynamoDB Global Tables, Aurora Global Database
- S3 CRR for data sync

**Data Residency:**
- Region selection for compliance (GDPR, data sovereignty)
- S3 Object Lock for WORM
- KMS regional keys

### Hybrid Connectivity

**VPN (< 1 Gbps, quick setup):**
- Site-to-Site VPN over internet
- Redundant tunnels for HA
- BGP for dynamic routing

**Direct Connect (1-100 Gbps, consistent latency):**
- Dedicated connection to AWS
- Private VIF (VPC), Public VIF (S3, DynamoDB)
- LAG for aggregated bandwidth
- DX Gateway for multi-VPC/region

**Hybrid DNS:**
- Route 53 Resolver Inbound (on-prem → AWS)
- Route 53 Resolver Outbound (AWS → on-prem)
- Conditional forwarding rules

### Security Best Practices

**IAM:**
- Least privilege principle
- Use roles, not users for applications
- MFA for privileged accounts
- Password policy, credential rotation
- Service Control Policies (SCPs) for guardrails

**Network:**
- Private subnets for workloads
- Security groups (allow), NACLs (deny)
- VPC Flow Logs for traffic analysis
- WAF for application layer protection
- Shield Advanced for DDoS mitigation

**Data:**
- Encrypt at rest (KMS) and in transit (TLS)
- S3 bucket policies, block public access
- Versioning + MFA Delete for critical data
- Secrets Manager for credential rotation
- Macie for PII discovery

**Monitoring:**
- CloudTrail for all API calls
- Config for resource compliance
- GuardDuty for threat detection
- Security Hub for centralized findings
- CloudWatch alarms for anomalies

### Performance Optimization

**Caching Layers:**
```
User → CloudFront (edge) → ALB → ElastiCache (app) → RDS (data)
```

**Database Performance:**
- Read replicas for read-heavy workloads
- ElastiCache/DAX for caching
- Connection pooling (RDS Proxy)
- Partition keys (DynamoDB)
- Indexes (RDS, DynamoDB GSI/LSI)

**Network Performance:**
- Enhanced Networking (SR-IOV)
- Placement Groups (cluster for low latency)
- VPC endpoints (avoid NAT/IGW)
- Direct Connect for consistent latency

### Compliance Keywords

**HIPAA:**
- Eligible services (most, but not all)
- BAA (Business Associate Agreement) required
- Encrypt PHI at rest and in transit

**PCI DSS:**
- Validated services for cardholder data
- Shared responsibility model
- Network segmentation, encryption

**GDPR:**
- Data residency (EU regions)
- Right to be forgotten (delete data)
- Data portability
- Encryption and access controls

**SOC/ISO:**
- Audit reports available in Artifact
- Demonstrates AWS controls

## Last-Minute Review

### Must-Know Service Combinations

1. **Web Application (HA, Scalable):**
   - Route 53 → CloudFront → ALB → ASG (EC2/ECS) → RDS Multi-AZ → ElastiCache

2. **Serverless API:**
   - API Gateway → Lambda → DynamoDB → S3

3. **Data Lake:**
   - S3 → Glue (ETL) → Athena/Redshift Spectrum → QuickSight

4. **Real-time Analytics:**
   - Kinesis Data Streams → Lambda/Kinesis Analytics → S3/DynamoDB

5. **Hybrid Connectivity:**
   - On-prem → Direct Connect/VPN → Transit Gateway → VPCs

6. **Multi-Account Security:**
   - Organizations (SCPs) → CloudTrail (centralized) → Config (aggregator) → Security Hub

7. **Disaster Recovery:**
   - Primary Region (RDS Multi-AZ) → Cross-region read replica → Route 53 failover

8. **Migration:**
   - Assessment (Migration Hub) → MGN (servers) + DMS (databases) → Validation

### Exam Day Checklist

✅ **Read questions carefully** - Look for keywords (most cost-effective, lowest latency, highest availability)
✅ **Eliminate wrong answers** - Use red flags list
✅ **Consider constraints** - Time, budget, compliance, existing infrastructure
✅ **Think multi-layer** - Security, monitoring, backup for every solution
✅ **AWS-native first** - Prefer managed services over self-managed
✅ **Scalability matters** - Choose services that scale automatically
✅ **Flag and review** - Mark uncertain questions, come back later

### Common Traps

⚠️ **Over-engineering** - Simplest solution often correct
⚠️ **Ignoring constraints** - Budget, time, compliance mentioned for a reason
⚠️ **Single point of failure** - Always consider HA/DR
⚠️ **Vendor lock-in concerns** - Exam assumes AWS-first approach
⚠️ **On-premises thinking** - Cloud-native patterns differDS instead of self-managed)
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
