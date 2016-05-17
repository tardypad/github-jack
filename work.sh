#!/bin/bash

MESSAGE='All work and no play makes Jack a dull boy.'
AUTHOR='Jack <jack@work.com>'
SHADE_MULTIPLIER=2

usage()
{
  cat << EOF
Usage: `basename $0` [ARGUMENT]...

Generate the work of Jack to be displayed on Github's contributions board

REQUIRED ARGUMENTS:
   --repo, -r       FOLDER  repo on which Jack is working
   --template, -t   FILE    Jack's work template

OPTIONAL ARGUMENTS:
   --help, -h               show this message only
   --verbose, -v            verbose mode
EOF
  exit
}

error()
{
  [ -z "$1" ] || echo "$1"
  echo "Try `basename $0` -h for more information"
  exit 1
}

function info()
{
  "$VERBOSE" && [ -n "$1" ] && echo "$1"
}

function reset_work()
{
  while true; do
    read -p "Are you sure you want to reset the previous work of that repo? "
    case $REPLY in
        yes|y) break;;
        no|n) exit;;
        *) echo "Please answer yes or no.";;
    esac
  done

  rm -rf "$REPO/.git"
  git --git-dir="$REPO/.git" --work-tree="$REPO" init --quiet
}

function day_count()
{
  local day_number="$1"
  local row=$(( $day_number % 7 + 1))
  local col=$(( $day_number / 7 + 1))
  local index=$(head "$TEMPLATE" -n $row | tail -n1 | head -c $col | tail -c1)

  echo $(( $index * $SHADE_MULTIPLIER))
}

function commit_year_work()
{
  local date_format='%Y-%m-%d'
  local start_date="$(date --date="-52 weeks next sunday" +$date_format)"
  local date count

  # 357 days is 51 weeks
  for (( c = 0; c < 357; c++ ))
  do
    date=$(date --date="$start_date +$c day" +$date_format)
    count=$(day_count $c)
    commit_day_work "$date" "$count"
  done
}

function random_time()
{
  local hours=$(( $RANDOM % 24 ))
  local minutes=$(( $RANDOM % 60 ))
  local seconds=$(( $RANDOM % 60 ))

  echo $hours:$minutes:$seconds
}

function commit_day_work()
{
  local date="$1"
  local count="$2"
  local time

  for ((i = 1; i <= $count; i++))
  do
    time=$(random_time)
    commit_a_work "$date" "$time"
  done
}

function commit_a_work()
{
  local date="$1"
  local time="$2"

  git \
  --git-dir="$REPO/.git" \
  --work-tree="$REPO" \
  commit \
  --allow-empty \
  --message "$MESSAGE" \
  --author "$AUTHOR" \
  --date "$date $time" \
  --quiet
}


REPO=
TEMPLATE=
VERBOSE=false

while [[ "$#" -gt 0 ]]
do
  case "$1" in
  --help|-h)
        usage
        ;;
  --repo|-r)
        [ -n "$2" ] || error 'Missing repo path'
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
        error 'Unrecognized argument'
        ;;
  esac
done

[ -n "$REPO" ] || error 'Missing repo argument'
[ -n "$TEMPLATE" ] || error 'Missing template argument'

[ -d "$REPO" ] || error 'Invalid repo path'
[ -f "$TEMPLATE" ] || error 'Invalid template path'

reset_work

info 'Committing work...'
commit_year_work
info "$MESSAGE"
