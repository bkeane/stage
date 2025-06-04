variable "topology" {
    description = "topology"
    type = object({
        accounts = map(string)
        account_lookup = map(string)
        git = object({
            repo = string
            owner = string
            path = string
            origin = string
        })
        resources = map(map(object({
            role_name = string
            role_arn = string
            policy_name = string
            policy_arn = string
            permissions_boundary_name = string
            permissions_boundary_arn = string
        })))
        ecr_repositories = set(object({
            arn = string
            repository_url = string
        }))
        oidc = object({
            subject_claim = string
        })
    })
}

variable "stage" {
    description = "stage name"
    type = string
}

variable "policy_document" {
    description = "policy document"
    type = object({
        json = optional(string, "")
        minified_json = optional(string, "")
    })
}

variable "permissions_boundary" {
    description = "permissions boundary policy document"
    default = {
        json = ""
        minified_json = ""
    }
    type = object({
        json = optional(string, "")
        minified_json = optional(string, "")
    })
}