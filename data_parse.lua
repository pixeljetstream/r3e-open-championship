local cjson = require("cjson")

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

local function parseAssetIcons(filename)
  local f = io.open(filename,"rt")
  local str = f:read("*a")
  f:close()

  local icons = {}
  for url,key in str:gmatch('image="(.-)">%s*(.-)<') do
    icons[key] = url
  end
  
  -- manual car icon patches
  icons["Mercedes-AMG GT3 2020"] = icons["Mercedes AMG GT3 Evo"]
  icons["BMW M4 DTM 2020e"] = icons["BMW M4 DTM 2020"]
  icons["Porsche 911 GT3 R"] = icons["Porsche 911 GT3 R (2019)"]
  icons["AMG-Mercedes C-Klasse DTM 2005"] = icons["AMG-Mercedes C-Klasse DTM"]
  icons["Audi RS 5 DTM 2020e"] = icons["Audi RS 5 DTM 2020"]
  icons["Lynk & Co 03 TCR"] = icons["Lynk &amp; Co 03 TCR"]
  icons["E36 V8 JUDD"] = icons["134 Judd V8"]
  icons["AMG-Mercedes CLK DTM 2003"] = icons["AMG-Mercedes CLK DTM"]
  icons["Mercedes-AMG C 63 DTM"] = icons["Mercedes-AMG C63 DTM"]
  icons["BMW M3 DTM "] = icons["BMW M3 DTM"]
  icons["Mercedes-AMG C 63 DTM 2015"] = icons["Mercedes-AMG C63 DTM"]
  icons["AMG-Mercedes 190 E 2.5-16 Evolution II 1992"] = icons["Mercedes 190E Evo II DTM"]
  icons["Porsche 911 GT3 Cup Endurance"] = icons["Porsche 911 GT3 Cup"]

  return icons
end

local json  = parseJson("r3e-data.json")
local icons = parseAssetIcons("assets.txt")

if (false) then
  for id,v in pairs(json.cars) do
    if (not icons[v.Name]) then
      print('--icons["'..v.Name..'"] = icons["????"]')
    end
  end
end

if (true) then
  local tracks = {}
  local maxl = 0

  for id,v in pairs(json.tracks) do
    for _,layout in pairs(v.layouts) do
      local name = v.Name.." - "..layout.Name
      maxl = math.max(string.len(name),maxl)
      table.insert(tracks, {name, tonumber(layout.MaxNumberOfVehicles), layout.Id, v.Name, layout.Name})
    end
  end

  table.sort(tracks, function(a,b) return a[2] == b[2] and a[1] > b[1] or a[2] > b[2] end)

  local function pad(str)
    return str..string.rep(" ", maxl - string.len(str))
  end

  print ("Max | "..pad("Track")..        " | Class Id")
  print ("----|-"..string.rep("-",maxl).."-|---------")
  for i,v in ipairs(tracks) do
    print(string.format("%3d | ",v[2])..pad(v[1]).." | "..v[3])
  end
  
  local function short(str)
    local ret = ""
    for first in str:gmatch("(%w)%w+") do
      ret = ret..first
    end
    return ret
  end
  
  if (true) then
    table.sort(tracks, function(a,b) return a[1] < b[1] end)
    for i,v in ipairs(tracks) do
      print('["'..v[3]..'"] = { track= "'..v[4]..'",   layout="'..v[5]..'", short="'..short(v[5])..'"},')
    end
  end
end


