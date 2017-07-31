#!/bin/sh

# Copyright 2017 Sean Kelleher. All rights reserved.

# `$0` tests a local RepoGate deployment and a docker-based RepoGate deployment.

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

bash \
    -x \
    docker/local_test/test.sh \
    "$frg" \
    "$test_proj_host_user" \
    "$test_proj_host" \
    "$test_proj_user" \
    "$test_proj_name"

# TODO Test with private key/certificate and without.

secrets_dir=$(mktemp --directory)
rm -rf $secrets_dir

bash \
    docker/allinone/test.sh \
    "$frg" \
    "$secrets_dir" \
    "$test_proj_host_user" \
    "$test_proj_host" \
    "$test_proj_user" \
    "$test_proj_name"

secrets_dir=$(mktemp --directory)
rm -rf $secrets_dir

bash \
    docker/allinone/with_docker/test.sh \
    "$frg" \
    "$secrets_dir" \
    "$test_proj_host_user" \
    "$test_proj_host" \
    "$test_proj_user" \
    "$test_proj_name"
