#!/bin/bash

SCRIPT_DIR=$( dirname "$( readlink --canonicalize "$0" )" )

. "$SCRIPT_DIR/lib/general.sh"
. "$SCRIPT_DIR/lib/validation.sh"
. "$SCRIPT_DIR/lib/work.sh"

init_variables

parse_inputs "$@"
validate_inputs

define_multiplier
init_work
commit_work

exit 0
