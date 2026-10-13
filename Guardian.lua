-- Guardian reconstruction for Parkour Duels. Paste into a server Script.
-- References: the supplied Guardian article and overhead/in-game screenshots.
-- Expanded 800 x 800 stud movement arena. Vertical levels remain movement-sized.
-- Floor coordinates mean TOP surfaces. Keep your existing movement controller.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CONFIG = {
    Origin = Vector3.new(0, 64, 0),
    FootprintStuds = 800, -- Playable floor width and depth; forest extends outside.
    RouteWallHeight = 14,
    FloorSurfaceThickness = 0.12,
    SetAtmosphere = true,
    EnableSpawns = true,
    EnableLifts = true,
    EnableVoidReset = true, -- Disable if other playable areas exist below this map.
    VoidDepth = 40, -- Kill before the default Studio baseplate can catch falling players.
    ForestDetail = true,
    ForestBands = 3,
    ForestTreesPerBand = 64, -- 192 scenic trees, plus the large Green landmark.
    ForestEdgeGap = 110, -- Keeps trunks AND canopy outside the playable square.
    ForestBandSpacing = 70,
    EnableLeafGround = true,
    LeafGroundMargin = 380,
    LeafClusters = 180,
    LeafTexture = "", -- Optional permitted leaf-litter image, otherwise native leaves.
    LightingClockTime = 16.35,
    LightingBrightness = 2.25,
    MistDensity = 0.22,
    -- Match your controller's 15% gravity cancellation while airborne.
    -- Use 1 if testing without air float; lift launch calculations use this factor.
    LiftGravityMultiplier = 0.85,
    MetalTexture = "", -- Optional permitted rbxassetid://... image texture.
    StoneTexture = "", -- Defaults use native materials plus procedural panel detail.
    TextureTileStuds = 10,
}
local UPPER = 16 -- Thin deck slabs leave 15 studs of clear space below.
local SNIPER_TOP = 24
local GENERATOR_ID = "ParkourDuelsGuardian_v3"
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
for _, name in ipairs({"Floors", "Walls", "Architecture", "Details", "Forest", "Gameplay", "Callouts", "FloorSurfaces", "ForestFloor"}) do
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
    local p=part(name,Vector3.new(width,1,length),frame*CFrame.new(0,-0.5,0),
        colors.metal,Enum.Material.Metal,"Floors")
    texture(p,CONFIG.MetalTexture)
    p:SetAttribute("RouteStart",a)
    p:SetAttribute("RouteEnd",b)
    for _,side in ipairs({-1,1}) do
        part(name.."_Fascia",Vector3.new(0.65,2,length),frame*CFrame.new(side*(width/2-0.2),-1,0),
            colors.edge,Enum.Material.Metal,"Architecture",false)
        if rails then
            part(name.."_Parapet",Vector3.new(0.7,3.2,length),frame*CFrame.new(side*width/2,1.6,0),
                colors.stone,Enum.Material.Slate,"Walls")
        end
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
wall("GoldEastBack",91.75,0,0,1.5,36,48)
wall("GoldNorthWest",49,0,-24,8,34,2)
wall("GoldNorthEast",82,0,-24,18,34,2)
arch("GoldCamoDoor",64,UPPER,-24,18,0,colors.gold)
wall("GoldSouthWest",45,0,24,2,34,4)
wall("GoldSouthEast",81,0,24,20,34,2)
arch("GoldBlueDoor",58,UPPER,24,24,0,colors.gold)
-- Tall facade and roof strips leave the shaft open; no cap across the lift.
floor("GoldRoofWest",54,34,0,16,50)
floor("GoldRoofEast",85.5,34,0,11,50)
wall("GoldLiftBackColumn",86,0,0,5,36,10)
glow("GoldColumnGlow",83.4,18,0,0.12,28,3,colors.gold,true)
for _,z in ipairs({-12,12}) do
    glow("GoldDropHoleMarker",72,UPPER+0.03,z-4.2,8.5,0.06,0.25,colors.gold,false)
