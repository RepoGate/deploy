README
======

About
-----

This repository contains scripts for a RepoGate deployment.

Deployments
-----------

This project supplies two types of deployments, a docker-based one and a local
one. The docker-based deployment is recommended because it is easier to set up
and use.

### Prerequisites

Both deployments require Git to be installed, and require a local `frg`
executable.

### Tests

The deployment tests require a hosted repository with a specific structure on a
service like GitHub or Bitbucket. Use `bash create_test_repo.sh` with a new
hosted repository URI to upload a project with the required structure to that
location. For instance:

    bash create_test_repo.sh https://github.com/username/repository.git

Docker-based Deployment
-----------------------

### Setup

`bash docker/allinone/start.sh` is used to start an "all-in-one" RepoGate
deployment in a docker container:

    bash docker/allinone/start.sh \
        <frg> \
        <secrets-dir> \
        <cont-name> \
        <https-port> \
        <gitd-ip> \
        <gitd-port> \
        <wall-port>

Details on the arguments:

* `<frg>` is a path to a `frg` executable.
* `<secrets-dir>` is a path to a directory that will contain a private key and a
  certificate for the HTTPS interface to the deployment. If a directory exists
  at this path then it must contain `privkey.pem` and `cert.pem`. If nothing
  exists at this location then a secrets directory will be generated with a
  self-signed certificate and corresponding private key.
* `<cont-name>` is the name that the container will be given.
* `<https-port>`, `<gitd-port>` and `<wall-port>` are the local ports that the
  HTTPS port, Git daemon port, and RepoGate wall port will be forwarded to.
* `<gitd-ip>` is the IP for the Git daemon to listen on. It is suggested to use
  `127.0.0.1` for this because repositories aren't currently protected. This can
  be set to `0.0.0.0` to make the daemon public.

### Usage

The docker-based deployment is primarily used through the HTTPS interface. It
can be accessed via `https://127.0.0.1:https-port/`, where `https-port` is the
port number passed to `docker_start.sh`.

There are three main steps in the current docker-based deployment workflow:

1. Add a project using the form at `/projects/add`. Once it has been added then
   it can be cloned from the container using `git clone
   git://127.0.0.1:${gitd-port}/${proj-name}`, where `gitd-port` is the port
   number passed to `docker_start.sh` and `proj-name` is the name of the project
   that was added (the names of projects currently in the container are listed
   on the `/projects` page).
2. Run `scripts/rg_init.sh` in the root of the repository if it hasn't already
   been initialised as a RepoGate repository, and commit the newly added files.
3. Once changes have been committed to the cloned repository then they can be
   tested and pushed back to the hosted repository by executing a `frg push`
   (assuming `frg` is on your path, `proj_name` is the name of the project that
   was added, and `wall_port` is the port number that was passed to
   `docker_start.sh`):

        frg push --proj=${proj_name} --wall=127.0.0.1:${wall_port}

Local Deployment
----------------

### Start and Test

A local deployment requires creating a `repogate` user with a home directory at
`/home/repogate` and then running the script to install the deployment, start
the services, and run a test:

    useradd --create-home repogate
    sudo bash scripts/install,start,test.sh \
        <frg> \
        $(date "+%Y%m%d_%H%M%S") \
        <test-proj-host-user> \
        <test-proj-host> \
        <test-proj-user> \
        <test-proj-name>

This installs the deployment under `/home/repogate/deploy_rg/`.

Details on the arguments (see the section "Tests" in "Deployments" for details
on creating the test repository):

* `<frg>` is a path to a `frg` executable,
* `<test-proj-host-user>` is a user with read/write permissions to the test
  repository on `<test-proj-host>`,
* `<test-proj-host>` is the repository host (e.g. github.com or bitbucket.org),
* `<test-proj-user>` is the user `test-proj-name` is stored under, and
* `<test-proj-name>` is the name of the test repository.

The script will ask for a "master" password that will be used for securely
handling username:password pairs for hosted repositories.

When the test is completed the deployment structure will be in place to use
RepoGate.

### Usage

Once the test has been run successfully then the deployment is ready for use.
There are currently three steps in the current workflow for using RepoGate with
a hosted repository.

1. Clone a hosted repository, which consists of two steps.

    1. Add the username:password pair (that is, the username and password,
       separated by a colon) for the hosted repository, to the password database
       at `/home/repogate/repos_pass.aes`, using the following:

            bash /home/repogate/deploy_rg/scripts/secrets/add.sh \
                <master> \
                /home/repogate/repos_pass.aes \
                <project> \
                <username:password>

       Here, `<master>` is the password that was set above and `<project>` is
       the project name used in the next step. Note that neither the username or
       the password should contain `:`.
    2. Clone the hosted repository into `/home/repogate/deploy_rg/repos` by
       changing to this directory and running the following:

            bash /home/repogate/scripts/clone.sh \
                <git-host> \
                <user> \
                <project> \
                MASTER_PASSWORD \
                <log> \
               /home/repogate/deploy_rg/repos_pass.aes

       Here, `<git-host>`, `<user>` and `<project>` specify a hosted repository;
       in the case of this project the values would be `github.org`, `repogate`
       and `deploy`, respectively. `<log>` simply specifies a log file to be
       written to. `clone.sh` sets the up the clone as a "mirror" repository
       that forwards updates to the hosted repository when it receives them.

2. Make a "working" copy of the mirror by cloning the repository from
   `git://<host>/<project>`, where `<host>` is the local host and `<project>` is
   the project name specified in the previous step. Note that changes cannot be
   pushed back to this location with `git push`.
2. Run `/home/repogate/deploy_rg/scripts/rg_init.sh` in the root of the
   repository if it hasn't already been initialised as a RepoGate repository,
   and commit the newly added files.
3. Once changes have been committed to the cloned repository then they can be
   tested and pushed back to the hosted repository by executing a `frg push`
   (assuming `frg` is on your path, and `9000` is the port number that was
   passed to `docker_start.sh`):

        frg push --proj=${project} --wall=127.0.0.1:9000

    Here, `${project}` is the project name specified above.

### Admin

A `scripts` directory is installed in `/home/repogate` by
`install,start,test.sh`. Amongst other files, this directory contains the
following scripts:

* `start_frg.sh` starts the RepoGate services.
* `start_ro_gitd.sh` starts a "read-only" Git daemon (see "High-level
  Operational Overview" for details).
* `monit.sh` tracks and outputs the output of services for a particular session.
  Use `bash scripts/monit.sh $(cat cur_sess.txt)` to track such output for the
  current session (assuming `cur_sess.txt` is kept updated with the current
  session ID).

Notes
-----

There are "test" scripts and "check" scripts in this project. Test scrips are
those that start a deployment instance and tear it down at the end of the test,
whereas scripts that check usually start a deployment instance and run checks to
confirm that it is running as expected, and leave the instance running when the
check finishes.
