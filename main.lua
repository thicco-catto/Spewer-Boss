if not REPENTANCE then
    print("The Spewer Boss mod needs Repentace to run")
    return
end

if not StageAPI then
    print("The Spewer Boss mod needs StageAPI to run")
    return
end

local function loadFile(loc, ...)
    local _, err = pcall(require, "")
    local modName = err:match("/mods/(.*)/%.lua")
    local path = "mods/" .. modName .. "/"
    return assert(loadfile(path .. loc .. ".lua"))(...)
end

local Constants = loadFile("spewer_boss_scripts/Constants")
local SpewerBehaviour = loadFile("spewer_boss_scripts/SpewerBehaviour")

SpewerBehaviour:AddCallbacks(Constants)