#!/bin/bash

# =============================================================================
# [0;32mSTEP-BY-STEP CONFIGURATION & EXECUTION INSTRUCTIONS[0m
# =============================================================================
#
# [0;32m  [PHASE 1: PREREQUISITES - DO BEFORE RUNNING THIS SCRIPT][0m
#   1. [0;32mInstall GitHub CLI (gh) if not already installed:[0m
#      Ubuntu/Debian:
#         curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
#         echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
#         sudo apt update
#         sudo apt install gh
#      macOS: brew install gh
#      Windows: winget install --id GitHub.cli --source winget
#
#      After installation, restart your terminal so the 'gh' command is recognized.
#
#   2. [0;32m⚠️ IMPORTANT: Authenticate GitHub CLI BEFORE running the script:[0m
#      Run: gh auth login
#
#      When prompted, you MUST choose:
#      ┌─────────────────────────────────────────────────────────────────────┐
#      │  ? What is your preferred protocol for Git operations?            │
#      │    > HTTPS    ← CHOOSE THIS (even though we'll use SSH later!)    │
#      │      SSH                                                          │
#      └─────────────────────────────────────────────────────────────────────┘
#
#      Why choose HTTPS now?
#      ✅ You haven't generated the SSH key yet (the script will do this)
#      ✅ gh needs an OAuth token to talk to GitHub API
#      ✅ The script will use this token to add your SSH key to GitHub
#      ✅ After the script runs, git will be reconfigured to use SSH
#
#      For the other prompts:
#      - Account: GitHub.com
#      - Authentication: Login with a web browser
#      - Your browser will open → Log in with password + 2FA
#      - GitHub issues an OAuth token → Stored securely on your system
#
#      ⚠️ Your GitHub password is ONLY needed now (in the browser).
#      The script will NEVER store or use your password directly.
#
#   3. [0;32mLog into your browser and create a new empty GitHub repository:[0m
#      - Go to: https://github.com/new
#      - Repository name: e.g., yourusername.github.io or project-name
#      - *CRITICAL*: Leave ALL initialization checkboxes UNCHECKED:
#        ❌ Add a README file
#        ❌ Add .gitignore
#        ❌ Choose a license
#      - Click "Create repository"
#      - Copy the SSH URL (e.g., git@github.com:username/repo-name.git)
#      - Save this URL for the REPO_SSH_URL variable below
#
#   4. [0;32mCreate your local project folder:[0m
#      mkdir -p ~/Development/[github-account-folder]/[repository-folder]
#      cd ~/Development/[github-account-folder]/[repository-folder]
#
#   5. [0;32mCreate this script file in the folder:[0m
#      nano setup.sh (or use your preferred editor)
#      Paste this entire script and save.
#
#   6. [0;32mUpdate the variables in Section 1 below with your profile information.[0m
#      IMPORTANT: Set REPO_SSH_URL to avoid typing it later!
#
# [0;32m  [PHASE 2: EXECUTION][0m
#   7. Make the script executable:
#      chmod +x setup.sh
#
#   8. Execute the script:
#      ./setup.sh
#
# [0;32m  [PHASE 3: WHAT THE SCRIPT DOES][0m
#   9. Checks if gh is installed and authenticated
#   10. Generates a new Ed25519 SSH key
#   11. Initializes git repository locally
#   12. Configures git to use your SSH key
#   13. Adds your SSH key to GitHub (using the OAuth token from step 2)
#   14. Tests SSH connection to GitHub
#   15. Shows final instructions to link and push
#
# [0;32m  🔐 AUTHENTICATION SUMMARY:[0m
#   ┌─────────────────────────────────────────────────────────────────────┐
#   │  PHASE          PROTOCOL     WHAT IT DOES                          │
#   ├─────────────────────────────────────────────────────────────────────┤
#   │  gh auth login  HTTPS        Creates OAuth token for gh API access │
#   │  Script runs    -            Generates SSH key                    │
#   │  Script adds    HTTPS        Uses OAuth token to add SSH key       │
#   │  git push       SSH          Uses SSH key (no password!)          │
#   └─────────────────────────────────────────────────────────────────────┘
#
# =============================================================================

