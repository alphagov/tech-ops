ARG ubuntu_digest
ARG terraform_digest
ARG terraform_version

FROM hashicorp/terraform@${terraform_digest} as terraform
FROM ubuntu@${ubuntu_digest}

LABEL terraform="${terraform_version}"

RUN apt-get update  --yes && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes awscli jq curl dnsutils unzip git

WORKDIR /tmp

COPY --from=terraform /bin/terraform /bin/terraform

ENTRYPOINT ["bash"]
