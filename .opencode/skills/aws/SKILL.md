---
name: aws-interaction
description: This skill should be used when the user asks to interact with AWS services via the CLI — listing resources, checking logs, deploying infrastructure, managing S3, EC2, Lambda, ECS, CloudFormation, IAM, CloudWatch, RDS, DynamoDB, SQS, SNS, Secrets Manager, SSM, ECR, Route53, API Gateway, Step Functions, or Cost Explorer. Provides safe AWS CLI patterns with a read-first, confirm-before-mutating approach.
version: 1.0.0
---

# AWS CLI Interaction

Safe, structured patterns for interacting with AWS services via the `aws` CLI. This skill enforces a **read-first, confirm-before-mutating** approach to prevent accidental resource destruction and cost surprises.

## Core Principles

1. **Identity first.** Always verify who you are before doing anything.
2. **Read before write.** Use `describe-*` / `list-*` / `get-*` before any mutation.
3. **Dry-run when available.** Use `--dry-run` (EC2) and `--dryrun` (S3) to preview.
4. **Confirm before mutating.** Never auto-run create, update, or delete commands — present the plan and wait.
5. **Never auto-delete.** Terminate, delete, and remove commands require explicit user approval every time.
6. **Tag everything.** All created resources get metadata tags for tracking.
7. **Limit output.** Use `--max-items`, `--query`, and `--output json` to keep responses manageable.

---

## Before Every Session

Always start with these two commands:

```bash
# 1. Who am I? (account, role, identity)
aws sts get-caller-identity

# 2. What region am I targeting?
aws configure get region
```

This prevents operating on the wrong account or region.

---

## Global Flags

Use these on every command to ensure predictable, non-blocking output:

```bash
aws <service> <command> \
  --output json \
  --no-cli-pager \
  --region <region>
```

| Flag | Purpose |
|------|---------|
| `--output json` | Machine-parseable output (default, but be explicit) |
| `--no-cli-pager` | Prevents interactive pager from blocking execution |
| `--region us-east-1` | Explicit region — never rely on defaults in automation |
| `--query '<jmespath>'` | Filter output to only needed fields |
| `--max-items N` | Limit pagination to N results |
| `--dry-run` | Preview EC2 operations without executing |

---

## Command Safety Classification

| Category | Prefixes | Agent Behaviour |
|----------|----------|----------------|
| **Safe (read-only)** | `describe-*`, `list-*`, `get-*`, `head-*`, `wait` | Run freely |
| **Mostly safe (creates)** | `create-*`, `put-*`, `tag-*`, `start-*` | Show user what will be created, warn about costs |
| **Dangerous (mutates)** | `update-*`, `modify-*`, `stop-*` | Describe current state first, confirm before running |
| **Very dangerous (destroys)** | `delete-*`, `terminate-*`, `remove-*`, `deregister-*`, `purge-*` | ALWAYS require explicit user confirmation |

---

## JMESPath Query Patterns

Use `--query` to extract only what you need:

```bash
# Select specific fields into a table
--query 'Resources[].{Name:Name, ID:Id, Status:Status}' --output table

# Filter by value
--query 'Items[?State==`active`]'

# Sort results
--query 'sort_by(Items, &CreatedAt)'

# Get latest item
--query 'reverse(sort_by(Items, &CreatedAt))[0]'

# Count
--query 'length(Items)'

# Null-safe tag extraction
--query 'Instances[].{ID:InstanceId, Name:Tags[?Key==`Name`].Value|[0]}'
```

For complex transformations beyond JMESPath, pipe to `jq`:

```bash
aws ec2 describe-instances --output json | jq -r \
  '.Reservations[].Instances[] | select(.State.Name=="running") | .InstanceId'
```

---

## Pagination

```bash
# Return only first page (quick sample)
--no-paginate

# Limit total results across all pages
--max-items 20

# Control items per API call (reduces timeout risk)
--page-size 50

# Resume from previous position
--starting-token <NextToken>
```

