#!/bin/sh

# Copyright 2017 Sean Kelleher. All rights reserved.

# `$0` starts the various services required for the all-in-one RepoGate
# container.

set -o errexit

secrets_dir=/secrets

if [ ! -e "$secrets_dir/privkey.pem" ] ; then
    if [ -e "$secrets_dir/cert.pem" ] ; then
        echo "'$secrets_dir/cert.pem' exists but '$secrets_dir/privkey.pem'" \
            "doesn't" 2>&1
        exit 1
    fi

    ls -l /secrets

    # https://www.ibm.com/support/knowledgecenter/en/SSWHYP_4.0.0/com.ibm.apimgmt.cmc.doc/task_apionprem_gernerate_self_signed_openSSL.html
    openssl \
        req \
        -newkey rsa:2048 \
        -nodes \
        -keyout "$secrets_dir"/privkey.pem \
        -x509 \
        -days 365 \
        -subj '/CN=example.com' \
        -out "$secrets_dir"/cert.pem
elif [ ! -e "$secrets_dir/cert.pem" ] ; then
    echo "'$secrets_dir/privkey.pem' exists but '$secrets_dir/cert.pem'" \
        "doesn't" 2>&1
    exit 1
fi

sess_id=$(date '+%Y%m%d_%H%M%S')

echo -n "Please enter a master password: "
master_pass="$(python scripts/get_pass.py)"

MASTER_PASSWORD="$master_pass" bash \
    scripts/start.sh \
    "$PWD/frg" \
    "$sess_id"

ln \
    -s \
    /secrets/cert.pem \
    /secrets/privkey.pem \
    /home/repogate/deploy_rg/secrets

var_dir="/var/tmp/node/$sess_id"
mkdir \
    --parents \
    /var/tmp/repo_update \
    "$var_dir"
MASTER_PASSWORD="$master_pass" node \
    index.js \
    2>&1 \
    | tee "$var_dir/log"
