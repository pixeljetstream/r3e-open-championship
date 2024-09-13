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
local cjson = require("cjson")

local cmdlineargs = {...}
--local cmdlineargs = {"-addrace", "./results/test_june_2023.lua", "inputs/2023_05_21_17_21_06_Race1.txt", "-makehtml", "./results/test_june_2023.lua", "./results/test_june_2023.html"}
local REGENONLY   = false

local cfg = {}

local function loadConfigString(string)
  local fn,err = loadstring(string)
  assert(fn, err)
  fn = setfenv(fn, cfg)
  fn()
end

local function loadConfig(filename)
  local fn,err = loadfile(filename)
  assert(fn, err)
  fn = setfenv(fn, cfg)
  fn()
end

loadConfig("config.lua")

-------------------------------------------------------------------------------------

local printlog = print

local function parseJson(filename)
  local f = io.open(filename,"rt")
  if (not f) then 
    printlog("file not openable")
    return
  end

  local txt = f:read("*a")
  f:close()
 return cjson.decode(txt)
end

local function tableFlatCopy(tab,fields)
  local tout = {}
  
  if (fields) then
    for i,v in pairs(fields) do
      tout[v] = tab[v]
    end
  else
    for i,v in pairs(tab) do
      tout[i] = v
    end
  end
  return tout
end

local function tableLayerCopy(tab,fields)
  local tout = {}
  
  for i,v in pairs(tab) do
    tout[i] = tableFlatCopy(v,fields)
  end
  
  return tout
end

local function quote(str)
  return str and '"'..tostring(str)..'"' or "nil"
end

local function ParseTime(str)
  if (not str) then return end
  local h,m,s = str:match("(%d+):(%d+):([0-9%.]+)")
  if (h and m and s) then return h*60*60 + m*60 + s end
  local m,s = str:match("(%d+):([0-9%.]+)")
  if (m and s) then return m*60 + s end
end

local function MakeTime(millis)
  local s = millis/1000
  local h = math.floor(s/3600)
  s = s - h*3600
  local m = math.floor(s/60)
  s = s - m*60
  
  return (h > 0 and tostring(h)..":" or "")..tostring(m)..":"..tostring(s)
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

-------------------------------------------------------------------------------------


-- indexed by id
local tracks   = {} -- table
local cars     = {} -- string name
local teams    = {} -- string name
-- indexed by name
local lktracks = {} -- table
local lkcars   = {} -- string id
local lkteams  = {} -- string id
local lkupper  = {} -- string upper name

do
  local json = parseJson("r3e-data.json")
  
  for id,track in pairs(json.tracks) do
    for _,layout in pairs(track.layouts) do
      local t = {track = track.Name, layout = layout.Name, name = track.Name.." - "..layout.Name, layoutId = layout.Id}
      tracks[layout.Id] = t
      lktracks[t.name] = t
      lkupper[string.lower(t.name)] = t.name
    end
  end
  
  for id,team in pairs(json.teams) do
    teams[id] = team.Name
    lkteams[team.Name] = id
  end
  for id,car in pairs(json.cars) do
    cars[id] = car.Name
    lkcars[car.Name] = id
  end
end

local function parseAssetIcons(filename)
  local f = io.open(filename,"rt")
  local str = f:read("*a")
  f:close()

  local icons = {}
  for id,url,key in str:gmatch('option value="(%d+)" data%-image="(.-)">%s*(.-)<') do
    icons[id]  = url
    icons[key] = url
    lkupper[string.lower(key)] = key
  end
  
  local function patch(dst, src)
    local i = icons[src]
    assert(i, src.." icon not found")
    
    if i then 
      icons[dst] = i
      lkupper[string.lower(dst)] = dst
    end
  end
  
  -- manual car icon patches
  patch("BMW M4 DTM 2020e", "BMW M4 DTM 2020")
  patch("Porsche 911 GT3 R", "Porsche 911 GT3 R (2019)")
  patch("AMG-Mercedes C-Klasse DTM 2005", "AMG-Mercedes C-Klasse DTM")
  patch("Audi RS 5 DTM 2020e", "Audi RS 5 DTM 2020")
  patch("Lynk & Co 03 TCR", "Lynk &amp; Co 03 TCR")
  patch("E36 V8 JUDD", "134 Judd V8")
  patch("AMG-Mercedes CLK DTM 2003", "AMG-Mercedes CLK DTM")
  patch("Mercedes-AMG C 63 DTM", "Mercedes-AMG C63 DTM")
  patch("BMW M3 DTM ", "BMW M3 DTM")
  patch("Mercedes-AMG C 63 DTM 2015", "Mercedes-AMG C63 DTM")
  patch("AMG-Mercedes 190 E 2.5-16 Evolution II 1992", "Mercedes 190E Evo II DTM")
  patch("AMG-Mercedes C-Klasse DTM 1995", "7076")
  
  for i,t in pairs(lktracks) do
    if (icons[i] == nil) then
      printlog("icon not found", i)
      icons[i] = "https://prod.r3eassets.com/static/img/icons/track.svg"
    end
  end
  for i,t in pairs(cars) do
    if (not icons[t]) then
      printlog("icon not found", t)
      icons[t] = "https://prod.r3eassets.com/static/img/icons/car.svg"
    end
  end
  return icons
