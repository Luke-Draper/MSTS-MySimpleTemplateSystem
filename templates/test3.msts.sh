#!/bin/bash

function msts() {
	echo 'World'
	runTemplate test2
	echo $CURRENT_TEMPLATE_RUN
	OUTPUT=""
}