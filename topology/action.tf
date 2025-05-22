locals {
  validate = file("${path.module}/scripts/validate.js")

  build_stage = {
    name = "ecr stage"
    description = ""

    runs = {
      using = "composite"
      steps = [
        {
          name = "assume role"
          id = "assume-role"
          uses = "aws-actions/configure-aws-credentials@v2"
          with = {
            role-to-assume = aws_iam_role.ecr_stage.arn
            role-session-name = "${local.git.repo}-ecr-session"
            aws-region = local.account_region
          }
        },
        {
          name = "ecr login"
          id = "ecr-login"
          uses = "aws-actions/amazon-ecr-login@v2"
        }
      ]
    }
  }

  stages = {
    name        = "setup stage"
    description = ""

    inputs = {
      stage = {
        description = "name of the stage"
        required = true
        type     = "string"
      }
      account = {
        description = "name of the account"
        required = true
        type     = "string"
      }
      region = {
        description = "region of the account"
        required = false
        type     = "string"
        default = local.account_region
      }
    }

    outputs = {
      role_arn = {
        description = "role arn for stage"
        value = "$${{ steps.validation.outputs.role_arn }}"
      }
    }

    runs = {
      using = "composite"
      steps = [
        {
          name = "validation"
          id   = "validation"
          env = {
            RESOURCES = jsonencode(local.resources)
          }
          uses = "actions/github-script@v7"
          with = {
            script = local.validate
          }
        },
        {
          name = "assume role"
          id = "assume-role"
          uses = "aws-actions/configure-aws-credentials@v2"
          with = {
            role-to-assume = "$${{ steps.validation.outputs.role_arn }}"
            role-session-name = "$${{ inputs.account }}-$${{ inputs.stage }}-session"
            aws-region = "$${{ inputs.region }}"
          }
        }
      ]
    }
  }
}

