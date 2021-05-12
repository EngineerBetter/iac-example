# ubuntu:hirsute
FROM ubuntu@sha256:9a5cc8359b220b9414e4dc6ec992f867b33f864c560a1e198fb833f98b8f7f3c

RUN \
  apt update \
  && DEBIAN_FRONTEND=noninteractive \
    apt install --yes \
      git \
      wget \
      unzip \
      gnupg2 \
      build-essential \
  && rm -rf /var/lib/apt/lists/*

RUN \
  apt update \
  && DEBIAN_FRONTEND=noninteractive \
    apt install --yes awscli \
  && rm -rf /var/lib/apt/lists/*

RUN \
  wget \
    -O /terraform.zip \
    https://releases.hashicorp.com/terraform/0.15.4/terraform_0.15.4_linux_amd64.zip \
  && unzip /terraform.zip \
  && rm /terraform.zip \
  && chmod +rx /terraform \
  && mv /terraform /usr/local/bin/terraform

RUN \
  wget \
    -O /usr/local/bin/aws-iam-authenticator \
    https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator \
  && chmod +rx /usr/local/bin/aws-iam-authenticator

RUN \
  wget \
    -O /usr/local/bin/kubectl \
    https://dl.k8s.io/release/v1.21.1/bin/linux/amd64/kubectl \
  && chmod +rx /usr/local/bin/kubectl

RUN \
  wget \
    -O /tflint.zip \
    https://github.com/terraform-linters/tflint/releases/download/v0.28.1/tflint_linux_amd64.zip \
  && unzip /tflint.zip \
  && rm /tflint.zip \
  && chmod +rx /tflint \
  && mv /tflint /usr/local/bin/tflint

RUN \
  wget \
    -O /usr/local/bin/snyk \
    https://github.com/snyk/snyk/releases/download/v1.616.0/snyk-linux \
  && chmod +rx /usr/local/bin/snyk