end
floor("GoldCamoLedge",64,UPPER,-32,28,16)
floor("GoldBlueJumpLanding",54,UPPER,41,12,12)
route("GoldJumpLandingLink",54,UPPER,35,54,UPPER,23,12,false)
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
route("PowerCoreHallNorth",62,UPPER,58,62,UPPER,23,12,false)
wall("PowerCoreHallSouthWall",39,UPPER,73,38,6,2)
wall("PowerCoreHallEastWall",69,UPPER,48,2,7,46)
-- Narrow bridges beside the drop retain a continuous walking route.
-- The perforated floor already supplies both lips; extra slabs caused flicker.
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

-- Scenery is generated after resizing, so its density and clearance use actual
-- studs instead of enlarging a sparse ring into giant, widely spaced trees.
local rng=Random.new(1703)
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
    -- The lift is supported by its host floor; no duplicate surface underneath.
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
-- Enlarge horizontally after construction, preserving the 8-stud level steps.
-- Two outer ledges make the layout bounds exactly 185 x 185 before resizing.
floor("SniperOuterWalk",-93.5,SNIPER_TOP,22,1,12)
floor("GoldOuterWalk",90.5,UPPER,0,1,46)
local SCALE=CONFIG.FootprintStuds/185
local OFFSET_X,OFFSET_Z=1.5,-18.5
map:SetAttribute("FootprintWidth",CONFIG.FootprintStuds)
map:SetAttribute("FootprintDepth",CONFIG.FootprintStuds)
map:SetAttribute("HorizontalScale",SCALE)
map:SetAttribute("LayoutOffsetX",OFFSET_X)
map:SetAttribute("LayoutOffsetZ",OFFSET_Z)
map:SetAttribute("Origin",CONFIG.Origin)
local function stretchVector(v)
    return Vector3.new(v.X*SCALE,v.Y,v.Z*SCALE)
end
local function stretchPoint(v)
    local q=v-CONFIG.Origin
    return CONFIG.Origin+Vector3.new((q.X+OFFSET_X)*SCALE,q.Y,(q.Z+OFFSET_Z)*SCALE)
end
local function layoutPoint(x,y,z)
    return stretchPoint(world(x,y,z))
end
local routes={}
for _,object in ipairs(map:GetDescendants()) do
    for _,key in ipairs({"Position","LaunchPoint","Destination","RouteStart","RouteEnd"}) do
        local value=object:GetAttribute(key)
        if value then object:SetAttribute(key,stretchPoint(value)) end
    end
    if object:IsA("BasePart") then
        local cf,oldSize=object.CFrame,object.Size
        local right=stretchVector(cf.RightVector)
        local up=stretchVector(cf.UpVector)
        local back=stretchVector(-cf.LookVector)
        local r=right.Unit
        local u=(up-r*up:Dot(r)).Unit
        local b=r:Cross(u)
        object.Size=Vector3.new(oldSize.X*right.Magnitude,
            oldSize.Y*math.abs(up:Dot(u)),oldSize.Z*math.abs(back:Dot(b)))
        object.CFrame=CFrame.fromMatrix(stretchPoint(cf.Position),r,u,b)
        if object:GetAttribute("RouteStart") then
            local a=object:GetAttribute("RouteStart")
            local finish=object:GetAttribute("RouteEnd")
            -- Rebuild sloped decks, rather than stretching their tilted thickness.
            object.Size=Vector3.new(oldSize.X*SCALE,1,(finish-a).Magnitude)
            object.CFrame=CFrame.lookAt((a+finish)/2,finish)*CFrame.new(0,-0.5,0)
            routes[object.Name]=object
        end
    elseif object:IsA("PointLight") then
        object.Range=math.min(60,object.Range*SCALE)
    end
end
for _,shaft in ipairs(lifts) do
    shaft.target=shaft.part:GetAttribute("Destination")
end

-- Compact jump runways keep the two shortcuts at 18 real studs after resizing.
local function physicalRoute(name,a,b,width)
    local p=part(name,Vector3.new(width,1,(b-a).Magnitude),
        CFrame.lookAt((a+b)/2,b)*CFrame.new(0,-0.5,0),colors.metal,Enum.Material.Metal,"Floors")
    p:SetAttribute("RouteStart",a)
    p:SetAttribute("RouteEnd",b)
    routes[name]=p
    return p
