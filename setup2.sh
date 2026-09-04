#!/bin/bash

# =============================================================================
# STEP-BY-STEP CONFIGURATION & EXECUTION INSTRUCTIONS
# =============================================================================
#
#   [PHASE 1: PREREQUISITES - DO BEFORE RUNNING THIS SCRIPT]
#   1. Install GitHub CLI (gh) if not already installed:
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
#   2. IMPORTANT: Authenticate GitHub CLI BEFORE running the script:
#      Run: gh auth login
#
#      When prompted, you MUST choose HTTPS (even though we'll use SSH later!)
#
#      Why choose HTTPS now?
#      - You haven't generated the SSH key yet (the script will do this)
#      - gh needs an OAuth token to talk to GitHub API
#      - The script will use this token to add your SSH key to GitHub
#      - After the script runs, git will be reconfigured to use SSH
#
#   3. Log into your browser and create a new empty GitHub repository:
#      - Go to: https://github.com/new
#      - Repository name: e.g., yourusername.github.io or project-name
#      - *CRITICAL*: Leave ALL initialization checkboxes UNCHECKED
#      - Click "Create repository"
#      - Copy the SSH URL (e.g., git@github.com:username/repo-name.git)
#      - Save this URL for the REPO_SSH_URL variable below
#
#   4. Create your local project folder and script:
#      mkdir -p ~/Development/[github-account-folder]/[repository-folder]
#      cd ~/Development/[github-account-folder]/[repository-folder]
#      Create setup.sh with this script and update the variables below.
#
#   [PHASE 2: EXECUTION]
#   5. Make the script executable: chmod +x setup.sh
#   6. Execute the script: ./setup.sh
#
#   [PHASE 3: WHAT THE SCRIPT DOES]
#   7. Checks if gh is installed and authenticated
#   8. Generates a new Ed25519 SSH key
#   9. Initializes git repository locally
#   10. Configures git to use your SSH key
#   11. Adds your SSH key to GitHub (using the OAuth token)
#   12. Tests SSH connection to GitHub
#   13. LINKS THE REMOTE REPOSITORY
#   14. PULLS or PUSHES content based on remote state
#   15. Shows final instructions
#
# =============================================================================

# ==========================================
# 1. USER VARIABLES (EDIT THESE FOR THE NEW PROJECT)
# ==========================================
USER_NAME="snakeandmoon"
USER_EMAIL="mrsleeokwei@gmail.com"
KEY_NAME="snakeandmoon"  # Filename for the unique SSH key file
REPO_SSH_URL="git@github.com:snakeandmoon/snakeandmoon.github.io"  # REPLACE WITH: git@github.com:username/repo-name.git
REPO_NAME="snakeandmoon/snakeandmoon.github.io"  # For gh commands: username/repo-name

# ==========================================
# 2. HELPER FUNCTIONS
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
        echo "macOS: brew install gh"
        echo "Windows: winget install --id GitHub.cli --source winget"
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
        echo "What will happen:"
        echo "  1. Your browser will open (or you'll get a device code)"
        echo "  2. You'll log in with your GitHub password + 2FA (if enabled)"
        echo "  3. GitHub will issue an OAuth token for gh"
        echo "  4. The token will be stored securely on your system"
        echo ""
        read -p "Press Enter to start authentication..."

        gh auth login

        if [ $? -ne 0 ]; then
            print_error "Authentication failed."
            return 1
        fi
    fi

    print_success "Authenticated as: $(gh api user --jq '.login' 2>/dev/null || echo 'Unknown')"
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
        # Backup old key
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
}

# ==========================================
# 7. ADD SSH KEY TO GITHUB
# ==========================================

