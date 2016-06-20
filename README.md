Github Jack
============

Generate work to be displayed on your Github's contributions board

![All work and](/assets/jack_1.png?raw=true "All work and")  
![no play makes](/assets/jack_2.png?raw=true "no play makes")  
![Jack a dull boy.](/assets/jack_3.png?raw=true "Jack a dull boy.")

Inspired by [Gitfiti](https://github.com/gelstudios/gitfiti) and other derivatives listed there.  
Written entirely in Bash.  
No dependency on external libraries, only use common commands.


Features
--------

- create work based on templates (see below), provided or user created
- define author name and email
- generate the work into the current repository or an external one
- define the work message
- adjust shades with a multiplier defined manually or calculated from the user Github profile
- define the template position relatively (left, center,...) or absolutely (start date)
- write the message into a repository file for each commit


Usage
-----

```
Usage: gh-jack [ARGUMENT]...

Generate the work to be displayed on Github's contributions board

OPTIONAL ARGUMENTS:
  -e, --email       VALUE     define author email
  -f. --force                 skip any confirmation question
  -g. --github      USERNAME  calculate multiplier from Github user profile
                              the value takes precedence over a shade argument
  -h, --help                  show this message only
  -k, --keep                  skip the reset of the work repository
  -m, --message     VALUE     define work message
  -n, --name        VALUE     define author name
  -p, --position    DATE/ID   define template position with a start date or
                              an identifier (see values below)
  -r, --repository  FOLDER    define work repository
                              gets created if doesn't exists, reset otherwise
  -s, --shade       INT       multiply work to adjust color shades
  -t, --template    FILE/ID   define work template with a file or
                              an identifier (see values below)
  -v, --verbose               enable verbose mode
  -w, --write       FILENAME  write the message into a repository file
                              for each single work

PROVIDED TEMPLATES IDENTIFIERS:
  Use the basename of all files within the templates folder
  templates/

TEMPLATE POSITIONS IDENTIFIERS:
  left      work starts on the left side of the current board
  center    work is centered on the current board
  right     work ends on the right side of the current board
  last      work starts after the last work in the repository (left if none)

DEFAULT VALUES:
  repository        current folder
  template          jack
  position          left
  author name       user global git name (Jack if not defined)
  author email      user global git email (jack@work.com if not defined)
  message           All work and no play makes Jack a dull boy.
```


Templates
---------

Templates follow almost the same structure as the ones used by [github-board](https://github.com/bayandin/github-board):
- the file should have 7 lines (just like the board, one line per day of the week)
- it should only contain indexes from 0 to 4 (correspond to the different board's green shades)
- each line should have the same length

Some templates are provided, see the [templates](templates/) folder.


Licenses
--------

Source code is released under the MIT license (See the [LICENSE](LICENSE) file)

Application specific graphics are released under Creative Commons CC BY


Enjoy!
