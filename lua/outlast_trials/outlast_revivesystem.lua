survivor = FindMetaTable("Entity")

CreateConVar("outlasttrials_enabled", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable or disable the Outlast Trials Revive System.")
CreateConVar("outlasttrials_bleedout_time", "60", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Time in seconds before a downed player bleeds out and dies.")
CreateConVar("outlasttrials_teamwipe_on_all_downed", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "If all players are downed, everybody dies.")
CreateConVar("outlasttrials_enable_execution", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable or disable the execution mechanic.")
CreateConVar("outlasttrials_player_damage_when_downed", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "If enabled, downed players can take damage.")

function survivor:IsDowned()
    return self:GetNWBool("Outlast_IsDowned", false)
end

function survivor:GetBleedoutTime()
    local bleedoutTime = self:GetNWFloat("Outlast_BleedoutTime", 0)
    local timeLeft = (CurTime() - bleedoutTime)*-1
    return timeLeft
end

function survivor:GetReviveProgress()
    return self:GetNWFloat("Outlast_ReviveProgress", 0)
end

function survivor:IsBeingRevived()
    return self:GetNWBool("Outlast_IsBeingRevived", false)
end

function survivor:IsReviving()
    local target = self:GetNWEntity("Outlast_RevivingTarget", NULL)
    return IsValid(target)
end

function survivor:GetReviveTarget()
    local target = self:GetNWEntity("Outlast_RevivingTarget", NULL)
    if IsValid(target) then
        return target
    end
    return nil
end

function survivor:GetExecutionTarget()
    return self:GetNWEntity("Outlast_ImpostorVictim", NULL)
end

function survivor:GetExecutionKiller()
    return self:GetNWEntity("Outlast_Impostor", NULL)
end

function survivor:IsBeingExecuted()
    local Killer = self:GetExecutionKiller()
    if IsValid(Killer) then
        return true 
    else
        return false
    end
end

function survivor:IsExecuting()
    local victim = self:GetExecutionTarget()
        if IsValid(victim) then
        return true 
    else
        return false
    end
end

function survivor:IsFallingToDowned() 
    return self:GetNWBool("Outlast_IsFalling", false)
end


hook.Add("SetupMove", "zzzzzz_OutlastTrialsReviveSystem_DownedMoveHandler", function(ply, mv, cmd)
    if not GetConVar("outlasttrials_enabled"):GetBool() then return end

    if ply:IsReviving() or ply:IsBeingRevived() or ply:IsExecuting() or ply:IsBeingExecuted() or ply:IsFallingToDowned() then
        mv:SetMaxClientSpeed(0)
        mv:SetMaxSpeed(0)
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetUpSpeed(0)
        mv:SetVelocity(Vector(0, 0, 0))
    end

    if ply:IsDowned() then
        mv:SetMaxSpeed(15)
        mv:SetMaxClientSpeed(15)

        local buttons = mv:GetButtons()
        buttons = bit.band(buttons, bit.bnot(IN_FORWARD))
        buttons = bit.band(buttons, bit.bnot(IN_BACK))
        buttons = bit.band(buttons, bit.bnot(IN_MOVELEFT))
        buttons = bit.band(buttons, bit.bnot(IN_MOVERIGHT))
        buttons = bit.band(buttons, bit.bnot(IN_JUMP))

        mv:SetButtons(buttons)
        
        if mv:KeyDown(IN_JUMP) then
            mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
        end
    end
end)


if SERVER then

    print("[OUTLAST TRIALS] SERVER System Loaded")

    util.AddNetworkString("OutlastTrialsReviveSystem_Notify")
    util.AddNetworkString("OutlastTrials_ForcePosition")

    function survivor:SetDownedState(state)
        self:SetNWBool("Outlast_IsDowned", state)
    end

    function survivor:SetBleedoutTime(time)
        self:SetNWFloat("Outlast_BleedoutTime", time)
    end

    function survivor:SetReviveProgress(progress)
        self:SetNWFloat("Outlast_ReviveProgress", progress)
    end

    function survivor:Revive()
        if not self:IsDowned() then return end
        self:SetDownedState(false)
        self:SetBleedoutTime(0)
        self:SetHealth(25)
        self:SetNoTarget(false)

        self:SetHull(Vector(-16, -16, 0), Vector(16, 16, 72))
        self:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, 36))
    end

    function survivor:ResetDownedState()
        self:SetDownedState(false)
        self:SetBleedoutTime(0)
    end

    function survivor:Down()
        if self:IsDowned() then return end
        self:SetDownedState(true)
        self:SetBleedoutTime(CurTime() + GetConVar("outlasttrials_bleedout_time"):GetFloat())
        self:SetHealth(100)
        self:SetNoTarget(true)

        -- Hull stojącego gracza: Vector(-16,-16,0), Vector(16,16,72)
        self:SetHull(Vector(-16, -16, 0), Vector(16, 16, 20)) 
        self:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, 20))
    end

    function survivor:HandleDownWhenReviving(target)
        target:SetNWEntity("Outlast_Reviver", NULL)
        self:SetNWEntity("Outlast_RevivingTarget", NULL)
        target:SetNWFloat("Outlast_ReviveStartTime", 0)
        target:SetNWBool("Outlast_IsBeingRevived", false)
        self.RevivingTarget = nil
        target.IsFallingToDowned = nil 
        self.IsFallingToDowned = nil

        self:StopSVMultiAnimation()
        target:StopSVMultiAnimation()
    end

    function ResetOutlastReviveFlags(reviver, downed)
        //Setting Entities to NULL
        downed:SetNWEntity("Outlast_Reviver", NULL)
        reviver:SetNWEntity("Outlast_RevivingTarget", NULL)

        //Resetting time and bool
        downed:SetNWFloat("Outlast_ReviveStartTime", 0)
        downed:SetNWBool("Outlast_IsBeingRevived", false)

        //Stopping animations
        reviver:StopSVMultiAnimation()
        downed:StopSVMultiAnimation()

        //Resetting server flags
        reviver.RevivingTarget = nil
        reviver.PlayingReviveAnim = false
        reviver.ReviveSnapped = false
        downed.PlayingGetupAnim = false
    end

    local function RemoveAllOutlastFlags(ply) 
        ply:SetNWEntity("Outlast_Reviver", NULL)
        ply:SetNWEntity("Outlast_RevivingTarget", NULL)
        ply:SetNWFloat("Outlast_ReviveStartTime", 0)
        ply:SetNWBool("Outlast_IsBeingRevived", false)
        ply:SetNWBool("Outlast_IsFalling", false)
        ply:SetNWEntity("Outlast_Impostor", NULL)
        ply:SetNWEntity("Outlast_ImpostorVictim", NULL)
        ply:Freeze(false) -- To prevent player being unable to respawn or use mouse 
        ply:StopSVMultiAnimation()

        ply.RevivingTarget = nil
        ply.PlayingReviveAnim = nil
        ply.ReviveSnapped = nil
        ply.PlayingGetupAnim = nil
        ply.Outlast_IsFallingToDowned = nil
        ply.ExecTarget = nil
        ply.StartedExecution = nil
        ply.StartedExecution = false
        ply.ExecTarget = nil
        ply.ExecStart = nil
        ply.ExecDirection = nil
        ply.ExecTime = nil

        timer.Remove("OutlastPlayerDownAnim_" .. ply:EntIndex()) -- To prevent downing seq when player died mid falling

        //Something broke? KYS! IT'S THAT SIMPLE!
    end

    local function GetExecutionFromView(ply)
        local tr = ply:GetEyeTraceNoCursor()
        if not IsValid(tr.Entity) then return end

        local ent = tr.Entity

        -- Szukamy VICTIM
        if ent:IsPlayer() and ent:IsDowned() then
            local attacker = ent:GetNWEntity("Outlast_Impostor")
            if IsValid(attacker) and attacker.StartedExecution then
                return attacker, ent
            end
        end

        -- Szukamy ATTACKERA
        if ent:IsPlayer() and ent.StartedExecution then
            local victim = ent.ExecTarget
            if IsValid(victim) then
                return ent, victim
            end
        end
    end

    local function InterruptExecution(interrupter, attacker, victim)
        if not (IsValid(attacker) and IsValid(victim)) then return end

        -- Przerwij animacje
        attacker:StopSVMultiAnimation()
        attacker:SetSVAnimation("")

        victim:StopSVMultiAnimation()
        victim:SetSVAnimation("")

        attacker:Freeze(false)
        victim:Freeze(false)
        
        -- Restore movement types
        attacker:SetMoveType(MOVETYPE_WALK)
        victim:SetMoveType(MOVETYPE_WALK)
        
        -- Restore collision groups
        attacker:SetCollisionGroup(attacker.ExecOldCollisionGroup or COLLISION_GROUP_PLAYER)
        victim:SetCollisionGroup(victim.ExecOldCollisionGroup or COLLISION_GROUP_PLAYER)
        
        -- Clear locked positions
        attacker.ExecLockedPos = nil
        attacker.ExecLockedAng = nil
        attacker.ExecOldCollisionGroup = nil
        victim.ExecLockedPos = nil
        victim.ExecLockedAng = nil
        victim.ExecOldCollisionGroup = nil

        -- Odepchnięcie ATTACKERA
        local pushDir = (attacker:GetPos() - interrupter:GetPos())
        pushDir.z = 0
        pushDir:Normalize()

        local phys = attacker:GetPhysicsObject()
        if IsValid(phys) then
            timer.Simple(0.2, function() phys:SetVelocity(pushDir * 1000 + Vector(0,0,150)) end)
        else
            timer.Simple(0.2, function() attacker:SetVelocity(pushDir * 1000 + Vector(0,0,150)) end)
        end
        attacker:ViewPunch(Angle(-10, math.Rand(-5,5), 0))

        -- Reset egzekucji
        attacker.StartedExecution = false
        attacker.ExecTarget = nil
        attacker.ExecStart = nil
        attacker.ExecDirection = nil
        attacker.ExecTime = nil

        attacker:SetNWEntity("Outlast_ImpostorVictim", NULL)
        victim:SetNWEntity("Outlast_Impostor", NULL)

        interrupter.KickedAttacker = true
        timer.Simple(1, function() 
            if IsValid(interrupter) then
                interrupter.KickedAttacker = nil
            end
        end)
        interrupter:SetSVAnimation(OutlastAnims.helper_kick, true)

        attacker:ApplyEffect("Stunned", 3)
        attacker:TakeDamage(5, interrupter, interrupter)
    end



    local function GetApproachDirection(reviver, downed)
        local toReviver = (reviver:GetPos() - downed:GetPos())
        toReviver.z = 0
        toReviver:Normalize()

        local forward = downed:EyeAngles()
        forward.p, forward.r = 0, 0
        forward = forward:Forward()
        local right = downed:EyeAngles()
        right.p, right.r = 0, 0
        right = right:Right()

        local forwardDot = forward:Dot(toReviver)
        local rightDot = right:Dot(toReviver)

        if forwardDot > 0.5 then
            return "front"
        elseif forwardDot < -0.5 then
            return "back"
        elseif rightDot > 0 then
            return "right"
        else
            return "left"
        end
    end


    function survivor:SnapToDownedPosition(target, approachDir, offset, adjust)
        if not IsValid(target) then return end
        if self:GetVelocity():LengthSqr() > 1 then self:SetVelocity(-self:GetVelocity()) end

        approachDir = approachDir or "front"
        offset = offset or 40
        adjust = adjust or 0

        -- inicjalizacja danych snapowania
        if not self.OutlastSnapData then
            self.OutlastSnapData = {
                forward = target:GetForward(),
                right   = target:GetRight(),
                pos     = target:GetPos(),
                time    = CurTime()
            }
        end

        local f = self.OutlastSnapData.forward
        local r = self.OutlastSnapData.right
        local targetPos = self.OutlastSnapData.pos

        -- kierunek główny offsetu
        local mainVec
        if approachDir == "front" then
            mainVec = f
        elseif approachDir == "back" then
            mainVec = -f
        elseif approachDir == "left" then
            mainVec = -r
        elseif approachDir == "right" then
            mainVec = r
        else
            mainVec = f
        end

        local adjustVec
        if approachDir == "front" or approachDir == "back" then
            adjustVec = r
        elseif approachDir == "left" or approachDir == "right" then
            adjustVec = f
        end

        local desiredPos = targetPos + mainVec * offset + adjustVec * adjust
        desiredPos.z = targetPos.z
        self.OutlastDesiredPos = desiredPos

        local lerpSpeed = math.Clamp(FrameTime() * 10, 0, 1)
        local newPos = LerpVector(lerpSpeed, self:GetPos(), desiredPos)
        self:SetPos(newPos)

        local dir = (targetPos - desiredPos)
        dir.z = 0
        if dir:LengthSqr() < 0.001 then
            dir = self:GetForward()
        end
        local lookAng = dir:Angle()
        lookAng.p = 0
        lookAng.r = 0

        local newAng = LerpAngle(lerpSpeed * 1.5, self:GetAngles(), lookAng)
        if not timer.Exists("OutlastRotatePlayerSnapping_" .. self:EntIndex()) then
            timer.Create("OutlastRotatePlayerSnapping_" .. self:EntIndex(), 0.1, 1, function()
                if IsValid(self) then
                    self:SetAngles(newAng)
                    self:SetEyeAngles(newAng)
                end
            end)
        end

        -- cleanup
        local tname = "DesiredPosOutlastCleanUp_" .. self:EntIndex()
        timer.Create(tname, 0.1, 1, function()
            if IsValid(self) then
                self.OutlastSnapData = nil
                self.OutlastDesiredPos = nil
            end
        end)

        -- developer debug overlay
        if GetConVar("developer"):GetInt() >= 1 then
            local points = {
                {pos = targetPos + f * offset, name = "front"},
                {pos = targetPos - f * offset, name = "back"},
                {pos = targetPos - r * offset, name = "left"},
                {pos = targetPos + r * offset, name = "right"},
            }

            for _, p in ipairs(points) do
                debugoverlay.Sphere(p.pos, 6, 1, Color(0,255,0), true)
                debugoverlay.Text(p.pos + Vector(0,0,10), p.name, 1, true)
            end
        end
    end




    function survivor:ResolvePlayerOverlap(target, minDist, tryBoth)
        if not IsValid(target) or not IsValid(self) then return false end
        minDist = minDist or 45

        local posA = self:GetPos()
        local posB = target:GetPos()

        local delta = posA - posB
        local dist = delta:Length()
        if dist >= minDist or dist <= 0.001 then
            return true
        end

        local need = minDist - dist
        local dir = delta:GetNormalized()
        local moveA = dir * (need * (tryBoth and 0.5 or 1))
        local moveB = -dir * (need * (tryBoth and 0.5 or 0))

        local desiredA = posA + moveA
        local mins, maxs = self:OBBMins() * 0.8, self:OBBMaxs() * 0.8

        local tr = util.TraceHull({
            start = posA,
            endpos = desiredA,
            mins = mins,
            maxs = maxs,
            mask = MASK_PLAYERSOLID,
            filter = function(ent) if ent == self or ent == target then return false end return true end
        })

        if not tr.Hit then
            local smooth = LerpVector(FrameTime() * 12, posA, desiredA)
            self:SetPos(smooth)
        else
            local upPos = posA + Vector(0,0,16)
            local trUp = util.TraceHull({
                start = posA,
                endpos = upPos,
                mins = mins,
                maxs = maxs,
                mask = MASK_PLAYERSOLID,
                filter = function(ent) if ent == self or ent == target then return false end return true end
            })
            if not trUp.Hit then
                self:SetPos(LerpVector(FrameTime() * 12, posA, upPos))
            else
                local side = dir:Cross(Vector(0,0,1)):GetNormalized()
                local altPos = posA + side * (need + 8)
                local trAlt = util.TraceHull({
                    start = posA,
                    endpos = altPos,
                    mins = mins,
                    maxs = maxs,
                    mask = MASK_PLAYERSOLID,
                    filter = function(ent) if ent == self or ent == target then return false end return true end
                })
                if not trAlt.Hit then
                    self:SetPos(LerpVector(FrameTime() * 12, posA, altPos))
                end
            end
        end

        if tryBoth and IsValid(target) and target.SetPos then
            local targetDesired = posB + moveB
            local tr2 = util.TraceHull({
                start = posB,
                endpos = targetDesired,
                mins = target:OBBMins() * 0.8,
                maxs = target:OBBMaxs() * 0.8,
                mask = MASK_PLAYERSOLID,
                filter = function(ent) if ent == self or ent == target then return false end return true end
            })
            if not tr2.Hit then
                local smooth2 = LerpVector(FrameTime() * 12, posB, targetDesired)
                target:SetPos(smooth2)
            end
        end

        return true
    end


    function DoRootMotionLerp(ent, sequenceName, duration, steps, invertMovement)
        if not IsValid(ent) then return end

        local seq, seqDur = ent:LookupSequence(sequenceName)
        if seq < 0 then return end

        local ok, deltaPos, deltaAng = ent:GetSequenceMovement(seq, 0, seqDur)
        if not ok then return end

        if invertMovement then
            deltaPos = deltaPos * -1
        end

        local ang = ent:GetAngles()
        local worldDelta =
            ang:Forward() * deltaPos.x +
            ang:Right()   * deltaPos.y +
            ang:Up()      * deltaPos.z

        local perStep     = worldDelta / steps
        local stepTime    = duration / steps

        local timerID = "OutlastRM_" .. ent:EntIndex()

        timer.Create(timerID, stepTime, steps, function()
            if not IsValid(ent) then
                timer.Remove(timerID)
                return
            end

            local startPos = ent:GetPos()
            local targetPos = startPos + perStep

            local mins = ent:OBBMins()
            local maxs = ent:OBBMaxs()
            local tr = util.TraceHull({
                start  = startPos,
                endpos = targetPos,
                mins   = mins,
                maxs   = maxs,
                filter = ent
            })

            if tr.Hit then
                timer.Remove(timerID)
                return
            end

            ent:SetPos(tr.HitPos)
        end)
    end

    function survivor:HandleFallAnimation(dmgpos)
        local ply = self

        local modelAng = ply:GetAngles()
        local forward = modelAng:Forward()
        local right   = modelAng:Right()

        -- kierunek dmg względem gracza (2D)
        local dir = (dmgpos - ply:GetPos())
        dir.z = 0
        dir:Normalize()

        -- Debug
        local startPos = ply:GetPos() + Vector(0,0,50)
        debugoverlay.Line(startPos, startPos + forward * 60, 2, Color(0,255,0), true)
        debugoverlay.Line(startPos, startPos + right * 60,   2, Color(0,0,255), true)
        debugoverlay.Line(startPos, startPos + dir * 60,     2, Color(255,0,0), true)

        -- kąty kierunku
        local angle = math.deg(math.atan2(right:Dot(dir), forward:Dot(dir)))

        local animPrefix

        if angle >= -45 and angle <= 45 then
            animPrefix = "fallbackward"
        elseif angle > 45 and angle < 135 then
            animPrefix = "fallleft"
        elseif angle < -45 and angle > -135 then
            animPrefix = "fallright"
        else
            animPrefix = "fallforward"
        end

        -- tylko centralne starty
        local startAnim = animPrefix .. "_start_center_rootmotion"
        local endAnim = animPrefix .. "_end_notrot"

        if animPrefix == "fallforward" then
            endAnim = animPrefix .. "_end"
        end

        -- wyciąganie z tabeli
        local fStart = OutlastAnims[startAnim]
        local fEnd   = OutlastAnims[endAnim]

        local startSeq, startTime = ply:LookupSequence(fStart)
        local endSeq, endTime     = ply:LookupSequence(fEnd)
        local totalTime = startTime + endTime

        ply:StopSVMultiAnimation() // remove all animations
        ply:SetSVAnimation("") // ensure that animation is cleared
        ply:SetSVMultiAnimation({fStart, fEnd}, true)

        local invertMovement = (animPrefix == "fallright" or animPrefix == "fallleft")
        timer.Simple(0.15, function() DoRootMotionLerp(ply, fStart, startTime, 60, invertMovement) end)

        ply:Freeze(true)

        -- Set downed state 0.3 seconds before animation ends so idle is ready to take over
        return totalTime - 0.3
    end

    local function PlayReviveInterrupt(ply, target, direction, progress)
        if not IsValid(target) then return end

        local ReviveInterruptAnims = {
            front = {low = OutlastAnims.getup_front_interupt_low, high = OutlastAnims.getup_front_interupt_high},
            back  = {low = OutlastAnims.getup_back_interupt_low,  high = OutlastAnims.getup_back_interupt_high},
            left  = {low = OutlastAnims.getup_left_interupt_low,  high = OutlastAnims.getup_left_interupt_high},
            right = {low = OutlastAnims.getup_right_interupt_low, high = OutlastAnims.getup_right_interupt_high},
        }

        local variant = (progress >= 0.5) and "high" or "low"
        local anim = ReviveInterruptAnims[direction][variant]
        --if anim then print ("[Outlast Trials] Playing revive interrupt animation: " .. anim) end

        target:StopSVMultiAnimation()
        target:SetSVAnimation("", true)
        target:SetSVAnimation(anim, true)
    end



    hook.Add("EntityTakeDamage", "OutlastTrialsReviveSystem_DamageDownedHandler", function(ent, dmginfo)
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        if not ent:IsPlayer() then return end

        local ply = ent
        if not ply:Alive() then return end

        local inflictor = dmginfo:GetInflictor()
        local attacker  = dmginfo:GetAttacker()

        local damagePos
        if IsValid(inflictor) then
            damagePos = inflictor:GetPos()
        elseif IsValid(attacker) then
            damagePos = attacker:GetPos()
        else
            damagePos = dmginfo:GetDamagePosition()
        end

        local damage = dmginfo:GetDamage()

        if IsValid(inflictor) and inflictor:GetClass() == "trigger_hurt" then
            return
        end


        -- Gracz ma paść, ale nie jest jeszcze powalony
        if damage >= ply:Health() and not ply:IsDowned() and not ply.Outlast_IsFallingToDowned then
            dmginfo:SetDamage(0)
            ply:SetHealth(1)
            ply.Outlast_IsFallingToDowned = true
            ply:SetNWBool("Outlast_IsFalling", true)
            ply.DamageOwner = attacker
            --ply:Down()

            local timetodown = ply:HandleFallAnimation(damagePos) or 1
            timer.Create("OutlastPlayerDownAnim_" .. ply:EntIndex(), timetodown, 1, function()
                if not IsValid(ply) or not ply:Alive() then return end
                ply:Down()
                ply.Outlast_IsFallingToDowned = nil
                ply:SetNWBool("Outlast_IsFalling", false)
                -- Don't force eye angles - the animation already positioned the player correctly
                hook.Run("Outlast_PlayerDowned", ply, attacker, inflictor)
            end)


            return true
        end

        if ply:IsDowned() and not ply:IsBeingExecuted() and not (ply:GetBleedoutTime() <= 0) then
            if not GetConVar("outlasttrials_player_damage_when_downed"):GetBool() then
                dmginfo:SetDamage(0)
                return true
            end
        end

        if ply.Outlast_IsFallingToDowned then
            return true
        end
    end)


    hook.Add("Think", "OutlastTrialsReviveSystem_Think", function()
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end

        local players = player.GetAll()
        for _, ply in ipairs(players) do
            if ply:IsDowned() then

                if IsValid(ply:GetReviveTarget()) then
                    ply:HandleDownWhenReviving(ply:GetReviveTarget())
                end

                local timeLeft = ply:GetBleedoutTime()
                if timeLeft <= 0 and not (ply:IsBeingRevived() or ply:IsBeingExecuted()) then
                    if not ply.PlayingDeathAnim then
                        ply:SetSVAnimation(OutlastAnims.downeddeath, true)
                        ply:Freeze(true)

                        timer.Create("OutlastPlayerDeathAnim_" .. ply:EntIndex(), 3, 1, function()
                            if IsValid(ply) then
                                ply:SetPos(ply:GetPos() + Vector(0,0,5))
                                ply:TakeDamage(ply:Health(), ply.DamageOwner or game.GetWorld(), ply)
                                ply:Freeze(false)
                                ply.PlayingDeathAnim = false
                            end
                        end)

                        ply.PlayingDeathAnim = true
                    end
                end
            end
        end

        -- Teamwipe on all downed players
        if GetConVar("outlasttrials_teamwipe_on_all_downed"):GetBool() then
            local alivePlayers = {}
            for _, ply in ipairs(players) do
                if ply:Alive() then
                    table.insert(alivePlayers, ply)
                end
            end

            if #alivePlayers == 0 then return end

            local allDowned = true
            for _, ply in ipairs(alivePlayers) do
                if not ply:IsDowned() then
                    allDowned = false
                    break
                end
            end

            if allDowned then
                for _, ply in ipairs(alivePlayers) do
                    if ply:Alive() and ply:IsDowned() and not ply:IsPlayingSVAnimation() and not ply.AllDownedTimerSet then
                        ply:SetBleedoutTime(CurTime() + 0.1)
                        --PrintMessage(HUD_PRINTTALK, "[Outlast Trials] All survivors are downed! Bleedout time accelerated.")
                        timer.Simple(4, function()
                            if IsValid(ply) then
                                ply.AllDownedTimerSet = nil
                            end
                        end)
                        ply.AllDownedTimerSet = true
                    end
                end
            end
        end
    end)


    hook.Add("PlayerDeath", "OutlastTrialsReviveSystem_DeathHandler", function(ply, inflictor, attacker)
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        if ply:IsDowned() then
            ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, 72))
            ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, 36))
            ply:ResetDownedState()
        end
        RemoveAllOutlastFlags(ply) 
        ply.DamageOwner = nil
    end)

    -- Clean up execution/revive states when a player disconnects
    hook.Add("PlayerDisconnected", "OutlastTrialsReviveSystem_DisconnectHandler", function(ply)
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        
        -- If disconnecting player was executing someone, free the victim
        local victim = ply:GetExecutionTarget()
        if IsValid(victim) then
            victim:SetNWEntity("Outlast_Impostor", NULL)
            victim:Freeze(false)
            victim:SetMoveType(MOVETYPE_WALK)
            victim:SetCollisionGroup(victim.ExecOldCollisionGroup or COLLISION_GROUP_PLAYER)
            victim.ExecLockedPos = nil
            victim.ExecLockedAng = nil
            victim.ExecOldCollisionGroup = nil
            victim:StopSVMultiAnimation()
        end
        
        -- If disconnecting player was being executed, free the attacker
        local attacker = ply:GetExecutionKiller()
        if IsValid(attacker) then
            attacker:SetNWEntity("Outlast_ImpostorVictim", NULL)
            attacker:Freeze(false)
            attacker:SetMoveType(MOVETYPE_WALK)
            attacker:SetCollisionGroup(attacker.ExecOldCollisionGroup or COLLISION_GROUP_PLAYER)
            attacker.StartedExecution = false
            attacker.ExecTarget = nil
            attacker.ExecStart = nil
            attacker.ExecDirection = nil
            attacker.ExecTime = nil
            attacker.ExecLockedPos = nil
            attacker.ExecLockedAng = nil
            attacker.ExecOldCollisionGroup = nil
            attacker:StopSVMultiAnimation()
        end
        
        -- If disconnecting player was reviving someone, cancel the revive
        local reviveTarget = ply:GetReviveTarget()
        if IsValid(reviveTarget) then
            ResetOutlastReviveFlags(ply, reviveTarget)
        end
        
        -- If disconnecting player was being revived, cancel the revive
        local reviver = ply:GetNWEntity("Outlast_Reviver", NULL)
        if IsValid(reviver) then
            ResetOutlastReviveFlags(reviver, ply)
        end
        
        RemoveAllOutlastFlags(ply)
    end)

    hook.Add("Think", "OutlastTrialsReviveSystem_DownedThinkHandler", function()
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        for _, ply in pairs(player.GetAll()) do
            if not IsValid(ply) or not ply:Alive() then continue end

            //Reviving Section
            local target = ply:GetEyeTrace().Entity
            if not ply.RevivingTarget and ply:KeyDown(IN_USE) and not ply:IsDowned() and not ply:IsFallingToDowned() and not ply.KickedAttacker and not ply:IsExecuting() and not ply:IsBeingExecuted() then
                if IsValid(target) and target:IsPlayer() and target:IsDowned() and not target:IsFallingToDowned() and not (target:GetBleedoutTime() <= 0 or target:IsBeingExecuted()) then
                    if ply:GetPos():DistToSqr(target:GetPos()) < 10000 then 
                        target:SetNWEntity("Outlast_Reviver", ply)
                        ply:SetNWEntity("Outlast_RevivingTarget", target)
                        target:SetNWFloat("Outlast_ReviveStartTime", CurTime())
                        target:SetNWBool("Outlast_IsBeingRevived", true)
                        local wep = ply:GetActiveWeapon()
                        ply.Outlast_UnequipedWeapon = IsValid(wep) and wep or nil
                        ply:SetActiveWeapon(nil)
                        ply.RevivingTarget = target
                    end
                end
            end

            local ReviveTarget = ply.RevivingTarget
            if ReviveTarget and IsValid(ReviveTarget) and ReviveTarget:IsDowned() then
                -- Cancel revive if target is being executed
                if ReviveTarget:IsBeingExecuted() then
                    local direction = GetApproachDirection(ply, ReviveTarget)
                    local reviveTime = 5
                    local elapsed = CurTime() - ReviveTarget:GetNWFloat("Outlast_ReviveStartTime", CurTime())
                    local progress = math.Clamp(elapsed / reviveTime, 0, 1)
                    PlayReviveInterrupt(ply, ReviveTarget, direction, progress)
                    ResetOutlastReviveFlags(ply, ReviveTarget)
                    if IsValid(ply.Outlast_UnequipedWeapon) then ply:SelectWeapon(ply.Outlast_UnequipedWeapon) end
                elseif ply:KeyDown(IN_USE) then
                    local reviveTime = 5
                    local elapsed = CurTime() - ReviveTarget:GetNWFloat("Outlast_ReviveStartTime", CurTime())
                    local progress = math.Clamp(elapsed / reviveTime, 0, 1)
                    local Direction = GetApproachDirection(ply, ReviveTarget)
                    ReviveTarget:SetReviveProgress(progress)
                    ply:SetEyeAngles(ply:EyeAngles())

                    if not ply.PlayingReviveAnim and not ReviveTarget.PlayingGetupAnim then
                        if Direction == "front" then
                            ply:SetSVMultiAnimation({OutlastAnims.helpup_phase1_front, OutlastAnims.helpup_phase2_front, OutlastAnims.helpup_phase3_front}, true)
                            ReviveTarget:SetSVMultiAnimation({OutlastAnims.getup_phase1_front, OutlastAnims.getup_phase2_front, OutlastAnims.getup_phase3_front}, true)
                        elseif Direction == "back" then
                            ply:SetSVMultiAnimation({OutlastAnims.helpup_phase1_back, OutlastAnims.helpup_phase2_back, OutlastAnims.helpup_phase3_back},  true)
                            ReviveTarget:SetSVMultiAnimation({OutlastAnims.getup_phase1_back, OutlastAnims.getup_phase2_back, OutlastAnims.getup_phase3_back}, true)
                        elseif Direction == "left" then
                            ply:SetSVMultiAnimation({OutlastAnims.helpup_phase1_left, OutlastAnims.helpup_phase2_left, OutlastAnims.helpup_phase3_left},  true)
                            ReviveTarget:SetSVMultiAnimation({OutlastAnims.getup_phase1_left, OutlastAnims.getup_phase2_left, OutlastAnims.getup_phase3_left}, true)
                        elseif Direction == "right" then
                            ply:SetSVMultiAnimation({OutlastAnims.helpup_phase1_right, OutlastAnims.helpup_phase2_right, OutlastAnims.helpup_phase3_right},  true)
                            ReviveTarget:SetSVMultiAnimation({OutlastAnims.getup_phase1_right, OutlastAnims.getup_phase2_right, OutlastAnims.getup_phase3_right}, true)
                        end
                        ply.PlayingReviveAnim = true
                        ReviveTarget.PlayingGetupAnim = true
                    end

                    //Snapping only at the start of the revive (when progress is below 10%)
                    if progress <= 0.1 then
                        if Direction == "front" then
                            ply:SnapToDownedPosition(ReviveTarget, "front", 30)
                        elseif Direction == "back" then
                            ply:SnapToDownedPosition(ReviveTarget, "back", 60)
                        elseif Direction == "left" then
                            ply:SnapToDownedPosition(ReviveTarget, "left", 40, -10)
                        elseif Direction == "right" then
                            ply:SnapToDownedPosition(ReviveTarget, "right", 45, -3)
                        end
                    end

                    //Resolve overlap when close to finishing the revive, so players don't get stuck inside each other
                    if progress >= 0.9 then
                        ply:ResolvePlayerOverlap(ReviveTarget, 45, false)
                    end

                    if progress >= 1 then
                        ReviveTarget:Revive()
                        ResetOutlastReviveFlags(ply, ReviveTarget)
                        if IsValid(ply.Outlast_UnequipedWeapon) then
                            ply:SelectWeapon(ply.Outlast_UnequipedWeapon)
                        end
                        hook.Run("Outlast_PlayerRevived", ply, ReviveTarget)
                    end
                else
                    ResetOutlastReviveFlags(ply, ReviveTarget)
                    ply:ResolvePlayerOverlap(ReviveTarget, 45, false)
                    if IsValid(ply.Outlast_UnequipedWeapon) then ply:SelectWeapon(ply.Outlast_UnequipedWeapon) end

                    local reviver = ply
                    local target = ReviveTarget

                    -- Tylko jeśli target jeszcze leży
                    if IsValid(target) and target:IsDowned() then
                        local direction = GetApproachDirection(reviver, target)

                        -- progress w momencie przerwania
                        local reviveTime = 5
                        local elapsed = CurTime() - target:GetNWFloat("Outlast_ReviveStartTime", CurTime())
                        local progress = math.Clamp(elapsed / reviveTime, 0, 1)

                        PlayReviveInterrupt(reviver, target, direction, progress)
                    end
                end
            end

            if ply:IsDowned() or ply:IsFallingToDowned() then
                ply:SetActiveWeapon(nil)
            end

            // Freeze player when being revived or falling to downed state
            // Don't override freeze state if player is falling (HandleFallAnimation manages that)
            if ply:IsBeingRevived() or ply:IsBeingExecuted() or ply:IsExecuting() then
                ply:Freeze(true)
            elseif not ply:IsFallingToDowned() and not ply.PlayingDeathAnim then
                ply:Freeze(false)
            end

            //Allow player to drain his time by holding ctrl key
            if ply:IsDowned() and ply:KeyDown(IN_DUCK) then
                local bleedoutTime = ply:GetBleedoutTime()
                ply:SetBleedoutTime(CurTime() + bleedoutTime - (FrameTime() * 10))
            end

            if ply:WaterLevel() >= 2 and ply:IsDowned() then
                local bleedoutTime = ply:GetBleedoutTime()
                ply:SetBleedoutTime(CurTime() + bleedoutTime - (FrameTime() * 20))
            end

            //Executions Section
            if GetConVar("outlasttrials_enable_execution"):GetBool() then

                if not ply.ExecTarget and not ply:IsReviving() and not ply:IsExecuting() and not ply:IsBeingRevived() and ply:KeyPressed(IN_RELOAD) and not ply:IsDowned() and not ply:IsFallingToDowned() then
                    local tr = ply:GetEyeTraceNoCursor()
                    local target = tr.Entity
                    
                    if not IsValid(target) or not target:IsPlayer() then continue end
                    
                    local ExecDirection = GetApproachDirection(ply, target)

                    if target:IsDowned() and not target:IsFallingToDowned() and not (target:GetBleedoutTime() <= 0) then
                        if target:GetPos():DistToSqr(ply:GetPos()) < 10000 and not target:IsPlayingSVAnimation() and not target:IsBeingRevived() and not target:IsBeingExecuted() then
                            target:SetNWEntity("Outlast_Impostor", ply)
                            ply:SetNWEntity("Outlast_ImpostorVictim", target) 
                            ply.ExecTarget = target
                            ply.ExecDirection = ExecDirection
                            ply.ExecStart = CurTime()
                            ply.StartedExecution = false
                            local wep = ply:GetActiveWeapon()
                            ply.Outlast_UnequipedWeapon = IsValid(wep) and wep or nil
                            hook.Run("Outlast_PlayerExecuting", ply, target)
                        end
                    end
                end
            end

            local ExecTarget = ply.ExecTarget
            if ExecTarget and IsValid(ExecTarget) then
                -- Cancel execution if target is no longer valid or died
                if not ExecTarget:Alive() or not ExecTarget:IsDowned() then
                    ply:Freeze(false)
                    ply:SetMoveType(MOVETYPE_WALK)
                    ply:SetCollisionGroup(ply.ExecOldCollisionGroup or COLLISION_GROUP_PLAYER)
                    ply:StopSVMultiAnimation()
                    ply.StartedExecution = false
                    ply.ExecTarget = nil
                    ply.ExecStart = nil
                    ply.ExecDirection = nil
                    ply.ExecTime = nil
                    ply.ExecLockedPos = nil
                    ply.ExecLockedAng = nil
                    ply.ExecOldCollisionGroup = nil
                    ply:SetNWEntity("Outlast_ImpostorVictim", NULL)
                    if IsValid(ply.Outlast_UnequipedWeapon) then ply:SelectWeapon(ply.Outlast_UnequipedWeapon) end
                    ply.Outlast_UnequipedWeapon = nil
                elseif not ply.StartedExecution then
                    local dir = ply.ExecDirection
                    local seq
                    local killerseq
                    if dir == "front" then
                        seq = OutlastAnims.victim_front
                        killerseq = OutlastAnims.finisher_front
                    elseif dir == "back" then
                        seq = OutlastAnims.victim_back
                        killerseq = OutlastAnims.finisher_back
                    elseif dir == "left" then
                        seq = OutlastAnims.victim_left
                        killerseq = OutlastAnims.finisher_left                       
                    elseif dir == "right" then
                        seq = OutlastAnims.victim_right
                        killerseq = OutlastAnims.finisher_right                       
                    end

                    ply.ExecSeq, ply.ExecTime = ply:LookupSequence(killerseq)
                    
                    // Disable collision first
                    ply.ExecOldCollisionGroup = ply:GetCollisionGroup()
                    ExecTarget.ExecOldCollisionGroup = ExecTarget:GetCollisionGroup()
                    ply:SetCollisionGroup(COLLISION_GROUP_WEAPON)
                    ExecTarget:SetCollisionGroup(COLLISION_GROUP_WEAPON)
                    
                    // Calculate proper positions based on direction
                    local victimPos = ExecTarget:GetPos()
                    local victimAng = ExecTarget:GetAngles()
                    victimAng.p = 0
                    victimAng.r = 0
                    
                    // Calculate attacker angle - should face toward victim based on direction
                    local attackerAng = Angle(0, 0, 0)
                    if dir == "front" then
                        attackerAng = Angle(0, victimAng.y + 180, 0)
                    elseif dir == "back" then
                        attackerAng = Angle(0, victimAng.y, 0)
                    elseif dir == "left" then
                        attackerAng = Angle(0, victimAng.y - 90, 0)
                    elseif dir == "right" then
                        attackerAng = Angle(0, victimAng.y + 90, 0)
                    end
                    attackerAng:Normalize()
                    
                    // Lock positions - both at victim's position, animations handle visual offset
                    ply.ExecLockedPos = victimPos
                    ply.ExecLockedAng = attackerAng
                    ExecTarget.ExecLockedPos = victimPos
                    ExecTarget.ExecLockedAng = victimAng
                    
                    // Apply positions and freeze before starting animations
                    ply:SetPos(victimPos)
                    ExecTarget:SetPos(victimPos)
                    ply:SetAngles(attackerAng)
                    ply:SetEyeAngles(attackerAng)
                    ExecTarget:SetAngles(victimAng)
                    ExecTarget:SetEyeAngles(victimAng)
                    ply:Freeze(true)
                    ExecTarget:Freeze(true)
                    
                    // Disable movement
                    ply:SetMoveType(MOVETYPE_NONE)
                    ExecTarget:SetMoveType(MOVETYPE_NONE)
                    ply:SetLocalVelocity(Vector(0,0,0))
                    ExecTarget:SetLocalVelocity(Vector(0,0,0))
                    
                    // Force client to update position before animation starts
                    net.Start("OutlastTrials_ForcePosition")
                        net.WriteVector(victimPos)
                        net.WriteAngle(attackerAng)
                    net.Send(ply)
                    
                    net.Start("OutlastTrials_ForcePosition")
                        net.WriteVector(victimPos)
                        net.WriteAngle(victimAng)
                    net.Send(ExecTarget)
                    
                    // Now start animations after positioning is applied
                    // Use the same start time for both to ensure sync
                    local animStartTime = CurTime()
                    
                    ExecTarget:SetNWString("SVAnim", seq)
                    ExecTarget:SetNWFloat("SVAnimDelay", ply.ExecTime)
                    ExecTarget:SetNWFloat("SVAnimStartTime", animStartTime)
                    ExecTarget:SetCycle(0)
                    
                    ply:SetNWString("SVAnim", killerseq)
                    ply:SetNWFloat("SVAnimDelay", ply.ExecTime)
                    ply:SetNWFloat("SVAnimStartTime", animStartTime)
                    ply:SetCycle(0)
                    
                    ply:SetActiveWeapon(nil)
                    ply.StartedExecution = true
                    
                    -- Auto-stop timers
                    timer.Simple(ply.ExecTime, function()
                        if IsValid(ExecTarget) and ExecTarget:GetNWString("SVAnim") == seq then
                            ExecTarget:SetNWString("SVAnim", "")
                        end
                    end)
                    timer.Simple(ply.ExecTime, function()
                        if IsValid(ply) and ply:GetNWString("SVAnim") == killerseq then
                            ply:SetNWString("SVAnim", "")
                        end
                    end)
                else
                    // Keep both players locked to their positions throughout execution
                    if ply.ExecLockedPos and IsValid(ExecTarget) and ExecTarget.ExecLockedPos then
                        -- Force position every frame (both at same position)
                        ply:SetPos(ply.ExecLockedPos)
                        ExecTarget:SetPos(ExecTarget.ExecLockedPos)
                        
                        -- Force angles every frame (attacker faces victim based on direction)
                        if ply.ExecLockedAng then
                            ply:SetAngles(ply.ExecLockedAng)
                            ply:SetEyeAngles(ply.ExecLockedAng)
                        end
                        if ExecTarget.ExecLockedAng then
                            ExecTarget:SetAngles(ExecTarget.ExecLockedAng)
                        end
                        
                        -- Kill any velocity
                        ply:SetLocalVelocity(Vector(0,0,0))
                        ExecTarget:SetLocalVelocity(Vector(0,0,0))
                    end

                    if CurTime() - ply.ExecStart >= (ply.ExecTime or 0) then
                        if IsValid(ExecTarget) and ExecTarget:Alive() and ExecTarget:IsDowned() then
                            ExecTarget:TakeDamage(ExecTarget:GetMaxHealth(), ply, ply)
                        end
                        
                        ply:Freeze(false)
                        ply:SetMoveType(MOVETYPE_WALK)
                        ply:SetCollisionGroup(ply.ExecOldCollisionGroup or COLLISION_GROUP_PLAYER)
                        if IsValid(ExecTarget) then 
                            ExecTarget:Freeze(false) 
                            ExecTarget:SetMoveType(MOVETYPE_WALK)
                            ExecTarget:SetCollisionGroup(ExecTarget.ExecOldCollisionGroup or COLLISION_GROUP_PLAYER)
                            ExecTarget.ExecLockedPos = nil
                            ExecTarget.ExecLockedAng = nil
                            ExecTarget.ExecOldCollisionGroup = nil
                        end
                        ply.StartedExecution = false
                        ply.ExecTarget = nil
                        ply.ExecStart = nil
                        ply.ExecDirection = nil
                        ply.ExecTime = nil
                        ply.ExecLockedPos = nil
                        ply.ExecLockedAng = nil
                        ply.ExecOldCollisionGroup = nil
                        if IsValid(ply.Outlast_UnequipedWeapon) then ply:SelectWeapon(ply.Outlast_UnequipedWeapon) end
                        ply.Outlast_UnequipedWeapon = nil
                        if IsValid(ply) then
                            ply:SetNWEntity("Outlast_ImpostorVictim", NULL)
                        end
                        if IsValid(ExecTarget) then
                            ExecTarget:SetNWEntity("Outlast_Impostor", NULL)
                        end
                    end
                end
            end

            -- === EXECUTION INTERRUPT ===
            if ply:KeyPressed(IN_USE) and not ply:IsDowned() and not ply:IsFallingToDowned() then
                local attacker, victim = GetExecutionFromView(ply)

                if IsValid(attacker) and IsValid(victim) then
                    if ply:GetPos():DistToSqr(attacker:GetPos()) <= 10000 then
                        InterruptExecution(ply, attacker, victim)
                    end
                end
            end
        end

        --[[PROTOTYPE NPC REVIVE SYSTEM]--
        local RegistedReviverNPCs = { 
            ["npc_citizen"] = true,
            ["npc_combine_s"] = true,
            ["npc_metropolice"] = true
        }

        local RegisteredDownedNPCs = { 
            ["npc_citizen"] = true,
            ["npc_combine_s"] = true,
            ["npc_metropolice"] = true,
        }

        local function IsFriend(npc, target)
            local disposition = npc:Disposition(target) or D_NU
            if disposition == D_LI then
                return true
            end
        end
        --NPC AI for Revive
        for _, npc in pairs(ents.GetAll()) do
            if npc:IsNPC() and (RegistedReviverNPCs[npc:GetClass()]) then
                local ReviveTargets = ents.FindInSphere(npc:GetPos(), 1024)

                for _, target in pairs(ReviveTargets) do
                    local NPCReviveTarget = npc.ReviveTarget
                    if !IsValid(NPCReviveTarget) then
                        if (target:IsPlayer() or (npc:IsNPC() and RegisteredDownedNPCs[target:GetClass()])) and target:IsDowned() and IsFriend(npc, target) then
                            npc.ReviveTarget = target
                            PrintMessage(HUD_PRINTTALK, "[Outlast Trials] NPC " .. tostring(npc:GetClass()) .. " has chosen a revive target: " .. tostring(target:GetClass() == "player" and target:Nick() or target:GetClass()))
                        end
                    else
                        local targetPos = NPCReviveTarget:GetPos()
                        local distToTarget = npc:GetPos():DistToSqr(targetPos)

                        if not timer.Exists("NPCReviveDelay_" .. npc:EntIndex()) then
                            timer.Create("NPCReviveDelay_" .. npc:EntIndex(), 3, 1, function()
                                if !IsValid(npc) then return end
                                if IsValid(NPCReviveTarget) then
                                    npc:SetLastPosition(targetPos)
                                    npc:SetSchedule(SCHED_FORCED_GO_RUN)
                                    PrintMessage(HUD_PRINTTALK, "[Outlast Trials] NPC " .. tostring(npc:GetClass()) .. " is moving to revive target.")
                                end
                            end)
                        end

                        local NPCProgress
                        if distToTarget <= 2500 then
                            
                            if not NPCReviveTarget.NPCReviveState then

                                NPCReviveTarget:SetNWFloat("Outlast_ReviveStartTime", CurTime())
                                NPCReviveTarget:SetNWEntity("Outlast_Reviver", npc)
                                NPCReviveTarget:SetNWBool("Outlast_IsBeingRevived", true)

                                npc:SetNWEntity("Outlast_RevivingTarget", NPCReviveTarget)

                                NPCReviveTarget.NPCReviveState = true
                            end

                            if not npc:IsPlayingSVAnimation() and not NPCReviveTarget:IsPlayingSVAnimation() then
                                local ApproachDirection = GetApproachDirection(npc, NPCReviveTarget)
                                if ApproachDirection == "front" then
                                    npc:SetSVMultiAnimation({OutlastAnims.helpup_phase1_front, OutlastAnims.helpup_phase2_front, OutlastAnims.helpup_phase3_front}, true)
                                    NPCReviveTarget:SetSVMultiAnimation({OutlastAnims.getup_phase1_front, OutlastAnims.getup_phase2_front, OutlastAnims.getup_phase3_front}, true)
                                elseif ApproachDirection == "back" then
                                    npc:SetSVMultiAnimation({OutlastAnims.helpup_phase1_back, OutlastAnims.helpup_phase2_back, OutlastAnims.helpup_phase3_back},  true)
                                    NPCReviveTarget:SetSVMultiAnimation({OutlastAnims.getup_phase1_back, OutlastAnims.getup_phase2_back, OutlastAnims.getup_phase3_back}, true)
                                elseif ApproachDirection == "left" then
                                    npc:SetSVMultiAnimation({OutlastAnims.helpup_phase1_left, OutlastAnims.helpup_phase2_left, OutlastAnims.helpup_phase3_left},  true)
                                    NPCReviveTarget:SetSVMultiAnimation({OutlastAnims.getup_phase1_left, OutlastAnims.getup_phase2_left, OutlastAnims.getup_phase3_left}, true)
                                elseif ApproachDirection == "right" then
                                    npc:SetSVMultiAnimation({OutlastAnims.helpup_phase1_right, OutlastAnims.helpup_phase2_right, OutlastAnims.helpup_phase3_right},  true)
                                    NPCReviveTarget:SetSVMultiAnimation({OutlastAnims.getup_phase1_right, OutlastAnims.getup_phase2_right, OutlastAnims.getup_phase3_right}, true)
                                end
                            end

                            local function CancelNPCRevive(npc, target)
                                if not IsValid(target) then return end

                                target.NPCReviveState = nil
                                target:SetNWBool("Outlast_IsBeingRevived", false)
                                target:SetNWEntity("Outlast_Reviver", NULL)
                                target:SetReviveProgress(0)

                                if IsValid(npc) then
                                    npc.ReviveTarget = nil
                                    npc:SetNWEntity("Outlast_RevivingTarget", NULL)
                                end

                                if not IsValid(npc) then 
                                    PrintMessage(HUD_PRINTTALK, "[Outlast Trials] NPC revive cancelled: NPC is no longer valid.")
                                    NPCReviveTarget:SetNWFloat("Outlast_ReviveStartTime", nil)
                                    target:SetNWBool("Outlast_IsBeingRevived", false)
                                    target:SetNWEntity("Outlast_Reviver", NULL)
                                    target:SetReviveProgress(0)
                                end
                            end


                            if !IsValid(npc) then
                                CancelNPCRevive(npc, NPCReviveTarget)
                                return
                            end

                            local reviveTime = 5
                            local startTime = NPCReviveTarget:GetNWFloat("Outlast_ReviveStartTime", 0)

                            local elapsed = CurTime() - startTime
                            local progress = math.Clamp(elapsed / reviveTime, 0, 1)

                            NPCReviveTarget:SetReviveProgress(progress)

                            if progress ~= nil then
                                if progress >= 1 then
                                    NPCReviveTarget:Revive()
                                    NPCReviveTarget.NPCReviveState = nil
                                    npc.ReviveTarget = nil
                                    NPCReviveTarget:SetNWEntity("Outlast_Reviver", NULL)
                                    NPCReviveTarget:SetNWBool("Outlast_IsBeingRevived", false)
                                    NPCReviveTarget:SetReviveProgress(0)
                                    hook.Run("Outlast_PlayerRevived", npc, NPCReviveTarget)
                                end
                            end
                        end
                    end
                end
            end
        end
        ]]--
    end)

    hook.Add("ShouldCollide", "OutlastTrialsReviveSystem_CollisionHandler", function(ent1, ent2)
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        if not IsValid(ent1) or not IsValid(ent2) then return end
        if not ent1:IsPlayer() or not ent2:IsPlayer() then return end

        local ply1 = ent1
        local ply2 = ent2

        -- Check if either player is in any animation state
        local ply1InState = ply1:IsBeingRevived() or ply1:IsReviving() or ply1:IsExecuting() or ply1:IsBeingExecuted() or ply1:IsDowned() or ply1:IsFallingToDowned()
        local ply2InState = ply2:IsBeingRevived() or ply2:IsReviving() or ply2:IsExecuting() or ply2:IsBeingExecuted() or ply2:IsDowned() or ply2:IsFallingToDowned()

        -- Disable collision if either player is in an animation state
        if ply1InState or ply2InState then
            return false
        end
    end)

    //Notifications

    hook.Add("Outlast_PlayerDowned", "OutlastTrialsReviveSystem_NotifyDowned", function(downedPlayer, attacker, inflictor)
        if not IsValid(downedPlayer) then return end

        local attName
        local wepName

        if IsValid(attacker) then

            if attacker:IsPlayer() then
                attName = attacker:Nick()
            else
                attName = GAMEMODE:GetDeathNoticeEntityName(attacker)
            end

            if IsValid(inflictor) and attacker ~= inflictor then
                wepName = inflictor:GetPrintName()
            elseif IsValid(attacker) and IsValid(attacker:GetActiveWeapon()) then
                wepName = attacker:GetActiveWeapon():GetPrintName()
            elseif IsValid(attacker) and attacker == inflictor then
                wepName = "himself"
            else
                wepName = ""
            end

        else
            attName = ""
            wepName = ""
        end

        net.Start("OutlastTrialsReviveSystem_Notify")
            net.WriteString(downedPlayer:Nick())
            net.WriteString(attName)
            net.WriteString(wepName)
            net.WriteString("downed")
        net.Broadcast()
    end)

    hook.Add("Outlast_PlayerRevived", "OutlastTrialsReviveSystem_NotifyRevived", function(reviver, revivedPlayer)
        if not IsValid(reviver) or not IsValid(revivedPlayer) then return end
        local reviverName
        if reviver:IsNPC() then
            reviverName = GAMEMODE:GetDeathNoticeEntityName(reviver)
        else
            reviverName = reviver:Nick()
        end

        net.Start("OutlastTrialsReviveSystem_Notify")
            net.WriteString(revivedPlayer:Nick())
            net.WriteString(reviverName)
            net.WriteString("")
            net.WriteString("revive")
        net.Broadcast()
    end)

    hook.Add("Outlast_PlayerExecuting", "OutlastTrialsReviveSystem_NotifyExecuting", function(executor, victim)
        if not IsValid(executor) or not IsValid(victim) then return end

        net.Start("OutlastTrialsReviveSystem_Notify")
            net.WriteString(victim:Nick())
            net.WriteString(executor:Nick())
            net.WriteString("")
            net.WriteString("execute")
        net.Broadcast()
    end)
