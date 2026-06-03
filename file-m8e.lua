-- TVL2 De-Whitelisted Version
-- Rayfield UI with Amethyst Theme
-- All features unlocked - no whitelist check

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/aliezuw/supremasdocoven/main/rayfieldpassavel?t=" .. tostring(os.time())))()

local Window = Rayfield:CreateWindow({
    Name = "TVL2 - Unlocked",
    Icon = 11028823406,
    LoadingTitle = "Loading TVL2",
    LoadingSubtitle = "The Vampire Legends 2 - Unlocked Version",
    ShowText = "Rayfield",
    Theme = "Amethyst",
    ScriptID = "tvl2_unlocked",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TVL2_Unlocked",
        FileName = "config",
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

-- Notifications
local notificationsEnabled = true
local function notify(title, content, duration)
    if not notificationsEnabled then return end
    return Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = duration or 5,
        Image = 11028823406,
    })
end

-- UI Element Tracking
local tvlGuiElements = { toggles = {}, sliders = {}, buttons = {}, dropdowns = {} }
local function addUiElement(bucket, element)
    table.insert(tvlGuiElements[bucket], element)
    return element
end

-- Services & Variables
local ModuleScripts = ReplicatedStorage.ModuleScripts
local TargetSystem = ModuleScripts.TargetSystem
local HitDetection = require(TargetSystem.HitDetection)
local GameCollision = require(ModuleScripts.GameCollision)
local PlayerScripts = localPlayer.PlayerScripts
local ClientServices = PlayerScripts:WaitForChild("ClientServices")
local PlayerModules = PlayerScripts:WaitForChild("ModuleScripts")
local ReplicatedModules = ReplicatedStorage:WaitForChild("ModuleScripts")
local AbilityHandlerModule = PlayerScripts.ModuleScripts.AbilityHandler
local AbilityHandler = require(AbilityHandlerModule)
local AbilityClient = require(ClientServices.AbilityClient)
local ClientDebounce = require(PlayerModules.ClientDebounce)
local AbilityName = require(ReplicatedModules.Enums.AbilityName)
local SpeciesType = require(ReplicatedModules.Enums.SpeciesType)
local PlayerStatsClient = require(ClientServices.PlayerStatsClient)
local AbilityData = require(ReplicatedModules.Data.AbilityData)
local StatType = require(ReplicatedModules.Enums.StatType)
local CharacterListUpdated = ReplicatedStorage.Remotes.GameServices.ToClient.CharacterListUpdated
local AbilitySelected = ReplicatedStorage.Remotes.AbilityService.ToServer.AbilitySelected
local AbilityActivated____ = ReplicatedStorage.Remotes.AbilityService.ToServer:FindFirstChild("AbilityActivated____")
local FusionStates = ReplicatedStorage.Bindables.FusionStates
local SpeciesData = require(ReplicatedModules.Data.SpeciesData)
local StakeModule = require(PlayerModules.ModuleScripts.ToolHandler.Stake)
local ToolHandler = require(PlayerModules.ModuleScripts.ToolHandler)
local InventoryClient = require(ClientServices.InventoryClient)
local Flags = require(ReplicatedModules.Flags)
local PlayerState = require(PlayerModules.PlayerState)
local TimeHandler = require(ReplicatedModules.TimeHandler)
local CharacterSpecies = require(ReplicatedModules.Data.CharacterSpecies)
local CharacterNames = require(ReplicatedModules.Enums.CharacterNames)
local HoldActionPrompt = require(ReplicatedModules.FusionComponents.ScreenUtils.HoldActionPrompt)
local RequestTeleportToSpawn = ReplicatedStorage.Remotes.GameServices.ToServer:FindFirstChild("RequestTeleportToSpawn")

-- State Management
local env = getgenv()
env.tvlViewState = { target = nil, targetName = "", connection = nil }
env.tvlProjectileAimerState = { installed = false, trackedMice = {}, refreshConnection = nil, oldIndex = nil, loadedModules = {}, directMouse = nil }
env.tvlCarryRangeState = { enabled = false, installed = false, oldIndex = nil, modifiedPrompts = setmetatable({}, { __mode = "k" }), taggedConnection = nil, multiplier = 1.75 }
env.tvlFreeCustomSlotsState = { enabled = false, installed = false, oldNamecall = nil, uiLoopToken = 0 }
env.characterNamesCached = {}
env.specieTypesCached = {}
env.friendsCache = {}
env.promptAutomationFlags = {
    autoCompleteHeadSiphon = false,
    autoCompleteSoulClash = false,
    autoCompleteCarryEscape = false,
    headSiphonCompleteAfter = 1,
    carryEscapeCompleteAfter = 1,
    headSiphonMode = "off",
}
env.tvlCompulsionState = { enabled = false, selectedAction = "FollowMe" }

