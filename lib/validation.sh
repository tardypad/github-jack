# Inputs validation functions

validate_position()
{
  if ! date --date "$POSITION" &> /dev/null \
     && [ "$POSITION" != 'left' ] \
     && [ "$POSITION" != 'center' ] \
     && [ "$POSITION" != 'right' ]
  then
    error 'Invalid position date or identifier'
  fi
}

validate_github_username()
{
  if [ -n "$GITHUB_USERNAME" ] \
     && ! curl --silent "https://api.github.com/users/$GITHUB_USERNAME" \
          | grep --quiet '"type": "User"'
  then
    error 'Invalid Github username: non existing user profile'
  fi
}

validate_shade_multiplier()
{
  if ! [[ $SHADE_MULTIPLIER =~ ^[1-9][0-9]* ]]
  then
    error 'Invalid shade multiplier: non strictly positive integer'
  fi
}

validate_template()
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
