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
    local target = self:GetNWEntity("Outlast_RevivingTarget", nil)
    return IsValid(target)
end

function survivor:GetReviveTarget()
    local target = self:GetNWEntity("Outlast_RevivingTarget", nil)
    if IsValid(target) then
        return target
    end
    return nil
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

    concommand.Add("outlast_trials_resetflags", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then return end

        for _, p in pairs(player.GetAll()) do
            p:ResetState()
            p:StopSVMultiAnimation()
            p:SetNWEntity("Outlast_Reviver", NULL)
            p:SetNWEntity("Outlast_RevivingTarget", NULL)
            p:SetNWFloat("Outlast_ReviveStartTime", 0)
            p:SetNWBool("Outlast_IsBeingRevived", false)
            ply.RevivingTarget = nil
            ply.PlayingReviveAnim = false
            p.PlayingGetupAnim = false
        end

        print("[Outlast Trials] All player downed states have been reset.")
    end)

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
        self:SetHealth(100)
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
    end

    local function GetApproachDirection(reviver, downed)
        local toReviver = (reviver:GetPos() - downed:GetPos()):GetNormalized()

        local forward = downed:EyeAngles():Forward()
        local right = downed:EyeAngles():Right()

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

    function survivor:SnapToDownedPosition(target, direction, offset)
        if not IsValid(target) then return end

        offset = offset or 40
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

        desiredPos.z = targetPos.z


        local currentPos = self:GetPos()
        local lerpSpeed = FrameTime() * 6
        local newPos = LerpVector(lerpSpeed, currentPos, desiredPos)
        self:SetPos(newPos)


        local lookAng = (targetPos - self:GetPos()):Angle()
        lookAng.p = 0
        self:SetAngles(LerpAngle(FrameTime() * 10, self:GetAngles(), lookAng))
        self:SetEyeAngles(lookAng)
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

    hook.Add("EntityTakeDamage", "OutlastTrialsReviveSystem_DamageDownedHandler", function(ent, dmginfo)
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        if not ent:IsPlayer() then return end
        local ply = ent
        local damage = dmginfo:GetDamage()

        if not ply:IsDowned() and damage >= ply:Health() then
            ply:Down()
            ply.DamageOwner = dmginfo:GetAttacker()
            return true
        end

        local timeleft = ply:GetBleedoutTime()
        if ply:IsDowned() then
            return true
        end

        if not ply:Alive() then return end
        if ply._OTRS_IsGettingDowned then return end
        ply._OTRS_IsGettingDowned = true
        timer.Simple(0, function()
            if IsValid(ply) then ply._OTRS_IsGettingDowned = false end
        end)
    end)

    hook.Add("Think", "OutlastTrialsReviveSystem_Think", function()
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        for _, ply in pairs(player.GetAll()) do
            if ply:IsDowned() then
                local timeLeft = ply:GetBleedoutTime()
                if timeLeft <= 0 then
                    if not ply.PlayingDeathAnim then
                        ply:SetSVAnimation(OutlastAnims.downeddeath, true)
                        timer.Simple(3, function()
                            if IsValid(ply) then
                                ply:SetPos(ply:GetPos() + Vector(0,0,5))
                                ply:Kill()
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
    end)

    hook.Add("Think", "OutlastTrialsReviveSystem_DownedThinkHandler", function()
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        for _, ply in pairs(player.GetAll()) do
            if not IsValid(ply) or not ply:Alive() then return end

            if not ply.RevivingTarget and ply:KeyPressed(IN_USE) then
                local tr = ply:GetEyeTraceNoCursor()
                local target = tr.Entity
                PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is looking at " .. tostring(target) .. " to revive. Approach Direction: " .. GetApproachDirection(ply, target))

                if IsValid(target) and target:IsPlayer() and target:IsDowned() then
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
                    ply:SnapToDownedPosition(ReviveTarget, Direction, 30)

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
                            ply:SetSVMultiAnimation({OutlastAnims.helpup_phase1_left, OutlastAnims.helpup_phase2_left, OutlastAnims.helpup_phase3_left},  true)
                            ReviveTarget:SetSVMultiAnimation({OutlastAnims.getup_phase1_left, OutlastAnims.getup_phase2_left, OutlastAnims.getup_phase3_left}, true)
                        end
                        ply.PlayingReviveAnim = true
                        ReviveTarget.PlayingGetupAnim = true
                    end

                    if progress >= 0.9 then
                        ply:ResolvePlayerOverlap(ReviveTarget, 40, false)
                    end

                    if progress >= 1 then
                        ReviveTarget:Revive()
                        ReviveTarget:SetNWEntity("Outlast_Reviver", NULL)
                        ply:SetNWEntity("Outlast_RevivingTarget", NULL)
                        ReviveTarget:SetNWFloat("Outlast_ReviveStartTime", nil)
                        ReviveTarget:SetNWBool("Outlast_IsBeingRevived", false)
                        ply:StopSVMultiAnimation()
                        ReviveTarget:StopSVMultiAnimation()
                        ply.RevivingTarget = nil
                        ply.PlayingReviveAnim = false
                        ReviveTarget.PlayingGetupAnim = false
                        ply:SelectWeapon(ply.Outlast_UnequipedWeapon)
                    end
                else
                    ReviveTarget:SetNWEntity("Outlast_Reviver", NULL)
                    ply:SetNWEntity("Outlast_RevivingTarget", NULL)
                    ReviveTarget:SetNWFloat("Outlast_ReviveStartTime", 0)
                    ReviveTarget:SetNWBool("Outlast_IsBeingRevived", false)
                    ply:StopSVMultiAnimation()
                    ReviveTarget:StopSVMultiAnimation()
                    ply.RevivingTarget = nil
                    ply.PlayingReviveAnim = false
                    ReviveTarget.PlayingGetupAnim = false
                    ply:ResolvePlayerOverlap(ReviveTarget, 40, false)
                    ply:SelectWeapon(ply.Outlast_UnequipedWeapon)
                end
            end

            if ply:IsDowned() then
                ply:SetActiveWeapon(nil)
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
end