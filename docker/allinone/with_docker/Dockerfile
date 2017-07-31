#!/bin/sh

# Copyright 2017 Sean Kelleher. All rights reserved.

# This Dockerfile is for an "all-in-one" docker-based RepoGate deployment image
# that includes the Docker Engine. Ideally this image would be created `FROM`
# the core "all-in-one" image to minimise duplication of the instructions, but
# this approach is taken so that updating the `frg` binary will not require
# re-installing the Docker Engine.

FROM node:8.1.2

RUN \
    apt-get update \
    && apt-get install --quiet --assume-yes \
        git \
        python

RUN \
    apt-get update \
    && apt-get install --quiet --assume-yes \
        apt-transport-https \
        ca-certificates \
        gnupg2 \
        software-properties-common \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
        | apt-key add - \
    && apt-key fingerprint 0EBFCD88 \
        | grep '9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88' \
        || { echo "couldn't validate fingerprint" ; exit 1 ; } \
    && add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install --quiet --assume-yes \
        docker-ce

RUN \
    useradd --password '' --create-home repogate \
    && usermod --append --groups docker repogate

RUN mkdir --parents /home/repogate/deploy_rg/repos

RUN \
    install --owner=repogate --group=repogate --mode=0700 --directory /secrets \
    && mkdir /home/repogate/deploy_rg/secrets

COPY . /home/repogate/deploy_rg

COPY frg /home/repogate/deploy_rg/frg

RUN chown -R repogate:repogate /home/repogate

USER repogate

WORKDIR /home/repogate/deploy_rg

CMD [ "bash", "/home/repogate/deploy_rg/docker/allinone/cmd.sh" ]

EXPOSE 8080
EXPOSE 9418
EXPOSE 9000
