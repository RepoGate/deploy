#!/bin/sh

# Copyright 2017 Sean Kelleher. All rights reserved.

# `$0 <git-host> <user> <project> <master-pass-env-var> <log> <pass-file>` bare
# clones the `<user>/<project>` repository from `<git-host>` using the
# `username:password` pair found in the `<pass-file>` encrypted with the
# environment variable named `<master-pass-env-var>`.
#
# The environment variable named `<master-pass-env-var>` is used to push updates
# back to the remote repository whenever updates are pushed to the cloned
# repository. Errors encountered when pushing updates to the remote repository
# are appended to `<log>`.

set -o errexit
set -o pipefail

if [ $# -ne 6 ] ; then
    echo "usage: $0 <git-host> <user> <project> <master-pass-env-var> <log> <pass-file>" >&2
    exit 1
fi

git_host=$1
user=$2
project=$3
master_pass_env_var=$4
log=$5
pass_file=$6

if [ -z "\$$master_pass_env_var" ] ; then
    echo "\`\$$master_pass_env_var\` is empty"
    exit 1
fi

user_pass=$(
    bash \
        "$(dirname $0)/secrets/get.sh" \
        ${!master_pass_env_var} \
        "$pass_file" \
        "$project" \
        2>/dev/null
)

if [ -z "$user_pass" ] ; then
    echo "couldn't read 'username:pass':"
    bash \
        "$(dirname $0)/secrets/get.sh" \
        ${!master_pass_env_var} \
        "$pass_file" \
        "$project" \
        2>&1 \
        1>/dev/null
    exit 1
fi

url="$git_host/$user/$project.git"

git \
    clone \
    -v \
    --bare \
    "https://$user_pass@$url" \
    "$project" \
    2>&1 \
    | sed "s/$user_pass/___:___/" \
    > "$log"

cat <<-EOF > "$project/hooks/post-update" || ( cat "$log" ; exit 1 )
#!/bin/sh

set -o errexit

if [ -z "\$$master_pass_env_var" ] ; then
echo b >> '$log'
    echo '\`\$$master_pass_env_var\` is empty' >> '$log'
    exit 1
fi

user_pass=\$(
    bash \\
        "$(dirname $0)/secrets/get.sh" \\
        \$$master_pass_env_var \\
        "$pass_file" \\
        "$project"
)

if [ -z "\$user_pass" ] ; then
    echo "couldn't read 'username:password':" >> "$log"
    bash \\
        "$(dirname $0)/secrets/get.sh" \\
        \$$master_pass_env_var \\
        "$pass_file" \\
        "$project" \\
        2>> "$log" \\
        1>/dev/null
    exit 1
fi

git \\
    push \\
    "https://\$user_pass@$url" \\
    master \\
    2>&1 \\
    | sed "s/\$user_pass/___:___/g" \\
    >> '$log'
EOF

chmod +x $project/hooks/post-update
