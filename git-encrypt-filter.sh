#!/usr/bin/env bash

IFS="
"

FILES=`git ls-tree --name-only --full-tree -r $GIT_COMMIT` || exit 1

for x in $FILES; do
	cat "$x" | $@ > "$x.tmp" || exit 1 
	cat "$x.tmp" > "$x" || exit 1
	rm "$x.tmp"
done
