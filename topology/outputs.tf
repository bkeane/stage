output "git" {
    value = local.git
}

output "oidc" {
    value = local.oidc
}

output "accounts" {
    value = var.accounts
}

output "account_lookup" {
    value = local.account_lookup
}

output "resources" {
    value = local.resources
}

output "ecr_repositories" {
    value = var.ecr_repositories
}

output "action" {
    value = yamlencode(local.stages)
}