**Important:** `--no-paginate` means "first page only", not "all results at once."

For agents: always use `--max-items` to keep output within context limits.

---

## Waiters

Use waiters instead of sleep loops for async operations:

```bash
aws ec2 wait instance-running --instance-ids i-xxx
aws ecs wait services-stable --cluster my-cluster --services my-service
aws rds wait db-instance-available --db-instance-identifier my-db
aws cloudformation wait stack-create-complete --stack-name my-stack
aws lambda wait function-updated --function-name my-func
```

Waiters poll at regular intervals and exit when the condition is met or timeout is reached (typically ~6 minutes).

---

## Error Handling

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | S3 transfer failure |
| 2 | Parse error |
| 252 | Invalid syntax/parameters |
| 253 | Invalid configuration/credentials |
| 254 | AWS service returned an error |

Use `--debug` to get full HTTP request/response details when troubleshooting.

---

## Service Reference

### S3

```bash
# List
aws s3 ls
aws s3 ls s3://bucket/prefix/ --recursive --summarize --human-readable

# Upload/Download
aws s3 cp file.txt s3://bucket/key
aws s3 cp s3://bucket/key file.txt
aws s3 sync ./local s3://bucket/prefix/ --dryrun   # ALWAYS dryrun first

# Pre-signed URL (max 7 days / 604800s)
aws s3 presign s3://bucket/key --expires-in 3600

# Object metadata
aws s3api head-object --bucket BUCKET --key KEY

# Bucket security audit
aws s3api get-public-access-block --bucket BUCKET
aws s3api get-bucket-encryption --bucket BUCKET
aws s3api get-bucket-policy --bucket BUCKET
```

**Dangerous — require confirmation:**
- `aws s3 rm s3://bucket/ --recursive` — deletes ALL objects
- `aws s3 sync --delete` — removes destination files not in source
- `aws s3 rb s3://bucket --force` — removes bucket and all contents

**Gotcha:** Pre-signed URLs generated with temporary credentials (SSO/STS) expire when the credential expires, regardless of `--expires-in`.

---

### EC2

```bash
# Describe instances (filtered, formatted)
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key==`Name`].Value|[0],Type:InstanceType,State:State.Name,IP:PrivateIpAddress}' \
  --output table

# Describe a specific instance
aws ec2 describe-instances --instance-ids i-xxx

# Security groups
aws ec2 describe-security-groups --group-ids sg-xxx
aws ec2 describe-security-group-rules --filter "Name=group-id,Values=sg-xxx"

# Latest AMI (self-owned)
aws ec2 describe-images --owners self \
  --query 'reverse(sort_by(Images,&CreationDate))[0].{ID:ImageId,Name:Name,Date:CreationDate}'

# Start/Stop (safe, reversible)
aws ec2 start-instances --instance-ids i-xxx
aws ec2 stop-instances --instance-ids i-xxx

# Dry-run a launch (validates permissions and params, creates nothing)
aws ec2 run-instances --dry-run --image-id ami-xxx --instance-type t3.micro --count 1
```

**Dangerous — require confirmation:**
- `aws ec2 terminate-instances` — permanently destroys instances and root volumes
- `aws ec2 delete-security-group` — can break connectivity
- `aws ec2 delete-snapshot` / `aws ec2 deregister-image` — data loss

**Gotcha:** `--dry-run` returns `DryRunOperation` on success (meaning "would have succeeded"). It only checks permissions, not whether AMI/subnet/SG actually exist.

---

### Lambda

```bash
# List functions
aws lambda list-functions \
  --query 'Functions[].{Name:FunctionName,Runtime:Runtime,Memory:MemorySize}' --output table

# Get function details
aws lambda get-function --function-name NAME
aws lambda get-function-configuration --function-name NAME

# Tail logs (live)
aws logs tail /aws/lambda/NAME --follow --since 30m

# Invoke (synchronous)
aws lambda invoke --function-name NAME --payload '{"key":"value"}' output.json --log-type Tail

# Decode invocation logs
aws lambda invoke --function-name NAME out --log-type Tail \
  --query 'LogResult' --output text | base64 --decode

# Permission check only (no execution)
aws lambda invoke --function-name NAME --invocation-type DryRun output.json

# Safe deployment pipeline
aws lambda update-function-code --function-name NAME --zip-file fileb://code.zip
aws lambda wait function-updated --function-name NAME
aws lambda publish-version --function-name NAME
```