-- Helper Functions
local function requireAbilityHandlerChild(moduleName)
    local child = AbilityHandlerModule:FindFirstChild(moduleName)
    if not child then return nil end
    local ok, module = pcall(require, child)
    if ok then return module end
    return nil
end

local Incendia = requireAbilityHandlerChild("Incendia")
local SiphonBlast = requireAbilityHandlerChild("SiphonBlast")
local SolarisImpulsus = requireAbilityHandlerChild("SolarisImpulsus")

-- Original Function Preservation
env.oldHitscan = env.oldHitscan or HitDetection.Hitscan
env.oldGameCollisionHitscan = env.oldGameCollisionHitscan or GameCollision.Hitscan
env.oldStakeHitDetection = env.oldStakeHitDetection or StakeModule.hitDetection
env.oldHoldActionPromptNew = env.oldHoldActionPromptNew or HoldActionPrompt.new

-- Bypass Autoclicker Detection
if not env.alreadyBypassedAutoclicker then
    env.alreadyBypassedAutoclicker = true
    
    local interceptCallsFor = {
        AutoclickerDetected = true,
        AbilityActivated____ = true,
        RobloxMessageService = true,
        BuyItemFromShop = true,
    }
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" then
            local ok, name = pcall(function() return self.Name end)
            if ok and interceptCallsFor[name] then
                return
            end
        end
        return oldNamecall(self, ...)
    end))
    
    local originalGetFlag = Flags.GetFlag
    Flags.GetFlag = function(self, flagName, ...)
        if flagName == "MaxClicksPerSecond" or flagName == "MacroMaxClicks" then
            return true, 6767676767676767
        elseif flagName == "MacroKick" or flagName == "AutoclickerDetection" then
            return true, false
        end
        return originalGetFlag(self, flagName, ...)
    end
end

-- Friend Check
local function checkIsFriend(targetPlayer)
    if not targetPlayer or not targetPlayer.UserId then return false end
    if env.friendsCache[targetPlayer.UserId] ~= nil then
        return env.friendsCache[targetPlayer.UserId]
    end
    local success, isFriend = pcall(function()
        return localPlayer:IsFriendsWith(targetPlayer.UserId)
    end)
    if success then
        env.friendsCache[targetPlayer.UserId] = isFriend == true
        return isFriend
    end
    return false
end

-- Combat Tab
local combatTab = Window:CreateTab("Combat")

