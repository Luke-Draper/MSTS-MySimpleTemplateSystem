#!/bin/bash

N=$'\n'
T=$'\t'

HR='|:| -+- - - - - - - - - - - - - - - -+- |:|'

echo ' _________________________________________ '
echo '|:- = - = - = - = - = = - = - = - = - = -:|'
echo '|:| -+- - - - - - - - - - - - - - - -+- |:|'
echo '|:| |:-  My Simple Template System  -:| |:|'
echo '|:| |:-    Made By : Luke Draper    -:| |:|'
echo '|:| -+- - - - - - - - - - - - - - - -+- |:|'
echo '|:- = - = - = - = - = = - = - = - = - = -:|'
echo '|:| -+- - - - - - - - - - - - - - - -+- |:|'
echo '|:| -:- This is a helper script to  -:- |:|'
echo '|:| -:- parse a JSON file using jq  -:- |:|'
echo '|:| -:-    and pass the variables   -:- |:|'
echo '|:| -:-  into further scripts then  -:- |:|'
echo '|:| -:- write the output to a file  -:- |:|'
echo '|:| -+- - - - - - - - - - - - - - - -+- |:|'
echo '|:- = - = - = - = - = = - = - = - = - = -:|'
echo '|:| -+- - - - - - - - - - - - - - - -+- |:|'

SOURCE_JSON_FILE=$1

SOURCE_JSON="$(cat ${SOURCE_JSON_FILE} | sed 's/\r$//')"

VALID_INPUT="$( jq -n --argjson data "$SOURCE_JSON" '$data |
		[has("templateDirectory"),has("tasks"), (.tasks |
		map(has("targets"),has("variables"),(.targets |
		map(has("templates"),has("destination"))))) ] |
		flatten(100) | all')"

if [ "$VALID_INPUT" = "true" ]; then
	echo "|:| Valid JSON Input  - - - - - - - -+- |:|"
else
	echo '|:| Invalid JSON Input'
	echo '|:|'
	echo '|:| JSON is required to this format exactly. Double check spelling |:|'
	echo '|:|'
	echo '|:| '
	echo '|:| {'
	echo '|:| "templateDirectory": // Path to the file folder holding the templates'
	echo '|:| "tasks": // Array holding objects representing a template operation in the form'
	echo '|:|   ['
	echo '|:|     {'
	echo '|:|     "targets": // Array holding objects representing a set of templates to run and where to put the output in the form'
	echo '|:|       ['
	echo '|:|         {'
	echo '|:|           "templates": // Array holding an ordered list of template base names (no .msts.sh extension) to be run to produce the output []'
	echo '|:|           "destination": // The file to write the template output to'
	echo '|:|         }, ... // More templates and file destinations using these variables as needed'
	echo '|:|       ]'
	echo '|:|       "variables": // The JSON object passed into the template runs as MSTS_VARS'
	echo '|:|     }, ... // More variable sets as needed'
	echo '|:|   ]'
	echo '|:| }'
	echo '|:|'
	echo '|:|'
	exit 1
fi

echo "$HR"

TEMPLATE_DIRECTORY="$( jq -n --argjson data "$SOURCE_JSON" '$data.templateDirectory')"
TEMPLATE_DIRECTORY="${TEMPLATE_DIRECTORY%\"}"
TEMPLATE_DIRECTORY="${TEMPLATE_DIRECTORY#\"}"
JSON_CURRENT_POSITION='$data.'

TEMPLATE_FUNCTIONS=()
TEMPLATE_NAMES=()
TEMPLATE_PATHS=()

MSTS_VARS=""
TEMPLATE_OUTPUT=""

function setupTemplate() {
	filename="$(basename ${TEMPLATE_PATHS[$i]} .msts.sh)"
	TEMPLATE_NAMES[$i]=$filename
	source ${TEMPLATE_PATHS[$i]}
	TEMPLATE_FUNCTIONS[$i]=$(declare -f $1)
	echo "|:| Template Loaded - - - - - - - - -+- |:| $filename"
}

for filepath in ~/${TEMPLATE_DIRECTORY}/*.msts.sh; do
	TEMPLATE_PATHS+=("${filepath}")
	TEMPLATE_FUNCTIONS+=("")
	TEMPLATE_NAMES+=("")
done

for i in ${!TEMPLATE_PATHS[@]}; do
	setupTemplate
done

echo "$HR"

runTemplate() {
	local completeFlag=""
	for i in ${!TEMPLATE_NAMES[@]}; do
		if [ "${TEMPLATE_NAMES[$i]}" = "$1" ]; then
			completeFlag="true"
			eval "${TEMPLATE_FUNCTIONS[$i]}"
			TEMPLATE_OUTPUT+="$(msts)"
			TEMPLATE_OUTPUT+="$N"
		fi
	done
	if [ -z "$completeFlag" ]; then
		echo "|:| Unable to locate template - - - --- |:| $1"
	else
		echo "|:| Succesfully located template  - -+- |:| $1"
	fi
}

runInternalTemplate() {
	local completeFlag=""
	for i in ${!TEMPLATE_NAMES[@]}; do
		if [ "${TEMPLATE_NAMES[$i]}" = "$1" ]; then
			completeFlag="true"
			eval "${TEMPLATE_FUNCTIONS[$i]}"
			echo "$(msts)"
		fi
	done
	if [ -z "$completeFlag" ]; then
		echo "|:| Unable to locate internal template  - --- |:| $1"
	else
		echo "|:| Succesfully located internal template -+- |:| $1"
	fi
}

CURRENT_JSON_TO_BASH_ARRAY=()

getJSONToBashArray() {
	# in the format 'arrayName' or 'objectWithArray.array'
	local targetJSONArray=$1
	local output=()
	local index=0
	# echo "$( jq -n --argjson data "$SOURCE_JSON" ''"$JSON_CURRENT_POSITION$targetJSONArray"'['"$index"']''')"
	while [ "$( jq -n --argjson data "$SOURCE_JSON" ''"$JSON_CURRENT_POSITION$targetJSONArray"'['"$index"']''')" != 'null' ]; do
		output=("${output[@]}" "$( jq -n --argjson data "$SOURCE_JSON" ''"$JSON_CURRENT_POSITION$targetJSONArray"'['"$index"']''')")
		((++index))
	done
	CURRENT_JSON_TO_BASH_ARRAY=("${output[@]}")
}


runTemplate 'test2'

runTemplate 'test'

runTemplate 'test2'

runTemplate 'test1'

echo "${CURRENT_JSON_TO_BASH_ARRAY[@]}"
getJSONToBashArray 'tasks'
echo "${CURRENT_JSON_TO_BASH_ARRAY[1]}"

echo "$TEMPLATE_OUTPUT"