**Dangerous — require confirmation:**
- `aws lambda delete-function` — permanent deletion
- `aws lambda put-function-concurrency --reserved-concurrent-executions 0` — effectively disables the function

**Gotcha:** After `update-function-code`, VPC-attached functions can take ~60s to become ready. Always use `aws lambda wait function-updated`.

---

### ECS / Fargate

```bash
# List clusters and services
aws ecs list-clusters
aws ecs list-services --cluster CLUSTER

# Service status
aws ecs describe-services --cluster CLUSTER --services SVC \
  --query 'services[0].{Status:status,Desired:desiredCount,Running:runningCount,TaskDef:taskDefinition}'

# Task details
aws ecs list-tasks --cluster CLUSTER --service-name SVC
aws ecs describe-tasks --cluster CLUSTER --tasks TASK_ARN

# Force new deployment (same task def)
aws ecs update-service --cluster CLUSTER --service SVC --force-new-deployment
aws ecs wait services-stable --cluster CLUSTER --services SVC

# Scale
aws ecs update-service --cluster CLUSTER --service SVC --desired-count N

# Exec into container (requires SSM Session Manager plugin)
aws ecs execute-command --cluster CLUSTER --task TASK_ID \
  --container CONTAINER --interactive --command "/bin/sh"
```

**Dangerous — require confirmation:**
- `aws ecs delete-service --force` — deletes service with running tasks
- `aws ecs delete-cluster` — removes the cluster
- `aws ecs update-service --desired-count 0` — scales to zero

**Gotcha:** ECS Exec requires the task role (not execution role) to have `ssmmessages:*` permissions, and the service must have `--enable-execute-command` set.

---

### CloudFormation

```bash
# List stacks
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[].{Name:StackName,Status:StackStatus}'

# Stack details and outputs
aws cloudformation describe-stacks --stack-name NAME
aws cloudformation describe-stacks --stack-name NAME \
  --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' --output table

# Recent events (for debugging)
aws cloudformation describe-stack-events --stack-name NAME \
  --query 'StackEvents[:10].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]' \
  --output table

# Validate template
aws cloudformation validate-template --template-body file://template.yaml

# SAFE deploy: always use change sets
aws cloudformation create-change-set \
  --stack-name NAME --template-body file://template.yaml \
  --change-set-name preview --capabilities CAPABILITY_IAM
aws cloudformation describe-change-set --change-set-name preview --stack-name NAME
# Review the change set, then:
aws cloudformation execute-change-set --change-set-name preview --stack-name NAME
aws cloudformation wait stack-update-complete --stack-name NAME

# Or use deploy (creates + executes change set in one step)
aws cloudformation deploy --template-file template.yaml --stack-name NAME \
  --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset

# Drift detection
DRIFT_ID=$(aws cloudformation detect-stack-drift --stack-name NAME --query 'StackDriftDetectionId' --output text)
aws cloudformation describe-stack-drift-detection-status --stack-drift-detection-id $DRIFT_ID
aws cloudformation describe-stack-resource-drifts --stack-name NAME \
  --stack-resource-drift-status-filters MODIFIED DELETED
```

**Dangerous — require confirmation:**
- `aws cloudformation delete-stack` — deletes stack AND all its resources (unless DeletionPolicy: Retain)
- `aws cloudformation update-stack` with wrong template — can replace/delete resources

**Best practice:** Always use change sets instead of direct `update-stack`. Use `--no-fail-on-empty-changeset` in CI/CD.

---

### IAM

