if CLIENT then
    concommand.Add("outlasttrials_open_settings", function()
        local frame = vgui.Create("DFrame")
        frame:SetSize(500, 400)
        frame:Center()
        frame:SetTitle("Outlast Trials Settings")
        frame:MakePopup()

        local sheet = vgui.Create("DPropertySheet", frame)
        sheet:Dock(FILL)

        -- ===== Client Tab =====
        local clientPanel = vgui.Create("DPanel", sheet)
        clientPanel:Dock(FILL)

        local function AddClientConVarCheckbox(parent, convar, label)
            local chk = vgui.Create("DCheckBoxLabel", parent)
            chk:SetText(label)
            chk:SetValue(GetConVar(convar):GetBool())
            chk:Dock(TOP)
            chk:DockMargin(5, 5, 5, 0)
            chk:SizeToContents()

            chk.OnChange = function(self, val)
                RunConsoleCommand(convar, val and "1" or "0")
                print("[Outlast Settings Panel] Set "..convar.." to "..tostring(val))
            end
        end

        AddClientConVarCheckbox(clientPanel, "outlasttrials_hud_enabled", "Show Revive System HUD")
        AddClientConVarCheckbox(clientPanel, "outlasttrials_bleedout_ring_enabled", "Show Bleedout Ring")
        AddClientConVarCheckbox(clientPanel, "outlasttrials_indicators", "Show Offscreen Indicators")

        sheet:AddSheet("Client", clientPanel, "icon16/user.png")

        -- ===== Server Tab =====
        local serverPanel = vgui.Create("DPanel", sheet)
        serverPanel:Dock(FILL)

        if LocalPlayer():IsAdmin() then
            local function AddServerConVarCheckbox(parent, convar, label)
                local chk = vgui.Create("DCheckBoxLabel", parent)
                chk:SetText(label)
                chk:SetValue(GetConVar(convar):GetBool())
                chk:Dock(TOP)
                chk:DockMargin(5,5,5,0)
                chk:SizeToContents()

                chk.OnChange = function(self, val)
                    RunConsoleCommand(convar, val and "1" or "0")
                    print("[Outlast Settings Panel] Set "..convar.." to "..tostring(val))
                end
            end

            local function AddServerConVarSlider(parent, convar, label, min, max)
                local lbl = vgui.Create("DLabel", parent)
                lbl:SetText(label)
                lbl:Dock(TOP)
                lbl:DockMargin(5,5,5,0)
                lbl:SizeToContents()

                local slider = vgui.Create("DNumSlider", parent)
                slider:SetMin(min)
                slider:SetMax(max)
                slider:SetDecimals(0)
                slider:SetValue(GetConVar(convar):GetInt())
                slider:Dock(TOP)
                slider:DockMargin(5,0,5,0)

                slider.OnValueChanged = function(self, val)
                    RunConsoleCommand(convar, math.floor(val))
                    print("[Outlast Settings Panel] Set "..convar.." to "..tostring(val))
                end
            end

            AddServerConVarCheckbox(serverPanel, "outlasttrials_enabled", "Enable Revive System")
            AddServerConVarSlider(serverPanel, "outlasttrials_bleedout_time", "Bleedout Time (sec)", 1, 300)
            AddServerConVarCheckbox(serverPanel, "outlasttrials_teamwipe_on_all_downed", "Teamwipe if all downed")
            AddServerConVarCheckbox(serverPanel, "outlasttrials_enable_execution", "Enable Execution Mechanic")
            AddServerConVarCheckbox(serverPanel, "outlasttrials_player_damage_when_downed", "Downed players can take damage")

        else
            local lbl = vgui.Create("DLabel", serverPanel)
            lbl:SetText("Error: No privileges!")
            lbl:SetTextColor(Color(255,50,50))
            lbl:Dock(TOP)
            lbl:DockMargin(10,10,10,0)
            lbl:SizeToContents()
        end

        sheet:AddSheet("Server", serverPanel, "icon16/server.png")
    end)
end
