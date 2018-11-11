#!/bin/bash

TEMPLATE_FUNCTIONS=()
TEMPLATE_NAMES=()
TEMPLATE_PATHS=()
TEMPLATE_OUTPUT=""
CURRENT_TEMPLATE_RUN_RUNTIME=""
CURRENT_JSON_TO_BASH_ARRAY_RUNTIME=()
CURRENT_TARGET_ARRAY=()
CURRENT_TEMPLATE_ARRAY=()
TASK_ARRAY=()
CURRENT_DESTINATION=""


function testValidJSONSource() {
	VALID_INPUT="$( jq -n --argjson data "$1" '$data |
			[has("templateDirectory"),has("tasks"), (.tasks |
			map(has("targets"),has("variables"),(.targets |
			map(has("templates"),has("destination"))))) ] |
			flatten(100) | all')"

	if [ "$VALID_INPUT" = "true" ]; then
		echo "|:| Valid JSON Input  - - - - - - - - - - -+- |:|"
		echo "$HR"
	else
		echo '|:| Invalid JSON Input'
		echo '|:|'
		echo '|:| JSON is required to follow this format exactly.'
		echo '|:| Spelling is required.'
		echo '|:| If problems persist please reference an example in the github repo.'
		echo '|:|'
		echo ''
		echo '{'
		echo '"templateDirectory": // Path to the file folder holding the templates'
		echo '"tasks": // Array holding objects representing a template operation in the form'
		echo '  ['
		echo '    {'
		echo '    "targets": // Array holding objects representing a set of templates to run and where to put the output in the form'
		echo '      ['
		echo '        {'
		echo '          "templates": // Array holding an ordered list of template base names (no .msts.sh extension) to be run to produce the output []'
		echo '          "destination": // The file to write the template output to'
		echo '        }, ... // More templates and file destinations using these variables as needed'
		echo '      ]'
		echo '      "variables": // The JSON object passed into the template runs as MSTS_VARS'
		echo '    }, ... // More variable sets as needed'
		echo '  ]'
		echo '}'
		echo ''
		exit 2
	fi
}

function testJSONSource() {
	if [ -z $SOURCE_JSON_FILE ]; then
		echo '|:| Please provide the path to your JSON source document when you call this function'
		echo '|:|'
		echo ''
		echo './MSTS.sh ./path/to/source.json'
		echo ''
		exit 1
	else
		SOURCE_JSON="$(cat ${SOURCE_JSON_FILE} | sed 's/\r$//')"
		testValidJSONSource "$SOURCE_JSON"
		TEMPLATE_DIRECTORY="$( jq -n --argjson data "$SOURCE_JSON" '$data.templateDirectory')"
		TEMPLATE_DIRECTORY="${TEMPLATE_DIRECTORY%\"}"
		TEMPLATE_DIRECTORY="${TEMPLATE_DIRECTORY#\"}"
		JSON_CURRENT_POSITION='$data.'
	fi
}

function setupTemplate() {
	filename="$(basename ${TEMPLATE_PATHS[$i]} .msts.sh)"
	TEMPLATE_NAMES[$i]=$filename
	source ${TEMPLATE_PATHS[$i]}
	TEMPLATE_FUNCTIONS[$i]=$(declare -f $1)
	echo "|:| Template Loaded - - - - - - - - - - - -+- -:- $filename"
}

