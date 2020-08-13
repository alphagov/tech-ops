FROM concourse/concourse-pipeline-resource
RUN apk update && apk add jq py3-pip
RUN pip3 install yq

