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
# Exits:
#   Never
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
#   None
# Exits:
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
#   None
# Exits:
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
# Exits:
#   Never
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
#   OPTIONS
#   POSITION
#   REPOSITORY
#   SHADE_MULTIPLIER
#   TEMPLATE
#   VERBOSE
#   WRITE_FILE
# Arguments:
#   Program's arguments
# Returns:
#   None
# Exits:
#   0 if print usage
#   1 if invalid argument
################################################################################
general::parse_inputs() {
   local long_options='email:,force,github:,help,keep,message:'
   long_options="${long_options},name:,position:,repository:,shade:"
   long_options="${long_options},template:,verbose,write:"

  OPTIONS=$(
    getopt \
    --options e:fg:hkm:n:p:r:s:t:vw: \
    --longoptions "${long_options}" \
    --name "$( basename $0 )" \
    -- "$@"
  )

  if [[ $? -ne 0 ]]; then
    general::error
  fi

  eval set -- "${OPTIONS}"

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --email|-e) AUTHOR_EMAIL="$2"; shift 2 ;;
      --force|-f) FORCE=true; shift ;;
      --github|-g) GITHUB_USERNAME="$2"; shift 2 ;;
      --help|-h) general::usage ;;
      --keep|-k) KEEP=true; shift ;;
      --message|-m) MESSAGE="$2"; shift 2 ;;
      --name|-n) AUTHOR_NAME="$2"; shift 2 ;;
      --position|-p) POSITION="$2"; shift 2 ;;
      --repository|-r) REPOSITORY="$2"; shift 2 ;;
      --shade|-s) SHADE_MULTIPLIER="$2"; shift 2 ;;
      --template|-t) TEMPLATE="$2"; shift 2 ;;
      --verbose|-v) VERBOSE=true; shift ;;
      --write|-w) WRITE_FILE="$2"; shift 2 ;;
      --) shift ;;
      *) general::error "Invalid argument '$1'" ;;
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
#   None
# Exits:
#   1 if at least one of them is invalid
################################################################################
general::validate_inputs() {
  validation::validate_position
  validation::validate_github_username
  validation::validate_shade_multiplier
  validation::validate_template
}
