#!/bin/bash

init_variables()
{
  SCRIPT_DIR=$( dirname "$( readlink -f "$0" )" )

  COLOR_MULTIPLIER=2
  EMAIL='jack@work.com'
  FORCE=false
  KEEP=false
  MESSAGE='All work and no play makes Jack a dull boy.'
  NAME='Jack'
  REPOSITORY=.
  START='left'
  TEMPLATE="jack"
  USERNAME=
  VERBOSE=false
  WRITE_FILE=

  if git config --global --includes user.name &> /dev/null
  then
    NAME=$( git config --global --includes user.name )
  fi

  if git config --global --includes user.email &> /dev/null
  then
    EMAIL=$( git config --global --includes user.email )
  fi
}

usage()
{
  cat << EOF
Usage: $( basename $0 ) [ARGUMENT]...

Generate the work to be displayed on Github's contributions board

OPTIONAL ARGUMENTS:
   --color, -c       INT       define work multiplier to adjust color shades
   --email, -e       VALUE     define worker email
   --force, -f                 don't ask for any confirmation
   --help, -h                  show this message only
   --keep, -k                  don't reset the work repository
   --message, -m     VALUE     define work message
   --name, -n        VALUE     define worker name
   --repository, -r  FOLDER    define work repository
   --start, -s       DATE/POS  define work start
   --template, -t    FILE/ID   define work template
   --username, -u    VALUE     define github username to calculate multiplier
   --verbose, -v               verbose mode
   --write, -w       VALUE     write work message into repository file

PROVIDED TEMPLATES IDENTIFIER:
   In $SCRIPT_DIR/templates/ folder:
$( find "$SCRIPT_DIR/templates/" -type f -printf '   - %f\n' )

DEFAULT VALUES:
   work repository          current folder
   work template            jack
   work start               left
   worker name              user global git name (Jack if not defined)
   worker email             user global git email (jack@work.com if not defined)
   work message             All work and no play makes Jack a dull boy.
   color multiplier         2

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

init_work()
{
  if [ -d "$REPOSITORY" ]
  then
    if ! $KEEP
    then
      local repository_name=$( basename $( readlink -f "$REPOSITORY" ) )

      if ! $FORCE && \
        ( [ -d "$REPOSITORY/.git" ] || [ -f "$REPOSITORY/$WRITE_FILE" ] )
      then
        while true; do
          read -p "Confirm the reset of that \"$repository_name\" repository work? "
          case $REPLY in
              yes|y) break;;
              no|n) exit 0;;
              *) echo "Please answer yes or no.";;
          esac
        done
      fi

      info "Resetting $repository_name work repository"
      rm -rf "$REPOSITORY/.git"
      [ -z "$WRITE_FILE" ] || > "$REPOSITORY/$WRITE_FILE"
    fi
  else
    info "Creating $REPOSITORY work repository"
    mkdir -p "$REPOSITORY"
  fi

  git --git-dir "$REPOSITORY/.git" --work-tree "$REPOSITORY" init --quiet
}

define_multiplier()
{
  if [ -n "$USERNAME" ]
  then
    local count=$(
      curl --silent "https://github.com/$USERNAME" \
      | grep data-count \
      | grep '#1e6823' \
      | sed -r 's/.* data-count="([0-9]+)" .*/\1/' \
      | sort --unique --general-numeric-sort \
      | head --lines 1
    )
    [[ "$count" -gt 0 ]] || count=1
    COLOR_MULTIPLIER=$( printf %0.f $( echo "$count / 4" | bc --mathlib ) )
  fi
}

day_count()
{
  local day_number="$1"
  local row=$(( $day_number % 7 + 1 ))
  local col=$(( $day_number / 7 + 1 ))
  local index=$( head "$TEMPLATE" -n $row | tail -n1 | head -c $col | tail -c1 )

  echo $(( $index * $COLOR_MULTIPLIER ))
}

start_date()
{
  if [ "$START" == 'left' ]
  then
    START='-1 year'
  else
    local template_cols=$( wc --max-line-length < "$TEMPLATE" )

    if [ "$START" == 'center' ]
    then
      START="-53 weeks $(( (53 - $template_cols)/2 )) weeks"
    elif [ "$START" == 'right' ]
    then
      START="-$template_cols weeks"
    fi
  fi

  local start="$( echo "$START" | sed "s/ /\\\ /g" )"
  echo "$start"'\ +'{0..6}'\ days' | xargs -n 1 date --date | grep Sun
}

