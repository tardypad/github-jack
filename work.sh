#!/bin/bash

usage()
{
  cat << EOF
Usage: $( basename $0 ) [ARGUMENT]...

Generate the work to be displayed on Github's contributions board

REQUIRED ARGUMENTS:
   --repository, -r FOLDER  define work repository
   --template, -t   FILE    define work template

OPTIONAL ARGUMENTS:
   --color, -c      INT     define work multiplier to adjust color shades
   --email, -e      VALUE   define worker email
   --force, -f              don't ask for any confirmation
   --help, -h               show this message only
   --message, -m    VALUE   define work message
   --name, -n       VALUE   define worker name
   --verbose, -v            verbose mode

DEFAULT VALUES:
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
  if ! $FORCE
  then
    while true; do
      read -p "Are you sure you want to reset the previous work of that repository? "
      case $REPLY in
          yes|y) break;;
          no|n) exit;;
          *) echo "Please answer yes or no.";;
      esac
    done
  fi

  rm -rf "$REPO/.git"
  git --git-dir="$REPO/.git" --work-tree="$REPO" init --quiet
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

  git \
  --git-dir="$REPO/.git" \
  --work-tree="$REPO" \
  commit \
  --allow-empty \
  --message "$MESSAGE" \
  --author "$NAME <$EMAIL>" \
  --date "$date $time" \
  --quiet
}


REPO=
TEMPLATE=
COLOR_MULTIPLIER=2
NAME='Jack'
EMAIL='jack@work.com'
MESSAGE='All work and no play makes Jack a dull boy.'
VERBOSE=false
FORCE=false

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
        REPO="$2"
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
  *)
        error "Invalid argument '$1'"
        ;;
  esac
done

[ -n "$REPO" ] || error 'Missing repository argument'
[ -n "$TEMPLATE" ] || error 'Missing template argument'

[ -d "$REPO" ] || error 'Invalid repository path'
[ -f "$TEMPLATE" ] || error 'Invalid template path'

[[ $COLOR_MULTIPLIER =~ ^[1-9][0-9]* ]] || error 'Invalid color multiplier'

reset_work
commit_work

info "$MESSAGE"
