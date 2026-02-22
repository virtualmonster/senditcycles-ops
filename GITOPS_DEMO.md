# GitOps Demo: Infrastructure as Code Affecting Deployed Apps

This guide demonstrates how changes to the `senditcycles-ops` repository automatically affect the running SendItCycles application.

## Demo Scenario: Scaling Backend Services

### The Story
"In our GitOps workflow, infrastructure changes live in Git, are reviewed via PR, and automatically deploy. Watch as we scale our backend from 1 instance to 3 instances—just by editing the docker-compose configuration."

---

## Demo Steps

### Step 1: Show Current State (Baseline)

**Terminal 1: Check running containers**
```bash
cd /path/to/senditcycles-ops/environments/dev
docker-compose ps
```

Expected output:
```
CONTAINER ID   IMAGE              STATUS      PORTS
...
senditcycles-db-dev         postgres:14-alpine         Up     5432->5432/tcp
senditcycles-api-dev        senditcycles-server:dev    Up     (no external port)
senditcycles-web-dev        senditcycles-client:dev    Up     (no external port)
senditcycles-lb-dev         nginx:alpine               Up     3000->80/tcp, 3001->80/tcp
```

**Terminal 2: Check nginx upstream**
```bash
docker exec senditcycles-lb-dev cat /etc/nginx/conf.d/default.conf | grep -A 5 "upstream backend"
```

Current configuration:
```
upstream backend {
    least_conn;
    server backend:3001;
    # Additional backends added during scaling:
    # server backend-2:3001;
    # server backend-3:3001;
}
```

**Show the code**
```bash
cat environments/dev/config/nginx.conf
```

Explain: "Currently one backend instance (`backend:3001`) serves all API traffic."

---

### Step 2: Make the IAC Change (Edit docker-compose)

**Step 2a: Create a feature branch**
```bash
git checkout -b demo/scale-backend-to-3-instances
```

**Step 2b: Edit the nginx config to add 2 more backend instances**

Edit `environments/dev/config/nginx.conf`:

```diff
  upstream backend {
      least_conn;
      server backend:3001;
-     # Additional backends added during scaling:
-     # server backend-2:3001;
-     # server backend-3:3001;
+     # Additional backends added during scaling:
+     server backend-2:3001;
+     server backend-3:3001;
  }
```

Explain: "We've configured Nginx to distribute traffic across 3 backend instances."

**Step 2c: Now update the docker-compose to actually create those instances**

Edit `environments/dev/docker-compose.yml`:

Add after the `frontend` service definition, before `load-balancer`:

```yaml
  backend-2:
    build:
      context: ../../../senditcycles/server
      dockerfile: Dockerfile
    container_name: senditcycles-api-dev-2
    environment:
      NODE_ENV: development
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: ${DB_USER:-senditcycles}
      DB_PASSWORD: ${DB_PASSWORD:-devpassword123}
      DB_NAME: ${DB_NAME:-senditcycles_dev}
      JWT_SECRET: ${JWT_SECRET:-dev-secret-key-change-in-prod}
      LOG_LEVEL: debug
    expose:
      - "3001"
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ../../../senditcycles/server/src:/app/src
    networks:
      - senditcycles-dev

  backend-3:
    build:
      context: ../../../senditcycles/server
      dockerfile: Dockerfile
    container_name: senditcycles-api-dev-3
    environment:
      NODE_ENV: development
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: ${DB_USER:-senditcycles}
      DB_PASSWORD: ${DB_PASSWORD:-devpassword123}
      DB_NAME: ${DB_NAME:-senditcycles_dev}
      JWT_SECRET: ${JWT_SECRET:-dev-secret-key-change-in-prod}
      LOG_LEVEL: debug
    expose:
      - "3001"
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ../../../senditcycles/server/src:/app/src
    networks:
      - senditcycles-dev
```

**Talking point**: "All we did was edit the docker-compose file in our Git repository. This is Infrastructure as Code—our desired state is now version-controlled."

---

### Step 3: Commit & Push

```bash
git add environments/dev/config/nginx.conf environments/dev/docker-compose.yml
git commit -m "feat: scale backend from 1 to 3 instances

- Add backend-2 and backend-3 services to docker-compose
- Update Nginx upstream to load balance across 3 backends
- Enables zero-downtime deployments and higher throughput"

git push origin demo/scale-backend-to-3-instances
```

**Talking point**: "Commit message explains WHY we made the change—compliance teams can audit this decision."

---

### Step 4: Create Pull Request & Show Validation

```bash
# In GitHub UI or via CLI:
gh pr create --title "Scale backend to 3 instances" \
  --body "Demonstrates GitOps scaling capability for Gartner demo"
```

**GitHub Actions workflow will automatically:**
- ✅ Validate docker-compose syntax
- ✅ Verify environment files exist
- ✅ Check for required secrets

**Show the PR checks passing**—no manual validation, fully automated.

---

### Step 5: Merge & Trigger Auto-Deployment

```bash
# Merge in GitHub UI or via CLI:
gh pr merge --squash
```

**This triggers the GitHub Actions workflow:**

