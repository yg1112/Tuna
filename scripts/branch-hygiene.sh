#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize arrays
declare -a MERGED_BRANCHES=()
declare -a STALE_BRANCHES=()
declare -a KEEP_BRANCHES=()

# Whitelist of protected branches
PROTECTED_BRANCHES=("main" "old-main")

# Function to check if a branch is protected
is_protected() {
    local branch=$1
    for protected in "${PROTECTED_BRANCHES[@]}"; do
        if [[ "$branch" == "$protected" || "$branch" == "origin/$protected" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to print status table
print_status_table() {
    echo -e "\n${GREEN}Branch Hygiene Summary:${NC}"
    echo -e "${YELLOW}----------------------------------------${NC}"
    echo -e "${GREEN}Merged Branches to Delete:${NC}"
    printf '%s\n' "${MERGED_BRANCHES[@]}"
    echo -e "\n${YELLOW}Stale Branches to Delete:${NC}"
    printf '%s\n' "${STALE_BRANCHES[@]}"
    echo -e "\n${GREEN}Branches to Keep:${NC}"
    printf '%s\n' "${KEEP_BRANCHES[@]}"
    echo -e "${YELLOW}----------------------------------------${NC}"
}

# Fetch and prune
echo "Fetching and pruning remote branches..."
git fetch --all --prune

# Get merged branches
echo "Identifying merged branches..."
while IFS= read -r branch; do
    branch=$(echo "$branch" | tr -d '[:space:]')
    if [[ -n "$branch" ]] && ! is_protected "${branch##origin/}"; then
        MERGED_BRANCHES+=("$branch")
    fi
done < <(git branch -r --merged origin/main | grep -v "HEAD")

# Get stale branches (>30 days old, no PR, not merged)
echo "Identifying stale branches..."
while IFS= read -r line; do
    branch=$(echo "$line" | awk '{print $NF}')
    if [[ -n "$branch" ]] && ! is_protected "${branch##refs/remotes/origin/}"; then
        # Check if branch is not in MERGED_BRANCHES and is older than 30 days
        if ! printf '%s\n' "${MERGED_BRANCHES[@]}" | grep -q "^origin/${branch##refs/remotes/origin/}$"; then
            last_commit=$(git log -1 --format=%ct "origin/${branch##refs/remotes/origin/}" 2>/dev/null)
            current_time=$(date +%s)
            days_old=$(( (current_time - last_commit) / 86400 ))
            
            if [[ $days_old -ge 30 ]]; then
                # Check if there's no open PR for this branch
                branch_name="${branch##refs/remotes/origin/}"
                if ! gh pr list --state open --head "$branch_name" 2>/dev/null | grep -q .; then
                    STALE_BRANCHES+=("origin/$branch_name")
                fi
            fi
        fi
    fi
done < <(git for-each-ref --sort=committerdate refs/remotes/origin/ --format='%(refname)')

# Get branches to keep
echo "Identifying branches to keep..."
while IFS= read -r branch; do
    branch=$(echo "$branch" | tr -d '[:space:]')
    if [[ -n "$branch" ]] && ! is_protected "${branch##origin/}"; then
        if ! printf '%s\n' "${MERGED_BRANCHES[@]}" "${STALE_BRANCHES[@]}" | grep -q "^$branch$"; then
            KEEP_BRANCHES+=("$branch")
        fi
    fi
done < <(git branch -r | grep -v "HEAD")

# Print status table
print_status_table

# Delete merged branches
echo -e "\n${GREEN}Deleting merged branches...${NC}"
for branch in "${MERGED_BRANCHES[@]}"; do
    branch_name="${branch##origin/}"
    echo "Deleting merged branch: $branch_name"
    git branch -d "$branch_name" 2>/dev/null || true
    git push origin --delete "$branch_name" 2>/dev/null || {
        echo -e "${RED}Failed to delete remote branch: $branch_name${NC}"
        exit 1
    }
done

# Delete stale branches
echo -e "\n${YELLOW}Deleting stale branches...${NC}"
for branch in "${STALE_BRANCHES[@]}"; do
    branch_name="${branch##origin/}"
    echo -e "${YELLOW}Warning: Deleting stale branch: $branch_name${NC}"
    git branch -D "$branch_name" 2>/dev/null || true
    git push origin --delete "$branch_name" 2>/dev/null || {
        echo -e "${RED}Failed to delete remote branch: $branch_name${NC}"
        exit 1
    }
done

echo -e "\n${GREEN}Branch cleanup completed successfully!${NC}"
exit 0 