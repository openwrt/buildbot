#!/usr/bin/env bash

git_author="Release Management"
git_email="lede-dev@lists.infradead.org"

base_url="http://downloads.lede-project.org/releases"

[ -f "./feeds.conf.default" ] || {
	echo "Please execute as ./${0##*/}" >&2
	exit 1
}

usage() {
	{
		echo ""
		echo "Usage: $0 [-i] [-a <Git author>] [-e <Git email>] \\"
		echo "          [-u <Download base url>] -n <codename> -v <version>"
		echo ""
		echo "-i"
		echo "Exit successfully if branch already exists"
		echo ""
		echo "-a Git author [$git_author]"
		echo "Override the author name used for automated Git commits"
		echo ""
		echo "-e Git email [$git_email]"
		echo "Override the email used for automated Git commits"
		echo ""
		echo "-u Download base url [$base_url]"
		echo "Use the given URL as base for download repositories"
		echo ""
		exit 1
	} >&2
}

while getopts "a:e:iu:n:v:" opt; do
	case "$opt" in
		a) git_author="$OPTARG" ;;
		e) git_email="$OPTARG" ;;
		i) ignore_existing=1 ;;
		u) base_url="${OPTARG%/}" ;;
		n) codename="$OPTARG" ;;
		v)
			case "$OPTARG" in
				[0-9]*.[0-9]*)
					version="$(echo "$OPTARG" | cut -d. -f1-2)"
				;;
				*)
					echo "Unexpected version format: $OPTARG" >&2
					exit 1
				;;
			esac
		;;
		\?)
			echo "Unexpected option: -$OPTARG" >&2
			usage
		;;
		:)
			echo "Missing argument for option: -$OPTARG" >&2
			usage
		;;
	esac
done

[ -n "$codename" -a -n "$version" ] || usage

if git rev-parse "lede-${version}^{tree}" >/dev/null 2>/dev/null; then
	if [ -z "$ignore_existing" ]; then
		echo "Branch lede-${version} already exists!" >&2
		exit 1
	fi

	exit 0
fi

revnum="$(./scripts/getver.sh)"
githash="$(git log --format=%h -1)"

prev_branch="$(git symbolic-ref -q HEAD)"

if [ "$prev_branch" != "refs/heads/main" ]; then
	echo "Expecting current branch name to be \"main\"," \
	     "but it is \"${prev_branch#refs/heads/}\" - aborting."

	exit 1
fi

export GIT_AUTHOR_NAME="$git_author"
export GIT_AUTHOR_EMAIL="$git_email"
export GIT_COMMITTER_NAME="$git_author"
export GIT_COMMITTER_EMAIL="$git_email"

git checkout -b "lede-$version"

while read type name url; do
	case "$type" in
		src-git)
			case "$url" in
				*^*|*\;*) : ;;
				*)
					ref="$(git ls-remote "$url" "lede-$version")"

					if [ -z "$ref" ]; then
						echo "WARNING: Feed \"$name\" provides no" \
						     "\"lede-$version\" branch - using main!" >&2
					else
						url="$url;lede-$version"
					fi
				;;
			esac
			echo "$type $name $url"
		;;
		src-*)
			echo "$type $name $url"
		;;
	esac
done < feeds.conf.default > feeds.conf.branch && \
	mv feeds.conf.branch feeds.conf.default

sed -e 's!^RELEASE:=.*!RELEASE:='"$codename"'!g' \
    -e 's!\(VERSION_NUMBER:=\$(if .*\),[^,]*)!\1,'"$version-SNAPSHOT"')!g' \
    -e 's!\(VERSION_REPO:=\$(if .*\),[^,]*)!\1,'"$base_url/$version-SNAPSHOT"')!g' \
	include/version.mk > include/version.branch && \
		mv include/version.branch include/version.mk

sed -e 's!http://downloads.lede-project.org/[^"]*!'"$base_url/$version-SNAPSHOT"'!g' \
	package/base-files/image-config.in > package/base-files/image-config.branch && \
		mv package/base-files/image-config.branch package/base-files/image-config.in

git commit -sm "LEDE v$version: set branch defaults" \
	feeds.conf.default \
	include/version.mk \
	package/base-files/image-config.in

git --no-pager log -p -1
git push origin "refs/heads/lede-$version:refs/heads/lede-$version"
git checkout "${prev_branch#refs/heads/}"
