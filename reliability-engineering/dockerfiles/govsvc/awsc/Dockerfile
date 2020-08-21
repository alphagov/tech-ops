FROM golang:1.12

ENV AWSC_VERSION 50283d253d3f5600dc53d5c1454a4ab7cbfccfe4
ENV GO111MODULE  on

RUN go get github.com/alphagov/awsc@$AWSC_VERSION

RUN apt-get update  --yes && \
    apt-get install --yes awscli jq

ENTRYPOINT ["bash"]
