# SendItCycles GitOps - Infrastructure as Code

This repository demonstrates **GitOps best practices** for managing the SendItCycles e-commerce application across multiple environments (dev, staging, production). Every infrastructure change is version-controlled, reviewed, and automatically deployed.

## What is GitOps?

GitOps is a set of practices where:
- **Git is the single source of truth** for desired infrastructure state
- **All changes are tracked** as commits (full audit trail)
- **Pull requests enable review** before deployment
- **Automation handles deployment** (no manual clicks)
- **Easy rollback** via git revert + push

## Repository Structure

```
senditcycles-ops/
├── environments/
│   ├── dev/                          # Development environment
│   │   ├── docker-compose.yml       # Dev container orchestration
│   │   ├── .env.dev                 # Dev configuration (secrets in CI/CD)
│   │   └── config/
│   ├── staging/                      # Staging (pre-production QA)
│   │   ├── docker-compose.yml       # Staging container orchestration
│   │   ├── .env.staging             # Staging config
│   │   └── config/
│   └── prod/                         # Production environment
│       ├── docker-compose.yml       # Prod container orchestration
│       ├── .env.prod                # Prod config (secrets via GitHub)
│       └── config/
├── scripts/
│   └── deploy.sh                     # Deployment automation script
├── .github/
│   └── workflows/
│       └── deploy.yml                # GitHub Actions GitOps pipeline
└── README.md                         # This file
```

## How It Works: The GitOps Flow

### 1. Developer Makes Changes

```bash
# Developer updates configuration in dev environment
git checkout -b feature/update-api-version
vim environments/dev/docker-compose.yml  # Update image version
git commit -m "Upgrade API to v2.1.0"
git push origin feature/update-api-version
```

### 2. Pull Request Review

- Create PR in GitHub
- Team reviews infrastructure changes
- Automated validation checks:
  - ✅ YAML syntax validation
  - ✅ Docker Compose config validation
  - ✅ Environment variables completeness

### 3. Merge & Auto-Deploy

When PR is merged to `main`:

```
Git Push to Main
      ↓
GitHub detects change in environments/**
      ↓
Workflow Triggered: .github/workflows/deploy.yml
      ↓
VALIDATE STAGE
  ├─ Validate docker-compose syntax
  ├─ Verify environment files exist
  └─ Check configuration completeness
      ↓
DEPLOY STAGE (Automatic progression)
  ├─ Deploy-Dev
  │  └─ Build & run dev environment
  │
  ├─ Deploy-Staging  (depends on Dev success)
  │  └─ Build & run staging with secrets from GitHub
  │
  └─ Deploy-Prod     (depends on Staging success)
     ├─ Create GitHub deployment record
     ├─ Build & run prod with secrets from GitHub
     ├─ Create deployment status
     └─ Notify Slack of success
      ↓
AUDIT LOG
  └─ Record deployment for compliance
```

## Configuration Management

### Environment-Specific Settings

Each environment has distinct configurations:

**Development** (`environments/dev/docker-compose.yml`):
- Uses local volumes for code changes
- Exposes all ports for debugging
- Verbose logging enabled
- Dev credentials in `.env.dev`

**Staging** (`environments/staging/docker-compose.yml`):
- Production-like setup with health checks
- Automatic restart on failure
- Secrets from GitHub Secrets
- Performance-tuned settings

**Production** (`environments/prod/docker-compose.yml`):
- High availability configuration
- Database backups configured
- Minimal logging (security)
- All secrets from GitHub Secrets only

### Secret Management (Critical!)

**Never commit secrets to this repository.**

Secrets are injected via GitHub Actions:

```yaml
# .github/workflows/deploy.yml
- name: Deploy to staging
  env:
    DB_PASSWORD_STAGING: ${{ secrets.STAGING_DB_PASSWORD }}
    JWT_SECRET_STAGING: ${{ secrets.STAGING_JWT_SECRET }}
```

**Setup GitHub Secrets:**
1. Go to repository Settings → Secrets → Actions
2. Add required secrets:
   - `STAGING_DB_PASSWORD`
   - `STAGING_JWT_SECRET`
   - `PROD_DB_PASSWORD`
   - `PROD_JWT_SECRET`
   - `DOCKER_USERNAME` (optional, for Docker Hub)
   - `DOCKER_PASSWORD` (optional)
   - `SLACK_WEBHOOK` (optional, for notifications)

## Running Deployments Locally

### Deploy to Dev (No secrets needed)

```bash
cd senditcycles-ops
./scripts/deploy.sh dev deploy
```

### Validate Environment Config

```bash
./scripts/deploy.sh dev validate
./scripts/deploy.sh staging validate
./scripts/deploy.sh prod validate
```

### Rollback Environment

```bash
./scripts/deploy.sh staging rollback
# Then make changes to git and push to re-deploy
```

## Making Changes: Step-by-Step

### Example: Upgrade Backend Service in Staging

