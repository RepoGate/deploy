#!/bin/sh

# Copyright 2017 Sean Kelleher. All rights reserved.

# `$0 <frg> <test_proj_host_user> <test_proj_host> <test_proj_user>
# <test_proj_name>` starts and tests a local RepoGate deployment.

set -o errexit

if [ $# -ne 5 ] ; then
    echo "usage: $0 <frg> <test_proj_host_user> <test_proj_host> <test_proj_user> <test_proj_name>" >&2
    exit 1
fi

frg="$1"
test_proj_host_user="$2"
test_proj_host="$3"
test_proj_user="$4"
test_proj_name="$5"

img_name=repogate/local_test

bash scripts/docker_rbuild.sh \
    "$img_name" \
    latest \
    --file=docker/local_test/Dockerfile \
    .

cont_id=$(
    docker \
        create \
        --interactive \
        --tty \
        --rm \
        --workdir='/home/dev/deploy_rg' \
        "$img_name" \
        bash \
            -c \
            "
                set -o errexit

                # We run a 'sudo' command once to skip the warning that appears
                # before the first 'sudo' run.
                sudo true &>/dev/null

                sudo \
                    useradd \
                    --password='' \
                    --create-home \
                    repogate

                sudo \
                    bash \
                    scripts/install,start,check.sh \
                    \"\$PWD/frg\" \
                    $(date '+%Y%m%d_%H%M%S') \
                    \"$test_proj_host_user\" \
                    \"$test_proj_host\" \
                    \"$test_proj_user\" \
                    \"$test_proj_name\" \
            "
)

docker cp . "$cont_id":/home/dev/deploy_rg
docker cp "$frg" "$cont_id":/home/dev/deploy_rg

docker start --attach --interactive "$cont_id"