1. **Validate stage** ✅ runs (syntax checks)
2. **Deploy-Dev stage** starts automatically
   - Validates docker-compose
   - Runs: `docker-compose up -d --build`
   - New services `backend-2` and `backend-3` are created
   - Nginx is reloaded with updated config
3. **Deploy-Staging stage** runs next (if enabled)
4. **Deploy-Prod stage** runs last (with approval gate)

---

### Step 6: Verify the Change in Running App

**Terminal: Watch containers scale up**

```bash
# In the dev environment directory:
watch 'docker-compose ps'

# Or manually check:
docker-compose ps
```

**Expected result after deployment:**
```
CONTAINER ID   IMAGE                          STATUS
...
senditcycles-db-dev           postgres:14-alpine            Up      
senditcycles-api-dev          senditcycles-server:dev       Up
senditcycles-api-dev-2        senditcycles-server:dev       Up      <- NEW
senditcycles-api-dev-3        senditcycles-server:dev       Up      <- NEW
senditcycles-web-dev          senditcycles-client:dev       Up
senditcycles-lb-dev           nginx:alpine                  Up
```

**Verify load balancer config updated:**

```bash
docker exec senditcycles-lb-dev cat /etc/nginx/conf.d/default.conf | grep -A 5 "upstream backend"
```

Expected:
```
upstream backend {
    least_conn;
    server backend:3001;
    server backend-2:3001;      <- NOW ACTIVE
    server backend-3:3001;      <- NOW ACTIVE
}
```

**Verify load balancing works:**

```bash
# Send requests through load balancer
for i in {1..6}; do
  curl -s http://localhost:3000/api/health -w "\nBackend: %{remote_ip}\n"
done

# You should see traffic distributed across the 3 instances
```

---

### Step 7: Show Audit Trail & Rollback

**View Git history**
```bash
git log --oneline --decorate -10
```

Shows:
- Commit hash
- Author
- Timestamp  
- Change description
- "scale-backend-to-3-instances" tag

**All infrastructure changes are tracked**: who changed what, when, and why.

**If something goes wrong, rollback is simple:**

```bash
# Revert the commit
git revert <commit-hash>
git push origin main

# GitHub Actions automatically redeploys with old config
# Containers scale back down to 1 instance
```

---

## Key Demo Points for Gartner

### ✅ What This Demonstrates

1. **Infrastructure as Code**
   - Deployment configuration lives in Git
   - Version controlled like application code
   - Full change history

2. **Pull Request Workflow**
   - Changes reviewed before deployment
   - Automated validation (no manual steps)
   - Compliance & audit trail

3. **Automated Deployment**
   - No manual deployment scripts
   - No SSH into servers
   - GitHub Actions handles everything
   - Progressive: dev → staging → prod

4. **Visible Impact**
   - Change docker-compose → containers scale
   - Infrastructure change → immediately live
   - Shows real cause-and-effect

5. **Easy Rollback**
   - One `git revert` command
   - Automatic redeployment with previous config
   - No downtime, no manual recovery

### 🎯 GitOps Principles in Action

- **Declarative**: Docker-compose describes desired state
- **Versioned**: Every change is a Git commit
- **Pulled, not pushed**: Kubernetes/Docker pulls config from Git repo
- **Automatically reconciled**: If config drifts, redeploy to fix it
- **Auditable**: Full commit log for compliance

---

## Real-World Benefits (Gartner Talking Points)

1. **Speed**: Deploy infrastructure changes in seconds
2. **Safety**: PR review prevents mistakes; rollback if needed
3. **Compliance**: Every change is audited (who, what, when, why)
4. **Consistency**: Same process across dev/staging/prod
5. **Knowledge**: Changes documented in Git; no tribal knowledge
6. **Scalability**: Works the same way for 1 app or 100 apps

---

## Tips for Running the Demo

### Do's ✅
- Keep it simple: show ONE clear change (1→3 instances)
- Start with git log to show previous work
- Show the PR process in GitHub UI
- Watch GitHub Actions logs in real-time
- Verify the change live (docker ps, curl tests)
- Explain each step in plain language

### Don'ts ❌
- Don't skip the PR step (that's the whole point)
- Don't deploy directly to production without PR
- Don't make multiple changes at once
- Don't rush; let people watch the flow
- Don't assume audience knows docker/git

### Timing
- Setup: 2 minutes (show baseline)
- Change: 2 minutes (edit files, commit, PR)
- Validation: 1 minute (GitHub checks)
- Merge & Deploy: 2 minutes (watch workflow)
- Verification: 2 minutes (show 3 containers, curl test)
- **Total: ~10 minutes**

### If Something Breaks
- **Nginx won't reload**: Backend container may not have started yet; wait 10 seconds
- **No health check response**: Make sure all 3 backend containers are running (`docker-compose logs backend backend-2 backend-3`)
- **Load balancer shows 502**: Check that all upstream backends are ready; view `docker-compose ps` and logs
- **Need to restart**: `docker-compose down && docker-compose up -d`

---

## Files Modified for This Demo

```
senditcycles-ops/
├── environments/
│   └── dev/
│       ├── docker-compose.yml      (added backend-2, backend-3, load-balancer)
│       └── config/
│           └── nginx.conf          (added upstream servers)
```

These changes can be progressively applied to `staging/` and `prod/` for the full multi-environment demo.
