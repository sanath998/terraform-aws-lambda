module "cloudwatch_log_group" {
 source = "git@github.com:sanath998/terraform-aws-cloudwatch.git"
 create_iam_role = false
 kms_key_arn = var.cloudwatch_logs_kms_key_arn
 retention_in_days = var.cloudwatch_logs_retention_in_days
 log_group_name = "/aws/lambda/${local.function_name}"
 tags = local.tags
}

resource "aws_lambda_function" "this" {
 architectures = var.architectures
 description = var.description
 filename = var.filename
 function_name = local.function_name
 handler = var.handler
 image_uri = var.image_uri
 kms_key_arn = var.kms_key_arn
 layers = var.layers
 memory_size = var.memory_size
 package_type = var.package_type
 publish = var.publish
 reserved_concurrent_executions = var.reserved_concurrent_executions
 role = var.role == null ? module.lambda_iam_role[0].role_arn : var.role
 runtime = var.runtime
 s3_bucket = var.s3_bucket
 s3_key = var.s3_key
 s3_object_version = var.s3_object_version
 source_code_hash = var.source_code_hash
 tags = local.tags
 timeout = var.timeout

 dynamic "dead_letter_config" {
 for_each = try(length(var.dead_letter_config_target_arn), 0) > 0 ? [true] : []

 content {
 target_arn = var.dead_letter_config_target_arn
 }
 }

 dynamic "environment" {
 for_each = var.lambda_environment != null ? [var.lambda_environment] : []
 content {
 variables = environment.value.variables
 }
 }

 dynamic "image_config" {
 for_each = length(var.image_config) > 0 ? [true] : []
 content {
 command = lookup(var.image_config, "command", null)
 entry_point = lookup(var.image_config, "entry_point", null)
 working_directory = lookup(var.image_config, "working_directory", null)
 }
 }

 logging_config {
 log_format = var.logging_config.log_format
 log_group = module.cloudwatch_log_group.log_group_name
 system_log_level = var.logging_config.system_log_level
 application_log_level = var.logging_config.application_log_level
 }

 dynamic "tracing_config" {
 for_each = var.tracing_config_mode != null ? [true] : []
 content {
 mode = var.tracing_config_mode
 }
 }

 dynamic "vpc_config" {
 for_each = var.vpc_config != null ? [var.vpc_config] : []
 content {
 security_group_ids = vpc_config.value.security_group_ids
 subnet_ids = vpc_config.value.subnet_ids
 }
 }

 dynamic "ephemeral_storage" {
 for_each = var.ephemeral_storage_size != null ? [var.ephemeral_storage_size] : []
 content {
 size = var.ephemeral_storage_size
 }
 }

 depends_on = [module.cloudwatch_log_group]
}

resource "aws_lambda_function_recursion_config" "this" {
 count = var.lambda_function_recursion_config_enabled ? 1 : 0
 function_name = aws_lambda_function.this.function_name
 recursive_loop = "Allow"
}