terraform {
  required_providers {
    corefunc = {
      source  = "northwood-labs/corefunc"
      version = "~> 1.0"
    }
  }
}

locals {
    // Account Information
    account_id = data.aws_caller_identity.current.account_id
    account_ids = toset([ for id in values(var.accounts) : id ])
    account_region = data.aws_region.current.name

    // Git Information
    repo_path = replace(data.corefunc_url_parse.origin.path, ".git", "")
    repo_path_parts = compact(split("/", local.repo_path))
    git = {
        origin = var.origin
        path   = local.repo_path
        repo   = local.repo_path_parts[1]
        owner  = local.repo_path_parts[0]
    }

    // Push Role
    ecr_stage = {
      role_name = "${local.git.repo}-push-role"
      role_arn = "arn:aws:iam::${local.account_id}:role/${local.git.repo}-push-role"
      policy_name = "${local.git.repo}-push-policy"
      policy_arn = "arn:aws:iam::${local.account_id}:policy/${local.git.repo}-push-policy"
    }

    // OIDC
    oidc = {
      subject_claim = "repo:${local.git.owner}/${local.git.repo}:*"
    }

    // Resources
    resources = merge({
      for account, id in var.accounts: account => {
        for stage in var.stages: stage => {
          role_name = "${local.git.repo}-${stage}-role"
          role_arn = "arn:aws:iam::${id}:role/${local.git.repo}-${stage}-role"
          policy_name = "${local.git.repo}-${stage}-policy"
          policy_arn = "arn:aws:iam::${id}:policy/${local.git.repo}-${stage}-policy"
          permissions_boundary_name = "${local.git.repo}-${stage}-permissions-boundary"
          permissions_boundary_arn = "arn:aws:iam::${id}:policy/${local.git.repo}-${stage}-permissions-boundary"
        }
      }
    })
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "corefunc_url_parse" "origin" {
  url = var.origin
}

data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
}