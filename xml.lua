local function parseargsXML(s)
  local arg = {}
  string.gsub(s, "([%-%w]+)=([\"'])(.-)%2", function (w, _, a)
    arg[w] = a
  end)
  return arg
end
    
local function collectXML(s)
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if not string.find(text, "^%s*$") then
      table.insert(top, text)
    end
    if empty == "/" then  -- empty element tag
      table.insert(top, {label=label, xarg=parseargsXML(xarg), empty=1})
    elseif c == "" then   -- start tag
      top = {label=label, xarg=parseargsXML(xarg)}
      table.insert(stack, top)   -- new level
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..label)
      end
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[#stack].label)
  end
  return stack[1]
end

local function parse(txt)
  local xml = collectXML(txt)
  local function labellink(obj)
    for i,v in ipairs(obj) do
      if (type(v) == "table" and v.label) then
        if (#v == 1 and type(v[1]) == "string") then
          local data = v[1]:gsub("[\r\n]","")
          obj[v.label] = tonumber(data) or data
        else
          obj[v.label] = v
          labellink(v)
        end
      end
    end
  end
  
  labellink(xml)
  return xml
end

local function parsefile(filename)
  local f = io.open(filename,"rt")
  if (not f) then 
    printlog("race file not openable")
    return
  end
  
  local txt = f:read("*a")
  f:close()
  
  return parse(txt)
end

local xml = {
  parse     = parse,
  parsefile = parsefile,
}
return xml