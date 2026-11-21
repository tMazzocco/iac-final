# Generate the SSH key

The container uses one dedicated key: `~/.ssh/iac_ed25519`. Create it once.

## Windows (PowerShell)

```powershell
New-Item -ItemType Directory -Force "$HOME\.ssh" | Out-Null
ssh-keygen -t ed25519 -f "$HOME\.ssh\iac_ed25519"
```

## Linux / macOS

```bash
mkdir -p ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/iac_ed25519
```

## Notes

- Create the key **before** the first `docker compose run`, otherwise Docker creates an empty folder in its place.
- Never commit or share the private key (`iac_ed25519`). Only the public key (`iac_ed25519.pub`) goes to AWS.
- Using another key: set `IAC_SSH_KEY` to its path.