end
-- Bridge ends enter the circular decks so their full width joins the rim.
for _,name in ipairs({"CenterToSniperLower","CenterToSniperUpper","CenterToGoldLower",
    "CenterToGoldUpper","CenterToBlueLower","CenterToBlueUpper"}) do
    local p=routes[name]
    local a,b=p:GetAttribute("RouteStart"),p:GetAttribute("RouteEnd")
    a=a+(layoutPoint(0,a.Y-CONFIG.Origin.Y,0)-a).Unit*6
    p:SetAttribute("RouteStart",a)
    p.Size=Vector3.new(p.Size.X,1,(b-a).Magnitude)
    p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.new(0,-0.5,0)
end
do
    local p=routes.GreenUnderpassB
    local a,b=p:GetAttribute("RouteStart"),p:GetAttribute("RouteEnd")
    b=b+(layoutPoint(0,0,0)-b).Unit*6
    p:SetAttribute("RouteEnd",b)
    p.Size=Vector3.new(p.Size.X,1,(b-a).Magnitude)
    p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.new(0,-0.5,0)
end
local greenLanding=layoutPoint(0,UPPER,-18)
local greenTakeoff=greenLanding-Vector3.new(0,0,18)
physicalRoute("GreenJumpRunway",layoutPoint(0,UPPER,-36)-Vector3.new(0,0,3),greenTakeoff,18)
local goldLanding=layoutPoint(48,UPPER,41)
local blueTakeoff=goldLanding-Vector3.new(18,0,0)
physicalRoute("BlueGoldJumpRunway",layoutPoint(30,UPPER,41),blueTakeoff,18)
physicalRoute("StumpMantleApproach",layoutPoint(0,8,-57),layoutPoint(0,8,-52),18)
for _,jump in ipairs({{"GreenStumpToCenter",greenTakeoff,greenLanding},
    {"BlueToGold",blueTakeoff,goldLanding}}) do
    local marker=Instance.new("Folder")
    marker.Name=jump[1]
    marker:SetAttribute("JumpTakeoff",jump[2])
    marker:SetAttribute("JumpLanding",jump[3])
    marker:SetAttribute("GapStuds",18)
    marker.Parent=folders.Callouts
end

-- Corridor walls stop long open sightlines. Ends stay open for pad turns.
local function routeWalls(name,height,oneSide)
    local owner=routes[name]
    if not owner then return end
    local a,b=owner:GetAttribute("RouteStart"),owner:GetAttribute("RouteEnd")
    local length=(b-a).Magnitude
    local clearEnd=math.min(owner.Size.X/2+5,length/3)
    local frame=CFrame.lookAt((a+b)/2,b)
    for _,side in ipairs(oneSide and {-1} or {-1,1}) do
        part(name.."_EnclosingWall",Vector3.new(2,height,length-2*clearEnd),
            frame*CFrame.new(side*(owner.Size.X/2-1),height/2,0),
            colors.stone,Enum.Material.Slate,"Walls")
    end
    -- Staggered cover leaves a continuous central running lane.
    if length>75 and owner.Size.X>30 then
        local side=1
        for distance=35,length-25,55 do
            part(name.."_Cover",Vector3.new(2.5,8,15),
                frame*CFrame.new(side*owner.Size.X/4,4,-length/2+distance),
                colors.edge,Enum.Material.Metal,"Walls")
            side=-side
        end
    end
end
for _,name in ipairs({"CenterToSniperLower","CenterToGoldLower","CenterToBlueLower",
    "BottomBlueToGoldA","BottomBlueToGoldB","GreenUnderpassA","GreenUnderpassB"}) do
    routeWalls(name,11)
end
for _,name in ipairs({"CenterToSniperUpper","CenterToGoldUpper","ElbowWest",
    "ElbowGreenRamp","PowerCoreHallNorth","GoldJumpLandingLink"}) do
    routeWalls(name,CONFIG.RouteWallHeight)
