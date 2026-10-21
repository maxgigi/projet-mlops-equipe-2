#!/usr/bin/env bash
set -euo pipefail
pre-commit run --all-files
# TODO: kubeconform / helm lint / tofu validate / ansible-lint
