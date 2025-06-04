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
    account_lookup = {
      for name, id in var.accounts: id => name
    }

    // Git Information
    repo_path = replace(data.corefunc_url_parse.origin.path, ".git", "")
    repo_path_parts = compact(split("/", local.repo_path))
    git = {
        origin = var.origin
        path   = local.repo_path
        repo   = local.repo_path_parts[1]
        owner  = local.repo_path_parts[0]
    }

    // OIDC
    oidc = {
      subject_claim = "repo:${local.git.owner}/${local.git.repo}:*"
    }

    // Build base resources map for all accounts and stages
    stage_resources = {
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
    }

    // ECR Management Stage
    ecr_mgmt_resource = {
      "${local.account_lookup[local.account_id]}" = {
        "${var.ecr_stage_name}" = {
          role_name = "${local.git.repo}-ecr-mgmt-role"
          role_arn = "arn:aws:iam::${local.account_id}:role/${local.git.repo}-ecr-mgmt-role"
          policy_name = "${local.git.repo}-ecr-mgmt-policy"
          policy_arn = "arn:aws:iam::${local.account_id}:policy/${local.git.repo}-ecr-mgmt-policy"
          permissions_boundary_name = "${local.git.repo}-ecr-mgmt-permissions-boundary"
          permissions_boundary_arn = "arn:aws:iam::${local.account_id}:policy/${local.git.repo}-ecr-mgmt-permissions-boundary"
        }
      }
    }

    resources = module.merged_stages.merged
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "corefunc_url_parse" "origin" {
  url = var.origin
}

data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

module "merged_stages" {
  source  = "Invicton-Labs/deepmerge/null"
  version = "0.1.5"
  maps = [
    local.stage_resources,
    local.ecr_mgmt_resource
  ]
}