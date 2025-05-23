# Stage

Stage provides a means to easily manage cross account OIDC based AWS role assumption. 

## Idea

Generally speaking CI/CD systems are RPC environments where we define a set of steps reprisentative of the idealized end of our local development flow.

The general categories of Continuous Integration and Continuous Deployment are defined by activity.

- Integration consists of unit testing, building and publishing artifacts from source code.
- Deployment is the set of activities required to bring those artifacts into production or service.

The problem is that these definitions provides little to no practical information. 

> "All bachelors are unmarried." - Kant

As Kant [points out](https://en.wikipedia.org/wiki/Analytic%E2%80%93synthetic_distinction) we learn nothing of bachelors here despite the superflous language. 

Similarly...

> "All integrations happen before deployments." - Bertrand Russell

...tells us nothing new.

## Paradigma

Instead of considering software pipelines from the self-evident order of activity they generally follow, it is far more useful a framework to think 
of a pipelines' **stages** from a security lense. RPC systems are stomping ground of overpriviledged and under-scrutinized software execution.

What this leads to more often than not is the presentation of secret material in a rather intractable fashion to a multitude of quickly chosen tooling.

Some companies choose to solve this supply chain vector through the constraint of tooling via committee; a universally disliked approach due to mixed directives.
Move as quickly as possible, but also don't forget to pass through the eye of that needle over there.

Stage proposes that software pipelines be architected primarily through access design and not by the self-evident phases of software in nature.

The End-to-End tests probably don't need to be able to push new oci images, and the build process probably doesn't need access to that `client_id` / `client_secret` pair.

Just as `kubectl apply` doesn't need `s3:DeleteObject` and the unit tests don't need access to a valid `~/.kube/config`.

The solution is to make easy and tractable the priviledge given to the tooling we use.

### Topology Module

The topology module...
1. Creates ECR repositories.
1. Configures cross-account read access on ECR repositories.
1. Internally generates topological contract for `stage` module.

example:
```terraform
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
    repositories = [
        "widgetfactory/weebler/api",
        "widgetfactory/wobbler/api"
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
  content = module.topology.stage_action
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
    strategy:
      matrix:
        account:
          - prod
          - dev
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
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
        with:
          fetch-depth: 0
      - uses: ./.github/actions/stages
        with:
          stage: deploy
          account: ${{ matrix.account }}
          region: us-west-2

      # Insert deployment steps here
```
