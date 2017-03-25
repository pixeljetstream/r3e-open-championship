r3e-open-championship
=====================

Open Championship Statistics for [R3E](http://game.raceroom.com)
© 2015 by Christoph Kubisch

### About

This is a small tool that parses the raceresult file from R3E and generates a tiny database and a html report for a championship based on multiple single race events (single- or multiplayer). It is not supported nor in anyway endorsed by the creators of R3E.

The tool supports either the raceresults.txt generated by R3E or json files by the server api.

![sample output](https://github.com/pixeljetstream/r3e-open-championship/blob/master/doc/samplesm.png)

As you can see at this [full sample website](http://htmlpreview.github.io/?https://github.com/pixeljetstream/r3e-open-championship/blob/master/doc/sample.html) it generates for every race:

* Driver Standings
* Team Standings (if more than one team)
* Vehicle Standings (if more than one vehicle type)
* Best Race Lap Times
* Best Qualification Times
* Detailed Race Results

### How it works 

#### Local Results

Run the ".exe" file, it should bring up a very simple program that you keep running while doing singleplayer races in R3E.

![ui](https://github.com/pixeljetstream/r3e-open-championship/blob/master/doc/ui.png)

* The program tracks edits to "My Documents/My Games/SimBin... raceresults.txt" which contains the results of the last completed race (no matter what kind of race it was).
* Based on the content of the file a unique "championship" is created (hash based on starter-field). That means if you choose always the same starter-field config (vehicle class and number of opponents) in your single player race, it shall treat it as a single championship
* For every completed race, the results are appended to the championship file (a simple text file storing the results for every race) and a HTML file is generated with the current standings, see image above

It is an "open" championship, as none of the settings are really frozen (AI...), you can keep going and mix tracks however you want, a pseudo championship based on your single player races. Simply delete the appropriate database lua file in the "results" directory to start fresh again.

* Edit the override database key to collect multiplayer races into a custom season database, just enter a filename compatible text here. There
is no compatibility check when a race is appended, so keep organized :) 

#### Server Results

* For Multiplayer races it is highly recommended to pass the server generated result files (json or xml) and use the commandline mode, as it gives more control than the UI.

If you do not want to setup the commandline yourself, simply use the `myleague.bat`:

* Pass the json or xml file that the server generates onto it, for example drag drop the result file (json or xml) onto the batch file.
* This will append the results to a database called `myleague` and the result html is generated and then shown in your default browser. 
* By renaming the batch file, for example `GTR3 Summer Season.bat` you will also rename the database being used. So simply copy the batch file, rename it to the league it shall represent, and pass the result files onto it.
* Every time you pass a result file onto the batch, it will get appended to the database of that filename, so races only need to be added once.

By renaming the batch file to something else, you can change

### Commandline mode

In commandline mode, the ui is not started and core functionality is exposed.

* `-addrace dataBaseFile raceresultsFile`
  Appends the race to the provided database file (no error checking whether it 
  contains drivers from the race or not).

* `-makehtml dataBaseFile htmlFile`
  Generates html results for the provided database file
  
* `-config "lua string"`
  Applies the lua string, overwriting the current settings. For example use `-config "ruleset='fia1962_1990'"` to apply old rulepoints prior adding a race to your custom season.
  
* `-configfile luaFile`
  Applies the config from this file, overwriting the current settings. By default `config.lua` is loaded.
  
For example:

One should prefer using luajit as startup, as it will print error outputs to console.

The following can be used as a batch file for managing multiplayer seasons.

```
luajit.exe r3e-open-championship.lua -config "ruleset='%3'" -addrace ./results/%1.lua %2 -makehtml ./results/%1.lua ./results/%1.html
```

The batch file expects three arguments, season file, result file (json, xml or txt) and ruleset for points in that race. It will add the results to the season and update the appropriate html file in the "results" subdirectory.

`mybatch.bat mygroup5 lastrace.json fia1962_1990`


### Configuration

To modify the HTML styling it's best to edit the `_style.css` file in '/results' or change the reference to your own file below. For league races it's recommended to disable the '#player' highlight color.

In the `config.lua` there is a few settings you can play with that affect the html generation:

* useicons: for track and car
* onlyicons: don't print text if icon exists
* driver_standings_vehicle: add vehicle column in driver standings
* driver_standings_team: add team column in driver standings
* vehicle_standings: print standings based on vehicle (automatically omitted if only one vehicle exists)
* team_standings: print standings based on teams (automatically omitted if only one team exists)
* stylesheetfile: change the default filename
* rulepoints: the table that is used to assign points to the drivers. The default entry must be provided, all others are optional, you can define your own analog to the ones that already exist. Just make sure the "ruleset" of a race within the easons matches an entry of the rulepoints table.

### History

Time-line for some distinct features
* 28. 2.2016 - xml result support, use time difference for best-lap and qualifying
*  6. 2.2016 - bugfix results when drivers are laps behind, remove minracetime check for json
* 17. 1.2016 - config file externalized, new config commandline, point handling per race
* 10. 1.2016 - json result bugfix racefinish state, config to disable team/vehicle standings
*  7.11.2015 - json result support to improve multiplayer usage
* 20. 6.2015 - multiplayer-friendly commandline options, and database override
* 14. 6.2015 - modified css styles a bit, allow position-based color-coding
* 13. 6.2015 - added icons for tracks and vehicles
* 16. 1.2015 - added optional description string for a championship
* 10. 1.2015 - added qual times, race results and driver standings with positions
*  9. 1.2015 - added team and car standings, as well as best laptimes
*  4. 1.2015 - first release, track multiple championship, html report for driver standings

### A few caveats

Simply do not run the app if you do races you don't want to track. If something is accidentally added somewhere you can always manually delete or edit the files and remove the last entry.
Since the tracknames are not stored in the result file (only track lengths), there needs to a mapping, which may be incomplete. Please send in tracklength-name pairings if you recgonize some are missing (then only the tracklength is printed).

### Third Party

Special thanks to **tAz-07** and **heppsan** from steam community on feedback and providing most of the track mappings. **ttfredo** and **Nicklas Petersson** from sector3studios forum for bug reproducers.

The icons are directly linked to the official game website.

The exe and wx dll were compressed via upx, the exe automatically executes the r3e-open-championship.lua file.

* [wxLua](http://wxlua.sourceforge.net/)
* [md5.lua](https://github.com/kikito/md5.lua)
* [upx](http://sourceforge.net/projects/upx/)
* [cjson](http://www.kyne.com.au/~mark/software/lua-cjson.php)
* [luajit](http://luajit.org/)