add_ssh_key_to_github() {
    print_step "Adding SSH key to GitHub..."

    PUBLIC_KEY=$(cat "$HOME/.ssh/$KEY_NAME.pub" | tr -d '\n')

    print_info "Fetching current SSH keys from GitHub..."
    EXISTING_KEYS=$(gh api user/keys --jq '.[] | {title: .title, key: .key}' 2>/dev/null)

    if [ $? -ne 0 ]; then
        print_warning "Could not fetch SSH keys from GitHub."
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
        read -p "Press Enter after you've added the key..."
        return 0
    fi

    # Check if key already exists
    KEY_EXISTS=$(echo "$EXISTING_KEYS" | grep -F "$PUBLIC_KEY" 2>/dev/null)

    if [ -n "$KEY_EXISTS" ]; then
        print_warning "This SSH key already exists on your GitHub account."
        return 0
    fi

    print_info "Adding SSH key to GitHub..."
    gh ssh-key add "$HOME/.ssh/$KEY_NAME.pub" \
        --title "$KEY_NAME - $(date '+%Y-%m-%d %H:%M:%S')" \
        --type authentication 2>/dev/null

    if [ $? -eq 0 ]; then
        print_success "SSH key successfully added to GitHub!"
    else
        print_error "Failed to add SSH key to GitHub."
        print_warning "Please add it manually:"
        echo ""
        echo "1. Go to: https://github.com/settings/keys"
        echo "2. Click 'New SSH Key'"
        echo "3. Title: $KEY_NAME - $(date '+%Y-%m-%d %H:%M')"
        echo "4. Paste the public key below:"
        echo ""
        cat "$HOME/.ssh/${KEY_NAME}.pub"
        echo ""
        read -p "Press Enter after you've added the key..."
    fi
}

# ==========================================
# 8. TEST SSH CONNECTION
# ==========================================

test_ssh_connection() {
    print_step "Testing SSH connection to GitHub..."

    echo "Testing with: ssh -T -i ~/.ssh/$KEY_NAME git@github.com"
    echo "--------------------------------------------------"

    SSH_OUTPUT=$(ssh -T -i "$HOME/.ssh/$KEY_NAME" git@github.com 2>&1)
    SSH_EXIT_CODE=$?

    echo "$SSH_OUTPUT"
    echo "--------------------------------------------------"

    if echo "$SSH_OUTPUT" | grep -q "You've successfully authenticated"; then
        print_success "SSH connection successful!"
        return 0
    elif echo "$SSH_OUTPUT" | grep -q "Permission denied (publickey)"; then
        print_error "SSH connection failed: Permission denied"
        print_warning "The SSH key is not being accepted by GitHub."
        echo ""
        print_info "Troubleshooting steps:"
        echo "1. Verify the key is on GitHub: https://github.com/settings/keys"
        echo "2. Try adding the key to ssh-agent:"
        echo "   eval \"\$(ssh-agent -s)\""
        echo "   ssh-add ~/.ssh/$KEY_NAME"
        echo "   ssh -T git@github.com"
        echo ""
        read -p "Press Enter to continue..."
        return 1
    else
        print_warning "SSH connection test returned: $SSH_EXIT_CODE"
        return $SSH_EXIT_CODE
    fi
}

# ==========================================
# 9. LINK AND SYNC REMOTE REPOSITORY
# ==========================================

