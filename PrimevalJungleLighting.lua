-- Primeval Jungle lighting only. Paste into Studio Command Bar OUTSIDE Play,
-- then save your place to retain the overcast preset in the editor.
local Workspace=game:GetService("Workspace")
local Lighting=game:GetService("Lighting")
local CONFIG={FootprintStuds=550, LightingClockTime=12, LightingBrightness=1.35, MistDensity=0.40}
local function applyForestLighting()
    -- Overcast green light and near haze, inspired by the supplied forest image.
    Lighting.ClockTime=CONFIG.LightingClockTime
    Lighting.Brightness=CONFIG.LightingBrightness
    Lighting.ExposureCompensation=-0.10
    Lighting.Ambient=Color3.fromRGB(62,78,68)
    Lighting.OutdoorAmbient=Color3.fromRGB(92,110,98)
    Lighting.EnvironmentDiffuseScale=0.45
    Lighting.EnvironmentSpecularScale=0.20
    Lighting.GlobalShadows=true
    Lighting.ShadowSoftness=1
    Lighting.FogColor=Color3.fromRGB(55,91,75)
    Lighting.FogStart=CONFIG.FootprintStuds*0.12
    Lighting.FogEnd=CONFIG.FootprintStuds*1.15
    local atmosphere=Lighting:FindFirstChild("GuardianAtmosphere") or Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere=Instance.new("Atmosphere")
        atmosphere.Name="GuardianAtmosphere"
        atmosphere.Parent=Lighting
    end
    -- Apply on every run, including when the previous version created it.
    atmosphere.Density=CONFIG.MistDensity
    atmosphere.Offset=-0.10
    atmosphere.Color=Color3.fromRGB(125,158,136)
    atmosphere.Decay=Color3.fromRGB(42,76,59)
    atmosphere.Haze=2.8
    atmosphere.Glare=0
    local sky=Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky=Instance.new("Sky")
        sky.Name="PrimevalJungleSky"
        sky.Parent=Lighting
    end
    sky.CelestialBodiesShown=false
    sky.StarCount=0
    local terrain=Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        local clouds=terrain:FindFirstChildOfClass("Clouds")
        if not clouds then
            clouds=Instance.new("Clouds")
            clouds.Name="PrimevalJungleClouds"
            clouds.Parent=terrain
        end
        clouds.Enabled=true
        clouds.Cover=0.98
        clouds.Density=0.80
        clouds.Color=Color3.fromRGB(79,100,87)
    end
    local function ownedEffect(name,class)
        local effect=Lighting:FindFirstChild(name)
        if effect and not effect:IsA(class) then
            error("Lighting."..name.." must be a "..class)
        end
        if not effect then
            effect=Instance.new(class)
            effect.Name=name
            effect.Parent=Lighting
        end
        effect.Enabled=true
        return effect
    end
    local grade=ownedEffect("GuardianColorGrade","ColorCorrectionEffect")
    grade.Brightness=-0.035
    grade.Contrast=0.14
    grade.Saturation=-0.22
    grade.TintColor=Color3.fromRGB(210,231,215)
    local bloom=ownedEffect("GuardianBloom","BloomEffect")
    bloom.Intensity=0.16
    bloom.Size=20
    bloom.Threshold=1.2
end
applyForestLighting()
print("Primeval Jungle overcast lighting applied. Save your place to keep it.")
