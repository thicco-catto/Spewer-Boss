local SpewerBehaviour = {}
local Constants
local game = Game()


local rainingProjectilesPositions = {}


local function GetSpewerPillAnimFromNumber(currentForm, num)
    if currentForm == Constants.SPEWER_BOSS_FORMS.DEFAULT then
        if num == 0 then
            return "RedPill"
        else
            return "WhitePill"
        end
    elseif currentForm == Constants.SPEWER_BOSS_FORMS.RED_PILLED then
        if num == 0 then
            return "GreenPill"
        else
            return "WhitePill"
        end
    else
        if num == 0 then
            return "RedPill"
        else
            return "GreenPill"
        end
    end
end


---@param pos Vector
---@return EntityPlayer
local function GetClosestPlayer(pos)
    local minDistance = math.maxinteger
    local closestPlayer = nil

    for i = 0, game:GetNumPlayers() - 1, 1 do
        local player = game:GetPlayer(i)
        local distance = pos:DistanceSquared(player.Position)

        if distance < minDistance then
            minDistance = distance
            closestPlayer = player
        end
    end

    return closestPlayer
end


---@param spewer EntityNPC
function SpewerBehaviour:OnSpewerInit(spewer)
    spewer:GetSprite():Play("Appear", true)
    spewer:GetData().SpewerForm = Constants.SPEWER_BOSS_FORMS.DEFAULT
end


---@param spewer EntityNPC
---@param spewerSprite Sprite
---@param spewerData table
local function OnSpewerAppear(spewer, spewerSprite, spewerData)
    if not spewerSprite:IsFinished("Appear") then return end

    spewer.State = NpcState.STATE_IDLE
    spewerSprite:Play("Idle", true)
    spewer.StateFrame = Constants.SPEWER_BOSS_JUMP_COUNTDOWN
    spewerData.JumpsLeft = 1
end


---@param spewer EntityNPC
---@param spewerSprite Sprite
---@param spewerData table
local function OnSpewerIdle(spewer, spewerSprite, spewerData)
    if spewer.StateFrame > 0 then
        spewer.StateFrame = spewer.StateFrame - 1
        return
    end

    if spewerData.JumpsLeft > 0 then
        spewerData.JumpsLeft = spewerData.JumpsLeft - 1
        local closestPlayer = GetClosestPlayer(spewer.Position)

        spewer.V2 = (closestPlayer.Position - spewer.Position):Normalized()
        spewer.State = NpcState.STATE_MOVE
        spewerSprite:Play("Jump", true)
    elseif spewer.I1 == 3 then
        local rng = spewer:GetDropRNG()
        local chosenPill = rng:RandomInt(2)

        local pillAnim = GetSpewerPillAnimFromNumber(spewerData.SpewerForm, chosenPill)
        spewerSprite:Play(pillAnim, true)

        spewer.I1 = 0
        spewer.State = NpcState.STATE_SPECIAL
    else
        spewer.I1 = spewer.I1 + 1
        spewer.State = NpcState.STATE_ATTACK

        spewerSprite:Play("Spit", true)
    end
end


---@param spewer EntityNPC
---@param spewerSprite Sprite
---@param spewerData table
local function OnSpewerJump(spewer, spewerSprite, spewerData)
    if spewerSprite:IsFinished("Jump") then
        spewerSprite:Play("JumpLoop", true)
    end

    if spewerSprite:IsFinished("JumpLoop") then
        spewerSprite:Play("JumpDown", true)
    end

    if spewerSprite:IsFinished("JumpDown") then
        spewerSprite:Play("JumpLand")
    end

    if spewerSprite:IsPlaying("JumpLand") or spewerSprite:IsPlaying("JumpDown") then
        spewer.Velocity = spewer.Velocity - spewer.Velocity:Normalized() * 0.3
        return
    end

    if spewerSprite:IsFinished("JumpLand") then
        spewer.State = NpcState.STATE_IDLE
        spewerSprite:Play("Idle", true)
        spewer.StateFrame = Constants.SPEWER_BOSS_JUMP_COUNTDOWN

        spewer.Velocity = Vector.Zero

        return
    end

    ---@diagnostic disable-next-line: assign-type-mismatch
    spewer.Velocity = spewer.V2 * Constants.SPEWER_BOSS_JUMP_VELOCITY
