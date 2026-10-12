-- Guardian reconstruction for Parkour Duels. Paste into a server Script.
-- References: the supplied Guardian article and overhead/in-game screenshots.
-- Topology and landmarks follow those references; studs/elevations are inferred.
-- Floor coordinates mean TOP surfaces. Keep your existing movement controller.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CONFIG = {
    Origin = Vector3.new(0, 64, 0),
    SetAtmosphere = true,
    EnableSpawns = true,
    EnableLifts = true,
    EnableVoidReset = true, -- Disable if other playable areas exist below this map.
    VoidDepth = 40, -- Kill before the default Studio baseplate can catch falling players.
    ForestDetail = true,
    -- Match your controller's 15% gravity cancellation while airborne.
    -- Use 1 if testing without air float; lift launch calculations use this factor.
    LiftGravityMultiplier = 0.85,
    MetalTexture = "", -- Optional permitted rbxassetid://... image texture.
    StoneTexture = "", -- Defaults use native materials plus procedural panel detail.
    TextureTileStuds = 10,
}
local UPPER = 16 -- Thin deck slabs leave 15 studs of clear space below.
local SNIPER_TOP = 24
local GENERATOR_ID = "ParkourDuelsGuardian_v2"
local old = Workspace:FindFirstChild("Guardian")
if old then
    if old:GetAttribute("GeneratorId") ~= GENERATOR_ID
        and old:GetAttribute("ApproximateReconstruction") ~= true then
        error("Workspace.Guardian already exists and is not this generator's model. Rename it first.")
    end
    old:Destroy()
end
local map = Instance.new("Model")
map.Name = "Guardian"
map:SetAttribute("GeneratorId", GENERATOR_ID)
map:SetAttribute("ApproximateReconstruction", true)
map:SetAttribute("ReferenceRevision", "User article and screenshots")
for name, value in pairs({WalkSpeed=16, SprintStart=21.5, SprintMax=29,
    SprintRampSeconds=1.2, FlowMultiplier=1.05, JumpHeight=7.5,
    AirGravityMultiplier=0.85, ClimbHeight=8}) do
    map:SetAttribute(name, value)
end
map.Parent = Workspace

local colors = {
    metal = Color3.fromRGB(86, 102, 104),
    stone = Color3.fromRGB(78, 91, 90),
    edge = Color3.fromRGB(43, 57, 58),
    panel = Color3.fromRGB(110, 126, 124),
    moss = Color3.fromRGB(73, 94, 47),
    cyan = Color3.fromRGB(92, 226, 240),
    blue = Color3.fromRGB(69, 155, 236),
    gold = Color3.fromRGB(243, 213, 116),
    bark = Color3.fromRGB(48, 61, 45),
    leaves = Color3.fromRGB(46, 81, 43),
    white = Color3.fromRGB(204, 246, 241),
}
local folders = {}
for _, name in ipairs({"Floors", "Walls", "Architecture", "Details", "Forest", "Gameplay", "Callouts"}) do
    local f = Instance.new("Folder")
    f.Name = name
    f.Parent = map
    folders[name] = f
end
local function world(x,y,z)
    return CONFIG.Origin + Vector3.new(x,y,z)
end
local function part(name,size,cf,color,material,group,collide,class)
    local p = Instance.new(class or "Part")
    p.Name = name
    p.Anchored = true
    p.Size = size
    p.CFrame = cf
    p.Color = color or colors.metal
    p.Material = material or Enum.Material.Metal
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.CanCollide = collide ~= false
    p.CanTouch = false
    p.CanQuery = collide ~= false
    p.CastShadow = group ~= "Details"
    p.Parent = folders[group or "Details"]
    return p
end
local function block(name,x,y,z,sx,sy,sz,color,material,group,collide)
    return part(name,Vector3.new(sx,sy,sz),CFrame.new(world(x,y,z)),color,material,group,collide)
end
local function texture(p,id)
    if id == "" then return end
    for _, face in ipairs({Enum.NormalId.Top,Enum.NormalId.Front,Enum.NormalId.Back,
        Enum.NormalId.Left,Enum.NormalId.Right}) do
        local t = Instance.new("Texture")
        t.Texture = id
        t.Face = face
        t.StudsPerTileU = CONFIG.TextureTileStuds
        t.StudsPerTileV = CONFIG.TextureTileStuds
        t.Parent = p
    end
