# AWS Solutions Architect Professional - Real Exam Examples & Scenarios

**FAANG Engineering Board Review - Extended Edition**

## Domain 1: Design for Organizational Complexity (26%)

### Multi-Account Strategy

**Example 1: Financial Services Company**
```
Scenario: Bank with 200+ AWS accounts needs centralized security controls
and audit compliance across all accounts.

Architecture:
- AWS Organizations with 5 OUs: Security, Network, Production, Non-Prod, Sandbox
- Control Tower for automated account provisioning
- SCPs at OU level:
  * Deny all regions except us-east-1, us-west-2
  * Deny root user actions
  * Require MFA for sensitive operations
- Centralized CloudTrail → S3 (log archive account) with Object Lock
- Config Aggregator in security account
- GuardDuty delegated admin in security account

Question: How do you prevent developers from launching EC2 in eu-west-1?
Answer: SCP at Workloads OU denying ec2:RunInstances for eu-west-1 region
```

**Example 2: Cross-Account Data Access**
```
Scenario: Analytics team in Account A needs read access to S3 bucket
in Account B without copying data.

Solution:
1. Account B: S3 bucket policy allowing Account A role ARN
2. Account B: KMS key policy allowing Account A to decrypt
3. Account A: IAM role with s3:GetObject and kms:Decrypt permissions
4. Analytics users AssumeRole in Account A

Bucket Policy (Account B):
{
  "Effect": "Allow",
  "Principal": {"AWS": "arn:aws:iam::111111111111:role/AnalyticsRole"},
  "Action": ["s3:GetObject", "s3:ListBucket"],
  "Resource": ["arn:aws:s3:::data-bucket/*", "arn:aws:s3:::data-bucket"]
}

KMS Key Policy (Account B):
{
  "Effect": "Allow",
  "Principal": {"AWS": "arn:aws:iam::111111111111:role/AnalyticsRole"},
  "Action": ["kms:Decrypt", "kms:DescribeKey"],
  "Resource": "*"
}
```

**Exam Question Pattern:**
*"A company has 50 AWS accounts. They need to ensure no account can launch
instances larger than m5.xlarge. What is the MOST efficient solution?"*

A) Create IAM policy in each account ❌
B) Use AWS Config rule in each account ❌
C) Create SCP at root level denying large instances ✅
D) Use Lambda to terminate large instances ❌

### Identity Federation

**Example 3: SSO with Azure AD**
```
Scenario: Enterprise with 10,000 employees using Azure AD needs AWS access.

Architecture:
- AWS IAM Identity Center (SSO) as identity provider
- SAML 2.0 federation with Azure AD
- Permission sets mapped to AD groups:
  * Developers → PowerUserAccess
  * DBAs → DatabaseAdministrator
  * Auditors → ReadOnlyAccess
- Automatic provisioning via SCIM

ABAC Example:
Permission set uses tag-based access:
{
  "Effect": "Allow",
  "Action": "ec2:*",
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "ec2:ResourceTag/Team": "${aws:PrincipalTag/Team}"
    }
  }
}

User with Team=DataScience can only manage EC2 with Team=DataScience tag.
```

**Exam Question Pattern:**
*"Company uses on-premises Active Directory. 5,000 users need temporary
AWS credentials. What provides the MOST scalable solution?"*

A) Create IAM users for each employee ❌
B) Use IAM Identity Center with AD Connector ✅
C) Use Cognito User Pools ❌
D) Create shared IAM credentials ❌

### Resource Sharing

**Example 4: Shared Services VPC**
```
Scenario: Central networking team manages Transit Gateway and Route 53
Resolver rules. 100 application accounts need access.

Solution using RAM:
1. Network account creates Transit Gateway
2. Share TGW via RAM to Organization
3. Application accounts attach VPCs to shared TGW
4. Share Route 53 Resolver rules for hybrid DNS

Benefits:
- Single TGW for all accounts (cost optimization)
- Centralized routing policies
- No VPC peering mesh complexity

RAM Share Example:
aws ram create-resource-share \
  --name shared-tgw \
  --resource-arns arn:aws:ec2:us-east-1:222222222222:transit-gateway/tgw-xxx \
  --principals arn:aws:organizations::222222222222:organization/o-xxx
```

