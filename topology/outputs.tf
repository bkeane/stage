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

output "repositories" {
    value = var.repositories
}

output "action" {
    value = yamlencode(local.stages)
}