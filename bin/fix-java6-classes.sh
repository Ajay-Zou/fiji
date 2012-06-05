#!/bin/sh

FIJIROOT="$(dirname "$0")/.."
FIJI="$FIJIROOT"/ImageJ
RETRO="$FIJIROOT"/retro/retrotranslator-transformer-1.2.9.jar
TARGETVERSION=$TARGETVERSION${TARGETVERSION:-1.3}

die () {
	echo "$*" >&2
	exit 1
}

case $# in
0)
	OFFENDERS=$(cd "$FIJIROOT" && ./ImageJ tests/class_versions.py |
		sed -n -e 's/(.*//' -e 's/^\t//p' |
		uniq)
	;;
*)
	OFFENDERS="$*"
	;;
esac

TMPDIR="$(mktemp -d fixXXXXXX 2> /dev/null)" || {
	TMPDIR=.tmp.dir.$$
	mkdir -p $TMPDIR
}

for f in $OFFENDERS
do
	echo "Fixing $f..."
	case "$f" in
	*.jar)
		"$FIJI" --jar "$RETRO" \
			-srcjar "$f" -destjar "$f".new -target $TARGETVERSION &&
		mv -f "$f".new "$f"
		;;
	*.class)
		mv "$f" "$TMPDIR" &&
		"$FIJI" --jar "$RETRO" \
			-srcdir "$TMPDIR" -destdir $(dirname "$f") -target $TARGETVERSION
		;;
	*)
		die "Unknown type: $f"
		;;
	esac ||
	die "Could not transform $f"
done
rm -rf "$TMPDIR"
