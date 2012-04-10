#!/usr/bin/env bash

##
# @author Jay Taylor [@jtaylor]
#
# @date 2012-04-09
#
# @description Initializes openssl encryption filter into the .git/config file
# of a cloned git repository.
#


localGitConfigFile='.git/config'


################################################################################

# Ensure that we are running in the root of a git repository.
if ! [ -r "$localGitConfigFile" ]; then
    echo 'fatal: this script can only be run in the root of a git repository' 1>&2
    echo 'check your current directory (by running `pwd`), correct any issues you find, and then try again' 1>&2
    exit 1
fi


# Define filter scripts and other static executable/reference file contents.
# NB: The semi-colons at the end of each line for the first 3 entries here are
# due to the use of `eval` below.
clean_filter_openssl='#!/usr/bin/env bash;
;
SALT_FIXED={{SALT}};
#A1F1F8129C4FEBAB3513C174 # 24 or less hex characters;
PASS_FIXED={{PASSWORD}};
;
openssl enc -base64 -aes-256-ecb -S $SALT_FIXED -k $PASS_FIXED'

smudge_filter_openssl='#!/usr/bin/env bash;
;
# No salt is needed for decryption.;
PASS_FIXED={{PASSWORD}};
;
# If decryption fails, use `cat` instead.;
# Error messages are redirected to /dev/null.;
openssl enc -d -base64 -aes-256-ecb -k $PASS_FIXED 2> /dev/null || cat'

diff_filter_openssl='#!/usr/bin/env bash;
;
# No salt is needed for decryption.;
PASS_FIXED={{PASSWORD}};
;
# Error messages are redirected to /dev/null.;
openssl enc -d -base64 -aes-256-ecb -k $PASS_FIXED -in "$1" 2> /dev/null || cat "$1"'

gitattributes='*.md filter=openssl diff=openssl
sensitive.txt filter=openssl diff=openssl
[merge]
	renormalize = true'

gitconfig='[filter "openssl"]
    smudge = ~/.gitencrypt/smudge_filter_openssl
    clean = ~/.gitencrypt/clean_filter_openssl
[diff "openssl"]
    textconv = ~/.gitencrypt/diff_filter_openssl'


# Initialize .gitencrypt directory in the users $HOME if not already there.

if ! [ -d "$HOME/.gitencrypt" ]; then
    echo 'info: initializing ~/.gitencrypt'

    # Prompt user for salt and password.
    while [ -z "$salt" ]; do
        echo 'Enter the salt phrase (16 hexadecimal characters):'
        read salt
    done

    while [ -z "$password" ]; do
        echo 'Enter the encryption pass-phrase:'
        read password
    done

    mkdir "$HOME/.gitencrypt"

    for filter in clean_filter_openssl smudge_filter_openssl diff_filter_openssl; do
        echo "info: generating filter script '$filter'"
        filterScriptPath="$HOME/.gitencrypt/$filter"

        # This ugliness is due to `eval` not handling newlines very nicely.
        # @see http://stackoverflow.com/a/3524860/293064 for more eval details.
        echo -e $(eval "echo \$$filter") | tr ';' '\n' | sed "s/{{SALT}}/$salt/g
            s/{{PASSWORD}}/$password/g
            s/^ *\(.*\) *$/\1/g" > "$filterScriptPath"

        chmod a+x "$filterScriptPath"
    done
fi


# Initialize .gitattributes file if it doesn't exist.

if ! [ -e '.gitattributes' ]; then
    echo "info: initializing file '.gitattributes'"
    echo -n $gitattributes > .gitattributes
fi


# Initialize the .git/conf file for this repository clone if not already.

checkForPreExistingConf=$(grep '^\[\(filter\|diff\) "openssl"]$' "$localGitConfigFile")

if [ -n "$checkForPreExistingConf" ]; then
    echo 'info: openssl filter/diff already configured for this clone'
else
    cat <<EOF >> "$localGitConfigFile"
$gitconfig
EOF
    echo 'info: openssl filter/diff successfuly applied to this clone'
fi


# Reset the HEAD to re-check out all of the files [with the encryption filters.]

echo 'info: re-checking out all of the files to ensure that the encryption filters are applied'
git reset --hard HEAD

