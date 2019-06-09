# evelyn
EVELYN (Essential Variety Effector Lateralizing Your Noncompliance) is a Battle Facility Randoms roll assistant.

Installation instructions (Mac OS X / Linux):
* download archive
* extract archive to folder
* open terminal in that folder
* enter command "chmod 744 ./evelyn.pl" (only before first-ever running) to set the executable flag on the script
* enter "./evelyn.pl" and check roll.txt
* edit roster.txt as you see fit, and have fun playing randoms

Troubleshooting:
* you may need to install perl (duh) and/or libc6 as dependencies before this runs
* do not use line breaks in roster.txt to separate the lists of mons in a given box; put them all on the same line; the program stops reading candidates after the first line break it encounters there

Currently accepted roll methods:
* repto (roll with duplicates)
* coeur (roll w/o  duplicates)
* asterisk (mark mon entries in roster.txt with asterisks; rolls without any of these are discarded; warning: every box must contain at least one asterisked entry in this case, or the program will re-roll in an endless loop (can be fixed by capping reroll attempts, and will soon be))
* asterisk-nodupl (as above, w/o duplicates)

If you want yours added, describe it to me and I might at least try to implement it. No guarantees, no refunds.

Planned features:
* Quick generation of pasteables from larger roster by selecting four sets
* Log rolls for an entire run
* maybe a grading system, "rate your mons"