# ==========================================
# 1. USER VARIABLES (EDIT THESE FOR THE NEW PROJECT)
# ==========================================
USER_NAME="snakeandmoon"
USER_EMAIL="mrsleeokwei@gmail.com"
KEY_NAME="snakeandmoon"  # Filename for the unique SSH key file
REPO_SSH_URL="git@github.com:snakeandmoon/snakeandmoon.github.io"  # REPLACE WITH: git@github.com:username/repo-name.git

# ==========================================
# 2. HELPER FUNCTIONS (No color codes in output)
# ==========================================

print_header() {
    echo "================================================================"
    echo "  $1"
    echo "================================================================"
}

print_success() {
    echo "✅ $1"
}

print_warning() {
    echo "⚠️  $1"
}

print_error() {
    echo "❌ $1"
}

print_info() {
    echo "ℹ️  $1"
}

print_step() {
    echo "📌 $1"
}

# ==========================================
# 3. PREREQUISITE CHECK: GITHUB CLI
# ==========================================

check_github_cli() {
    print_step "Checking for GitHub CLI..."

    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed."
        echo ""
        echo "Please install GitHub CLI using one of these methods:"
        echo ""
        echo "Ubuntu/Debian:"
        echo "  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
        echo "  echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
        echo "  sudo apt update"
        echo "  sudo apt install gh"
        echo ""
        echo "macOS:"
        echo "  brew install gh"
        echo ""
        echo "Windows:"
        echo "  winget install --id GitHub.cli --source winget"
        echo ""
        echo "After installation, restart your terminal and run this script again."
        exit 1
    fi

    print_success "GitHub CLI version: $(gh --version | head -n1)"
}

# ==========================================
# 4. AUTHENTICATION CHECK
# ==========================================

check_authentication() {
    print_step "Checking GitHub authentication..."

    if ! gh auth status &> /dev/null; then
        print_warning "Not authenticated with GitHub."
        echo ""
        echo "We need to authenticate with GitHub CLI (gh)."
        echo ""
        echo "IMPORTANT: When prompted during 'gh auth login':"
        echo "  ┌─────────────────────────────────────────────────────────────────────┐"
        echo "  │  ? What is your preferred protocol for Git operations?            │"
        echo "  │    > HTTPS    ← CHOOSE THIS (even though we'll use SSH later!)    │"
        echo "  │      SSH                                                          │"
        echo "  └─────────────────────────────────────────────────────────────────────┘"
        echo ""
        echo "Why choose HTTPS now?"
        echo "  ✅ You haven't generated the SSH key yet (the script will do this)"
        echo "  ✅ gh needs an OAuth token to talk to GitHub API"
        echo "  ✅ The script will use this token to add your SSH key to GitHub"
        echo "  ✅ After the script runs, git will be reconfigured to use SSH"
        echo ""
        echo "What will happen:"
        echo "  1. Your browser will open (or you'll get a device code)"
        echo "  2. You'll log in with your GitHub password + 2FA (if enabled)"
        echo "  3. GitHub will issue an OAuth token for gh"
        echo "  4. The token will be stored securely on your system"
        echo "  5. You'll never need to do this again on this machine"
        echo ""
        echo "Your GitHub password is ONLY needed now (in the browser)."
        echo "The script will NEVER store or use your password directly."
        echo ""
        read -p "Press Enter to start authentication..."

        gh auth login

        if [ $? -ne 0 ]; then
            print_error "Authentication failed."
            echo "Manual fallback: You'll need to add the SSH key manually."
            return 1
        fi
    fi

    print_success "Authenticated as: $(gh api user --jq '.login' 2>/dev/null || echo 'Unknown')"
    print_info "OAuth token is stored securely. No password needed for script operations."
    return 0
}

# ==========================================
# 5. SSH KEY GENERATION
# ==========================================