IAM is **read-only for agents.** Never create, delete, or modify IAM resources via CLI — use Infrastructure as Code.

```bash
# Who am I?
aws sts get-caller-identity

# Audit roles and policies
aws iam list-roles --query 'Roles[].{Name:RoleName,Arn:Arn}' --output table
aws iam get-role --role-name NAME
aws iam list-attached-role-policies --role-name NAME
aws iam get-policy-version --policy-arn ARN --version-id v1

# Audit users and access keys
aws iam list-users --query 'Users[].{Name:UserName,Created:CreateDate}'
aws iam list-access-keys --user-name NAME

# Test permissions without executing
aws iam simulate-principal-policy \
  --policy-source-arn ROLE_ARN \
  --action-names s3:GetObject \
  --resource-arns "arn:aws:s3:::bucket/*"

# Credential report
aws iam generate-credential-report
aws iam get-credential-report --query 'Content' --output text | base64 --decode
```

**Never run via CLI:** `create-user`, `delete-user`, `create-role`, `delete-role`, `attach-*-policy`, `detach-*-policy`, `put-*-policy`, `create-access-key`. These must be managed through IaC (CloudFormation, CDK, Terraform).

---

### CloudWatch (Logs & Metrics)

```bash
# Tail logs live
aws logs tail /aws/lambda/NAME --follow --since 30m
aws logs tail /aws/lambda/NAME --follow --filter-pattern "ERROR"

# Search historical logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/NAME \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --filter-pattern "Exception"

# CloudWatch Logs Insights query
QUERY_ID=$(aws logs start-query \
  --log-group-name /aws/lambda/NAME \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 50' \
  --query 'queryId' --output text)
aws logs get-query-results --query-id $QUERY_ID

# Metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda --metric-name Errors \
  --dimensions Name=FunctionName,Value=NAME \
  --start-time 2024-01-01T00:00:00Z --end-time 2024-01-02T00:00:00Z \
  --period 3600 --statistics Sum

# Active alarms
aws cloudwatch describe-alarms --state-value ALARM \
  --query 'MetricAlarms[].{Name:AlarmName,Reason:StateReason}'
```

**Gotcha:** `filter-log-events` uses `--start-time` in **milliseconds** since epoch. `start-query` uses **seconds**. Always check which one a command expects.

---

### RDS

```bash
# List instances
aws rds describe-db-instances \
  --query 'DBInstances[].{ID:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine,Class:DBInstanceClass}' \
  --output table

# Instance details
aws rds describe-db-instances --db-instance-identifier NAME

# List snapshots
aws rds describe-db-snapshots --db-instance-identifier NAME \
  --query 'DBSnapshots[].{ID:DBSnapshotIdentifier,Created:SnapshotCreateTime,Status:Status}'

# Create snapshot (safe, non-destructive)
aws rds create-db-snapshot \
  --db-instance-identifier NAME \
  --db-snapshot-identifier snap-$(date +%Y%m%d-%H%M%S)

# Download error log
aws rds download-db-log-file-portion --db-instance-identifier NAME \
  --log-file-name error/mysql-error.log
```

**Dangerous — require confirmation:**
- `aws rds delete-db-instance` — especially with `--skip-final-snapshot`
- `aws rds delete-db-snapshot` — permanent data loss
- `aws rds modify-db-instance --publicly-accessible` — exposes DB to internet

**Gotcha:** `stop-db-instance` auto-restarts after 7 days. Creating a snapshot on Single-AZ causes brief I/O suspension.

---

### DynamoDB

```bash
# List and describe tables
aws dynamodb list-tables
aws dynamodb describe-table --table-name TABLE

# Get single item
aws dynamodb get-item --table-name TABLE \
  --key '{"pk":{"S":"value"}}' --consistent-read

# Query (efficient, uses index)
aws dynamodb query --table-name TABLE \
  --key-condition-expression "pk = :pk" \
  --expression-attribute-values '{":pk":{"S":"value"}}' \
  --limit 10

# Scan (expensive — always limit)
aws dynamodb scan --table-name TABLE --max-items 10

# Conditional put (prevents overwrite)
aws dynamodb put-item --table-name TABLE \
  --item '{"pk":{"S":"123"},"name":{"S":"test"}}' \
  --condition-expression "attribute_not_exists(pk)"

# Monitor capacity consumption
aws dynamodb query ... --return-consumed-capacity TOTAL
```

