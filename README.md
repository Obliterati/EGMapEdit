# EGMapEdit v0.3

EGMapEdit is a basic Ruby script for merging conflicting map scenarios for the game 'Europa Universalis IV'.  It is a tool for developing the Europa Gooniversalis mod.

## How to use

EGM works by appending 'history' entries to the end of province files.  These entries are generated based on information drawn from the set of province files designated in history/provinces (in this case, the EUIV vanilla 1444 scenario).  These are then appended to the parent history files, in history_output/provinces (history_new/provinces is a backup set of these).

Running through the console (' ruby main.rb ') will conclude the script.

## Update history

- 0.1: initial release
- 0.2: cleared up UTF-8 encoding issues, refactored code
- 0.3: EGME now handles pre-1444 history entries, multiple cores in vanilla start

## Current issues

- Avoid repeated runs of the script as currently history entries will be repeated.