## Domain 2: Design for New Solutions (29%)

### High Availability Web Application

**Example 5: Global E-commerce Platform**
```
Scenario: E-commerce site serving 10M users globally, 99.99% uptime SLA.

Architecture:
┌─────────────────────────────────────────────────────────┐
│ Route 53 (Latency-based routing + health checks)       │
└─────────────────────────────────────────────────────────┘
                    │                    │
        ┌───────────┴──────────┐  ┌─────┴──────────────┐
        │   us-east-1          │  │   eu-west-1        │
        │                      │  │                    │
        │  CloudFront          │  │  CloudFront        │
        │      ↓               │  │      ↓             │
        │  ALB (Multi-AZ)      │  │  ALB (Multi-AZ)    │
        │      ↓               │  │      ↓             │
        │  ECS Fargate         │  │  ECS Fargate       │
        │  (3 AZs)             │  │  (3 AZs)           │
        │      ↓               │  │      ↓             │
        │  ElastiCache Redis   │  │  ElastiCache Redis │
        │  (Cluster mode)      │  │  (Cluster mode)    │
        │      ↓               │  │      ↓             │
        │  Aurora Global       │  │  Aurora Global     │
        │  (Primary)           │  │  (Secondary)       │
        └──────────────────────┘  └────────────────────┘

Key Design Decisions:
- CloudFront for edge caching (reduce origin load)
- ALB for HTTP/2, WebSocket, path-based routing
- Fargate for serverless containers (no EC2 management)
- ElastiCache for session store and query cache
- Aurora Global for <1s cross-region replication
- S3 + CloudFront for static assets

Failure Scenarios:
1. AZ failure → ALB routes to healthy AZs
2. Region failure → Route 53 fails over to secondary region
3. Database failure → Aurora auto-failover in <30s
4. Container failure → ECS replaces unhealthy tasks
```

**Exam Question Pattern:**
*"Application requires <100ms latency globally and 99.99% availability.
Database writes in us-east-1, reads worldwide. What design?"*

A) RDS Multi-AZ with read replicas in each region ❌ (replication lag)
B) DynamoDB Global Tables ✅ (active-active, low latency)
C) Aurora with cross-region read replicas ❌ (eventual consistency)
D) Redshift with cross-region snapshots ❌ (not for OLTP)

### Serverless Event-Driven Architecture

**Example 6: Order Processing System**
```
Scenario: Process 100K orders/day with async workflows, retry logic,
and audit trail.

Architecture:
API Gateway → Lambda (Validator) → EventBridge
                                        ↓
                    ┌───────────────────┼───────────────────┐
                    ↓                   ↓                   ↓
            Lambda (Inventory)  Lambda (Payment)   Lambda (Shipping)
                    ↓                   ↓                   ↓
            DynamoDB (Stock)    Stripe API         SQS (Fulfillment)
                    ↓                   ↓                   ↓
            EventBridge         EventBridge        Lambda (Warehouse)
                    ↓                   ↓                   ↓
            SNS (Notifications) Step Functions     DynamoDB (Orders)

Key Patterns:
- EventBridge for event routing (decoupled)
- SQS for durable queuing (retry with DLQ)
- Step Functions for complex workflows (saga pattern)
- DynamoDB Streams for change data capture
- Lambda destinations for async error handling

EventBridge Rule Example:
{
  "source": ["order.service"],
  "detail-type": ["Order Placed"],
  "detail": {
    "amount": [{"numeric": [">", 1000]}]
  }
}
→ Routes high-value orders to fraud detection Lambda

Cost Optimization:
- Lambda with 1GB memory (right-sized)
- DynamoDB on-demand for unpredictable traffic
- EventBridge pay-per-event (no idle cost)
- S3 for order archives with Glacier transition
```

