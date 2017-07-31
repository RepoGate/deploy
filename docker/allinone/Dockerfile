#!/bin/sh

# Copyright 2017 Sean Kelleher. All rights reserved.

# This Dockerfile is for an "all-in-one" docker-based RepoGate deployment image.

FROM node:8.1.2

RUN \
    apt-get update \
    && apt-get install --quiet --assume-yes \
        git \
        python

RUN useradd --password '' --create-home repogate

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
