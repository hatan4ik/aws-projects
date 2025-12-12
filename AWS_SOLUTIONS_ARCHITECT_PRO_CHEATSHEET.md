# AWS Solutions Architect Professional (SAP-C02) Rapid Cheatsheet

Curated day-before review for SAP-C02. Optimize for least privilege, automation, multi-account governance, multi-AZ by default, and data transfer cost awareness.

## Exam Mindset

- Security first (least privilege, encryption, isolation), then reliability, then cost/performance.
- Prefer managed, serverless, and automation (CloudFormation/CDK, Systems Manager) over manual builds.
- Multi-account is normal; pick the control plane that matches scale (Organizations + Control Tower).
- Cross-region for DR; multi-AZ for HA. Validate RPO/RTO vs design.

## Domain 1: Design for Organizational Complexity

- **Landing zone:** AWS Control Tower for guardrails; AWS Organizations with OUs (security, infra, workloads, sandbox). SCPs are deny/allow lists that set max permissions; they do not grant access.
- **Identity at scale:** IAM Identity Center (successor to AWS SSO) with permission sets and assignments per account/OUs. Use attribute-based access control (ABAC) with tags when scaling roles.
- **Guardrails and logging:** Organization CloudTrail, AWS Config aggregator, GuardDuty/Inspector/Firewall Manager for centralized findings and WAF rules. Centralize logs to dedicated log archive account with S3 bucket + KMS CMK + S3 Object Lock for immutability.
- **Cross-account access:** Prefer IAM roles with external IDs for third parties; use Resource Access Manager (RAM) to share Transit Gateway, Subnets, Route 53 Resolver Rules, License Manager configs. Permission boundaries for delegated builders.
- **Tagging/FinOps:** Enforce tagging via SCP/Config; use cost allocation tags, consolidated billing, and AWS Budgets/Cost Anomaly Detection.

## Domain 2: Design for New Solutions

- **Security & encryption:** Default to KMS CMKs; multi-Region keys for DR; CloudHSM when FIPS 140-2 Level 3/HSM needed; VPC endpoints + private DNS to keep traffic off the internet. S3 Block Public Access everywhere; bucket policies with `aws:PrincipalOrgID` for org-only access.
- **Network entry:** ALB for HTTP/HTTPS with WAF; NLB for TCP/UDP/TLS and static IP; Gateway Load Balancer for inline appliances; Global Accelerator for static anycast and faster failover than DNS.
- **App integration:** EventBridge for decoupled, rule-based routing; SQS for durable queues; SNS for pub/sub fanout; Kinesis/MSK for ordered streams; Step Functions for orchestration; API Gateway vs ALB for API front doors.
- **Data layer patterns:** Aurora for relational HA/reader scaling (Global Database for DR/low-latency reads); RDS Multi-AZ for HA, read replicas for scale; DynamoDB for millisecond scale, DAX for caching, Streams + Lambda for CDC, Global Tables for multi-Region active/active. Redshift RA3 + Spectrum/Serverless for analytics; Athena + Glue Data Catalog for lake queries; Lake Formation for fine-grained permissions.
- **Storage:** S3 versioning + lifecycle + replication (SRR/CRR). EBS gp3 baseline 3000 IOPS; io2 for high durability and IOPS; EFS regional, infrequent access tier, and lifecycle; FSx (NetApp ONTAP for NFS/SMB, Windows for SMB, Lustre for HPC).
- **Compute choices:** EC2 + Auto Scaling with launch templates and warm pools; Fargate for serverless containers; Lambda for event-driven (use SnapStart for Java). Placement groups: spread for HA, cluster for low latency, partition for large fleets. Consider Nitro Enclaves for isolated compute.
- **Observability:** CloudWatch metrics/logs/traces, Application Insights, X-Ray, ServiceLens. Centralize alarms with EventBridge + SNS/Chatbot/PagerDuty. VPC Flow Logs for network visibility.

## Domain 3: Continuously Improve Existing Solutions

- **HA and scaling:** Multi-AZ everywhere feasible; health checks and fail-open designs. Scaling policies: target tracking for stable utilization, step scaling for sudden load, scheduled for known peaks. Use ASG instance refresh/rolling for safe deployments.
- **Cost optimization:** Savings Plans (compute/EC2) before RIs; use Spot for interruption-tolerant workloads with capacity-optimized allocation. Right-size EBS, EFS IA, S3 IA/Glacier tiers; use Compute Optimizer and Cost Explorer.
- **Performance tuning:** Caching at every layer (CloudFront, ALB/NLB connection reuse, ElastiCache Redis/Memcached, DynamoDB DAX, RDS Proxy for connection pools). Optimize network paths with PrivateLink and VPC endpoints to avoid NAT costs.
- **Governance/ops:** SSM Automation/Run Command/Patch Manager/Session Manager for fleet ops without SSH. Config conformance packs for drift. Fault Injection Simulator to test resilience.

## Domain 4: Accelerate Workload Migration and Modernization

