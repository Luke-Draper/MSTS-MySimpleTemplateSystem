#!/bin/bash

N=$'\n'
T=$'\t'

SOURCE_JSON_FILE=$1

SOURCE_JSON="$(cat ${SOURCE_JSON_FILE} | sed 's/\r$//')"

# Test for required fields in each JSON object as listed below
# {
# "templateDirectory": Path to the file folder holding the templates
# "tasks": Array holding objects representing a template operation in the form
# 	[
# 		{
# 		"targets": Array holding objects representing a set of templates to run and where to put the output in the form
# 			[
# 				{
# 					"templates": Array holding an ordered list of template base names (no .msts.sh extension) to be run to produce the output []
# 					"destination": The file to write the template output to
# 				}
# 			]
# 			"variables": The JSON object passed into the template runs as MSTS_VARS
VALID_INPUT="$( jq -n --argjson data "$SOURCE_JSON" '$data |
		[has("templateDirectory"),has("tasks"), (.tasks |
		map(has("targets"),has("variables"),(.targets |
		map(has("templates"),has("destination"))))) ] |
		flatten(100) | all')"

if [ "$VALID_INPUT" = "true" ]; then
	echo "Valid JSON Input"
else
	echo 'Invalid JSON Input'
	echo ''
	echo 'JSON is required to this format exactly. Double check spelling :'
	echo ''
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
	echo '|:|         }, ...'
	echo '|:|       ]'
	echo '|:|       "variables": // The JSON object passed into the template runs as MSTS_VARS'
	echo '|:|     }, ...'
	echo '|:|   ]'
	echo '|:| }'
	echo '|:| '
	echo ''
	exit 1
fi


TEMPLATE_DIRECTORY="$( jq -n --argjson data "$SOURCE_JSON" '$data.templateDirectory')"
TEMPLATE_DIRECTORY="${TEMPLATE_DIRECTORY%\"}"
TEMPLATE_DIRECTORY="${TEMPLATE_DIRECTORY#\"}"

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
	echo "Template Loaded : $filename"
}

for filepath in ~/${TEMPLATE_DIRECTORY}/*.msts.sh; do
	TEMPLATE_PATHS+=("${filepath}")
	TEMPLATE_FUNCTIONS+=("")
	TEMPLATE_NAMES+=("")
done

for i in ${!TEMPLATE_PATHS[@]}; do
	setupTemplate
done

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
		echo "Unable to locate template    : $1"
	else
		echo "Succesfully located template : $1"
	fi
}

runTemplate 'test2'

runTemplate 'test'

runTemplate 'test2'

runTemplate 'test1'

echo "$TEMPLATE_OUTPUT"