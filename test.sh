#!/bin/bash

if [ -z "$POSTGRES_SEARCH_PATH" ]; then
	POSTGRES_SEARCH_PATH="public"
fi

for sql in $(find ./tests -name test.*.sql); do
	rm -rf /tmp/semver.out
	expected=${sql/%.sql/.expected}
	echo -n $sql "..."
	psql "options=--search_path=${POSTGRES_SEARCH_PATH}" -q -A -t -f "$sql"	> /tmp/semver.out
	diffs=$(diff /tmp/semver.out "$expected")
	if [ -z "$diffs" ]; then
		echo "OK"
	else
		echo $diffs
	fi
done

rm -rf /tmp/semver.out
