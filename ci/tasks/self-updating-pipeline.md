## Self updating pipeline

The intention is for the pipelines to be able to self update.

The task will validate the pipeline before applying.

### Parameters

| Parameter | Description | Required | Default |
|---|---|---|---|
| CONCOURSE_TEAM | Concourse team the pipeline will be applied to. Will also be used as the username. | Yes | N/A |
| CONCOURSE_USERNAME | Concourse username authenticating the task with fly cli. | No | `${CONCOURSE_TEAM}` |
| CONCOURSE_PASSWORD | Concourse password authenticating the task with fly cli. | Yes | N/A |
| PIPELINE_PATH | Path to the pipeline YAML file withing your repository. | Yes | N/A |
| PIPELINE_NAME | Name for the pipeline to be written into Concourse. | Yes | N/A |
| CONCOURSE_URL | Concourse URL to target for interaction via fly cli. | No | `https://cd.gds-reliability.engineering` |

### Usage

Minimal setup:

```yaml
resources:
  - name: tech-ops
    type: git
    source:
      uri: https://github.com/alphagov/tech-ops.git

  - name: my-pipelines
    type: git
    source:
      uri: https://github.com/example/my-pipelines.git

jobs:
- name: self-update
  serial: true
  plan:
  - get: tech-ops
  - get: my-pipelines
    trigger: true
  - task: set-pipelines
    file: tech-ops/ci/tasks/self-updating-pipeline.yaml
    input_mapping: {repository: my-pipelines}
    params:
      CONCOURSE_TEAM: my-team
      CONCOURSE_PASSWORD: ((readonly_local_user_password))
      PIPELINE_PATH: ci/deploy.yaml
      PIPELINE_NAME: deploy
```
