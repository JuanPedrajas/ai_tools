echo "# This file is located at 'src/review_command.sh'."
echo "# It contains the implementation for the 'juanbot review' command."
echo "# The code you write here will be wrapped by a function named 'juanbot_review_command()'."
echo "# Feel free to edit this file; your changes will persist when regenerating."
inspect_args

# Shows a loading message while a command runs.
# Usage: run_with_loading "Your message here" command arg1 arg2 ...
run_with_loading() {
    local message="$1"
    shift
    local command=("$@")

    echo "[.] $message" >&2
    # Execute command, capturing stdout, while allowing stderr to pass through.
    output=$("${command[@]}")
    local exit_code=$?
    echo "[+] DONE" >&2

    if [ $exit_code -ne 0 ]; then
        echo "Error: Command failed with exit code $exit_code" >&2
        return $exit_code
    fi

    echo "$output"
    return 0
}

# Gets the diff from a target branch.
# Usage: get_diff [target_branch] [pr_branch]
get_diff() {
    local target_branch="${1:-master}"
    local pr_branch="$2" # Can be empty if we are on the branch
    git diff "$target_branch" "$pr_branch"
}

# Gets an explanation of the diff from Gemini.
# The diff content is piped into this function.
get_explanation_from_gemini() {
    local diff_content
    diff_content=$(cat) # Read from stdin
    gemini -p "Explain the following diff: $diff_content"
}

# Generates the final review prompt.
generate_review_prompt() {
    local changes="$1"
    local explanation="$2"

    cat <<-EOF
# I want you to review a pr, here is the information:
## What to look out for:
- look at the code in the current directory
- look at its architectural patterns
- only give feedback regarding architecture and security (take into account the overall project architecture)
## PR information
The pr diff:
$changes

The explanation:
$explanation
EOF
}


# Example: ./review_pr.sh my-feature-branch
# Compares my-feature-branch against master.
# If no arg is given, compares current branch against master.
local source_branch=${args[source]}
local target_branch=${args[target]:-"master"}

local changes
changes=$(run_with_loading "Retrieving PR diff..." get_diff "$target_branch" "$source_branch")
if [ $? -ne 0 ]; then exit 1; fi

local explanation_of_pr
explanation_of_pr=$(echo "$changes" | run_with_loading "Understanding diff with Gemini..." get_explanation_from_gemini)
if [ $? -ne 0 ]; then exit 1; fi

local review_prompt
review_prompt=$(generate_review_prompt "$changes" "$explanation_of_pr")

echo "$review_prompt"

