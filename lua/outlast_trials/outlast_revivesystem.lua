survivor = FindMetaTable("Player")

CreateConVar("outlasttrials_enabled", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable or disable the Outlast Trials Revive System.")
CreateConVar("outlasttrials_bleedout_time", "60", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Time in seconds before a downed player bleeds out and dies.")

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

hook.Add("SetupMove", "OutlastTrialsReviveSystem_DownedMoveHandler", function(ply, mv, cmd)
    if not GetConVar("outlasttrials_enabled"):GetBool() then return end
    if ply:IsDowned() then
        mv:SetMaxSpeed(15)
        mv:SetMaxClientSpeed(15)
    end
end)

if SERVER then

    print("[OUTLAST TRIALS] SERVER System Loaded")

    util.AddNetworkString("OutlastTrialsReviveSystem_NotifyDowned")

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
    end

    function survivor:ResetState()
        self:SetDownedState(false)
        self:SetBleedoutTime(0)
    end

    function survivor:Down()
        if self:IsDowned() then return end
        self:SetDownedState(true)
        self:SetBleedoutTime(CurTime() + GetConVar("outlasttrials_bleedout_time"):GetFloat())
        self:SetHealth(100)
        self:SetNoTarget(true)
    end

    function survivor:HandleDownWhenReviving(target)
        target:SetNWEntity("Outlast_Reviver", NULL)
        self:SetNWEntity("Outlast_RevivingTarget", NULL)
        target:SetNWFloat("Outlast_ReviveStartTime", nil)
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
        downed:SetNWFloat("Outlast_ReviveStartTime", nil)
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
        ply:SetNWFloat("Outlast_ReviveStartTime", nil)
        ply:SetNWBool("Outlast_IsBeingRevived", false)
        ply:SetNWBool("Outlast_IsFalling", false)
        ply:SetNWEntity("Outlast_Impostor", NULL)
        ply:SetNWEntity("Outlast_ImpostorVictim", NULL) 
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

        //Something broke? KYS! IT'S THAT SIMPLE!
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


    function survivor:SnapToDownedPosition(target, direction, offset, adjust)
        if not IsValid(target) then return end

        offset = offset or 40
        adjust = adjust or 0
        local approachDir = direction or "front"

        local forward = target:GetForward()
        local right = target:GetRight()
        local targetPos = target:GetPos()

        local desiredPos
        if approachDir == "front" then
            desiredPos = targetPos + forward * offset
        elseif approachDir == "back" then
            desiredPos = targetPos - forward * offset
        elseif approachDir == "left" then
            desiredPos = targetPos - right * offset 
        elseif approachDir == "right" then
            desiredPos = targetPos + right * offset
        else
            desiredPos = targetPos + forward * offset
        end

        -- zachowaj wysokość i zastosuj przesunięcie w lewo/prawo względem targetu
        desiredPos.z = targetPos.z
        desiredPos = desiredPos + right * adjust
        self.OutlastDesiredPos = desiredPos

        local currentPos = self:GetPos()
        local lerpSpeed = FrameTime() * 6
        local newPos = LerpVector(lerpSpeed, currentPos, self.OutlastDesiredPos)
        self:SetPos(newPos)

        local lookAng = (targetPos - self:GetPos()):Angle()
        lookAng.p = 0
        self:SetAngles(LerpAngle(FrameTime() * 10, self:GetAngles(), lookAng))
        self:SetEyeAngles(lookAng)
        local tname = "DesiredPosOutlastCleanUp_" .. self:EntIndex()
        if timer.Exists(tname) then
            timer.Adjust(tname, 0.1, 1, function()
                if IsValid(self) then self.OutlastDesiredPos = nil end
            end)
            timer.Start(tname)
        else
            timer.Create(tname, 0.1, 1, function()
                if IsValid(self) then self.OutlastDesiredPos = nil end
            end)
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

    function survivor:HandleFallAnimation(damagePos)
        if not IsValid(self) or not damagePos then return end

        local myPos = self:GetPos() + Vector(0, 0, 40)
        local dir = (damagePos - myPos):GetNormalized()

        -- Lokalna orientacja gracza
        local forward = self:GetForward()
        local right = self:GetRight()

        local forwardDot = forward:Dot(dir)
        local rightDot = right:Dot(dir)

        local mainDir
        if forwardDot > 0.5 then
            mainDir = "fallbackward"
        elseif forwardDot < -0.5 then
            mainDir = "fallforward"
        elseif rightDot > 0 then
            mainDir = "fallleft"
        else
            mainDir = "fallright"
        end

        local subDir
        if math.abs(rightDot) < 0.25 then
            subDir = "center"
        elseif rightDot > 0 then
            subDir = "left"
        else
            subDir = "right"
        end

        local angafterfall = self:EyeAngles()
        if mainDir == "fallbackward" then
            angafterfall.y = angafterfall.y + 180
        elseif mainDir == "fallleft" then
           angafterfall.y = angafterfall.y + 90
        elseif mainDir == "fallright" then
            angafterfall.y = angafterfall.y - 90
        end

        local animKey = string.format("%s_start_%s", mainDir, subDir)
        local animName = OutlastAnims[animKey] or OutlastAnims[mainDir .. "_start_center"]
        local animEndName = OutlastAnims[mainDir .. "_end"]

        local fallID, fallTime = self:LookupSequence(animName)
        local fallEndID, fallEndTime = self:LookupSequence(animEndName)
        local finalTime = fallTime + fallEndTime - 1

        self:SetSVMultiAnimation({animName, animEndName}, true)
        self:Freeze(true)
        timer.Create("OutlastAnim_UnfreezeAfterFall" .. self:EntIndex(), finalTime, 1, function()
            self:Freeze(false)
            self:SetEyeAngles(angafterfall)
        end)
        return finalTime
    end


    hook.Add("EntityTakeDamage", "OutlastTrialsReviveSystem_DamageDownedHandler", function(ent, dmginfo)
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        if not ent:IsPlayer() then return end

        local ply = ent
        if not ply:Alive() then return end

        local inflictor = dmginfo:GetInflictor()
        local damagePos = IsValid(inflictor) and inflictor:GetPos() or dmginfo:GetDamagePosition()
        local attacker = dmginfo:GetAttacker()
        local damage = dmginfo:GetDamage()

        -- Gracz ma paść, ale nie jest jeszcze powalony
        if damage >= ply:Health() and not ply:IsDowned() and not ply.Outlast_IsFallingToDowned then
            dmginfo:SetDamage(0)
            ply.Outlast_IsFallingToDowned = true
            ply:SetNWBool("Outlast_IsFalling", true)
            ply.DamageOwner = attacker

            local timetodown = ply:HandleFallAnimation(damagePos) or 1

            timer.Create("OutlastPlayerDownAnim_" .. ply:EntIndex(), timetodown, 1, function()
                if not IsValid(ply) or not ply:Alive() then return end
                ply:Down()
                ply.Outlast_IsFallingToDowned = nil
                ply:SetNWBool("Outlast_IsFalling", false)
            end)

            hook.Run("Outlast_PlayerDowned", ply, attacker, inflictor)
            return true
        end

        -- Blok obrażeń w trakcie animacji upadku
        if ply.Outlast_IsFallingToDowned then
            return true
        end
    end)


    hook.Add("Think", "OutlastTrialsReviveSystem_Think", function()
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        for _, ply in pairs(player.GetAll()) do
            if ply:IsDowned() then

                if IsValid(ply:GetReviveTarget()) then
                    ply:HandleDownWhenReviving(ply:GetReviveTarget())
                end

                local timeLeft = ply:GetBleedoutTime()
                if timeLeft <= 0 and not ply:IsBeingRevived() then
                    if not ply.PlayingDeathAnim then
                        ply:SetSVAnimation(OutlastAnims.downeddeath, true)
                        ply:Freeze(true)
                        timer.Simple(3, function()
                            if IsValid(ply) then
                                ply:SetPos(ply:GetPos() + Vector(0,0,5))
                                ply:TakeDamage(ply:Health(), ply.DamageOwner or game.GetWorld(), nil)
                                ply:Freeze(false)
                                ply.PlayingDeathAnim = false
                            end
                        end)
                        ply.PlayingDeathAnim = true
                    end
                end
            end
        end
    end)

    hook.Add("PlayerDeath", "OutlastTrialsReviveSystem_DeathHandler", function(ply, inflictor, attacker)
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        if ply:IsDowned() then
            ply:ResetState()
        end
        RemoveAllOutlastFlags(ply) 
        ply.DamageOwner = nil
    end)

    hook.Add("Think", "OutlastTrialsReviveSystem_DownedThinkHandler", function()
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        for _, ply in pairs(player.GetAll()) do
            if not IsValid(ply) or not ply:Alive() then return end

            //Reviving Section
            if not ply.RevivingTarget and ply:KeyPressed(IN_USE) and not ply:IsDowned() then
                local tr = ply:GetEyeTraceNoCursor()
                local target = tr.Entity
                --PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is looking at " .. tostring(target) .. " to revive. Approach Direction: " .. GetApproachDirection(ply, target))

                if IsValid(target) and target:IsPlayer() and target:IsDowned() and not (target:GetBleedoutTime() <= 0) then
                    if target:GetPos():DistToSqr(ply:GetPos()) < 10000 then 
                        target:SetNWEntity("Outlast_Reviver", ply)
                        ply:SetNWEntity("Outlast_RevivingTarget", target)
                        target:SetNWFloat("Outlast_ReviveStartTime", CurTime())
                        target:SetNWBool("Outlast_IsBeingRevived", true)
                        ply.Outlast_UnequipedWeapon = ply:GetActiveWeapon()
                        ply:SetActiveWeapon(nil)
                        ply.RevivingTarget = target
                    end
                end
            end

            local ReviveTarget = ply.RevivingTarget
            if ReviveTarget and IsValid(ReviveTarget) and ReviveTarget:IsDowned() then
                if ply:KeyDown(IN_USE) then
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
                            ply:SnapToDownedPosition(ReviveTarget, "back", 55)
                        elseif Direction == "left" then
                            ply:SnapToDownedPosition(ReviveTarget, "left", 40)
                        elseif Direction == "right" then
                            ply:SnapToDownedPosition(ReviveTarget, "right", 45)
                        end
                    end

                    //Resolve overlap when close to finishing the revive, so players don't get stuck inside each other
                    if progress >= 0.9 then
                        ply:ResolvePlayerOverlap(ReviveTarget, 45, false)
                    end

                    if progress >= 1 then
                        ReviveTarget:Revive()
                        ResetOutlastReviveFlags(ply, ReviveTarget)
                        ply:SelectWeapon(ply.Outlast_UnequipedWeapon)
                        hook.Run("Outlast_PlayerRevived", ply, ReviveTarget)
                    end
                else
                    ResetOutlastReviveFlags(ply, ReviveTarget)
                    ply:ResolvePlayerOverlap(ReviveTarget, 40, false)
                    ply:SelectWeapon(ply.Outlast_UnequipedWeapon)
                end
            end

            if (ply:IsDowned() or ply.Outlast_IsFallingToDowned) then
                ply:SetActiveWeapon(nil)
            end

            //Executions Section
            if not ply.ExecTarget and ply:KeyPressed(IN_RELOAD) and not ply:IsDowned() then
                local tr = ply:GetEyeTraceNoCursor()
                local target = tr.Entity
                local ExecDirection = GetApproachDirection(ply, target)

                if IsValid(target) and target:IsPlayer() and target:IsDowned() and not (target:GetBleedoutTime() <= 0) then
                    if target:GetPos():DistToSqr(ply:GetPos()) < 10000 then
                        --PrintMessage(HUD_PRINTTALK, ply:Nick() .. " tried killing a: " .. target:Nick())
                        target:SetNWEntity("Outlast_Impostor", ply)
                        ply:SetNWEntity("Outlast_ImpostorVictim", target) 
                        ply.ExecTarget = target
                        ply.ExecDirection = ExecDirection
                        ply.ExecStart = CurTime()
                        ply.StartedExecution = false -- reset na wszelki wypadek
                        ply.Outlast_UnequipedWeapon = ply:GetActiveWeapon()
                        hook.Run("Outlast_PlayerExecuting", ply, target)
                    end
                end
            end

            local ExecTarget = ply.ExecTarget
            if ExecTarget and IsValid(ExecTarget) then
                if not ply.StartedExecution then
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
                    ExecTarget:SetSVAnimation(seq, true)
                    ply:SetSVAnimation(killerseq, true)
                    ply:Freeze(true)
                    ExecTarget:Freeze(true)
                    ply:SetActiveWeapon(nil)
                    ply.StartedExecution = true
                else
                    //Snapping
                    if CurTime() - ply.ExecStart <= 2 then
                        local ExecDirection = GetApproachDirection(ply, ExecTarget)
                        local VictimAngle = (ExecTarget:GetPos() - ply:GetPos()):Angle()
                        VictimAngle.p = 0
                        ply:SetEyeAngles(VictimAngle)
                        ply:SetAngles(VictimAngle)

                        if ExecDirection == "front" then
                            ply:SnapToDownedPosition(ExecTarget, "front", 40)
                        elseif ExecDirection == "back" then
                            ply:SnapToDownedPosition(ExecTarget, "back", 60)
                        elseif ExecDirection == "left" then
                            ply:SnapToDownedPosition(ExecTarget, "left", 40)
                        elseif ExecDirection == "right" then
                            ply:SnapToDownedPosition(ExecTarget, "right", 40)
                        end

                    end

                    if CurTime() - ply.ExecStart >= (ply.ExecTime or 0) then
                        if IsValid(ExecTarget) and ExecTarget:Alive() and ExecTarget:IsDowned() then
                            ExecTarget:TakeDamage(ExecTarget:Health(), ply, ply)
                        end
                        
                        ply:Freeze(false)
                        if IsValid(ExecTarget) then ExecTarget:Freeze(false) end
                        ply.StartedExecution = false
                        ply.ExecTarget = nil
                        ply.ExecStart = nil
                        ply.ExecDirection = nil
                        ply.ExecTime = nil
                        ply:SelectWeapon(ply.Outlast_UnequipedWeapon)
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
        end
    end)
end


if CLIENT then
    print("[OTRS] CLIENT System Loaded")

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