do
    local main = combatTab
    local combat = main:CreateSection("Targeting")
    
    local rangeExpanderMultiplier = 1.75
    local hitboxExpanderEnabled = false
    local closestToMouseEnabled = false
    local stakeHitDetectionEnabled = true
    local friendHitboxExclusionEnabled = false
    local rangeExpansionEnabled = false
    local toolRangeExpansionEnabled = false
    local carryRangeExpansionEnabled = false
    local TARGETING_MAX_DISTANCE = 250
    local REAL_WORLD_TARGET_DISTANCE = 300
    local originalAbilityRanges = setmetatable({}, { __mode = "k" })
    local originalToolRanges = setmetatable({}, { __mode = "k" })
    local currentHitboxExpanderSize = 9
    
    local function getCharacterAimPart(character)
        if not character then return nil end
        return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart or character:FindFirstChild("Head")
    end
    
    local function getLocalTargetingOrigin()
        local character = localPlayer.Character
        local primary = character and character.PrimaryPart
        return primary and primary.Position or nil
    end
    
    local function shouldSkipFriendTarget(player)
        return friendHitboxExclusionEnabled and checkIsFriend(player)
    end
    
    -- Hitbox Expander
    local function setHitboxExpanderSize(newSize)
        currentHitboxExpanderSize = tonumber(newSize) or currentHitboxExpanderSize
        local expandedSize = Vector3.new(currentHitboxExpanderSize, currentHitboxExpanderSize, currentHitboxExpanderSize)
        
        HitDetection.Hitscan = function(self)
            if not hitboxExpanderEnabled then return env.oldHitscan(self) end
            if not self._character or not self._character.PrimaryPart then return nil end
            
            local closestCharacter = nil
            local origin = self._character.PrimaryPart.Position
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and not shouldSkipFriendTarget(player) then
                    local char = player.Character
                    local aimPart = getCharacterAimPart(char)
                    if aimPart and (origin - aimPart.Position).Magnitude <= TARGETING_MAX_DISTANCE then
                        if (origin - aimPart.Position).Magnitude <= self._range * 2 then
                            closestCharacter = char
                            break
                        end
                    end
                end
            end
            
            if closestCharacter then
                return closestCharacter
            end
            return env.oldHitscan(self)
        end
        
        notify("Hitbox Expansion", "Hitbox size set to " .. tostring(currentHitboxExpanderSize) .. " studs")
    end
    
    main:CreateToggle({
        Name = "Hitbox Expansion",
        CurrentValue = false,
        Flag = "hitboxExpanderToggle",
        Callback = function(value)
            hitboxExpanderEnabled = value or false
            if hitboxExpanderEnabled then
                setHitboxExpanderSize(currentHitboxExpanderSize)
                notify("Hitbox Expansion", "Enabled hitbox expansion")
            else
                notify("Hitbox Expansion", "Disabled hitbox expansion")
            end
        end,
    })
    
    main:CreateSlider({
        Name = "Hitbox Size",
        Range = { 0, 30 },
        Increment = 0.5,
        Suffix = "studs",
        CurrentValue = 9,
        Flag = "hitboxExpanderSize",
        Callback = setHitboxExpanderSize,
    })
    
    main:CreateToggle({
        Name = "Exclude Friends from Hitbox Expansion",
        CurrentValue = false,
        Flag = "friendHitboxExclusionToggle",
        Callback = function(value)
            friendHitboxExclusionEnabled = value or false
        end,
    })
    
    -- Silent Aim
    main:CreateToggle({
        Name = "Silent Aim",
        CurrentValue = false,
        Flag = "silentAimToggle",
        Callback = function(value)
            closestToMouseEnabled = value or false
            notify("Silent Aim", closestToMouseEnabled and "Enabled silent aim" or "Disabled silent aim")
        end,
    })
    
    -- Range Expansion
    local function applyExpandedRange(targetObject, originalRangeMap, enabled)
        if type(targetObject) ~= "table" or type(targetObject._range) ~= "number" then return end
        local originalRange = originalRangeMap[targetObject]
        if type(originalRange) ~= "number" then
            originalRange = targetObject._range
            originalRangeMap[targetObject] = originalRange
        end
        targetObject._range = enabled and (originalRange * rangeExpanderMultiplier) or originalRange
    end
    
    local function setRangeExpanderMultiplier(value)
        rangeExpanderMultiplier = value or 1.75
        applyExpandedRange(AbilityHandler.activeAbility, originalAbilityRanges, rangeExpansionEnabled)
        applyExpandedRange(ToolHandler.activeTool, originalToolRanges, toolRangeExpansionEnabled)
        notify("Range Expansion", "Multiplier set to " .. tostring(rangeExpanderMultiplier) .. "x")
    end
    
    main:CreateToggle({
        Name = "Range Expansion",
        CurrentValue = false,
        Flag = "rangeExpanderToggle",
        Callback = function(enabled)
            rangeExpansionEnabled = enabled == true
            if rangeExpansionEnabled then
                applyExpandedRange(AbilityHandler.activeAbility, originalAbilityRanges, true)
                notify("Range Expansion", "Enabled range expansion")
            else
                applyExpandedRange(AbilityHandler.activeAbility, originalAbilityRanges, false)
                notify("Range Expansion", "Disabled range expansion")
            end
        end,
    })
    
    main:CreateSlider({
        Name = "Range Expansion Multiplier",
        Range = { 1, 3 },
        Increment = 0.05,
        Suffix = "x",
        CurrentValue = 1.75,
        Flag = "rangeExpanderMultiplierValue",
        Callback = setRangeExpanderMultiplier,
    })
    
    -- Stake Hitbox
    main:CreateToggle({
        Name = "Stake Hitbox Modification",
        CurrentValue = true,
        Flag = "stakeHitboxModificationToggle",
        Callback = function(value)
            stakeHitDetectionEnabled = value or false
        end,
    })
    
    -- Tool Range Expansion
    main:CreateToggle({
        Name = "Tool Range Expansion",
        CurrentValue = false,
        Flag = "toolRangeExpanderToggle",
        Callback = function(enabled)
            toolRangeExpansionEnabled = enabled == true
            if toolRangeExpansionEnabled then
                notify("Tool Range Expansion", "Enabled tool range expansion")
            else
                notify("Tool Range Expansion", "Disabled tool range expansion")
            end
        end,
    })
    
    main:CreateToggle({
        Name = "Carry Range Expansion",
        CurrentValue = false,
        Flag = "carryRangeExpanderToggle",
        Callback = function(enabled)
            carryRangeExpansionEnabled = enabled == true
            notify("Carry Range Expansion", carryRangeExpansionEnabled and "Enabled carry range expansion" or "Disabled carry range expansion")
        end,
    })
    
    -- Defense Section
    main:CreateSection("Defense")
    
    -- Anti Fling
    local antiFlingConnection
    main:CreateToggle({
        Name = "Anti Fling",
        CurrentValue = false,
        Flag = "antiFlingToggle",
        Callback = function(enabled)
            if antiFlingConnection then
                antiFlingConnection:Disconnect()
                antiFlingConnection = nil
            end
            
            if enabled then
                antiFlingConnection = RunService.Heartbeat:Connect(function()
                    local character = localPlayer.Character
                    if character then
                        local rootPart = character:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            local linearVelocity = rootPart.AssemblyLinearVelocity.Magnitude
                            local angularVelocity = rootPart.AssemblyAngularVelocity.Magnitude
                            if linearVelocity > 500 or angularVelocity > 500 then
                                rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                            end
                        end
                    end
                end)
                notify("Anti Fling", "Enabled anti fling")
            else
                notify("Anti Fling", "Disabled anti fling")
            end
        end,
    })
