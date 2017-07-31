#!/bin/sh

# Copyright 2017 Sean Kelleher. All rights reserved.

# `$0` tests a docker-based RepoGate deployment in a container.

set -o errexit

if [ $# -ne 6 ] ; then
    echo "usage: $0 <frg> <secrets-dir> <test-proj-host-user> <test-proj-host> <test-proj-user> <test-proj-name>" >&2
    exit 1
fi

frg=$1
secrets_dir=$2
test_proj_host_user=$3
test_proj_host=$4
test_proj_user=$5
test_proj_name=$6
sess_id=test

img_name=repogate/allinone
cont_name=repogate.allinone_test

https_port=10001
gitd_port=10002
wall_port=10003
bash \
    -x \
    docker/allinone/start.sh \
    "$frg" \
    "$secrets_dir" \
    "$cont_name" \
    "$https_port" \
    "127.0.0.1" \
    "$gitd_port" \
    "127.0.0.1" \
    "$wall_port"

trap '
    echo "Stopping container..."
    echo "Stopped container $(docker stop $cont_name)"
    docker logs $cont_name | sed "s/^/[logs] /"
    echo "Removing container..."
    echo "Removed container $(docker rm $cont_name)"
' EXIT

var_dir="/var/tmp/repos/$sess_id"
rm -rf "$var_dir"

echo -n "Please enter password for 'https://$test_proj_host_user@$test_proj_host': "
test_proj_host_pass="$(python scripts/get_pass.py)"

bash \
    docker/allinone/check.sh \
    "$frg" \
    "$cont_name" \
    "$sess_id" \
    "$test_proj_host_user" \
    "$test_proj_host_pass" \
    "$test_proj_host" \
    "$test_proj_user" \
    "$test_proj_name"