end
local function makeIcon(url,name,style)
  return '<img src="'..url..'" alt="'..name..'" title="'..name..'" style="vertical-align:middle;'..(style or "")..'" >'
end
local function upperfix(str)
  return lkupper[str] or str
end


local icons = parseAssetIcons("assets.txt")

-------------------------------------------------------------------------------------

local function GenerateStatsHTML(outfilename,standings)
  assert(outfilename and standings)
  local info = standings[1].slots
  assert(info)
  
  printlog("generate HTML",outfilename)
  
  -- check if we have unique names, then operate based on
  -- names and not slotindices
  local uniquedrivers = true
  local lkdrivers = {}
  for i,v in ipairs(info) do
    if (lkdrivers[v.Driver]) then
      uniquedrivers = false
    end
    lkdrivers[v.Driver] = i
  end
  
  if (uniquedrivers) then
    printlog "uniquedrivers used"
    -- make info a copy to avoid messing with "standings"
    info = tableLayerCopy(info,{"Driver","Team","Vehicle"})
    
    -- if we have unique names, append new drivers of later races
    for r,race in ipairs(standings) do 
      for i,v in ipairs(race.slots) do
        if (not lkdrivers[v.Driver]) then
          local vnew = tableFlatCopy(v,{"Driver","Team","Vehicle"})
          table.insert(info,vnew)
          lkdrivers[v.Driver] = #info
        end
      end
    end
    
    -- start reshuffling all results based on info, and add dummy entries
    for r,race in ipairs(standings) do
      -- fill in the dummy info first
      local newslots = tableFlatCopy(info)
      -- overwrite with real info
      for i,v in ipairs(race.slots) do
        newslots[ lkdrivers[v.Driver] ] = v
      end
      race.slots = newslots
    end
  end
    
  local numdrivers = #info
  
  local numraces   = #standings
  local numbestlap = math.min(cfg.maxbestlap,numdrivers)
  local numbestqual= math.min(cfg.maxbestqual,numdrivers)
  
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
  -- [numraces][numdrivers]
  local raceresults     = {}
  local racepositions   = {}
  local racepoints      = {}
  
  -- [numraces][numteams]
  local teamracepoints  = {}
  -- [numraces][numcars]
  local carracepoints   = {}
  
  -- [numraces][numbestlap]
  local lapracetimes    = {}
  -- [numraces][numbestqual]
  local qualracetimes   = {}
  
  -- create point table per race per slot
  for r,race in ipairs(standings) do 
    local function getSortedTimes(field)
      local times = {}
      local sorted = {}
      for i=1,numdrivers do
        sorted[i] = i
        assert(race.slots[i], string.format("%d %d",r,i))
        times[i] = ParseTime(race.slots[i][field] or "")
        -- may be nil if DNF 
      end
      
      table.sort(sorted,
        function(a,b) 
          return (times[a] or 1000000000) < (times[b] or 1000000000)
        end)
      
      return sorted,times
    end
    
    local function getSortedResults()
      local times = {}
      local sorted = {}
      local pos    = {}
      local laps   = {}
      for i=1,numdrivers do
        sorted[i] = i
        assert(race.slots[i], string.format("%d %d",r,i))
        times[i] = ParseTime(race.slots[i].RaceTime or "")
        laps[i]  = tonumber(race.slots[i].Laps) or 0
        -- if no position use something very high
        pos[i]   = race.slots[i].Position and tonumber(race.slots[i].Position) or 10000000
      end
      
      local function sortTime(a,b)
        local lapdiff  = laps[a] - laps[b]
        local timediff = (times[a] or 1000000000) - (times[b] or 1000000000)
        
        if  (lapdiff ~= 0) then return (lapdiff > 0)
        else                    return (timediff < 0)
        end
      end
      
      local function sortPos(a,b)
        local posdiff  = pos[a] - pos[b]
        local lapdiff  = laps[a] - laps[b]
        local timediff = (times[a] or 1000000000) - (times[b] or 1000000000)
        
        if      (posdiff ~= 0) then return (posdiff < 0)
        elseif  (lapdiff ~= 0) then return (lapdiff > 0)
        else                        return (timediff < 0)
        end
      end
      
      table.sort(sorted, cfg.usepositionsort and sortPos or sortTime)
      
      return sorted,times
    end
    
    -- get sorted and times and generate points
    local sorted,times = getSortedResults()
    local points = {}
    local results = {}
    
    local ruleset    = race.ruleset ~= "" and race.ruleset or "default"
    local rulepoints = cfg.rulepoints[ruleset] 
    assert(rulepoints, "could not find ruleset: "..ruleset)
    
    for i=1,math.min(numdrivers,#rulepoints) do
      -- only set points if time is valid
      points[sorted[i]] = times[sorted[i]] and rulepoints[i]
    end
    for i=1,numdrivers do
      results[i] = race.slots[sorted[i]]
      results[i].Player = sorted[i] == 1
      
      if (times[i] and results[i].Position and tonumber(results[i].Position) ~= i) then
        printlog("warning position mismatch "..results[i].Driver.." should: "..results[i].Position.." has: "..i)
      end
      
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
  
  local f = io.open(outfilename,"wt")
 
  local descr = standings.description ~= "" and standings.description
  descr = descr and "<h3>"..descr.."</h3>\n" or ""
  
  f:write([[
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <meta charset="utf-8"/>
    <link href='http://fonts.googleapis.com/css?family=Open+Sans:400,700' rel='stylesheet' type='text/css'>
    <link rel="stylesheet" href="]]..cfg.stylesheetfile..[[">
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
    ]]..(cfg.driver_standings_vehicle and "<th>Vehicle</th>" or "")..[[ 
    ]]..(cfg.driver_standings_team    and "<th>Team</th>" or "")..[[ 
    <th>Points</th>
  ]])
  
  local function addHeaderTracks(attr)
    -- complete header for all tracks
    -- <th><div class="track">blah<br>2015/01/04<br>10:21:50</div></th>
    for r=1,numraces do
      
      local track = standings[r].trackname
      local tinfo = lktracks[track]
      local tname = tinfo and tinfo.name or track
      local ticon = tinfo and tinfo.name or track
      local icon  = icons[ticon]
      if (icon) then
        icon  = cfg.usetrackicons and makeIcon(icon,ticon,cfg.trackiconstyle) or ""
        track = cfg.onlytrackicons and icon or icon.."<br>"..tname
      end
      local ctime = standings[r].timestring:gsub("(%s)","<br>")
      
      f:write([[
        <th id="track" ]]..(attr or "").." >"..track..(cfg.usetrackdates and "<br>"..ctime or "")..[[</th>
      ]])
    end
    f:write([[
      </tr>
    ]])
  end
  local colspan = cfg.driver_standings_position and "colspan=2" or ""
  addHeaderTracks(colspan)

  -- iterate sorted drivers
  local accumpoints = getaccumpoints(racepoints, numdrivers)
  local sortedslots = getsortedslots(accumpoints)
  for pos,i in ipairs(sortedslots) do
    local vehicle = info[i].Vehicle
    local icon = icons[vehicle]
    if (icon and cfg.usevehicleicons) then
      icon = makeIcon(icon,vehicle)
      vehicle = cfg.onlyvehicleicons and icon or icon..'<span class="minor">'..vehicle..'</span>'
    end
    
    local vehicle = cfg.driver_standings_vehicle and "<td>"..vehicle.."</td>" or ""
    local team    = cfg.driver_standings_team    and "<td>"..info[i].Team.."</td>" or ""
    
    f:write([[
      <tr]]..(pos%2 == 0 and ' class="even"' or "")..(i==1 and ' id="player"' or "")..[[>
      <td>]]..pos..[[</td>
      <td>]]..info[i].Driver..[[</td>
      ]]..vehicle..[[ 
      ]]..team..[[ 
      <td class="points">]]..(accumpoints[i] == 0 and "-" or accumpoints[i])..[[</td>
    ]])
    for r=1,numraces do
      local str = racepoints[r][i]
      local didrace = standings[r].slots[i].RaceTime
      
      f:write([[
          <span class="points">]])
      if (not str) then
        f:write([[<td ]]..colspan..[[ class="minor">]]..(didrace and "DNF" or "non-starter")..[[</td>]])
      else
        str = (str == 0 and "-" or str)
        local rpos = racepositions[r][i]
        local ppos = [[<td class="pointcolumn]]..(cfg.driver_standings_position and [[">]] or [[_only">]])..str..[[</td>]]
        local rpos = cfg.driver_standings_position and [[<td class="poscolumn pos]]..rpos..[[">]]..rpos..[[.</td>]] or ""
        f:write(ppos..rpos)
      end
      f:write([[</span>
          ]])
    end
    f:write([[
      </tr>
    ]])
  end

  -- team standings
if (numteams > 1 and cfg.team_standings) then
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
end
  
  
if (numcars > 1 and cfg.vehicle_standings) then
  
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
    if (icon and cfg.usevehicleicons) then
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
      local str = ""
      if (tab) then
        local vehicle = tab.Vehicle
        local icon = icons[vehicle]
        if (icon and cfg.usevehicleicons) then
          icon = makeIcon(icon,vehicle)
          vehicle = cfg.onlyvehicleicons and icon or icon.."<br>"..vehicle
        end
        
        local driver  = tab.Driver or ""
        local vehicle = '<br><span class="minor">'..vehicle.."</span>" or ""
        local ctime   = '<br>'..tab.BestLap or ""
        local gap     = ""
        
        if (pos > 1) then
          local winner   = lapracetimes[r][1]
          local previous = lapracetimes[r][pos-1]

          -- to winner
          ctime = DiffTime( winner.BestLap, tab.BestLap )
          ctime = ctime and '<br>'..ctime or ""
          -- to previous driver
          gap  = DiffTime( previous.BestLap, tab.BestLap )
          gap  = gap  and '<br><span class="minor">'..gap..'</span>' or ""
        end
        
        str = driver..vehicle..ctime..gap
      end

      
      f:write([[
        <td]]..(tab and tab.Player and ' id="player"' or "")..[[>]]..str..[[</td>
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
        if (icon and cfg.usevehicleicons) then
          icon = makeIcon(icon,vehicle)
          vehicle = cfg.onlyvehicleicons and icon or icon.."<br>"..vehicle
        end
        
        local driver  = tab.Driver or ""
        local vehicle = '<br><span class="minor">'..vehicle.."</span>" or ""
        local ctime   = '<br>'..tab.QualTime or ""
        local gap     = ""
        
        if (pos > 1) then
          local winner   = qualracetimes[r][1]
          local previous = qualracetimes[r][pos-1]

          -- to winner
          ctime = DiffTime( winner.QualTime, tab.QualTime )
          ctime = ctime and '<br>'..ctime or ""
          -- to previous driver
          gap  = DiffTime( previous.QualTime, tab.QualTime )
          gap  = gap  and '<br><span class="minor">'..gap..'</span>' or ""
        end
        
        str = driver..vehicle..ctime..gap
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
      local didrace = tab.RaceTime
      local ctime = '<br>'..(tab.RaceTime or "non-starter")
      local gap   = ""
      
      if (pos > 1) then
        local winner   = raceresults[r][1]
        local previous = raceresults[r][pos-1]
        
        local function DiffLap(prevlap, selflap)
          local diff = tonumber(prevlap)-tonumber(selflap)
          if (diff > 0) then
            return "+ "..diff.."laps "
          else
            return ""
          end
        end
        -- to winner
        ctime = DiffTime( winner.RaceTime,      tab.RaceTime )
        ctime = ctime and '<br>'..DiffLap(winner.Laps, tab.Laps)..ctime or (didrace and "<br>DNF" or "<br>non-starter")
        -- to previous driver
        gap  = DiffTime( previous.RaceTime,  tab.RaceTime )
        gap  = gap  and '<br><span class="minor">'..DiffLap(previous.Laps, tab.Laps)..gap..'</span>' or ""
      end
      
      local vehicle = tab.Vehicle
      local icon = icons[vehicle]
      if (icon and cfg.usevehicleicons and cfg.onlyvehicleicons) then
        icon = makeIcon(icon,vehicle,"opacity:0.6;height:1.7em;")
        vehicle = icon
      else
        vehicle = '<span class="minor">'..tab.Vehicle..'</span>'
      end
    
      local driver  = tab.Driver
      local vehicle = '<br>'..vehicle
      
      f:write([[
        <td]]..(tab and tab.Player and ' id="player"' or "")..[[>]]..driver..vehicle..ctime..gap..[[</td>
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
  
  return outfilename
end

----------------------------------------------------------------------------------------------------------------
-- Internals

local md5   = dofile("md5.lua")

local function ParseResultsJSONdedi(json)
  local datet = type(json.Time) == "string" and math.floor(tonumber(json.Time:match("(%d+)"))/1000) or json.Time
  local date  = os.date("*t",datet)
  local date2 = os.date("*t",datet + 1)
  local date3 = os.date("*t",datet + 2)
  local timestring  = string.format("%d/%d/%d %d:%d:%d",date.year, date.month, date.day,  date.hour,  date.min,  date.sec)
  local timestring2 = string.format("%d/%d/%d %d:%d:%d",date2.year,date2.month,date2.day, date2.hour, date2.min, date2.sec)
  local timestring3 = string.format("%d/%d/%d %d:%d:%d",date3.year,date3.month,date3.day, date3.hour, date3.min, date3.sec)
    
  local trackname   = json.Track..(json.TrackLayout and " - "..json.TrackLayout or "")
  local trackid     = lktracks[trackname] and lktracks[trackname].layoutId
  local mode        = "1"
  
  if (not (timestring and trackname and trackid and mode)) then
    printlog("race details not found")
    return
  end

  local key
  local hash = ""
  local slots  = {}
  local slots2 = {}
  local slots3 = {}
  local mintime
  local drivers = {}
  local lkdrivers = {}
  local uniquedrivers = true
  
  -- find race and qualify sessions
  -- only track people who raced
  
  local sessqualify
  local sessrace
  local sessrace2
  local sessrace3
  
  for i,sess in ipairs(json.Sessions) do
    if sess.Type == "Qualify" then sessqualify  = sess end
    if sess.Type == "Race"    then sessrace     = sess end
    if sess.Type == "Race2"   then sessrace2    = sess end
    if sess.Type == "Race3"   then sessrace3    = sess end
  end
  
  if (not sessrace) then 
    printlog("race not found")
    return 
  end
  
  local function procRace(sess, slots, first)
    for i,player in ipairs(sess.Players) do
      local slot = i
      if (not slots[slot]) then 
        local tab = {}
        tab.Driver    = player[cfg.jsonDriverName]
        tab.Vehicle   = player.Car
        tab.Team      = "-"
        tab.RaceTime  = player.FinishStatus == "Finished" and MakeTime(player.TotalTime) or "DNF"
        tab.BestLap   = player.BestLapTime > 0 and MakeTime(player.BestLapTime) or nil
        tab.Laps      = #player.RaceSessionLaps
        tab.Position  = player.Position
        slots[slot]   = tab
        
        if (first) then
          hash = hash..tab.Team..tab.Driver
          table.insert(drivers,tab.Driver)
          if (lkdrivers[tab.Driver]) then
            uniquedrivers = false
          end
          lkdrivers[tab.Driver] = tab
        end
      end
    end
  end
  
  procRace(sessrace, slots, true)
  
  if (sessrace2) then
    procRace(sessrace2, slots2, false)
  end
  
  if (sessrace3) then
    procRace(sessrace3, slots3, false)
  end
  
  if (sessqualify) then
    for i,player in ipairs(sessqualify.Players) do
      local name = player[cfg.jsonDriverName]
      local tab = lkdrivers[name]
      
      if (player.BestLapTime > 0 and tab) then
        tab.QualTime = MakeTime(player.BestLapTime)
      end
    end
  end
  
  --table.sort(drivers)
  
  -- discard if no valid time found
  --if (not mintime) then
  --  printlog("race without results", slots[1].Vehicle, timestring)
  --  return
  --end
  
  -- key is based on slot0 Vehicle + team and hash of all drivers
  key = slots[1].Vehicle.." "..md5.sumhexa(hash)
  
  printlog("race parsed",key, timestring)
  
  local race1 =               {trackname = trackname, trackid=trackid, timestring=timestring,  slots = slots,  ruleset=cfg.ruleset}
  local race2 = sessrace2 and {trackname = trackname, trackid=trackid, timestring=timestring2, slots = slots2, ruleset=cfg.ruleset}
  local race3 = sessrace3 and {trackname = trackname, trackid=trackid, timestring=timestring3, slots = slots3, ruleset=cfg.ruleset}
  
  return key, race1, race2, race3
end

local function ParseResultsJSONsp(json)
  
  local key
  local hash = ""
  local slots  = {}
  local mintime
  local drivers = {}
  local lkdrivers = {}
  
  local timestring  = json.header.time
  
  local track
  local trackname
  if (json.event.track and json.event.layout) then
    trackname = upperfix(json.event.track.." - "..json.event.layout)
    track     = lktracks[trackname]
  else
    trackkname = tostring(json.event.layoutId)
    track      = tracks[json.event.layoutId]
  end

  if (not track) then
    printlog("error could not find track", trackname)
    return
  end
  
    
  local trackid     = track.layoutId
  local trackname   = track.name
  
  local function procRace(drivers, slots, first)
    for i,player in ipairs(drivers) do
      local slot = i
      if (not slots[slot] and player.name) then 
        local tab = {}
        tab.Driver    = player.name
        
        tab.countryId = tostring(player.countryId)
        tab.liveryId  = tostring(player.liveryId)
        tab.carId     = tostring(player.carId)
        tab.teamId    = tostring(player.teamId)
        
        if (player.vehicle) then
          tab.Vehicle   = upperfix(player.vehicle)
          tab.carId     = lkcars[tab.Vehicle]
        else
          tab.Vehicle   = cars[tab.carId] or tab.carId
        end
        if (player.team) then
          tab.Team    = player.team
          tab.teamId  = lkteams[player.team]
        else
          tab.Team    = teams[tab.teamId] or tab.teamId
        end
        
        local qualTimeMs = player.qualtimems or player.qualTimeMs
        local raceTimeMs = player.racetimems or player.raceTimeMs
        local bestLapTimeMs = player.bestlaptimems or player.bestLapTimeMs
        
        tab.RaceTime  = player.place > 0 and MakeTime(raceTimeMs) or "DNF"
        tab.QualTime  = qualTimeMs > 0 and MakeTime(qualTimeMs) or nil
        tab.BestLap   = bestLapTimeMs > 0 and MakeTime(bestLapTimeMs) or nil
        tab.Laps      = player.totallaps or player.totalLaps
        tab.Position  = player.place
        slots[slot]   = tab
        
        if (first) then
          hash = hash..tab.Team..tab.Driver
          table.insert(drivers,tab.Driver)
          if (lkdrivers[tab.Driver]) then
            uniquedrivers = false
          end
          lkdrivers[tab.Driver] = tab
        end
        
        local ctime = raceTimeMs > 0 and raceTimeMs/1000
        if (ctime) then mintime = math.min(mintime or 10000000,ctime) end
      end
    end
  end
  
  procRace(json.drivers, slots, true)
  
  if (#slots < 1) then
    printlog("no drivers found")
    return 
  end
  
  -- discard if race was too short
  if (not mintime or (mintime < 60*cfg.minracetime)) then 
    printlog("race too short", slots[1] and slots[1].Vehicle)
    return 
  end
  
  key = slots[1].Vehicle.." "..md5.sumhexa(hash)
  
  printlog("race parsed",key, timestring)
  
  local race1 = {trackname = trackname, trackid=trackid, timestring=timestring,  slots = slots,  ruleset=cfg.ruleset}
  
  return key, race1
end

local function ParseResultsJSON(filename)
    local f = io.open(filename,"rt")
  if (not f) then 
    printlog("race file not openable")
    return
  end
  
  local txt = f:read("*a")
  f:close()
  
  local json = cjson.decode(txt)
  
  if (not json) then 
    printlog("could not decode")
    return
  end
  
  if (json.Server) then
    return ParseResultsJSONdedi(json)
  else
    return ParseResultsJSONsp(json)
  end
end

local lxml = dofile("xml.lua")

local function ParseResultsXML(filename)
  local f = io.open(filename,"rt")
  if (not f) then 
    printlog("race file not openable")
    return
  end
  
  local txt = f:read("*a")
  f:close()
  
  local xml = lxml.parse(txt)
  
  if (not xml or not xml.MultiplayerRaceResult) then 
    printlog("could not decode")
    return
  end
  
  xml = xml.MultiplayerRaceResult
  
  local timestring
  local timestring2
  local timestring3
  do
    -- 2021-09-27T19:01:45Z
    -- 2015-10-30T20:45:12.217Z
    local year,month,day,hour,min,sec = xml.Time:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):([%d%.]+)")
    timestring  = string.format("%s/%s/%s %s:%s:%s",year,month,day, hour, min, sec)
    timestring2 = string.format("%s/%s/%s %s:%s:%s",year,month,day, hour, min, sec+1) -- bit of a hack
    timestring3 = string.format("%s/%s/%s %s:%s:%s",year,month,day, hour, min, sec+2) -- bit of a hack
  end
  
  
  local trackname   = xml.Track..(xml.TrackLayout and " - "..xml.TrackLayout or "")
  local trackid     = lktracks[trackname] and lktracks[trackname].layoutId
  local mode        = "1"
  
  if (not (timestring and trackname and trackid and mode)) then
    printlog("race details not found")
    return
  end

  local key
  local hash = ""
  local slots  = {}
  local slots2 = {}
  local slots3 = {}
  local mintime
  local drivers = {}
  local lkdrivers = {}
  local uniquedrivers = true
  
  -- find race and qualify sessions
  -- only track people who raced
  
  local sessqualify
  local sessrace
  local sessrace2
  local sessrace3
  
  for i,sess in ipairs(xml.Sessions) do
    if sess.Type == "Qualify" then sessqualify  = sess end
    if sess.Type == "Race"    then sessrace     = sess end
    if sess.Type == "Race2"   then sessrace2    = sess end
    if sess.Type == "Race3"   then sessrace3    = sess end
  end
  
  if (not sessrace) then 
    printlog("race not found")
    return 
  end
  
  local function procRace(sess, slots, first)
    for i,player in ipairs(sess.Players) do
      local slot = i
      if (not slots[slot]) then 
        local tab = {}
        tab.Driver    = player[cfg.xmlDriverName]
        tab.Vehicle   = player.Car
        tab.Team      = "-"
        tab.RaceTime  = player.FinishStatus == "Finished" and MakeTime(player.TotalTime) or "DNF"
        tab.BestLap   = player.BestLapTime > 0 and MakeTime(player.BestLapTime) or nil
        tab.Laps      = #player.RaceSessionLaps
        tab.Position  = player.Position
        slots[slot]   = tab
        
        if (first) then
          hash = hash..tab.Team..tab.Driver
          table.insert(drivers,tab.Driver)
          if (lkdrivers[tab.Driver]) then
            uniquedrivers = false
          end
          lkdrivers[tab.Driver] = tab
        end
        
        local ctime = player.TotalTime > 0 and player.TotalTime/1000
        if (ctime) then mintime = math.min(mintime or 10000000,ctime) end
      end
    end
  end
  
  procRace(sessrace, slots, true)
  
  if (sessrace2) then
    procRace(sessrace2, slots2, false)
  end
  
  if (sessrace3) then
    procRace(sessrace3, slots3, false)
  end
  
  if (sessqualify) then
    for i,player in ipairs(sessqualify.Players) do
      local name = player[cfg.jsonDriverName]
      local tab = lkdrivers[name]
      
      if (player.BestLapTime > 0 and tab) then
        tab.QualTime = MakeTime(player.BestLapTime)
      end
    end
  end
  
  --table.sort(drivers)
  
  -- discard if no valid time found
  --if (not mintime) then
  --  printlog("race without results", slots[1].Vehicle)
  --  return
  --end
  
  -- key is based on slot0 Vehicle + team and hash of all drivers
  key = slots[1].Vehicle.." "..md5.sumhexa(hash)
  
  printlog("race parsed",key, timestring)
  
  local race1 =               {trackname = trackname, trackid=trackid, timestring=timestring,  slots = slots,  ruleset=cfg.ruleset}
  local race2 = sessrace2 and {trackname = trackname, trackid=trackid, timestring=timestring2, slots = slots2, ruleset=cfg.ruleset}
  local race3 = sessrace3 and {trackname = trackname, trackid=trackid, timestring=timestring3, slots = slots3, ruleset=cfg.ruleset}
  
  return key, race1,race2,race3
end

local function ParseResults(filename)
  assert(filename, "no filename provided")
  local parserRegistry = {
    txt  = ParseResultsJSON,
    json = ParseResultsJSON,
    xml  = ParseResultsXML,
  }
  
  local ext = filename:lower():match("%.(.-)$")
  local parser = parserRegistry[ext or ""]
  assert(parser, "could not derive valid parser for: "..filename)
  return parser(filename)
end

local function LoadStats(outfilename)
  local f = io.open(outfilename,"rt")
  if (not f) then return nil end
  
  local str = f:read("*a")
  f:close()
  local txt = "return {\n"..str.."\n}\n"
  
  local fn,err = loadstring(txt)
  if (not fn) then
    printlog("load failed",outfilename, err)
    return standings
  end
  
  standings = fn()
  
  return standings
end

local function AppendStats(outfilename,results,descr)
  local f = io.open(outfilename,"at")
  if (descr) then
    f:write('description = [['..descr..']],\n\n')
  end
  printlog("appendrace",outfilename)
  
  f:write('{ trackname = '..quote(results.trackname)..', trackid = '..quote(results.trackid))
  if (results.filename) then
    f:write(', filename = '..quote(results.filename))
  end
  f:write(', timestring = '..quote(results.timestring)..', ruleset = '..quote(results.ruleset or "default")..', slots = {\n')
  for i,s in ipairs(results.slots) do
    f:write("  { ")
    for k,v in pairs(s) do
      f:write(k..'='..quote(v)..', ')
    end
    f:write("  },\n")
  end
  f:write("},},\n")
  f:flush()
  f:close()
end

local function UpdateHistory(filename, outfilename)
  -- parse results
  local key,res,res2,res3 = ParseResults(filename)
  if (key and res) then
    -- test
    local filenameshort = filename:match("[^\\/]+$")
    
    -- override key
    local key = cfg.forcedkey ~= "" and cfg.forcedkey or key
    -- append to proper statistics file
    local outfilename = outfilename or cfg.outdir..key..".lua"
    local standings = LoadStats(outfilename) or { description = cfg.newdescr }
    local numraces = #standings
    local lastres = res3 or res2 or res
    
    local found = false
    for i=1,numraces do
      if (standings[i].timestring == lastres.timestring) then
        found = true
      end
    end
    
    if (not found) then
      res.filename = filenameshort
      AppendStats(outfilename, res, numraces == 0 and standings.description)
      table.insert(standings, res)
      if (res2) then
        res2.filename = filenameshort
        AppendStats(outfilename, res2)
        table.insert(standings, res2)
      end
      if (res3) then
        res3.filename = filenameshort
        AppendStats(outfilename, res3)
        table.insert(standings, res3)
      end
      
      return key,standings,outfilename
    else
      printlog("race already in database")
    end
  end
end

do
  -- commandline
  local i = 1
  local argcnt = #cmdlineargs

  while (i <= argcnt) do
    local arg = cmdlineargs[i]
    if (arg == "-addrace") then
      print("... -addrace ...")
      if (i + 2 > argcnt) then print("error: two arguments required: database-file raceresults-file"); os.exit(1); end
      local outfile = cmdlineargs[i+1]
      local infile  = cmdlineargs[i+2]
      
      UpdateHistory(infile,outfile)
      
      i = i + 2
    elseif (arg == "-addraceautodb") then
      print("... -addraceautodb ...")
      if (i + 3 > argcnt) then print("error: three arguments required: raceresults-file"); os.exit(1); end
      local infile   = cmdlineargs[i+1]
      local cmd      = cmdlineargs[i+2]
      
      local _,standings,outfile = UpdateHistory(infile,nil)
      if (standings and outfile and cmd:find("html")) then
        local htmlfile = outfile:sub(1,-5)..".html"
        htmlfile = GenerateStatsHTML(htmlfile,standings)
        if (htmlfile and cmd:find("show")) then
          os.execute('start "" "'..htmlfile..'"')
        end
      end
      i = i + 2
    elseif ( arg == "-makehtml") then
      print("... -makehtml ...")
      if (i + 2 > argcnt) then print("error: two arguments required: database-file html-file"); os.exit(1); end
      
      local infile  = cmdlineargs[i+1]
      local outfile = cmdlineargs[i+2]
      
      local standings = LoadStats(infile)
      if (not standings) then print("error: database-file did not load"); os.exit(1); end
      
      GenerateStatsHTML(outfile,standings) 
      
      i = i + 2
    elseif (arg == "-configfile") then
      print("... -configfile ...")
      if (i + 1 > argcnt) then print("error: two arguments required: config lua-file"); os.exit(1); end
      loadConfig(cmdlineargs[i+1])
      
      i = i + 1
    elseif (arg == "-config") then
      print("... -config ...")
      if (i + 1 > argcnt) then print("error: two arguments required: config lua string"); os.exit(1); end
      loadConfigString(cmdlineargs[i+1])
      
      i = i + 1
    end
    
    i = i + 1
  end
  if (argcnt > 1) then 
    print("... done ...")
    return 
  end
end

require("wx")

local function RegenerateStatsHTML()
  printlog("rebuilding all stats")
  
  local f = io.open(cfg.outdir.."index.html","wt")
  f:write([[
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <meta charset="utf-8"/>
    <link href='http://fonts.googleapis.com/css?family=Open+Sans:400,700' rel='stylesheet' type='text/css'>
    <link rel="stylesheet" href="]]..cfg.stylesheetfile..[[">
    </head>
    <body>
    <h1>Championships</h1>
    <table>
    <tr>
    <th>Car</th>
    <th>Description</th>
    <th>Races</th>
    <th></th>
    </tr>
  ]])
  
  -- iterate lua files
  local path = wx.wxGetCwd().."/"..cfg.outdir
  local dir = wx.wxDir(path)
  local found, file = dir:GetFirst("*.lua", wx.wxDIR_FILES)
  local row = 1
  while found do
    local key = file:sub(1,-5)
    local standings = LoadStats(cfg.outdir..key..".lua")
    if (standings) then
      GenerateStatsHTML(cfg.outdir..key..".html",standings)
      
      local info = standings[1].slots
      local vehicle = info[1].Vehicle
      local icon = icons[vehicle]
      local imgicon = makeIcon(icon,vehicle)
      f:write([[
      <tr]]..(row%2 == 0 and ' class="even"' or "")..[[>
      <td>]]..imgicon..vehicle..[[</td>
      <td style="color:#aaa">]]..standings.description..[[</td>
      <td style="color:#aaa">]]..#standings..[[</td>
      <td>
      <a style="color:#aaa" href="]]..key..[[.html">Results</a> 
      </td>
      </tr>
      ]])
    end
    row = row + 1
    found, file = dir:GetNext()
  end
  f:close()
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
  local ww = 600
  local wh = 700
  
  frame = wx.wxFrame( wx.NULL, 1, "R3E Open Championship",
                      wx.wxDefaultPosition, wx.wxSize(ww+16, wh),
                      wx.wxDEFAULT_FRAME_STYLE )

  -- show the frame window
  frame:Show(true)
  
  local replacedirs = {
    USER_DOCUMENTS = wx.wxStandardPaths.Get():GetDocumentsDir(),
  }
  
  local resultpath = cfg.inputfile:gsub("%$([%w_]+)%$", replacedirs):match("(.+)[\\/][^\\/]+$")
  
  local splitter = wx.wxSplitterWindow(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(ww+16,wh))
  splitter:SetSashGravity(0)
  frame.splitter = splitter
  
  local win = wx.wxWindow(splitter, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(440+16,200) )
  frame.win = win
  
  local txtlog  = wx.wxTextCtrl(splitter, wx.wxID_ANY, "",
                  wx.wxPoint(0,0), wx.wxSize(ww-16,500),
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
  printlog(string.format("minracetime %d mins", cfg.minracetime))  
  
  local label = wx.wxStaticText(win, wx.wxID_ANY, "R3E results found:\n"..resultpath, wx.wxPoint(8,8), wx.wxSize(ww,70) )
  local line  = wx.wxStaticLine(win, wx.wxID_ANY, wx.wxPoint(8,80), wx.wxSize(ww-16,-1))
  local s = 100
  local bw,bh,bhgap = 200,30,40
  local btncheck    = wx.wxButton(win, wx.wxID_ANY, "Process result file",        wx.wxPoint(8,s),     wx.wxSize(bw-16,bh))
  s = s + bhgap
  local btnrebuild  = wx.wxButton(win, wx.wxID_ANY, "Rebuild all HTML stats",     wx.wxPoint(8,s),     wx.wxSize(bw-16,bh))
  local btnoutput   = wx.wxButton(win, wx.wxID_ANY, "Open output directory",      wx.wxPoint(8+bw,s),  wx.wxSize(bw-16,bh))
  s = s + bhgap
  local labeldescr  = wx.wxStaticText(win, wx.wxID_ANY, "New season description (optional):",wx.wxPoint(8,s),     wx.wxSize(300,bh) )
  local txtdescr    = wx.wxTextCtrl(win, wx.wxID_ANY, "",                 wx.wxPoint(8,s+bh+5),     wx.wxSize(ww-32,30), 0)
  s = s + bh+5+30+5
  local labelkey    = wx.wxStaticText(win, wx.wxID_ANY, "Override database filename (optional):", wx.wxPoint(8,s),    wx.wxSize(300,bh) )
  local txtkey      = wx.wxTextCtrl(win, wx.wxID_ANY, "",                   wx.wxPoint(8,s+bh+5),    wx.wxSize(ww-32,30), 0)
  s = s + bh+5+30+5
  local labellog    = wx.wxStaticText(win, wx.wxID_ANY, "Log:",                   wx.wxPoint(8,s),    wx.wxSize(60,bh) )
  
  local sh = s + bhgap
  splitter:SetMinimumPaneSize(sh) -- don't let it unsplit
  splitter:SplitHorizontally(win, txtlog, sh)

  btncheck:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    local fileDialog = wx.wxFileDialog(frame, "Process file",
      resultpath,
      "Text Files (.txt)|.txt",
      "",
      wx.wxFD_OPEN + wx.wxFD_FILE_MUST_EXIST + wx.wxFD_MULTIPLE)
    if fileDialog:ShowModal() == wx.wxID_OK then
      for _, path in ipairs(fileDialog:GetPaths()) do
        local key, standings = UpdateHistory(path)
        if (key and standings) then
          GenerateStatsHTML(cfg.outdir..key..".html",standings)
        end
      end
    end
    fileDialog:Destroy()
  end)

  btnrebuild:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    RegenerateStatsHTML()
  end)

  btnoutput:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    local outpath = (wx.wxGetCwd().."/"..cfg.outdir.."_style.css"):gsub("/","\\")
    
    wx.wxExecute('explorer /select,"'..outpath..'"', wx.wxEXEC_ASYNC)
  end)

  txtdescr:Connect( wx.wxEVT_COMMAND_TEXT_UPDATED, function(event)
    cfg.newdescr = event:GetString()
  end)

  txtkey:Connect( wx.wxEVT_COMMAND_TEXT_UPDATED, function(event)
    cfg.forcedkey = event:GetString()
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
end

main()
wx.wxGetApp():MainLoop()
