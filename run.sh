#!/bin/bash
#
# manage environment and launch containers
set -euo pipefail

# Find project root by searching upward for compose.yaml
find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/compose.yaml" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "Error: Could not find compose.yaml in any parent directory" >&2
    exit 1
}

export PROJECT_ROOT="${PROJECT_ROOT:-$(find_project_root)}"
cd "${PROJECT_ROOT}"

if [[ ! -f .env ]]; then
    echo "Error: .env file not found"
    echo "Copy artifacts/env.example to .env and fill in your values"
    exit 1
fi

# Export current user info if not set
export CONTAINER_UID="${CONTAINER_UID:-$(id -u)}"
export CONTAINER_GID="${CONTAINER_GID:-$(id -g)}"

exec docker compose "$@"
