if CLIENT then

    OutlastIcons = {
        //Transparent icons
        trans_bleedout = Material("outlast/bleedout.png"),
        trans_info = Material("outlast/helper.png"),
        trans_medkit = Material("outlast/item_pharma.png"),
        trans_skull = Material("outlast/item_skull.png"),
        trans_plaster = Material("outlast/plaster.png"),
        trans_hourglass = Material("outlast/sablier.png"),
        trans_object = Material("outlast/objectif_largepickup.png"),
        trans_shield = Material("outlast/objectif_zonedefence.png"),

        //Objective icons
        obj_base = Material("outlast/objectif_base.png"),
        obj_base2 = Material("outlast/objectif_base_02.png"),
        obj_base3 = Material("outlast/objectif_base_03.png"),
        obj_base4 = Material("outlast/objectif_base_04.png"),

        //States
        state_revive = Material("outlast/state_revive.png"),
        state_bleedout = Material("outlast/state_bleedout.png"),
        state_execution = Material("outlast/state_execution.png"),
        state_helping = Material("outlast/state_helping.png"),
        state_indanger = Material("outlast/state_indanger.png"),
        state_lowhealth = Material("outlast/state_lowhealth.png"),
        state_dead = Material("outlast/state_dead.png"),
        state_coop = Material("outlast/state_coop.png"),
        state_syringe = Material("outlast/state_syringe.png"),

        //Marker
        obj_ping = Material("outlast/objective_ping.png"),
        obj_markup = Material("outlast/objectif_generic.png"),
        obj_exit = Material("outlast/objectif_exit.png"),
        obj_arrow = Material("outlast/objectif_arrow.png"),

        bloodscreen1 = Material("outlast/vignette_blood.png"),
        bloodscreen2 = Material("outlast/vignette_blood_02.png")
    }
    print("[OTRS] HUD System Loaded")

    CreateClientConVar("outlasttrials_hud_enabled", "1", true, false, "Enable or disable the Outlast Trials Revive System HUD.")
    CreateClientConVar("outlasttrials_bleedout_ring_enabled", "1", true, false, "Enable or disable the bleedout ring on the HUD.")
    CreateClientConVar("outlasttrials_indicators", 1, true, false, "Show offscreen indicators above downed players.")



    local function DrawCircularRing(centerX, centerY, radius, thickness, angleStart, angleEnd, color)
        surface.SetDrawColor(color)

        for i = angleStart, angleEnd do
            local rad = math.rad(i)
            local nextRad = math.rad(i + 1)

            for t = 0, thickness do
                local r = radius - t
                surface.DrawLine(
                    centerX + math.cos(rad) * r,
                    centerY + math.sin(rad) * r,
                    centerX + math.cos(nextRad) * r,
                    centerY + math.sin(nextRad) * r
                )
            end
        end
    end

    hook.Add("HUDPaint", "OutlastTrialsReviveSystem_HUD", function()
        local ply = LocalPlayer()
        local reviveColor = Color(21, 255, 0)
        local MidX = ScrW() / 2
        local MidY = ScrW() / 2
        local margin = 50
        local iconMargin = 20
        local Radius = math.max(ScrW(), ScrH())
        if ply:IsDowned() then

            local totalTime = GetConVar("outlasttrials_bleedout_time"):GetFloat()
            local timeLeft = ply:GetBleedoutTime()

            local progress = timeLeft / totalTime 
            local angle = 360 * progress

            local reviveProgress = ply:GetReviveProgress()
            local reviveAngle = 360 * reviveProgress

            local ringcolor 
            if progress > 0.5 then
                ringcolor = Color(255, 255, 255)
            elseif progress > 0.2 then
                ringcolor = Color(255, 255, 0, 255)
            else
                ringcolor = Color(255, 0, 0, 255)
            end

            local w, h = ScrW(), ScrH()
            local centerX, centerY = w / 2, h / 2

            if not ply:IsBeingRevived() then
                DrawCircularRing(centerX, centerY, 50, 10, -90, 270, Color(0, 0, 0, 200))
                DrawCircularRing(centerX, centerY, 50, 10, -90, -90 + angle, ringcolor)
                if timeLeft <= 0 then
                    surface.SetMaterial(OutlastIcons.state_dead)
                elseif ply:IsBeingExecuted() then
                    surface.SetMaterial(OutlastIcons.state_execution)
                else
                    surface.SetMaterial(OutlastIcons.state_bleedout)
                end
                surface.SetDrawColor(Color(255, 255, 255, 255))
                surface.DrawTexturedRectRotated(centerX, centerY, 50, 50, 0)
            else
                DrawCircularRing(centerX, centerY, 50, 10, -90, 270, Color(0, 0, 0, 200))
                DrawCircularRing(centerX, centerY, 50, 10, -90, -90 + reviveAngle, reviveColor)
                surface.SetMaterial(OutlastIcons.state_revive)
                surface.SetDrawColor(Color(255,255,255,255))
                surface.DrawTexturedRectRotated(centerX, centerY, 50, 50, 0)
            end

            //Blood screen
            surface.SetMaterial(OutlastIcons.bloodscreen2)
            surface.SetDrawColor(Color(255,255,255))
            surface.DrawTexturedRect(0, 0, w, h)
            surface.DrawTexturedRectUV(0, 0, w, h, 1, 0, 0, 1)

            draw.SimpleTextOutlined("[CTRL]", "DermaDefault", ScrW() / 2 - 25, ScrH() / 2 + 100, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0))
            surface.SetMaterial(OutlastIcons.obj_base2)
            surface.SetDrawColor(Color(255,255,255))
            surface.DrawTexturedRectRotated(ScrW() / 2 + 45, ScrH() / 2 + 100, 50, 50, 0)
            surface.SetMaterial(OutlastIcons.trans_bleedout)
            surface.SetDrawColor(Color(255,255,255))
            surface.DrawTexturedRectRotated(ScrW() / 2 + 45, ScrH() / 2 + 100, 25, 25, 0)
        end

        local players = player.GetAll()
        for _, otherPly in ipairs(players) do
            if otherPly ~= ply and otherPly:IsDowned() and otherPly:Alive() then
                local name = ply:Nick()

                local totalplyTime = GetConVar("outlasttrials_bleedout_time"):GetFloat()
                local plytimeLeft = otherPly:GetBleedoutTime()

                local reviveProgress = otherPly:GetReviveProgress()
                local reviveCirleAngle = 360 * reviveProgress
                otherPly.ReviveAngle = Lerp(FrameTime() * 10, otherPly.ReviveAngle or 0, reviveCirleAngle)

                local healthFraction = math.Clamp(otherPly:Health() / otherPly:GetMaxHealth(), 0, 1)
                if healthFraction < 0 then healthFraction = 0 end
                local HPAngle = 360 * healthFraction

                local plyhead = otherPly:LookupBone("ValveBiped.Bip01_Head1")
                local plyheadpos, plyheadang = otherPly:GetBonePosition(plyhead)
                local correctpos = plyheadpos + Vector(0, 0, 15)

                local screenPos = correctpos:ToScreen()
                local screenX, screenY = screenPos.x, screenPos.y

                -- Zaczyna od 1 i schodzi do 0
                local plyprogress =  plytimeLeft / totalplyTime 
                local plyangle = 360 * plyprogress

                local ringcolor 
                if plyprogress > 0.5 then
                    ringcolor = Color(255, 255, 255) -- Zielony
                elseif plyprogress > 0.2 then
                    ringcolor = Color(255, 255, 0, 255) -- Żółty
                else
                    ringcolor = Color(255, 0, 0, 255) -- Czerwony
                end

                if not otherPly:IsBeingRevived() then
                    draw.SimpleText(otherPly:Nick(), "TargetID", screenX, screenY - 50, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    DrawCircularRing(screenX, screenY, 30, 5, -90, 270, Color(0, 0, 0, 200))
                    DrawCircularRing(screenX, screenY, 30, 5, -90, -90 + plyangle, ringcolor)
                    DrawCircularRing(screenX, screenY, 33, 2, -90, -90 + HPAngle, Color(99, 0, 0))
                    if plytimeLeft <= 0 then
                        surface.SetMaterial(OutlastIcons.state_dead)
                    elseif otherPly:IsBeingExecuted() then
                        surface.SetMaterial(OutlastIcons.state_execution)
                    else
                        surface.SetMaterial(OutlastIcons.state_bleedout)
                    end
                    surface.SetDrawColor(Color(255, 255, 255, 255))
                    surface.DrawTexturedRectRotated(screenX, screenY, 50, 50, 0)
                else
                    DrawCircularRing(screenX, screenY, 30, 5, -90, 270, Color(0, 0, 0, 200))
                    DrawCircularRing(screenX, screenY, 30, 5, -90, -90 + otherPly.ReviveAngle, reviveColor)
                    surface.SetMaterial(OutlastIcons.state_revive)
                    surface.SetDrawColor(Color(255, 255, 255, 255))
                    surface.DrawTexturedRectRotated(screenX, screenY, 50, 50, 0)
                end


                if GetConVar("outlasttrials_indicators"):GetBool() then
                    local OnScreenDowned = math.atan2(screenY - MidY, screenX - MidX)
                    local IndicatorX = MidX + math.cos(OnScreenDowned) * Radius
                    local IndicatorY = MidY + math.sin(OnScreenDowned) * Radius
                    local RotationTowards = math.NormalizeAngle(0 - math.deg( OnScreenDowned)) - 90
                    if math.abs(math.cos(OnScreenDowned)) * Radius > math.abs(math.sin(OnScreenDowned)) * Radius then
                        IndicatorX = math.Clamp(IndicatorX, margin, ScrW() - margin)
                        IndicatorY = MidY + math.sin(OnScreenDowned) * ((IndicatorX - MidX) / math.cos(OnScreenDowned))
                    else
                        IndicatorY = math.Clamp(IndicatorY, margin, ScrH() - margin)
                        IndicatorX = MidX + math.cos(OnScreenDowned) * ((IndicatorY - MidY) / math.sin(OnScreenDowned))
                    end

                    local ClampedX = math.Clamp(IndicatorX, margin, ScrW() - margin)
                    local ClampedY = math.Clamp(IndicatorY, margin, ScrH() - margin)
                                                
                    if IndicatorX ~= ClampedX then
                        IndicatorX = ClampedX
                        IndicatorY = MidY + math.sin(OnScreenDowned) * ((IndicatorX - MidX) / math.cos(OnScreenDowned))
                    end
                                            
                    if IndicatorY ~= ClampedY then
                        IndicatorY = ClampedY
                        IndicatorX = MidX + math.cos(OnScreenDowned) * ((IndicatorY - MidY) / math.sin(OnScreenDowned))
                    end

                    IndicatorX = math.Clamp(IndicatorX, margin, ScrW() - margin)
                    IndicatorY = math.Clamp(IndicatorY, margin, ScrH() - margin)
                    local IconIndicatorX = IndicatorX - math.cos(OnScreenDowned) * iconMargin
                    local IconIndicatorY = IndicatorY - math.sin(OnScreenDowned) * iconMargin
                    

                    if (screenX < 0 or screenX > ScrW() or screenY < 0 or screenY > ScrH()) then
                        surface.SetMaterial(OutlastIcons.obj_arrow)
                        surface.SetDrawColor(Color(255,255,255))
                        surface.DrawTexturedRectRotated(IndicatorX, IndicatorY, 20, 20, RotationTowards - 180)
                        if otherPly:IsDowned() then
                            if plytimeLeft <= 0 then
                                surface.SetMaterial(OutlastIcons.state_dead)
                            elseif otherPly:IsBeingRevived() then
                                surface.SetMaterial(OutlastIcons.state_revive)
                            elseif otherPly:IsBeingExecuted() then
                                surface.SetMaterial(OutlastIcons.state_execution)
                            else
                                surface.SetMaterial(OutlastIcons.state_bleedout)
                            end
                            surface.SetDrawColor(Color(255, 255, 255, 255))
                            surface.DrawTexturedRectRotated(IconIndicatorX, IconIndicatorY, 30, 30, 0)
                        end
                    end
                end
            end

            local tr = ply:GetEyeTrace()
            if tr.Entity == otherPly and otherPly:IsDowned() and otherPly:Alive() and tr.HitPos:DistToSqr(ply:GetPos()) < 10000 and not otherPly:IsBeingRevived() then
                --local name = otherPly:Nick()
                draw.SimpleTextOutlined("[E]", "DermaDefault", ScrW() / 2 - 25, ScrH() / 2 + 100, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0))
                surface.SetMaterial(OutlastIcons.obj_base2)
                surface.SetDrawColor(Color(255,255,255))
                surface.DrawTexturedRectRotated(ScrW() / 2 + 25, ScrH() / 2 + 100, 50, 50, 0)
                surface.SetMaterial(OutlastIcons.trans_medkit)
                surface.SetDrawColor(Color(255,255,255))
                surface.DrawTexturedRectRotated(ScrW() / 2 + 25, ScrH() / 2 + 100, 25, 25, 0)

                draw.SimpleTextOutlined("[R]", "DermaDefault", ScrW() / 2 - 25, ScrH() / 2 + 150, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0))
                surface.SetMaterial(OutlastIcons.obj_base2)
                surface.SetDrawColor(Color(255,255,255))
                surface.DrawTexturedRectRotated(ScrW() / 2 + 25, ScrH() / 2 + 150, 50, 50, 0)
                surface.SetMaterial(OutlastIcons.trans_skull)
                surface.SetDrawColor(Color(255,255,255))
                surface.DrawTexturedRectRotated(ScrW() / 2 + 25, ScrH() / 2 + 150, 25, 25, 0)
            end

            if ply:IsReviving() then
                local reviveTarget = ply:GetReviveTarget()
                local targetReviveProgress = reviveTarget:GetReviveProgress()
                local targetReviveAngle = 360 * targetReviveProgress
                ply.ReviveAngle = Lerp(FrameTime() * 10, ply.ReviveAngle or 0, targetReviveAngle)
                if reviveTarget == otherPly then
                    DrawCircularRing(ScrW() / 2, ScrH() / 2, 50, 10, -90, 270, Color(0, 0, 0, 200))
                    DrawCircularRing(ScrW() / 2, ScrH() / 2, 50, 10, -90, -90 + ply.ReviveAngle, reviveColor)
                    surface.SetMaterial(OutlastIcons.state_revive)
                    surface.SetDrawColor(Color(255, 255, 255, 255))
                    surface.DrawTexturedRectRotated(ScrW() / 2, ScrH() / 2, 50, 50, 0)
                    surface.SetMaterial(OutlastIcons.state_helping)
                    surface.SetDrawColor(Color(255,255,255))
                    surface.DrawTexturedRectRotated(ScrW() / 2 - 50, ScrH() / 2 + 100, 50, 50, 0)
                    draw.SimpleTextOutlined(reviveTarget:Nick(), "DermaLarge", ScrW() / 2, ScrH() / 2 + 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0))
                end
            end
        end
    end)

    hook.Add("StartCommand", "OutlastTrialsReviveSystem_CameraLock", function(ply, ucmd)
        local ang = ply:GetNWAngle("Outlast_AfterFallAngle", nil)
        local IsInAnimation = ply:GetNWString("SVAnim") ~= ""
        --chat.AddText("In animation: " .. tostring(IsInAnimation))
        if not IsInAnimation then
            if ang and not ang:IsZero() then
                ucmd:SetViewAngles(ang)
                ucmd:SetForwardMove(1000)
                ply:SetLocalVelocity(Vector(0,0,0))
            end
        end
    end)

    hook.Add("SetupMove", "Outlast_BlockInputs", function(ply, mv)
        if ply:IsDowned() then
            local buttons = mv:GetButtons()
            buttons = bit.band(buttons, bit.bnot(IN_JUMP))
            mv:SetButtons(buttons)
        end
    end)


end