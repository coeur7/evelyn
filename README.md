# evelyn
EVELYN (Essential Variety Effector Lateralizing Your Noncompliance) is a Battle Facility Randoms roll assistant.

Installation instructions (Mac OS X / Linux; Windows users are currently on their own, although there should be a way):
* download archive
* extract archive to folder
* open terminal in that folder
* enter command "chmod 744 ./evelyn.pl" (only before first-ever running) to set the executable flag on the script
* enter "./evelyn.pl" and check roll.txt
* edit roster.txt as you see fit, and have fun playing randoms

Troubleshooting:
* you may need to install perl (duh) and/or libc6 as dependencies before this runs
* Perl is case-sensitive, "Coeur" and "COEUR" and "coeur" and "cOEuR" are not interchangeable. Make sure to be consistent (until I might implement "user-friendly" normalization "under the hood", but it's not there yet).
* do not use line breaks in roster.txt to separate the lists of mons in a given box; put them all on the same line; the program stops reading candidates after the first line break it encounters there
* run "./evelyn.pl -?" for further usage information

Currently accepted roll methods:
* repto (roll with duplicates)
* coeur (roll w/o  duplicates)
* asterisk (mark mon entries in roster.txt with asterisks; rolls without any of these are discarded)
* asterisk-nodupl (as above, w/o duplicates)

If you want your method added, describe it to me and I might at least try to implement it. No guarantees, no refunds.

Rating System: 
* EVELYN now allows you to rate your flunkies. Set up your roster file (if you haven't already), then run "./evelyn.pl -g" to generate a new ratings file automatically, which will contain entries of the form "SET, AVERAGE GRADE, TIMES USED" (without commas; the latter two initialized to zero, of course).
* From here, you can run "./evelyn.pl -r SET GRADE" (replacing SET and GRADE with the appropriate string and number) to add a grade, which will be re-averaged with the current grade, and TIMES USED incremented by 1.
* "./evelyn.pl -r0 SET GRADE" will manually reset the SET's average grade to GRADE and TIMES USED to 1.
* If you need more support or functionality, feel free to ask me.

Planned features:
* Quick generation of pasteables from larger roster by selecting four sets
* Log rolls for an entire run