end


local function ShootGreenProjectile(spewer)
    local closestPlayer = GetClosestPlayer(spewer.Position)

    local params = ProjectileParams()

    params.BulletFlags = ProjectileFlags.ACID_GREEN | ProjectileFlags.EXPLODE
    params.Color = Color(0.5, 0.9, 0.4)
    params.Variant = ProjectileVariant.PROJECTILE_TEAR
    --For lobbed shots
    params.FallingAccelModifier = 0.7
    params.FallingSpeedModifier = -10

    local velocity = (closestPlayer.Position - spewer.Position):Normalized() * 8
    spewer:FireProjectiles(spewer.Position, velocity, 0, params)
end


local function ShootBigRedProjectile(spewer)
    local closestPlayer = GetClosestPlayer(spewer.Position)

    local params = ProjectileParams()

    params.BulletFlags = ProjectileFlags.RED_CREEP | ProjectileFlags.ACID_RED
    params.Scale = 2.5

    local velocity = (closestPlayer.Position - spewer.Position):Normalized() * 8
    spewer:FireProjectiles(spewer.Position, velocity, 0, params)
end


---@param spewer EntityNPC
local function ShootWhiteVomitProjectiles(spewer)
    local closestPlayer = GetClosestPlayer(spewer.Position)

    local params = ProjectileParams()

    local projectileSeed = spewer:GetDropRNG():Next()
    local rng = RNG()
    rng:SetSeed(projectileSeed, 35)

    params.Scale = 1 + (rng:RandomFloat() * 0.8 - 0.4)
    params.Color = Color(1, 1, 1, 1, 1, 1, 1)
    --For lobbed shots
    params.FallingAccelModifier = 0.7 + (rng:RandomFloat() * 0.2 - 0.1)
    params.FallingSpeedModifier = -10 + (rng:RandomFloat() * 2 - 1)

    local randomDirection = Vector(rng:RandomFloat() * 2 - 1, rng:RandomFloat() * 2 - 1)
    local randomDirection2 = Vector(rng:RandomFloat() * 2 - 1, rng:RandomFloat() * 2 - 1)

    ---@type Vector
    ---@diagnostic disable-next-line: assign-type-mismatch
    local targetPosition = closestPlayer.Position + randomDirection * 40

    ---@type Vector
    ---@diagnostic disable-next-line: assign-type-mismatch
    local spawningPos = spewer.Position + Vector(0, 10) + randomDirection2 * 20

    local velocity = (targetPosition - spawningPos):Normalized() * 8
    spewer:FireProjectiles(spawningPos, velocity, 0, params)

end


---@param spewer EntityNPC
---@param spewerSprite Sprite
---@param spewerData table
local function OnSpewerAttack(spewer, spewerSprite, spewerData)
    if spewerSprite:IsFinished("Spit") then
        spewer.State = NpcState.STATE_IDLE
        spewerSprite:Play("Idle", true)
        spewer.StateFrame = Constants.SPEWER_BOSS_JUMP_COUNTDOWN

        if spewerData.SpewerForm == Constants.SPEWER_BOSS_FORMS.RED_PILLED then
            spewerData.JumpsLeft = 2
        else
            spewerData.JumpsLeft = 1
        end
    end

    if spewerSprite:IsEventTriggered("Shoot") then
        if spewerData.SpewerForm == Constants.SPEWER_BOSS_FORMS.DEFAULT then
            ShootGreenProjectile(spewer)
        elseif spewerData.SpewerForm == Constants.SPEWER_BOSS_FORMS.RED_PILLED then
            ShootBigRedProjectile(spewer)
        else
            spewerSprite:Play("SpitLoop", true)
            spewer.I2 = Constants.WHITE_ATTACK_DURATION
        end
    end

    if spewerSprite:IsPlaying("SpitLoop") then
        ShootWhiteVomitProjectiles(spewer)

        spewer.I2 = spewer.I2 - 1

        if spewer.I2 == 0 then
            spewerSprite:SetFrame("Spit", 18)
        end
    end
