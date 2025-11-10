print("Player Anims Loaded!")
local survivor = FindMetaTable("Player")
OutlastAnims = {
    // Idle and moving anims
    idle = "player_downed_idle_loop",
    moveforward = "player_downed_move_forward_3P_nomo", 
    movebackward = "player_downed_move_backward_3P_nomo",
    moveright = "player_downed_move_right_3P_nomo",
    moveleft = "player_downed_move_left_3P_nomo",

    // Death
    downeddeath = "player_downed_bleedout_to_dead",

    // Fall animations depending on direction of hit
    fallbackward_end = "player_hitreaction_fall_to_downed_backward_end_nomo",
    fallbackward_start_center = "player_hitreaction_fall_to_downed_backward_start_c_nomo",
    fallbackward_start_left = "player_hitreaction_fall_to_downed_backward_start_l_nomo",
    fallbackward_start_right = "player_hitreaction_fall_to_downed_backward_start_r_nomo",

    fallforward_end = "player_hitreaction_fall_to_downed_forward_end",
    fallforward_start_center = "player_hitreaction_fall_to_downed_forward_start_c_nomo",
    fallforward_start_left = "player_hitreaction_fall_to_downed_forward_start_l_nomo",
    fallforward_start_right = "player_hitreaction_fall_to_downed_forward_start_r_nomo",

    fallleft_end = "player_hitreaction_fall_to_downed_left_end",
    fallleft_start_center = "player_hitreaction_fall_to_downed_left_start_c_nomo",
    fallleft_start_left = "player_hitreaction_fall_to_downed_left_start_l_nomo", 
    fallleft_start_right = "player_hitreaction_fall_to_downed_left_start_r_nomo",
    
    fallright_end = "player_hitreaction_fall_to_downed_right_end",
    fallright_start_center = "player_hitreaction_fall_to_downed_right_start_c_nomo", 
    fallright_start_left = "player_hitreaction_fall_to_downed_right_start_l_nomo",
    fallright_start_right = "player_hitreaction_fall_to_downed_right_start_r_nomo",

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
            self:SetNWBool("SVAnimBlending", true)

            index = index + 1

            -- Czas do rozpoczęcia następnej animacji (trochę wcześniej)
            local nextDelay = math.max(0, dur - blendTime)
            local tname = "SVMultiAnim_" .. self:EntIndex() .. "_" .. index
            table.insert(self.SVMultiAnimTimers, tname)

            timer.Create(tname, nextDelay, 1, function()
                if not IsValid(self) then return end
                self:SetNWBool("SVAnimBlending", true)
                PlayNext()

                -- wyłącz blending po krótkim czasie
                timer.Simple(blendTime, function()
                    if IsValid(self) then
                        self:SetNWBool("SVAnimBlending", false)
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

        local dir = ply:MovingDirection(8)
        local moving = vel:Length2D() > 10
        local anims = ply.OutlastAnimCache

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

    if ply:GetNWBool("SVAnimBlending", false) then
        ply:SetPlaybackRate(0.5)
    end
end)



hook.Add("CalcView", "OutlastTrialsDownedViewOffset", function(ply, pos, ang, fov)
    local viewply = ply
    if not IsValid(viewply) or not viewply:IsPlayer() then
        viewply = LocalPlayer()
        if not IsValid(viewply) or not viewply:IsPlayer() then return end
    end

    local isDowned = (type(viewply.IsDowned) == "function" and viewply:IsDowned())
    local isReviving = (type(viewply.IsReviving) == "function" and viewply:IsReviving())
    local isBeingRevived = (type(viewply.IsBeingRevived) == "function" and viewply:IsBeingRevived())

    if not (isDowned or isReviving or isBeingRevived) then return end

    local attId = viewply:LookupAttachment("cam")
    local attLoc = viewply:GetAttachment(attId)
    if not attLoc then return end

    local ReviveProgress = viewply:GetReviveProgress()

    local fixedcamtable = {
        OutlastAnims.getup_phase1_back, OutlastAnims.getup_phase2_back, OutlastAnims.getup_phase3_back,
        OutlastAnims.getup_phase1_front, OutlastAnims.getup_phase2_front, OutlastAnims.getup_phase3_front,
        OutlastAnims.getup_phase1_left, OutlastAnims.getup_phase2_left, OutlastAnims.getup_phase3_left,
        OutlastAnims.getup_phase1_right, OutlastAnims.getup_phase2_right, OutlastAnims.getup_phase3_right,
        OutlastAnims.helpup_phase1_back, OutlastAnims.helpup_phase2_back, OutlastAnims.helpup_phase3_back,
        OutlastAnims.helpup_phase1_front, OutlastAnims.helpup_phase2_front, OutlastAnims.helpup_phase3_front,
        OutlastAnims.helpup_phase1_left, OutlastAnims.helpup_phase2_left, OutlastAnims.helpup_phase3_left,
        OutlastAnims.helpup_phase1_right, OutlastAnims.helpup_phase2_right, OutlastAnims.helpup_phase3_right,
        OutlastAnims.downeddeath, OutlastAnims.finisher_front, OutlastAnims.finisher_back, OutlastAnims.finisher_left,
        OutlastAnims.finisher_right, OutlastAnims.victim_front, OutlastAnims.victim_back, OutlastAnims.victim_left,
        OutlastAnims.victim_right
    }

    local PlyOrigin, PlyAng

    if table.HasValue(fixedcamtable, viewply:GetNWString("SVAnim", "")) then
        PlyAng = attLoc.Ang + Angle(0, 0, -90)
        PlyOrigin = attLoc.Pos
        if ReviveProgress > 0.8 and isDowned then
            local t = math.Clamp((ReviveProgress - 0.8) / 0.2, 0, 1)
            local targetPos = viewply:EyePos()
            local targetAng = viewply:EyeAngles()

            PlyOrigin = LerpVector(t, PlyOrigin, targetPos)
            PlyAng = LerpAngle(t, PlyAng, targetAng)
            --chat.AddText("Lerping! Player Flags: Downed: " .. tostring(isDowned) .. " isReviving: " .. tostring(isReviving) .. " isBeingRevived: " .. tostring(isBeingRevived))
        end
        --chat.AddText("Doing FIXED animation! Using calc.")
    else
        PlyAng = ang
        PlyOrigin = attLoc.Pos
        --chat.AddText("Crawling or not doing fixed anim.")
    end

    return {
        origin = PlyOrigin,
        angles = PlyAng,
        fov = 110,
        drawviewer = true
    }
end)