end
local function floor(name,x,top,z,sx,sz,stone)
    local p = block(name,x,top-0.5,z,sx,1,sz,stone and colors.stone or colors.metal,
        stone and Enum.Material.Slate or Enum.Material.Metal,"Floors")
    texture(p,stone and CONFIG.StoneTexture or CONFIG.MetalTexture)
    for offset=-sx/2+8,sx/2-0.5,8 do
        block(name.."_Seam",x+offset,top+0.015,z,0.06,0.02,sz-0.4,
            colors.edge,Enum.Material.Metal,"Details",false)
    end
    return p
end
-- Subdivide a floor around actual rectangular holes; no invisible collision cap.
local function perforatedFloor(name,top,xs,zs,holes)
    for i=1,#xs-1 do
        for j=1,#zs-1 do
            local x,z=(xs[i]+xs[i+1])/2,(zs[j]+zs[j+1])/2
            local cut=false
            for _,hole in ipairs(holes) do
                if x>hole[1] and x<hole[2] and z>hole[3] and z<hole[4] then cut=true break end
            end
            if not cut then
                floor(name.."_"..i.."_"..j,x,top,z,xs[i+1]-xs[i],zs[j+1]-zs[j])
            end
        end
    end
end
local function wall(name,x,bottom,z,sx,height,sz)
    local p=block(name,x,bottom+height/2,z,sx,height,sz,colors.stone,Enum.Material.Slate,"Walls")
    texture(p,CONFIG.StoneTexture)
    block(name.."_Cap",x,bottom+height-0.2,z,sx+0.25,0.4,sz+0.25,
        colors.panel,Enum.Material.Metal,"Details",false)
    -- Dark horizontal joints, flush with the surface, on both visible faces.
    for y=bottom+4,bottom+height-1,4 do
        if sx>sz then
            for _,side in ipairs({-1,1}) do
                block(name.."_Joint",x,y,z+side*(sz/2+0.015),sx-0.15,0.065,0.02,
                    colors.edge,Enum.Material.Metal,"Details",false)
            end
        else
            for _,side in ipairs({-1,1}) do
                block(name.."_Joint",x+side*(sx/2+0.015),y,z,0.02,0.065,sz-0.15,
                    colors.edge,Enum.Material.Metal,"Details",false)
            end
        end
    end
    return p
end
local function glow(name,x,y,z,sx,sy,sz,color,lit)
    local p=block(name,x,y,z,sx,sy,sz,color,Enum.Material.Neon,"Details",false)
    if lit then
        local light=Instance.new("PointLight")
        light.Color=color
        light.Range=22
        light.Brightness=0.8
        light.Parent=p
    end
    return p
end
local function disc(name,x,top,z,radius,thickness,color,material,group,collide)
    local p=block(name,x,top-thickness/2,z,thickness,radius*2,radius*2,color or colors.metal,
        material or Enum.Material.Metal,group or "Floors",collide)
    p.Shape=Enum.PartType.Cylinder
    p.CFrame=CFrame.new(world(x,top-thickness/2,z))*CFrame.Angles(0,0,math.pi/2)
    return p
end
local function route(name,ax,ay,az,bx,by,bz,width,rails)
    local a,b=world(ax,ay,az),world(bx,by,bz)
    local delta=b-a
    local length=delta.Magnitude
    local frame=CFrame.lookAt((a+b)/2,b)
    -- Offset perpendicular to the ramp so its top follows both given endpoints.
    local p=part(name,Vector3.new(width,1,length+0.7),frame*CFrame.new(0,-0.5,0),
        colors.metal,Enum.Material.Metal,"Floors")
    texture(p,CONFIG.MetalTexture)
    for _,side in ipairs({-1,1}) do
        part(name.."_Fascia",Vector3.new(0.65,2,length),frame*CFrame.new(side*(width/2-0.2),-1,0),
            colors.edge,Enum.Material.Metal,"Architecture",false)
        if rails then
            part(name.."_Parapet",Vector3.new(0.7,3.2,length),frame*CFrame.new(side*width/2,1.6,0),
                colors.stone,Enum.Material.Slate,"Walls")
        end
    end
    for i=1,math.floor(length/8) do
        part(name.."_Seam",Vector3.new(width-0.4,0.025,0.07),
            frame*CFrame.new(0,0.015,-length/2+i*length/(math.floor(length/8)+1)),
            colors.edge,Enum.Material.Metal,"Details",false)
    end
    return p
