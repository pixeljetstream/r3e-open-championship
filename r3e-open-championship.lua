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

local outdir      = "results/"
local minracetime = 5           -- in minutes, if a race was shorter it doesn't contribute to stats
local checkrate   = 1           -- in minutes
local rulepoints  = {25,18,15,12,10,8,6,4,2,1}
local tracknamelength = 12      -- to keep track columns tight, names are cut off, alternatively set 
                                -- a high value here, and make use of <br> below
local tracknames  =             -- maps tracklength to a name, let's hope those are unique
{            
["4556.0303"]="Hockenheim", 
["3663.8022"]="Oschersleben",
["4359.0034"]="Hungaroring",
["2192.3979"]="Norisring",
["3898.8025"]="Moscow",
["4305.5688"]="RedBullRing",
["3609.2053"]="Nurburgring",
["3434.4822"]="Lausitz",
["4275.6143"]="Zandvoort",
["1939.5625"]="BrandsHatch",
["5915.0332"]="Slovakia",
["3649.3059"]="Sachsenring",
["3797.2512"]="RaceroomRaceway",
["4623.4604"]="Portimao",
["6191.8174"]="Bathurst",
["3992.8533"]="Zolder",
["4069.3682"]="Indianapolis",
["3585.5344"]="LagunaSeca",
["3809.4441"]="MidOhio",
["5783.3423"]="Monza",
["5801.7275"]="Suzuka",
["3464.6255"]="SuzukaWC",
}


local function ParseTime(str)
  local h,m,s = str:match("(%d+):(%d+):([0-9%.]+)")
  if (h and m and s) then return h*60*60 + m*60 + s end
  local m,s = str:match("(%d+):([0-9%.]+)")
  if (m and s) then return m*60 + s end
end

local printlog = print

