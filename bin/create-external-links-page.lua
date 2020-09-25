#!/usr/local/bin/lua


package.path = package.path .. ';/home/gemini/toledoweather/GeminiToledoWXLua/lib/?.lua'

local config = require "config"
local page   = require "page"

page.set_template_name("links");

-- page.set_template_variable("basic_page", true);

local gmi_output = page.get_output("External Links")

local output_filename =  config.get_value_for("gmidir") .. config.get_value_for("wx_links_output_file")

local o = assert(io.open(output_filename, "w"))

o:write(gmi_output)

o:close()
