--[[
The MIT License (MIT)

Copyright (c) 2015 Christoph Kubisch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

local REGENONLY   = false

local useicons    = true
local onlyicons   = false
local maxmergedrivers = 5       -- number of drivers that can be different to first race of season 
                                -- meant for merging multiplayer races where drivers may be missing
local outdir      = "results/"
local minracetime = 5           -- in minutes, if a race was shorter it doesn't contribute to stats
local checkrate   = 1           -- in minutes
local rulepoints  = {25,18,15,12,10,8,6,4,2,1}
local maxbestlap  = 3
local maxbestqual = 3
local tracknamelength = 12      -- to keep track columns tight, names are cut off, alternatively set 
                                -- a high value here, and make use of <br> below
local tracknames  =             -- maps tracklength to a name, let's hope those are unique
{
--tracklength={shortname,           official asset name}
["6191.8174"]={"Bathurst",          "Bathurst Circuit - Mount Panorama"},
["1939.5625"]={"BrandsHatchIndy",   "Brands Hatch - Indy"},
["4275.6143"]={"Zandvoort",         "Circuit Park Zandvoort - Grand Prix"},
["2887.9546"]={"ZandvoortNational", "Circuit Park Zandvoort - National"},
["2510.1907"]={"ZandvoortClub",     "Circuit Park Zandvoort - Club"},
["3992.8533"]={"Zolder",            "Circuit Zolder - Grand Prix"},
["3407.2373"]={"LausitzAuto",       "EuroSpeedway Lausitz - Automobilsport"},
["3434.4822"]={"Lausitz",           "EuroSpeedway Lausitz - Grand Prix"},
["4556.0303"]={"Hockenheim",        "Hockenheimring - Grand Prix"},
["3684.3110"]={"HockenheimNational","Hockenheimring - National"},
["2585.4141"]={"HockenheimShort",   "Hockenheimring - Short"},
["4359.0034"]={"Hungaroring",       "Hungaroring - Grand Prix"},
["4069.3682"]={"Indianapolis",      "Indianapolis - Grand Prix"},
["4193.3374"]={"IndianapolisMoto",  "Indianapolis - Moto"},
["3585.5344"]={"LagunaSeca",        "Mazda Laguna Seca - Grand Prix"},
["3809.4441"]={"MidOhioChicane",    "Mid Ohio - Chicane"},
["3823.2102"]={"MidOhioFull",       "Mid Ohio - Full"},
["2880.1135"]={"MidOhioShort",      "Mid Ohio - Short"},
["5783.3423"]={"Monza",             "Monza Circuit - Grand Prix"},
["2416.6360"]={"MonzaJR",           "Monza Circuit - Junior"},
["3898.8025"]={"Moscow",            "Moscow Raceway - FIM"},
["2512.9583"]={"MoscowSprint",      "Moscow Raceway - Sprint"},
["3924.9500"]={"MoscowFull",        "Moscow Raceway - Full"},
["3663.8022"]={"Oschersleben",      "Motorsport Arena Oschersleben - Grand Prix"},
["3663.8020"]={"Oschersleben",      "Motorsport Arena Oschersleben - Grand Prix"},
["2192.3979"]={"Norisring",         "Norisring - Grand Prix"},
["3609.2053"]={"NürburgringSprint", "Nürburgring - Sprint"},
["5123.2192"]={"Nürburgring",       "Nürburgring - Grand Prix"},
["3597.9592"]={"NürburgringShort",  "Nürburgring - Short"},
["3885.0781"]={"PortimaoClub",      "Portimao Circuit - Club"},
["3880.8940"]={"PortimaoChicane",   "Portimao Circuit - Club Chicane"},
["4623.4604"]={"Portimao",          "Portimao Circuit - Grand Prix"},
["4148.3921"]={"PortimaoNational",  "Portimao Circuit - National"},
["3797.2512"]={"Raceroom",          "RaceRoom Raceway - Grand Prix"},
["3356.2083"]={"RaceroomBridge",    "RaceRoom Raceway - Bridge"},
["3840.5679"]={"RaceroomClassic",   "RaceRoom Raceway - Classic"},
["3628.0947"]={"RaceroomClassicSprint","RaceRoom Raceway - Classic Sprint"},
["3604.7246"]={"RaceroomNational",  "RaceRoom Raceway - National"},
["3208.6384"]={"SonomaSprint",      "Sonoma Raceway - Sprint"},
["4101.1851"]={"SonomaWTCC",        "Sonoma Raceway - WTCC"},
["3706.5615"]={"SonomaIRL",         "Sonoma Raceway - IRL"},
["4046.4993"]={"SonomaLong",        "Sonoma Raceway - Long"},
["4305.5688"]={"RedBullRing",       "Red Bull Ring Spielberg - Grand Prix"},
["3649.3059"]={"Sachsenring",       "Sachsenring - Grand Prix"},
--["3649.3323"]={"Salzburgring",      "Salzburgring - Grand Prix"},
--["12234.5293"]={"Shanghai",         "Shanghai Circuit - East Course"},
--["15801.7275"]={"ShanghaiWTCC",     "Shanghai Circuit - Intermediate (WTCC)"},
--["13464.6255"]={"ShanghaiWest",     "Shanghai Circuit - West Long"},
["5915.0332"]={"Slovakia",          "Slovakia Ring - Grand Prix"},
["2234.5293"]={"SuzukaEast",        "Suzuka Circuit - East Course"},
["5801.7275"]={"Suzuka",            "Suzuka Circuit - Grand Prix"},
["3464.6255"]={"SuzukaWest",        "Suzuka Circuit - West Course"},
}
local descrdummy = "optionally added to a newly created season file"
local newdescr = ""

local function ParseTime(str)
  if (not str) then return end
  local h,m,s = str:match("(%d+):(%d+):([0-9%.]+)")
  if (h and m and s) then return h*60*60 + m*60 + s end
  local m,s = str:match("(%d+):([0-9%.]+)")
  if (m and s) then return m*60 + s end
end

local function DiffTime(stra, strb)
  local ta = ParseTime(stra)
  local tb = ParseTime(strb)
  if (not (ta and tb)) then return end
  local diff = tb-ta
  local absdiff = math.abs(diff)
  
  local h = math.floor(absdiff/3600)
  absdiff = absdiff - h * 3600
  local m = math.floor(absdiff/60)
  absdiff = absdiff - m * 60
  local s = absdiff
  
  local sign = (diff >= 0 and "+" or "-")
  
  if (h > 0) then
    return sign..string.format(" %2d:%2d:%.3f", h,m,s)
  elseif (m > 0) then
    return sign.. string.format(" %2d:%.3f", m, s)
  else
    return sign.. string.format(" %.3f", s)
  end
  
end

local printlog = print

local function parseAssetIcons(filename)
  local f = io.open(filename,"rt")
  local str = f:read("*a")
  f:close()

  local icons = {}
  for url,key in str:gmatch('image="(.-)">%s*(.-)<') do
    icons[key] = url
  end
  
  for i,v in pairs(tracknames) do
    assert(icons[v[2]], v[2].." icon not found")
  end
  return icons
end
local function makeIcon(url,name,style)
  return '<img src="'..url..'" alt="'..name..'" title="'..name..'" style="vertical-align:middle;'..(style or "")..'" >'
end

local icons = parseAssetIcons("assets.txt")

local function GenerateStatsHTML(championship,standings)
  assert(championship and standings)
  local info = standings[1].slots
  assert(info)
  local numdrivers = #info
  local numraces   = #standings
  local numbestlap = math.min(maxbestlap,numdrivers)
  local numbestqual= math.min(maxbestqual,numdrivers)
  
  -- create team and car slots and lookup tables
  local lkcars = {}
  local lkteam = {}
  local carslots = {}
  local teamslots = {}
  
  local function makegen(lk,tab)
    local function append(key)
      table.insert(tab,{Name=key,Entries=0})
      return #tab
    end
    return function(key)
      local idx = lk[key] or append(key)
      lk[key] = idx
      tab[idx].Entries = tab[idx].Entries + 1
    end
  end
  
  local fncars = makegen(lkcars,carslots)
  local fnteam = makegen(lkteam,teamslots)
  
  for i=1,numdrivers do
    fncars(info[i].Vehicle)
    fnteam(info[i].Team)
  end
  
  local numteams = #teamslots
  local numcars  = #carslots
    
  -- driver, team and car points
  local raceresults     = {}
  local racepositions   = {}
  local racepoints      = {}
  local teamracepoints  = {}
  local carracepoints   = {}
  local lapracetimes    = {}
  local qualracetimes   = {}
  
  -- create point table per race per slot
  for r,race in ipairs(standings) do 
    local function getSortedTimes(field)
      local times = {}
      local sorted = {}
      for i=1,numdrivers do
        sorted[i] = i
        times[i] = ParseTime(race.slots[i][field] or "")
        -- may be nil if DNF 
      end
      
      table.sort(sorted,
        function(a,b) 
          return (times[a] or 1000000000) < (times[b] or 1000000000)
        end)
      
      return sorted,times
    end
    
    -- get sorted and times and generate points
    local sorted,times = getSortedTimes("RaceTime")
    local points = {}
    local results = {}
    for i=1,math.min(numdrivers,#rulepoints) do
      -- only set points if time is valid
      points[sorted[i]] = times[sorted[i]] and rulepoints[i]
    end
    for i=1,numdrivers do
      results[i] = race.slots[sorted[i]]
      results[i].Player = sorted[i] == 1
      
      if (not points[i]) then
        -- only set non nil if had a valid time
        points[i] = times[i] and 0 
      end
    end
    raceresults[r]    = results
    racepoints[r]     = points
    
    local positions = {}
    for i=1,numdrivers do
      -- only set if time was valid
      positions[sorted[i]] = times[sorted[i]] and i
    end
    racepositions[r]  = positions
    
    -- distribute points on team and car
    local carspoints = {}
    local teampoints = {}
    for i=1,numdrivers do
      local tslot = lkteam[info[i].Team]
      local cslot = lkcars[info[i].Vehicle]
      carspoints[cslot] = (carspoints[cslot] or 0) + (points[i] or 0)
      teampoints[tslot] = (teampoints[tslot] or 0) + (points[i] or 0)
    end
  
    for i=1,numteams do
      teampoints[i]      = teampoints[i] or 0
    end
    for i=1,numcars do
      carspoints[i]      = carspoints[i] or 0
    end
    carracepoints[r]  = carspoints
    teamracepoints[r] = teampoints
    
    -- best lap
    local sorted,times = getSortedTimes("BestLap")
    local laptimes = {}
    for i=1,numbestlap do
      local slot = sorted[i]
      laptimes[i] = times[slot] and race.slots[slot]
    end
    lapracetimes[r] = laptimes
    
    -- best qual
    local sorted,times = getSortedTimes("QualTime")
    local qualtimes = {}
    for i=1,numbestqual do
      local slot = sorted[i]
      qualtimes[i] = times[slot] and race.slots[slot]
    end
    qualracetimes[r] = qualtimes
  end
  
  local function getaccumpoints(allpoints,num)
    local out = {}
    for r,race in ipairs(allpoints) do
      for i=1,num do
        local point = race[i]
        out[i] = (out[i] or 0) + (point or 0)
      end
    end
    return out
  end

  -- sorted slots by final points
  -- FIXME would have to count higher positions if equal
  local function getsortedslots(points)
    local slots = {}
    for i=1,#points do slots[i]=i end
    table.sort(slots,
      function(a,b) 
        return points[a] > points[b]
      end)
    return slots
  end
  
  printlog("generate HTML",championship)
  
  local f = io.open(outdir..championship..".html","wt")
 
  local descr = standings.description ~= "" and standings.description
  descr = descr and "<h3>"..descr.."</h3>\n" or ""
  
  
  f:write([[
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <meta charset="utf-8"/>
    <link href='http://fonts.googleapis.com/css?family=Open+Sans:400,700' rel='stylesheet' type='text/css'>
    <link rel="stylesheet" href="_style.css">
    </head>
    <body>
    <span class="minor">Icons are linked directly from the game's official website</span>
    <h1>R3E Championship Standings</h1>
    ]]..descr..[[
    <table>
    <caption>Driver Standings</caption>
    <tr>
    <th>Pos</th>
    <th>Driver</th>
    <th>Vehicle</th>
    <th>Team</th>
    <th>Points</th>
  ]])
  
  local function addHeaderTracks(attr)
    -- complete header for all tracks
    -- <th><div class="track">blah<br>2015/01/04<br>10:21:50</div></th>
    for r=1,numraces do
      local track = tostring(standings[r].tracklength)
      local tinfo = tracknames[track]
      if (tinfo) then
        local icon  = icons[tinfo[2]]
        icon  = useicons and makeIcon(icon,tinfo[2]) or ""
        track = onlyicons and icon or icon.."<br>"..tinfo[1]:sub(1,tracknamelength)
      end
      local time   = standings[r].timestring:gsub("(%s)","<br>")
      
      f:write([[
        <th id="track" ]]..(attr or "").." >"..track.."<br>"..time..[[</th>
      ]])
    end
    f:write([[
      </tr>
    ]])
  end
  addHeaderTracks("colspan=2")

  -- iterate sorted drivers
  local accumpoints = getaccumpoints(racepoints, numdrivers)
  local sortedslots = getsortedslots(accumpoints)
  for pos,i in ipairs(sortedslots) do
    local vehicle = info[i].Vehicle
    local icon = icons[vehicle]
    if (icon and useicons) then
      icon = makeIcon(icon,vehicle)
      vehicle = onlyicons and icon or icon..'<span class="minor">'..vehicle..'</span>'
    end
    
    f:write([[
      <tr]]..(pos%2 == 0 and ' class="even"' or "")..(i==1 and ' id="player"' or "")..[[>
      <td>]]..pos..[[</td>
      <td>]]..info[i].Driver..[[</td>
      <td>]]..vehicle..[[</td>
      <td>]]..info[i].Team..[[</td>
      <td class="points">]]..(accumpoints[i] == 0 and "-" or accumpoints[i])..[[</td>
    ]])
    for r=1,numraces do
      local str = racepoints[r][i]
      
      f:write([[
          <span class="points">]])
      if (not str) then
        f:write([[<td colspan=2>DNF</td>]])
      else
        str = (str == 0 and "-" or str)
        local rpos = racepositions[r][i]
        f:write([[<td class="pointcolumn">]]..str..[[</td><td class="poscolumn pos]]..rpos..[[">]]..rpos..[[.</td>]])
      end
      f:write([[</span>
          ]])
    end
    f:write([[
      </tr>
    ]])
  end

  -- team standings
  f:write([[
    </table>
    <br><br>
    <table>
    <caption>Team Standings</caption>
    <tr>
    <th>Pos</th>
    <th>Team</th>
    <th>Entries</th>
    <th>Points</th>
  ]])
  addHeaderTracks()
  
  -- iterate sorted teams
  local accumpoints = getaccumpoints(teamracepoints, numteams)
  local sortedslots = getsortedslots(accumpoints)
  for pos,i in ipairs(sortedslots) do
    f:write([[
      <tr]]..(pos%2 == 0 and ' class="even"' or "")..(i==1 and ' id="player"' or "")..[[>
      <td>]]..pos..[[</td>
      <td>]]..teamslots[i].Name..[[</td>
      <td>]]..teamslots[i].Entries..[[</td>
      <td class="points">]]..(accumpoints[i] == 0 and "-" or accumpoints[i])..[[</td>
    ]])
    for r=1,numraces do
      local str = teamracepoints[r][i]
      str = str == 0 and "-" or str or "DNF"
      f:write([[
        <td class="points">]]..str..[[</td>
      ]])
    end
    f:write([[
      </tr>
    ]])
  end
  
  
  
if (numcars > 1) then
  
  -- car standings
  f:write([[
    </table>
    <br><br>
    <table>
    <caption>Vehicle Standings</caption>
    <tr>
    <th>Pos</th>
    <th>Vehicle</th>
    <th>Entries</th>
    <th>Points</th>
  ]])
  addHeaderTracks()
  
  -- iterate sorted cars
  local accumpoints = getaccumpoints(carracepoints, numcars)
  local sortedslots = getsortedslots(accumpoints)
  for pos,i in ipairs(sortedslots) do
    local carname = carslots[i].Name
    local icon = icons[carname]
    if (icon and useicons) then
      icon = makeIcon(icon,carname)
      carname = icon..carname
    end
    
    f:write([[
      <tr]]..(pos%2 == 0 and ' class="even"' or "")..(i==1 and ' id="player"' or "")..[[>
      <td>]]..pos..[[</td>
      <td>]]..carname..[[</td>
      <td>]]..carslots[i].Entries..[[</td>
      <td class="points">]]..(accumpoints[i] == 0 and "-" or accumpoints[i])..[[</td>
    ]])
    for r=1,numraces do
      local str = carracepoints[r][i]
      str = str == 0 and "-" or str or "DNF"
      f:write([[
        <td class="points">]]..str..[[</td>
      ]])
    end
    f:write([[
      </tr>
    ]])
  end
end

  -- bestlaps
  f:write([[
    </table>
    <br><br>
    <table>
    <caption>Best Race Lap Times</caption>
    <tr>
    <th>Pos</th>
  ]])
  addHeaderTracks()
  for pos=1,numbestlap do
    f:write([[
      <tr]]..(pos%2 == 0 and ' class="even"' or "")..[[>
      <td>]]..pos..[[</td>
    ]])
    for r=1,numraces do
      local tab = lapracetimes[r][pos]
      local vehicle = tab.Vehicle
      local icon = icons[vehicle]
      if (icon and useicons) then
        icon = makeIcon(icon,vehicle)
        vehicle = onlyicons and icon or icon.."<br>"..vehicle
      end
      
      local driver  = tab and tab.Driver or ""
      local vehicle = tab and '<br><span class="minor">'..vehicle.."</span>" or ""
      local time    = tab and '<br>'..tab.BestLap or ""
      
      f:write([[
        <td]]..(tab and tab.Player and ' id="player"' or "")..[[>]]..driver..vehicle..time..[[</td>
      ]])
    end
    f:write([[
      </tr>
    ]])
  end
  
  -- bestqual
  f:write([[
    </table>
    <br><br>
    <table>
    <caption>Best Qualification Times</caption>
    <tr>
    <th>Pos</th>
  ]])
  addHeaderTracks()
  for pos=1,numbestqual do
    f:write([[
      <tr]]..(pos%2 == 0 and ' class="even"' or "")..[[>
      <td>]]..pos..[[</td>
    ]])
    for r=1,numraces do
      local tab = qualracetimes[r][pos]
      local str = ""
      if (tab) then
        local vehicle = tab.Vehicle
        local icon = icons[vehicle]
        if (icon and useicons) then
          icon = makeIcon(icon,vehicle)
          vehicle = onlyicons and icon or icon.."<br>"..vehicle
        end
        local driver  = tab.Driver or ""
        local vehicle = '<br><span class="minor">'..vehicle.."</span>" or ""
        local time    = '<br>'..tab.QualTime or ""
        str = driver..vehicle..time
      end
      
      f:write([[
        <td]]..(tab and tab.Player and ' id="player"' or "")..[[>]]..str..[[</td>
      ]])
    end
    f:write([[
      </tr>
    ]])
  end
  
  -- results
  f:write([[
    </table>
    <br><br>
    <table>
    <caption>Race Results</caption>
    <tr>
    <th>Pos</th>
  ]])
  addHeaderTracks()
  for pos=1,numdrivers do
    f:write([[
      <tr]]..(pos%2 == 0 and ' class="even"' or "")..[[>
      <td>]]..pos..[[</td>
    ]])
    for r=1,numraces do
      local tab  = raceresults[r][pos]
      local time = '<br>'..tab.RaceTime
      local gap  = ""
      
      if (pos > 1) then
        -- to winner
        time = DiffTime( raceresults[r][1].RaceTime,      tab.RaceTime )
        time = time and '<br>'..time or ""
        -- to previous driver
        gap  = DiffTime( raceresults[r][pos-1].RaceTime,  tab.RaceTime )
        gap  = gap  and '<br><span class="minor">'..gap..'</span>' or ""
      end
      
      local vehicle = tab.Vehicle
      local icon = icons[vehicle]
      if (icon and useicons and onlyicons) then
        icon = makeIcon(icon,vehicle,"opacity:0.6;height:1.7em;")
        vehicle = icon
      else
        vehicle = '<span class="minor">'..tab.Vehicle..'</span>'
      end
    
      local driver  = tab.Driver
      local vehicle = '<br>'..vehicle
      
      f:write([[
        <td]]..(tab and tab.Player and ' id="player"' or "")..[[>]]..driver..vehicle..time..gap..[[</td>
      ]])
    end
    f:write([[
      </tr>
    ]])
  end
  
  f:write([[
    </table>
    </body>
    </html>
  ]])
  f:close()
end

----------------------------------------------------------------------------------------------------------------
-- Internals

local md5 = dofile("md5.lua")

local function ParseResults(filename)
  
local txt = [[
[Header]
Game=RaceRoom Racing Experience
Version=0.3.0.4058
TimeString=2015/01/04 10:21:50

[Race]
RaceMode=1
Scene=Grand Prix
AIDB=Grand Prix.AIW
Track Length=3434.4822

[Slot000]
Driver=Christoph Kubisch
Vehicle=Opel Omega 3000 Evo500
Team=Irmscher Motorsport
Penalty=0
Laps=0
LapDistanceTravelled=282.287811
RaceTime=DNF
Reason=0

[Slot001]
Driver=Hubert Haubt
Vehicle=Audi V8 DTM
Team=Schmidt Motorsport Technik
Penalty=0
QualTime=1:59.338
Laps=10
LapDistanceTravelled=1157.956909
BestLap=2:00.171
RaceTime=0:02:13.192

[Slot002]
Driver=Frank Jelinski
Vehicle=Audi V8 DTM
Team=Audi Zentrum Reutlingen
Penalty=0
QualTime=1:59.711
Laps=10
LapDistanceTravelled=1104.959106
BestLap=2:01.038
RaceTime=0:02:11.328

]]

  local f = io.open(filename,"rt")
  if (not f) then 
    printlog("race file not openable")
    return
  end
  
  local txt = f:read("*a")
  f:close()
  
  if (not txt:find("[END]")) then 
    printlog("race incomplete")
    return
  end
  
  local header = txt:match("%[Header%](.-\n\n)")
  if (not (header)) then
    printlog("race header not found")
    return
  end
  
  local timestring  = header:match("TimeString=(.-)\n")

  local race = txt:match("%[Race%](.-\n\n)")
  if (not (race)) then
    printlog("race info not found")
    return
  end
  
  local tracklength = race:match("Track Length=(.-)\n")
  local scene       = race:match("Scene=(.-)\n")
  local mode        = race:match("RaceMode=(.-)\n")
  
  if (not (timestring and tracklength and scene and mode)) then
    printlog("race details not found")
    return
  end
  
  if (mode == "3") then
    printlog("race was replay")
    return
  end

  local key
  local hash = ""
  local slots = {}
  local mintime
  local drivers = {}
  local lkdrivers = {}
  local uniquedrivers = true
  
  for slot,info in txt:gmatch("%[Slot(%d+)%](.-\n\n)") do
    slot = tonumber(slot) + 1
    if (not slots[slot]) then 
      local tab = {}
      for key,val in info:gmatch("(%w+)=(.-)\n") do
        tab[key] = val
      end
      slots[slot] = tab
      
      hash = hash..tab.Team..tab.Driver
      table.insert(drivers,tab.Driver)
      if (lkdrivers[tab.Driver]) then
        uniquedrivers = false
      end
      lkdrivers[tab.Driver] = true
      
      local time = ParseTime(tab.RaceTime)
      if (time) then mintime = math.min(mintime or 10000000,time) end
    end
  end
  
  table.sort(drivers)
  
  -- discard if no valid time found
  if (not mintime) then
    printlog("race without results", slots[1].Vehicle)
    return
  end
  -- discard if race was too short
  if (mintime < 60*minracetime) then 
    printlog("race too short", slots[1].Vehicle)
    return 
  end
  
  -- key is based on slot0 Vehicle + team and hash of all drivers
  key = slots[1].Vehicle.." "..md5.sumhexa(hash)
  
  printlog("race parsed",key, timestring)
  
  return key,{tracklength = tracklength, scene=scene, timestring=timestring, slots = slots}, uniquedrivers and drivers
end

local function LoadStats(championship)
  local standings = { description = newdescr }
  
  local f = io.open(outdir..championship..".lua","rt")
  if (not f) then return standings end
  
  local str = f:read("*a")
  f:close()
  local txt = "return {\n"..str.."\n}\n"
  
  local fn,err = loadstring(txt)
  if (not fn) then
    printlog("load failed",championship, err)
    return standings
  end
  
  standings = fn()
  return standings
end

local function AppendStats(championship,results,descr)
  local f = io.open(outdir..championship..".lua","at")
  if (descr) then
    f:write('description = [['..descr..']],\n\n')
  end
  
  f:write('{ tracklength = "'..results.tracklength..'", scene="'..results.scene..'", timestring="'..results.timestring..'", slots = {\n')
  for i,s in ipairs(results.slots) do
    f:write("  { ")
    for k,v in pairs(s) do
      f:write(k..'="'..v..'", ')
    end
    f:write("  },\n")
  end
  f:write("},},\n")
  f:close()
end

local function UpdateHistory(filename)
  -- parse results
  local key,res,drivers = ParseResults(filename)
  if (key and res) then
    -- append to proper statistics file
    local standings = LoadStats(key,drivers)
    local numraces = #standings
    if (numraces == 0 or standings[numraces].timestring ~= res.timestring) then
      AppendStats(key, res, numraces == 0 and standings.description)
      table.insert(standings,res)
      
      -- rebuild html stats
      GenerateStatsHTML(key,standings)
    else
      printlog("race already in database")
    end
  end
end

require("wx")

local function RegenerateStatsHTML()
  printlog("rebuilding all stats")
  -- iterate lua files
  local path = wx.wxGetCwd().."/"..outdir
  local dir = wx.wxDir(path)
  local found, file = dir:GetFirst("*.lua", wx.wxDIR_FILES)
  while found do
    local key   = file:sub(1,-5)
    local standings = LoadStats(key)
    GenerateStatsHTML(key,standings)
    
    found, file = dir:GetNext()
  end
end

local function GetFileModTime(filename)
  local fn = wx.wxFileName(filename)
  if fn:FileExists() then
    return fn:GetModificationTime()
  end
end

-- debugging
if (REGENONLY) then
  RegenerateStatsHTML()
  return 
end

frame = nil
timer = nil

function main()
  -- create the frame window
  frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "R3E Open Championship (c) by Christoph Kubisch",
                      wx.wxDefaultPosition, wx.wxSize(400+16,340),
                      wx.wxDEFAULT_FRAME_STYLE )

  -- show the frame window
  frame:Show(true)
  
  local resultfile = wx.wxStandardPaths.Get():GetDocumentsDir()..[[\My Games\SimBin\RaceRoom Racing Experience\UserData\Log\Results\raceresults.txt]]
  local oldmod     = GetFileModTime(resultfile)
  if (not oldmod) then
    local label = wx.wxStaticText(win, wx.wxID_ANY, "Could not find R3E results:\n"..resultfile)
    frame.label = label
    return
  end
  
  local function checkUpdate(force)
    local newmod = GetFileModTime(resultfile)
    if (force or (newmod and oldmod and oldmod:IsEarlierThan(newmod))) then
      oldmod = newmod
      UpdateHistory(resultfile)
    end
  end
  
  local splitter = wx.wxSplitterWindow(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(400+16,340))
  splitter:SetMinimumPaneSize(200) -- don't let it unsplit
  splitter:SetSashGravity(0)
  frame.splitter = splitter
  
  local win = wx.wxWindow(splitter, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(400+16,200) )
  frame.win = win
  
  local txtlog  = wx.wxTextCtrl(splitter, wx.wxID_ANY, "",
                  wx.wxPoint(0,0), wx.wxSize(400+16,100),
                  wx.wxTE_MULTILINE+wx.wxTE_DONTWRAP+wx.wxTE_READONLY)
  frame.txtlog = txtlog
  
  printlog = function(...)
    local args = {}
    for i,v in ipairs({...}) do
      args[i] = tostring(v)
    end
    local argstring = table.concat(args,"\t")
    txtlog:AppendText(argstring.."\n")
  end
  
  printlog("init completed")
  printlog(string.format("minracetime %d mins, checkrate %d mins, useicons %s, onlyicons %s", minracetime, checkrate, tostring(useicons), tostring(onlyicons) )) 
  
  splitter:SplitHorizontally(win, txtlog, 200)
  
  local label = wx.wxStaticText(win, wx.wxID_ANY, "R3E results found:\n"..resultfile, wx.wxPoint(8,8), wx.wxSize(400,50) )
  local line  = wx.wxStaticLine(win, wx.wxID_ANY, wx.wxPoint(8,60), wx.wxSize(400-16,-1))
  local s = 70
  local bw,bh = 200,20
  local tglpoll     = wx.wxCheckBox(win, wx.wxID_ANY, "Check automatically", wx.wxPoint(8,s), wx.wxSize(bw-16,bh))
  local btncheck    = wx.wxButton(win, wx.wxID_ANY, "Check now", wx.wxPoint(8+bw,s), wx.wxSize(bw-16,bh))
  local btnrebuild  = wx.wxButton(win, wx.wxID_ANY, "Rebuild all HTML stats", wx.wxPoint(8,s+30), wx.wxSize(bw-16,bh))
  local btnresult   = wx.wxButton(win, wx.wxID_ANY, "Open result directory", wx.wxPoint(8+bw,s+30), wx.wxSize(bw-16,bh))
  local labeldescr  = wx.wxStaticText(win, wx.wxID_ANY, "New season description:", wx.wxPoint(8,s+60), wx.wxSize(200,16) )
  local txtdescr    = wx.wxTextCtrl(win, wx.wxID_ANY, descrdummy,             wx.wxPoint(8,s+80), wx.wxSize(400-16,30), 0)
  local labellog    = wx.wxStaticText(win, wx.wxID_ANY, "Log:", wx.wxPoint(8,s+114), wx.wxSize(60,16) )
  
  tglpoll:SetValue(true)
  tglpoll:Connect( wx.wxEVT_COMMAND_CHECKBOX_CLICKED, function(event)
    if (timer) then
      if (event:IsChecked ()) then
        timer:Start(1000*60*checkrate)
      else
        timer:Stop()
      end
    end
  end)

  btncheck:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    checkUpdate(true)
  end)

  btnrebuild:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    RegenerateStatsHTML()
  end)

  btnresult:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    local outpath = (wx.wxGetCwd().."/"..outdir.."_style.css"):gsub("/","\\")
    
    wx.wxExecute('explorer /select,"'..outpath..'"', wx.wxEXEC_ASYNC)
  end)

  txtdescr:Connect( wx.wxEVT_COMMAND_TEXT_UPDATED, function(event)
    newdescr = event:GetString()
  end)

  win.label = label
  win.line  = line
  win.tglpoll = tglpoll
  win.btncheck = btncheck
  win.btnrebuild = btnrebuild
  win.btnresult = btnresult
  win.labeldescr = labeldescr
  win.txtdescr  = txtdescr
  win.labellog = labellog
  
  frame:Connect(wx.wxEVT_ACTIVATE,
    function(event)
      if (not timer) then
        timer = wx.wxTimer( frame, wx.wxID_ANY )
        timer:Start(1000*60*checkrate)
        
        frame:Connect(wx.wxEVT_TIMER,
          function(event)
            checkUpdate()
          end)
      end
    end)
end

main()
wx.wxGetApp():MainLoop()
