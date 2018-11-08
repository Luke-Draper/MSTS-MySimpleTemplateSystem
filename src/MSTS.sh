#!/bin/bash

SOURCE_JSON_FILE=$1

SOURCE_JSON="$(cat ${SOURCE_JSON_FILE} | sed 's/\r$//')"

TEMPLATE_DIRECTORY="$( jq -n --argjson data "$SOURCE_JSON" '$data.templateDirectory')"
TEMPLATE_DIRECTORY="${TEMPLATE_DIRECTORY%\"}"
TEMPLATE_DIRECTORY="${TEMPLATE_DIRECTORY#\"}"

TEMPLATE_FUNCTIONS=()
TEMPLATE_NAMES=()
TEMPLATE_PATHS=()

MSTS_VARS=()

for filepath in ~/${TEMPLATE_DIRECTORY}/*.msts.sh; do
	TEMPLATE_PATHS+=("${filepath}")
	TEMPLATE_FUNCTIONS+=("")
	TEMPLATE_NAMES+=("")
done


function setupTemplate() {
	filename="$(basename ${TEMPLATE_PATHS[$i]} .msts.sh)"
	TEMPLATE_NAMES[$i]=$filename
	source ${TEMPLATE_PATHS[$i]}
	TEMPLATE_FUNCTIONS[$i]=$(declare -f $1)
	echo "Template Loaded : $filename"
}

for i in ${!TEMPLATE_PATHS[@]}; do
	setupTemplate
done

runTemplate() {
	for i in ${!TEMPLATE_NAMES[@]}; do
		if [ "${TEMPLATE_NAMES[$i]}" = "$1" ]; then
			eval "${TEMPLATE_FUNCTIONS[$i]}"
			msts
		fi
	done
}

runTemplate test

