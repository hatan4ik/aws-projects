# Stage 5 Safety Enhancements

## Critical Features Added

### 1. Sequential ASG Updates
- ASGs are now updated one at a time instead of simultaneously
- Reduces blast radius if new AMI has issues
- Each ASG must complete before next one starts

### 2. Health Check Validation
- Step Functions polls instance refresh status every 60 seconds
- Validates refresh completes successfully before proceeding
- Monitors percentage complete and final status

### 3. Automatic Rollback
- Stores previous AMI ID in SSM Parameter Store (`{param}-previous`)
- On refresh failure, automatically reverts Launch Templates to previous AMI
- Sends rollback notification via SNS

## New Lambda Functions

### `check_refresh_status.py`
Polls Auto Scaling Group instance refresh status and returns:
- Current status (Pending, InProgress, Successful, Failed)
- Percentage complete
- Whether refresh is complete and successful

### `rollback_ami.py`
Reverts infrastructure to previous AMI:
- Retrieves previous AMI from SSM Parameter
- Updates all Launch Templates to previous AMI
- Updates SSM Parameter back to previous value

## Updated Lambda Functions

### `trigger_instance_refresh.py`
Now processes ASGs sequentially:
- Tracks current index in ASG list
- Returns single ASG refresh details per invocation
- Signals completion when all ASGs processed

### `share_ami.py`
Enhanced with rollback support:
- Stores current AMI as "previous" before updating
- Enables rollback to last known good AMI

## Step Functions Flow

```
UpdateLaunchTemplate
  ↓
TriggerInstanceRefresh (ASG 1)
  ↓
WaitForRefresh (60s)
  ↓
CheckRefreshStatus
  ↓
EvaluateRefreshStatus
  ├─ Success → TriggerInstanceRefresh (ASG 2)
  ├─ Failed → RollbackAMI → NotifyRollback → NotifyFailure
  └─ InProgress → WaitForRefresh (loop)
```

## Configuration

No additional configuration required. The enhancements work with existing variables:
- `launch_template_ids` - Templates to update/rollback
- `auto_scaling_group_names` - ASGs to refresh sequentially

## Safety Guarantees

1. **Progressive Rollout**: Only one ASG updates at a time
2. **Health Validation**: Waits for successful completion before next ASG
3. **Automatic Recovery**: Rolls back on any failure
4. **Audit Trail**: All actions logged to CloudWatch and SNS notifications
