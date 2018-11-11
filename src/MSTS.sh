#!/bin/bash

source './MSTS_Template_Functions.sh'
source './MSTS_Runtime_Functions.sh'

SOURCE_JSON_FILE=$1

echo ' _______________________________________________ '
echo "$LHR"
echo '|:| |:-     My Simple Template System     -:| |:|'
echo '|:| |:-       Made By : Luke Draper       -:| |:- See -:- https://github.com/Luke-Draper/MSTS-MySimpleTemplateSystem'
echo "$LHR"
echo '|:| -:- This is a helper script to parse  -:- |:|'
echo '|:| -:- a JSON file using jq and pass the -:- |:|'
echo '|:| -:-  variables into further scripts   -:- |:|'
echo '|:| -:-  then write the output to a file  -:- |:|'
echo "$LHR"

testJSONSource

setupAllTemplates

runTemplates
