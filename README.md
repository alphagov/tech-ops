# alphagov/tech-ops

## Building and Releasing GovSVC Docker containers.

Building and releasing the GovSVC specific Docker images is done by a set of Github actions attached to this repo.

They will run automatically if a change is made to the corresponding dockerfile, or they can be triggered manually through the Github Actions UI.

Pipeline runs will have to be approved by a trusted person that is in the `re-autom8` or `reliability-engineering` Github teams.

### Docker Images
#### AWSC
[:rocket: Github Action](https://github.com/alphagov/tech-ops/actions/workflows/build_govsvc_docker_awsc.yml)
[:octocat: GHCR Repo](https://github.com/orgs/alphagov/packages/container/package/awsc)
[:whale: Dockerhub Repo](https://hub.docker.com/r/govsvc/awsc)

#### AWS Terraform
[:rocket: Github Action](https://github.com/alphagov/tech-ops/actions/workflows/build_govsvc_docker_aws_terraform.yml)
[:octocat: GHCR Repo](https://github.com/orgs/alphagov/packages/container/package/aws-terraform)
[:whale: Dockerhub Repo](https://hub.docker.com/r/govsvc/aws-terraform)

#### AWS Ruby
[:rocket: Github Action](https://github.com/alphagov/tech-ops/actions/workflows/build_govsvc_docker_aws_ruby.yml)
[:octocat: GHCR Repo](https://github.com/orgs/alphagov/packages/container/package/aws-ruby)
[:whale: Dockerhub Repo](https://hub.docker.com/r/govsvc/aws-ruby)

#### OctoDNS
[:rocket: Github Action](https://github.com/alphagov/tech-ops/actions/workflows/build_govsvc_docker_octodns.yml)
[:octocat: GHCR Repo](https://github.com/orgs/alphagov/packages/container/package/octodns)
[:whale: Dockerhub Repo](https://hub.docker.com/r/govsvc/octodns)

#### Autom8 Task Toolbox
[:rocket: Github Action](https://github.com/alphagov/tech-ops/actions/workflows/build_govsvc_docker_concourse_task_toolbox.yml)
[:octocat: GHCR Repo](https://github.com/orgs/alphagov/packages/container/package/automate%2Ftask-toolbox)
[:whale: Dockerhub Repo](https://hub.docker.com/r/govsvc/task-toolbox)