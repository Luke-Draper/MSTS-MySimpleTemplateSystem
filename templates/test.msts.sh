#!/bin/bash

function msts() {
	echo 'World'
	runTemplate test3
	echo $CURRENT_TEMPLATE_RUN
	OUTPUT=""
}