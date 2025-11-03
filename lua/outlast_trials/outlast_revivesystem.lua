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

    hook.Add("Move", "OutlastTrialsReviveSystem_DownedMoveHandler", function(ply, mv)
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        if ply:IsDowned() then
            mv:SetMaxSpeed(15)
            mv:SetMaxClientSpeed(15)
        end
    end)

    hook.Add("Think", "OutlastTrialsReviveSystem_DownedThinkHandler", function()
        if not GetConVar("outlasttrials_enabled"):GetBool() then return end
        for _, ply in pairs(player.GetAll()) do
            if not IsValid(ply) or not ply:Alive() then return end

            if not ply.RevivingTarget and ply:KeyPressed(IN_USE) then
                local tr = ply:GetEyeTrace()
                local target = tr.Entity

                if IsValid(target) and target:IsPlayer() and target:IsDowned() then
                    if tr.HitPos:DistToSqr(ply:GetPos()) < 10000 then 
                        target:SetNWEntity("Outlast_Reviver", ply)
                        ply:SetNWEntity("Outlast_RevivingTarget", target)
                        target:SetNWFloat("Outlast_ReviveStartTime", CurTime())
                        target:SetNWBool("Outlast_IsBeingRevived", true)
                        ply.RevivingTarget = target
                        PrintMessage(HUD_PRINTTALK, ply:Nick() .. " started reviving " .. target:Nick())
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