local function GenerateStatsHTML(championship,standings)
  assert(championship and standings)
  local info = standings[1].slots
  assert(info)
  local numdrivers = #info
  local numraces   = #standings
  
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
  local racepoints  = {}
  local teamracepoints = {}
  local carracepoints = {}
  local lapracetimes = {}
  
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
    for i=1,math.min(numdrivers,#rulepoints) do
      -- only set points if time is valid
      points[sorted[i]] = times[sorted[i]] and rulepoints[i]
    end
    for i=1,numdrivers do
      if (not points[i]) then
        -- only set non nil if had a valid time
        points[i] = times[i] and 0 
      end
    end
    racepoints[r] = points
    
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
    for i=1,3 do
      local slot = sorted[i]
      laptimes[i] = times[slot] and { 
        Driver=race.slots[slot].Driver, 
        Vehicle=race.slots[slot].Vehicle,
        BestLap=race.slots[slot].BestLap,
        Player = (slot == 1)}
    end
    lapracetimes[r] = laptimes
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
  f:write([[
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <meta charset="utf-8"/>
    <link href='http://fonts.googleapis.com/css?family=Open+Sans:400,700' rel='stylesheet' type='text/css'>
    <link rel="stylesheet" href="_style.css">
    </head>
    <body>
    <h1>R3E Championship Standings</h1>
    <table>
    <caption>Driver Standings</caption>
    <tr>
    <th>Pos</th>
    <th>Driver</th>
    <th>Vehicle</th>
    <th>Team</th>
    <th>Points</th>
  ]])
  
  local function addHeaderTracks()
    -- complete header for all tracks
    -- <th><div class="track">blah<br>2015/01/04<br>10:21:50</div></th>
    for r=1,numraces do
      local track = tostring(standings[r].tracklength)
      track = tracknames[track] or track
      local time   = standings[r].timestring:gsub("(%s)","<br>")
      
      f:write([[
        <th id="track">]]..track:sub(1,tracknamelength).."<br>"..time..[[</th>
      ]])
    end
    f:write([[
      </tr>
    ]])
  end
  addHeaderTracks()

  -- iterate sorted drivers
  local accumpoints = getaccumpoints(racepoints, numdrivers)
  local sortedslots = getsortedslots(accumpoints)
  for pos,i in ipairs(sortedslots) do
    f:write([[
      <tr]]..(pos%2 == 0 and ' class="even"' or "")..(i==1 and ' id="player"' or "")..[[>
      <td>]]..pos..[[</td>
      <td>]]..info[i].Driver..[[</td>
      <td>]]..info[i].Vehicle..[[</td>
      <td>]]..info[i].Team..[[</td>
      <td class="points">]]..(accumpoints[i] == 0 and "-" or accumpoints[i])..[[</td>
    ]])
    for r=1,numraces do
      local str = racepoints[r][i]
      str = str == 0 and "-" or str or "DNF"
      f:write([[
        <td class="points">]]..str..[[</td>
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
    f:write([[
      <tr]]..(pos%2 == 0 and ' class="even"' or "")..(i==1 and ' id="player"' or "")..[[>
      <td>]]..pos..[[</td>
      <td>]]..carslots[i].Name..[[</td>
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
    <caption>Best Lap Times</caption>
    <tr>
    <th>Pos</th>
  ]])
  addHeaderTracks()
  for pos=1,3 do
    f:write([[
      <tr]]..(pos%2 == 0 and ' class="even"' or "")..[[>
      <td>]]..pos..[[</td>
    ]])
    for r=1,numraces do
      local tab = lapracetimes[r][pos]
      f:write([[
        <td]]..(tab and tab.Player and ' id="player"' or "")..[[>]]..(tab and (tab.Driver.."<br>"..tab.Vehicle.."<br>"..tab.BestLap) or "")..[[</td>
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

  local timestring  = txt:match("TimeString=(.-)\n")
  local tracklength = txt:match("Track Length=(.-)\n")
  local scene       = txt:match("Scene=(.-)\n")

  local key
  local hash = ""
  local slots = {}
  
  local mintime = 100000000
  
  for slot,info in txt:gmatch("%[Slot(%d+)%](.-\n\n)") do
    slot = tonumber(slot) + 1
    if (not slots[slot]) then 
      local tab = {}
      for key,val in info:gmatch("(%w+)=(.-)\n") do
        tab[key] = val
      end
      slots[slot] = tab
      
      hash = hash..tab.Team..tab.Driver
      
      local time = ParseTime(tab.RaceTime)
      if (time) then mintime = math.min(mintime,time) end
    end
  end
  
  
  -- discard if race was too short
  if (mintime < 60*minracetime) then 
    printlog("race too short", slots[1].Vehicle)
    return 
  end
  
  -- key is based on slot0 Vehicle + team and hash of all drivers
  key = slots[1].Vehicle.." "..md5.sumhexa(hash)
  
  printlog("race parsed",key, timestring)
  
  return key,{tracklength = tracklength, scene=scene, timestring=timestring, slots = slots}
end

local function LoadStats(championship)
  local standings = {}
  
  local f = io.open(outdir..championship..".lua","rt")
  if (not f) then return standings end
  
  local txt = "return {\n"..f:read("*a").."\n}\n"
  f:close()
  
  local fn = loadstring(txt)
  standings = fn()
  
  return standings
end

local function AppendStats(championship,results)
  local f = io.open(outdir..championship..".lua","at")
  f:write("{ tracklength = "..results.tracklength..", scene='"..results.scene.."', timestring='"..results.timestring.."', slots = {\n")
  for i,s in ipairs(results.slots) do
    f:write("  { ")
    for k,v in pairs(s) do
      f:write(k.."='"..v.."', ")
    end
    f:write("  },\n")
  end
  f:write("},},\n")
  f:close()
end

local function UpdateHistory(filename)
  -- parse results
  local key,res = ParseResults(filename)
  if (key and res) then
    -- append to proper statistics file
    local standings = LoadStats(key)
    local numraces = #standings
    if (numraces == 0 or standings[numraces].timestring ~= res.timestring) then
      AppendStats(key, res)
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
if (false) then
  RegenerateStatsHTML()
  return 
end

frame = nil
timer = nil

function main()
  -- create the frame window
  frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "R3E Open Championship (c) by Christoph Kubisch",
                      wx.wxDefaultPosition, wx.wxSize(400+16,280),
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
  
  local function checkUpdate()
    local newmod = GetFileModTime(resultfile)
    if (newmod and oldmod and oldmod:IsEarlierThan(newmod)) then
      oldmod = newmod
      UpdateHistory(resultfile)
    end
  end
  
  local splitter = wx.wxSplitterWindow(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(400+16,280))
  splitter:SetMinimumPaneSize(50) -- don't let it unsplit
  splitter:SetSashGravity(0)
  frame.splitter = splitter
  
  local win = wx.wxWindow(splitter, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(400+16,140) )
  frame.win = win
  
  local txtlog  = wx.wxTextCtrl(splitter, wx.wxID_ANY, "",
                  wx.wxPoint(0,140), wx.wxSize(400+16,100),
                  wx.wxTE_MULTILINE+wx.wxTE_DONTWRAP+wx.wxTE_READONLY)
  frame.txtlog = txtlog
  
  printlog = function(...)
    local args = {...}
    local argstring = table.concat({...},"\t")
    txtlog:AppendText(argstring.."\n")
  end
  
  printlog(string.format("init completed, minracetime %d mins, checkrate %d mins", minracetime, checkrate )) 
  
  splitter:SplitHorizontally(win, txtlog, 0)
  
  local label = wx.wxStaticText(win, wx.wxID_ANY, "R3E results found:\n"..resultfile, wx.wxPoint(8,8), wx.wxSize(400,50) )
  local line  = wx.wxStaticLine(win, wx.wxID_ANY, wx.wxPoint(8,60), wx.wxSize(400-16,-1))
  local s = 70
  local bw,bh = 200,20
  local tglpoll     = wx.wxCheckBox(win, wx.wxID_ANY, "Check automatically", wx.wxPoint(8,s), wx.wxSize(bw-16,bh))
  local btncheck    = wx.wxButton(win, wx.wxID_ANY, "Check now", wx.wxPoint(8+bw,s), wx.wxSize(bw-16,bh))
  local btnrebuild  = wx.wxButton(win, wx.wxID_ANY, "Rebuild All HTML Stats", wx.wxPoint(8,s+30), wx.wxSize(bw-16,bh))
  local btnresult   = wx.wxButton(win, wx.wxID_ANY, "Open Result Directory", wx.wxPoint(8+bw,s+30), wx.wxSize(bw-16,bh))
  
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

  win.label = label
  win.line  = line
  win.tglpoll = tglpoll
  win.btncheck = btncheck
  win.btnrebuild = btnrebuild
  win.btnresult = btnresult
  
  UpdateHistory(resultfile)
  
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
