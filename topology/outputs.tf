output "git" {
    value = local.git
}

output "oidc" {
    value = local.oidc
}

output "accounts" {
    value = var.accounts
}

output "resources" {
    value = local.resources
}

output "ecr_action" {
    value = yamlencode(local.build_stage)
}

output "stage_action" {
    value = yamlencode(local.stages)
}