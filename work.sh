#!/bin/bash

REPO="$1"
MESSAGE='All work and no play makes Jack a dull boy.'
AUTHOR='Jack <jack@work.com>'

function random_time()
{
  local hours=$(( $RANDOM % 24 ))
  local minutes=$(( $RANDOM % 60 ))
  local seconds=$(( $RANDOM % 60 ))
  echo $hours:$minutes:$seconds
}

function commit_day_work()
{
  local day="$1"
  local count="$2"

  for ((i = 1; i <= $count; i++))
  do
    commit_a_work "$day" "$(random_time)"
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

commit_day_work 2016-05-01 3
