if CLIENT then
    print("[OTRS] HUD System Loaded")

    CreateClientConVar("outlasttrials_hud_enabled", "1", true, false, "Enable or disable the Outlast Trials Revive System HUD.")
    CreateClientConVar("outlasttrials_bleedout_ring_enabled", "1", true, false, "Enable or disable the bleedout ring on the HUD.")

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
                surface.SetMaterial(Material("revive_icon.png"))
                surface.SetDrawColor(Color(255, 255, 255, 255))
                surface.DrawTexturedRectRotated(centerX, centerY, 32, 32, 0)
            else
                DrawCircularRing(centerX, centerY, 50, 10, -90, 270, Color(0, 0, 0, 200))
                DrawCircularRing(centerX, centerY, 50, 10, -90, -90 + reviveAngle, Color(0, 132, 255))
                surface.SetMaterial(Material("revive_icon.png"))
                surface.SetDrawColor(Color(255,255,255,255))
                surface.DrawTexturedRectRotated(centerX, centerY, 32, 32, 0)
            end
        end

        local players = player.GetAll()
        for _, otherPly in ipairs(players) do
            if otherPly ~= ply and otherPly:IsDowned() and otherPly:Alive() then
                local name = ply:Nick()

                local totalplyTime = GetConVar("outlasttrials_bleedout_time"):GetFloat()
                local plytimeLeft = otherPly:GetBleedoutTime()

                local reviveProgress = otherPly:GetReviveProgress()
                local reviveCirleAngle = 360 * reviveProgress

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
                    DrawCircularRing(screenX, screenY, 30, 5, -90, 270, Color(0, 0, 0, 200))
                    DrawCircularRing(screenX, screenY, 30, 5, -90, -90 + plyangle, ringcolor)
                    surface.SetMaterial(Material("revive_icon.png"))
                    surface.SetDrawColor(Color(255, 255, 255, 255))
                    surface.DrawTexturedRectRotated(screenX, screenY, 25, 25, 0)
                else
                    DrawCircularRing(screenX, screenY, 30, 5, -90, 270, Color(0, 0, 0, 200))
                    DrawCircularRing(screenX, screenY, 30, 5, -90, -90 + reviveCirleAngle, Color(0, 132, 255))
                    surface.SetMaterial(Material("revive_icon.png"))
                    surface.SetDrawColor(Color(255, 255, 255, 255))
                    surface.DrawTexturedRectRotated(screenX, screenY, 25, 25, 0)
                end
            end

            local tr = ply:GetEyeTrace()
            if tr.Entity == otherPly and otherPly:IsDowned() and otherPly:Alive() and tr.HitPos:DistToSqr(ply:GetPos()) < 10000 then
                local name = otherPly:Nick()
                draw.SimpleTextOutlined("Press and hold E to Revive " .. name, "DermaLarge", ScrW() / 2, ScrH() / 2 + 100, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0))
            end
        end
    end)
end