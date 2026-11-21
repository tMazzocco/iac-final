# IaC tools container

One Docker image with everything needed to run the project. No tool to install on the host except Docker.

## Content

| Tool | Version |
|---|---|
| Base image | `python:3.13-slim-bookworm` (Debian 12) |
| Python | 3.13 |
| Terraform | 1.17.2 |
| tflint | 0.66.0 |
| AWS CLI | 2.42.1 |
| ansible-core | 2.22.0 |
| ansible-lint | 26.11.0 |
| boto3 | 1.44.9 |
| Ansible collections | `amazon.aws`, `community.general`, `ansible.posix` (latest at build time) |
| Utilities | git, openssh-client, sshpass, jq, make, curl, unzip |

Versions are set as `ARG` at the top of the `Dockerfile`.

The container runs as the non-root user `iac`, with all Linux capabilities dropped.

## Prerequisites

1. Docker Desktop (Windows / macOS) or Docker Engine + Compose (Linux).
2. The SSH key `~/.ssh/iac_ed25519`, see [ssh-gen.md](ssh-gen.md).
3. The `~/.aws` folder with your credentials (one-time setup below).

Both the key and `~/.aws` must exist **before** the first run, otherwise Docker creates empty folders in their place.

## First setup (once)

Run from the project folder.

**Windows (PowerShell)**

```powershell
New-Item -ItemType Directory -Force "$HOME\.aws" | Out-Null
docker compose build
docker run --rm -it -v "${HOME}\.aws:/home/iac/.aws" iac-tools aws configure
```

**Linux / macOS**

```bash
mkdir -p ~/.aws
docker compose build
docker run --rm -it -v ~/.aws:/home/iac/.aws iac-tools aws configure
```

## Usage

The container stays running in the background; commands run inside it with `exec`.

```bash
docker compose up -d                              # start (once per session)
docker compose exec iac bash                      # interactive shell
docker compose exec iac terraform plan            # single command
docker compose exec iac ansible-playbook site.yml
docker compose down                               # stop
```

- Mounted files (project, key, AWS) are live: host edits are visible immediately, no restart needed.
- Restart (`down` then `up -d`) only after changing a mount, `IAC_SSH_KEY` or `AWS_PROFILE`.
- After changing the `Dockerfile`: `docker compose up -d --build`.
- Anything written outside `/work` is lost on `down`.

## Mounts

| Host | Container | Mode |
|---|---|---|
| project folder | `/work` | read/write |
| `~/.aws` | `/home/iac/.aws` | read-only |
| `~/.ssh/iac_ed25519` | `/home/iac/.ssh/id_iac` | read-only |

Only this one SSH key is mounted, never the whole `~/.ssh`. Ansible uses it automatically.

## Options

| Variable | Default | Purpose |
|---|---|---|
| `IAC_SSH_KEY` | `~/.ssh/iac_ed25519` | Use another private key |
| `AWS_PROFILE` | `default` | Use another AWS profile |
