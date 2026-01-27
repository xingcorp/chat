# CI/CD Setup Guide

## Overview

This guide explains how to set up Continuous Integration and Continuous Deployment (CI/CD) for the Sharitek Office Chat Flutter application. We provide configurations for both GitHub Actions and GitLab CI.

## Platform Selection

### GitHub Actions (Recommended for GitHub)

**Pros:**
- Native integration with GitHub
- Free for public repositories
- 2,000 minutes/month for private repositories (free tier)
- Easy to configure
- Good marketplace for actions

**Cons:**
- Limited to GitHub
- Can be expensive for heavy usage

### GitLab CI (Recommended for GitLab)

**Pros:**
- Native integration with GitLab
- 400 minutes/month for free tier
- Self-hosted runners available
- Powerful pipeline features

**Cons:**
- Limited to GitLab
- Steeper learning curve

## GitHub Actions Setup

### Step 1: Verify Configuration File

The configuration file is located at `.github/workflows/flutter-ci.yml`

**Verify it exists:**
```bash
ls -la .github/workflows/flutter-ci.yml
```

### Step 2: Configure Secrets

Navigate to your GitHub repository:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add the following secrets:

**Required Secrets:**
- `CODECOV_TOKEN` (optional, for code coverage)
- `ANDROID_KEYSTORE` (for signed Android builds)
- `ANDROID_KEY_ALIAS` (for signed Android builds)
- `ANDROID_KEY_PASSWORD` (for signed Android builds)
- `ANDROID_STORE_PASSWORD` (for signed Android builds)

**Example:**
```
Name: ANDROID_KEY_PASSWORD
Value: your-secure-password-here
```

### Step 3: Enable Actions

1. Go to **Settings** → **Actions** → **General**
2. Under **Actions permissions**, select:
   - ✅ Allow all actions and reusable workflows
3. Under **Workflow permissions**, select:
   - ✅ Read and write permissions
   - ✅ Allow GitHub Actions to create and approve pull requests

### Step 4: Test the Pipeline

```bash
# Create a test branch
git checkout -b test/ci-pipeline

# Make a trivial change
echo "# CI Test" >> README.md

# Commit and push
git add README.md
git commit -m "test: verify CI/CD pipeline"
git push origin test/ci-pipeline
```

**Verify:**
1. Go to **Actions** tab in GitHub
2. You should see the workflow running
3. Click on the workflow to see details
4. All jobs should pass ✅

### Step 5: Configure Branch Protection

1. Go to **Settings** → **Branches**
2. Click **Add rule** for `main` branch
3. Configure:
   - ✅ Require a pull request before merging
   - ✅ Require approvals: 2
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - Select required status checks:
     - `Analyze Code`
     - `Run Tests`
4. Click **Create** or **Save changes**

## GitLab CI Setup

### Step 1: Verify Configuration File

The configuration file is located at `.gitlab-ci.yml`

**Verify it exists:**
```bash
ls -la .gitlab-ci.yml
```

### Step 2: Configure CI/CD Variables

Navigate to your GitLab project:
1. Go to **Settings** → **CI/CD** → **Variables**
2. Click **Add variable**
3. Add the following variables:

**Required Variables:**
- `ANDROID_KEYSTORE` (Type: File, for signed Android builds)
- `ANDROID_KEY_ALIAS` (Type: Variable)
- `ANDROID_KEY_PASSWORD` (Type: Variable, Masked)
- `ANDROID_STORE_PASSWORD` (Type: Variable, Masked)

**Example:**
```
Key: ANDROID_KEY_PASSWORD
Value: your-secure-password-here
Type: Variable
Flags: ✅ Masked, ✅ Protected
```

### Step 3: Configure Runners

**Option A: Use Shared Runners (Recommended for Free Tier)**
1. Go to **Settings** → **CI/CD** → **Runners**
2. Enable **Shared runners**
3. Verify runners are available

**Option B: Setup Self-Hosted Runner**
1. Go to **Settings** → **CI/CD** → **Runners**
2. Click **New project runner**
3. Follow instructions to install runner on your server
4. Register runner with provided token

### Step 4: Test the Pipeline

```bash
# Create a test branch
git checkout -b test/ci-pipeline

# Make a trivial change
echo "# CI Test" >> README.md

# Commit and push
git add README.md
git commit -m "test: verify CI/CD pipeline"
git push origin test/ci-pipeline
```

**Verify:**
1. Go to **CI/CD** → **Pipelines** in GitLab
2. You should see the pipeline running
3. Click on the pipeline to see details
4. All stages should pass ✅

### Step 5: Configure Protected Branches

1. Go to **Settings** → **Repository** → **Protected branches**
2. Select `main` branch
3. Configure:
   - **Allowed to merge:** Maintainers
   - **Allowed to push:** No one
   - ✅ Require approval from code owners
4. Click **Protect**

## Pipeline Stages Explained

### Stage 1: Analyze

**Purpose:** Verify code quality and formatting

