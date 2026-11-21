FROM python:3.13-slim-bookworm

ARG TERRAFORM_VERSION=1.17.2
ARG AWSCLI_VERSION=2.42.1
ARG TFLINT_VERSION=0.66.0
ARG ANSIBLE_CORE_VERSION=2.22.0
ARG ANSIBLE_LINT_VERSION=26.11.0
ARG BOTO3_VERSION=1.44.9
# For the apple users
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip git openssh-client sshpass jq make less groff \
    && rm -rf /var/lib/apt/lists/*

#------- Terraform ----------
RUN set -eux; \
    cd /tmp; \
    curl -fsSLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip"; \
    curl -fsSLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS"; \
    grep "linux_${TARGETARCH}.zip" "terraform_${TERRAFORM_VERSION}_SHA256SUMS" | sha256sum -c -; \
    unzip -o "terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip" terraform -d /usr/local/bin; \
    rm -f /tmp/terraform_*; \
    terraform -version

# ---------- tflint ----------
RUN set -eux; \
    cd /tmp; \
    curl -fsSLO "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${TARGETARCH}.zip"; \
    unzip -o "tflint_linux_${TARGETARCH}.zip" tflint -d /usr/local/bin; \
    rm -f /tmp/tflint_*; \
    tflint --version

# ---------- AWS CLI ----------
RUN set -eux; \
    case "${TARGETARCH}" in \
    amd64) AWS_ARCH=x86_64 ;; \
    arm64) AWS_ARCH=aarch64 ;; \
    *) echo "Unsupported arch: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    cd /tmp; \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}-${AWSCLI_VERSION}.zip" -o awscliv2.zip; \
    unzip -q awscliv2.zip; \
    ./aws/install; \
    rm -rf /tmp/aws /tmp/awscliv2.zip; \
    aws --version

# ---------- Ansible + AWS SDK for Python ----------
RUN pip install --no-cache-dir \
    "ansible-core==${ANSIBLE_CORE_VERSION}" \
    "ansible-lint==${ANSIBLE_LINT_VERSION}" \
    "boto3==${BOTO3_VERSION}" \
    botocore

# Collections installed system-wide so the non-root user can use them
ENV ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible/collections
RUN ansible-galaxy collection install -p /usr/share/ansible/collections \
    amazon.aws community.general ansible.posix

# ---------- Non-root user ----------
RUN useradd --create-home --shell /bin/bash iac \
    && mkdir -p /work \
    && chown iac:iac /work

ENV ANSIBLE_HOST_KEY_CHECKING=False \
    ANSIBLE_FORCE_COLOR=1 \
    ANSIBLE_PRIVATE_KEY_FILE=/home/iac/.ssh/id_iac \
    TF_PLUGIN_CACHE_DIR=/home/iac/.terraform.d/plugin-cache

USER iac
# ~/.ssh created here (owned by iac) so known_hosts stays writable when a
# single key file is bind-mounted inside it
RUN mkdir -p /home/iac/.terraform.d/plugin-cache \
    && mkdir -m 700 /home/iac/.ssh
WORKDIR /work

CMD ["/bin/bash"]
