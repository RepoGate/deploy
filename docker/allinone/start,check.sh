#!/bin/sh

# Copyright 2017 Sean Kelleher. All rights reserved.

# `$0` starts a docker-based RepoGate deployment in a container and checks that
# it's running as expected.

set -o errexit

if [ $# -ne 12 ] ; then
    echo "usage: $0 <frg> <secrets-dir> <cont-name> <sess-id> <https-port> <gitd-ip> <gitd-port> <wall-ip> <wall-port> <test-proj-host-user> <test-proj-host> <test-proj-user> <test-proj-name>" >&2
    exit 1
fi

frg="$1"
secrets_dir="$2"
cont_name="$3"
sess_id="$4"
https_port="$5"
gitd_ip="$6"
gitd_port="$7"
wall_ip="$8"
wall_port="$9"
test_proj_host_user="${10}"
test_proj_host="${11}"
test_proj_user="${12}"
test_proj_name="${13}"

bash \
    docker/allinone/start.sh \
    "$frg" \
    "$secrets_dir" \
    "$cont_name" \
    "$https_port" \
    "$gitd_ip" \
    "$gitd_port" \
    "$wall_ip" \
    "$wall_port"

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
