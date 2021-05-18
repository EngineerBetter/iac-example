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

# System test requirements
RUN wget \
    -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub \
    | apt-key add - \
  && echo \
    "deb http://dl.google.com/linux/chrome/deb/ stable main" \
    >> /etc/apt/sources.list.d/google.list \
  && apt update --yes \
  && DEBIAN_FRONTEND=noninteractive \
    apt install --yes google-chrome-stable golang build-essential \
  && rm -rf /var/lib/apt/lists/* \
  && wget -q \
    -O /tmp/chromedriver_linux64.zip \
    https://chromedriver.storage.googleapis.com/90.0.4430.24/chromedriver_linux64.zip \
  && unzip /tmp/chromedriver_linux64.zip \
  && rm /tmp/chromedriver_linux64.zip \
  && chmod +rx ./chromedriver \
  && mv ./chromedriver /usr/local/bin/chromedriver \
  && mkdir /go && chmod a+rwx /go \
  && mkdir /gocache && chmod a+rwx /gocache

ENV GOCACHE /gocache

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
    -O /tmp/conftest_0.25.0_Linux_x86_64.tar.gz \
    https://github.com/open-policy-agent/conftest/releases/download/v0.25.0/conftest_0.25.0_Linux_x86_64.tar.gz \
  && tar xzf /tmp/conftest_0.25.0_Linux_x86_64.tar.gz  --directory=/tmp \
  && mv /tmp/conftest /usr/local/bin/conftest \
  && chmod +rx /usr/local/bin/conftest \
  && rm /tmp/conftest_0.25.0_Linux_x86_64.tar.gz

RUN \
  wget \
    -O /usr/local/bin/snyk \
    https://github.com/snyk/snyk/releases/download/v1.616.0/snyk-linux \
  && chmod +rx /usr/local/bin/snyk

RUN \
  wget \
    -O /usr/local/bin/yq \
    https://github.com/mikefarah/yq/releases/download/v4.9.1/yq_linux_amd64 \
  && chmod +rx /usr/local/bin/yq