end


---@param spewer EntityNPC
---@param spewerSprite Sprite
---@param spewerData table
local function OnSpewerPill(spewer, spewerSprite, spewerData)
    if spewerSprite:IsFinished("WhitePill") then
        spewerSprite:Load("gfx/whitespewer.anm2", true)
        spewerSprite:Play("Appear")
        spewerData.SpewerForm = Constants.SPEWER_BOSS_FORMS.WHITE_PILLED
    elseif spewerSprite:IsFinished("RedPill") then
        spewerSprite:Load("gfx/redspewer.anm2", true)
        spewerSprite:Play("Appear")
        spewerData.SpewerForm = Constants.SPEWER_BOSS_FORMS.RED_PILLED
    elseif spewerSprite:IsFinished("GreenPill") then
        spewerSprite:Load("gfx/spewer.anm2", true)
        spewerSprite:Play("Appear")
        spewerData.SpewerForm = Constants.SPEWER_BOSS_FORMS.DEFAULT
    end

    if spewerSprite:IsFinished("Appear") then
        spewerSprite:Play("Idle")
        spewer.State = NpcState.STATE_IDLE
        spewer.StateFrame = Constants.SPEWER_BOSS_JUMP_COUNTDOWN

        if spewerData.Form == Constants.SPEWER_BOSS_FORMS.RED_PILLED then
            spewerData.JumpsLeft = 2
        else
            spewerData.JumpsLeft = 1
        end
    end
end


---@param spewer EntityNPC
function SpewerBehaviour:OnSpewerUpdate(spewer)
    local spewerSprite = spewer:GetSprite()
    local spewerData = spewer:GetData()

    if spewer.State == NpcState.STATE_INIT then
        OnSpewerAppear(spewer, spewerSprite, spewerData)
    elseif spewer.State == NpcState.STATE_IDLE then
        OnSpewerIdle(spewer, spewerSprite, spewerData)
    elseif spewer.State == NpcState.STATE_MOVE then
        OnSpewerJump(spewer, spewerSprite, spewerData)
    elseif spewer.State == NpcState.STATE_ATTACK then
        OnSpewerAttack(spewer, spewerSprite, spewerData)
    elseif spewer.State == NpcState.STATE_SPECIAL then
        OnSpewerPill(spewer, spewerSprite, spewerData)
    end
end


---@param projectile EntityProjectile
function SpewerBehaviour:OnProjectileInit(projectile)
    if projectile.SpawnerType ~= Constants.SPEWER_BOSS_TYPE then return end

    projectile:GetData().SpewerForm = projectile.SpawnerEntity:GetData().SpewerForm

    if projectile:GetData().SpewerForm == Constants.SPEWER_BOSS_FORMS.RED_PILLED then
        projectile.FallingAccel = -0.1
        projectile.FallingSpeed = 0
    end
end


