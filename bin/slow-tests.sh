#!/usr/bin/env bash

set -e

### The following section defines `realpath` to resolve symbolic links.
###
### Copyright (c) 2014 Michael Kropat
### Licensed under the terms of the MIT License (https://opensource.org/licenses/MIT)
### Original code at https://github.com/mkropat/sh-realpath

realpath() {
    canonicalize_path "$(resolve_symlinks "$1")"
}

resolve_symlinks() {
    _resolve_symlinks "$1"
}

_resolve_symlinks() {
    _assert_no_path_cycles "$@" || return

    local dir_context path
    path=$(readlink -- "$1")
    if [ $? -eq 0 ]; then
        dir_context=$(dirname -- "$1")
        _resolve_symlinks "$(_prepend_dir_context_if_necessary "$dir_context" "$path")" "$@"
    else
        printf '%s\n' "$1"
    fi
}

_prepend_dir_context_if_necessary() {
    if [ "$1" = . ]; then
        printf '%s\n' "$2"
    else
        _prepend_path_if_relative "$1" "$2"
    fi
}

_prepend_path_if_relative() {
    case "$2" in
        /* ) printf '%s\n' "$2" ;;
         * ) printf '%s\n' "$1/$2" ;;
    esac
}

_assert_no_path_cycles() {
    local target path

    target=$1
    shift

    for path in "$@"; do
        if [ "$path" = "$target" ]; then
            return 1
        fi
    done
}

canonicalize_path() {
    if [ -d "$1" ]; then
        _canonicalize_dir_path "$1"
    else
        _canonicalize_file_path "$1"
    fi
}

_canonicalize_dir_path() {
    (cd "$1" 2>/dev/null && pwd -P)
}

_canonicalize_file_path() {
    local dir file
    dir=$(dirname -- "$1")
    file=$(basename -- "$1")
    (cd "$dir" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$file")
}

### end of realpath code

BIN_DIR=$( dirname "$( realpath "${BASH_SOURCE[0]}" )" )
BASE_DIR=$( dirname "$BIN_DIR" )

cd "$BASE_DIR" || exit 1

SBT_OPTS="-batch -Dparallel=5 -Dsbt.color=always -Dsbt.supershell=false"

echo "Running the full test suite (slow tests enabled)..."
echo "$ RUN_SLOW_TESTS=true sbt $SBT_OPTS it:test"
RUN_SLOW_TESTS=true sbt $SBT_OPTS it:test
