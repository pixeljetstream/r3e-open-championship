r3e-open-championship
=====================

Open Championship Statistics for [R3E](http://game.raceroom.com)

### About

This is a small tool that parses the raceresult file from R3E and generates a tiny database and a html report for a championship based on multiple single race events. It is not supported nor in anyway endorsed by the creators of R3E.

![sample output](https://github.com/pixeljetstream/r3e-open-championship/blob/master/doc/samplesm.png)

As you can see at this [full sample website](http://htmlpreview.github.io/?https://github.com/pixeljetstream/r3e-open-championship/blob/master/doc/sample.html) it generates for every race:

* Driver Standings
* Team Standings
* Vehicle Standings (if more than one vehicle type)
* Best Race Lap Times
* Best Qualification Times
* Race Results

### How it works

Run the ".exe" file, it should bring up a very simple program that you keep running while doing singleplayer races in R3E.

![ui](https://github.com/pixeljetstream/r3e-open-championship/blob/master/doc/ui.png)

* The program tracks edits to "My Documents/My Games/SimBin... raceresults.txt" which contains the results of the last completed race (no matter what kind of race it was).
* Based on the content of the file a unique "championship" is created (hash based on starter-field). That means if you choose always the same starter-field config (vehilce class and number of opponents) in your single player race, it shall treat it as a single championship
* For every completed race, the results are appended to the championship file (a simple text file storing the results for every race) and a HTML file is generated with the current standings, see image above

It is an "open" championship, as none of the settings are really frozen (AI...), you can keep going and mix tracks however you want, a pseudo championship based on your single player races. Simply delete the appropriate database lua file in the "results" directory to start fresh again.

### A few caveats

Simply do not run the app if you do races you don't want to track. If something is accidentally added somewhere you can always manually delete or edit the files and remove the last entry.
Since the tracknames are not stored in the result file (only track lengths), there needs to a mapping, which is currently incomplete.

### Third Party

The exe was created via wxLuaFreeze and upx and automatically executes the r3e-open-championship.lua file.

* [wxLua](http://wxlua.sourceforge.net/)
* [md5.lua](https://github.com/kikito/md5.lua)
* [upx](http://sourceforge.net/projects/upx/)