#!/bin/bash

SCRIPT_DIR=$( dirname "$( readlink -f "$0" )" )

COLOR_MULTIPLIER=2
EMAIL='jack@work.com'
FORCE=false
MESSAGE='All work and no play makes Jack a dull boy.'
NAME='Jack'
REPOSITORY=.
TEMPLATE="$SCRIPT_DIR/templates/jack"
VERBOSE=false
WRITE_FILE=


usage()
{
  cat << EOF
Usage: $( basename $0 ) [ARGUMENT]...

Generate the work to be displayed on Github's contributions board

OPTIONAL ARGUMENTS:
   --color, -c      INT     define work multiplier to adjust color shades
   --email, -e      VALUE   define worker email
   --force, -f              don't ask for any confirmation
   --help, -h               show this message only
   --message, -m    VALUE   define work message
   --name, -n       VALUE   define worker name
   --repository, -r FOLDER  define work repository
   --template, -t   FILE    define work template
   --verbose, -v            verbose mode
   --write, -w      VALUE   write work message into repository file

DEFAULT VALUES:
   work repository          current folder
   work template            $SCRIPT_DIR/templates/jack
   worker name              Jack
   worker email             jack@work.com
   work message             All work and no play makes Jack a dull boy.
   color multiplier         2
EOF
  exit
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

reset_work()
{
  if [ -d "$REPOSITORY" ]
  then
    if ! $FORCE
    then
      local repository_name=$( basename $( readlink -f "$REPOSITORY" ) )

      while true; do
        read -p "Confirm the reset of that \"$repository_name\" repository work? "
        case $REPLY in
            yes|y) break;;
            no|n) exit;;
            *) echo "Please answer yes or no.";;
        esac
      done
    fi
  else
    mkdir -p "$REPOSITORY"
  fi

  [ -z "$WRITE_FILE" ] || > "$REPOSITORY/$WRITE_FILE"

  rm -rf "$REPOSITORY/.git"
  git --git-dir="$REPOSITORY/.git" --work-tree="$REPOSITORY" init --quiet
}

day_count()
{
  local day_number="$1"
  local row=$(( $day_number % 7 + 1 ))
  local col=$(( $day_number / 7 + 1 ))
  local index=$( head "$TEMPLATE" -n $row | tail -n1 | head -c $col | tail -c1 )

  echo $(( $index * $COLOR_MULTIPLIER ))
}

commit_work()
{
  local date_format='%Y-%m-%d'
  local start_date="$( date --date="-52 weeks next sunday" +$date_format )"
  local days=$(( $( wc --max-line-length < "$TEMPLATE" ) * 7 ))
  local date count

  for (( c = 0; c < "$days"; c++ ))
  do
    date=$( date --date="$start_date +$c day" +$date_format )
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
    --git-dir="$REPOSITORY/.git" \
    --work-tree="$REPOSITORY" \
    add \
    "$WRITE_FILE"
  fi

  git \
  --git-dir="$REPOSITORY/.git" \
  --work-tree="$REPOSITORY" \
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
  [ -f "$TEMPLATE" ] || error 'Invalid template path: non existing file'

  if ! [[ $COLOR_MULTIPLIER =~ ^[1-9][0-9]* ]]
  then
    error 'Invalid color multiplier: non strictly positive integer'
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
    --template|-t)
      [ -n "$2" ] || error 'Missing template path'
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


parse_inputs "$@"
validate_inputs

reset_work
commit_work

info "$MESSAGE"