function setupAllTemplates() {
	echo '|:| Loading all templates - - - - - - - - -+- |:|'
	echo "$HR"
	for filepath in ~/${TEMPLATE_DIRECTORY}/*.msts.sh; do
		TEMPLATE_PATHS+=("${filepath}")
		TEMPLATE_FUNCTIONS+=("")
		TEMPLATE_NAMES+=("")
	done

	for i in ${!TEMPLATE_PATHS[@]}; do
		setupTemplate
	done
	echo "$HR"
	echo '|:| Template Loading Complete - - - - - - -+- |:|'
	echo "$LHR"
}

function runTemplateRuntime() {
	local completeFlag=""
	for i in ${!TEMPLATE_NAMES[@]}; do
		if [ "${TEMPLATE_NAMES[$i]}" = "$1" ]; then
			completeFlag="true"
			eval "${TEMPLATE_FUNCTIONS[$i]}"
			CURRENT_TEMPLATE_RUN_RUNTIME="$(msts)"
		fi
	done
	if [ -z "$completeFlag" ]; then
		echo "|:| Unable to locate template - - - - - - --- -:- $1"
	else
		echo "|:| Running Template  - - - - - - - - - - -+- -:- $1"
	fi
}

getJSONToBashArrayRuntime() {
	# in the format 'arrayName' or 'objectWithArray.array'
	local targetJSONArray=$1
	local output=()
	local index=0
	while [ "$( jq -n --argjson data "$SOURCE_JSON" '$data.'"$targetJSONArray"'['"$index"']''')" != 'null' ]; do
		output=("${output[@]}" "$( jq -n --argjson data "$SOURCE_JSON" '$data.'"$targetJSONArray"'['"$index"']''')")
		((++index))
	done
	CURRENT_JSON_TO_BASH_ARRAY_RUNTIME=("${output[@]}")
}

function runTemplates() {
	echo '|:| Reading Task List - - - - - - - - - - -+- |:|'

	getJSONToBashArrayRuntime 'tasks'
	TASK_ARRAY=("${CURRENT_JSON_TO_BASH_ARRAY_RUNTIME[@]}")

	echo '|:| Task List Length  - - - - - - - - - - -+- -:- '"${#TASK_ARRAY[@]}"
	echo "$HR"

	taskIndex=0
	for task in ${!TASK_ARRAY[@]}; do
		echo '|:| Reading Target List of Task - - - - - -+- -:- '"$taskIndex"

		getJSONToBashArrayRuntime 'tasks['"$task"'].targets'
		CURRENT_TARGET_ARRAY=("${CURRENT_JSON_TO_BASH_ARRAY_RUNTIME[@]}")

		echo '|:| Target List Length  - - - - - - - - - -+- -:- '"${#CURRENT_TARGET_ARRAY[@]}"
		echo "$HR"

		targetIndex=0
		for target in ${!CURRENT_TARGET_ARRAY[@]}; do
			echo '|:| Reading Template List of Target - - - -+- -:- '"$targetIndex"

			getJSONToBashArrayRuntime 'tasks['"$task"'].targets['"$target"'].templates'
			CURRENT_TEMPLATE_ARRAY=("${CURRENT_JSON_TO_BASH_ARRAY_RUNTIME[@]}")
			CURRENT_DESTINATION="$( jq -n --argjson data "$SOURCE_JSON" '$data.tasks['"$task"'].targets['"$target"'].destination')"
			JSON_CURRENT_POSITION='tasks['"$task"'].variables.'
			MSTS_VARS="$( jq -n --argjson data "$SOURCE_JSON" '$data.tasks['"$task"'].variables')"
			
			echo '|:| Template List Length  - - - - - - - - -+- -:- '"${#CURRENT_TEMPLATE_ARRAY[@]}"
			echo "$HR"

			for template in ${!CURRENT_TEMPLATE_ARRAY[@]}; do
				runTemplateRuntime "${CURRENT_TEMPLATE_ARRAY[$template]//\"}"
				TEMPLATE_OUTPUT+="$CURRENT_TEMPLATE_RUN_RUNTIME"
				TEMPLATE_OUTPUT+="$N"
			done

			echo "$HR"
			echo '|:| Writing Templates to File - - - - - - -+- -:- '"$CURRENT_DESTINATION"

			touch "$HOME"'/'"${CURRENT_DESTINATION//\"}"
			echo "$TEMPLATE_OUTPUT" > "$HOME"'/'"${CURRENT_DESTINATION//\"}"
			TEMPLATE_OUTPUT=""

			echo '|:| Templates Succesfully to File - - - - -+- |:| '"$CURRENT_DESTINATION"
			echo "$HR"

			((++targetIndex))
		done

		((++taskIndex))
	done
}