generate_ssh_key() {
    print_step "Setting up SSH directory..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    print_step "Checking for existing SSH key..."
    if [ -f "$HOME/.ssh/$KEY_NAME" ]; then
        print_warning "SSH key already exists at ~/.ssh/$KEY_NAME"
        read -p "Do you want to overwrite it? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Setup aborted. Keeping existing key."
            exit 1
        fi
        # Backup old key just in case
        mv "$HOME/.ssh/$KEY_NAME" "$HOME/.ssh/${KEY_NAME}.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$HOME/.ssh/$KEY_NAME.pub" "$HOME/.ssh/${KEY_NAME}.pub.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null
    fi

    print_step "Generating Ed25519 SSH key..."
    ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$HOME/.ssh/$KEY_NAME" -N ""

    if [ $? -ne 0 ]; then
        print_error "Failed to generate SSH key."
        exit 1
    fi

    chmod 600 "$HOME/.ssh/$KEY_NAME"
    chmod 644 "$HOME/.ssh/$KEY_NAME.pub"

    print_success "SSH key generated: ~/.ssh/$KEY_NAME"
}

# ==========================================
# 6. GIT REPOSITORY INITIALIZATION
# ==========================================

initialize_git_repo() {
    print_step "Initializing Git repository..."

    if git rev-parse --git-dir &> /dev/null; then
        print_warning "This directory is already a Git repository."
        read -p "Continue with setup in existing repo? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Setup aborted."
            exit 1
        fi
    else
        git init
        if [ $? -ne 0 ]; then
            print_error "Failed to initialize git repository."
            exit 1
        fi
        print_success "Git repository initialized."
    fi

    print_step "Configuring Git identity..."
    git config user.name "$USER_NAME"
    git config user.email "$USER_EMAIL"
    print_success "Git identity configured: $USER_NAME <$USER_EMAIL>"

    print_step "Configuring Git SSH key..."
    git config core.sshCommand "ssh -i ~/.ssh/$KEY_NAME"
    print_success "Git configured to use key: ~/.ssh/$KEY_NAME"
    print_info "Git will now use SSH for all operations in this repository"
}

# ==========================================
# 7. ADD SSH KEY TO GITHUB (FIXED)
# ==========================================

add_ssh_key_to_github() {
    print_step "Adding SSH key to GitHub..."

    PUBLIC_KEY=$(cat "$HOME/.ssh/$KEY_NAME.pub" | tr -d '\n')

    # Get current list of keys from GitHub
    print_info "Fetching current SSH keys from GitHub..."
    EXISTING_KEYS=$(gh api user/keys --jq '.[] | {title: .title, key: .key}' 2>/dev/null)

    if [ $? -ne 0 ]; then
        print_error "Failed to fetch SSH keys from GitHub. Check your authentication."
        print_warning "You'll need to add the SSH key manually:"
        echo ""
        echo "1. Go to: https://github.com/settings/keys"
        echo "2. Click 'New SSH Key'"
        echo "3. Title: $KEY_NAME - $(date '+%Y-%m-%d %H:%M')"
        echo "4. Key type: Authentication Key"
        echo "5. Paste the public key below:"
        echo ""
        cat "$HOME/.ssh/${KEY_NAME}.pub"
        echo ""
        return 1
    fi

    # Check if the key already exists by comparing full keys
    KEY_EXISTS=$(echo "$EXISTING_KEYS" | grep -F "$PUBLIC_KEY" 2>/dev/null)

    if [ -n "$KEY_EXISTS" ]; then
        print_warning "This SSH key already exists on your GitHub account."
        print_info "No action needed - key is already added."
        return 0
    fi

    # Try to add the key
    print_info "Adding SSH key to GitHub..."
    ADD_RESULT=$(gh ssh-key add "$HOME/.ssh/$KEY_NAME.pub" \
        --title "$KEY_NAME - $(date '+%Y-%m-%d %H:%M:%S')" \
        --type authentication 2>&1)

    if [ $? -eq 0 ]; then
        print_success "SSH key successfully added to GitHub!"
        print_info "The gh CLI used your OAuth token (not your password) to add this key."

        # Verify the key was actually added
        print_info "Verifying key was added..."
        VERIFY_KEYS=$(gh api user/keys --jq '.[] | {title: .title, key: .key}' 2>/dev/null)

        if echo "$VERIFY_KEYS" | grep -F "$PUBLIC_KEY" > /dev/null 2>&1; then
            print_success "Verification successful! SSH key is now on GitHub."
            return 0
        else
            print_warning "Verification failed - key was not found on GitHub after adding."
            print_info "The key may have been added but verification is failing."
            print_info "Continuing with manual fallback instructions..."
        fi
    else
        print_error "Failed to add SSH key to GitHub."
        print_info "Error output: $ADD_RESULT"
    fi

    # Manual fallback instructions
    echo ""
    print_warning "MANUAL STEP REQUIRED: Add this SSH key to GitHub manually:"
    echo ""
    echo "1. Copy the public key below"
    echo "2. Go to: https://github.com/settings/keys"
    echo "3. Click 'New SSH Key'"
    echo "4. Title: $KEY_NAME - $(date '+%Y-%m-%d %H:%M')"
    echo "5. Key type: Authentication Key"
    echo "6. Paste the key and click 'Add SSH Key'"
    echo ""
    echo "-----BEGIN PUBLIC KEY-----"
    cat "$HOME/.ssh/${KEY_NAME}.pub"
    echo "-----END PUBLIC KEY-----"
    echo ""
    read -p "Press Enter after you've added the key manually..."

    # Verify again after manual addition
    print_info "Verifying manual key addition..."
    VERIFY_KEYS=$(gh api user/keys --jq '.[] | {title: .title, key: .key}' 2>/dev/null)

    if echo "$VERIFY_KEYS" | grep -F "$PUBLIC_KEY" > /dev/null 2>&1; then
        print_success "Verification successful! SSH key is now on GitHub."
        return 0
    else
        print_warning "Could not verify the key. Please check manually:"
        echo "https://github.com/settings/keys"
        echo ""
        read -p "Press Enter to continue with setup (assuming key was added)..."
        return 0
    fi
}