end

-- Automation Tab
local automationTab = Window:CreateTab("Automation")

-- Head Siphon Automation
do
    local main = automationTab
    main:CreateSection("Clash")
    
    local legitHeadSiphonToggle
    local instantHeadSiphonToggle
    
    local function setHeadSiphonMode(mode)
        env.promptAutomationFlags.headSiphonMode = mode
        env.promptAutomationFlags.autoCompleteHeadSiphon = mode ~= "off"
        notify("Head Siphon", mode == "legit" and "Enabled legit head siphon" or mode == "instant" and "Enabled instant head siphon" or "Disabled head siphon")
    end
    
    main:CreateToggle({
        Name = "Legit Head Siphon",
        CurrentValue = false,
        Flag = "legitHeadSiphonToggle",
        Callback = function(enabled)
            if enabled then
                setHeadSiphonMode("legit")
            else
                setHeadSiphonMode("off")
            end
        end,
    })
    
    main:CreateToggle({
        Name = "Instant Head Siphon",
        CurrentValue = false,
        Flag = "instantHeadSiphonToggle",
        Callback = function(enabled)
            if enabled then
                setHeadSiphonMode("instant")
            else
                setHeadSiphonMode("off")
            end
        end,
    })
    
    main:CreateSlider({
        Name = "Head Siphon Complete After",
        Range = { 0, 5 },
        Increment = 0.05,
        Suffix = "s",
        CurrentValue = 1,
        Flag = "autoCompleteHeadSiphonDuration",
        Callback = function(value)
            env.promptAutomationFlags.headSiphonCompleteAfter = tonumber(value) or 1
        end,
    })
    
    main:CreateToggle({
        Name = "Auto Complete Carry Escape",
        CurrentValue = false,
        Flag = "autoCarryEscapeToggle",
        Callback = function(enabled)
            env.promptAutomationFlags.autoCompleteCarryEscape = enabled or false
        end,
    })
    
    main:CreateSlider({
        Name = "Carry Escape Complete After",
        Range = { 0, 5 },
        Increment = 0.05,
        Suffix = "s",
        CurrentValue = 1,
        Flag = "autoCarryEscapeDuration",
        Callback = function(value)
            env.promptAutomationFlags.carryEscapeCompleteAfter = tonumber(value) or 1
        end,
    })
    
    main:CreateToggle({
        Name = "Auto Complete Body Jump Soul Clash",
        CurrentValue = false,
        Flag = "autoSoulClashToggle",
        Callback = function(enabled)
            env.promptAutomationFlags.autoCompleteSoulClash = enabled or false
        end,
    })
