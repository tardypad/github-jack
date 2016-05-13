#!/bin/bash

REPO="$1"
MESSAGE='All work and no play makes Jack a dull boy.'
AUTHOR='Jack <jack@work.com>'


function commit_year_work()
{
  local count="$1"
  local start_day="$(date --date="-52 weeks next sunday" +%Y-%m-%d)"

  # 357 days is 51 weeks
  for (( c = 0; c < 357; c++ ))
  do
    commit_day_work "$(date --date="$start_day +$c day" +%Y-%m-%d)" "$count"
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

commit_year_work 3
