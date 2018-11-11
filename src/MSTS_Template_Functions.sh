#!/bin/bash

N=$'\n'
T=$'\t'

HR='|:| -+- - - - - - - - - - - - - - - - - - -+- |:|'
LHR="$HR$N"'|:- = - = - = - = - = - = - = - = - = - = - = -:|'"$N$HR"

CURRENT_TEMPLATE_RUN=""
CURRENT_JSON_TO_BASH_ARRAY=()
CURRENT_JSON_TO_BASH_VAR=""

MSTS_VARS=""
MSTS_OUTPUT=""

runTemplate() {
	local completeFlag=""
	for i in ${!TEMPLATE_NAMES[@]}; do
		if [ "${TEMPLATE_NAMES[$i]}" = "$1" ]; then
			completeFlag="true"
			eval "${TEMPLATE_FUNCTIONS[$i]}"
			CURRENT_TEMPLATE_RUN="$(msts)"
			CURRENT_TEMPLATE_RUN+="$N"
		fi
	done
	if [ -z "$completeFlag" ]; then
		echo "--MSTS ERROR : Unable to locate template '$1'"
	fi
}

getJSONToBashArray() {
	# in the format 'arrayName' or 'objectWithArray.array'
	local targetJSONArray=$1
	local output=()
	local index=0
	while [ "$( jq -n --argjson data "$MSTS_VARS" '$data.'"$targetJSONArray"'['"$index"']''')" != 'null' ]; do
		output=("${output[@]}" "$( jq -n --argjson data "$MSTS_VARS" '$data.'"$targetJSONArray"'['"$index"']''')")
		((++index))
	done
	CURRENT_JSON_TO_BASH_ARRAY=("${output[@]}")
}

getJSONToBashVar() {
	# in the format 'varName' or 'objectWithVar.varName'
	local targetJSONVar=$1
	if [ "$( jq -n --argjson data "$MSTS_VARS" '$data.'"$targetJSONVar"'')" != 'null' ]; then
		output=("${output[@]}" "$( jq -n --argjson data "$MSTS_VARS" '$data.'"$targetJSONArray"'['"$index"']''')")
	fi
	CURRENT_JSON_TO_BASH_VAR=("$output")
}
