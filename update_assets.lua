local htmlfilename = "assets_raceroom_leaderboard.html"
local htmlfile     = io.open(htmlfilename, "rt")
if (not htmlfile) then
  print ("error, could not open input file", htmlfilename)
  return
else
  print("reading", htmlfilename)
end
local htmltxt  = htmlfile:read("*a")
htmlfile:close()

local assets = htmltxt:match('(<div data%-type="car_class" title="" class="car_class has%-filter ">.+)<div data%-type="driving_model" title="" class="driving_model has%-filter ">')
if (not assets) then
  print ("error, could not find relevant substring")
  return
else
  print "found substring"
end

assets = assets:gsub(">", ">\n")

local assetsfilename = "assets.txt"
local assetsfile     = io.open(assetsfilename, "wt")
if (not assetsfile) then
  print ("error, could not open output file", assetsfilename)
  return
end

assetsfile:write(assets)
assetsfile:close()

print(assetsfilename, "update completed")