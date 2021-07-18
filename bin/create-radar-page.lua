#!/usr/local/bin/lua

local http  = require "socket.http"
local ltn12 = require "ltn12"
local io    = require "io"

package.path = package.path .. ';/home/gemini/toledoweather/GeminiToledoWXLua/lib/?.lua'

local config = require "config"
local page   = require "page"
local utils  = require "utils"


function download_gif(gif_file, url)

    local imagedir = config.get_value_for("imagedir")

    local local_radar_file_name = imagedir .. gif_file

    if ( string.match(local_radar_file_name, '^[a-zA-Z0-9/.%-_]+$') == nil ) then
        error("Bad filename " .. local_radar_file_name .. ".")
    end

    local bincontent = {}

    local status_code, headers, status_string

    bincontent, status_code, headers, status_string = utils.get_web_page(url)

    if ( status_code == 200 ) then
--        bincontent = table.concat(bincontent)
        local o = assert(io.open(local_radar_file_name, "wb"))
        o:write(bincontent)
        o:close()
    else 
        error("Failed to download gif file.")
    end
end


---------------------------------------

-- in december 2020, the nws ended support for these simple, useful animated images in favor of a clunky, bloated radar mess.
-- download_gif("dtx-loop.gif", "https://radar.weather.gov/ridge/lite/N0R/DTX_loop.gif")
-- download_gif("iwx-loop.gif", "https://radar.weather.gov/ridge/lite/N0R/IWX_loop.gif")

-- in june 2021, dupage ended support for these wonderful static gif radar images.
-- download_gif("in-oh-radar.gif", "https://climate.cod.edu/data/satellite/1km/Indiana_Ohio/current/Indiana_Ohio.rad.gif")
-- download_gif("mi-radar.gif", "http://climate.cod.edu/data/satellite/1km/Michigan/current/Michigan.rad.gif")

download_gif("det-pon-nws.gif", "https://radar.weather.gov/ridge/lite/KDTX_loop.gif")
download_gif("n-in-nws.gif",    "https://radar.weather.gov/ridge/lite/KIWX_loop.gif")

page.set_template_name("radar");

-- page.set_template_variable("back_and_refresh", true)

-- page.set_template_variable("refresh_button_url", config.get_value_for("radar_home_page"))

local gmi_output = page.get_output("Radar")

local output_filename =  config.get_value_for("gmidir") .. config.get_value_for("wx_radar_output_file")

local o = assert(io.open(output_filename, "w"))

o:write(gmi_output)

o:close()