commit_work()
{
  local date_format='%Y-%m-%d'
  local start_date="$( date --date "$( start_date )" +$date_format )"
  local days=$(( $( wc --max-line-length < "$TEMPLATE" ) * 7 ))
  local date count

  for (( c = 0; c < "$days"; c++ ))
  do
    date=$( date --date "$start_date +$c day" +$date_format )
    count=$( day_count $c )
    commit_day_work "$date" "$count"
  done
}

random_time()
{
  local hours=$( printf %02d $(( $RANDOM % 24 )) )
  local minutes=$( printf %02d $(( $RANDOM % 60 )) )
  local seconds=$( printf %02d $(( $RANDOM % 60 )) )

  echo $hours:$minutes:$seconds
}

commit_day_work()
{
  local date="$1"
  local count="$2"
  local times

  info "Committing day work $date $count"

  for ((i = 1; i <= $count; i++))
  do
    times="$times $( random_time )"
  done

  for time in $( echo "$times" | tr " " "\n" | sort )
  do
   commit_a_work "$date" "$time"
  done
}

commit_a_work()
{
  local date="$1"
  local time="$2"

  if [ -n "$WRITE_FILE" ]
  then
    echo "$MESSAGE" >> "$REPOSITORY/$WRITE_FILE"
    git \
    --git-dir "$REPOSITORY/.git" \
    --work-tree "$REPOSITORY" \
    add \
    "$WRITE_FILE"
  fi

  git \
  --git-dir "$REPOSITORY/.git" \
  --work-tree "$REPOSITORY" \
  commit \
  --allow-empty \
  --message "$MESSAGE" \
  --author "$NAME <$EMAIL>" \
  --date "$date $time" \
  --quiet
}

validate_template()
{
  if [ $( tr --delete 01234'\n' < "$TEMPLATE" | wc --chars ) != 0 ]
  then
    error 'Invalid template: should contain only integers 0 to 4 and newlines'
  fi

  local trimmed_template=$( sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$TEMPLATE" )

  if [ $( echo "$trimmed_template" | wc --lines ) != 7 ]
  then
    error 'Invalid template: should have 7 lines'
  fi

  local max_line_length=$( wc --max-line-length < "$TEMPLATE" )
  local line_length

  while read line
  do
    line_length=${#line}

    if [ "$line_length" == 0 ]
    then
      error 'Invalid template: empty lines are not allowed'
    fi

    if [ "$line_length" != "$max_line_length" ]
    then
      error 'Invalid template: all lines should have the same length'
    fi
  done < <( echo "$trimmed_template" )
}

validate_inputs()
{
  if [ ! -f "$TEMPLATE" ]
  then
    local provided_template="$SCRIPT_DIR/templates/$TEMPLATE"

    if [ -f "$provided_template" ]
    then
      TEMPLATE="$provided_template"
    else
      error 'Invalid template value: non existing file or invalid identifier'
    fi
  fi

  if ! [[ $COLOR_MULTIPLIER =~ ^[1-9][0-9]* ]]
  then
    error 'Invalid color multiplier: non strictly positive integer'
  fi

  if ! date --date "$START" &> /dev/null \
     && [ "$START" != 'left' ] \
     && [ "$START" != 'center' ] \
     && [ "$START" != 'right' ]
  then
    error 'Invalid start date or position'
  fi

  if [ -n "$USERNAME" ] \
     && ! curl --silent "https://api.github.com/users/$USERNAME" \
          | grep --quiet '"type": "User"'
  then
    error 'Invalid username: non existing user profile'
  fi

  validate_template
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
      EMAIL="$2"
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
      NAME="$2"
      shift 2
      ;;
    --repository|-r)
      [ -n "$2" ] || error 'Missing repository path'
      REPOSITORY="$2"
      shift 2
      ;;
    --start|-s)
      [ -n "$2" ] || error 'Missing start date'
      START="$2"
      shift 2
      ;;
    --template|-t)
      [ -n "$2" ] || error 'Missing template path'
      TEMPLATE="$2"
      shift 2
      ;;
    --username|-u)
      [ -n "$2" ] || error 'Missing username value'
      USERNAME="$2"
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


init_variables

parse_inputs "$@"
validate_inputs

define_multiplier
init_work
commit_work

info "$MESSAGE"

exit 0