end
routeWalls("CenterToBlueUpper",CONFIG.RouteWallHeight,true)
-- Outside ramps get short boundary walls, with clear space around every turn.
for _,name in ipairs({"SniperWindingRampA","SniperWindingRampB","SniperWindingRampC",
    "BlueOuterRampA","BlueOuterRampB","BlueOuterRampC"}) do
    routeWalls(name,8,true)
end
local function roomWall(name,x,bottom,z,sx,height,sz)
    return part(name,Vector3.new(sx*SCALE,height,sz*SCALE),
        CFrame.new(layoutPoint(x,bottom+height/2,z)),colors.stone,Enum.Material.Slate,"Walls")
end
-- Enclose the wide rooms, leaving their entrances, lifts, and drops open.
roomWall("BlueFrontWest",-14,UPPER,54,12,16,0.45)
roomWall("BlueFrontEast",10.5,UPPER,54,5,16,0.45)
roomWall("BlueUpperWest",-19.7,UPPER,73,0.45,16,38)
roomWall("BlueUpperEastRear",19.7,UPPER,82,0.45,16,20)
roomWall("GoldUpperWestNorth",48,UPPER,-15.5,0.45,16,15)
roomWall("GoldUpperWestSouth",48,UPPER,15.5,0.45,16,15)
roomWall("SniperUpperWest",-79.7,SNIPER_TOP,-1,0.45,18,38)
roomWall("SniperUpperFrontWest",-75,SNIPER_TOP,18,10,14,0.45)
roomWall("GreenNorthWall",0,0,-73.6,46,14,0.45)
roomWall("GreenWestWall",-22.6,0,-64,0.45,14,20)
roomWall("GreenEastWall",22.6,0,-66,0.45,14,16)
-- Broad chambers get partial dividing walls with 24+ stud passing space.
roomWall("BlueRoomScreenWest",-11,UPPER,78,8,12,0.5)
roomWall("BlueRoomScreenEast",11,UPPER,72,8,12,0.5)
roomWall("GoldRoomScreenNorth",57,UPPER,-14,10,12,0.5)
roomWall("GoldRoomScreenSouth",83,UPPER,14,10,12,0.5)
roomWall("GreenCoverWest",-12,0,-61,0.5,8,8)
roomWall("GreenCoverEast",12,0,-53,0.5,8,8)

-- Build disjoint visible floor patches. Overlapping collision slabs are hidden;
-- their union remains solid, but two top faces can never flicker at the same Y.
local EPS=0.000001
local function cross2(a,b,c)
    return (b.X-a.X)*(c.Z-a.Z)-(b.Z-a.Z)*(c.X-a.X)
