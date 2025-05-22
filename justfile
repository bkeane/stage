# tofu apply prod and dev
apply:
    AWS_PROFILE=prod.kaixo.io tofu -chdir=e2e/prod apply
    AWS_PROFILE=dev.kaixo.io tofu -chdir=e2e/dev apply

# tofu destroy prod and dev
destroy:
    AWS_PROFILE=dev.kaixo.io tofu -chdir=e2e/dev destroy
    AWS_PROFILE=prod.kaixo.io tofu -chdir=e2e/prod destroy