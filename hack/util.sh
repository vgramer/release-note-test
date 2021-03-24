#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail


function util::command_exists() {
	command -v "$1" >/dev/null 2>&1
}


function util::fatal() {
	echo "Error: $1"
	exit 1
}

function util::require-hub() {
  util::command_exists "hub" || util::fatal 'hub not found in path. please install it before running script. see instruction at https://hub.github.com/'
}