# ==========================================
# 8. TEST SSH CONNECTION (FIXED)
# ==========================================

test_ssh_connection() {
    print_step "Testing SSH connection to GitHub..."

    # First, try with the specific key
    echo "Testing with: ssh -T -i ~/.ssh/$KEY_NAME git@github.com"
    echo "--------------------------------------------------"

    SSH_OUTPUT=$(ssh -T -i "$HOME/.ssh/$KEY_NAME" git@github.com 2>&1)
    SSH_EXIT_CODE=$?

    echo "$SSH_OUTPUT"
    echo "--------------------------------------------------"

    # Check for successful authentication message
    if echo "$SSH_OUTPUT" | grep -q "You've successfully authenticated"; then
        print_success "SSH connection successful!"
        print_info "GitHub recognized your SSH key."
        return 0
    elif [ $SSH_EXIT_CODE -eq 1 ] && echo "$SSH_OUTPUT" | grep -q "successfully authenticated"; then
        # Sometimes exit code 1 but message says success
        print_success "SSH connection successful!"
        print_info "GitHub recognized your SSH key."
        return 0
    elif echo "$SSH_OUTPUT" | grep -q "Permission denied (publickey)"; then
        print_error "SSH connection failed: Permission denied"
        print_warning "The SSH key is not being accepted by GitHub."
        echo ""
        print_info "Troubleshooting steps:"
        echo "1. Verify the key is on GitHub: https://github.com/settings/keys"
        echo "2. Check that you're using the correct key: ~/.ssh/$KEY_NAME"
        echo "3. Try adding the key to ssh-agent:"
        echo "   eval \"\$(ssh-agent -s)\""
        echo "   ssh-add ~/.ssh/$KEY_NAME"
        echo "   ssh -T git@github.com"
        echo ""
        read -p "Press Enter to continue (after troubleshooting)..."
        return 1
    else
        print_warning "SSH connection test returned: $SSH_EXIT_CODE"
        print_info "Output: $SSH_OUTPUT"
        read -p "Press Enter to continue..."
        return $SSH_EXIT_CODE
    fi
}

# ==========================================
# 9. FINAL OUTPUT AND INSTRUCTIONS
# ==========================================

