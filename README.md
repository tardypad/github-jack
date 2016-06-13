Github Jack
============

Generate work to be displayed on your Github's contributions board

_All work and no play makes Jack a dull boy._

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

Launch the command with the _--help_ option to see the full usage.


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
