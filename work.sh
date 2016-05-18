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
   --force, -f              don't ask for any confirmation
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

info()
{
  "$VERBOSE" && [ -n "$1" ] && echo "$1"
}

reset_work()
{
  if ! $FORCE
  then
    while true; do
      read -p "Are you sure you want to reset the previous work of that repo? "
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
  local row=$(( $day_number % 7 + 1))
  local col=$(( $day_number / 7 + 1))
  local index=$(head "$TEMPLATE" -n $row | tail -n1 | head -c $col | tail -c1)

  echo $(( $index * $SHADE_MULTIPLIER))
}

commit_work()
{
  local date_format='%Y-%m-%d'
  local start_date="$(date --date="-52 weeks next sunday" +$date_format)"
  local days=$(( $(wc --max-line-length < "$TEMPLATE") * 7 ))
  local date count

  for (( c = 0; c < "$days"; c++ ))
  do
    date=$(date --date="$start_date +$c day" +$date_format)
    count=$(day_count $c)
    commit_day_work "$date" "$count"
  done
}

random_time()
{
  local hours=$(printf %02d $(( $RANDOM % 24 )))
  local minutes=$(printf %02d $(( $RANDOM % 60 )))
  local seconds=$(printf %02d $(( $RANDOM % 60 )))

  echo $hours:$minutes:$seconds
}

commit_day_work()
{
  local date="$1"
  local count="$2"
  local times

  for ((i = 1; i <= $count; i++))
  do
    times="$times $(random_time)"
  done

  for time in $(echo "$times" | tr " " "\n" | sort)
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
  --author "$AUTHOR" \
  --date "$date $time" \
  --quiet
}


REPO=
TEMPLATE=
VERBOSE=false
FORCE=false

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
  --force|-f)
        FORCE=true
        shift
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
commit_work
info "$MESSAGE"