end
-- Forerunner doorway: angular frame with an unobstructed 14-stud-tall opening.
local function arch(name,x,bottom,z,width,angle,color)
    local frame=CFrame.new(world(x,bottom,z))*CFrame.Angles(0,angle or 0,0)
    for _,side in ipairs({-1,1}) do
        part(name.."_Shoulder",Vector3.new(3,16,3),frame*CFrame.new(side*(width/2+1.5),8,0),
            colors.edge,Enum.Material.Metal,"Walls")
        part(name.."_Bevel",Vector3.new(2.5,5,3.4),
            frame*CFrame.new(side*(width/2+1.5),13.5,-0.1)*CFrame.Angles(0,side*math.pi/2,0),
            colors.panel,Enum.Material.Metal,"Details",false,"WedgePart")
        part(name.."_Light",Vector3.new(0.15,10,0.16),frame*CFrame.new(side*(width/2+0.1),7,-1.6),
            color or colors.white,Enum.Material.Neon,"Details",false)
    end
    part(name.."_Lintel",Vector3.new(width+6,2,3),frame*CFrame.new(0,15,0),
        colors.metal,Enum.Material.Metal,"Walls")
end
local function glyph(p,color)
    -- An asset-free surface pattern; visible details never add collision.
    local gui=Instance.new("SurfaceGui")
    gui.Name="ForerunnerGlyph"
    gui.Face=Enum.NormalId.Front
    gui.CanvasSize=Vector2.new(128,256)
    gui.LightInfluence=0.3
    gui.Parent=p
    for i,stroke in ipairs({{27,28,11,126,0},{89,28,11,126,0},
        {44,32,10,62,25},{74,32,10,62,-25},{59,99,10,96,0},
        {38,160,10,62,-25},{79,160,10,62,25},{41,225,46,8,0}}) do
        local f=Instance.new("Frame")
        f.Name="Stroke"..i
        f.BorderSizePixel=0
        f.BackgroundColor3=color or colors.white
        f.Position=UDim2.fromOffset(stroke[1],stroke[2])
        f.Size=UDim2.fromOffset(stroke[3],stroke[4])
        f.Rotation=stroke[5]
        f.Parent=gui
    end
end
local function pylon(name,x,bottom,z,angle)
    local frame=CFrame.new(world(x,bottom,z))*CFrame.Angles(0,angle or 0,0)
    local p=part(name,Vector3.new(4,7,3),frame*CFrame.new(0,3.5,0),
        colors.edge,Enum.Material.Metal,"Architecture",true)
    glyph(p)
    part(name.."_Cap",Vector3.new(4.8,0.7,3.8),frame*CFrame.new(0,7,0),
        colors.panel,Enum.Material.Metal,"Details",false)
    glow(name.."_Node",x,bottom+7.5,z,1.2,0.2,1.2,colors.cyan,false)
end
local function callout(name,x,y,z)
    local f=Instance.new("Folder")
    f.Name=name
    f:SetAttribute("Position",world(x,y,z))
    f.Parent=folders.Callouts
end

-- Overhead reference orientation: tree/Green north, Blue south, Sniper west.
-- CENTER: radial upper deck and enclosed Hammer room beneath it.
disc("CenterLower",0,0,0,22,2)
disc("CenterUpper",0,UPPER,0,18,1)
disc("CenterMedallion",0,UPPER+0.025,0,4,0.03,colors.edge,Enum.Material.Metal,"Details",false)
for i=0,7 do
    local angle=i*math.pi/4
    local frame=CFrame.new(world(0,UPPER+0.035,0))*CFrame.Angles(0,angle,0)
    part("CenterRadialInlay",Vector3.new(0.14,0.03,13),frame*CFrame.new(0,0,-11),
        colors.edge,Enum.Material.Metal,"Details",false)
    part("CenterRim",Vector3.new(13.9,1.8,0.8),frame*CFrame.new(0,-1,-17.1),
        colors.edge,Enum.Material.Metal,"Architecture",false)
    -- Corner wall sections preserve the four cardinal ground-level entrances.
    local theta=angle+math.pi/8
    local p=block("HammerRoomWall",math.sin(theta)*17,7.5,math.cos(theta)*17,
        7,15,1.8,colors.stone,Enum.Material.Slate,"Walls")
    p.CFrame=CFrame.new(world(math.sin(theta)*17,7.5,math.cos(theta)*17))*CFrame.Angles(0,theta,0)
    if i==1 or i==5 then
        p.Material=Enum.Material.Glass
        p.Color=colors.cyan
        p.Transparency=0.48
        p.Name="HammerRoomGlass"
    end
