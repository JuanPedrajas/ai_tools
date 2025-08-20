# Shows a loading message while a command runs.
# Usage: run_with_loading "Your message here" command arg1 arg2 ...
run_with_loading() {
    local message="$1"
    shift
    local command=("$@")

    echo "[-] $message" >&2
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

# A function to sleep for a specified number of seconds while showing a loading animation.
# Usage: sleep_with_loading <seconds>
sleep_with_loading() {
  local duration=$1
  echo -n "Loading " >&2
  for (( i=0; i<duration; i++ )); do
    echo -n "." >&2
    sleep 1
  done
  echo "" # Move to the next line after finishing
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
    local tmp_filename
    diff_content="$(cat)" # Read from stdin
    tmp_filename="$(pwd)/.$(cat /dev/random | head -c 5 | base64)"
    echo $diff_content > $tmp_filename
    sleep_with_loading 5
    gemini -p "Explain the following diff: $tmp_filename"
    rm $tmp_filename
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

generate_pr_review() {
    local prompt=$(echo $1)
    local tmp_filename="$(pwd)/.$(cat /dev/random | head -c 5 | base64)"
    echo $prompt > $tmp_filename
    sleep_with_loading 5
    gemini -p "Run the prompt in this file: @$tmp_filename"
    rm $tmp_filename
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

pr_review=$(run_with_loading "Exploring code and being critic..." generate_pr_review "$review_prompt")
if [ $? -ne 0 ]; then exit 1; fi

echo "# Explained PR:"
echo "$explanation_of_pr"
echo "# The review:"
echo "$pr_review"

