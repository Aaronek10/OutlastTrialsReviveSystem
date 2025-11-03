if SERVER then
    local function LoadFiles(folder)
        local files, _ = file.Find(folder .. "/*.lua", "LUA")

        for _, filename in ipairs(files) do
            local filepath = folder .. "/" .. filename
            AddCSLuaFile(filepath)
            include(filepath)
            print("[Outlast Trials] File " .. filename .. " has been loaded.")
        end
    end

    hook.Add("Initialize", "OutlastTrials_LoadFiles", function()
        LoadFiles("outlast_trials")
    end)

    concommand.Add("outlast_trials_reload", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then return end

        LoadFiles("outlast_trials")
        print("[Outlast Trials] All files have been reloaded.")
    end)
else
        local function LoadClientFiles(folder)
            local files, _ = file.Find(folder .. "/*.lua", "LUA")

            for _, filename in ipairs(files) do
                local filepath = folder .. "/" .. filename
                AddCSLuaFile(filepath)
                include(filepath)
                print("[Outlast Trials] File " .. filename .. " has been loaded.")
            end
        end

        hook.Add("Initialize", "OutlastTrials_LoadClientFiles", function()
            LoadClientFiles("outlast_trials")
        end)

        concommand.Add("outlast_trials_reload_client", function(ply, cmd, args)
            if IsValid(ply) and not ply:IsAdmin() then return end

            LoadClientFiles("outlast_trials")
            print("[Outlast Trials] All client files have been reloaded.")
        end)
end