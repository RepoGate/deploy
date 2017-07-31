#!/bin/bash

# Copyright 2017 Sean Kelleher. All rights reserved.

# `$0 <frg> <sess-id>` starts a local RepoGate deployment.

set -o errexit

if [ $# -ne 2 ] ; then
    echo "usage: $0 <frg> <sess-id>" >&2
    exit 1
fi

frg=$1
sess_id=$2

rg_home='/home/repogate'
repo_log_dir='/var/tmp/repo_update'

su - repogate bash -c "
    set -o errexit

    echo '$sess_id' > cur_sess.txt

    bash \
        '$rg_home/deploy_rg/scripts/start_ro_gitd.sh' \
        '$rg_home/deploy_rg/repos' \
        '$sess_id'

    MASTER_PASSWORD='$MASTER_PASSWORD' PATH='$rg_home/bin:$PATH' bash \
        '$rg_home/deploy_rg/scripts/start_frg.sh' \
        '$rg_home/deploy_rg/repos' \
        '$sess_id' \
        '$frg'

    mkdir --parents '$repo_log_dir'
"
