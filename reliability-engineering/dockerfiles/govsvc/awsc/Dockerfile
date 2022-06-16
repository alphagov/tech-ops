FROM golang:1.18

ENV AWSC_VERSION 50283d253d3f5600dc53d5c1454a4ab7cbfccfe4

RUN go install github.com/alphagov/awsc@$AWSC_VERSION

RUN apt-get update  --yes && \
    apt-get install --yes awscli jq

ENTRYPOINT ["bash"]
