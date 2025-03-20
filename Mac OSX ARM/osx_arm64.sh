#!/bin/sh

set -o errexit
set -o nounset

report_crash () {
    curl --location --request POST 'https://o1224273.ingest.sentry.io/api/4504100877828096/store/?sentry_key=0b9fcaeae27d4918b933ed747b1a1047' \
      --header 'Content-Type: application/json' \
      --data-raw "{
          \"level\": \"error\",
          \"transaction\": \"postman-cli-install\",
          \"tags\": {
              \"os\": \"mac_arm\"
          },
          \"exception\": {
              \"values\": [
                  {
                      \"type\": \"InstallationError\",
                      \"value\": \"$1\"
                  }
              ]
          }
      }" > /dev/null 2>&1

    SYSTEM_ERROR="true"
    echo "The Postman CLI couldn't be installed. $1" 1>&2
    exit 1
}

trap 'report_crash USER_ABORT' SIGINT SIGTERM

PREFIX='/usr/local'
URL='https://dl-cli.pstmn.io/download/latest/osx_arm64'
SYSTEM_ERROR=''

# We should always make use a temporary directory
# to not risk leaving a trail of files behind in the user's system
TMP="$(mktemp -d)"
clean() { rm -rf "$TMP"; }
trap clean EXIT

# replace curl from script to use local zip instead
# curl --location --retry 10 --output "$TMP/postman-cli.zip" "$URL" || report_crash "Failed to download Postman CLI"
mv postman-cli-1.13.1-macos-arm64.zip "$TMP/postman-cli.zip"
ditto -x -k "$TMP/postman-cli.zip" "$TMP" || report_crash "Failed to unzip Postman CLI"

# Don't use sudo(8) if we don't seem to need it
RUN='sudo'
if test -d "$PREFIX/bin" && test -w "$PREFIX/bin"
then
  RUN='eval'
elif test -d "$PREFIX" && test -w "$PREFIX"
then
  RUN='eval'
fi

# Use install(1) rather than mkdir/cp
"$RUN" install -d "$PREFIX/bin" || report_crash "Failed to create $PREFIX/bin"
"$RUN" install -m 0755 "$TMP/postman-cli" "$PREFIX/bin/postman" || report_crash "Failed to install Postman CLI"

if [[ -z $SYSTEM_ERROR ]]; then
    echo "The Postman CLI has been installed" 1>&2
fi