end


if CLIENT then
    print("[OTRS] CLIENT System Loaded")
    
    // Receive forced position from server during executions
    net.Receive("OutlastTrials_ForcePosition", function()
        local pos = net.ReadVector()
        local ang = net.ReadAngle()
        local ply = LocalPlayer()
        
        if IsValid(ply) then
            ply:SetPos(pos)
            ply:SetAngles(ang)
            ply:SetEyeAngles(ang)
            ply:SetLocalVelocity(Vector(0,0,0))
        end
    end)

    concommand.Add("outlast_trials_printstatus", function()
        local ply = LocalPlayer()
        print("IsDowned: ", ply:IsDowned())
        print("BleedoutTime: ", ply:GetBleedoutTime())
        print("IsBeingRevived: ", ply:IsBeingRevived())
        print("IsReviving: ", ply:IsReviving())
        local revivingTarget = ply:GetNWEntity("Outlast_RevivingTarget", nil)
        if IsValid(revivingTarget) then
            print("Reviving Target: ", revivingTarget:Nick())
        else
            print("Reviving Target: None")
        end
    end)

    hook.Add("Think", "OutlastTrialsReviveSystem_ClientThink", function()
        local downedPlayers = player.GetAll()

        function survivor:SpawnBloodParticle()
            local pos = self:GetBonePosition(self:LookupBone("ValveBiped.Bip01_Spine4") or 0)
            local emitter = ParticleEmitter(pos)
            if not emitter then return end

            local particle = emitter:Add("decals/blood_gunshot_decalmodel", pos)
            if particle then
                particle:SetDieTime(30)            -- znika po 15s
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(math.random(12, 24))
                particle:SetEndSize(0)
                particle:SetRoll(math.random(0, 360))
                particle:SetColor(90, 0, 0)
                particle:SetAirResistance(100)
                particle:SetGravity(Vector(0, 0, -800))
                particle:SetCollide(true)
            end

            emitter:Finish()
        end

        for _, ply in pairs(downedPlayers) do
            if ply:IsDowned() and ply:GetVelocity():LengthSqr() > 0 then
                if not ply.NextBloodParticle then
                    ply.NextBloodParticle = 0
                end
                if CurTime() >= ply.NextBloodParticle then
                    ply:SpawnBloodParticle()
                    ply.NextBloodParticle = CurTime() + math.Rand(0.1, 0.3)
                end
            end
        end
    end)
end