---@param projectile EntityProjectile
function SpewerBehaviour:OnProjectileRemoved(projectile)
    if projectile:GetData().IsRedSpewerSplitProjectile then
        local closestPlayer = GetClosestPlayer(projectile.Position)
        local projectileSpeed = (closestPlayer.Position - projectile.Position):Normalized() * 10

        local leperProjectile = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, projectile.Position, projectileSpeed, nil)
        leperProjectile = leperProjectile:ToProjectile()

        leperProjectile.Color = Color(1, 1, 1, 1, 0.3, 0, 0)
        leperProjectile:AddProjectileFlags(ProjectileFlags.RED_CREEP)
    end

    if projectile.SpawnerType ~= Constants.SPEWER_BOSS_TYPE then return end

    local data = projectile:GetData()
    if data.SpewerForm == Constants.SPEWER_BOSS_FORMS.DEFAULT then
        table.insert(rainingProjectilesPositions, {center = projectile.Position, frames = Constants.RAINING_PROJECTILES_FRAMES, rng = projectile:GetDropRNG()})
    elseif data.SpewerForm == Constants.SPEWER_BOSS_FORMS.RED_PILLED then
        for x = -1, 1, 1 do
            for y = -1, 1, 1 do
                if x ~= 0 and y ~= 0 then
                    local projectileDirection = Vector(x, y)
                    local projectileSpeed = projectileDirection * 4

                    local splitProjectile = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, projectile.Position, projectileSpeed, nil)
                    splitProjectile = splitProjectile:ToProjectile()
                    splitProjectile:AddScale(1.3)
                    splitProjectile:GetData().IsRedSpewerSplitProjectile = true

                    splitProjectile:AddFallingAccel(1)
                    splitProjectile:AddFallingSpeed(-10)
                end
            end
        end
    elseif data.SpewerForm == Constants.SPEWER_BOSS_FORMS.WHITE_PILLED then
        if projectile:GetDropRNG():RandomInt(100) < 75 then
            local whiteCreep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_WHITE, 0, projectile.Position, Vector.Zero, nil)
            whiteCreep = whiteCreep:ToEffect()

            whiteCreep.Timeout = whiteCreep.Timeout * 2
        end
    end
end


function SpewerBehaviour:OnFrameUpdate()
    local rainingProjectilePositionWithFrames = {}

    for _, rainingProjectilePosition in ipairs(rainingProjectilesPositions) do
        if game:GetFrameCount() % 4 == 0 then
            ---@type RNG
            local rng = rainingProjectilePosition.rng
            local randomDirection = Vector(rng:RandomFloat() * 2 - 1, rng:RandomFloat() * 2 - 1)

            ---@type Vector
            ---@diagnostic disable-next-line: assign-type-mismatch
            local spawningPos = rainingProjectilePosition.center + randomDirection * Constants.RAINING_PROJECTILES_AREA
            local room = game:GetRoom()
            spawningPos = room:GetClampedPosition(spawningPos, 1)

            local projectile = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, spawningPos, Vector.Zero, nil)
            projectile = projectile:ToProjectile()

            projectile:AddHeight(-600)
            projectile:AddFallingAccel(3)
        end

        rainingProjectilePosition.frames = rainingProjectilePosition.frames - 1

        if rainingProjectilePosition.frames > 0 then
            table.insert(rainingProjectilePositionWithFrames, rainingProjectilePosition)
        end
    end

    rainingProjectilesPositions = rainingProjectilePositionWithFrames
end


function SpewerBehaviour:OnNewRoom()
    rainingProjectilesPositions = {}
end


function SpewerBehaviour:AddCallbacks(constants)
    Constants = constants

    Constants.MOD:AddCallback(ModCallbacks.MC_POST_NPC_INIT, SpewerBehaviour.OnSpewerInit, Constants.SPEWER_BOSS_TYPE)
    Constants.MOD:AddCallback(ModCallbacks.MC_NPC_UPDATE, SpewerBehaviour.OnSpewerUpdate, Constants.SPEWER_BOSS_TYPE)

    Constants.MOD:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, SpewerBehaviour.OnProjectileInit)
    Constants.MOD:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, SpewerBehaviour.OnProjectileRemoved, EntityType.ENTITY_PROJECTILE)

    Constants.MOD:AddCallback(ModCallbacks.MC_POST_UPDATE, SpewerBehaviour.OnFrameUpdate)
    Constants.MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, SpewerBehaviour.OnNewRoom)
end

return SpewerBehaviour