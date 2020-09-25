#!/usr/local/bin/lua

-- fetch-flash-briefing-gmi.lua
--
-- created in 2019 as fetch-flash-briefing.lua.
-- modified here on Jun 26, 2020 to output
-- a basic Markdown-like file to use with 
-- my Gemini site.


local https = require "ssl.https"
local http  = require "socket.http"
local cjson = require "cjson"


function trim_spaces (str)
    if (str == nil) then
        return nil
    end
   
    -- remove leading spaces 
    str = string.gsub(str, "^%s+", "")

    -- remove trailing spaces.
    str = string.gsub(str, "%s+$", "")

    return str
end



function fetch_url(url)
    local body,code,headers,status

    body,code,headers,status = http.request(url)

    if code < 200 or code >= 300 then
        body,code,headers,status = https.request(url)
    end

    if type(code) ~= "number" then
        code = 500
        status = "url fetch failed"
    end

    return body,code,headers,status
end



function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end



function is_numeric(str)
    if ( str == nil ) then
        return false
    end

    local s = string.match(str, '^[0-9]+$')

    if ( s == nil ) then
        return false
    end

    return true
end



--convert this 2018-02-09T18:02:23-05:00 into a better format
function reformat_nws_date_time(str) 

    local hash = {}

    if ( str == nil ) then
        hash["date"]   = "-"
        hash["time"]   = "-"
        hash["period"] = "-"
        return hash
    end

    local months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

    local xdate, xtime = string.match(str, '(.*)T(.*)')

    local hrminsec = split(xtime, '-')

    local time = split(hrminsec[1], ':')

    local hr  = time[1]
    local min = time[2]

    if ( is_numeric(hr) == false ) then
        hash["date"]   = "-"
        hash["time"]   = "-"
        hash["period"] = "-"
        return hash
    end

    local prd = "am"

    hr = tonumber(hr)

    if ( hr > 12 ) then
        prd = "pm"
    end

    if ( hr > 12 ) then
        hr = hr - 12
    end

    if ( hr == 0 ) then
        hr = 12
    end

    local time_str = string.format("%d:%02d", hr, min)

    local yrmonday = split(xdate, '-')

    local date_str = string.format("%s %d, %d", months[tonumber(yrmonday[2])], yrmonday[3], yrmonday[1])

    hash["date"]   = date_str
    hash["time"]   = time_str
    hash["period"] = prd

     return hash
end



function get_forecast()

    -- lucas_county_zone_json file
    local url = "https://forecast.weather.gov/MapClick.php?lat=41.6203&lon=-83.7095&unit=0&lg=english&FcstType=json"

    local content, code, headers, status = fetch_url(url)

    local lua_table = cjson.decode(content)

    local creation_date = lua_table.creationDate


    local forecast_array = {}

    for i=1,#lua_table.data.text do
        forecast_array[i] = lua_table.data.text[i]
    end


    local time_period_array = {}

    for i=1,#lua_table.time.startPeriodName do
        time_period_array[i] = lua_table.time.startPeriodName[i]
    end


    local loop = {}

--    for i=1,#forecast_array do
-- short-term forecast. display only first five 12-hour segments
    for i=1,5 do
        local hash = {}
        hash["period"] = time_period_array[i]
        hash["forecast"] = forecast_array[i]
        hash["forecast"] = string.gsub(hash["forecast"], "mph", "miles per hour")
        loop[i] = hash
    end


    local tmp_hash = reformat_nws_date_time(creation_date)

    creation_date = tmp_hash["date"] .. " "  .. tmp_hash["time"] .. " " .. tmp_hash["period"]

    local forecast_text = "Here is Toledo's short-term forecast as of " .. creation_date .. "\n\n"

    for i=1, #loop do
        forecast_text = forecast_text .. loop[i].period .. " will be " .. loop[i].forecast .. "\n\n"
    end

    return forecast_text
end



----------------------

-- my Toledo WX Lua-based app creates numerous static files, including a JSON file that is used
-- for the Amazon Echo smart home speaker flash briefing.

local json_briefing_url = "http://toledoweather.info/briefing.json"

local json_text, return_code, return_headers, return_status = fetch_url(json_briefing_url)


if return_code >= 300 then
    os.exit("Error: Could not fetch JSON briefing. Status: " .. return_status)
end

local json_table = cjson.decode(json_text)

--[[
json is an array of info.
key "titleText" contains the following values:
  Important Statement
  Current Conditions
  Synopsis
  Forecast
]]



print("# Toledo Weather Briefing\n")
print("## As of: " .. json_table[1].updateDate .. "\n")

    for i=1, #json_table do
        local title_text = json_table[i].titleText
        local main_text  = trim_spaces(json_table[i].mainText)
        if title_text == "Important Statement" then
            print("\n### Statements\n\n" .. main_text .. "\n")
        elseif title_text == "Current Conditions" then
            print("\n### Conditions\n\n" .. main_text .. "\n")
        elseif title_text == "Synopsis" then
            print("\n### Synopsis\n\n" .. main_text .. "\n")
        elseif title_text == "Forecast" then
            -- print("### Forecast\n\n" .. main_text .. "\n")
            print("\n### Forecast\n\n" .. get_forecast()) 
        end
    end
