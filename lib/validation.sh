# Copyright (c) 2016 Damien Tardy-Panis
#
# This file is subject to the terms and conditions defined in
# file 'LICENSE', which is part of this source code package.
#
# Inputs validation functions


################################################################################
# Validate the position input
# Globals:
#   POSITION
# Arguments:
#   None
# Returns:
#   None
# Exits:
#   1 if invalid
################################################################################
validation::validate_position() {
  if ! date --date "${POSITION}" &> /dev/null \
     && [[ "${POSITION}" != 'left' ]] \
     && [[ "${POSITION}" != 'center' ]] \
     && [[ "${POSITION}" != 'right' ]] \
     && [[ "${POSITION}" != 'last' ]]; then
    general::error 'Invalid position date or identifier'
  fi
}


################################################################################
# Validate the Github username input
# Globals:
#   GITHUB_USERNAME
# Arguments:
#   None
# Returns:
#   None
# Exits:
#   1 if invalid
################################################################################
validation::validate_github_username() {
  # Check that the username provided exists and is linked to an user account
  if [[ -n "${GITHUB_USERNAME}" ]] \
     && ! curl --silent "https://api.github.com/users/${GITHUB_USERNAME}" \
            | grep --quiet '"type": "User"'; then
    general::error 'Invalid Github username: non existing user profile'
  fi
}


################################################################################
# Validate the shade multiplier input
# Globals:
#   SHADE_MULTIPLIER
# Arguments:
#   None
# Returns:
#   None
# Exits:
#   1 if invalid
################################################################################
validation::validate_shade_multiplier() {
  if ! [[ ${SHADE_MULTIPLIER} =~ ^[1-9][0-9]* ]]; then
    general::error 'Invalid shade multiplier: non strictly positive integer'
  fi
}


################################################################################
# Validate the template input
# Globals:
#   SCRIPT_DIR
#   TEMPLATE
# Arguments:
#   None
# Returns:
#   None
# Exits:
#   1 if invalid
################################################################################
validation::validate_template() {
  if [[ ! -f "${TEMPLATE}" ]]; then
    local provided_template=$(
      find "${SCRIPT_DIR}/templates/" -name "${TEMPLATE}.tpl" -print -quit
    )

    if [[ -f "${provided_template}" ]]; then
      TEMPLATE="${provided_template}"
    else
      local error_message='non existing file or invalid identifier'
      general::error "Invalid template value: ${error_message}"
    fi
  fi

  if [[ $( tr --delete 01234'\n' < "${TEMPLATE}" | wc --chars ) != 0 ]]; then
    local error_message='should contain only integers 0 to 4 and newlines'
    general::error "Invalid template: ${error_message}"
  fi

  # Ignore trailing newlines for further checks
  local trimmed_template=$(
    cat -- "${TEMPLATE}" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
  )

  if [[ $( echo "${trimmed_template}" | wc --lines ) != 7 ]]; then
    general::error 'Invalid template: should have 7 lines'
  fi

  local max_line_length=$( wc --max-line-length < "${TEMPLATE}" )
  local line_length

  while read line; do
    line_length=${#line}

    if [[ "${line_length}" == 0 ]]; then
      general::error 'Invalid template: empty lines are not allowed'
    fi

    if [[ "${line_length}" != "${max_line_length}" ]]; then
      general::error 'Invalid template: all lines should have the same length'
    fi
  done < <( echo "${trimmed_template}" )
}
