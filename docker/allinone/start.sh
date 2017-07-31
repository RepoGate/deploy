#!/bin/sh

# Copyright 2017 Sean Kelleher. All rights reserved.

# `$0` starts a docker-based RepoGate deployment in a container.

set -o errexit

if [ $# -ne 8 ] ; then
    echo "usage: $0 <frg> <secrets-dir> <cont-name> <https-port> <gitd-ip> <gitd-port> <wall-ip> <wall-port>" >&2
    exit 1
fi

frg="$1"
secrets_dir="$2"
cont_name="$3"
https_port="$4"
gitd_ip="$5"
gitd_port="$6"
wall_ip="$7"
wall_port="$8"

if [ ! -e "$secrets_dir" ] ; then
    mkdir "$secrets_dir"

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
fi

dir=$(mktemp --directory)
rmdir "$dir"
cp -r . "$dir"
(
    cd "$dir"
    cp "$frg" frg

    img_name=repogate/allinone

    bash scripts/docker_rbuild.sh \
        "$img_name" \
        latest \
        --file=docker/allinone/Dockerfile \
        .

    echo -n "Please enter a master password: "
    master_pass="$(python scripts/get_pass.py)"

    docker \
        create \
        --interactive \
        --name="$cont_name" \
        --publish=$https_port:8080 \
        --publish=$wall_ip:$wall_port:9000 \
        --publish=$gitd_ip:$gitd_port:9418 \
        --tty \
        --volume="$secrets_dir":'/secrets' \
        "$img_name" \
        bash \
        -c \
        "
            set -o errexit

            sess_id=$(date '+%Y%m%d_%H%M%S')

            MASTER_PASSWORD='$master_pass' bash \
                scripts/start.sh \
                \"\$PWD/frg\" \
                \"\$sess_id\"

            ln \
                -s \
                /secrets/cert.pem \
                /secrets/privkey.pem \
                /home/repogate/deploy_rg/secrets

            var_dir=\"/var/tmp/node/\$sess_id\"
            mkdir \
                --parents \
                /var/tmp/repo_update \
                \"\$var_dir\"
            MASTER_PASSWORD='$master_pass' node \
                index.js \
                2>&1 \
                | tee \"\$var_dir/log\"
        "

    echo "Starting container..."
    docker start "$cont_name"
#     python -c "
# import getpass
# import pexpect
# 
# child = pexpect.spawn('docker start -ai \"$cont_name\"')
# child.expect('Please enter a master password: ')
# child.sendline(getpass.getpass('Please enter a master password: '))
# child.wait()
# " &
# 
#     sleep 5

    echo "Waiting for port $https_port to handle requests..."
    echo "https://127.0.0.1:$https_port"
    for i in `seq 0 3` ; do
        if curl -ksf "https://127.0.0.1:$https_port/" >/dev/null ; then
            break
        elif [ $i -eq 3 ] ; then
            echo "Couldn't connect to container"
            echo "Stopping container..."
            echo "Stopped container $(docker stop $cont_name)"
            docker logs "$cont_name" | sed "s/^/[logs] /"
            echo "Removing container..."
            echo "Removed container $(docker rm $cont_name)"
            exit 1
        fi
        sleep 1
    done

    echo "Ready."
)