end
local function splitPolygon(poly,a,b)
    local inside,outside={},{}
    for i,p in ipairs(poly) do
        local q=poly[i%#poly+1]
        local dp,dq=cross2(a,b,p),cross2(a,b,q)
        if dp>=-EPS then table.insert(inside,p) end
        if dp<=EPS then table.insert(outside,p) end
        if (dp>EPS and dq< -EPS) or (dp< -EPS and dq>EPS) then
            local hit=p+(q-p)*(dp/(dp-dq))
            table.insert(inside,hit)
            table.insert(outside,hit)
        end
    end
    return inside,outside
end
local function area(poly)
    local total=0
    for i,p in ipairs(poly) do
        local q=poly[i%#poly+1]
        total=total+p.X*q.Z-q.X*p.Z
    end
    return total/2
end
local function bounds(poly)
    local xmin,xmax,zmin,zmax=math.huge,-math.huge,math.huge,-math.huge
    for _,v in ipairs(poly) do
        xmin,xmax=math.min(xmin,v.X),math.max(xmax,v.X)
        zmin,zmax=math.min(zmin,v.Z),math.max(zmax,v.Z)
    end
    return {xmin,xmax,zmin,zmax}
end
local function subtractPolygon(poly,cutter)
    local pb,cb=bounds(poly),bounds(cutter)
    if pb[2]<=cb[1]+EPS or cb[2]<=pb[1]+EPS or pb[4]<=cb[3]+EPS or cb[4]<=pb[3]+EPS then
        return {poly}
    end
    local remaining=poly
    local output={}
    for i,a in ipairs(cutter) do
        if #remaining<3 then break end
        local inside,outside=splitPolygon(remaining,a,cutter[i%#cutter+1])
        if #outside>=3 and math.abs(area(outside))>0.001 then table.insert(output,outside) end
        remaining=inside
    end
    return output
end
local function renderTriangle(a,b,c,color,material)
    local ab,ac,bc=b-a,c-a,c-b
    if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then
        c,a=a,c
    elseif ac:Dot(ac)>bc:Dot(bc) then
        a,b=b,a
    end
    ab,ac,bc=b-a,c-a,c-b
    if bc.Magnitude<0.01 then return end
    local normal=ac:Cross(ab)
    if normal.Magnitude<0.01 then return end
    local right=normal.Unit
    local up=bc:Cross(right).Unit
    local back=bc.Unit
    local height=math.abs(ab:Dot(up))
    if height<0.05 then return end
    local projection=b-back*ab:Dot(back)
    local lower=Vector3.new(0,-CONFIG.FloorSurfaceThickness/2,0)
    for _,t in ipairs({{a,b,projection,right,back},{a,c,projection,-right,-back}}) do
        local length=math.abs((t[2]-t[1]):Dot(t[5]))
        if length>=0.05 then
            local patch=part("FloorPatch",Vector3.new(CONFIG.FloorSurfaceThickness,height,length),
                CFrame.fromMatrix((t[1]+t[2])/2+lower,t[4],up,t[5]),color,material,"FloorSurfaces",false,"WedgePart")
            patch:SetAttribute("TriangleA",t[1])
            patch:SetAttribute("TriangleB",t[2])
            patch:SetAttribute("TriangleC",t[3])
            texture(patch,material==Enum.Material.Slate and CONFIG.StoneTexture or CONFIG.MetalTexture)
        end
    end
end
local function renderPolygon(poly,color,material)
    if #poly==4 then
        local first,last=poly[2]-poly[1],poly[4]-poly[1]
        if first.Magnitude>=0.05 and last.Magnitude>=0.05
            and math.abs(first.Unit:Dot(last.Unit))<0.000001
            and ((poly[1]+poly[3])-(poly[2]+poly[4])).Magnitude<0.001 then
            local right=first.Unit
            local panel=part("FloorPanel",Vector3.new(first.Magnitude,CONFIG.FloorSurfaceThickness,last.Magnitude),
                CFrame.fromMatrix((poly[1]+poly[3])/2-Vector3.new(0,CONFIG.FloorSurfaceThickness/2,0),
                    right,Vector3.new(0,1,0),right:Cross(Vector3.new(0,1,0))),
                color,material,"FloorSurfaces",false)
            for i,v in ipairs(poly) do panel:SetAttribute("Quad"..i,v) end
            texture(panel,material==Enum.Material.Slate and CONFIG.StoneTexture or CONFIG.MetalTexture)
            return
        end
    end
    if #poly<=8 then
        for i=2,#poly-1 do renderTriangle(poly[1],poly[i],poly[i+1],color,material) end
        return
    end
    -- A center fan avoids thin edge triangles that Roblox would enlarge to its
    -- minimum Part size, producing a new visible overlap along circular rims.
    local center=Vector3.new(0,0,0)
    for _,v in ipairs(poly) do center=center+v end
    center=center/#poly
    for i,v in ipairs(poly) do renderTriangle(center,v,poly[i%#poly+1],color,material) end
end
local layers={}
for _,p in ipairs(folders.Floors:GetChildren()) do
    local polygon={}
    local top
    if p.Shape==Enum.PartType.Cylinder and math.abs(p.CFrame.RightVector.Y)>0.999 then
        top=p.Position.Y+p.Size.X/2
        for i=0,127 do
            local angle=i*math.pi/64
            local v=p.CFrame:PointToWorldSpace(Vector3.new(0,math.cos(angle)*p.Size.Y/2,math.sin(angle)*p.Size.Z/2))
            table.insert(polygon,Vector3.new(v.X,top,v.Z))
        end
    elseif p.CFrame.UpVector.Y>0.99999 then
        top=p.Position.Y+p.Size.Y/2
        for _,v in ipairs({{-1,-1},{1,-1},{1,1},{-1,1}}) do
            table.insert(polygon,p.CFrame:PointToWorldSpace(Vector3.new(v[1]*p.Size.X/2,p.Size.Y/2,v[2]*p.Size.Z/2)))
        end
    end
    if #polygon>=3 then
        if area(polygon)<0 then
            local reverse={}
            for i=#polygon,1,-1 do table.insert(reverse,polygon[i]) end
            polygon=reverse
        end
        local key=string.format("%.4f",top)
        layers[key]=layers[key] or {}
        local pending={polygon}
        for _,occupied in ipairs(layers[key]) do
            local nextPieces={}
            for _,piece in ipairs(pending) do
                for _,fragment in ipairs(subtractPolygon(piece,occupied)) do table.insert(nextPieces,fragment) end
            end
            pending=nextPieces
            if #pending==0 then break end
        end
        for _,piece in ipairs(pending) do
            renderPolygon(piece,p.Color,p.Material)
        end
        table.insert(layers[key],polygon)
        -- Retain substantial wood bodies just below their newly drawn top.
        local thickness=p.Shape==Enum.PartType.Cylinder and p.Size.X or p.Size.Y
        if thickness>2 then
            local size=p.Size
            if p.Shape==Enum.PartType.Cylinder then size=Vector3.new(size.X-0.15,size.Y,size.Z)
            else size=Vector3.new(size.X,size.Y-0.15,size.Z) end
            local body=part(p.Name.."_Body",size,p.CFrame+Vector3.new(0,-0.075,0),p.Color,p.Material,"Architecture",false)
            body.Shape=p.Shape
        end
        p.Transparency=1
        p.CastShadow=false
    end
end
map:SetAttribute("FloorPatches",#folders.FloorSurfaces:GetChildren())
map:SetAttribute("WallParts",#folders.Walls:GetChildren())

-- A leafy underlay covers the view through the arena gaps. It is visual only.
-- An existing Studio baseplate also receives the appearance without moving it.
local baseplate=Workspace:FindFirstChild("Baseplate")
if baseplate and not baseplate:IsA("BasePart") then baseplate=nil end
local fallbackGround=CONFIG.Origin.Y-72
local baseplateTop=baseplate and (baseplate.Position.Y+baseplate.Size.Y/2) or fallbackGround
local groundTop=math.min(baseplateTop+0.06,CONFIG.Origin.Y-CONFIG.VoidDepth-10)
map:SetAttribute("SceneGroundTop",groundTop)
if CONFIG.EnableLeafGround then
    local groundColor=Color3.fromRGB(54,75,43)
    if baseplate then
        baseplate.Material=Enum.Material.LeafyGrass
        baseplate.Color=groundColor
        -- Hide the default checker grid instead of layering leaves over it.
        for _,mark in ipairs(baseplate:GetChildren()) do
            if (mark:IsA("Texture") or mark:IsA("Decal")) and mark.Face==Enum.NormalId.Top then
                if mark.Name~="GuardianLeafTexture" then mark.Transparency=1 end
            end
        end
        local topTexture=baseplate:FindFirstChild("GuardianLeafTexture")
        if CONFIG.LeafTexture~="" then
            if not topTexture then
                topTexture=Instance.new("Texture")
                topTexture.Name="GuardianLeafTexture"
                topTexture.Face=Enum.NormalId.Top
                topTexture.Parent=baseplate
            end
            topTexture.Texture=CONFIG.LeafTexture
            topTexture.StudsPerTileU=18
            topTexture.StudsPerTileV=18
            topTexture.Transparency=0
        elseif topTexture then
            topTexture:Destroy()
        end
    end
    local groundSpan=CONFIG.FootprintStuds+CONFIG.LeafGroundMargin*2
    local ground=part("LeafGround",Vector3.new(groundSpan,2,groundSpan),
        CFrame.new(CONFIG.Origin.X,groundTop-1,CONFIG.Origin.Z),groundColor,
        Enum.Material.LeafyGrass,"ForestFloor",false)
    ground.CastShadow=false
    ground:SetAttribute("DecorativeOnly",true)
    if CONFIG.LeafTexture~="" then
        local image=Instance.new("Texture")
        image.Name="LeafLitterTexture"
        image.Face=Enum.NormalId.Top
        image.Texture=CONFIG.LeafTexture
        image.StudsPerTileU=18
        image.StudsPerTileV=18
        image.Parent=ground
    end
    -- Flat oval leaves add real litter detail without needing an uploaded asset.
    local leafColors={Color3.fromRGB(76,101,48),Color3.fromRGB(97,115,57),
        Color3.fromRGB(111,101,57),Color3.fromRGB(58,85,42)}
    local litterRng=Random.new(7813)
    for cluster=1,CONFIG.LeafClusters do
        local x=CONFIG.Origin.X+litterRng:NextNumber(-groundSpan/2+12,groundSpan/2-12)
        local z=CONFIG.Origin.Z+litterRng:NextNumber(-groundSpan/2+12,groundSpan/2-12)
        for leaf=1,3 do
            local p=part("LeafPatch",Vector3.new(litterRng:NextNumber(2.5,4.5),0.12,litterRng:NextNumber(5,9)),
                CFrame.new(x+litterRng:NextNumber(-3,3),groundTop+0.10+leaf*0.045,z+litterRng:NextNumber(-3,3))
                    *CFrame.Angles(0,litterRng:NextNumber(0,math.pi*2),0),
                leafColors[litterRng:NextInteger(1,#leafColors)],Enum.Material.Grass,"ForestFloor",false)
            p.Shape=Enum.PartType.Ball
            p.CastShadow=false
            p:SetAttribute("DecorativeOnly",true)
        end
    end
end

-- Three staggered square belts immerse all four sides without entering the map.
local treeRng=Random.new(1703)
local treeCount=0
if CONFIG.ForestDetail then
    local half=CONFIG.FootprintStuds/2
    local perBand=math.max(4,math.floor(CONFIG.ForestTreesPerBand/4)*4)
    for band=1,CONFIG.ForestBands do
        local radius=half+CONFIG.ForestEdgeGap+(band-1)*CONFIG.ForestBandSpacing
        local perSide=perBand/4
        for index=1,perBand do
            local side=math.floor((index-1)/perSide)
            local slot=(index-1)%perSide
            local along=((slot+0.5+treeRng:NextNumber(-0.18,0.18)+(band-1)*0.15)/perSide*2-1)*radius
            local edge=radius+treeRng:NextNumber(-8,8)
            local x,z
            if side==0 then x,z=along,-edge
            elseif side==1 then x,z=edge,along
            elseif side==2 then x,z=-along,edge
            else x,z=-edge,-along end
            x,z=x+CONFIG.Origin.X,z+CONFIG.Origin.Z
            local height=treeRng:NextNumber(180,270)+(band-1)*12
            local width=treeRng:NextNumber(9,16)
            local center=Vector3.new(x,groundTop+height/2-6,z)
            local trunk=part("AncientForestTrunk",Vector3.new(height,width,width),
                CFrame.new(center)*CFrame.Angles(0,0,math.pi/2+treeRng:NextNumber(-0.035,0.035)),
                colors.bark,Enum.Material.Wood,"Forest",false)
            trunk.Shape=Enum.PartType.Cylinder
            trunk.CastShadow=band==1
            trunk:SetAttribute("DecorativeTree",true)
            trunk:SetAttribute("ForestBand",band)
            treeCount=treeCount+1
            local top=groundTop+height-6
            for crown=1,3 do
                local canopy=part("ForestCanopy",Vector3.new(treeRng:NextNumber(60,88),treeRng:NextNumber(34,55),treeRng:NextNumber(58,86)),
                    CFrame.new(x+treeRng:NextNumber(-18,18),top-18+(crown-1)*12,z+treeRng:NextNumber(-18,18)),
                    crown==2 and Color3.fromRGB(49,83,48) or colors.leaves,Enum.Material.Grass,"Forest",false)
                canopy.Shape=Enum.PartType.Ball
                canopy.CastShadow=false
            end
            -- A branch and a vine silhouette add depth to the closest belt.
            if band==1 then
                local a=Vector3.new(x,top-38,z)
                local b=a+Vector3.new(treeRng:NextNumber(-20,20),13,treeRng:NextNumber(-20,20))
                local branch=part("ForestBranch",Vector3.new(4,4,(b-a).Magnitude),
                    CFrame.lookAt((a+b)/2,b),colors.bark,Enum.Material.Wood,"Forest",false)
                branch.CastShadow=false
                local vine=part("HangingVine",Vector3.new(0.45,treeRng:NextNumber(25,48),0.5),
                    CFrame.new(x+12,top-42,z+8),colors.moss,Enum.Material.Grass,"Forest",false)
                vine.CastShadow=false
            end
        end
    end
    -- Keep Green's ancient tree as a distant landmark, rooted into the litter.
    local giantZ=CONFIG.Origin.Z-half-CONFIG.ForestEdgeGap-40
    local giant=part("GreenAncientTree",Vector3.new(65,300,55),
        CFrame.new(CONFIG.Origin.X+6,groundTop+144,giantZ),colors.bark,Enum.Material.Wood,"Forest",false)
    giant:SetAttribute("DecorativeOnly",true)
    giant.CastShadow=false
    for crown=1,3 do
        local canopy=part("AncientTreeCrown",Vector3.new(100,58,92),
            CFrame.new(CONFIG.Origin.X+(crown-2)*20,groundTop+280+crown*9,giantZ),
            colors.leaves,Enum.Material.Grass,"Forest",false)
        canopy.Shape=Enum.PartType.Ball
        canopy.CastShadow=false
    end
end
map:SetAttribute("ForestTreeCount",treeCount)

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
                    if math.abs(p.X)<shaft.part.Size.X/2 and math.abs(p.Z)<shaft.part.Size.Z/2
                        and p.Y>-shaft.part.Size.Y/2 and p.Y<shaft.part.Size.Y/2+1.5 then
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
        spawn.CFrame=CFrame.new(layoutPoint(pos[1],pos[2]+0.1,pos[3]))
        spawn.Transparency=1
        spawn.CanCollide=false
        spawn.CanQuery=false
        spawn.CanTouch=false
        spawn.Parent=folders.Gameplay
    end
end
if CONFIG.SetAtmosphere then
    -- Late-afternoon light with cool mist; ambient fill keeps enclosed rooms clear.
    Lighting.ClockTime=CONFIG.LightingClockTime
    Lighting.Brightness=CONFIG.LightingBrightness
    Lighting.ExposureCompensation=0.15
    Lighting.Ambient=Color3.fromRGB(96,113,119)
    Lighting.OutdoorAmbient=Color3.fromRGB(130,151,141)
    Lighting.EnvironmentDiffuseScale=0.65
    Lighting.EnvironmentSpecularScale=0.55
    Lighting.GlobalShadows=true
    Lighting.ShadowSoftness=0.45
    Lighting.FogColor=Color3.fromRGB(99,135,139)
    Lighting.FogStart=CONFIG.FootprintStuds*0.42
    Lighting.FogEnd=CONFIG.FootprintStuds*1.7
    local atmosphere=Lighting:FindFirstChild("GuardianAtmosphere") or Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere=Instance.new("Atmosphere")
        atmosphere.Name="GuardianAtmosphere"
        atmosphere.Parent=Lighting
    end
    -- Apply on every run, including when the previous version created it.
    atmosphere.Density=CONFIG.MistDensity
    atmosphere.Offset=0.12
    atmosphere.Color=Color3.fromRGB(145,180,176)
    atmosphere.Decay=Color3.fromRGB(61,85,99)
    atmosphere.Haze=1.3
    atmosphere.Glare=0.10
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
    grade.Brightness=0.015
    grade.Contrast=0.06
    grade.Saturation=-0.07
    grade.TintColor=Color3.fromRGB(226,239,238)
    local bloom=ownedEffect("GuardianBloom","BloomEffect")
    bloom.Intensity=0.10
    bloom.Size=20
    bloom.Threshold=1.4
end
print("Guardian generated: leafy ground, "..treeCount.." scenic forest trees, readable dusk lighting.")