- **Migration strategies:** 7 Rs (Retire, Retain, Rehost, Replatform, Repurchase, Refactor, Relocate). Pick per-app and phase rollouts.
- **Migration services:** Application Migration Service (MGN) for lift/shift servers; DMS + SCT for database migration/modernization; DataSync for NFS/SMB to S3/EFS/FSx; Transfer Family for SFTP/FTPS/FTP; Snowball/Snowcone for edge/air-gapped; Snowmobile for petabyte-scale. FSx for NetApp ONTAP for NAS migrations.
- **Modernization:** Containers (ECS/Fargate/EKS) with blue/green via CodeDeploy; service mesh (App Mesh) for traffic shaping; serverless stacks (Lambda, Step Functions, EventBridge). CI/CD via CodePipeline + CodeBuild/CodeDeploy or GitHub Actions. Use feature flags and canary/linear deployments.

## Networking and Hybrid Patterns

- **Connectivity:** Transit Gateway for hub-and-spoke multi-VPC/multi-account; VPC peering for simple 1:1; PrivateLink for producer-consumer without transitive routing; Route 53 Resolver inbound/outbound endpoints for DNS across networks.
- **Hybrid:** Site-to-Site VPN for quick IPsec; Direct Connect for consistent bandwidth/latency; DX + VPN (as backup) with BGP for failover; SD-WAN appliances via GWLB. Use AWS Managed VPN CloudHub for hub-and-spoke from branch to AWS.
- **Routing/DNS:** Route 53 policies: simple, weighted, latency, geolocation, geoproximity, failover, multi-value. Health checks plus CloudWatch alarms for hybrid endpoints. Use split-horizon DNS with Resolver rules.
- **IPv6:** Dual-stack VPCs, Egress-Only IGW for IPv6 outbound. NLB/ALB support IPv6 front-ends.

## Resilience and DR

- **Patterns vs RPO/RTO:** Backup/Restore (high RPO/RTO), Pilot Light (low RPO, higher RTO), Warm Standby (low RPO, moderate RTO), Multi-site Active/Active (lowest). Use Route 53 failover/latency + health checks or Global Accelerator for fast cutover.
- **Data durability:** S3 is regional and durable; CRR for cross-region. Aurora Global Database async <1s typically; DynamoDB Global Tables active/active; RDS cross-Region read replicas for DR; EBS snapshots to S3, copy cross-Region.
- **Stateful failover:** Keep infra as code, replicate parameters/secrets, pre-provision minimal capacity, and test regularly (GameDays/FIS).

## Edge, Performance, and App Delivery

- **Edge:** CloudFront for CDN with origin shield; signed URLs/cookies for private content; Lambda@Edge/CloudFront Functions for lightweight logic. Global Accelerator for TCP/UDP acceleration and deterministic failover.
- **APIs:** API Gateway REST/HTTP vs ALB for HTTP services; throttling, WAF, usage plans, custom domains. Use VPC links/PrivateLink for private backends.
- **Messaging:** SQS FIFO for ordering, standard for throughput; SNS for fanout; EventBridge for SaaS/app integration; Kinesis/MSK for ordered streams and replay.

## Security Quick Hits

- IAM roles over long-lived keys; use temporary credentials (STS). External ID for third-party access. Permission boundaries for delegated admins; session policies for further scope-down.
- Resource policies where available (S3, KMS, Lambda, SQS/SNS, EventBridge, API Gateway, Secrets Manager) for cross-account sharing.
- Encrypt everywhere: S3 SSE-KMS, EBS encryption by default, EFS/FSx encryption in transit/at rest. CloudHSM for customer-controlled keys.
- Network protections: Security groups are stateful; NACLs stateless. WAF + Shield Advanced for DDoS; Network Firewall or GWLB appliances for inspection; VPC Lattice for service-to-service auth and traffic controls.

## Cost Optimization Reminders

- Pick the right purchase option: Savings Plans > RIs > On-Demand > Spot (interruptible). Zonal reserved capacity for guaranteed AZ capacity.
- Cut data transfer: Use PrivateLink/VPC endpoints, keep traffic in-AZ/VPC, prefer CloudFront for egress, compress objects, use S3 Transfer Acceleration only when it beats the public path.
- Storage tiers: S3 Intelligent-Tiering for unknown patterns; S3 IA/Glacier for cold; EFS IA; FSx tiering; set lifecycle policies.

## Quick Decision Guides

- **Load balancer:** ALB (HTTP/HTTPS + WAF), NLB (L4/TLS passthrough, static IP), GWLB (security appliances), GA (static anycast/failover), CloudFront (edge cache).
- **Data store:** Strong consistency/relational -> Aurora/RDS; high scale/low latency -> DynamoDB (+DAX); analytics -> Redshift/Athena; search -> OpenSearch; graph -> Neptune; time series -> Timestream.
- **Connectivity:** Many VPCs/accounts -> Transit Gateway; private producer/consumer -> PrivateLink; hybrid enterprise -> DX + VPN; simple VPC-to-VPC -> peering.
- **DR replication:** Aurora Global DB, DynamoDB Global Tables, S3 CRR, RDS cross-Region replicas, EBS snapshot copy, FSx replication (per service).

Good luck on the exam! Focus on tradeoffs, least privilege, and multi-account patterns.***
