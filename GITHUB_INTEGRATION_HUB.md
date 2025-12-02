# 🔗 GitHub Integration Guide - Aqim Project
## Panduan Lengkap Integrasi dengan Repository https://github.com/megatemran/aqim

---

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Git Configuration](#git-configuration)
3. [Repository Structure](#repository-structure)
4. [Integration Steps](#integration-steps)
5. [Best Practices](#best-practices)
6. [Common Issues & Solutions](#common-issues--solutions)
7. [CI/CD Setup](#cicd-setup)

---

## ✅ Prerequisites

### Required Tools
```bash
# Check Git installation
git --version  # Should be 2.x or higher

# Check Flutter installation
flutter --version  # Should be 3.x or higher
flutter doctor -v  # Verify all setup

# Check GitHub CLI (optional but recommended)
gh --version
```

### GitHub Account Setup
- GitHub account dengan access ke repository `megatemran/aqim`
- SSH key atau Personal Access Token (PAT) configured
- Git configured dengan username dan email anda

---

## 🔧 Git Configuration

### 1. Configure Git Identity
```bash
# Set your name and email
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify configuration
git config --list
```

### 2. Setup SSH Key (Recommended)
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Start SSH agent
eval "$(ssh-agent -s)"

# Add SSH key to agent
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard
cat ~/.ssh/id_ed25519.pub
# Paste this to GitHub: Settings > SSH and GPG keys > New SSH key
```

### 3. Test GitHub Connection
```bash
# Test SSH connection
ssh -T git@github.com
# Should see: "Hi username! You've successfully authenticated..."
```

---

## 📁 Repository Structure

### Current Project Structure
```
aqim/
├── android/                 # Android native code
├── ios/                     # iOS native code
├── lib/                     # Flutter application code
│   ├── main.dart           # Entry point
│   ├── models/             # Data models
│   ├── screens/            # UI screens
│   ├── services/           # Business logic
│   ├── localization/       # i18n support
│   └── utils/              # Helper utilities
├── assets/                 # Images, fonts, sounds
│   ├── fonts/
│   ├── images/
│   ├── sounds/
│   └── lottie/
├── test/                   # Test files
├── pubspec.yaml            # Dependencies
├── analysis_options.yaml   # Lint rules
├── CLAUDE.md              # Claude Code guide
└── README.md              # Project documentation
```

### Recommended .gitignore
```gitignore
# Flutter/Dart/Pub related
**/doc/api/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
flutter_*.png
linked_*.ds
unlinked.ds
unlinked_spec.ds

# Android related
**/android/**/gradle-wrapper.jar
**/android/.gradle
**/android/captures/
**/android/gradlew
**/android/gradlew.bat
**/android/local.properties
**/android/**/GeneratedPluginRegistrant.java
**/android/key.properties
*.jks
*.keystore

# iOS/XCode related
**/ios/**/*.mode1v3
**/ios/**/*.mode2v3
**/ios/**/*.moved-aside
**/ios/**/*.pbxuser
**/ios/**/*.perspectivev3
**/ios/**/*sync/
**/ios/**/.sconsign.dblite
**/ios/**/.tags*
**/ios/**/.vagrant/
**/ios/**/DerivedData/
**/ios/**/Icon?
**/ios/**/Pods/
**/ios/**/.symlinks/
**/ios/**/profile
**/ios/**/xcuserdata
**/ios/.generated/
**/ios/Flutter/.last_build_id
**/ios/Flutter/App.framework
**/ios/Flutter/Flutter.framework
**/ios/Flutter/Flutter.podspec
**/ios/Flutter/Generated.xcconfig
**/ios/Flutter/ephemeral
**/ios/Flutter/app.flx
**/ios/Flutter/app.zip
**/ios/Flutter/flutter_assets/
**/ios/Flutter/flutter_export_environment.sh
**/ios/ServiceDefinitions.json
**/ios/Runner/GeneratedPluginRegistrant.*

# Exceptions to above rules.
!**/ios/**/default.mode1v3
!**/ios/**/default.mode2v3
!**/ios/**/default.pbxuser
!**/ios/**/default.perspectivev3

# Web related
lib/generated_plugin_registrant.dart

# Symbolication related
app.*.symbols

# Obfuscation related
app.*.map.json

# Android Studio
.idea/
*.iml
*.ipr
*.iws
.gradle/
local.properties

# IntelliJ
*.iml
.idea/

# Visual Studio Code
.vscode/
.history/

# macOS
.DS_Store

# Sensitive files
**/google-services.json
**/GoogleService-Info.plist
*.env
secrets.yaml

# Generated files
*.g.dart
*.freezed.dart
*.mocks.dart

# Coverage
coverage/
*.lcov

# Translations
*.arb.json

# Other
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/
migrate_working_dir/
```

---

## 🚀 Integration Steps

### Step 1: Clone Repository (New Setup)

```bash
# Navigate to your workspace
cd ~/workspace

# Clone the repository
git clone git@github.com:megatemran/aqim.git
cd aqim

# Verify remote
git remote -v
```

### Step 2: Setup Existing Project

If you already have code locally:

```bash
# Navigate to your project directory
cd /path/to/your/aqim-project

# Initialize git if not already done
git init

# Add remote origin
git remote add origin git@github.com:megatemran/aqim.git

# Fetch remote branches
git fetch origin

# Check current branch
git branch

# If you want to sync with remote main branch
git pull origin main --allow-unrelated-histories
```

### Step 3: Create Feature Branch

```bash
# Create and switch to feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description

# Or for documentation
git checkout -b docs/what-you-are-documenting
```

### Step 4: Add and Commit Changes

```bash
# Check status
git status

# Add specific files
git add lib/screens/new_screen.dart
git add assets/images/new_image.png

# Or add all changes (use carefully)
git add .

# Commit with descriptive message
git commit -m "feat: add prayer times widget functionality

- Implemented prayer times display widget
- Added JAKIM API integration
- Updated UI with Material Design 3
- Added responsive design for tablets

Closes #123"

# Commit message format:
# <type>: <subject>
#
# <body>
#
# <footer>
```

### Step 5: Push Changes

```bash
# Push to remote branch
git push origin feature/your-feature-name

# If this is the first push for this branch
git push -u origin feature/your-feature-name
```

### Step 6: Create Pull Request

**Via GitHub Web Interface:**
1. Go to https://github.com/megatemran/aqim
2. Click "Pull requests" tab
3. Click "New pull request"
4. Select your branch
5. Fill in PR details:
   - Title: Clear, concise description
   - Description: Explain what and why
   - Link related issues
   - Add screenshots for UI changes
6. Request review from team members
7. Click "Create pull request"

**Via GitHub CLI:**
```bash
# Install GitHub CLI if not already
# macOS: brew install gh
# Windows: winget install GitHub.cli

# Authenticate
gh auth login

# Create PR
gh pr create \
  --title "feat: Add prayer times widget" \
  --body "Implements prayer times display with JAKIM API integration" \
  --base main \
  --head feature/your-feature-name
```

---

## 📝 Best Practices

### Commit Message Convention

Follow **Conventional Commits** specification:

```bash
# Format
<type>(<scope>): <subject>

<body>

<footer>

# Types
feat:     # New feature
fix:      # Bug fix
docs:     # Documentation only
style:    # Formatting, missing semi colons, etc
refactor: # Code change that neither fixes bug nor adds feature
perf:     # Performance improvements
test:     # Adding missing tests
chore:    # Maintain/tooling changes

# Examples
feat(prayer-times): add JAKIM API integration
fix(qibla): correct compass direction calculation
docs(readme): update installation instructions
style(home): format code with dartfmt
refactor(services): extract location logic to service
perf(ui): optimize prayer times rendering
test(models): add unit tests for PrayerTime model
chore(deps): update flutter to 3.16.0
```

### Branch Naming Convention

```bash
# Feature branches
feature/prayer-times-widget
feature/qibla-compass
feature/duas-collection

# Bug fix branches
fix/prayer-time-calculation
fix/notification-sound
fix/compass-accuracy

# Documentation branches
docs/api-documentation
docs/user-guide
docs/contributing-guide

# Release branches
release/v1.0.0
release/v1.1.0

# Hotfix branches
hotfix/critical-crash
hotfix/prayer-time-bug
```

### Pull Request Best Practices

**1. PR Title and Description**
```markdown
## Description
Implements prayer times display widget with JAKIM API integration for Malaysian users.

## Changes Made
- Added `PrayerTimesService` for API calls
- Created `PrayerTimesWidget` with Material Design 3
- Implemented caching mechanism for prayer times
- Added unit tests for prayer time calculations

## Testing Done
- [x] Unit tests pass
- [x] Widget tests pass
- [x] Manual testing on Android
- [x] Manual testing on iOS
- [x] Tested with different locations

## Screenshots
[Attach screenshots here]

## Related Issues
Closes #123
Relates to #456

## Checklist
- [x] Code follows project style guidelines
- [x] Self-review completed
- [x] Comments added for complex code
- [x] Documentation updated
- [x] Tests added/updated
- [x] No new warnings
```

**2. Keep PRs Small and Focused**
- One feature or fix per PR
- Easier to review
- Faster merge time
- Easier to revert if needed

**3. Update Your Branch Regularly**
```bash
# Fetch latest changes from main
git checkout main
git pull origin main

# Switch back to your feature branch
git checkout feature/your-feature-name

# Merge main into your branch
git merge main

# Or rebase (cleaner history)
git rebase main

# Resolve conflicts if any
# Then push
git push origin feature/your-feature-name --force-with-lease
```

### Code Review Guidelines

**For Reviewers:**
- Check code quality and standards
- Verify tests are included
- Look for potential bugs
- Consider performance implications
- Check for security issues
- Ensure documentation is updated

**For Authors:**
- Respond to all comments
- Make requested changes promptly
- Explain your decisions
- Be open to feedback
- Update PR description if scope changes

---

## 🛠 Common Issues & Solutions

### Issue 1: Git Authentication Failed

**Problem:**
```bash
remote: Repository not found.
fatal: Authentication failed
```

**Solution:**
```bash
# If using SSH
ssh -T git@github.com

# If using HTTPS, generate Personal Access Token
# Go to: GitHub Settings > Developer settings > Personal access tokens
# Use token as password

# Or switch to SSH
git remote set-url origin git@github.com:megatemran/aqim.git
```

### Issue 2: Merge Conflicts

**Problem:**
```bash
CONFLICT (content): Merge conflict in lib/main.dart
Automatic merge failed; fix conflicts and then commit the result.
```

**Solution:**
```bash
# Open conflicted files and look for conflict markers
# <<<<<<<, =======, >>>>>>>

# Edit the file to resolve conflicts
# Remove conflict markers

# Mark as resolved
git add lib/main.dart

# Complete the merge
git commit -m "merge: resolve conflicts from main"

# Push changes
git push origin feature/your-feature-name
```

### Issue 3: Accidentally Committed to Wrong Branch

**Problem:**
```bash
# You committed to main instead of feature branch
```

**Solution:**
```bash
# Create new branch from current state
git checkout -b feature/your-feature-name

# Go back to main
git checkout main

# Reset main to match remote
git reset --hard origin/main

# Switch back to feature branch
git checkout feature/your-feature-name

# Your changes are safe here
```

### Issue 4: Need to Undo Last Commit

**Problem:**
```bash
# You made a mistake in the last commit
```

**Solution:**
```bash
# Undo commit but keep changes
git reset --soft HEAD~1

# Undo commit and discard changes (careful!)
git reset --hard HEAD~1

# Amend last commit message
git commit --amend -m "New commit message"
```

### Issue 5: Large Files Not Pushing

**Problem:**
```bash
remote: error: File large-file.zip is 120.00 MB; this exceeds GitHub's file size limit of 100.00 MB
```

**Solution:**
```bash
# Remove file from git history
git rm --cached large-file.zip

# Add to .gitignore
echo "large-file.zip" >> .gitignore

# Commit changes
git commit -m "chore: remove large file from git"

# For files already in history, use git-filter-repo
# Install: pip install git-filter-repo
git filter-repo --path large-file.zip --invert-paths
```

---

## 🔄 CI/CD Setup

### GitHub Actions Workflow

Create `.github/workflows/flutter-ci.yml`:

```yaml
name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: '11'
        
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        channel: 'stable'
        
    - name: Get dependencies
      run: flutter pub get
      
    - name: Analyze code
      run: flutter analyze
      
    - name: Run tests
      run: flutter test
      
    - name: Build APK
      run: flutter build apk --release
      
    - name: Upload APK artifact
      uses: actions/upload-artifact@v3
      with:
        name: app-release
        path: build/app/outputs/flutter-apk/app-release.apk
```

### Automated Code Quality Checks

Create `.github/workflows/code-quality.yml`:

```yaml
name: Code Quality

on:
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        
    - name: Get dependencies
      run: flutter pub get
      
    - name: Check formatting
      run: dart format --set-exit-if-changed .
      
    - name: Analyze code
      run: flutter analyze
      
    - name: Run tests with coverage
      run: flutter test --coverage
      
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
```

---

## 📚 Additional Resources

### Git Commands Cheat Sheet

```bash
# Basic commands
git status              # Check current status
git log                 # View commit history
git log --oneline       # Compact commit history
git diff                # See unstaged changes
git diff --staged       # See staged changes

# Branch management
git branch              # List local branches
git branch -a           # List all branches
git branch -d branch    # Delete branch
git checkout -b branch  # Create and switch branch

# Stashing changes
git stash               # Save changes temporarily
git stash list          # List stashed changes
git stash pop           # Apply and remove stash
git stash apply         # Apply but keep stash

# Remote operations
git remote -v           # Show remotes
git fetch origin        # Fetch without merge
git pull origin main    # Fetch and merge
git push origin branch  # Push to remote

# Undoing changes
git restore file        # Discard unstaged changes
git restore --staged f  # Unstage file
git revert commit-hash  # Create new commit that undoes
git reset --soft HEAD~1 # Undo commit, keep changes
git reset --hard HEAD~1 # Undo commit, discard changes

# Cleaning
git clean -n            # Preview files to delete
git clean -fd           # Delete untracked files/dirs
```

### Flutter Project Commands

```bash
# Development
flutter run                     # Run app
flutter run -d chrome          # Run on web
flutter run --release          # Run release build

# Building
flutter build apk              # Build APK
flutter build appbundle        # Build AAB for Play Store
flutter build ios              # Build for iOS
flutter build web              # Build for web

# Testing
flutter test                   # Run all tests
flutter test --coverage        # Run with coverage
flutter test path/to/test.dart # Run specific test

# Code quality
flutter analyze                # Analyze code
dart format .                  # Format code
flutter pub outdated           # Check outdated packages
flutter pub upgrade           # Upgrade packages

# Cleaning
flutter clean                  # Clean build
flutter pub cache repair       # Repair pub cache
```

### Useful Git Aliases

Add to `~/.gitconfig`:

```ini
[alias]
    # Shortcuts
    co = checkout
    br = branch
    ci = commit
    st = status
    
    # Pretty logs
    lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    
    # Show branches
    branches = branch -a
    
    # Undo last commit
    undo = reset HEAD~1 --mixed
    
    # Amend last commit
    amend = commit --amend --no-edit
    
    # Show diff of staged changes
    staged = diff --staged
    
    # Prune deleted remote branches
    prune = remote prune origin
```

---

## ✅ Integration Checklist

Before pushing to production, ensure:

- [ ] All code is properly formatted (`dart format .`)
- [ ] No analysis issues (`flutter analyze`)
- [ ] All tests pass (`flutter test`)
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Version number is bumped in `pubspec.yaml`
- [ ] Secrets and API keys are not committed
- [ ] .gitignore is properly configured
- [ ] README.md has setup instructions
- [ ] PR has clear description and screenshots
- [ ] Code review is completed
- [ ] CI/CD pipeline passes

---

## 🆘 Getting Help

If you encounter issues:

1. **Check Documentation**
   - Review this guide
   - Check CLAUDE.md for project-specific info
   - Read Flutter documentation

2. **Search Existing Issues**
   - GitHub Issues: https://github.com/megatemran/aqim/issues
   - Stack Overflow: Tag with `flutter` and `git`

3. **Ask for Help**
   - Create issue on GitHub
   - Discuss with team members
   - Flutter Discord/Slack communities

4. **Contact**
   - Project maintainer: [Your contact info]
   - Team lead: [Team lead contact]

---

## 📄 License

This project follows the license specified in the repository.

---

**Happy Coding! 🎉**

*Last updated: December 2024*