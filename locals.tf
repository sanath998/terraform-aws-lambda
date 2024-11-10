locals {
 prefix = length(var.prefix) > 0 ? var.prefix : module.eits_vars.prefix
 account_id = data.aws_caller_identity.this.account_id
 partition = data.aws_partition.this.partition
 region_name = data.aws_region.this.name
 function_name = "${local.prefix}-${var.function_scope}-lambda"
 tags = merge(var.tags, module.eits_vars.tags, data.aws_default_tags.this.tags)

 iam_policies = {
 cloudwatch_logs = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
 cloudwatch_insights = var.cloudwatch_lambda_insights_enabled ? "arn:${local.partition}:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy" : null,
 vpc_access = var.vpc_config != null ? "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole" : null,
 xray = var.tracing_config_mode != null ? "arn:${local.partition}:iam::aws:policy/AWSXRayDaemonWriteAccess" : null
 }

 enabled_iam_policies = [for policy in values(local.iam_policies) : policy if policy != null]
}
