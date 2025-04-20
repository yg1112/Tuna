#!/bin/bash

# Mock git environment
setup_mock_git() {
    # Create a temporary directory for the test
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR" || exit 1
    
    # Initialize git repo
    git init
    git config --global user.email "test@example.com"
    git config --global user.name "Test User"
    
    # Create main branch
    echo "initial" > file
    git add file
    git commit -m "Initial commit"
    git branch -M main
    
    # Create and setup mock branches
    # 1. Merged branch
    git checkout -b merged-branch
    echo "merged" >> file
    git add file
    git commit -m "Merged branch commit"
    git checkout main
    git merge merged-branch
    
    # 2. Stale branch (>30 days old)
    git checkout -b stale-branch
    echo "stale" >> file
    git add file
    git commit -m "Stale branch commit" --date="40 days ago"
    
    # 3. Active branch (<30 days old)
    git checkout -b active-branch
    echo "active" >> file
    git add file
    git commit -m "Active branch commit"
    
    git checkout main
}

# Clean up test environment
cleanup() {
    rm -rf "$TEST_DIR"
}

# Run the actual test
run_test() {
    # Source the branch hygiene script (mock version)
    source ../../scripts/branch-hygiene.sh
    
    # Test merged branches detection
    local merged_count=0
    while IFS= read -r branch; do
        if [[ "$branch" == "merged-branch" ]]; then
            ((merged_count++))
        fi
    done < <(git branch --merged main | grep -v "main")
    
    # Test stale branches detection
    local stale_count=0
    while IFS= read -r branch; do
        if [[ "$branch" == "stale-branch" ]]; then
            last_commit=$(git log -1 --format=%ct "$branch")
            current_time=$(date +%s)
            days_old=$(( (current_time - last_commit) / 86400 ))
            if [[ $days_old -ge 30 ]]; then
                ((stale_count++))
            fi
        fi
    done < <(git branch | grep -v "main")
    
    # Test active branches detection
    local active_count=0
    while IFS= read -r branch; do
        if [[ "$branch" == "active-branch" ]]; then
            last_commit=$(git log -1 --format=%ct "$branch")
            current_time=$(date +%s)
            days_old=$(( (current_time - last_commit) / 86400 ))
            if [[ $days_old -lt 30 ]]; then
                ((active_count++))
            fi
        fi
    done < <(git branch | grep -v "main")
    
    # Assert results
    if [[ $merged_count -eq 1 && $stale_count -eq 1 && $active_count -eq 1 ]]; then
        echo "All tests passed!"
        return 0
    else
        echo "Tests failed!"
        echo "Expected: 1 merged, 1 stale, 1 active"
        echo "Got: $merged_count merged, $stale_count stale, $active_count active"
        return 1
    fi
}

# Run the test suite
setup_mock_git
run_test
test_result=$?
cleanup

exit $test_result 