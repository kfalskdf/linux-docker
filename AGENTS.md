# AGENTS.md - Agent Coding Guidelines

This file provides guidelines for agentic coding agents operating in this repository.

## Project Overview

This is a **Docker-based Linux environment** project. It builds a Debian 12 slim container with SSH access and pre-installed networking tools (cloudflared, EasyTier, gost). The project is primarily infrastructure-as-code with a Dockerfile and GitHub Actions workflow.

- **Primary file**: `Dockerfile` - defines the container image
- **CI/CD**: `.github/workflows/docker-publish.yml` - builds and pushes to GHCR

---

## Build, Lint, and Test Commands

### Building the Docker Image

```bash
# Build locally
docker build -t linux-docker:latest .

# Build with custom password
docker build --build-arg DEFAULT_PASSWORD=YourPassword -t linux-docker:custom .

# Build with BuildKit (faster)
DOCKER_BUILDKIT=1 docker build -t linux-docker:latest .
```

### Running the Container

```bash
docker run -d -p 2222:22 --name linux-docker linux-docker:latest
ssh kfal@localhost -p 2222  # password: Debian2026
```

### Linting

Use hadolint for Dockerfile linting:

```bash
# Install (Windows with scoop)
scoop install hadolint

# Lint
hadolint Dockerfile

# Or via Docker
docker run --rm -i hadolint/hadolint < Dockerfile
```

### Testing

There are **no traditional unit tests**. Testing is manual container verification:

```bash
docker build -t linux-docker:test .
docker run -d --name test-container linux-docker:test
docker exec test-container which cloudflared
docker exec test-container which easytier
docker exec test-container which gost
docker exec test-container id kfal
docker stop test-container && docker rm test-container
```

### CI/CD Commands

```bash
gh workflow run docker-publish.yml
gh run list --workflow=docker-publish.yml
```

---

## Code Style Guidelines

### Dockerfile Conventions

1. **Base Image**: Use specific tags (e.g., `debian:12-slim`, not `debian:latest`)
2. **Layer Ordering**: Put less frequently changing layers first for better caching
3. **Cleanup**: Always clean up apt caches:
   ```dockerfile
   RUN apt-get update && apt-get install -y ... && \
       apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
   ```
4. **Non-root User**: Run as non-root user (kfal) for security
5. **Exposed Ports**: Document all exposed ports with comments

### Shell Scripting (if added)

- Use `#!/bin/bash` with `set -euo pipefail`
- Use double quotes for variable expansion: `"$VAR"`
- Use `$(command)` instead of backticks

### Git Commit Messages

Follow conventional commits: `feat:`, `fix:`, `docs:`, `ci:`

### YAML (GitHub Actions)

- Use 2-space indentation
- Add comments for non-obvious steps
- Use latest action versions (e.g., `actions/checkout@v4`)

---

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Docker image | lowercase, hyphenated | `linux-docker` |
| Git branches | kebab-case | `feature/add-tool` |
| Git tags | v-prefixed semver | `v1.0.0` |
| Variables (Dockerfile) | UPPER_SNAKE_CASE | `DEFAULT_PASSWORD` |
| Workflow jobs | kebab-case | `build-and-push` |

---

## Error Handling

### Dockerfile

- Chain commands with `&&` to fail on any error
- Use `--no-install-recommends` with apt-get to minimize image size
- Verify downloads when possible

### GitHub Actions

- Use `if: ${{ success() }}` or `if: ${{ failure() }}` for conditional steps
- Set appropriate permissions in workflow

---

## Security Considerations

1. **Never commit secrets** - use GitHub Secrets for passwords
2. **Use specific versions** - avoid `latest` tags for production
3. **Non-root user** - always run as non-root in containers
4. **Minimal base image** - use slim variants when possible
5. **SSH keys** - generate with `ssh-keygen -A` for container

---

## File Structure

```
.
├── Dockerfile
├── AGENTS.md
└── .github/workflows/docker-publish.yml
```

---

## Common Tasks

### Adding a New Tool

1. Add download commands in Dockerfile (before verification step)
2. Add EXPOSE port if needed
3. Update this AGENTS.md
4. Test locally with `docker build` and `docker run`

### Updating a Tool Version

1. Update the download URL in Dockerfile
2. Test the new version in container
3. Commit: `fix: update <tool> to vX.X.X`

### Releasing a New Version

```bash
git tag v1.0.0
git push origin v1.0.0
```

This triggers the CI workflow to build and push to GHCR.

---

## Notes for Agents

- This is a **Docker-only project** - no JavaScript, Python, or other application code
- All "tests" are manual container verification
- Default SSH password: `Debian2026` (configurable via build arg)
- User `kfal` has sudo NOPASSWD access
- Tools installed: cloudflared, EasyTier, gost