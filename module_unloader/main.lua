-- ============================================================
-- Editable list: add, remove, or modify kernel module names here
-- ============================================================
local MODULES = {
    "oplus_secure_guard_new",
}

-- ============================================================
-- Internal helper functions
-- ============================================================
local function unload_module(name)
    -- Try common rmmod paths; exec starts the program directly without a shell
    local paths = {
        "/system/bin/rmmod",
        "/sbin/rmmod",
        "/usr/bin/rmmod",
    }

    for _, rmmod in ipairs(paths) do
        local result = exec(rmmod, name)
        if result.ok then
            info(string.format("Unloaded module: %s (via %s)", name, rmmod))
            return true
        end
    end

    warn(string.format("Failed to unload module or module not present: %s", name))
    return false
end

local function unload_all()
    for _, module in ipairs(MODULES) do
        unload_module(module)
    end
end

-- ============================================================
-- Background daemon callback: runs once every 30 minutes
-- ============================================================
local function daemon_tick()
    info("Background check: scanning module list")
    unload_all()
    info("Background check: this round finished")
end

-- ============================================================
-- Lifecycle callbacks
-- ============================================================

-- Earliest execution stage: unload once immediately during post-fs-data
local function post_fs_data()
    info("post_fs_data: running the first module unload round")
    unload_all()
end

-- Service stage: start the background daemon with a 1800-second interval (30 minutes)
local function service()
    info("service: starting background daemon task with a 1800-second interval")
    local ok = start_daemon("daemon_tick", 1800)
    if not ok then
        warn("Failed to start background daemon task")
    end
end

-- Optional: manually trigger one check through a plugin action
local function action()
    info("Manual trigger: running one module unload round")
    unload_all()
end

-- ============================================================
-- The entry point must return a table; callbacks are functions in it
-- ============================================================
return {
    post_fs_data = post_fs_data,
    service = service,
    action = action,
    daemon_tick = daemon_tick,
}