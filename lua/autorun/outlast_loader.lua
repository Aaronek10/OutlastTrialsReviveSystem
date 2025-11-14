--[[
-----------------------------------------------------------------------------------------------------
Code
-----------------------------------------------------------------------------------------------------
]]


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

    hook.Add("PreGamemodeLoaded", "OutlastTrials_LoadFiles", function()
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

    hook.Add("PostGamemodeLoaded", "OutlastTrials_LoadClientFiles", function()
        timer.Simple(3, function() LoadClientFiles("outlast_trials") end)
    end)

    concommand.Add("outlast_trials_reload_client", function()
        LoadClientFiles("outlast_trials")
        print("[Outlast Trials] Client files reloaded.")
    end)
end

--[[
-----------------------------------------------------------------------------------------------------
Sound Tables
-----------------------------------------------------------------------------------------------------
]]

-- Murder
sound.Add( {
    name = "OutlastTrials.MurderIntroKick",
    channel = CHAN_WEPAON,
    volume = 1,
    level = 75,
    pitch = {95, 110},
    sound = {
        "outlasttrials/murder/SFX_Murder_IntroKick.ogg",
    }
} )

-- Foley
sound.Add( {
    name = "OutlastTrials.TorsoHeavyLong",
    channel = CHAN_BODY,
    volume = 0.5,
    level = 70,
    pitch = {95, 110},
    sound = {
        "outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Long01.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Long02.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Long03.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Long04.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Long05.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Long06.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Long07.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Long08.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Long09.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Long10.ogg",
    }
} )
sound.Add( {
    name = "OutlastTrials.TorsoHeavyShort",
    channel = CHAN_BODY,
    volume = 1,
    level = 70,
    pitch = {95, 110},
    sound = {
        "outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short01.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short02.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short03.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short04.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short05.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short06.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short07.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short08.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short09.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short10.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short11.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short12.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short13.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short14.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short15.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short16.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short17.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonHeavy_Short18.ogg",
    }
} )
sound.Add( {
    name = "OutlastTrials.TorsoLightLong",
    channel = CHAN_BODY,
    volume = 1,
    level = 70,
    pitch = {95, 110},
    sound = {
        "outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long01.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long02.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long03.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long04.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long05.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long06.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long07.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long08.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long09.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long10.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long11.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long12.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long13.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long14.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long15.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long16.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Long17.ogg",
    }
} )
sound.Add( {
    name = "OutlastTrials.TorsoLightShort",
    channel = CHAN_BODY,
    volume = 1,
    level = 60,
    pitch = {95, 110},
    sound = {
        "outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Short01.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Short02.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Short03.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Short04.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Short05.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Short06.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Short07.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Short08.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Short09.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Short10.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Short11.ogg",
		"outlasttrials/foley/cotton/torso/FOL_Player_Torso_CottonLight_Short12.ogg",
    }
} )

-- Impact
sound.Add( {
    name = "OutlastTrials.PVPStab",
    channel = CHAN_WEPAON,
    volume = 1,
    level = 75,
    pitch = {95, 110},
    sound = {
        "outlasttrials/impact/SFX_Player_PVP_Knife_Stab01.ogg",
		"outlasttrials/impact/SFX_Player_PVP_Knife_Stab02.ogg",
		"outlasttrials/impact/SFX_Player_PVP_Knife_Stab03.ogg",
		"outlasttrials/impact/SFX_Player_PVP_Knife_Stab04.ogg",
		"outlasttrials/impact/SFX_Player_PVP_Knife_Stab05.ogg",
		"outlasttrials/impact/SFX_Player_PVP_Knife_Stab06.ogg",
    }
} )




