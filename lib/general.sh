init_variables()
{
  COLOR_MULTIPLIER=1
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
  --color, -c       INT       multiply work to adjust color shades
  --email, -e       VALUE     define worker email
  --force, -f                 skip any confirmation question
  --help, -h                  show this message only
  --keep, -k                  skip the reset of the work repository
  --message, -m     VALUE     define work message
  --name, -n        VALUE     define worker name
  --position, -p    DATE/ID   define template position
  --repository, -r  FOLDER    define work repository
  --template, -t    FILE/ID   define work template
  --username, -u    VALUE     calculate multiplier from user github profile
  --verbose, -v               enable verbose mode
  --write, -w       VALUE     write work message into repository file

PROVIDED TEMPLATES IDENTIFIER:
  In $SCRIPT_DIR/templates/ folder:
$( find "$SCRIPT_DIR/templates/" -type f -printf '   - %f\n' )

DEFAULT VALUES:
  work repository    current folder
  work template      jack
  work position      left
  worker name        user global git name (Jack if not defined)
  worker email       user global git email (jack@work.com if not defined)
  work message       All work and no play makes Jack a dull boy.

NOTES
  - In case both username and color arguments are provided, the multiplier
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
    --color|-c)
      [ -n "$2" ] || error 'Missing color value'
      COLOR_MULTIPLIER="$2"
      shift 2
      ;;
    --email|-e)
      [ -n "$2" ] || error 'Missing email value'
      AUTHOR_EMAIL="$2"
      shift 2
      ;;
    --force|-f)
      FORCE=true
      shift
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
    --template|-t)
      [ -n "$2" ] || error 'Missing template path or identifier'
      TEMPLATE="$2"
      shift 2
      ;;
    --username|-u)
      [ -n "$2" ] || error 'Missing username value'
      GITHUB_USERNAME="$2"
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
  validate_color_multiplier
  validate_template
}
