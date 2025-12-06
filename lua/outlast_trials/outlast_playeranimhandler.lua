print("[Outlast Trials] Animation Handler loaded!")
local survivor = FindMetaTable("Player")
OutlastAnims = {
    // Idle and moving anims
    idle = "player_downed_idle_loop",
    moveforward = "player_downed_move_forward_3P_nomo", 
    movebackward = "player_downed_move_backward_3P_nomo",
    moveright = "player_downed_move_right_3P_nomo",
    moveleft = "player_downed_move_left_3P_nomo",
    turn_left = "player_downed_turn_90_L",
    turn_right = "player_downed_turn_90_R",

    // Death
    downeddeath = "player_downed_bleedout_to_dead",

    // Fall animations depending on direction of hit
    fallbackward_end = "player_hitreaction_fall_to_downed_backward_end",
    fallbackward_end_notrot = "player_hitreaction_fall_to_downed_backward_end_norot",
    fallbackward_start_center_rootmotion = "player_hitreaction_fall_to_downed_backward_start_c",
    fallbackward_start_left_rootmotion = "player_hitreaction_fall_to_downed_backward_start_l",
    fallbackward_start_right_rootmotion  = "player_hitreaction_fall_to_downed_backward_start_r",

    fallforward_end = "player_hitreaction_fall_to_downed_forward_end",
    fallforward_start_center_rootmotion = "player_hitreaction_fall_to_downed_forward_start_c",
    fallforward_start_left_rootmotion = "player_hitreaction_fall_to_downed_forward_start_l",
    fallforward_start_right_rootmotion = "player_hitreaction_fall_to_downed_forward_start_r",

    fallleft_end = "player_hitreaction_fall_to_downed_left_end",
    fallleft_end_notrot = "player_hitreaction_fall_to_downed_left_end_norot",
    fallleft_start_center_rootmotion = "player_hitreaction_fall_to_downed_left_start_c",
    fallleft_start_left_rootmotion = "player_hitreaction_fall_to_downed_left_start_l", 
    fallleft_start_right_rootmotion = "player_hitreaction_fall_to_downed_left_start_r",
    
    fallright_end = "player_hitreaction_fall_to_downed_right_end",
    fallright_end_notrot = "player_hitreaction_fall_to_downed_right_end_norot",
    fallright_start_center_rootmotion = "player_hitreaction_fall_to_downed_right_start_c", 
    fallright_start_left_rootmotion = "player_hitreaction_fall_to_downed_right_start_l",
    fallright_start_right_rootmotion = "player_hitreaction_fall_to_downed_right_start_r",



    // Downed getting up animations
    getup_phase1_back = "player_helpup_follower_entry_back",
    getup_phase2_back = "player_helpup_follower_try_back",
    getup_phase3_back = "player_helpup_follower_success_back",

    getup_phase1_front = "player_helpup_follower_entry_front",
    getup_phase2_front = "player_helpup_follower_try_front",
    getup_phase3_front = "player_helpup_follower_success_front",

    getup_phase1_left = "player_helpup_follower_entry_left",
    getup_phase2_left = "player_helpup_follower_try_left",
    getup_phase3_left = "player_helpup_follower_success_left",

    getup_phase1_right = "player_helpup_follower_entry_right",
    getup_phase2_right = "player_helpup_follower_try_right",
    getup_phase3_right = "player_helpup_follower_success_right",


    //Get-up interupt animations
    getup_front_interupt_low = "player_helpup_follower_drop_front_low",
    getup_front_interupt_high = "player_helpup_follower_drop_front_high",

    getup_back_interupt_low = "player_helpup_follower_drop_back_low",
    getup_back_interupt_high = "player_helpup_follower_drop_back_high",

    getup_left_interupt_low = "player_helpup_follower_drop_left_low",
    getup_left_interupt_high = "player_helpup_follower_drop_left_high",

    getup_right_interupt_low = "player_helpup_follower_drop_right_low",
    getup_right_interupt_high = "player_helpup_follower_drop_right_high",

    //Reviver helping up animations
    helpup_phase1_back = "player_helpup_leader_entry_back",
    helpup_phase2_back = "player_helpup_leader_try_back",
    helpup_phase3_back = "player_helpup_leader_success_back", 

    helpup_phase1_front = "player_helpup_leader_entry_front",
    helpup_phase2_front = "player_helpup_leader_try_front",
    helpup_phase3_front = "player_helpup_leader_success_front",

    helpup_phase1_left = "player_helpup_leader_entry_left",
    helpup_phase2_left = "player_helpup_leader_try_left",
    helpup_phase3_left = "player_helpup_leader_success_left",

    helpup_phase1_right = "player_helpup_leader_entry_right",
    helpup_phase2_right = "player_helpup_leader_try_right",
    helpup_phase3_right = "player_helpup_leader_success_right",

    //Impostor finishers
    finisher_back = "Imposter_PVP_Downed_Murder_01_Back",
    finisher_front = "Imposter_PVP_Downed_Murder_01_Front",
    finisher_left = "Imposter_PVP_Downed_Murder_01_Left",
    finisher_right = "Imposter_PVP_Downed_Murder_01_Right",

    victim_back = "Player_PVP_Downed_Murder_01_Back",
    victim_front = "Player_PVP_Downed_Murder_01_Front",
    victim_left = "Player_PVP_Downed_Murder_01_Left",
    victim_right = "Player_PVP_Downed_Murder_01_Right"
}