**Dangerous — require confirmation:**
- `aws dynamodb delete-table` — permanently removes table and ALL data
- `aws dynamodb put-item` without `--condition-expression` — silently overwrites existing items
- `aws dynamodb scan` on large tables — consumes massive RCUs, can throttle the table

**Gotcha:** `--limit` (DynamoDB API parameter) and `--max-items` (CLI parameter) behave differently. Use `--max-items` to control total output. Filter expressions do NOT reduce RCU consumption.

---

### SQS / SNS

```bash
# SQS
aws sqs list-queues
aws sqs get-queue-attributes --queue-url URL --attribute-names All
aws sqs send-message --queue-url URL --message-body '{"event":"test"}'
aws sqs receive-message --queue-url URL --max-number-of-messages 10 --wait-time-seconds 20
aws sqs delete-message --queue-url URL --receipt-handle HANDLE

# SNS
aws sns list-topics
aws sns list-subscriptions-by-topic --topic-arn ARN
aws sns publish --topic-arn ARN --subject "Alert" --message "Something happened"
```

**Dangerous — require confirmation:**
- `aws sqs purge-queue` — deletes ALL messages (can only run once per 60s)
- `aws sqs delete-queue` / `aws sns delete-topic` — permanent deletion

**Gotcha:** `receive-message` may return fewer messages than `--max-number-of-messages`. Default visibility timeout is 30s — unacknowledged messages reappear.

---

### Secrets Manager / SSM Parameter Store

```bash
# Secrets Manager
aws secretsmanager list-secrets --query 'SecretList[].{Name:Name,Changed:LastChangedDate}'
aws secretsmanager get-secret-value --secret-id NAME --query 'SecretString' --output text

# SSM Parameter Store
aws ssm get-parameter --name /app/config/key --with-decryption --query 'Parameter.Value' --output text
aws ssm get-parameters-by-path --path /app/config/ --recursive --with-decryption

# Access Secrets Manager through Parameter Store
aws ssm get-parameter --name /aws/reference/secretsmanager/SECRET_NAME --with-decryption
```

**Dangerous — require confirmation:**
- `aws secretsmanager delete-secret --force-delete-without-recovery` — permanent, no recovery
- `aws ssm delete-parameter` — immediate, no recovery

**Security:** Secrets passed as CLI arguments are visible in shell history and `ps` output. For sensitive values, use `--cli-input-json file://input.json` instead.

**Gotcha:** `--with-decryption` is required for SecureString parameters — without it you get the encrypted blob.

---

### ECR

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region REGION | \
  docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.REGION.amazonaws.com

# List repositories
aws ecr describe-repositories --query 'repositories[].{Name:repositoryName,URI:repositoryUri}'

# Recent images
aws ecr describe-images --repository-name REPO \
  --query 'reverse(sort_by(imageDetails,&imagePushedAt))[:5].[imageTags[0],imagePushedAt]'

# Find untagged images
aws ecr list-images --repository-name REPO --filter tagStatus=UNTAGGED
```

**Dangerous — require confirmation:**
- `aws ecr delete-repository --force` — deletes repo AND all images

**Gotcha:** ECR auth tokens expire after 12 hours. Always pipe `get-login-password` directly to `docker login --password-stdin`.

---

### Route53

```bash
# List hosted zones
aws route53 list-hosted-zones --query 'HostedZones[].{Name:Name,ID:Id}'

# List records
aws route53 list-resource-record-sets --hosted-zone-id ZONE_ID \
  --query 'ResourceRecordSets[].{Name:Name,Type:Type,Value:ResourceRecords[0].Value}' --output table