**Exam Question Pattern:**
*"Microservices need to react to order events without tight coupling.
Some services are external SaaS. What integration?"*

A) SQS with polling ❌ (tight coupling)
B) SNS with HTTP subscriptions ❌ (no filtering)
C) EventBridge with event bus and rules ✅ (flexible routing)
D) Kinesis Data Streams ❌ (overkill for events)

### Data Lake Architecture

**Example 7: Analytics Platform**
```
Scenario: Ingest 10TB/day from multiple sources, query with SQL,
ML model training.

Architecture:
┌─────────────────────────────────────────────────────────┐
│ Data Sources                                            │
│ - Application logs → Kinesis Firehose → S3 (raw)       │
│ - Databases → DMS → S3 (raw)                            │
│ - Files → DataSync → S3 (raw)                           │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ S3 Data Lake (Partitioned by date)                     │
│ s3://lake/raw/logs/year=2024/month=01/day=15/           │
│ - Lifecycle: raw → IA after 30 days → Glacier after 90 │
│ - Versioning enabled                                    │
│ - Replication to DR region                             │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ Glue ETL Jobs (Spark)                                   │
│ - Clean, transform, enrich                              │
│ - Output: Parquet format (columnar, compressed)         │
│ - Glue Data Catalog (schema registry)                   │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ S3 Processed Zone                                       │
│ s3://lake/processed/analytics/year=2024/month=01/       │
└─────────────────────────────────────────────────────────┘
                    ↓               ↓               ↓
            ┌───────┴─────┐  ┌─────┴─────┐  ┌─────┴─────┐
            │   Athena    │  │ Redshift  │  │ SageMaker │
            │   (Ad-hoc)  │  │ Spectrum  │  │    (ML)   │
            └─────────────┘  └───────────┘  └───────────┘
                    ↓               ↓               ↓
            ┌───────┴───────────────┴───────────────┴─────┐
            │          QuickSight Dashboards              │
            └─────────────────────────────────────────────┘

Security:
- Lake Formation for fine-grained access (column/row level)
- S3 bucket policies with aws:PrincipalOrgID
- KMS encryption for all data
- VPC endpoints for private access
- CloudTrail for audit

Performance:
- Partition by date for query pruning
- Parquet format (10x faster than JSON)
- Glue Data Catalog for schema evolution
- Athena workgroups for cost control
```

**Exam Question Pattern:**
*"Data lake has PII in some columns. Analysts need access to non-PII
columns only. What provides column-level security?"*

A) S3 bucket policies ❌ (object-level only)
B) IAM policies ❌ (not column-aware)
C) Lake Formation permissions ✅ (column/row filtering)
D) Glue Data Catalog ❌ (metadata only)

## Domain 3: Continuously Improve Existing Solutions (25%)

### Cost Optimization

**Example 8: EC2 Fleet Optimization**
```
Scenario: 500 EC2 instances running 24/7, $200K/month bill.

Current State:
- 300x m5.2xlarge On-Demand ($0.384/hr × 300 × 730hr = $84K/mo)
- 200x c5.4xlarge On-Demand ($0.68/hr × 200 × 730hr = $99K/mo)
- Total: $183K/mo

Analysis:
- 80% of instances have steady utilization → Savings Plans
- 15% have predictable patterns → Scheduled scaling
- 5% have bursty workloads → Spot with fallback

Optimized State:
- 240x m5.2xlarge Compute Savings Plan (3-year, 72% discount)
  $0.107/hr × 240 × 730hr = $19K/mo
- 60x m5.2xlarge On-Demand (for burst)
  $0.384/hr × 60 × 730hr = $17K/mo
- 150x c5.4xlarge EC2 Instance Savings Plan (1-year, 40% discount)
  $0.408/hr × 150 × 730hr = $45K/mo
- 50x c5.4xlarge Spot (70% discount)
  $0.204/hr × 50 × 730hr = $7K/mo
- Total: $88K/mo (52% savings)

Additional Optimizations:
- Right-size: 20% of instances <30% CPU → downsize to m5.xlarge
- EBS gp2 → gp3 (20% cost reduction, same performance)
- Delete unattached EBS volumes ($5K/mo waste)
- S3 Intelligent-Tiering for logs (30% storage savings)
```

