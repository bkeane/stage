variable "origin" {
    description = "git remote origin https:// url"
    type = string

    validation {
        condition = can(regex("^https://github.com/.+/.+", var.origin))
        error_message = "Origin must be a valid GitHub URL"
    }
}

variable "accounts" {
    description = "Map of account names to account ids"
    type = map(string)

    validation {
        condition = alltrue([
            for id in values(var.accounts) :
            can(regex("^\\d{12}$", id))
        ])
        error_message = "All account IDs must be 12-digit AWS account IDs"
    }
}

variable "ecr_stage_name" {
    description = "ECR stage name"
    type = string
    default = "build"
}

variable "stages" {
    description = "List of stage names"
    type = set(string)
}

variable "repositories" {
    description = "List of ECR repository paths"
    type = set(string)
}