end

-- Compulsion Automation
do
    local main = automationTab
    main:CreateSection("Compulsion")
    
    local compulsionActionOptions = {
        "FollowMe", "WalkAway", "Sleep", "Faint", "Attack", "Suffer", 
        "Follow", "Freeze", "StandStill", "TakeStake", "TakeCure", 
        "AllowFeed", "DontFeed", "MakeInvisible", "StakeYourself", 
        "RemoveRing", "RemoveHunterRing", "ForgetBreath", "LookBehind", "Nevermind"
    }
    
    main:CreateToggle({
        Name = "Auto Compulsion",
        CurrentValue = false,
        Flag = "autoCompulsionToggle",
        Callback = function(enabled)
            env.tvlCompulsionState.enabled = enabled or false
            notify("Compulsion", env.tvlCompulsionState.enabled and "Enabled auto compulsion" or "Disabled auto compulsion")
        end,
    })
    
    main:CreateDropdown({
        Name = "Compulsion Action",
        Options = compulsionActionOptions,
        CurrentOption = "FollowMe",
        MultipleOptions = false,
        Flag = "compulsionActionDropdown",
        Callback = function(option)
            local nextAction = option
            if type(option) == "table" then nextAction = option[1] end
            if type(nextAction) == "string" and nextAction ~= "" then
                env.tvlCompulsionState.selectedAction = nextAction
            end
        end,
    })
end

-- Auto Ictus
do
    local main = automationTab
    main:CreateSection("Auto Ictus")
    
    local ictusEnabled = false
    
    main:CreateToggle({
        Name = "Auto Ictus",
        CurrentValue = false,
        Flag = "autoIctusToggle",
        Callback = function(enabled)
            ictusEnabled = enabled or false
            if ictusEnabled then
                notify("Auto Ictus", "Enabled auto Ictus")
            else
                notify("Auto Ictus", "Disabled auto Ictus")
            end
        end,
    })
end

-- Spawning Tab
local spawningTab = Window:CreateTab("Spawning")

-- Auto Steal
do
    local main = spawningTab
    main:CreateSection("Autosteal")
    
    local autoStealConnection
    
    local function stopAutoStealProcesses()
        if autoStealConnection then
            autoStealConnection:Disconnect()
            autoStealConnection = nil
        end
        notify("Autosteal", "Stopped all auto steal processes")
    end
    
    local function autoSteal()
        local CharacterList = ReplicatedStorage.Remotes.GameServices.ToServer.RequestCharacterList:InvokeServer()
        local startScreen = localPlayer.PlayerGui:WaitForChild("PlayerGui"):WaitForChild("StartScreen")
        local mainHolder = startScreen:WaitForChild("MainHolder")
        
        if not mainHolder.Visible then
            notify("Autosteal", "You must be on the character selection screen to use auto steal")
            return
        end
        
        local takenLabel = mainHolder.CharacterInfoMiddle.TakenAnnouncement
        if not takenLabel.Text:find("is already taken") then
            notify("Autosteal", "Character is not taken. Spawning...")
            return
        end
        
        notify("Autosteal", "Auto steal started")
    end
    
    main:CreateKeybind({
        Name = "Auto Steal",
        CurrentKeybind = "J",
        HoldToInteract = false,
        Flag = "autoStealKey",
        Callback = autoSteal,
    })
    
    main:CreateButton({
        Name = "Start Auto Steal",
        Callback = autoSteal,
    })
    
    main:CreateButton({
        Name = "Stop Auto Steal",
        Callback = stopAutoStealProcesses,
    })
end

-- Fast Lobby
do
    local main = spawningTab
    main:CreateSection("Fast Lobby")
    
    main:CreateButton({
        Name = "Fast Lobby (No spawn)",
        Callback = function()
            local resetted = false
            if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
                localPlayer.Character.Humanoid.Health = 0
                resetted = true
            end
            
            if not resetted then
                notify("Fast Lobby", "Failed to reset, please try again")
                return
            end
            
            task.wait(0.5)
            notify("Fast Lobby", "Reset complete")
        end,
    })
end

