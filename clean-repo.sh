#!/bin/bash
set -e

echo "Step 1: Backup current repository"
cd ~/Desktop/proton/
cp -r proton proton-backup

echo "Step 2: Clone fresh shallow copy of the containers branch"
git clone --depth 1 --branch containers https://github.com/Mkhwanazi-B/proton.git proton-clean
cd proton-clean

echo "Step 3: Remove all .terraform directories and Terraform state files"
find . -name ".terraform*" -exec rm -rf {} + 2>/dev/null || true
find . -name "*.tfstate*" -exec rm -rf {} + 2>/dev/null || true

echo "Step 4: Create comprehensive .gitignore"
cat > .gitignore << 'EOF'
# Terraform files
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example
.terraformrc
terraform.rc
*.tfplan
*.tfplan.*
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraform.d/
crash.log
crash.*.log

# Large binaries
*.exe
*.dll
*.so
*.dylib

# OS and IDE files
.DS_Store
Thumbs.db
.vscode/
.idea/
*.swp
*.swo
*~

# Build artifacts
target/
build/
dist/
*.war
*.jar
*.class
node_modules/

# Logs
*.log
logs/

# Environment files
.env
.env.local
.env.*.local
EOF

echo "Step 5: Repository size after cleanup"
du -sh .git

echo "Step 6: Commit the clean state"
git add .
git commit -m "Clean repository: Remove Terraform binaries and add comprehensive .gitignore

- Removed all .terraform/ directories and state files
- Added comprehensive .gitignore for Terraform, build artifacts, and OS files
- Repository is now clean and ready for development"

echo "Step 7: Force push the clean version"
git push origin containers --force

echo "✅ Repository cleanup complete!"

