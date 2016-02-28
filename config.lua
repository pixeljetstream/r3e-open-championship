
-- html generation
useicons    = true
onlyicons   = false
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
}

stylesheetfile = "_style.css"

-- json import
jsonDriverName = "FullName" -- alternatively use "Username"
-- xml
xmlDriverName = "FullName" -- alternatively use "Username"

-- general
outdir      = "results/"

-- processing races
-- applied when loading a result file and appending/creating season file
newdescr = ""   -- name of the championship if created new
forcedkey = ""  -- enforce a key
minracetime = 5           -- in minutes, if a race was shorter it doesn't contribute to stats
ruleset     = "default"   -- the race will use this rulepoints (defined above) during html point generation

-- UI tool polling rate
checkrate   = 1           -- in minutes