# Upsert a record (creates if missing, updates if exists)
aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID \
  --change-batch file://change.json

# Wait for propagation
aws route53 wait resource-record-sets-changed --id /change/CHANGE_ID
```

**Dangerous — require confirmation:**
- `Action: "DELETE"` in change-batch — removes DNS records
- `aws route53 delete-hosted-zone` — removes entire zone

**Gotcha:** `change-resource-record-sets` requires JSON input via `file://`. DNS propagation can take up to 60s after API success.

---

### Step Functions

```bash
# List state machines
aws stepfunctions list-state-machines --query 'stateMachines[].{Name:name,Arn:stateMachineArn}'

# Start execution
aws stepfunctions start-execution --state-machine-arn ARN --input '{"key":"value"}'

# Check execution status
aws stepfunctions describe-execution --execution-arn EXEC_ARN

# Event history (latest first)
aws stepfunctions get-execution-history --execution-arn EXEC_ARN --reverse-order

# List running executions
aws stepfunctions list-executions --state-machine-arn ARN --status-filter RUNNING
```

**Gotcha:** `start-execution` returns immediately. Poll `describe-execution` for results. Execution names must be unique per state machine for 90 days.

---

### Cost Explorer

```bash
# Monthly cost by service
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-02-01 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Daily cost for a specific service
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-08 \
  --granularity DAILY \
  --metrics BlendedCost \
  --filter '{"Dimensions":{"Key":"SERVICE","Values":["Amazon EC2"]}}'
```

**Gotcha:** End date is **exclusive**. Cost data has up to 24-hour delay. The API itself costs $0.01 per request.

---

## Credential Management

### Check Current Identity

```bash
aws sts get-caller-identity
```

### Profile Usage

```bash
# Use a named profile
aws s3 ls --profile production

# Set for the session
export AWS_PROFILE=production
```

### SSO Login

```bash
aws sso login --profile my-sso-profile
```

### Assume Role

```bash
# Temporary credentials via role assumption
CREDS=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/MyRole --role-session-name agent-session)
export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')
```

**Best practices:**
- Prefer SSO or assume-role over long-lived access keys
- Never store credentials in code or commit them to git
- Use `--profile` explicitly rather than relying on environment defaults
- Role chaining limits sessions to 1 hour max

---

## Cost Awareness

Before creating any resource, consider:

1. **Instance type cost** — Verify the instance type/class is appropriate (avoid accidentally using p4d/p5 GPU instances)
2. **Region** — Confirm the target region (prices vary significantly)
3. **Data transfer** — S3 sync, cross-region copies, and NAT Gateway traffic incur costs
4. **Always-on resources** — NAT Gateways, RDS instances, ECS services, and Elasticsearch domains charge per hour
5. **DynamoDB scans** — Full table scans consume read capacity proportional to table size

Check current spend:

```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

---

## Discovering Command Parameters

Use `--generate-cli-skeleton` to see every parameter a command accepts:

```bash
aws ec2 run-instances --generate-cli-skeleton input
```

This outputs a JSON template you can fill in and pass back via `--cli-input-json file://input.json`.

---

## Quick Reference: Safe Exploration Commands

```bash
# Identity
aws sts get-caller-identity

# Compute
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"
aws lambda list-functions
aws ecs list-clusters && aws ecs list-services --cluster NAME

# Storage
aws s3 ls
aws rds describe-db-instances
aws dynamodb list-tables

# Networking
aws ec2 describe-vpcs
aws ec2 describe-security-groups
aws route53 list-hosted-zones

# Observability
aws logs tail /aws/lambda/NAME --follow --since 30m
aws cloudwatch describe-alarms --state-value ALARM

# Security
aws iam list-roles
aws secretsmanager list-secrets
aws ssm get-parameters-by-path --path /app/ --recursive

# Cost
aws ce get-cost-and-usage --time-period Start=YYYY-MM-DD,End=YYYY-MM-DD --granularity DAILY --metrics UnblendedCost
```
