-- Copyright (C) 2014-2017 Jian Chang <aa65535@live.com>
-- Copyright (C) 2020-2021 honwen <https://github.com/honwen>
-- Licensed to the public under the GNU General Public License v3.

module("luci.controller.xray", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/xray") then
		return
	end

	entry({"admin", "services", "xray"},
		alias("admin", "services", "xray", "general"),
		_("Xray"), 10).dependent = true

	entry({"admin", "services", "xray", "general"},
		cbi("xray/general"),
		_("General Settings"), 10).leaf = true

	entry({"admin", "services", "xray", "status"},
		call("action_status")).leaf = true

	entry({"admin", "services", "xray", "servers"},
		arcombine(cbi("xray/servers"), cbi("xray/servers-details")),
		_("Servers Manage"), 20).leaf = true

	if luci.sys.call("command -v xray >/dev/null") ~= 0 then
		return
	end

	entry({"admin", "services", "xray", "access-control"},
		cbi("xray/access-control"),
		_("Access Control"), 30).leaf = true

	entry({"admin", "services", "xray", "log"},
		call("action_log"),
		_("System Log"), 90).leaf = true

	if luci.sys.call("command -v /etc/init.d/dnsmasq-extra >/dev/null") ~= 0 then
		return
	end

	entry({"admin", "services", "xray", "gfwlist"},
		call("action_gfw"),
		_("GFW-List"), 60).leaf = true

	entry({"admin", "services", "xray", "custom"},
		cbi("xray/gfwlist-custom"),
		_("Custom-List"), 50).leaf = true

end

local function is_running(name)
	return luci.sys.call("pgrep -f '%s' >/dev/null" %{name}) == 0
end

function action_status()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		xray_status = is_running("bin/xray"),
	})
end

function action_log()
	local conffile = "/var/log/xray_watchdog.log"
	local watchdog = nixio.fs.readfile(conffile) or ""
	luci.template.render("xray/plain", {content=watchdog})
end

function action_gfw()
	local conffile = "/etc/dnsmasq-extra.d/gfwlist"
	local gfwlist = nixio.fs.readfile(conffile) or luci.sys.exec("cat %s.gz | gunzip -c" %{conffile}) or ""
	luci.template.render("xray/plain", {content=gfwlist})
end