end
for _,pos in ipairs({{-12,12},{12,12},{-12,-12},{12,-12}}) do
    pylon("CenterPylon",pos[1],UPPER,pos[2],math.atan2(pos[1],pos[2]))
end
route("CenterToSniperLower",-22,0,0,-44,0,0,12,false)
route("CenterToSniperUpper",-18,UPPER,0,-42,UPPER,0,12,false)
route("CenterToGoldLower",22,0,0,44,0,0,12,false)
route("CenterToGoldUpper",18,UPPER,0,48,UPPER,0,12,false)
route("CenterToBlueLower",0,0,22,0,0,44,12,false)
route("CenterToBlueUpper",0,UPPER,18,0,UPPER,54,12,false)
-- Impenetrable glass cover on the Blue-center walkway, as described in reference.
local glass=block("BlueBridgeGlass",7.1,UPPER+5,36,0.65,10,23,
    colors.cyan,Enum.Material.Glass,"Walls")
glass.Transparency=0.55
block("BlueGlassBottomFrame",7.1,UPPER+0.4,36,1,0.8,24,colors.edge,Enum.Material.Metal,"Details",false)
block("BlueGlassTopFrame",7.1,UPPER+10,36,1,0.6,24,colors.panel,Enum.Material.Metal,"Details",false)
callout("Center / Hammer Room",0,0,0)

-- SNIPER: lower ledge, forward balcony, winding ramp and taller S2 deck.
-- Rising ramps meet landing EDGES so solid pads never cut across the ascent.
floor("SniperLower",-66,0,1,44,42,true)
floor("SniperRampApproach",-66,0,-25,44,12,true)
local sniperUpper=floor("SniperUpper",-68,SNIPER_TOP,-1,24,38)
sniperUpper:SetAttribute("Climbable",true)
sniperUpper:SetAttribute("ClimbHeight",8)
floor("SniperFrontBalcony",-49,UPPER,-1,14,28)
floor("SniperLiftLanding",-50,UPPER,22,14,12)
route("SniperCannonLandingLink",-50,UPPER,16,-50,UPPER,12,12,false)
route("SniperWindingRampA",-50,0,-25,-81,12,-25,10,false)
floor("SniperHalfLanding",-87,12,-25,12,12)
route("SniperWindingRampB",-87,12,-19,-87,SNIPER_TOP,16,10,false)
floor("SniperTopLanding",-87,SNIPER_TOP,22,12,12)
route("SniperWindingRampC",-81,SNIPER_TOP,22,-62,SNIPER_TOP,22,10,false)
route("SniperTopEntrance",-62,SNIPER_TOP,22,-62,SNIPER_TOP,14,10,false)
-- Balcony -> S2 is an 8-stud jump/mantle; the winding ramp is the walking route.
-- Leave the southern landing open for the Bottom Blue man-cannon.
wall("SniperBack",-95,0,0,2,38,62)
wall("SniperNorthCover",-68,SNIPER_TOP,-21,26,7,2)
arch("SniperLowerDoor",-44,0,0,12,math.pi/2,colors.cyan)
arch("SniperS2Door",-68,SNIPER_TOP,-16,12,0,colors.cyan)
glow("SniperWallStrip",-93.8,18,0,0.12,22,1,colors.cyan,true)
callout("S1 / Sniper",-66,0,0)
callout("S2 / Overlook",-68,SNIPER_TOP,0)