**Exam Question Pattern:**
*"Application runs 24/7 with steady load. Some instances need to scale
for daily peak. What is MOST cost-effective?"*

A) All On-Demand with Auto Scaling ❌
B) All Reserved Instances ❌ (can't scale down)
C) Savings Plan for baseline + On-Demand for peak ✅
D) All Spot Instances ❌ (can be interrupted)

### Performance Optimization

**Example 9: Database Performance Tuning**
```
Scenario: RDS PostgreSQL with slow queries, high CPU, connection exhaustion.

Problem Analysis:
- 5000 connections from Lambda functions
- Queries taking 5-10 seconds
- Read-heavy workload (90% reads)

Solution:
1. RDS Proxy for connection pooling
   - Reduces connections from 5000 → 100
   - Reuses connections (lower overhead)
   - IAM authentication for Lambda

2. Read Replicas for read scaling
   - 3 read replicas in different AZs
   - Application routes reads to replicas
   - Async replication (<1s lag)

3. ElastiCache Redis for query cache
   - Cache frequent queries (TTL 5 min)
   - 99% cache hit rate
   - Reduces DB load by 80%

4. Query optimization
   - Add indexes on frequently queried columns
   - Use EXPLAIN ANALYZE to identify slow queries
   - Partition large tables by date

Results:
- Query latency: 5s → 50ms (100x improvement)
- Database CPU: 80% → 20%
- Cost: +$500/mo (RDS Proxy + ElastiCache) vs +$5K/mo (larger RDS instance)

Architecture:
Lambda → RDS Proxy → RDS Primary (writes)
                  ↘ RDS Replicas (reads)
Lambda → ElastiCache Redis (cache) → RDS Proxy (cache miss)
```

**Exam Question Pattern:**
*"Lambda functions connecting to RDS exhaust database connections.
What reduces connection overhead?"*

A) Increase RDS max_connections ❌ (doesn't solve root cause)
B) Use RDS Proxy ✅ (connection pooling)
C) Add more read replicas ❌ (doesn't help connections)
D) Increase Lambda timeout ❌ (makes it worse)

### Disaster Recovery

**Example 10: Multi-Region DR**
```
Scenario: Mission-critical app, RTO 1 hour, RPO 15 minutes.

Primary Region (us-east-1):
- Application: ECS Fargate with ALB
- Database: Aurora PostgreSQL (Multi-AZ)
- Storage: S3 with versioning
- Cache: ElastiCache Redis

DR Region (us-west-2):
- Application: ECS task definitions (no running tasks)
- Database: Aurora Global Database (read-only secondary)
- Storage: S3 with CRR (15-min replication)
- Cache: ElastiCache Redis (empty, ready to populate)

Failover Process:
1. Route 53 health check detects primary failure
2. Route 53 updates DNS to point to us-west-2 ALB
3. Lambda triggers ECS service scale-up in us-west-2
4. Aurora secondary promoted to primary (RDS API call)
5. Application starts serving traffic in us-west-2
6. ElastiCache warms up from database

Automation:
- Step Functions orchestrates failover
- EventBridge triggers on health check alarm
- Systems Manager runbooks for manual steps
- Regular DR drills (quarterly)

Cost:
- Primary: $10K/mo
- DR (warm standby): $3K/mo (Aurora replica, S3 replication, minimal compute)
- Total: $13K/mo (30% overhead for 1-hour RTO)

Alternative (Pilot Light - 4 hour RTO):
- DR cost: $500/mo (Aurora replica only, no compute)
- Failover: Manually provision ECS, ALB, ElastiCache
```

