# Copyright (c) 2016 Damien Tardy-Panis
#
# This file is subject to the terms and conditions defined in
# file 'LICENSE', which is part of this source code package.
#
# General global functions


################################################################################
# Initialize the environment global variables
# Globals:
#   AUTHOR_EMAIL
#   AUTHOR_NAME
#   FORCE
#   GITHUB_USERNAME
#   KEEP
#   MESSAGE
#   POSITION
#   REPOSITORY
#   SHADE_MULTIPLIER
#   TEMPLATE
#   VERBOSE
#   WRITE_FILE
# Arguments:
#   None
# Returns:
#   None
################################################################################
general::init_variables() {
  AUTHOR_EMAIL='jack@work.com'
  AUTHOR_NAME='Jack'
  FORCE=false
  GITHUB_USERNAME=
  KEEP=false
  MESSAGE='All work and no play makes Jack a dull boy.'
  POSITION='left'
  REPOSITORY=.
  SHADE_MULTIPLIER=1
  TEMPLATE='jack'
  VERBOSE=false
  WRITE_FILE=

  if git config --global --includes user.name &> /dev/null; then
    AUTHOR_NAME=$( git config --global --includes user.name )
  fi

  if git config --global --includes user.email &> /dev/null; then
    AUTHOR_EMAIL=$( git config --global --includes user.email )
  fi
}


################################################################################
# Print the usage explanation of the main program and exit
# Globals:
#   SCRIPT_DIR
# Arguments:
#   None
# Returns:
#   0
################################################################################
general::usage() {
  cat << EOF
Usage: $( basename $0 ) [ARGUMENT]...

Generate the work to be displayed on Github's contributions board

OPTIONAL ARGUMENTS:
  -e, --email       VALUE     define author email
  -f. --force                 skip any confirmation question
  -g. --github      USERNAME  calculate multiplier from Github user profile
                              the value takes precedence over a shade argument
  -h, --help                  show this message only
  -k, --keep                  skip the reset of the work repository
  -m, --message     VALUE     define work message
  -n, --name        VALUE     define author name
  -p, --position    DATE/ID   define template position with a start date or
                              an identifier (see values below)
  -r, --repository  FOLDER    define work repository
                              gets created if doesn't exists, reset otherwise
  -s, --shade       INT       multiply work to adjust color shades
  -t, --template    FILE/ID   define work template with a file or
                              an identifier (see values below)
  -v, --verbose               enable verbose mode
  -w, --write       FILENAME  write the message into a repository file
                              for each single work

PROVIDED TEMPLATES IDENTIFIERS:
  Use the basename of all files within the templates folder
  ${SCRIPT_DIR}/templates/

TEMPLATE POSITIONS IDENTIFIERS:
  left      work starts on the left side of the current board
  center    work is centered on the current board
  right     work ends on the right side of the current board
  last      work starts after the last work in the repository (left if none)

DEFAULT VALUES:
  repository        current folder
  template          jack
  position          left
  author name       user global git name (Jack if not defined)
  author email      user global git email (jack@work.com if not defined)
  message           All work and no play makes Jack a dull boy.
EOF
  exit 0
}


################################################################################
# Print an error message and exit
# Globals:
#   None
# Arguments:
#   - message to display (optional)
# Returns:
#   1
################################################################################
general::error() {
  [[ -z "$1" ]] || echo "$1" >&2
  echo "Try '$( basename $0 ) --help' for more information" >&2
  exit 1
}


################################################################################
# Prints an information message if verbose mode is enabled
# Globals:
#   VERBOSE
# Arguments:
#   - message to display
# Returns:
#   None
################################################################################
general::info() {
  "${VERBOSE}" && [[ -n "$1" ]] && echo "$1"
}


################################################################################
# Parse the main program's inputs
# Globals:
#   AUTHOR_EMAIL
#   AUTHOR_NAME
#   FORCE
#   GITHUB_USERNAME
#   KEEP
#   MESSAGE
#   POSITION
#   REPOSITORY
#   SHADE_MULTIPLIER
#   TEMPLATE
#   VERBOSE
#   WRITE_FILE
# Arguments:
#   Program's arguments
# Returns:
#   1 in case of invalid argument or missing value
#
################################################################################
general::parse_inputs() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --email|-e)
        [[ -n "$2" ]] || general::error 'Missing email value'
        AUTHOR_EMAIL="$2"
        shift 2
        ;;
      --force|-f)
        FORCE=true
        shift
        ;;
      --github|-g)
        [[ -n "$2" ]] || general::error 'Missing Github username'
        GITHUB_USERNAME="$2"
        shift 2
        ;;
      --help|-h)
        general::usage
        ;;
      --keep|-k)
        KEEP=true
        shift
        ;;
      --message|-m)
        [[ -n "$2" ]] || general::error 'Missing message value'
        MESSAGE="$2"
        shift 2
        ;;
      --name|-n)
        [[ -n "$2" ]] || general::error 'Missing name value'
        AUTHOR_NAME="$2"
        shift 2
        ;;
      --position|-p)
        [[ -n "$2" ]] || general::error 'Missing position date or identifier'
        POSITION="$2"
        shift 2
        ;;
      --repository|-r)
        [[ -n "$2" ]] || general::error 'Missing repository path'
        REPOSITORY="$2"
        shift 2
        ;;
      --shade|-s)
        [[ -n "$2" ]] || general::error 'Missing shade multiplier'
        SHADE_MULTIPLIER="$2"
        shift 2
        ;;
      --template|-t)
        [[ -n "$2" ]] || general::error 'Missing template path or identifier'
        TEMPLATE="$2"
        shift 2
        ;;
      --verbose|-v)
        VERBOSE=true
        shift
        ;;
      --write|-w)
        [[ -n "$2" ]] || general::error 'Missing write filename value'
        WRITE_FILE="$2"
        shift 2
        ;;
      *)
        general::error "Invalid argument '$1'"
        ;;
    esac
  done
}


################################################################################
# Validate all the inputs
# Globals:
#   GITHUB_USERNAME
#   POSITION
#   SCRIPT_DIR
#   SHADE_MULTIPLIER
#   TEMPLATE
# Arguments:
#   None
# Returns:
#   1 if at least one of them is invalid
################################################################################
general::validate_inputs() {
  validation::validate_position
  validation::validate_github_username
  validation::validate_shade_multiplier
  validation::validate_template
}