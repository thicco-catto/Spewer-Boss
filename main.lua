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


local function mysplit (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end


local function OnCmd(_, cmd, args)
    args = mysplit(args, " ")

    if cmd == "pro" then
        local projectile = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, Game():GetRoom():GetCenterPos(), Vector.Zero, nil)

        local color = Color(1, 1, 1)
        color:SetColorize(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4]))
        projectile.Color = color
    end
end
Constants.MOD:AddCallback(ModCallbacks.MC_EXECUTE_CMD, OnCmd)