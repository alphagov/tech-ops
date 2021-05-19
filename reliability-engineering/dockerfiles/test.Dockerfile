# This empty dockerfile is used as a quick test that pushing to ECR works in
# the concourse-deployer pipeline
FROM ghcr.io/alphagov/paas/alpine:b11f2b9068cd492ffd3b33b9db54a1cf8ad136b3
RUN date
