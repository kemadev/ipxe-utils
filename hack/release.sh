#!/usr/bin/env bash

set -euo pipefail

declare BUMP_TYPE
declare CURRENT_VERSION
declare NEXT_VERSION

function usage() {
	echo "Usage: $0 --bump <major|minor|patch>"
	echo "Bumps the version of the project and creates a release."
	echo
	echo "Arguments:"
	echo "  --bump <major|minor|patch>  Specify the type of version bump."
	exit 1
}

function parse_args() {
	if [[ $# -eq 0 ]]; then
		usage
	fi
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--bump)
			if [[ -z "${2:-}" || ! "$2" =~ ^(major|minor|patch)$ ]]; then
				echo "Error: Invalid bump type. Use 'major', 'minor', or 'patch'."
				usage
			fi
			BUMP_TYPE="${2}"
			echo "Bump type set to ${BUMP_TYPE}"
			shift 2
			;;
		*)
			echo "Error: Unknown argument '${1}'."
			usage
			;;
		esac
	done
	if [[ -z "${BUMP_TYPE:-}" ]]; then
		echo "Error: Bump type is required."
		usage
	fi
}

function cd_to_repo_root() {
	local TMP_CD_DIR
	TMP_CD_DIR="$(git rev-parse --show-toplevel)"
	if [ -n "${TMP_CD_DIR}" ]; then
		cd "${TMP_CD_DIR}"
	else
		echo "Failed to determine the repository root directory."
		exit 1
	fi
}

function get_latest_version() {
	CURRENT_VERSION="$(git describe --tags --always)"
	if [[ -z "${CURRENT_VERSION}" ]]; then
		echo "No tags found in the repository. Please create a tag first."
		exit 1
	fi
	if [[ ! "${CURRENT_VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		CURRENT_VERSION="0.0.0"
	fi
	echo "Current version: ${CURRENT_VERSION}"
}

function bump_version() {
	major=0
	minor=0
	patch=0
	IFS='.' read -r major minor patch <<<"${CURRENT_VERSION}"

	case "${BUMP_TYPE}" in
	major)
		((major+=1))
		minor=0
		patch=0
		;;
	minor)
		((minor+=1))
		patch=0
		;;
	patch)
		((patch+=1))
		;;
	*)
		echo "Error: Invalid bump type '${BUMP_TYPE}'."
		exit 1
		;;
	esac

	NEXT_VERSION="${major}.${minor}.${patch}"
	echo "Next version: ${NEXT_VERSION}"
}

function build_version() {
	docker build --tag="ipxe:${NEXT_VERSION}" --file=./build/Dockerfile --target=local-artifact . --output ./dist
	echo "Build completed for version ${NEXT_VERSION}"
}

function tag_version() {
	git tag -a "${NEXT_VERSION}" -m "Release ${NEXT_VERSION}"
	git push origin "${NEXT_VERSION}"
	echo "Tagged version: ${NEXT_VERSION}"
}

function release_version() {
	if ! command -v gh &>/dev/null; then
		echo "GitHub CLI (gh) is not installed. Please install it to create a release."
		exit 1
	fi

	gh release create "${NEXT_VERSION}" \
		--title "Release ${NEXT_VERSION}" \
		--notes "New version!" \
		./dist/ipxe.efi
}

function main() {
	parse_args "${@}"
	cd_to_repo_root
	get_latest_version
	bump_version "${@}"
	build_version
	tag_version
	release_version
}

main "${@}"
