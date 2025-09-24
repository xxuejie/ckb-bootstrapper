# This is a utility script that builds a reproducible tarball given
# a directory

DIR=$(realpath $1)
REPO_DIR=$(realpath $2)

TARBALL=$(basename -- "$DIR")

# The following workflow is adapted from:
# https://www.gnu.org/software//tar/manual/html_section/Reproducibility.html

function get_commit_time() {
  TZ=UTC0 git log -1 \
    --format=tformat:%cd \
    --date=format:%Y-%m-%dT%H:%M:%SZ \
    "$@"
}

cd $REPO_DIR
SOURCE_EPOCH=$(get_commit_time)
cd $DIR

if [ -d .git ]; then
  # Set each source file timestamp to that of its latest commit.
  git ls-files | while read -r file; do
    commit_time=$(get_commit_time "$file") &&
    touch -md $commit_time "$file"
  done
else
  # In the absense of a .git directory, set each file to the timestamp
  # of the latest source repo
  find -type f | while read -r file; do
    touch -md $SOURCE_EPOCH "$file"
  done
fi
# Set timestamp of each directory under $FILES
# to the latest timestamp of any descendant.
find . -depth -type d -exec sh -c \
  'touch -r "$0/$(ls -At "$0" | head -n 1)" "$0"' \
  {} ';'

cd ..
# Create $ARCHIVE.tgz from $FILES, pretending that
# the modification time for each newer file
# is that of the most recent commit of any source file.
TARFLAGS="
  --sort=name --format=posix
  --pax-option=exthdr.name=%d/PaxHeaders/%f
  --pax-option=delete=atime,delete=ctime
  --clamp-mtime --mtime=$SOURCE_EPOCH
  --numeric-owner --owner=0 --group=0
  --mode=go+u,go-w
"
GZIPFLAGS="--no-name --best"
LC_ALL=C tar $TARFLAGS -cf - $TARBALL |
  gzip $GZIPFLAGS > $TARBALL.tar.gz
rm -rf $TARBALL
