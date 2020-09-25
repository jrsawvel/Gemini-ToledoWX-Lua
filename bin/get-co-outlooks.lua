#!/usr/local/bin/lua


local http  = require "socket.http"
local ltn12 = require "ltn12"
local io    = require "io"

package.path = package.path .. ';/home/gemini/toledoweather/GeminiToledoWXLua/lib/?.lua'

-- my modules
local config = require "config"
local page   = require "page"
local utils  = require "utils"


local gmidir     = config.get_value_for("gmidir")


for ctr=1, 3 do
    local configparam = "day" .. ctr .. "outlookhtml"
    local dayurl      = config.get_value_for(configparam)
    local dayfilename

    local tmp_str = string.match(dayurl, '^.*[/](.*)$')
    if ( tmp_str == nil ) then
        error("Cannot obtain filename from " .. dayurl .. ".")
    end
    dayfilename = gmidir .. tmp_str
    dayfilename = string.gsub(dayfilename, "html", "gmi")

    if ( string.match(dayfilename, '^[a-zA-Z0-9/.-_]+$') == nil ) then
        error("Bad data in first argument for filename.")
    end

    local content = {}

    local status_code, headers, status_string

    content, status_code, headers, status_string = utils.get_web_page(dayurl)

    if ( status_code == 200 ) then
        -- get body as string by concatenating table filled by sink
--        content = table.concat(content)

        local text;

        text = string.match(content, '<pre>(.*)</pre>')
        if ( text == nil ) then
            error("Unable to parse HTML file for " .. configparam .. ".\n")
        end

        text = utils.remove_html(text)
        text = utils.trim_spaces(text)
--        text = utils.newline_to_br(text)
        text = string.lower(text)

        page.set_template_name("convectiveoutlook")
        page.set_template_variable("text", text)
--        page.set_template_variable("back_and_home", true)
--        page.set_template_variable("back_button_url", config.get_value_for("outlook_home_page"))

        local gmi_output = page.get_output("Day " .. ctr .. " Convective Outlook")

        local o = assert(io.open(dayfilename, "w"))
        o:write(gmi_output)
        o:close()
    else
        error("File not downloaded - " .. status_string)
    end
end
