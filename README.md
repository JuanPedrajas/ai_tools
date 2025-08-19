# Juanbot

This repository contains a collection of tools designed to integrate AI into a developer's workflow. The main tool is `juanbot`, a command-line utility that helps with code reviews and other functions.

## Installation

To install `juanbot`, run the following command:

```bash
./install.sh
```

This will install the `juanbot` script to `~/.local/bin`. Make sure this directory is in your `PATH`.

### Dependencies

The following dependencies are required:

*   `git`
*   `gemini`

## Uninstallation

To uninstall `juanbot`, run the following command:

```bash
./uninstall.sh
```

## Usage

### `juanbot review`

This command provides a review of a pull request. It does this by:

1.  Getting the diff between the source and target branches.
2.  Using Gemini to get an explanation of the diff.
3.  Generating a prompt that can be used to get a final review from Gemini.

#### Arguments

*   `SOURCE`: The name of the source branch (the branch with the new changes).
*   `TARGET` (optional): The name of the target branch (the branch to compare against). Defaults to `master`.

#### Examples

```bash
# Review the changes in the 'ACC-224' branch against 'master'
juanbot review ACC-224

# Review the changes in the 'ACC-224' branch against 'dev'
juanbot review ACC-224 dev
```