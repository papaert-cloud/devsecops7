# -------- Provider --------
region  = "us-east-1"
profile = "default"

# -------- StackSet identity & template --------
stack_set_name = "iam-user-group-stackset-v2"
capabilities   = ["CAPABILITY_IAM","CAPABILITY_NAMED_IAM"]

# -------- Parameters passed to the CFN template --------
parameters = {
  UserName         = "student-user"
  GroupName        = "student-group"
  PolicyName       = "s3-readonly-policy"
  TagKey           = "Environment"
  TagValue         = "NonProd"
  ManagedPolicyArn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

tags = { Project = "DevSecOps" }

# -------- Permissions model --------
permission_model = "SERVICE_MANAGED"   # you run from Mgmt account (delegated admin not required)
call_as          = "SELF"

# -------- Targets (SERVICE_MANAGED uses OUs) --------
stack_set_instance_region = "us-east-1"
ou_ids                    = ["ou-im88-1fmr1yt9"]   # your OU
account_ids               = []                     # not used for SERVICE_MANAGED

# -------- Auto-deployment preferences --------
auto_deployment_enabled          = true
retain_stacks_on_account_removal = false

# -------- Concurrency / failure handling --------
failure_tolerance_percentage = 100   # abort never (let all accounts try)
max_concurrent_percentage    = 100   # run across all targets in parallel
region_concurrency_type      = "SEQUENTIAL"

# -------- Timeouts --------
timeout_create = "45m"
timeout_update = "45m"
timeout_delete = "45m"

# -------- Template path (now CFN_Templates) --------
template_path = "${path.root}/../CFN_Templates/iam/iam_user_group.yml"