#!/usr/bin/env sh

# This is actually a wrapper script that takes care of file permission
# issue when running in guix under docker

mkdir -p /working/out
cp -r /working/actual_ckb /working/ckb
chown -R -f `id -u`:`id -g` /working/ckb

"$@"
EXEC_RESULT=$?

cp -f /working/out/* /working/actual_out/
rm -rf /working/out /working/ckb

exit $EXEC_RESULT