**Exam Question Pattern:**
*"Application requires 1-hour RTO and 5-minute RPO. Database is 2TB.
What DR strategy?"*

A) Backup and Restore ❌ (RTO too high)
B) Pilot Light ❌ (RTO might exceed 1 hour)
C) Warm Standby ✅ (meets RTO/RPO)
D) Multi-Site Active/Active ❌ (over-engineered, expensive)

## Domain 4: Accelerate Workload Migration (20%)

### Database Migration

**Example 11: Oracle to Aurora PostgreSQL**
```
Scenario: 5TB Oracle database, 24/7 uptime requirement, minimize downtime.

Migration Strategy:
1. Assessment Phase
   - AWS SCT analyzes schema compatibility
   - Identifies 95% automatic conversion
   - 5% requires manual refactoring (PL/SQL → PL/pgSQL)

2. Schema Conversion
   - SCT converts schema, stored procedures, triggers
   - Create Aurora PostgreSQL cluster (Multi-AZ)
   - Apply converted schema

3. Data Migration (DMS)
   - Full load: Initial 5TB copy (takes 48 hours)
   - CDC (Change Data Capture): Continuous replication
   - Validation: Compare row counts and checksums

4. Cutover
   - Stop writes to Oracle (maintenance window)
   - Wait for CDC to catch up (5-10 minutes)
   - Update application connection strings
   - Start writes to Aurora
   - Monitor for issues

5. Rollback Plan
   - Keep Oracle running for 1 week
   - Reverse DMS task (Aurora → Oracle) if needed
   - DNS switch back to Oracle

Timeline:
- Week 1-2: Assessment and schema conversion
- Week 3-4: Full load and CDC setup
- Week 5: Testing and validation
- Week 6: Cutover (5-minute downtime)

Cost:
- DMS replication instance: c5.4xlarge ($1.36/hr × 720hr = $980/mo)
- Aurora: db.r6g.4xlarge ($1.632/hr × 2 × 730hr = $2,383/mo)
- Total migration cost: ~$1K (1 month DMS)
- Ongoing savings: Oracle license $50K/yr → Aurora $28K/yr = $22K/yr savings
```

**Exam Question Pattern:**
*"Migrate 10TB SQL Server to Aurora MySQL with minimal downtime.
Application can't tolerate >5 minutes outage. What approach?"*

A) Export to S3, import to Aurora ❌ (hours of downtime)
B) DMS with full load and CDC ✅ (continuous replication)
C) Database snapshots ❌ (not cross-engine)
D) AWS Backup ❌ (not for migration)

### Application Migration

**Example 12: Lift-and-Shift with MGN**
```
Scenario: 200 on-premises servers (Windows/Linux) to AWS, 3-month timeline.

Migration Waves:
Wave 1 (Dev/Test - 50 servers):
- Install MGN agent on source servers
- Continuous replication to AWS (EBS snapshots)
- Launch test instances in AWS
- Validate functionality
- Cutover (update DNS)

Wave 2 (Non-critical - 100 servers):
- Same process as Wave 1
- Cutover during maintenance window

Wave 3 (Critical - 50 servers):
- Blue/green deployment
- Run parallel in AWS and on-prem
- Gradual traffic shift (Route 53 weighted routing)
- Full cutover after validation

MGN Process:
1. Install replication agent on source
2. Agent replicates to staging area (EBS)
3. Launch test instance from replicated data
4. Perform cutover test
5. Production cutover (launch target instance)
6. Decommission source server

Network Setup:
- Site-to-Site VPN for replication traffic
- Direct Connect for production cutover (lower latency)
- Hybrid DNS with Route 53 Resolver

Post-Migration Optimization:
- Right-size instances (many over-provisioned on-prem)
- Convert to Auto Scaling groups
- Add ALB for load balancing
- Implement CloudWatch monitoring
- Apply Savings Plans

Results:
- Migration completed in 2.5 months
- Zero data loss
- <5 minutes downtime per server
- 40% cost reduction vs on-premises
```

