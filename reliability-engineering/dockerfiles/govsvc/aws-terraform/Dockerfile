FROM hashicorp/terraform:1.2.0 as terraform
FROM ubuntu:20.04

LABEL terraform="1.2.0"

ARG APT_GET_DEPENDENCIES="\
 awscli \
 curl \
 dnsutils \
 git \
 jq \
 unzip \
"

RUN apt update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
RUN apt upgrade -y && TZ=Etc/UTC apt install --no-install-recommends -y ${APT_GET_DEPENDENCIES} && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

COPY --from=terraform /bin/terraform /bin/terraform

ENTRYPOINT ["bash"]
