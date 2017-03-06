--- lousy.signal library.
--
-- Mimic the luakit signal api functions for tables.
--
-- @module lousy.signal
-- @author Fabian Streitel &lt;karottenreibe@gmail.com&gt;
-- @author Mason Larobina  &lt;mason.larobina@gmail.com&gt;
-- @copyright 2010 Fabian Streitel, Mason Larobina

local _M = {}

-- Private signal data for objects
local data = setmetatable({}, { __mode = "k" })

local methods = {
    "add_signal",
    "emit_signal",
    "remove_signal",
    "remove_signals",
}

local function get_data(object)
    local d = data[object]
    assert(d, "object isn't setup for signals")
    return d
end

function _M.add_signal(object, signame, func)
    local signals = get_data(object).signals

    -- Check signal name
    assert(type(signame) == "string", "invalid signame type: " .. type(signame))
    assert(string.match(signame, "^[%w_%-:]+$"), "invalid chars in signame: " .. signame)

    -- Check handler function
    assert(type(func) == "function", "invalid handler function")

    -- Add to signals table
    if not signals[signame] then
        signals[signame] = { func, }
    else
        table.insert(signals[signame], func)
    end
end

function _M.emit_signal(object, signame, ...)
    local d = get_data(object)
    local sigfuncs = d.signals[signame] or {}

    msg.debug("emit_signal: %q on %s", signame, tostring(object))

    for _, sigfunc in ipairs(sigfuncs) do
        local ret
        if d.module then
            ret = { sigfunc(...) }
        else
            ret = { sigfunc(object, ...) }
        end
        if ret[1] ~= nil then
            return unpack(ret)
        end
    end
end

-- Remove a signame & function pair.
function _M.remove_signal(object, signame, func)
    local signals = get_data(object).signals
    local sigfuncs = signals[signame] or {}

    for i, sigfunc in ipairs(sigfuncs) do
        if sigfunc == func then
            table.remove(sigfuncs, i)
            -- Remove empty sigfuncs table
            if #sigfuncs == 0 then
                signals[signame] = nil
            end
            return func
        end
    end
end

-- Remove all signal handlers with the given signame.
function _M.remove_signals(object, signame)
    local signals = get_data(object).signals
    signals[signame] = nil
end

function _M.setup(object, module)
    assert(not data[object], "given object already setup for signals")

    data[object] = { signals = {}, module = module }

    for _, fn in ipairs(methods) do
        assert(not object[fn], "signal object method conflict: " .. fn)
        if module then
            local func = _M[fn]
            object[fn] = function (...) return func(object, ...) end
        else
            object[fn] = _M[fn]
        end
    end

    return object
end

return _M

-- vim: et:sw=4:ts=8:sts=4:tw=80
