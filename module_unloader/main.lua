-- ============================================================
-- Editable module list: add, remove, or rename modules here
-- ============================================================
local MODULES = {
    "inte",
    "oplus_secure_guard_new",
}

-- rmmod candidate paths, tried in order
local RMMOD_PATHS = {
    "/system/bin/rmmod",
    "/system/xbin/rmmod",
    "/sbin/rmmod",
    "/vendor/bin/rmmod",
    "/usr/bin/rmmod",
}

-- Background re-check interval in seconds (30 minutes)
local CHECK_INTERVAL = 1800

-- Maximum number of dmesg lines written to the log per action call
local DMESG_MAX_LINES = 500

-- ============================================================
-- Helpers
-- ============================================================
local function unload_module(name)
    for _, rmmod in ipairs(RMMOD_PATHS) do
        local called, result = pcall(exec, rmmod, name)
        if called and type(result) == "table" and result.ok then
            info(string.format("Unloaded module: %s (via %s)", name, rmmod))
            return true
        end
    end
    warn(string.format("Failed to unload module or not present: %s", name))
    return false
end

local function unload_all()
    for _, module in ipairs(MODULES) do
        unload_module(module)
    end
end

-- ============================================================
-- Boot callbacks
-- ============================================================

-- Earliest stage: unload once at post-fs-data
local function post_fs_data()
    info("post_fs_data: initial unload round")
    unload_all()
end

-- Service stage: start the background daemon.
-- start_daemon's interval is the wait time after each round returns,
-- so the actual period is CHECK_INTERVAL plus the round's own duration.
local function service()
    info(string.format("service: starting daemon (interval=%ds)", CHECK_INTERVAL))
    local started = start_daemon("check_modules", CHECK_INTERVAL)
    if not started then
        -- Documented: existing same-name daemon, plugin disabled, or
        -- readiness failure may all cause this. Log and continue.
        info("service: daemon not started (already running or unavailable)")
    end
end

-- Daemon body: one finite round, then return so the host can schedule
-- the next round after CHECK_INTERVAL seconds.
local function check_modules()
    info("daemon: periodic check round")
    unload_all()
end

-- ============================================================
-- Action button: run "dmesg | grep secureguard"
-- ============================================================
local function action()
    info("action: running 'dmesg | grep secureguard'")

    -- exec does not go through a shell, so pipes require sh -c.
    -- The command string is fixed, no user input is concatenated.
    local called, result = pcall(exec, "/system/bin/sh", "-c", "dmesg | grep secureguard")
    if not called then
        warn("action: failed to invoke command: " .. tostring(result))
        return
    end

    local stdout = result.stdout or ""

    -- Collect non-empty lines
    local lines = {}
    for line in stdout:gmatch("[^\n]+") do
        lines[#lines + 1] = line
    end

    if #lines > 0 then
        local shown = math.min(#lines, DMESG_MAX_LINES)
        for i = 1, shown do
            info(lines[i])
        end
        if #lines > shown then
            info(string.format(
                "action: truncated, showing %d of %d lines", shown, #lines))
        end
        info(string.format("action: matched %d line(s)", #lines))
        return
    end

    -- No stdout. Distinguish grep-no-match from real errors.
    if result.code == 1 then
        -- grep exits 1 when no line matched; this is not a failure.
        info("action: no matching lines")
    elseif result.ok then
        info("action: no output")
    else
        warn(string.format(
            "action: command failed (code=%s): %s",
            tostring(result.code), result.stderr or ""))
    end
end

return {
    post_fs_data = post_fs_data,
    service = service,
    check_modules = check_modules,
    action = action,
}
