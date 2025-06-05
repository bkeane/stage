# Stage

Stage provides a means to easily manage complex cross account OIDC based AWS role assumption within Github Actions Workflows. It assumes strong reliance on container based workflows via
ECR.

Stage provides:
  - Hub and Spoke cross-account ECR access.
  - A generated github action for cross-account AWS role assumption.

## Idea

Generally speaking CI/CD systems are RPC environments where we define a set of steps reprisentative of the idealized end of our local development flow.

The general categories of Continuous Integration and Continuous Deployment are defined by activity.

- Integration consists of unit testing, building and publishing artifacts from source code.
- Deployment is the set of activities required to bring those artifacts into production or service.

The problem is that these definitions provide little to no practical information. 

> "All bachelors are unmarried." - Kant

As Kant [points out](https://en.wikipedia.org/wiki/Analytic%E2%80%93synthetic_distinction) we learn nothing of bachelors here despite the superflous language. 

Similarly...

> "All integrations happen before deployments." - Bertrand Russell

...tells us nothing new.

## Paradigma

Instead of considering software pipelines from the self-evident order of activity they generally follow, it is far more useful a framework to think 
of a pipeline segmented into **stages** through a security lense. RPC systems are the stomping ground of overpriviledged and under-scrutinized software execution. A
place where secret material is presented to a rapidly changing landscape of needs-based-tooling reprisentative of supply chain vectors.

Stage proposes that software pipelines be architected primarily through access design and not by the self-evident phases of software in nature.

The End-to-End tests probably don't need to be able to overwrite oci images, and the build process probably doesn't need access to that `client_id` / `client_secret` pair.

Just as `kubectl apply` doesn't need `s3:DeleteObject` and the unit tests don't need access to a valid `~/.kube/config`.

The solution is to make easy the modeling and tractablility of priviledge given to the tooling we use.

## The Parts

### Topology Module

The topology module is only created in the account in which you wish to centralize your ECR repositories.

The topology module...
1. Creates ECR repositories.
1. Configures cross-account read access on ECR repositories.
1. Creates special `build` role under topology account.
1. Internally generates topological data contract for `stage` module.

example:
```terraform
resource "aws_ecr_repository" "weebler" {
  name = "widgetfactory/weebler/api"
}

resource "aws_ecr_repository" "wobbler" {
  name = "widgetfactory/wobbler/api"
}

module "topology" {
    source = "../../topology"
    origin = "https://github.com/bkeane/stage.git"

    # Account name to ID map.
    accounts = {
        "prod" = "677771948337"
        "dev" = "831926600600"
    }

    # Names of stages for all accounts.
    stages = [
        "deploy",
        "e2e"
    ]

    # ECR Image Paths.
    ecr_repositories = [
        aws_ecr_repository.weebler,
        aws_ecr_repository.wobbler
    ]
}

output "topology" {
    value = module.topology
}
```

### Stage Module

The stage module...
1. Creates a github assumable role.
1. Allows for the assignment of a policy to said role.
1. Allows for the assignment of a permissions boundary to said role.

example:
```terraform
# Within each account defined in `module.topology.accounts`...

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

data "terraform_remote_state" "ecr_account" {
  backend = "s3"
  config = {
    bucket  = "my-state-bucket"
    key     = "ecr_account/terraform.tfstate"
    region  = "us-west-2"
  }
}

module "deploy" {
    source = "../../stage"
    topology = data.terraform_remote_state.ecr_account.outputs.topology
    stage = "s3"
    policy_document = data.aws_iam_policy_document.eks_access
}

module "e2e" {
    source = "../../stage"
    topology = data.terraform_remote_state.ecr_account.outputs.topology
    stage = "s3"
    policy_document = data.aws_iam_policy_document.api_gateway_access
}
```

### Composite Actions

The composite actions output by `module.topology` provide a simple mechanism to setup these stages in a Github Actions workflow.

Within one's terraform...
```terraform
module "topology" {
    # ... As above
}

resource "local_file" "stages" {
  content = module.topology.action
  filename = "../../.github/actions/stages/action.yaml"
}
```

Within one's `.github/workflows/*.yaml`...
```yaml
name: Deploy

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  unit-test:
    runs-on: ubuntu-latest
    needs: build
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/stages
        with:
          stage: unit
          account: dev
          region: us-west-2

      # Insert unit test steps here

  deploy:
    runs-on: ubuntu-latest
    needs: unit-test
    permissions:
      id-token: write
      contents: read
    strategy:
      matrix:
        account:
          - prod
          - dev
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/stages
        with:
          stage: deploy
          account: ${{ matrix.account }}
          region: us-west-2

      # Insert deployment steps here
```

### The ECR Management Stage

As mentioned before, the topology module injects a single stage under the same account the topology module is applied. The name can be modified with the `ecr_stage_name` attribute and by default the stage is named `build`.

This role is to be used for read-write access to ECR. It should be used by build / push steps.

```yaml
      - uses: ./.github/actions/stages
        with:
          stage: build
          account: ecr-account
          region: us-west-2
```

Unlike other stages, this stage is not available in all accounts.