-- GREEN: the prominent dead tree stump, roots, jump and low Hammer route.
floor("GreenPlatform",0,0,-57,46,34,true)
disc("GreenDeadStump",0,UPPER,-44,8,UPPER,colors.bark,Enum.Material.Wood,"Floors")
-- Split broken roots form two 8-stud mantle steps, away from the lower lane.
local rootStep=block("StumpRootStep8",0,4,-61,12,8,8,colors.bark,Enum.Material.Wood,"Floors")
rootStep:SetAttribute("Climbable",true)
rootStep:SetAttribute("ClimbHeight",8)
local stump=folders.Floors:FindFirstChild("GreenDeadStump")
stump:SetAttribute("Climbable",true)
stump:SetAttribute("ClimbHeight",8)
disc("StumpTopWood",0,UPPER+0.02,-44,7.5,0.03,colors.stone,Enum.Material.Wood,"Details",false)
for _,angle in ipairs({0,1.2,2.7,4.1,5.3}) do
    local frame=CFrame.new(world(0,7,-44))*CFrame.Angles(0,angle,0)
    part("StumpBrokenRoot",Vector3.new(3,8,13),frame*CFrame.new(0,-3,10),
        colors.bark,Enum.Material.Wood,"Details",false,"WedgePart")
end
-- Stump front edge -36, circular center edge -18: equal-height 18-stud jump.
route("GreenUnderpassA",14,0,-40,14,0,-28,10,false)
route("GreenUnderpassB",14,0,-28,0,0,-22,10,false)
wall("GreenRearCover",-14,0,-75,16,6,2)
callout("Green / Stump",0,0,-57)

-- ELBOW: L-shaped outer route SNIPER -> GREEN, separate from Blue-Gold hall.
route("ElbowWest",-50,UPPER,-14,-50,UPPER,-38,12,false)
floor("ElbowCorner",-50,UPPER,-44,12,12)
route("ElbowGreenRamp",-44,UPPER,-44,-23,0,-44,12,false)
wall("ElbowOuterWest",-57,UPPER,-30,2,5,38)
wall("ElbowOuterNorth",-50,UPPER,-51,14,5,2)
pylon("ElbowCornerPylon",-55,UPPER,-47,math.pi/2)
callout("Elbow",-50,UPPER,-36)

-- GOLD: the lift shaft plus TWO real drop holes in the upper floor.
floor("GoldLower",67,0,0,46,46)
perforatedFloor("GoldUpper",UPPER,
    {48,64,68,76,80,90},{-23,-16,-8,-5,5,8,16,23},
    {{64,80,-5,5},{68,76,-16,-8},{68,76,8,16}})
wall("GoldEastBack",91,0,0,2,36,48)
wall("GoldNorthWest",49,0,-24,8,34,2)
wall("GoldNorthEast",82,0,-24,18,34,2)
arch("GoldCamoDoor",64,UPPER,-24,18,0,colors.gold)
wall("GoldSouthWest",45,0,24,2,34,4)
wall("GoldSouthEast",81,0,24,20,34,2)
arch("GoldBlueDoor",58,UPPER,24,24,0,colors.gold)
-- Tall facade and roof strips leave the shaft open; no cap across the lift.
floor("GoldRoofWest",54,34,0,16,50)
floor("GoldRoofEast",88,34,0,16,50)
wall("GoldLiftBackColumn",86,0,0,5,36,10)
glow("GoldColumnGlow",83.4,18,0,0.12,28,3,colors.gold,true)
for _,z in ipairs({-12,12}) do
    glow("GoldDropHoleMarker",72,UPPER+0.03,z-4.2,8.5,0.06,0.25,colors.gold,false)
end
floor("GoldCamoLedge",64,UPPER,-32,28,16)
floor("GoldBlueJumpLanding",54,UPPER,41,12,12)
route("GoldJumpLandingLink",54,UPPER,35,54,UPPER,24,12,false)
callout("Gold / Yellow Lift",72,0,0)
callout("Camo Ledge",64,UPPER,-32)

