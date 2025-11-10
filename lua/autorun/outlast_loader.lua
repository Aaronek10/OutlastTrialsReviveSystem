if SERVER then
    local function LoadFiles(folder)
        local files, _ = file.Find(folder .. "/*.lua", "LUA")

        for _, filename in ipairs(files) do
            local filepath = folder .. "/" .. filename
            AddCSLuaFile(filepath)
            include(filepath)
            print("[Outlast Trials] Loaded server file: " .. filename)
        end
    end

    -- Lepiej użyć InitPostEntity, bo Initialize może być za wcześnie
    hook.Add("InitPostEntity", "OutlastTrials_LoadFiles", function()
        LoadFiles("outlast_trials")
    end)

    concommand.Add("outlast_trials_reload", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then return end

        LoadFiles("outlast_trials")
        print("[Outlast Trials] Server files reloaded.")
    end)

else
    local function LoadClientFiles(folder)
        local files, _ = file.Find(folder .. "/*.lua", "LUA")

        for _, filename in ipairs(files) do
            local filepath = folder .. "/" .. filename
            include(filepath)
            print("[Outlast Trials] Loaded client file: " .. filename)
        end
    end

    hook.Add("InitPostEntity", "OutlastTrials_LoadClientFiles", function()
        timer.Simple(3, function() LoadClientFiles("outlast_trials") end)
    end)

    concommand.Add("outlast_trials_reload_client", function()
        LoadClientFiles("outlast_trials")
        print("[Outlast Trials] Client files reloaded.")
    end)
end