**Exam Question Pattern:**
*"Migrate 500 servers to AWS with minimal downtime. Servers have
interdependencies. What service?"*

A) VM Import/Export ❌ (manual, high downtime)
B) Application Migration Service (MGN) ✅ (continuous replication)
C) DataSync ❌ (for file data, not servers)
D) Snowball ❌ (offline, high downtime)

## Advanced Board-Review Scenarios (New)

### Data Residency and Sovereignty

**Example 13: EU PII with Global Analytics**
```
Scenario: EU customer PII must never leave eu-central-1. Analytics team in us-east-1
needs aggregated insights without exposing PII.

Architecture:
- Control Tower with region-scoped OUs (EU, NA). SCP denies non-EU regions for EU workloads.
- Workload account (EU): S3 lake (single-Region KMS CMK, NOT multi-Region key), Lake Formation,
  Glue catalog. Macie for discovery; GuardDuty delegated admin.
- Processing: EMR Serverless/Glue jobs in eu-central-1 to produce anonymized aggregates.
- Data export path: Write sanitized parquet to "share" bucket with Object Lock + signed manifests.
- Cross-region transfer: S3 CRR from sanitized bucket to us-east-1 analytics account.
- Analytics account (US): Athena/Redshift Spectrum on sanitized data only. No KMS grants to raw key.

Trade-offs & Board Notes:
- Multi-Region keys replicate material outside region → avoid for strict residency.
- Keep VPC endpoints + private DNS; block internet egress via egress-only controls/NACLs.
- Use aws:PrincipalOrgID in bucket policies to restrict to org. Add Service Quotas alerts on CRR.

Exam Pattern:
Question leans toward "keep raw data in-region, export anonymized aggregates; use single-Region CMK".
```

### SaaS Multi-Tenant Isolation