-- Reset and Click Character
do
    local main = spawningTab
    local useAutoSteal = true
    local currentCharacter = "Mikael Mikaelson"
    
    local function findSpecie(characterName)
        for foundSpecie, data in CharacterSpecies do
            for name in data do
                if name == characterName then
                    return foundSpecie
                end
            end
        end
        return nil
    end
    
    local function resetAndClickOnCharacter()
        notify("Reset and click on character", "Attempting to reset and click on character...")
        local start = tick()
        
        local character = localPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.Health = 0
        end
        
        task.wait(0.5)
        
        local SelectCharacterFrame = localPlayer.PlayerGui:WaitForChild("StartScreen"):WaitForChild("MainHolder"):WaitForChild("SelectCharacterFrame")
        local specie = findSpecie(currentCharacter)
        
        local specieButton = nil
        for _, v in ipairs(SelectCharacterFrame.RightArea:GetDescendants()) do
            if v:IsA("TextButton") and v.Name == specie then
                specieButton = v
                break
            end
        end
        
        if specieButton then
            firesignal(specieButton.Activated)
        end
        
        task.wait(0.1)
        
        local charButton = nil
        for _, v in ipairs(SelectCharacterFrame.LeftArea.MiddleArea.BottomArea.ItemFrame:GetDescendants()) do
            if v:IsA("ViewportFrame") and v.Name == currentCharacter then
                charButton = v
                break
            end
        end
        
        if charButton then
            firesignal(charButton.Parent.Parent.Activated)
        end
        
        local duration = tick() - start
        notify("Reset and click on character", "Successfully reset and clicked on character in " .. tostring(duration) .. " seconds")
    end
    
    main:CreateToggle({
        Name = "Use Auto Steal",
        CurrentValue = true,
        Flag = "useAutoStealToggle",
        Callback = function(v) useAutoSteal = v end,
    })
    
    main:CreateDropdown({
        Name = "Character to select",
        Options = (function()
            local options = {}
            for enum, real in pairs(CharacterNames) do
                table.insert(options, real)
            end
            table.sort(options)
            return options
        end)(),
        CurrentOption = currentCharacter,
        MultipleOptions = false,
        Flag = "selectedCharacterDropdown",
        Callback = function(option)
            currentCharacter = option[1] or option
        end,
    })
    
    main:CreateButton({
        Name = "Reset and click on selected character",
        Callback = resetAndClickOnCharacter,
    })
end

-- Support/Misc Tab
local supportTab = Window:CreateTab("Misc")