print_final_instructions() {
    echo ""
    print_header "SUCCESS: Local Environment Initialized!"
    echo ""

    echo "YOUR SSH PUBLIC KEY (save for reference):"
    echo "----------------------------------------------------------------------"
    cat "$HOME/.ssh/${KEY_NAME}.pub"
    echo "----------------------------------------------------------------------"
    echo ""

    echo "REPOSITORY INFORMATION:"
    echo "  Local directory: $(pwd)"
    echo "  Git user: $USER_NAME"
    echo "  Git email: $USER_EMAIL"
    echo "  SSH key: ~/.ssh/$KEY_NAME"
    echo ""

    echo "STEP 1: LINK YOUR REMOTE REPOSITORY"
    echo "  Run these commands to link your local folder to GitHub:"
    echo ""

    if [ -n "$REPO_SSH_URL" ]; then
        echo "  git branch -M main"
        echo "  git remote add origin $REPO_SSH_URL"
        echo "  git push -u origin main"
        echo ""
        echo "STEP 2: CREATE YOUR FIRST FILE AND PUSH"
        echo "  echo \"# $(basename $(pwd))\" > README.md"
        echo "  git add README.md"
        echo "  git commit -m \"Initial commit\""
        echo "  git push -u origin main"
        echo ""
    else
        echo "  git branch -M main"
        echo "  git remote add origin git@github.com:YOUR_USERNAME/YOUR_REPO_NAME.git"
        echo "  git push -u origin main"
        echo ""
        echo "TIPS:"
        echo "  - Replace 'YOUR_USERNAME' with your GitHub username"
        echo "  - Replace 'YOUR_REPO_NAME' with the repository name you created"
        echo "  - Example: git@github.com:snakeandmoon/snakeandmoon.github.io.git"
        echo ""
        echo "STEP 2: CREATE YOUR FIRST FILE AND PUSH"
        echo "  echo \"# $(basename $(pwd))\" > README.md"
        echo "  git add README.md"
        echo "  git commit -m \"Initial commit\""
        echo "  git push -u origin main"
        echo ""
    fi

    echo "STEP 3: TEST SSH CONNECTION (if not already done)"
    echo "  ssh -T -i ~/.ssh/$KEY_NAME git@github.com"
    echo ""

    echo "AUTHENTICATION SUMMARY:"
    echo "  ┌─────────────────────────────────────────────────────────────────────┐"
    echo "  │  PHASE          PROTOCOL     WHAT IT DOES                          │"
    echo "  ├─────────────────────────────────────────────────────────────────────┤"
    echo "  │  gh auth login  HTTPS        Creates OAuth token for gh API access │"
    echo "  │  Script runs    -            Generates SSH key                    │"
    echo "  │  Script adds    HTTPS        Uses OAuth token to add SSH key       │"
    echo "  │  git push       SSH          Uses SSH key (no password!)          │"
    echo "  └─────────────────────────────────────────────────────────────────────┘"
    echo ""
    echo "SECURITY NOTES:"
    echo "  - Private key: ~/.ssh/$KEY_NAME (KEEP SECRET!)"
    echo "  - Public key: ~/.ssh/${KEY_NAME}.pub (Share this with services)"
    echo "  - Never share your private key or commit it to version control"
    echo "  - No passwords are stored in scripts or config files"
    echo ""

    print_header "Setup Complete! Happy Coding!"
    echo ""
}

# ==========================================
# 10. MAIN EXECUTION FLOW
# ==========================================

main() {
    print_header "GITHUB REPOSITORY AUTOMATED SETUP"
    echo ""

    # Check if REPO_SSH_URL is set
    if [ -z "$REPO_SSH_URL" ]; then
        print_warning "REPO_SSH_URL is not set in the script variables."
        echo "You'll need to manually link your repository later."
        echo ""
    else
        print_info "Repository SSH URL: $REPO_SSH_URL"
        echo ""
    fi

    # Show current settings
    echo "Settings:"
    echo "  Username: $USER_NAME"
    echo "  Email: $USER_EMAIL"
    echo "  Key name: $KEY_NAME"
    echo "  Repository URL: ${REPO_SSH_URL:-Not set (will link manually)}"
    echo "  Current directory: $(pwd)"
    echo ""

    read -p "Continue with these settings? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Setup aborted. Edit the variables in Section 1 and try again."
        exit 1
    fi

    # Execute setup steps
    check_github_cli
    echo ""

    check_authentication
    echo ""

    generate_ssh_key
    echo ""

    initialize_git_repo
    echo ""

    add_ssh_key_to_github
    echo ""

    test_ssh_connection
    echo ""

    print_final_instructions
}

# ==========================================
# 11. SCRIPT EXECUTION START
# ==========================================

# Check if the script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
else
    echo "⚠️  This script is being sourced. Run it directly with: ./setup.sh"
fi

# =============================================================================
# END OF SCRIPT
# =============================================================================
