#!/bin/sh

# Copyright 2017 Sean Kelleher. All rights reserved.

# `$0 <user> <dir>` installs infrastructure for repogate deployments for
# `<user>` to `<dir>`
#
# This script assumes that `<user>` is a member of a group of the same name.

set -o errexit

if [ $# -ne 2 ] ; then
    echo "usage: $0 <user> <dir>" >&2
    exit 1
fi

user=$1
dir=$2

install \
    --owner="$user" \
    --group="$user" \
    --mode=0744 \
    --directory \
    "/home/$user/deploy_rg"

for dir in scripts scripts/secrets repos ; do
    install \
        --owner="$user" \
        --group="$user" \
        --mode=0744 \
        --directory \
        "/home/$user/deploy_rg/$dir"

    if [ -d "$dir" ] ; then
        install \
            --owner="$user" \
            --group="$user" \
            --mode=0644 \
            $(find "$dir" -maxdepth 1 -type f) \
            "/home/$user/deploy_rg/$dir"
    fi
done