function survivor:MovingDirection(threshold)
    threshold = threshold or 0.1
    local vel = self:GetVelocity()
    if vel:Length2D() < threshold then
        return "stand"
    end

    local forward = Angle(0, self:EyeAngles().y, 0):Forward()
    local right = Angle(0, self:EyeAngles().y, 0):Right()
    forward.z, right.z = 0, 0
    forward:Normalize()
    right:Normalize()

    local forwardDot = vel:Dot(forward)
    local rightDot = vel:Dot(right)

    local dir
    if math.abs(forwardDot) > math.abs(rightDot) then
        dir = (forwardDot > 0) and "forward" or "backward"
    else
        dir = (rightDot > 0) and "right" or "left"
    end
    
    self.LastMoveDir = dir

    return dir
end


if SERVER then
    function survivor:SetSVAnimation(anim, autostop)
        if anim == "" then
            self:SetNWString("SVAnim", "")
            self:SetCycle(0)
            return
        end

        local seq, dur = self:LookupSequence(anim)
        if seq == -1 then
            print("[OutlastAnim] Invalid animation:", anim, "for model:", self:GetModel())
            return
        end

        self:SetNWString("SVAnim", anim)
        self:SetNWFloat("SVAnimDelay", dur)
        self:SetNWFloat("SVAnimStartTime", CurTime())
        self:SetCycle(0)

        if autostop then
            timer.Simple(dur, function()
                if not IsValid(self) then return end
                if self:GetNWString("SVAnim") == anim then
                    self:SetSVAnimation("")
                end
            end)
        end
    end

    function survivor:IsPlayingSVAnimation()
        local anim = self:GetNWString("SVAnim", "")
        return anim != ""
    end

    function survivor:SetSVMultiAnimation(animTable, autostop)
        if not istable(animTable) or #animTable == 0 then return end

        -- Usuń poprzednie multi-animacje, jeśli jakieś jeszcze działają
        if self.SVMultiAnimTimers then
            for _, timerName in ipairs(self.SVMultiAnimTimers) do
                if timer.Exists(timerName) then
                    timer.Remove(timerName)
                end
            end
        end
        self.SVMultiAnimTimers = {}

        local index = 1
        local blendTime = 0.15 -- sekundy na płynne przejście

        local function PlayNext()
            if not IsValid(self) then return end
            local anim = animTable[index]
            if not anim then
                if autostop then
                    self:SetSVAnimation("") -- zakończ animację
                end
                return
            end

            local seq, dur = self:LookupSequence(anim)
            if seq == -1 then
                print("[OutlastAnim] Invalid animation:", anim, "for model:", self:GetModel())
                index = index + 1
                PlayNext()
                return
            end

            -- Ustaw aktualną animację
            self:SetSVAnimation(anim, false)
            --self:SetNWBool("SVAnimBlending", true)

            index = index + 1

            -- Czas do rozpoczęcia następnej animacji (trochę wcześniej)
            local nextDelay = math.max(0, dur - blendTime)
            local tname = "SVMultiAnim_" .. self:EntIndex() .. "_" .. index
            table.insert(self.SVMultiAnimTimers, tname)

            timer.Create(tname, nextDelay, 1, function()
                if not IsValid(self) then return end
                --self:SetNWBool("SVAnimBlending", true)
                PlayNext()

                -- wyłącz blending po krótkim czasie
                timer.Simple(blendTime, function()
                    if IsValid(self) then
                        --self:SetNWBool("SVAnimBlending", false)
                    end
                end)
            end)
        end

        PlayNext()
    end



    function survivor:StopSVMultiAnimation()
        -- Usuń wszelkie aktywne timery związane z multi-animacjami
        if self.SVMultiAnimTimers then
            for _, timerName in ipairs(self.SVMultiAnimTimers) do
                if timer.Exists(timerName) then
                    timer.Remove(timerName)
                end
            end
            self.SVMultiAnimTimers = nil 
        end

        -- Wyczyść aktualne informacje o animacji
        self:SetNWString("SVAnim", "")
        self:SetNWFloat("SVAnimDelay", 0)
        self:SetNWFloat("SVAnimStartTime", 0)

        -- Zresetuj cykl animacji
        self:SetCycle(0)
    end



