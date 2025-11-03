
wOS.DynaBase:RegisterSource({
    Name = "Outlast Trials Extension",
    Type =  WOS_DYNABASE.EXTENSION,
    Shared = "models/player/wiltos/anim_extension_mod11.mdl",
})

hook.Add( "PreLoadAnimations", "wOS.DynaBase.MountJA", function( gender )
    if gender != WOS_DYNABASE.SHARED then return end
    IncludeModel( "models/player/wiltos/anim_extension_mod11.mdl" )
end )