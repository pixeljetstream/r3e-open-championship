
-- html generation
usetrackdates    = true
usetrackicons    = true
onlytrackicons   = false
trackiconstyle   = "" -- if you want to have smaller icons use for example "max-width:50%;"
usevehicleicons    = true
onlyvehicleicons   = false

usepositionsort    = true -- use position logged in results if available, otherwise only use lap & racetime fields

driver_standings_position = true
driver_standings_vehicle = true
driver_standings_team = true
vehicle_standings = true
team_standings = true
maxbestlap  = 3
maxbestqual = 3
rulepoints  = {   -- applied based on race's "ruleset" entry
  default      = {25,18,15,12,10,8,6,4,2,1},
  fia1962_1990 = {9,6,4,3,2,1},
  fia1991_2002 = {10,6,4,3,2,1},
  fia2003_2009 = {10,8,6,5,4,3,2,1},
  fia_current  = {25,18,15,12,10,8,6,4,2,1},
  porsche_ccd      = {25,20,16,13,11,10,9,8,7,6,5,4,3,2,1},
  porsche_supercup = {25,20,17,14,12,10,9,8,7,6,5,4,3,2,1},
}

stylesheetfile = "_style.css"

-- json import
jsonDriverName = "FullName" -- alternatively use "Username"
-- xml import
xmlDriverName = "FullName"  -- alternatively use "Username"

-- general
outdir      = "results/"

-- processing races
-- applied when loading a result file and appending/creating season file
newdescr    = ""          -- name of the championship if created new
forcedkey   = ""          -- enforce a key
minracetime = 5           -- in minutes, if a race was shorter it doesn't contribute to stats
ruleset     = "default"   -- the race will use this rulepoints (defined above) during html point generation

-- UI tool 
checkrate   = 1           -- polling rate in minutes
-- default inputfile that is polled for changes
-- for now only USER_DOCUMENTS is a special variable
inputfile   = [[$USER_DOCUMENTS$\My Games\SimBin\RaceRoom Racing Experience\UserData\Log\Results\raceresults.txt]]