-- BLUE: archway, blue light and hologram; shotgun hallway below.
floor("BottomBlue",0,0,68,48,48)
perforatedFloor("BlueUpper",UPPER,{-20,-18,-6,20},{54,58,70,92},{{-18,-6,58,70}})
wall("BlueBackCenter",-4,0,94,20,36,2)
wall("BlueBackRight",22,0,94,8,36,2)
arch("BlueLowerRampDoor",-19,0,94,10,0,colors.cyan)
arch("BlueUpperRampDoor",12,UPPER,94,12,0,colors.blue)
wall("BlueWestBack",-25,0,78,2,36,34)
wall("BlueEastBack",25,0,82,2,36,26)
arch("BlueHallDoor",20,UPPER,64,12,math.pi/2,colors.blue)
arch("BlueCenterDoor",0,UPPER,54,14,0,colors.blue)
wall("BlueRoofBack",0,32,88,52,2,12)
glow("BlueBackAmbient",0,UPPER+9,92.8,40,0.45,0.12,colors.blue,true)
-- A free-standing hologram in a rear alcove, outside the main running line.
disc("BlueHologramPlinth",0,UPPER+0.6,84,3,0.6,colors.edge)
local orb=glow("BlueNebulaHologram",0,UPPER+4.1,84,4.5,4.5,4.5,colors.blue,true)
orb.Shape=Enum.PartType.Ball
orb.Transparency=0.48
for i=0,2 do
    local ring=disc("HologramProjectionRing",0,UPPER+1+i*0.8,84,2.7-i*0.4,0.045,
        colors.cyan,Enum.Material.Neon,"Details",false)
    ring.Transparency=0.55
end
-- Bottom Blue's shotgun hall is short, with entrances at both ends and above.
wall("ShotgunHallDivider",-6,0,77,1.2,12,28)
glow("ShotgunHallGuide",-23.8,3,76,0.1,0.35,25,colors.cyan,false)
floor("ShotgunEastPassage",40,0,64,32,20)
route("BottomBlueToGoldA",52,0,64,60,0,48,12,false)
route("BottomBlueToGoldB",60,0,48,60,0,23,12,false)
-- Blue drop hole is over the shotgun hall. There is no floor filling that opening.
route("BlueOuterRampA",-19,0,88,-19,8,99,10,false)
floor("BlueRampTurn",-19,8,105,12,12)
route("BlueOuterRampB",-13,8,105,6,UPPER,105,10,false)
floor("BlueRampTopTurn",12,UPPER,105,12,12)
route("BlueOuterRampC",12,UPPER,99,12,UPPER,92,10,false)
-- The optional direct Blue -> Gold jump has 18 studs between facing edges.
floor("BlueGoldJumpLaunch",25,UPPER,41,10,12)
route("BlueJumpApproach",17,UPPER,54,25,UPPER,47,10,false)
arch("BlueGoldJumpArch",25,UPPER,48,12,0,colors.blue)
callout("Blue Room",0,UPPER,74)
callout("Bottom Blue / Shotgun",-15,0,70)

-- POWER-CORE HALL: safer L-shaped Blue -> Gold upper path, with a lower drop.
perforatedFloor("PowerCoreHallEast",UPPER,{20,40,42,50,56},{56,60,68,72},{{42,50,60,68}})
floor("PowerCoreHallCorner",62,UPPER,64,12,12)
route("PowerCoreHallNorth",62,UPPER,58,62,UPPER,24,12,false)
wall("PowerCoreHallSouthWall",39,UPPER,73,38,6,2)
wall("PowerCoreHallEastWall",69,UPPER,48,2,7,46)
-- Narrow bridges beside the drop retain a continuous walking route.
floor("PowerCoreDropNorthLip",46,UPPER,58,12,4)
floor("PowerCoreDropSouthLip",46,UPPER,70,12,4)
for _,z in ipairs({34,45,56}) do
    local core=glow("WallPowerCore",67.8,UPPER+3,z,0.2,2.8,1.3,colors.blue,false)
    core:SetAttribute("DecorativeOnly",true) -- No weapons/explosions added to your game.
    block("PowerCoreRecess",68.1,UPPER+3,z,0.2,4,2.4,colors.edge,Enum.Material.Metal,"Details",false)
end
callout("Power-core Hall",62,UPPER,47)

-- Overhead Forerunner ring/arms: a recognizable canopy above the center.
for i=0,7 do
    local angle=i*math.pi/4
    local frame=CFrame.new(world(0,48,0))*CFrame.Angles(0,angle,0)
    part("OverheadRingSegment",Vector3.new(18,3,4),frame*CFrame.new(0,0,-22),
        colors.edge,Enum.Material.Metal,"Architecture",false)
    part("OverheadRib",Vector3.new(2,18,4),frame*CFrame.new(0,-6,-24)*CFrame.Angles(math.rad(18),0,0),
        colors.stone,Enum.Material.Slate,"Architecture",false)
    part("OverheadLight",Vector3.new(11,0.15,0.2),frame*CFrame.new(0,-1.6,-21),
        colors.cyan,Enum.Material.Neon,"Details",false)
