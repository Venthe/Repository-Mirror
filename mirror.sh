#!/usr/bin/env bash

set -o pipefail
set -o errexit
# set -o xtrace

PARSE_FILE=${1:-repositories}

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

#dos2unix repositories.txt
mkdir -p repositories
CURRENT_DIRECTORY=`pwd`

function indent() {
  sed "s/^/  $1/"
}

function in_brackets() {
    local BRACKET_COLOR="${Yellow}"
    local NAME_COLOR="${Green}"
    echo -e "${BRACKET_COLOR}[${Color_Off}${NAME_COLOR}${1}${Color_Off}:${2}${BRACKET_COLOR}]${Color_Off}"
}
function mirror_github() {
    local SPLIT=(${1//\// })
    local OWNER="${SPLIT[0]}"
    local REPOSITORY_NAME="${SPLIT[1]}"
    local TARGET_DIRECTORY="${OWNER}/${REPOSITORY_NAME}.git"
    local TIMESTAMP_FILE="${OWNER}/${REPOSITORY_NAME}.timestamp"
    1>&2 echo -e "🪟 $(in_brackets o ${OWNER})$(in_brackets r ${REPOSITORY_NAME})"
    mkdir -p "${TARGET_DIRECTORY}"

    local TIMESTAMP=$(head -n 1 ${TIMESTAMP_FILE} 2>/dev/null || printf "0")
    local CURRENT_TIME=$(date +%s%3N)
    local DIFF=$((CURRENT_TIME-TIMESTAMP))
    if [[ DIFF -gt $((1*24*60*60*1000))  ]]; then
        start=`date +%s%3N`
        git clone git@github.com:${OWNER}/${REPOSITORY_NAME}.git --mirror "${TARGET_DIRECTORY}" 2>&1 | indent 1>&2 \
            || bash -c "cd ${TARGET_DIRECTORY} && git remote update" | indent 1>&2
        echo "$(date +%s%3N)" > "${TIMESTAMP_FILE}"
        end=`date +%s%3N`
        echo -e "Execution time: $((end-start))ms" | indent 1>&2
    #else
    #    echo "Status: OK (Mirror not stale)" | indent 1>&2
    fi
}

while read line; do
    SPLIT_BY_DELIMETER=(${line// / })
    TYPE=${SPLIT_BY_DELIMETER[0]}

    if [[ ${TYPE:0:1} == "#" ]]; then
      continue
    fi

    cd "${PARSE_FILE}"

    if [[ $TYPE == "GITHUB" ]]; then
        mirror_github "${SPLIT_BY_DELIMETER[@]:1}"
    fi
    cd "${CURRENT_DIRECTORY}"
done < "${PARSE_FILE}.txt"