```bash
# 1. Create feature branch
git checkout -b upgrade/backend-v2-1-0

# 2. Make change to docker-compose
vim environments/staging/docker-compose.yml
# Change: image: backend:2.0.0 → image: backend:2.1.0

# 3. Test locally (optional)
cd environments/staging
docker-compose config  # Validate syntax
docker-compose build   # Build containers

# 4. Commit with clear message
git add environments/staging/docker-compose.yml
git commit -m "feat: upgrade backend service to v2.1.0 in staging

- Update image tag from 2.0.0 to 2.1.0
- Includes bug fixes and performance improvements
- Requires 2 GB additional memory"

# 5. Push and create PR
git push origin upgrade/backend-v2-1-0
# Create PR in GitHub web interface

# 6. Team reviews change

# 7. Merge to main (via GitHub UI)
# GitHub Actions automatically:
# - Validates configuration
# - Deploys to dev
# - Deploys to staging with new backend v2.1.0
# - Deploys to prod (if you merge to prod branch)
```

## CI/CD Pipeline Details

### Validation Stage

Runs on every push and PR:
- ✅ Docker Compose YAML syntax
- ✅ Environment file presence
- ✅ No required secrets in repo

### Progressive Deployment

Each environment automatically triggers the next on success:

1. **Dev** deploys immediately
2. **Staging** waits for dev success
3. **Prod** waits for staging success (with approval)

### Production Safeguards

Production deployment includes:
- ✅ Required approval (GitHub environment protection rule)
- ✅ Audit logging (who, what, when)
- ✅ Slack notifications
- ✅ GitHub deployment records
- ✅ Deployment status tracking

## Monitoring & Audit Trail

### View Deployment History

1. Go to GitHub: **Actions** tab
2. Click **GitOps Deployment Pipeline**
3. See all deployments with:
   - Status (✅ success, ❌ failed)
   - Timestamp
   - Author
   - Commit message
   - Logs (click on specific jobs)

### View Git History

```bash
# See infrastructure changes
git log --oneline environments/

# See specific environment changes
git log --oneline environments/prod/

# See who changed what and when
git log -p environments/staging/docker-compose.yml

# Show diff between commits
git diff <commit1> <commit2> environments/
```

### Revert a Deployment

If something goes wrong:

```bash
# Find the bad commit
git log --oneline

# Revert it
git revert <commit-hash>

# Push to trigger automatic rollback
git push origin main

# GitHub Actions automatically re-deploys with previous config
```

## Security Best Practices

✅ **This repository demonstrates:**
- No secrets in Git
- Environment-specific configs
- Signed commits (recommended)
- Branch protection rules (recommended)
- Audit logging
- Role-based access (recommended)

### Recommended GitHub Settings

1. **Require PR reviews** before merge to main
2. **Require status checks** to pass (CI/CD validation)
3. **Restrict who can approve** production deployments
4. **Enable branch protection** on main
5. **Require signed commits** for production changes

## Troubleshooting

### Deployment Failed

1. Check GitHub Actions logs:
   - Go to Actions → recent run → job details
   - Look for validation or build errors

2. Common issues:
   ```bash
   # YAML syntax error
   docker-compose -f environments/dev/docker-compose.yml config
   
   # Port conflict
   docker ps  # Check what's running
   
   # Missing environment variable
   grep '\${' environments/*/docker-compose.yml  # Find all vars
   ```

### Secrets Not Available

1. Verify secrets are set in GitHub:
   - Settings → Secrets → Actions
   - Check secret names match workflow exactly

2. Secrets only available to:
   - Main branch
   - PR from same repository (not forks)

### Container Won't Start

1. Check logs:
   ```bash
   docker-compose -f environments/dev/docker-compose.yml logs backend
   ```

2. Verify health checks:
   ```bash
   docker-compose -f environments/dev/docker-compose.yml ps
   ```

## Advanced Topics

### Adding a New Environment

1. Create folder: `environments/newenv/`
2. Copy from existing: `cp -r environments/dev/* environments/newenv/`
3. Modify `.env.newenv` and `docker-compose.yml`
4. Add to GitHub Actions workflow: `.github/workflows/deploy.yml`
5. Commit and push

### Custom Pre-Deployment Checks

Edit `.github/workflows/deploy.yml` validation stage:

```yaml
- name: Run custom health checks
  run: |
    ./scripts/health-check.sh staging
    ./scripts/security-scan.sh environments/prod
```

### Database Migrations

Add to `environments/<env>/docker-compose.yml`:

```yaml
migrations:
  image: backend:latest
  command: npm run migrate
  environment:
    DB_HOST: postgres
  depends_on:
    postgres:
      condition: service_healthy
```

## Gartner Demo Script

**Problem**: "How do you manage infrastructure changes safely?"

**Solution**: "We use GitOps. Every change is in Git, reviewed before deployment, and automatically deployed."

**Demo Steps**:
1. Show `senditcycles-ops` repo structure
2. Make a change: `git checkout -b demo/upgrade-api && vim environments/dev/docker-compose.yml`
3. Update API version or replica count
4. `git commit -m "Update backend version"` and `git push`
5. Create a PR in GitHub web
6. Show PR validation checks passing
7. Merge PR
8. Watch GitHub Actions workflow run (dev → staging → prod)
9. Show deployment history in GitHub Actions
10. Show git log with full audit trail

**Key Messages**:
- ✅ Version controlled infrastructure
- ✅ Review before deployment (PR process)
- ✅ Automated deployment (no manual steps)
- ✅ Complete audit trail (compliance)
- ✅ Easy rollback (git revert)
- ✅ Multi-environment management (dev/staging/prod)

---

**Built with HCL DevOps Loop in mind** — managing the full software delivery lifecycle through automated, auditable, version-controlled processes.