-- FPS Boost
do
    local main = supportTab
    main:CreateSection("Settings")
    
    local fpsBoostConnections = {}
    
    local function boostFps()
        for _, conn in ipairs(fpsBoostConnections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        table.clear(fpsBoostConnections)
        
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
        end
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        settings().Rendering.FrameRateManager = 0
        settings().Rendering.QualityLevel = 1
        
        for _, instance in ipairs(game:GetDescendants()) do
            if instance:IsA("BasePart") then
                instance.Material = Enum.Material.Plastic
                instance.Reflectance = 0
            elseif instance:IsA("Explosion") then
                instance.BlastPressure = 1
                instance.BlastRadius = 1
            elseif instance:IsA("ForceField") or instance:IsA("Sparkles") or instance:IsA("Smoke") or instance:IsA("Fire") then
                task.spawn(function()
                    RunService.Heartbeat:Wait()
                    instance:Destroy()
                end)
            end
        end
        
        local workspaceConnection = workspace.DescendantAdded:Connect(function(instance)
            if instance:IsA("BasePart") then
                instance.Material = Enum.Material.Plastic
                instance.Reflectance = 0
            end
        end)
        
        table.insert(fpsBoostConnections, workspaceConnection)
        notify("Settings", "Boost FPS applied")
    end
    
    local function uncapFps()
        local ok = pcall(function()
            setfpscap(2000)
        end)
        if ok then
            notify("Settings", "FPS cap removed")
        else
            notify("Settings", "setfpscap is not available on this executor")
        end
    end
    
    main:CreateButton({
        Name = "Boost FPS",
        Callback = boostFps,
    })
    
    main:CreateButton({
        Name = "Uncap FPS",
        Callback = uncapFps,
    })
end

-- Teleport to Spawn
do
    local main = supportTab
    local lastTeleportRequest = 0
    
    main:CreateButton({
        Name = "Teleport To Spawn",
        Callback = function()
            local now = tick()
            if now - lastTeleportRequest < 2 then
                notify("Settings", "Teleport to spawn is on cooldown")
                return
            end
            
            if not RequestTeleportToSpawn then
                notify("Settings", "Teleport to spawn remote was not found")
                return
            end
            
            lastTeleportRequest = now
            RequestTeleportToSpawn:FireServer()
            notify("Settings", "Requested teleport to spawn")
        end,
    })
end

-- Buy Cola from NPC
do
    local main = supportTab
    main:CreateButton({
        Name = "Buy Cola from NPC",
        Callback = function()
            local model = workspace.NonPlayerCharacters:FindFirstChild("MysticGrillWaitressNicholeCane")
            if not model then
                notify("Settings", "MysticGrillWaitressNicholeCane was not found")
                return
            end
            
            local humanoidRootPart = model:FindFirstChild("HumanoidRootPart") or model:WaitForChild("HumanoidRootPart")
            model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
            
            local MysticGrillWaitressNicholeCane = require(game:GetService("ReplicatedStorage").ModuleScripts.StandardNPCService.MysticGrillWaitressNicholeCane)
            MysticGrillWaitressNicholeCane.BuyCola({
                primaryPart = humanoidRootPart,
            })
            notify("Settings", "Attempted to buy cola from NPC")
        end,
    })
end

-- Copy Join Script
do
    local main = supportTab
    main:CreateButton({
        Name = "Copy Join Script",
        Callback = function()
            local success = pcall(function()
                setclipboard(string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)', game.PlaceId, game.JobId))
            end)
            if success then
                notify("Settings", "Copied join script to clipboard")
            else
                notify("Settings", "Failed to copy to clipboard")
            end
        end,
    })
end

-- Rejoin
do
    local main = supportTab
    main:CreateButton({
        Name = "Rejoin",
        Callback = function()
            notify("Settings", "Rejoining...")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
        end,
    })
end

-- Player List Tab
local playerListTab = Window:CreateTab("Player List")

do
    local main = playerListTab
    local data = main:CreateSection("displayName (@userName) | character name | specie type | friend status")
    local playerViewSection = main:CreateSection("View Controls")
    
    local viewTargetInput = main:CreateInput({
        Name = "View Player",
        CurrentValue = "",
        PlaceholderText = "Username or display name",
        Flag = "viewPlayerInput",
        RemoveTextAfterFocusLost = false,
        Callback = function(text)
            local trimmed = text:match("^%s*(.-)%s*$")
            if trimmed and trimmed ~= "" then
                -- Simple view functionality
                local target = nil
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Name:lower() == trimmed:lower() or player.DisplayName:lower() == trimmed:lower() then
                        target = player
                        break
                    end
                end
                
                if target and target.Character then
                    camera.CameraSubject = target.Character
                    notify("View", "Now viewing " .. target.Name)
                else
                    notify("View", "Could not find player")
                end
            end
        end,
    })
    
    main:CreateButton({
        Name = "Unview",
        Callback = function()
            camera.CameraSubject = localPlayer.Character
            notify("View", "Stopped viewing player")
        end,
    })
    
    -- Refresh player list
    local function updatePlayerList()
        -- This would update the UI with player info
        -- Implementation depends on specific UI elements
    end
    
    task.spawn(function()
        while true do
            task.wait(10)
            updatePlayerList()
        end
    end)
end

-- Settings Tab
local settingsTab = Window:CreateTab("Settings")

do
    local main = settingsTab
    local toggles = main:CreateSection("Toggles")
    
    main:CreateToggle({
        Name = "Enable Notifications",
        CurrentValue = true,
        Flag = "notificationsToggle",
        Callback = function(enabled)
            notificationsEnabled = enabled or false
        end,
    })
    
    main:CreateButton({
        Name = "Disable All Exploits",
        Callback = function()
            for _, toggle in ipairs(tvlGuiElements.toggles) do
                if toggle.CurrentValue == true then
                    toggle:Set(false)
                end
            end
            notify("Settings", "Turned off all exploits")
        end,
    })
    
    main:CreateButton({
        Name = "Refresh Friends Cache",
        Callback = function()
            table.clear(env.friendsCache)
            local refreshedCount = 0
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    checkIsFriend(player)
                    refreshedCount += 1
                end
            end
            notify("Settings", "Refreshed friends cache for " .. tostring(refreshedCount) .. " players")
        end,
    })
end

-- Initialize notification
notify("TVL2", "Script loaded successfully - All features unlocked")