link_and_sync_remote() {
    print_step "Linking remote repository..."

    # Check if remote already exists
    if git remote get-url origin &> /dev/null; then
        print_warning "Remote 'origin' already exists: $(git remote get-url origin)"
        read -p "Do you want to update it to: $REPO_SSH_URL? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git remote set-url origin "$REPO_SSH_URL"
            print_success "Remote URL updated."
        else
            print_info "Keeping existing remote configuration."
        fi
    else
        # Add the remote
        git remote add origin "$REPO_SSH_URL"
        print_success "Remote added: $REPO_SSH_URL"
    fi

    # Set default branch to main
    git branch -M main 2>/dev/null || print_info "Branch already named main"

    # Check if remote has content
    print_step "Checking remote repository status..."

    # Try to fetch to see if remote has content
    git fetch origin 2>/dev/null

    if [ $? -ne 0 ]; then
        print_warning "Could not fetch from remote. It may not exist or may be empty."
        print_info "Creating initial commit and pushing..."

        # Create README if none exists
        if [ ! -f "README.md" ]; then
            echo "# $(basename $(pwd))" > README.md
            print_success "Created README.md"
        fi

        # Add and commit
        git add .
        if ! git diff --cached --quiet; then
            git commit -m "Initial commit"
            print_success "Created initial commit"
        fi

        # Push
        git push -u origin main
        if [ $? -eq 0 ]; then
            print_success "Successfully pushed to GitHub!"
        else
            print_error "Failed to push. You may need to push manually."
            echo "Try: git push -u origin main"
        fi
    else
        print_success "Successfully fetched from remote."

        # Check if remote has content
        REMOTE_HAS_CONTENT=$(git ls-remote origin main 2>/dev/null | wc -l)

        if [ "$REMOTE_HAS_CONTENT" -gt 0 ]; then
            print_info "Remote repository has content. Pulling..."

            # Pull with unrelated histories
            git pull origin main --allow-unrelated-histories --no-edit

            if [ $? -eq 0 ]; then
                print_success "Successfully pulled from GitHub!"
            else
                print_warning "Pull had issues. You may need to resolve conflicts."
                echo "Try: git pull origin main --allow-unrelated-histories"
            fi
        else
            print_info "Remote repository is empty. Preparing to push..."

            # Create README if none exists
            if [ ! -f "README.md" ]; then
                echo "# $(basename $(pwd))" > README.md
                print_success "Created README.md"
            fi

            # Add and commit local changes
            git add .
            if ! git diff --cached --quiet; then
                git commit -m "Initial commit"
                print_success "Created initial commit"
            fi

            # Push
            git push -u origin main
            if [ $? -eq 0 ]; then
                print_success "Successfully pushed to GitHub!"
            else
                print_error "Failed to push. You may need to push manually."
                echo "Try: git push -u origin main"
            fi
        fi
    fi

    # Show final status
    echo ""
    print_info "Current repository status:"
    git log --oneline --graph --all --decorate -n 5 2>/dev/null || echo "No commits yet"
    echo ""
}

# ==========================================
# 10. FINAL OUTPUT AND INSTRUCTIONS
# ==========================================

print_final_instructions() {
    echo ""
    print_header "SUCCESS: Repository Setup Complete!"
    echo ""

    echo "REPOSITORY INFORMATION:"
    echo "  Local directory: $(pwd)"
    echo "  Remote: $REPO_SSH_URL"
    echo "  SSH key: ~/.ssh/$KEY_NAME"
    echo ""

    echo "NEXT STEPS:"
    echo "  1. Make changes to your files"
    echo "  2. git add ."
    echo "  3. git commit -m \"Your message\""
    echo "  4. git push"
    echo ""

    echo "USEFUL COMMANDS:"
    echo "  git status          - Check current state"
    echo "  git log             - View commit history"
    echo "  git pull            - Get latest changes"
    echo "  git push            - Push your changes"
    echo ""

    echo "SECURITY NOTES:"
    echo "  - Private key: ~/.ssh/$KEY_NAME (KEEP SECRET!)"
    echo "  - Never share your private key or commit it to version control"
    echo ""

    print_header "Setup Complete! Happy Coding! 🚀"
    echo ""
}

# ==========================================
# 11. MAIN EXECUTION FLOW
# ==========================================

main() {
    print_header "GITHUB REPOSITORY AUTOMATED SETUP"
    echo ""

    print_info "Repository SSH URL: $REPO_SSH_URL"
    echo ""

    echo "Settings:"
    echo "  Username: $USER_NAME"
    echo "  Email: $USER_EMAIL"
    echo "  Key name: $KEY_NAME"
    echo "  Repository URL: $REPO_SSH_URL"
    echo "  Current directory: $(pwd)"
    echo ""

    read -p "Continue with these settings? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Setup aborted."
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

    link_and_sync_remote
    echo ""

    print_final_instructions
}

# ==========================================
# 12. SCRIPT EXECUTION START
# ==========================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
else
    echo "⚠️  This script is being sourced. Run it directly with: ./setup.sh"
fi

# =============================================================================
# END OF SCRIPT
# =============================================================================
