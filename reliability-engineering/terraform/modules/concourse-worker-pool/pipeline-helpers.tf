resource "aws_ssm_parameter" "concourse_worker_private_bucket_name" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_private_bucket_name"

  type        = "String"
  description = "Private s3 bucket name for ${var.deployment}/${var.name}"
  value       = aws_s3_bucket.concourse_worker_private.bucket

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_private_bucket_arn" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_private_bucket_arn"

  type        = "String"
  description = "Private s3 bucket arn for ${var.deployment}/${var.name}"
  value       = aws_s3_bucket.concourse_worker_private.arn

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_private_bucket_domain_name" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_private_bucket_domain_name"

  type        = "String"
  description = "Private s3 bucket domain name for ${var.deployment}/${var.name}"
  value       = aws_s3_bucket.concourse_worker_private.bucket_domain_name

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_public_bucket_name" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_public_bucket_name"

  type        = "String"
  description = "Public s3 bucket name for ${var.deployment}/${var.name}"
  value       = aws_s3_bucket.concourse_worker_public.bucket

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_public_bucket_arn" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_public_bucket_arn"

  type        = "String"
  description = "Public s3 bucket arn for ${var.deployment}/${var.name}"
  value       = aws_s3_bucket.concourse_worker_public.arn

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_public_bucket_domain_name" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_public_bucket_domain_name"

  type        = "String"
  description = "Public s3 bucket domain name for ${var.deployment}/${var.name}"
  value       = aws_s3_bucket.concourse_worker_public.bucket_domain_name

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_private_ecr_repo_name" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_private_ecr_repo_name"

  type        = "String"
  description = "Private ecr repo name for ${var.deployment}/${var.name}"
  value       = aws_ecr_repository.concourse_worker_private.name

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_private_ecr_repo_arn" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_private_ecr_repo_arn"

  type        = "String"
  description = "Private ecr repo arn for ${var.deployment}/${var.name}"
  value       = aws_ecr_repository.concourse_worker_private.arn

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_private_ecr_repo_url" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_private_ecr_repo_url"

  type        = "String"
  description = "Private ecr repo name for ${var.deployment}/${var.name}"
  value       = aws_ecr_repository.concourse_worker_private.repository_url

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_private_ecr_repo_registry_id" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_private_ecr_repo_registry_id"

  type        = "String"
  description = "Private ecr repo registry id for ${var.deployment}/${var.name}"
  value       = aws_ecr_repository.concourse_worker_private.registry_id

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_team_name" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_team_name"

  type        = "String"
  description = "Team name for ${var.deployment}/${var.name}"
  value       = var.name

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_secrets_path_prefix" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_secrets_path_prefix"

  type        = "String"
  description = "Secrets path prefix for ${var.deployment}/${var.name}"
  value       = "/${var.deployment}/concourse/pipelines/${var.name}"

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_secrets_kms_key_id" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_secrets_kms_key_id"

  type        = "String"
  description = "KMS key id for ${var.deployment}/${var.name}"
  value       = var.kms_key_id

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_egress_ips" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_egress_ips"

  type        = "String"
  description = "Egress IPs for ${var.deployment}/${var.name}"
  value       = join(",", var.egress_ips)

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_codecommit_pool_uri" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_codecommit_pool_uri"

  type        = "String"
  description = "Clone URI for codecommit pool repo ${var.deployment}/${var.name}"
  value       = "ssh://${
    replace(
      aws_codecommit_repository.pool_resource.clone_url_ssh,
      "ssh://",
      "${aws_iam_user_ssh_key.codecommit.ssh_public_key_id}@",
    )
  }"

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_codecommit_private_key" {
  name = "/${var.deployment}/concourse/pipelines/${var.name}/readonly_codecommit_private_key"

  type        = "String"
  description = "Clone URI for codecommit pool repo ${var.deployment}/${var.name}"
  value       = tls_private_key.codecommit.private_key_pem

  tags = {
    Deployment = var.deployment
  }
}
