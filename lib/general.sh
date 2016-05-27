init_variables()
{
  SHADE_MULTIPLIER=1
  AUTHOR_EMAIL='jack@work.com'
  FORCE=false
  KEEP=false
  MESSAGE='All work and no play makes Jack a dull boy.'
  AUTHOR_NAME='Jack'
  REPOSITORY=.
  POSITION='left'
  TEMPLATE="jack"
  GITHUB_USERNAME=
  VERBOSE=false
  WRITE_FILE=

  if git config --global --includes user.name &> /dev/null
  then
    AUTHOR_NAME=$( git config --global --includes user.name )
  fi

  if git config --global --includes user.email &> /dev/null
  then
    AUTHOR_EMAIL=$( git config --global --includes user.email )
  fi
}

usage()
{
  cat << EOF
Usage: $( basename $0 ) [ARGUMENT]...

Generate the work to be displayed on Github's contributions board

OPTIONAL ARGUMENTS:
  -e, --email       VALUE     define worker email
  -f. --force                 skip any confirmation question
  -g. --github      USERNAME  calculate multiplier from Github user profile
  -h, --help                  show this message only
  -k, --keep                  skip the reset of the work repository
  -m, --message     VALUE     define work message
  -n, --name        VALUE     define worker name
  -p, --position    DATE/ID   define template position
  -r, --repository  FOLDER    define work repository
  -s, --shade       INT       multiply work to adjust color shades
  -t, --template    FILE/ID   define work template
  -v, --verbose               enable verbose mode
  -w, --write       VALUE     write work message into repository file

PROVIDED TEMPLATES IDENTIFIER:
  In $SCRIPT_DIR/templates/ folder:
$( find "$SCRIPT_DIR/templates/" -type f -printf '   - %f\n' )

WORK TEMPLATE POSITIONS:
  left      work starts on the left side of the board
  center    work is centered on the board
  right     work ends on the right side of the board

DEFAULT VALUES:
  work repository    current folder
  work template      jack
  work position      left
  worker name        user global git name (Jack if not defined)
  worker email       user global git email (jack@work.com if not defined)
  work message       All work and no play makes Jack a dull boy.

NOTES
  - In case both the github and shade arguments are provided, the multiplier
    calculated from the Github profile takes precedence
EOF
  exit 0
}

error()
{
  [ -z "$1" ] || echo "$1"
  echo "Try '$( basename $0 ) --help' for more information"
  exit 1
}

info()
{
  "$VERBOSE" && [ -n "$1" ] && echo "$1"
}

parse_inputs()
{
  while [[ "$#" -gt 0 ]]
  do
    case "$1" in
    --email|-e)
      [ -n "$2" ] || error 'Missing email value'
      AUTHOR_EMAIL="$2"
      shift 2
      ;;
    --force|-f)
      FORCE=true
      shift
      ;;
    --github|-g)
      [ -n "$2" ] || error 'Missing Github username'
      GITHUB_USERNAME="$2"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    --keep|-k)
      KEEP=true
      shift
      ;;
    --message|-m)
      [ -n "$2" ] || error 'Missing message value'
      MESSAGE="$2"
      shift 2
      ;;
    --name|-n)
      [ -n "$2" ] || error 'Missing name value'
      AUTHOR_NAME="$2"
      shift 2
      ;;
    --position|-p)
      [ -n "$2" ] || error 'Missing position start date or identifier'
      POSITION="$2"
      shift 2
      ;;
    --repository|-r)
      [ -n "$2" ] || error 'Missing repository path'
      REPOSITORY="$2"
      shift 2
      ;;
    --shade|-s)
      [ -n "$2" ] || error 'Missing shade multiplier'
      SHADE_MULTIPLIER="$2"
      shift 2
      ;;
    --template|-t)
      [ -n "$2" ] || error 'Missing template path or identifier'
      TEMPLATE="$2"
      shift 2
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --write|-w)
      [ -n "$2" ] || error 'Missing write filename value'
      WRITE_FILE="$2"
      shift 2
      ;;
    *)
      error "Invalid argument '$1'"
      ;;
    esac
  done
}

validate_inputs()
{
  validate_position
  validate_github_username
  validate_shade_multiplier
  validate_template
}