**Example 14: Pooled + Siloed Tenancy Mix**
```
Scenario: SaaS with standard (pooled) tier and regulated (siloed) tier.
Needs per-tenant isolation, noisy-neighbor control, and cost attribution.

Architecture:
- Identity: Cognito or IAM Identity Center → OIDC JWT with tenant_id claim; STS session tags.
- Pooled tier: EKS/ECS on Fargate; VPC Lattice for service-to-service auth; ALB per app.
- Data plane (pooled): DynamoDB with per-tenant PK; row-level IAM conditions on tenant_id tag.
  S3 prefixes per tenant with bucket policy `aws:PrincipalTag/tenant = s3:prefix/tenant/*`.
- Siloed tier: Per-tenant account + VPC + isolated RDS/Aurora; shared service (billing, auth)
  consumed via PrivateLink to provider VPC.
- Observability: CloudWatch cross-account observability; X-Ray with tenant metadata; per-tenant
  log groups and retention. Cost allocation tags + CUR to Athena.

Board Notes:
- Lattice gives auth + routing without mesh sidecars; good for mixed compute (Lambda/ECS/EKS).
- Permission boundaries for delegated tenant admins; deny cross-tenant access via SCP conditions.
- For noisy neighbors, use DynamoDB adaptive capacity + per-tenant WCU/RCU throttling; add
  WAF rate-limits with tenant keys.

Exam Pattern:
Look for "per-tenant account + PrivateLink for regulated tenants; tag-based isolation for pooled".
```

### Streaming at Scale

**Example 15: 250K events/sec IoT Ingestion**
```
Scenario: 1KB payloads, 250K events/sec (~250 MB/s). Need <5s end-to-end, multiple consumers.

Architecture:
- Kinesis Data Streams in on-demand mode (auto-shard). Baseline capacity ≈ 4 MB/s/shard.
  Expect ~63 shards for 250 MB/s; pre-warm via PutRecords if steady state.
- Enhanced fan-out for 3 consumers (reduces shared 2 MB/s/shard limit).
- Kinesis Data Analytics (Flink) for stream join/enrichment; output to Firehose → S3 parquet +
  partitioning by dt/hour; secondary stream to Lambda for alerts.
- Partition key choice: device_id to balance across shards (avoid hot shards).
- DLQ: Kinesis → OnFailure to SQS with retries; CloudWatch alarms on IteratorAge.

Trade-offs:
- MSK suits strict ordering and Kafka APIs but adds ops; Kinesis on-demand reduces capacity planning.
- If consumers need replay beyond 7 days, enable Extended Retention.
- Firehose simplifies batch→S3/Redshift; for exactly-once semantics in Flink use sink with
  checkpoints to S3/FSx for Lustre.

Exam Pattern:
Math shard capacity (1 MB/s in, 2 MB/s out per shard) and pick Kinesis on-demand + enhanced fan-out.
```

### HPC / GenAI Training

**Example 16: Distributed Training with EFA**
```
Scenario: Train transformer model on 64 GPUs, minimize time-to-train and checkpoint stalls.

Architecture:
- AWS ParallelCluster with Slurm; p4d.24xlarge (8x A100) in cluster placement group.
- Networking: EFA + OSU/NCCL tuned AMIs; placement group "cluster" for low latency.
- Storage: FSx for Lustre linked to S3 for datasets; checkpoint to FSx and asynchronously copy to S3.
- Scaling policy: MixedInstancesPolicy ASG with Spot (70%) + On-Demand (30%) for capacity floor.
- Observability: CloudWatch agent + DCGM metrics; SSM Session Manager for ops; automated requeue
  on Spot interruption via Slurm resume scripts.

Trade-offs:
- EFS not ideal for high-throughput HPC; FSx for Lustre gives 200+ MB/s/TiB.
- Keep S3 transfer acceleration off unless cross-region ingest; prefer local FSx read-through.
- SnapStart not applicable; use warm pools for control nodes.

Exam Pattern:
If question mentions MPI/horovod/NCCL and low latency, answer is EFA + placement group + FSx Lustre.
```

### Incident Containment & Kill Switch

**Example 17: Compromised Access Key Response**
```
Scenario: Access key leaked; attacker launching resources across accounts. Need 5-minute containment.

Response Architecture:
- GuardDuty finding → EventBridge → Step Functions "KillSwitch".
- Actions:
  1) Block key in AWS IAM (set to inactive) or quarantine role via SCP (deny sts:AssumeRole for ARN).
  2) Apply quarantine SCP to impacted OU: deny ec2:RunInstances, iam:CreateUser, kms:Decrypt, s3:PutObject.
  3) Isolate VPC via Network Firewall default-deny or detach IGWs/NAT (RunCommand/SSM).
  4) Snapshot evidence: EBS snapshots, S3 object locks, CloudTrail lookup → central S3 bucket.
  5) Notify security chat/on-call (SNS + Chatbot); open OpsItem in Systems Manager.

Board Notes:
- Use service-linked role for SCP propagation (fast, org-wide). Keep pre-staged quarantine policy IDs.
- Logging account must be write-only; do not rotate KMS keys during incident.
- For third-party, use external ID and scope-down session policies to minimize blast radius.

Exam Pattern:
Look for automated EventBridge → SCP/quarantine, not manual console steps.
```

## Real Exam Question Patterns

### Pattern 1: "Most Cost-Effective"
```
Keywords: minimize cost, reduce spend, optimize budget

Strategy:
1. Eliminate expensive options (multi-region when not needed)
2. Look for managed services (less operational overhead)
3. Consider usage patterns (Spot for batch, Savings Plans for steady)
4. Check for over-engineering (do you need 5 AZs?)

Example:
"Process 1TB of log files daily. Files accessed once then archived.
What is MOST cost-effective storage?"

A) EBS volumes ❌ (expensive for archive)
B) S3 Standard with lifecycle to Glacier ✅ (automatic, cheap archive)
C) EFS with IA ❌ (more expensive than S3)
D) Instance Store ❌ (ephemeral, not durable)
```

### Pattern 2: "Lowest Latency"
```
Keywords: minimize latency, fastest response, real-time

Strategy:
1. Caching at every layer
2. Regional services over global
3. In-memory over disk
4. Direct connections over internet

Example:
"Application in us-east-1 serves users in Asia with high latency.
What reduces latency?"

A) Add read replicas in ap-southeast-1 ❌ (helps but not optimal)
B) CloudFront with origin in us-east-1 ✅ (edge caching)
C) Increase instance size ❌ (doesn't help network latency)
D) Use Elastic IPs ❌ (no latency benefit)
```

### Pattern 3: "Highest Availability"
```
Keywords: 99.99% uptime, fault-tolerant, no single point of failure

Strategy:
1. Multi-AZ by default
2. Multi-region for critical workloads
3. Health checks and automatic failover
4. Redundancy at every layer

Example:
"Application must survive AZ failure with no manual intervention.
What design?"

A) Single AZ with EBS snapshots ❌ (manual recovery)
B) Multi-AZ with ALB and Auto Scaling ✅ (automatic failover)
C) Single AZ with larger instances ❌ (no redundancy)
D) Multi-region active/active ❌ (over-engineered for AZ failure)
```

### Pattern 4: "Most Secure"
```
Keywords: least privilege, encryption, compliance, audit

Strategy:
1. Encryption at rest and in transit
2. IAM roles over credentials
3. Private networking (VPC endpoints, PrivateLink)
4. Logging and monitoring

Example:
"Lambda needs to access S3 bucket. What is MOST secure?"

A) Hardcode access keys in Lambda ❌ (credentials in code)
B) Store keys in environment variables ❌ (still exposed)
C) Use IAM role attached to Lambda ✅ (temporary credentials)
D) Use Secrets Manager ❌ (unnecessary for AWS services)
```

### Pattern 5: "Decouple Components"
```
Keywords: loosely coupled, independent scaling, fault isolation

Strategy:
1. Async communication (queues, events)
2. API contracts (API Gateway)
3. Service discovery (Cloud Map, ALB)
4. Avoid direct dependencies

Example:
"Microservice A needs to notify microservice B of events.
B is sometimes unavailable. What decouples them?"

A) Direct HTTP calls ❌ (tight coupling)
B) SQS queue between A and B ✅ (async, durable)
C) Shared database ❌ (tight coupling)
D) Lambda calling B directly ❌ (still coupled)
```

## Final Exam Tips

### Time Management
- 180 minutes for 75 questions = 2.4 min/question
- Flag difficult questions, come back later
- Don't spend >3 minutes on any question

### Elimination Strategy
1. Read question carefully (note keywords)
2. Eliminate obviously wrong answers
3. Between 2 good answers, pick AWS-native/managed service
4. Consider cost, complexity, operational overhead

### Common Wrong Answer Patterns
- ❌ Manual processes (scripts, cron jobs)
- ❌ Self-managed when managed service exists
- ❌ Over-complicated solutions
- ❌ Single AZ for production
- ❌ Hardcoded credentials
- ❌ Public internet when private option exists

### AWS Service Preferences (Exam Bias)
1. Managed > Self-managed
2. Serverless > Server-based
3. Multi-AZ > Single AZ
4. IAM roles > Access keys
5. CloudFormation > Manual
6. CloudWatch > Third-party monitoring
7. VPC endpoints > NAT Gateway
8. Secrets Manager > Parameter Store (for rotation)

### Last-Minute Checklist
✅ Know service limits (Lambda 15min, API Gateway 29s, etc.)
✅ Understand when to use each load balancer type
✅ Know RTO/RPO for each DR strategy
✅ Understand cross-account access patterns
✅ Know when to use each database service
✅ Understand VPC connectivity options
✅ Know encryption options for each service
✅ Understand cost optimization strategies

**Good luck! Remember: Security first, then reliability, then cost/performance.**