end

hook.Add("CalcMainActivity", "!OutlastTrialsDownedAnimations", function(ply, vel)
    if ply:IsDowned() and ply:GetNWString("SVAnim", "") == "" then
        if not ply.OutlastAnimCache then
            ply.OutlastAnimCache = {}
            for key, seqName in pairs(OutlastAnims) do
                ply.OutlastAnimCache[key] = ply:LookupSequence(seqName)
            end
        end

        local anims = ply.OutlastAnimCache
        local dir   = ply:MovingDirection(8)
        local moving = vel:Length2D() > 10
        local yaw = ply:EyeAngles().y

        if not ply._lastYaw then
            ply._lastYaw = yaw
        end

        local deltaYaw = math.AngleDifference(yaw, ply._lastYaw)
        ply._lastYaw = yaw

        local threshold = 1

        if not moving then
            if deltaYaw > threshold then
                return -1, anims.turn_right
            elseif deltaYaw < -threshold then
                return -1, anims.turn_left
            end
        end

        if dir == "forward" and moving then
            return -1, anims.moveforward
        elseif dir == "backward" and moving then
            return -1, anims.movebackward
        elseif dir == "left" and moving then
            return -1, anims.moveleft
        elseif dir == "right" and moving then
            return -1, anims.moveright
        else
            return -1, anims.idle
        end
    end
end)


hook.Add("CalcMainActivity", "OutlastTrialsSVAnimHandler", function(ply, vel)
    local str = ply:GetNWString('SVAnim')
    local num = ply:GetNWFloat('SVAnimDelay')
    local st  = ply:GetNWFloat('SVAnimStartTime')
    if str != "" and num > 0 then
        local seq = ply:LookupSequence(str)
        if seq != -1 then
            ply:SetCycle(((CurTime() - st) / num) % 1)
            ply:SetPlaybackRate(1)
            return -1, seq
        end
    end
end)

hook.Add("UpdateAnimation", "OutlastTrialsDownedPlayback", function(ply, velocity, maxseqgroundspeed)
    if ply:IsDowned() or ply:IsReviving() then
        ply:SetPlaybackRate(1) 
        return true
    end

    --[[
    if ply:GetNWBool("SVAnimBlending", false) then
        ply:SetPlaybackRate(0.5)
    end
    ]]--
end)