end
-- Suspended underside ribs and corner columns do not intrude into walkways.
for _,pos in ipairs({{-76,0},{68,0},{0,78}}) do
    for _,offset in ipairs({-10,10}) do
        block("UnderstructureFin",pos[1]+offset,-13,pos[2],3,26,7,
            colors.edge,Enum.Material.Metal,"Architecture",false)
    end
end

-- Jungle: close trunks frame the rooms; scenery collision is disabled.
local rng=Random.new(1703)
if CONFIG.ForestDetail then
    for i=1,20 do
        local angle=i*2*math.pi/20
        local radius=rng:NextNumber(124,151)
        local x,z=math.cos(angle)*radius,math.sin(angle)*radius
        local height=rng:NextNumber(90,136)
        local tree=block("AncientForestTrunk",x,height/2-50,z,12,height,12,
            colors.bark,Enum.Material.Wood,"Forest",false)
        tree.CFrame=tree.CFrame*CFrame.Angles(0,angle,rng:NextNumber(-0.08,0.08))
        for branch=1,3 do
            local crown=block("ForestCanopy",x+rng:NextNumber(-12,12),height-52+branch*5,
                z+rng:NextNumber(-12,12),rng:NextNumber(30,48),20,rng:NextNumber(30,48),
                colors.leaves,Enum.Material.Grass,"Forest",false)
            crown.Shape=Enum.PartType.Ball
        end
        -- Hanging vine strips: no collision and no particle load.
        for vine=1,3 do
            block("HangingVine",x+rng:NextNumber(-7,7),height-60,z+rng:NextNumber(-7,7),
                0.3,rng:NextNumber(16,32),0.35,colors.moss,Enum.Material.Grass,"Forest",false)
        end
    end
    -- Giant trunk behind Green ties the architecture to the screenshot's tree.
    local giant=block("GreenAncientTree",0,22,-94,34,125,28,
        colors.bark,Enum.Material.Wood,"Forest",false)
    giant.CFrame=giant.CFrame*CFrame.Angles(0,0,-0.10)
    for i=1,16 do
        block("GreenBarkVein",rng:NextNumber(-15,15),rng:NextNumber(8,58),-79.5,
            0.5,rng:NextNumber(12,30),0.5,colors.moss,Enum.Material.Grass,"Forest",false)
    end
end
-- Small edge moss, never distributed through the middle of a movement lane.
for _,pos in ipairs({{-73,SNIPER_TOP,14},{18,0,-68},{-18,UPPER,88},{85,UPPER,19}}) do
    for i=1,5 do
        block("EdgeMoss",pos[1]+rng:NextNumber(-2,2),pos[2]+0.025,pos[3]+rng:NextNumber(-2,2),
            rng:NextNumber(1,3),0.035,rng:NextNumber(1,2),colors.moss,Enum.Material.Grass,"Details",false)
    end
end

-- Lifts follow the reference's three directed routes. No teleporting.
-- Launch points and destination attrs are available to offline geometry checks.
local lifts={}
local cooldown=setmetatable({}, {__mode="k"})
local function lift(name,x,y,z,tx,ty,tz,color,flightTime,vertical)
    floor(name.."_Base",x,y,z,10,10)
    local pad=disc(name.."_Emitter",x,y+0.035,z,3.2,0.07,color,Enum.Material.Neon,"Details",false)
    pad.Transparency=0.15
    local trigger=block(name,x,y+2.5,z,6,5,6,color,Enum.Material.ForceField,"Gameplay",false)
    trigger.Transparency=1
    trigger:SetAttribute("LaunchPoint",world(x,y+3,z))
    trigger:SetAttribute("Destination",world(tx,ty+3,tz))
    trigger:SetAttribute("FlightTime",flightTime)
    trigger:SetAttribute("EffectiveGravityMultiplier",CONFIG.LiftGravityMultiplier)
    local attachment=Instance.new("Attachment")
    attachment.Parent=trigger
    local emitter=Instance.new("ParticleEmitter")
    emitter.Color=ColorSequence.new(color)
    emitter.Rate=12
    emitter.Lifetime=NumberRange.new(0.3,0.55)
    emitter.Speed=NumberRange.new(8,14)
    emitter.SpreadAngle=Vector2.new(5,5)
    emitter.LightEmission=0.8
    emitter.Parent=attachment
    if vertical then
        local column=glow(name.."_Beam",x,y+8,z,4,16,4,color,true)
        column.Transparency=0.88
    else
        -- Side prongs form the familiar open Forerunner launcher silhouette.
        local direction=Vector3.new(tx-x,0,tz-z)
        local frame=CFrame.lookAt(world(x,y,z),world(x,y,z)+direction)
        for _,side in ipairs({-1,1}) do
            local p=part(name.."_Prong",Vector3.new(1.5,5,5),frame*CFrame.new(side*4.5,2.5,1),
                colors.edge,Enum.Material.Metal,"Architecture",true)
            glyph(p,colors.cyan)
        end
    end
    table.insert(lifts,{part=trigger,target=world(tx,ty+3,tz),time=flightTime})