**Jobs:**
- `analyze:format` - Check code formatting
- `analyze:code` - Run Flutter analyze
- `analyze:dependencies` - Check for outdated dependencies
- `analyze:security` - Run security audit

**What it checks:**
- Code follows formatting standards
- No linting errors
- No deprecated dependencies
- No known security vulnerabilities

### Stage 2: Test

**Purpose:** Run automated tests

**Jobs:**
- `test:unit` - Run unit tests with coverage

**What it checks:**
- All unit tests pass
- Code coverage meets threshold
- No test failures

**Coverage Report:**
- Generated in `coverage/` directory
- Uploaded as artifact
- Displayed in merge request

### Stage 3: Build

**Purpose:** Build application artifacts

**Jobs:**
- `build:android` - Build Android APK
- `build:android:bundle` - Build Android App Bundle (AAB)
- `build:ios` - Build iOS app (no codesign)
- `build:web` - Build web app

**Artifacts:**
- APK file for Android
- AAB file for Play Store
- iOS build directory
- Web build directory

### Stage 4: Deploy (Optional)

**Purpose:** Deploy to environments

**Jobs:**
- `deploy:staging` - Deploy to staging (manual)
- `deploy:production` - Deploy to production (manual)

**Environments:**
- Staging: For testing
- Production: For end users

## Troubleshooting

### Pipeline Fails on Analyze

**Problem:** `flutter analyze` fails

**Solution:**
```bash
# Run locally to see errors
cd flutter_chat_app
flutter analyze

# Fix errors
# ...

# Commit and push
git add .
git commit -m "fix: resolve analyze errors"
git push
```

### Pipeline Fails on Test

**Problem:** Tests fail

**Solution:**
```bash
# Run tests locally
cd flutter_chat_app
flutter test

# Fix failing tests
# ...

# Commit and push
git add .
git commit -m "fix: resolve test failures"
git push
```

### Pipeline Fails on Build

**Problem:** Build fails

**Solution:**
```bash
# Run build locally
cd flutter_chat_app
flutter build apk --release

# Check for errors
# Fix issues

# Commit and push
git add .
git commit -m "fix: resolve build errors"
git push
```

### Secrets Not Working

**Problem:** Pipeline can't access secrets

**Solution:**
1. Verify secrets are added correctly
2. Check secret names match exactly
3. Ensure secrets are not expired
4. For protected branches, mark secrets as "Protected"

### Runner Out of Minutes

**Problem:** CI/CD minutes exhausted

**Solution:**
1. Optimize pipeline (reduce unnecessary jobs)
2. Use caching to speed up builds
3. Upgrade to paid plan
4. Setup self-hosted runner

## Best Practices

### DO:
✅ Run CI/CD on all branches  
✅ Require CI/CD to pass before merging  
✅ Use caching to speed up builds  
✅ Keep secrets secure  
✅ Monitor pipeline performance  
✅ Fix failing pipelines immediately  
✅ Review pipeline logs regularly  

### DON'T:
❌ Commit secrets to repository  
❌ Disable CI/CD checks  
❌ Merge without CI/CD passing  
❌ Ignore failing tests  
❌ Skip code review  
❌ Deploy without testing  

## Monitoring and Alerts

### GitHub Actions

**View Pipeline Status:**
1. Go to **Actions** tab
2. See all workflow runs
3. Click on run for details

**Setup Notifications:**
1. Go to **Settings** → **Notifications**
2. Enable **Actions** notifications
3. Choose notification method (email, mobile)

### GitLab CI

**View Pipeline Status:**
1. Go to **CI/CD** → **Pipelines**
2. See all pipeline runs
3. Click on pipeline for details

**Setup Notifications:**
1. Go to **Settings** → **Integrations**
2. Configure Slack/Teams integration
3. Enable pipeline notifications

## Performance Optimization

### Caching

**GitHub Actions:**
```yaml
- uses: actions/cache@v3
  with:
    path: |
      ~/.pub-cache
      flutter_chat_app/.dart_tool
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
```

**GitLab CI:**
```yaml
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - flutter_chat_app/.dart_tool/
    - flutter_chat_app/.packages
```

### Parallel Jobs

Run independent jobs in parallel:
- Analyze and test can run in parallel
- Multiple build jobs can run in parallel

### Conditional Execution

Only run expensive jobs when needed:
- Build only on `main` and `develop`
- Deploy only on `main`
- Security scan only on merge requests

## Maintenance

### Regular Tasks

**Weekly:**
- [ ] Review failed pipelines
- [ ] Check for outdated dependencies
- [ ] Monitor CI/CD minutes usage

**Monthly:**
- [ ] Update Flutter version in CI/CD
- [ ] Review and optimize pipeline
- [ ] Update secrets if needed
- [ ] Check for security vulnerabilities

**Quarterly:**
- [ ] Audit CI/CD configuration
- [ ] Review and update best practices
- [ ] Evaluate alternative CI/CD platforms

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [Codecov Documentation](https://docs.codecov.com/)

---

**Last Updated:** [Date]  
**Maintained by:** QA/DevOps Team  
**Questions?** Ask in #sharitek-chat-dev channel