hook.Add("CalcView", "OutlastTrialsDownedViewOffset", function(ply, pos, ang, fov)
    local viewply = ply
    local isDowned = (type(viewply.IsDowned) == "function" and viewply:IsDowned())
    local isReviving = (type(viewply.IsReviving) == "function" and viewply:IsReviving())
    local isBeingRevived = (type(viewply.IsBeingRevived) == "function" and viewply:IsBeingRevived())
    local isExecuting = (type(viewply.IsExecuting) == "function" and viewply:IsExecuting())
    local isBeingExecuted = (type(viewply.IsBeingExecuted) == "function" and viewply:IsBeingExecuted())
    local isFalling = (type(viewply.IsFallingToDowned) == "function" and viewply:IsFallingToDowned())

    if not (isDowned or isReviving or isBeingRevived or isExecuting or isBeingExecuted or isFalling) then return end
    local attId = viewply:LookupAttachment("cam")
    local attLoc = viewply:GetAttachment(attId)
    
    if not attId then
        chat.AddText("attId not found. Using Default EyeAngles and Pos.") 
        return 
    end

    if not attLoc then
        chat.AddText("attLoc not found. Using Default EyeAngles and Pos.") 
        return 
    end

    local ReviveProgress = viewply:GetReviveProgress()

    local fixedcamtable = {
        -- Get-up animations
        OutlastAnims.getup_phase1_back, OutlastAnims.getup_phase2_back, OutlastAnims.getup_phase3_back,
        OutlastAnims.getup_phase1_front, OutlastAnims.getup_phase2_front, OutlastAnims.getup_phase3_front,
        OutlastAnims.getup_phase1_left, OutlastAnims.getup_phase2_left, OutlastAnims.getup_phase3_left,
        OutlastAnims.getup_phase1_right, OutlastAnims.getup_phase2_right, OutlastAnims.getup_phase3_right,

        -- Help-up animations
        OutlastAnims.helpup_phase1_back, OutlastAnims.helpup_phase2_back, OutlastAnims.helpup_phase3_back,
        OutlastAnims.helpup_phase1_front, OutlastAnims.helpup_phase2_front, OutlastAnims.helpup_phase3_front,
        OutlastAnims.helpup_phase1_left, OutlastAnims.helpup_phase2_left, OutlastAnims.helpup_phase3_left,
        OutlastAnims.helpup_phase1_right, OutlastAnims.helpup_phase2_right, OutlastAnims.helpup_phase3_right,

        -- Fall backward
        OutlastAnims.fallbackward_start_center_rootmotion, OutlastAnims.fallbackward_start_left_rootmotion, OutlastAnims.fallbackward_start_right_rootmotion,
        OutlastAnims.fallbackward_end,

        -- Fall forward
        OutlastAnims.fallforward_start_center_rootmotion, OutlastAnims.fallforward_start_left_rootmotion, OutlastAnims.fallforward_start_right_rootmotion,
        OutlastAnims.fallforward_end,

        -- Fall left
        OutlastAnims.fallleft_start_center_rootmotion, OutlastAnims.fallleft_start_left_rootmotion, OutlastAnims.fallleft_start_right_rootmotion,
        OutlastAnims.fallleft_end,

        -- Fall right
        OutlastAnims.fallright_start_center_rootmotion, OutlastAnims.fallright_start_left_rootmotion, OutlastAnims.fallright_start_right_rootmotion,
        OutlastAnims.fallright_end,

        -- Deaths and finishers
        OutlastAnims.downeddeath,
        OutlastAnims.finisher_front, OutlastAnims.finisher_back, OutlastAnims.finisher_left, OutlastAnims.finisher_right,
        OutlastAnims.victim_front, OutlastAnims.victim_back, OutlastAnims.victim_left, OutlastAnims.victim_right
    }


    local PlyOrigin, PlyAng

    if table.HasValue(fixedcamtable, viewply:GetNWString("SVAnim", "")) then
        PlyAng = attLoc.Ang
        PlyOrigin = attLoc.Pos
        --chat.AddText("Fixed Cam Applied for animation: " .. viewply:GetNWString("SVAnim", ""))
        if ReviveProgress > 0.8 and isDowned then
            local t = math.Clamp((ReviveProgress - 0.8) / 0.2, 0, 1)
            local targetPos = viewply:EyePos()
            local targetAng = viewply:EyeAngles()

            PlyOrigin = LerpVector(t, PlyOrigin, targetPos)
            PlyAng = LerpAngle(t, PlyAng, targetAng)
        end
    else
        PlyAng = ang
        PlyOrigin = attLoc.Pos
    end

    local hiddenBones = {
        "ValveBiped.Bip01_Head1",
        "ValveBiped.Bip01_Neck1",
        "ValveBiped.Bip01_Neck",
        "ValveBiped.Bip01_L_Clavicle",
        "ValveBiped.Bip01_R_Clavicle",
    }

    for _, boneName in ipairs(hiddenBones) do
        local boneId = viewply:LookupBone(boneName)
        if boneId then
            if (isDowned or isReviving or isBeingRevived or isExecuting or isBeingExecuted or isFalling) then
                viewply:ManipulateBoneScale(boneId, Vector(0, 0, 0))
                timer.Create("LocalPly_returnbonescales_Bone" .. boneId .. "_" .. viewply:Nick(), 1, 1, function()
                    viewply:ManipulateBoneScale(boneId, Vector(1, 1, 1))
                end)
            end
        end
    end

    return {
        origin = PlyOrigin,
        angles = PlyAng,
        fov = 100,
        drawviewer = true
    }
end)

if CLIENT then
    
    hook.Add("Think", "OutlastTrials_KnifePosition", function()
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsExecuting() then
                -- Stwórz model tylko raz
                if not IsValid(ply.Outlast_knife) then
                    ply.Outlast_knife = ClientsideModel("models/weapons/outlast/execution/w_nmrih_knife.mdl", RENDERGROUP_OPAQUE)
                    ply.Outlast_knife:SetNoDraw(false)
                    ply.Outlast_knife:SetParent(ply)
                    -- ply.Outlast_knife:AddEffects(EF_BONEMERGE)
                end

                local attIndex = ply:LookupAttachment("anim_attachment_RH")
				local angOffset = Angle(0, -0, 0) 
				local PosOffset = Vector(0, 0, 0) 
                if attIndex and attIndex > 0 then
                    local att = ply:GetAttachment(attIndex)
                    if att then
                        ply.Outlast_knife:SetPos(att.Pos + PosOffset)
                        ply.Outlast_knife:SetAngles(att.Ang + angOffset)
                    end
                end
            else
                if IsValid(ply.Outlast_knife) then
                    ply.Outlast_knife:Remove()
                    ply.Outlast_knife = nil
                end
            end
        end
    end)
end