end
if CONFIG.EnableLifts then
    lift("GoldLift",72,0,0,58,UPPER,0,colors.gold,0.65,true)
    floor("BottomBlueCannonPlatform",-34,0,46,12,14)
    route("BottomBlueCannonAccess",-24,0,50,-34,0,50,10,false)
    lift("BottomBlueToSniper",-34,0,46,-50,UPPER,22,colors.cyan,0.85,false)
    floor("GreenCannonPlatform",40,0,-36,12,14,true)
    route("GreenCannonAccess",23,0,-54,36,0,-36,10,false)
    lift("GreenToGold",40,0,-36,64,UPPER,-32,colors.cyan,0.70,false)
end
local heartbeat
heartbeat=RunService.Heartbeat:Connect(function()
    if map.Parent==nil then heartbeat:Disconnect() return end
    local now=os.clock()
    for _,player in ipairs(Players:GetPlayers()) do
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if root and humanoid and humanoid.Health>0 then
            if CONFIG.EnableVoidReset and root.Position.Y<CONFIG.Origin.Y-CONFIG.VoidDepth then
                humanoid.Health=0
            elseif (cooldown[root] or 0)<now then
                for _,shaft in ipairs(lifts) do
                    local p=shaft.part.CFrame:PointToObjectSpace(root.Position)
                    if math.abs(p.X)<3 and math.abs(p.Z)<3 and p.Y>-2.5 and p.Y<4 then
                        local delta=shaft.target-root.Position
                        local t=shaft.time
                        local gravity=Workspace.Gravity*CONFIG.LiftGravityMultiplier
                        root.AssemblyLinearVelocity=Vector3.new(delta.X/t,delta.Y/t+0.5*gravity*t,delta.Z/t)
                        cooldown[root]=now+t+0.6
                        break
                    end
                end
            end
        end
    end
end)
if CONFIG.EnableSpawns then
    for i,pos in ipairs({{0,UPPER,75},{56,UPPER,12},{-68,SNIPER_TOP,0},{-14,0,-58}}) do
        local spawn=Instance.new("SpawnLocation")
        spawn.Name="GuardianSpawn"..i
        spawn.Anchored=true
        spawn.Neutral=true
        spawn.Duration=0
        spawn.Size=Vector3.new(5,0.2,5)
        spawn.CFrame=CFrame.new(world(pos[1],pos[2]+0.1,pos[3]))
        spawn.Transparency=1
        spawn.CanCollide=false
        spawn.CanQuery=false
        spawn.CanTouch=false
        spawn.Parent=folders.Gameplay
    end
end
if CONFIG.SetAtmosphere then
    Lighting.ClockTime=13.5
    Lighting.Brightness=1.8
    Lighting.Ambient=Color3.fromRGB(62,83,81)
    Lighting.OutdoorAmbient=Color3.fromRGB(112,141,126)
    Lighting.FogColor=Color3.fromRGB(104,186,170)
    Lighting.FogStart=120
    Lighting.FogEnd=380
    local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere=Instance.new("Atmosphere")
        atmosphere.Name="GuardianAtmosphere"
        atmosphere.Density=0.30
        atmosphere.Offset=0.12
        atmosphere.Color=Color3.fromRGB(149,210,183)
        atmosphere.Decay=Color3.fromRGB(55,91,74)
        atmosphere.Haze=1.8
        atmosphere.Parent=Lighting
    end
end
print("Guardian generated from supplied references: 3 lifts, 2 Gold drop holes, 4 spawns.")
