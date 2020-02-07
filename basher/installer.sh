#!/usr/bin/env bash

source $(dirname $0)/docker_functions.sh
source $(dirname $0)/software_functions.sh

"${@}"
