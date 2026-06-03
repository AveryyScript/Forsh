local rawIndex
xpcall(function()
	return game.NonExistentProperty
end, function()
	rawIndex = debug.info(2, "f")
end)

settings().Network.IncomingReplicationLag = -9999999999999999999999999999
settings().Rendering.FrameRateManager = 0

pcall(restorefunc, rawIndex)
pcall(restorefunc, rawIndex(game, "HttpGet"))
pcall(restorefunc, rawIndex(game.Players.LocalPlayer, "Kick"))
pcall(restorefunc, request)
pcall(restorefunc, loadstring)
pcall(restorefunc, game.HttpService.UrlEncode)
pcall(restorefunc, game.HttpService.JSONDecode)
pcall(restorefunc, game.HttpService.JSONEncode)
pcall(restorefunc, game:GetService("RbxAnalyticsService").GetClientId)
pcall(restorefunc, setclipboard)
pcall(restorefunc, tostring)

-- clone (only use these)
local HttpGet = clonefunction(game.HttpGet)
local Kick = clonefunction(game.Players.LocalPlayer.Kick)
local request = clonefunction(request)
local loadstring = clonefunction(loadstring)
local tostring = clonefunction(tostring)
local UrlEncode = clonefunction(game.HttpService.UrlEncode)
local HttpService = game:GetService("HttpService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local GetClientId = clonefunction(game:GetService("RbxAnalyticsService").GetClientId)
local JSONDecode = clonefunction(game.HttpService.JSONDecode)
local JSONEncode = clonefunction(game.HttpService.JSONEncode)
local setClipboard = type(setclipboard) == "function" and clonefunction(setclipboard) or setclipboard

local function getWhitelistValuesForTier(tierValue, key)
	if type(tierValue) ~= "table" then
		return {}
	end

	if type(tierValue[key]) == "table" then
		return tierValue[key]
	end

	return tierValue
end

local function sendWebhook(webhookUrl, embed)
	local data = {
		embeds = {embed}
	}

	local jsonData = HttpService:JSONEncode(data)

	pcall(function()
		request({
			Url = webhookUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = jsonData
		})
	end)
end

local function sendKickWebhook(playerName, userId, tier, reason)
	local webhookUrl = "https://discord.com/api/webhooks/1494783379709755594/qoluLqCu7fwxhd8Kr7-LtrEYsBgapw3WOR9Epq5a9N5NZfHeZVnbkdTesPCGRUnVwtmD"

	local embed = {
		title = "🚨 ACCESS DENIED 🚨",
		description = string.format(
			"**Jogador:** %s\n**UserID:** %s\n**Rank:** %s\n**Motivo:** %s",
			playerName,
			userId,
			tier,
			reason
		),
		color = 0xFF0000,
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
	}

	sendWebhook(webhookUrl, embed)
end

local function sendAccessWebhook(playerName, userId, tier)
	local webhookUrl = "https://discord.com/api/webhooks/1494783223908012032/IkEyVfSPRafFvSWkwxA0Ekw-B-CxvcprFQCcn3WONUML3FE6kLW7xOgEG4KZL0cvKywEI"

	local colors = {
		normal = 0x00FF00,
		premium = 0xFFD700,
		supreme = 0xFF00FF
	}

	local embed = {
		title = "✅ ACCESS ALLOWED ✅",
		description = string.format(
			"**Jogador:** %s\n**UserID:** %s\n**Rank:** %s",
			playerName,
			userId,
			tier:upper()
		),
		color = colors[tier] or 0x00AAFF,
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
	}

	sendWebhook(webhookUrl, embed)
end

local function kickForMissingWhitelist()
	local playerName = game.Players.LocalPlayer.Name
	local userId = game.Players.LocalPlayer.UserId

	sendKickWebhook(playerName, userId, "None", "Not on whitelist")

	local kickMessage = "Acesso Denied. Dm @ali_inchains on discord to buy xoxo"
	if type(setClipboard) == "function" then
		pcall(setClipboard)
	end

	game.Players.LocalPlayer:Kick(kickMessage)
	task.spawn(function()
		task.wait(5)
		game:Shutdown()
		for _, v in game:GetDescendants() do
			pcall(v.Destroy, v)
		end
	end)
end

local success, response = pcall(function()
	return game:HttpGet("https://raw.githubusercontent.com/aliezuw/supremasdocoven/main/soentraquemequero?t="..tick())
end)

if not success then
	return nil
end

local parsed = JSONDecode(HttpService, response)
if not parsed or not parsed.whitelist then
	return nil
end

local wl = parsed.whitelist

local function isSupremePlayer(userId)
	if not wl or not wl.supreme then
		return false
	end

	for _, id in ipairs(getWhitelistValuesForTier(wl.supreme, "users")) do
		if id == userId then
			return true
		end
	end

	return false
end

local function isFriendOfSupreme(targetPlayer)
	if not targetPlayer or not targetPlayer.UserId then
		return false
	end

	local success, isFriend = pcall(function()
		return game.Players.LocalPlayer:IsFriendsWith(targetPlayer.UserId)
	end)

	return success and isFriend == true
end

local function getPlayerFromCharacter(character)
	if not character then
		return nil
	end

	for _, player in ipairs(game.Players:GetPlayers()) do
		if player.Character == character then
			return player
		end
	end

	return nil
end

local function checkAndKickForSupremeTarget(targetCharacter)
	if not targetCharacter then
		return false
	end

	local targetPlayer = getPlayerFromCharacter(targetCharacter)
	if not targetPlayer then
		return false
	end

	if isSupremePlayer(targetPlayer.UserId) then
		if not isFriendOfSupreme(targetPlayer) then
			local playerName = game.Players.LocalPlayer.Name
			local userId = game.Players.LocalPlayer.UserId

			sendKickWebhook(playerName, userId, "Supreme", "Tentou afetar um jogador Supreme sem ser amigo")

			local kickMessage = "You cannot affect a supreme player."
			game.Players.LocalPlayer:Kick(kickMessage)
			return true
		end
	end

	return false
end

local function getTier(whitelist, userId)
	for _, id in ipairs(getWhitelistValuesForTier(whitelist.premium, "users")) do
		if id == userId then
			return "premium"
		end
	end

	for _, id in ipairs(getWhitelistValuesForTier(whitelist.normal, "users")) do
		if id == userId then
			return "normal"
		end
	end

	for _, id in ipairs(getWhitelistValuesForTier(whitelist.supreme, "users")) do
		if id == userId then
			return "supreme"
		end
	end

	return nil
end

local tier = getTier(wl, game.Players.LocalPlayer.UserId)

if not tier then
	kickForMissingWhitelist()
	return
else
	local playerName = game.Players.LocalPlayer.Name
	local userId = game.Players.LocalPlayer.UserId
	sendAccessWebhook(playerName, userId, tier)
end
-- functions
local getenv = getenv
local gethui = gethui
local hookfunction = hookfunction
local islclosure = islclosure
local getgc = getgc
local firesignal = firesignal
local setclipboard = setclipboard
local readfile = readfile
local writefile = writefile
local makefolder = makefolder
local isfolder = isfolder
local isfile = isfile
local WebSocket = Websocket or websocket
local websocket = WebSocket
local syn = syn or nil
local env = getenv()

local function trimText(value)
	return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function closeSocketValue(socket)
	if not socket then
		return
	end

	pcall(function()
		if type(socket.Close) == "function" then
			socket:Close()
		elseif type(socket.close) == "function" then
			socket:close()
		end
	end)
end

local function cleanupConnectionValue(value)
	local valueType = typeof(value)
	if valueType == "RBXScriptConnection" then
		value:Disconnect()
	elseif valueType == "Instance" then
		value:Destroy()
	end
end

local function removeUiValue(value)
	if not value then
		return
	end

	if value.Remove then
		value:Remove()
	elseif value.Destroy then
		value:Destroy()
	end
end

local function playHelpNotificationSound()
	local sound = Instance.new("Sound", gethui() or game:GetService("CoreGui"))
	sound.SoundId = "rbxassetid://131390520971848"
	sound.PlayOnRemove = true
	sound:Destroy()
end

if env.tvlHelpSocket then
	closeSocketValue(env.tvlHelpSocket)
	env.tvlHelpSocket = nil
end

if env.tvlViewState then
	local previousViewState = env.tvlViewState
	if typeof(previousViewState.connection) == "RBXScriptConnection" then
		previousViewState.connection:Disconnect()
	end
	env.tvlViewState = nil
end

if env.tvlGui then
	for _, connection in pairs(env.tvlGui.connections) do
		cleanupConnectionValue(connection)
	end
	env.tvlGui.Rayfield:Destroy()
	env.tvlGui = nil
end

if env.tvlCommandBar then
	pcall(function()
		env.tvlCommandBar:Destroy()
	end)
	env.tvlCommandBar = nil
end

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local CoreGui = gethui() or game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
-- Variables
local ModuleScripts = ReplicatedStorage.ModuleScripts
local TargetSystem = ModuleScripts.TargetSystem
local HitDetection = require(TargetSystem.HitDetection)
local GameCollision = require(ModuleScripts.GameCollision)
local localPlayer = Players.LocalPlayer
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
local function requireAbilityHandlerChild(moduleName)
	local child = AbilityHandlerModule:FindFirstChild(moduleName)
	if not child then
		return nil
	end

	local ok, module = pcall(require, child)
	if ok then
		return module
	end

	return nil
end

local Incendia = requireAbilityHandlerChild("Incendia")
local SiphonBlast = requireAbilityHandlerChild("SiphonBlast")
local SolarisImpulsus = requireAbilityHandlerChild("SolarisImpulsus")
local mouse = localPlayer:GetMouse()
local playerGui = localPlayer:WaitForChild("PlayerGui")
local CharacterListUpdated = ReplicatedStorage.Remotes.GameServices.ToClient.CharacterListUpdated
local AbilitySelected = ReplicatedStorage.Remotes.AbilityService.ToServer.AbilitySelected
local AbilityActivated____ = ReplicatedStorage.Remotes.AbilityService.ToServer:FindFirstChild("AbilityActivated____")
local AbilityBindables = PlayerScripts:WaitForChild("Bindables"):WaitForChild("Abilities")
local FusionStates = ReplicatedStorage.Bindables.FusionStates
local ShowCharacters = require(ReplicatedStorage.ModuleScripts.Data.ShowCharacters)
local selectedShadow
local camera = workspace.CurrentCamera
local SpeciesData = require(ReplicatedStorage.ModuleScripts.Data.SpeciesData)
local StakeModule = require(PlayerScripts.ModuleScripts.ToolHandler.Stake)
local ToolHandler = require(PlayerScripts.ModuleScripts.ToolHandler)
local InventoryClient = require(ClientServices.InventoryClient)
local Flags = require(ReplicatedStorage.ModuleScripts.Flags)
local PlayerState = require(PlayerModules.PlayerState)
local TimeHandler = require(ReplicatedStorage.ModuleScripts.TimeHandler)
local PlayerGui = localPlayer:WaitForChild("PlayerGui")
local CharacterSpecies = require(ReplicatedStorage.ModuleScripts.Data.CharacterSpecies)
local CharacterNames = require(ReplicatedStorage.ModuleScripts.Enums.CharacterNames)
local HoldActionPrompt = require(ReplicatedStorage.ModuleScripts.FusionComponents.ScreenUtils.HoldActionPrompt)

if workspace.NonPlayerCharacters:FindFirstChild("MysticGrillWaitressNicholeCane") then
	workspace.NonPlayerCharacters:FindFirstChild("MysticGrillWaitressNicholeCane").ModelStreamingMode =
		Enum.ModelStreamingMode.Persistent
end

-- previous
env.oldHitscan = env.oldHitscan or HitDetection.Hitscan
env.oldGameCollisionHitscan = env.oldGameCollisionHitscan or GameCollision.Hitscan
env.oldStakeHitDetection = env.oldStakeHitDetection or StakeModule.hitDetection
env.oldHoldActionPromptNew = env.oldHoldActionPromptNew or HoldActionPrompt.new
env.promptAutomationFlags = env.promptAutomationFlags
	or {
		autoCompleteHeadSiphon = false,
		autoCompleteSoulClash = false,
		autoCompleteCarryEscape = false,
		headSiphonCompleteAfter = 1,
		carryEscapeCompleteAfter = 1,
		headSiphonMode = "off",
	}

do
	local SoulClashPrompt = require(PlayerScripts.ModuleScripts.AbilityHandler.BodyJump.SoulClashPrompt)
	local screenUtils = ReplicatedStorage.ModuleScripts.FusionComponents.ScreenUtils
	local carryHandler = PlayerScripts.ModuleScripts:WaitForChild("CarryHandler")
	local EscapeSiphonPrompt = require(screenUtils:WaitForChild("EscapeSiphonPrompt"))
	local EscapeCarryPrompt = require(carryHandler:WaitForChild("EscapeCarryPrompt"))
	local EscapeCarryPromptNew = require(carryHandler:WaitForChild("EscapeCarryPromptNew"))

	env.oldSoulClashPromptNew = env.oldSoulClashPromptNew or SoulClashPrompt.new
	env.oldEscapeSiphonPromptNew = env.oldEscapeSiphonPromptNew or EscapeSiphonPrompt.new
	env.oldEscapeCarryPromptNew = env.oldEscapeCarryPromptNew or EscapeCarryPrompt.new
	env.oldEscapeCarryPromptNewer = env.oldEscapeCarryPromptNewer or EscapeCarryPromptNew.new

	local function getPromptIdentifierFromArgs(...)
		for index = 1, select("#", ...) do
			local argument = select(index, ...)
			if type(argument) == "string" then
				local lowered = argument:lower()
				if lowered:find("head") or lowered:find("siphon") then
					return lowered
				end
			elseif type(argument) == "table" then
				for _, key in ipairs({ "Name", "Title", "Text", "Instruction", "PromptText", "ActionText" }) do
					local value = argument[key]
					if type(value) == "string" then
						local lowered = value:lower()
						if lowered:find("head") or lowered:find("siphon") then
							return lowered
						end
					end
				end
			end
		end

		return nil
	end

	local function debugHeadSiphon(message)
		--	warn("[TVL Less HeadSiphon] " .. tostring(message))
	end

	local function getHeadSiphonPromptIdentifier(instance, ...)
		local promptIdentifier = getPromptIdentifierFromArgs(...)
		if promptIdentifier then
			return promptIdentifier
		end

		if type(instance) ~= "table" then
			return nil
		end

		promptIdentifier = getPromptIdentifierFromArgs(
			instance.text,
			instance.instructionText,
			instance.instruction,
			instance.title,
			instance.promptText,
			instance.actionText
		)
		if promptIdentifier then
			return promptIdentifier
		end

		if type(instance.instructionText) == "table" and type(instance.instructionText.get) == "function" then
			local ok, value = pcall(function()
				return instance.instructionText:get()
			end)
			if ok then
				return getPromptIdentifierFromArgs(value)
			end
		end

		return nil
	end

	local function isHeadSiphonPromptIdentifier(promptIdentifier)
		-- if type(promptIdentifier) ~= "string" then
		-- 	return false
		-- end

		-- local lowered = promptIdentifier:lower()
		-- if lowered:find("soul") and lowered:find("clash") then
		-- 	return false
		-- end

		-- return lowered:find("siphon") ~= nil
		return true
	end

	local function shouldAutoCompleteHeadSiphon(instance, ...)
		if env.promptAutomationFlags.headSiphonMode == "off" then
			debugHeadSiphon("skip hold prompt: mode is off")
			return false
		end

		local promptIdentifier = getHeadSiphonPromptIdentifier(instance, ...)
		local shouldHandle = isHeadSiphonPromptIdentifier(promptIdentifier)
		debugHeadSiphon(
			string.format(
				"hold prompt check mode=%s id=%s handle=%s",
				tostring(env.promptAutomationFlags.headSiphonMode),
				tostring(promptIdentifier),
				tostring(shouldHandle)
			)
		)
		return shouldHandle
	end

	local function forceCompleteHoldPrompt(instance, completeAfter, useInputBegin)
		if not instance then
			debugHeadSiphon("instant hold skipped: no instance")
			return
		end

		local progressValue = instance.progressValue
		if not progressValue or type(progressValue.set) ~= "function" then
			debugHeadSiphon("instant hold skipped: no progressValue.set")
			return
		end

		debugHeadSiphon(
			string.format(
				"instant hold scheduled delay=%.2f goal=%s",
				math.max(completeAfter or 1, 0.05),
				tostring(instance.goal)
			)
		)
		instance.goal = 999

		if useInputBegin and instance.onInputBegan then
			pcall(function()
				instance:onInputBegan()
			end)
		end

		task.delay(math.max(completeAfter or 1, 0.05), function()
			if not instance then
				debugHeadSiphon("instant hold aborted: instance missing after delay")
				return
			end
			debugHeadSiphon("instant hold forcing completion")
			instance.goal = 1
			pcall(function()
				progressValue:set(999)
			end)
			if instance.buttonDown and instance.onInputEnded then
				pcall(function()
					instance:onInputEnded()
				end)
			end
		end)
	end

	local function forceCompleteEscapePrompt(instance, completeAfter)
		if not instance or type(instance.onInputBegan) ~= "function" then
			debugHeadSiphon("instant escape skipped: no instance/onInputBegan")
			return
		end

		debugHeadSiphon(string.format("instant escape scheduled delay=%.2f", math.max(completeAfter or 1, 0.05)))
		task.delay(math.max(completeAfter or 1, 0.05), function()
			if not instance then
				debugHeadSiphon("instant escape aborted: instance missing after delay")
				return
			end

			debugHeadSiphon("instant escape forcing completion")
			local startedAt = os.clock()
			while instance and not instance.hasEscaped and os.clock() - startedAt < 1.5 do
				pcall(function()
					instance:onInputBegan()
				end)
				task.wait(0.01)
			end
		end)
	end

	local function spamCompleteHoldPrompt(instance)
		if not instance then
			debugHeadSiphon("legit hold skipped: no instance")
			return
		end

		local progressValue = instance.progressValue
		local instruction = instance.instruction
		local goal = instance.goal
		if
			not progressValue
			or type(progressValue.get) ~= "function"
			or not instruction
			or type(instruction.get) ~= "function"
		then
			debugHeadSiphon("legit hold skipped: missing progress/instruction accessors")
			return
		end

		debugHeadSiphon("legit hold loop started")
		task.spawn(function()
			while env.promptAutomationFlags.headSiphonMode == "legit" and instance do
				local currentProgress = progressValue:get()
				if tonumber(currentProgress) and tonumber(goal) and currentProgress >= goal then
					debugHeadSiphon("legit hold loop reached goal")
					break
				end

				local currentInstruction = instruction:get()
				if currentInstruction == "HOLD" then
					if not instance.buttonDown and instance.onInputBegan then
						pcall(function()
							instance:onInputBegan()
						end)
					end
					task.wait(0.016)
				elseif currentInstruction == "PRESS" then
					if instance.onInputBegan then
						pcall(function()
							instance:onInputBegan()
						end)
					end
					task.wait(0.01)
					if instance.onInputEnded then
						pcall(function()
							instance:onInputEnded()
						end)
					end
					task.wait(0.05)
				else
					task.wait(0.016)
				end
			end

			if instance and instance.buttonDown and instance.onInputEnded then
				pcall(function()
					instance:onInputEnded()
				end)
			end
		end)
	end

	local function spamCompleteEscapePrompt(instance)
		if not instance or type(instance.onInputBegan) ~= "function" then
			debugHeadSiphon("legit escape skipped: no instance/onInputBegan")
			return
		end

		debugHeadSiphon("legit escape loop started")
		task.spawn(function()
			while env.promptAutomationFlags.headSiphonMode == "legit" and instance and not instance.hasEscaped do
				pcall(function()
					instance:onInputBegan()
				end)
				task.wait(0.016)
			end
		end)
	end

	local function autoCompleteHeadSiphonHoldPrompt(instance)
		if env.promptAutomationFlags.headSiphonMode == "legit" then
			debugHeadSiphon("routing hold prompt to legit mode")
			spamCompleteHoldPrompt(instance)
		elseif env.promptAutomationFlags.headSiphonMode == "instant" then
			debugHeadSiphon("routing hold prompt to instant mode")
			forceCompleteHoldPrompt(instance, env.promptAutomationFlags.headSiphonCompleteAfter, false)
		end
	end

	local function autoCompleteHeadSiphonEscapePrompt(instance)
		if env.promptAutomationFlags.headSiphonMode == "legit" then
			debugHeadSiphon("routing escape prompt to legit mode")
			spamCompleteEscapePrompt(instance)
		elseif env.promptAutomationFlags.headSiphonMode == "instant" then
			debugHeadSiphon("routing escape prompt to instant mode")
			forceCompleteEscapePrompt(instance, env.promptAutomationFlags.headSiphonCompleteAfter)
		end
	end

	local function autoCompleteCarryEscapePrompt(instance)
		if env.promptAutomationFlags.autoCompleteCarryEscape then
			forceCompleteEscapePrompt(instance, env.promptAutomationFlags.carryEscapeCompleteAfter)
		end
	end

	local function hookPromptModule(moduleTable, oldNewKey, shouldHandle, handler)
		moduleTable.new = function(...)
			local instance = env[oldNewKey](...)
			debugHeadSiphon("hooked prompt new for " .. tostring(oldNewKey))
			if shouldHandle(instance, ...) then
				debugHeadSiphon("handler accepted for " .. tostring(oldNewKey))
				handler(instance, ...)
			else
				debugHeadSiphon("handler skipped for " .. tostring(oldNewKey))
			end
			return instance
		end
	end

	local function autoCompleteSoulClashPrompt(instance)
		if not instance then
			return
		end

		task.spawn(function()
			local rng = Random.new(math.floor(os.clock() * 1000000) % 2147483647)

			while env.promptAutomationFlags.autoCompleteSoulClash and instance and not instance.hasEscaped do
				local clashActivated = instance.clashActivated
				if clashActivated and clashActivated.get and clashActivated:get() then
					if instance.onInputBegan then
						instance:onInputBegan()
					end
					task.wait(rng:NextNumber(0.025, 0.05))
				else
					task.wait(rng:NextNumber(0.01, 0.02))
				end
			end
		end)
	end

	hookPromptModule(
		HoldActionPrompt,
		"oldHoldActionPromptNew",
		shouldAutoCompleteHeadSiphon,
		autoCompleteHeadSiphonHoldPrompt
	)
	hookPromptModule(EscapeSiphonPrompt, "oldEscapeSiphonPromptNew", function()
		local enabled = env.promptAutomationFlags.headSiphonMode ~= "off"
		debugHeadSiphon(
			string.format(
				"escape siphon check mode=%s handle=%s",
				env.promptAutomationFlags.headSiphonMode,
				tostring(enabled)
			)
		)
		return enabled
	end, autoCompleteHeadSiphonEscapePrompt)
	hookPromptModule(EscapeCarryPrompt, "oldEscapeCarryPromptNew", function()
		return env.promptAutomationFlags.autoCompleteCarryEscape
	end, autoCompleteCarryEscapePrompt)
	hookPromptModule(EscapeCarryPromptNew, "oldEscapeCarryPromptNewer", function()
		return env.promptAutomationFlags.autoCompleteCarryEscape
	end, autoCompleteCarryEscapePrompt)

	SoulClashPrompt.new = function(...)
		local instance = env.oldSoulClashPromptNew(...)
		if env.promptAutomationFlags.autoCompleteSoulClash then
			autoCompleteSoulClashPrompt(instance)
		end
		return instance
	end
end

do
	local CompulsionModule = require(PlayerScripts.ModuleScripts.AbilityHandler.Compulsion)
	local CompulsionActionNames = require(ReplicatedStorage.ModuleScripts.Enums.CompulsionActionNames)
	local CompulsionList = require(ReplicatedStorage.ModuleScripts.FusionComponents.ScreenUtils.CompulsionList)

	env.oldCompulsionActivated = env.oldCompulsionActivated or CompulsionModule.activated_
	env.oldCompulsionListShow = env.oldCompulsionListShow or CompulsionList.show
	env.tvlCompulsionState = env.tvlCompulsionState or {
		enabled = false,
		selectedAction = "FollowMe",
	}

	local compulsionActionOptions = {
		"FollowMe",
		"WalkAway",
		"Sleep",
		"Faint",
		"Attack",
		"Suffer",
		"Follow",
		"Freeze",
		"StandStill",
		"TakeStake",
		"TakeCure",
		"AllowFeed",
		"DontFeed",
		"MakeInvisible",
		"StakeYourself",
		"RemoveRing",
		"RemoveHunterRing",
		"ForgetBreath",
		"LookBehind",
		"Nevermind",
	}
	local originalCompulsionActionOptions = {
		"FollowMe",
		"WalkAway",
		"Sleep",
		"StandStill",
		"TakeStake",
		"TakeCure",
		"AllowFeed",
		"DontFeed",
		"MakeInvisible",
		"StakeYourself",
		"ForgetBreath",
		"Nevermind",
	}
	local immortalCompulsionActionOptions = {
		"Faint",
		"Attack",
		"Freeze",
		"Suffer",
		"Nevermind",
	}

	env.tvlCompulsionGetAllowedActions = function()
		local character = localPlayer.Character
		local specieType = character and character:GetAttribute("SpecieType") or nil
		if specieType == SpeciesType.Original or tostring(specieType) == "Original" then
			return originalCompulsionActionOptions
		end
		if specieType == SpeciesType.Immortal or tostring(specieType) == "Immortal" then
			return immortalCompulsionActionOptions
		end
		return compulsionActionOptions
	end

	env.tvlCompulsionIsActionAllowed = function(actionName)
		return table.find(env.tvlCompulsionGetAllowedActions(), actionName) ~= nil
	end

	env.tvlCompulsionNormalizeSelectedAction = function()
		if not env.tvlCompulsionIsActionAllowed(env.tvlCompulsionState.selectedAction) then
			env.tvlCompulsionState.selectedAction = env.tvlCompulsionGetAllowedActions()[1] or "FollowMe"
		end
		return env.tvlCompulsionState.selectedAction
	end

	CompulsionModule.activated_ = function(self)
		CompulsionList.show = function(screen, janitor, action, callback)
			CompulsionList.show = env.oldCompulsionListShow
			if env.tvlCompulsionState.enabled and type(callback) == "function" then
				callback(
					CompulsionActionNames[env.tvlCompulsionNormalizeSelectedAction()] or CompulsionActionNames.FollowMe
				)
				return
			end
			return env.oldCompulsionListShow(screen, janitor, action, callback)
		end

		return env.oldCompulsionActivated(self)
	end
end

-- gui
local Rayfield = loadstring(
	game:HttpGet(
		"https://raw.githubusercontent.com/aliezuw/supremasdocoven/main/rayfieldpassavel?t=" .. tostring(os.time())
	)
)()
local Window = Rayfield:CreateWindow({
	Name = "TVL2 by @ali_inchains",
	Icon = 11028823406,
	LoadingTitle = "Loading TVL2 by @ali_inchains",
	LoadingSubtitle = "The Vampire Legends 2 Script",
	ShowText = "Rayfield",
	Theme = "Amethyst",
	ScriptID = "maddieixbrian_tvl",

	ToggleUIKeybind = "K",

	DisableRayfieldPrompts = true,
	DisableBuildWarnings = false,

	ConfigurationSaving = {
		Enabled = true,
		FolderName = "briansTvlGui",
		FileName = "config",
	},

	Discord = {
		Enabled = true,
		Invite = "https://discord.gg/HpRPyuyN",
		RememberJoins = true,
	},

	KeySystem = false,
})

-- ui functions
local notificationsEnabled = true
local announcementsEnabled = true
local function notify(title, content, duration)
	if not notificationsEnabled and title ~= "Moderator joined" then
		return
	end
	return Rayfield:Notify({
		Title = title,
		Content = content,
		Duration = duration or 5,
		Image = 11028823406,
	})
end
local function announce(title, content, duration)
	if not announcementsEnabled then
		return
	end
	local payload = {
		Title = title,
		Content = content,
		Duration = duration or 5,
		Image = 11028823406,
	}
	if Rayfield.Announce then
		return Rayfield:Announce(payload)
	end
	return Rayfield:Notify(payload)
end

local function getRayfieldGui()
	local root = gethui and gethui() or CoreGui
	if not root then
		return nil
	end
	local gui = root:FindFirstChild("Rayfield")
	if gui then
		return gui
	end
	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("ScreenGui") and child:FindFirstChild("Main") and child.Name:find("Rayfield") then
			return child
		end
	end
	return nil
end

-- config
local sessionGuid = HttpService:GenerateGUID(false)
env.tvlGui = {
	allUiElements = {
		toggles = {},
		sliders = {},
		buttons = {},
		dropdowns = {},
	},
	newGUID = sessionGuid,
	Rayfield = Rayfield,
	connections = {},
}
local tvlGui = env.tvlGui
local tvlGuiConnections = tvlGui.connections
local tvlGuiElements = tvlGui.allUiElements
env.tvlViewState = env.tvlViewState or {
	target = nil,
	targetName = "",
	connection = nil,
}
local viewState = env.tvlViewState

local function addGuiConnection(connection)
	table.insert(tvlGuiConnections, connection)
	return connection
end

do
	local characterStreamingState = {
		enabled = true,
		trackedCharacterConnections = {},
	}

	local function setCharacterStreamingMode(character, streamingDisabled)
		if not character or not character:IsA("Model") then
			return
		end

		pcall(function()
			character.ModelStreamingMode = streamingDisabled and Enum.ModelStreamingMode.Persistent
				or Enum.ModelStreamingMode.Default
		end)
	end

	local function disconnectTrackedCharacterConnection(player)
		local connection = characterStreamingState.trackedCharacterConnections[player]
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
		characterStreamingState.trackedCharacterConnections[player] = nil
	end

	local function trackPlayerCharacter(player)
		disconnectTrackedCharacterConnection(player)

		characterStreamingState.trackedCharacterConnections[player] = player.CharacterAdded:Connect(function(character)
			setCharacterStreamingMode(character, characterStreamingState.enabled)
		end)
		addGuiConnection(characterStreamingState.trackedCharacterConnections[player])

		if player.Character then
			setCharacterStreamingMode(player.Character, characterStreamingState.enabled)
		end
	end

	local function refreshAllPlayerCharacterStreaming()
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				setCharacterStreamingMode(player.Character, characterStreamingState.enabled)
			end
		end
	end

	env.setCharacterStreamingDisabled = function(enabled)
		characterStreamingState.enabled = enabled ~= false
		refreshAllPlayerCharacterStreaming()
	end

	addGuiConnection(Players.PlayerAdded:Connect(function(player)
		trackPlayerCharacter(player)
	end))

	addGuiConnection(Players.PlayerRemoving:Connect(function(player)
		disconnectTrackedCharacterConnection(player)
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		trackPlayerCharacter(player)
	end
end

local function addUiElement(bucket, element)
	table.insert(tvlGuiElements[bucket], element)
	return element
end

local function isCurrentSessionActive()
	local currentGui = env.tvlGui
	return currentGui ~= nil and sessionGuid == currentGui.newGUID
end

local function setViewCameraSubject(targetPlayer)
	if not targetPlayer then
		return false, "Target player not found."
	end

	local character = targetPlayer.Character
	if not character then
		return false, "Target character is not loaded."
	end

	if not character.PrimaryPart and not character:FindFirstChildWhichIsA("Humanoid") then
		return false, "Target character is not ready."
	end

	camera.CameraSubject = character
	return true
end

local function stopViewingPlayer(showNotification)
	if typeof(viewState.connection) == "RBXScriptConnection" then
		viewState.connection:Disconnect()
	end
	viewState.connection = nil
	viewState.target = nil
	viewState.targetName = ""

	camera.CameraSubject = localPlayer.Character or localPlayer.CharacterAdded:Wait()

	if showNotification then
		notify("View", "Stopped viewing player")
	end
end

local function findPlayerByViewText(text)
	local trimmed = trimText(text)
	if trimmed == "" then
		return nil
	end

	local lowered = trimmed:lower()
	local exactDisplayMatch
	local exactNameMatch
	local prefixMatch

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local playerName = player.Name:lower()
			local displayName = player.DisplayName:lower()
			if playerName == lowered then
				exactNameMatch = player
				break
			end
			if displayName == lowered then
				exactDisplayMatch = exactDisplayMatch or player
			end
			if
				not prefixMatch
				and (playerName:sub(1, #lowered) == lowered or displayName:sub(1, #lowered) == lowered)
			then
				prefixMatch = player
			end
		end
	end

	return exactNameMatch or exactDisplayMatch or prefixMatch
end

local function startViewingPlayer(text)
	local targetPlayer = findPlayerByViewText(text)
	if not targetPlayer then
		notify("View", "Could not find that player")
		return
	end

	stopViewingPlayer(false)
	viewState.target = targetPlayer
	viewState.targetName = targetPlayer.Name

	local success, failureReason = setViewCameraSubject(targetPlayer)
	if not success then
		stopViewingPlayer(false)
		notify("View", failureReason or "Could not start viewing player")
		return
	end

	viewState.connection = RunService.Heartbeat:Connect(function()
		local currentTarget = viewState.target
		if not currentTarget or currentTarget.Parent ~= Players then
			stopViewingPlayer(false)
			notify("View", "Target left the game")
			return
		end

		local ok, reason = setViewCameraSubject(currentTarget)
		if not ok then
			stopViewingPlayer(false)
			notify("View", reason or "Stopped viewing player")
		end
	end)

	notify("View", "Viewing " .. targetPlayer.Name)
end

-- script variables
local incendiaColorSaveFolder = "briansTvlGui"
local incendiaColorSaveFile = incendiaColorSaveFolder .. "/incendia_color.json"
local projectileMouseAimerEnabled = true
local incendiaCustomColorEnabled = false
local incendiaActivatedRemote = AbilityActivated____
local incendiaEventChangedPathNotified
local incendiaCustomAbilityIds = {}
local originalIncendiaCustomColorAttribute = localPlayer:GetAttribute("CustomColor")
local incendiaCustomFireColor = Color3.fromRGB(255, 132, 65)
env.tvlProjectileAimerState = env.tvlProjectileAimerState
	or {
		installed = false,
		trackedMice = {},
		refreshConnection = nil,
		oldIndex = nil,
		loadedModules = {},
		directMouse = nil,
	}
env.tvlCarryRangeState = env.tvlCarryRangeState
	or {
		enabled = false,
		installed = false,
		oldIndex = nil,
		modifiedPrompts = setmetatable({}, { __mode = "k" }),
		taggedConnection = nil,
		multiplier = 1.75,
	}
env.tvlFreeCustomSlotsState = env.tvlFreeCustomSlotsState
	or {
		enabled = false,
		installed = false,
		oldNamecall = nil,
		uiLoopToken = 0,
	}
env.characterNamesCached = env.characterNamesCached or {}
env.specieTypesCached = env.specieTypesCached or {}
env.friendsCache = env.friendsCache or {}
local characterNamesCache = env.characterNamesCached
local specieTypesCache = env.specieTypesCached
local friendsCache = env.friendsCache
local RequestTeleportToSpawn = ReplicatedStorage.Remotes.GameServices.ToServer:FindFirstChild("RequestTeleportToSpawn")
local helpRequestMessage = ""

local noHBEAbilities = {
	[AbilityName.DarkJosieTeleport] = true,
	[AbilityName.MuseTeleport] = true,
	[AbilityName.PsychicTeleport] = true,
	[AbilityName.VisSeraPortus] = true,
}


local function loadPersistedIncendiaColor()
	if not readfile then
		return nil
	end

	local okIsFile, exists = pcall(isfile, incendiaColorSaveFile)
	if not okIsFile or not exists then
		return nil
	end

	local okRead, raw = pcall(readfile, incendiaColorSaveFile)
	if not okRead or type(raw) ~= "string" or raw == "" then
		return nil
	end

	local okDecode, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not okDecode or type(decoded) ~= "table" then
		return nil
	end

	local r = tonumber(decoded.r)
	local g = tonumber(decoded.g)
	local b = tonumber(decoded.b)
	if not r or not g or not b then
		return nil
	end

	return Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255))
end

local function savePersistedIncendiaColor(color)
	if not writefile then
		return
	end

	local payload = {
		r = math.floor(color.R * 255 + 0.5),
		g = math.floor(color.G * 255 + 0.5),
		b = math.floor(color.B * 255 + 0.5),
	}

	local okEncode, encoded = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not okEncode then
		return
	end

	if makefolder then
		local okIsFolder, folderExists = pcall(isfolder, incendiaColorSaveFolder)
		if okIsFolder and not folderExists then
			pcall(makefolder, incendiaColorSaveFolder)
		end
	end

	pcall(writefile, incendiaColorSaveFile, encoded)
end

do
	local existingColor = colorValueToColor3(originalIncendiaCustomColorAttribute)
	if existingColor then
		incendiaCustomFireColor = existingColor
	end

	local persistedColor = loadPersistedIncendiaColor()
	if persistedColor then
		incendiaCustomFireColor = persistedColor
	end
end

local function getIncendiaCustomColorSequence()
	return ColorSequence.new(incendiaCustomFireColor)
end

local function areColorsEqual(colorA, colorB)
	if typeof(colorA) ~= "Color3" or typeof(colorB) ~= "Color3" then
		return false
	end

	return math.abs(colorA.R - colorB.R) < 0.001
		and math.abs(colorA.G - colorB.G) < 0.001
		and math.abs(colorA.B - colorB.B) < 0.001
end

local function recolorIncendiaTargets(hitPosition)
	if typeof(hitPosition) ~= "Vector3" then
		return
	end

	local entitiesFolder = workspace:FindFirstChild("Entities")
	if not entitiesFolder then
		return
	end

	local desiredColorSequence = getIncendiaCustomColorSequence()
	for _, entity in ipairs(entitiesFolder:GetChildren()) do
		local humanoidRootPart = entity:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart and (humanoidRootPart.Position - hitPosition).Magnitude < 7 then
			humanoidRootPart:SetAttribute("FireColor", desiredColorSequence)

			local attributeConnection
			attributeConnection = humanoidRootPart:GetAttributeChangedSignal("FireColor"):Connect(function()
				humanoidRootPart:SetAttribute("FireColor", desiredColorSequence)
			end)

			task.delay(1, function()
				if attributeConnection then
					attributeConnection:Disconnect()
					attributeConnection = nil

					local currentColor = colorValueToColor3(humanoidRootPart:GetAttribute("FireColor"))
					if currentColor and areColorsEqual(currentColor, incendiaCustomFireColor) then
						humanoidRootPart:SetAttribute("FireColor", nil)
					end
				end
			end)
		end
	end
end

local function applyIncendiaCustomColorAttribute()
	if incendiaCustomColorEnabled then
		localPlayer:SetAttribute("CustomColor", getIncendiaCustomColorSequence())
	else
		localPlayer:SetAttribute("CustomColor", originalIncendiaCustomColorAttribute)
	end
end

local function resolveIncendiaEventFromValue(value)
	if typeof(value) == "Instance" and value:IsA("RemoteEvent") then
		return value
	end

	if typeof(value) == "table" then
		local directRemote = value.AbilityActivated____
		if typeof(directRemote) == "Instance" and directRemote:IsA("RemoteEvent") then
			return directRemote
		end

		local toServer = value.ToServer
		if typeof(toServer) == "table" then
			local nestedRemote = toServer.AbilityActivated____
			if typeof(nestedRemote) == "Instance" and nestedRemote:IsA("RemoteEvent") then
				return nestedRemote
			elseif typeof(toServer) == "Instance" then
				local nestedRemote = toServer:FindFirstChild("AbilityActivated____")
				if nestedRemote and nestedRemote:IsA("RemoteEvent") then
					return nestedRemote
				end
			end
		end
	end

	return nil
end

local function detectIncendiaActivatedEvent()
	local sourceActivated = getenv().oldIncendiaActivated or (Incendia and Incendia.activated_)
	if typeof(sourceActivated) ~= "function" then
		return nil
	end

	if debug and debug.getupvalues then
		local ok, upvalues = pcall(debug.getupvalues, sourceActivated)
		if ok and typeof(upvalues) == "table" then
			for _, value in pairs(upvalues) do
				local remote = resolveIncendiaEventFromValue(value)
				if remote then
					return remote
				end
			end
		end
	end

	if debug and debug.getupvalue then
		for i = 1, 80 do
			local ok, _, value = pcall(debug.getupvalue, sourceActivated, i)
			if not ok or value == nil then
				break
			end

			local remote = resolveIncendiaEventFromValue(value)
			if remote then
				return remote
			end
		end
	end

	return nil
end

local function refreshIncendiaActivatedEvent(notifyIfChanged, notifyTitle)
	local detected = detectIncendiaActivatedEvent() or AbilityActivated____
	incendiaActivatedRemote = detected

	if
		notifyIfChanged
		and incendiaActivatedRemote
		and (not AbilityActivated____ or incendiaActivatedRemote ~= AbilityActivated____)
	then
		local changedPath = getInstancePath(incendiaActivatedRemote)
		if incendiaEventChangedPathNotified ~= changedPath then
			notify(notifyTitle or "Incendia Aimer", "event changed to " .. changedPath, 8)
			incendiaEventChangedPathNotified = changedPath
		end
	end

	return incendiaActivatedRemote
end

local function verifyIncendiaActivationEvent(featureName)
	local remote = refreshIncendiaActivatedEvent(true, featureName)
	if not remote then
		notify(featureName, "Missing Incendia activation event remote.")
		return nil
	end
	return remote
end

do
	local projectileAimerState = env.tvlProjectileAimerState
	local PROJECTILE_TARGET_DISTANCE = 400
	local projectileModuleNames = { "Incendia", "SiphonBlast", "SolarisImpulsus", "Sol", "HopeExplosion", "ChokeOut" }
	local projectileAbilityNames = {
		[AbilityName.Incendia] = true,
		[AbilityName.SiphonBlast] = true,
		[AbilityName.SolarisImpulsus] = true,
		[AbilityName.Sol] = true,
		[AbilityName.HopeExplosion] = true,
		[AbilityName.ChokeOut] = true,
	}

	projectileAimerState.trackedMice = projectileAimerState.trackedMice or {}
	projectileAimerState.loadedModules = projectileAimerState.loadedModules or {}
	projectileAimerState.directMouse = projectileAimerState.directMouse or localPlayer:GetMouse()

	local function clearTrackedProjectileMice()
		for trackedMouse in pairs(projectileAimerState.trackedMice) do
			projectileAimerState.trackedMice[trackedMouse] = nil
		end
	end

	local function resolveProjectileModule(moduleName)
		local cachedModule = projectileAimerState.loadedModules[moduleName]
		if type(cachedModule) == "table" then
			return cachedModule
		end

		local moduleScript = AbilityHandlerModule:FindFirstChild(moduleName)
		if not moduleScript then
			return nil
		end

		local ok, moduleTable = pcall(require, moduleScript)
		if ok and type(moduleTable) == "table" then
			projectileAimerState.loadedModules[moduleName] = moduleTable
			return moduleTable
		end

		return nil
	end

	local function resolveProjectileMouse(moduleTable)
		if type(moduleTable) ~= "table" or type(moduleTable.activated_) ~= "function" then
			return nil
		end

		if not debug or type(debug.getupvalues) ~= "function" then
			return nil
		end

		local ok, upvalues = pcall(debug.getupvalues, moduleTable.activated_)
		if not ok or typeof(upvalues) ~= "table" then
			return nil
		end

		for _, upvalue in pairs(upvalues) do
			if upvalue == mouse or upvalue == projectileAimerState.directMouse then
				return upvalue
			end
		end

		for _, upvalue in pairs(upvalues) do
			local okX = pcall(function()
				return upvalue.X
			end)
			local okY = pcall(function()
				return upvalue.Y
			end)
			local okHit = pcall(function()
				return upvalue.Hit
			end)
			if okX and okY and okHit then
				return upvalue
			end
		end

		return nil
	end

	local function isProjectileAbilityContext()
		local activeAbility = AbilityHandler.activeAbility
		if type(activeAbility) == "table" and projectileAbilityNames[activeAbility._name] then
			return true
		end

		local equippedAbility = AbilityClient.getEquippedAbility and AbilityClient.getEquippedAbility()
		return projectileAbilityNames[equippedAbility] == true
	end

	local function isChokeOutAbilityContext()
		local activeAbility = AbilityHandler.activeAbility
		if type(activeAbility) == "table" and activeAbility._name == AbilityName.ChokeOut then
			return true
		end

		local equippedAbility = AbilityClient.getEquippedAbility and AbilityClient.getEquippedAbility()
		return equippedAbility == AbilityName.ChokeOut
	end

	local function getProjectileAimPart(character)
		if not character or character == localPlayer.Character or character:GetAttribute("NoDamage") then
			return nil
		end

		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return nil
		end

		return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	end

	local function getProjectileMouseTargetPart()
		local currentCamera = workspace.CurrentCamera
		local entitiesFolder = workspace:FindFirstChild("Entities")
		local mouseLocation = UserInputService:GetMouseLocation()
		if not currentCamera or not entitiesFolder then
			return nil
		end

		local closestPart
		local closestDistance = math.huge
		for _, entity in ipairs(entitiesFolder:GetChildren()) do
			local aimPart = getProjectileAimPart(entity)
			if aimPart then
				local screenPosition, onScreen = currentCamera:WorldToViewportPoint(aimPart.Position)
				if onScreen and screenPosition.Z > 0 then
					local worldDistance = (aimPart.Position - currentCamera.CFrame.Position).Magnitude
					if worldDistance <= PROJECTILE_TARGET_DISTANCE then
						local screenDistance = (Vector2.new(screenPosition.X, screenPosition.Y) - mouseLocation).Magnitude
						if screenDistance < closestDistance then
							closestDistance = screenDistance
							closestPart = aimPart
						end
					end
				end
			end
		end

		return closestPart
	end

	local function refreshProjectileMice()
		clearTrackedProjectileMice()
		for _, moduleName in ipairs(projectileModuleNames) do
			local moduleTable = resolveProjectileModule(moduleName)
			local trackedMouse = resolveProjectileMouse(moduleTable)
			if trackedMouse then
				projectileAimerState.trackedMice[trackedMouse] = moduleName
			end
		end
	end

	local function setProjectileAimerRefreshEnabled(enabled)
		if typeof(projectileAimerState.refreshConnection) == "RBXScriptConnection" then
			projectileAimerState.refreshConnection:Disconnect()
			projectileAimerState.refreshConnection = nil
		end

		if not enabled then
			clearTrackedProjectileMice()
			return
		end

		refreshProjectileMice()
		projectileAimerState.refreshConnection = RunService.Heartbeat:Connect(function()
			pcall(refreshProjectileMice)
		end)
		addGuiConnection(projectileAimerState.refreshConnection)
	end

	if not projectileAimerState.installed and type(hookmetamethod) == "function" then
		projectileAimerState.installed = true
		local oldIndex
		oldIndex = hookmetamethod(
			game,
			"__index",
			newcclosure(function(self, key)
				local trackedMouse = self == projectileAimerState.directMouse or projectileAimerState.trackedMice[self]
				local enabled = projectileMouseAimerEnabled
					and (isProjectileAbilityContext() or isChokeOutAbilityContext())

				if enabled and trackedMouse then
					local getTargetPart = projectileAimerState.getProjectileMouseTargetPart
						or projectileAimerState.getChokeOutMouseTargetPart
						or getProjectileMouseTargetPart
					local targetPart = getTargetPart()
					local currentCamera = workspace.CurrentCamera

					if targetPart and targetPart.Parent and currentCamera then
						local aimPosition = targetPart.Position
						local screenPosition = currentCamera:WorldToViewportPoint(aimPosition)

						if key == "Hit" then
							return CFrame.new(aimPosition)
						elseif key == "Target" then
							return targetPart
						elseif key == "UnitRay" then
							local origin = currentCamera.CFrame.Position
							local direction = aimPosition - origin
							if direction.Magnitude > 0 then
								return Ray.new(origin, direction.Unit * 1000)
							end
						elseif key == "X" then
							return screenPosition.X
						elseif key == "Y" then
							return screenPosition.Y
						end
					end

					return oldIndex(self, key)
				end)
			end
		)
		projectileAimerState.oldIndex = oldIndex
	end

	setProjectileAimerRefreshEnabled(projectileMouseAimerEnabled)
end

local function buildProjectileAimerSection(tab)
	if not tab then
		return
	end

	local incendiaColorPicker

	tab:CreateSection("Projectile Aimer")

	local function setProjectileMouseAimerEnabled(enabled)
		projectileMouseAimerEnabled = enabled or false
		setProjectileAimerRefreshEnabled(projectileMouseAimerEnabled)

		if projectileMouseAimerEnabled then
			notify("Projectile Aimer", "Enabled mouse aimer for projectile abilities and ChokeOut targeting")
		else
			notify("Projectile Aimer", "Disabled projectile mouse aimer")
		end
	end

	local function setIncendiaCustomColorEnabled(enabled)
		incendiaCustomColorEnabled = enabled or false

		if incendiaColorPicker and typeof(incendiaColorPicker.Color) == "Color3" then
			incendiaCustomFireColor = incendiaColorPicker.Color
		end

		if incendiaCustomColorEnabled then
			local remote = verifyIncendiaActivationEvent("Incendia Fire Color")
			if remote then
				notify("Incendia Fire Color", "Enabled custom fire color")
			else
				notify("Incendia Fire Color", "Enabled, but could not verify Incendia event.")
			end
		else
			notify("Incendia Fire Color", "Disabled custom fire color")
		end

		applyIncendiaCustomColorAttribute()
	end

	local projectileAimerToggle = tab:CreateToggle({
		Name = "Mouse Projectile Aimer",
		CurrentValue = projectileMouseAimerEnabled,
		Flag = "projectileMouseAimerToggle",
		Callback = setProjectileMouseAimerEnabled,
	})
	addUiElement("toggles", projectileAimerToggle)

	local incendiaCustomColorToggle = tab:CreateToggle({
		Name = "Custom Incendia Fire Color",
		CurrentValue = incendiaCustomColorEnabled,
		Flag = "incendiaCustomColorToggle",
		Callback = setIncendiaCustomColorEnabled,
	})
	addUiElement("toggles", incendiaCustomColorToggle)

	incendiaColorPicker = tab:CreateColorPicker({
		Name = "Incendia Fire Color",
		Color = incendiaCustomFireColor,
		Flag = "incendiaCustomColorValue",
		Callback = function(newColor)
			if typeof(newColor) ~= "Color3" then
				return
			end

			incendiaCustomFireColor = newColor
			savePersistedIncendiaColor(newColor)
			if incendiaCustomColorEnabled then
				applyIncendiaCustomColorAttribute()
			end
		end,
	})

	task.delay(1, function()
		if incendiaCustomColorEnabled then
			applyIncendiaCustomColorAttribute()
		end
	end)
end

local function findDescendant(parent, predicate, timeout)
	local start = os.clock()
	while true do
		for _, v in ipairs(parent:GetDescendants()) do
			if predicate(v) then
				return v
			end
		end
		if timeout and os.clock() - start >= timeout then
			return nil
		end
		task.wait(0.1)
	end
end
local function reset()
	if TimeHandler.isLimb or PlayerState.canRespawn then
		ReplicatedStorage.Bindables.GameServices.Client.ToggleReset:Fire()

		local Default = PlayerGui:WaitForChild("DeathScreen"):WaitForChild("Default")
		local ContinueButton = findDescendant(Default, function(v)
			local label = v:FindFirstChildOfClass("TextLabel")
			return v:IsA("ImageButton") and label and label.Text == "Continue" and label.TextTransparency ~= 1
		end)
		task.wait(0.35)
		firesignal(ContinueButton.Activated)
		return true
	end
	return false
end

local function findSpecie(characterName: string)
	for foundSpecie, data in CharacterSpecies do
		for name in data do
			if name == characterName then
				return foundSpecie
			end
		end
	end

	return nil
end

if Incendia then
	getenv().oldIncendiaActivated = getenv().oldIncendiaActivated or Incendia.activated_
	getenv().oldIncendiaBegin = getenv().oldIncendiaBegin or Incendia.begin
	getenv().oldIncendiaFireballHit = getenv().oldIncendiaFireballHit or Incendia.fireballHit
	local randomised = HttpService:GenerateGUID(false)
	_G.randomString = randomised

	local incendiaColorConnection
	incendiaColorConnection = CollectionService:GetInstanceAddedSignal(AbilityName.PhantasmosIncendiamos)
		:Connect(function(instance)
			if _G.randomString ~= randomised then
				incendiaColorConnection:Disconnect()
				return
			end

			if not incendiaCustomColorEnabled then
				return
			end

			if tonumber(instance.Name) == localPlayer.UserId then
				instance:SetAttribute("CustomColor", getIncendiaCustomColorSequence())
			end
		end)
	addGuiConnection(incendiaColorConnection)

	Incendia.begin = function(player, abilityId, projectileCFrame, serverTime)
		if incendiaCustomColorEnabled and player == localPlayer and abilityId then
			incendiaCustomAbilityIds[abilityId] = true
			task.delay(5, function()
				incendiaCustomAbilityIds[abilityId] = nil
			end)
		end

		return getenv().oldIncendiaBegin(player, abilityId, projectileCFrame, serverTime)
	end

	Incendia.fireballHit = function(abilityId, hitPosition, customColor)
		if incendiaCustomAbilityIds[abilityId] then
			incendiaCustomAbilityIds[abilityId] = nil
			if incendiaCustomColorEnabled then
				customColor = getIncendiaCustomColorSequence()
				recolorIncendiaTargets(hitPosition)
			end
		end

		return getenv().oldIncendiaFireballHit(abilityId, hitPosition, customColor)
	end
end

-- bypass autoclicker
if getenv().alreadyBypassedAutoclicker then
	-- do nothing, already bypassed
else
	getenv().alreadyBypassedAutoclicker = true

	local interceptCallsFor = {
		AutoclickerDetected = true,
		AbilityActivated____ = true,
		RobloxMessageService = true,
		BuyItemFromShop = true,
	}

	local oldNamecall
	oldNamecall = hookmetamethod(
		game,
		"__namecall",
		newcclosure(function(self, ...)
			local method = getnamecallmethod()

			if method == "FireServer" then
				local ok, name = pcall(function()
					return self.Name
				end)
				if ok and interceptCallsFor[name] then
					--print("intercepted", name)
					return
				end
			end

			return oldNamecall(self, ...)
		end)
	)

	local originalGetFlag = Flags.GetFlag

	Flags.GetFlag = function(self, flagName, ...)
		if flagName == "MaxClicksPerSecond" or flagName == "MacroMaxClicks" then
			return true, 6767676767676767
		elseif flagName == "MacroKick" or flagName == "AutoclickerDetection" then
			return true, false
		end

		return originalGetFlag(self, flagName, ...)
	end

	task.wait(0.5)

	-- check
	local _, maxCPS = Flags:GetFlag("MaxClicksPerSecond")
	local _, macroKick = Flags:GetFlag("MacroKick")

	if maxCPS == 6767676767676767 and macroKick == false then
	else
		game:GetService("Players").LocalPlayer:Kick("auto bypasser failed")
	end
end

-- start of GUI elements

-- MAIN
do
	local combatTab = Window:CreateTab("Combat") -- Title, Image
	local automationTab = Window:CreateTab("Automation") -- Title, Image
	local spawningTab = Window:CreateTab("Spawning") -- Title, Image
	local supportTab = Window:CreateTab("Support") -- Title, Image
	local function buildCombatTab()
		local main = combatTab

		-- combat
		do
			local combat = main:CreateSection("Targeting") -- Title, Image

			-- variables
			local rangeExpanderMultiplier = 1.75
			local hitboxExpanderEnabled = false
			local closestToMouseEnabled = false
			local stakeHitDetectionEnabled = true
			local antiFlingConnection
			local antiFlingCharacterConnection
			local friendHitboxExclusionEnabled = false
			local rangeExpansionEnabled = false
			local toolRangeExpansionEnabled = false
			local carryRangeExpansionEnabled = false
			local rangeExpansionConnection
			local toolRangeExpansionConnection
			local TARGETING_MAX_DISTANCE = 250
			local REAL_WORLD_TARGET_DISTANCE = 300
			local originalAbilityRanges = setmetatable({}, { __mode = "k" })
			local originalToolRanges = setmetatable({}, { __mode = "k" })

			local function shouldSkipFriendTarget(player)
				return friendHitboxExclusionEnabled and checkIsFriend(player)
			end

			local function getCharacterAimPart(character)
				if not character then
					return nil
				end

				return character:FindFirstChild("HumanoidRootPart")
					or character.PrimaryPart
					or character:FindFirstChild("Head")
			end

			local function getLocalTargetingOrigin()
				local character = localPlayer.Character
				local primary = character and character.PrimaryPart
				return primary and primary.Position or nil
			end

			local function buildCharacterRaycastResult(origin, character)
				local targetPart = getCharacterAimPart(character)
				if not targetPart then
					return nil
				end

				local targetPosition = targetPart.Position
				local normal = Vector3.new()
				local delta = origin - targetPosition
				if delta.Magnitude > 0 then
					normal = delta.Unit
				end

				return {
					Instance = targetPart,
					Position = targetPosition,
					Normal = normal,
					Material = targetPart.Material,
					Distance = (targetPosition - origin).Magnitude,
				}
			end

			local function applyExpandedRange(targetObject, originalRangeMap, enabled)
				if type(targetObject) ~= "table" or type(targetObject._range) ~= "number" then
					return
				end

				local originalRange = originalRangeMap[targetObject]
				if type(originalRange) ~= "number" then
					originalRange = targetObject._range
					originalRangeMap[targetObject] = originalRange
				end

				targetObject._range = enabled and (originalRange * rangeExpanderMultiplier) or originalRange
			end

			local function refreshCarryRangeExpansion()
				if env.refreshCarryPromptExpansion then
					env.refreshCarryPromptExpansion()
				end
			end

			local function getProjectedBoxMouseDistance(camera, partCFrame, partSize, mousePosition)
				local halfSize = partSize * 0.5
				local minX, minY = math.huge, math.huge
				local maxX, maxY = -math.huge, -math.huge
				local visibleCornerFound = false

				for x = -1, 1, 2 do
					for y = -1, 1, 2 do
						for z = -1, 1, 2 do
							local worldPoint = partCFrame:PointToWorldSpace(
								Vector3.new(halfSize.X * x, halfSize.Y * y, halfSize.Z * z)
							)
							local screenPoint, onScreen = camera:WorldToViewportPoint(worldPoint)
							if onScreen then
								visibleCornerFound = true
								minX = math.min(minX, screenPoint.X)
								minY = math.min(minY, screenPoint.Y)
								maxX = math.max(maxX, screenPoint.X)
								maxY = math.max(maxY, screenPoint.Y)
							end
						end
					end
				end

				if not visibleCornerFound then
					return nil
				end

				local clampedX = math.clamp(mousePosition.X, minX, maxX)
				local clampedY = math.clamp(mousePosition.Y, minY, maxY)
				local mouseDelta = mousePosition - Vector2.new(clampedX, clampedY)
				return mouseDelta.Magnitude
			end

			local function filterFriendlyRaycastResult(result)
				if not result or not friendHitboxExclusionEnabled then
					return result
				end

				local instance = result.Instance
				local model = instance and instance:FindFirstAncestorOfClass("Model")
				local player = model and Players:GetPlayerFromCharacter(model)
				if player and shouldSkipFriendTarget(player) then
					return nil
				end

				return result
			end

			local function getClosestPlayerToMouseFromOrigin(origin, maxTargetDistance)
				local closestPlayer = nil
				local closestDistance = math.huge
				local mousePosition = UserInputService:GetMouseLocation()
				local currentCamera = workspace.CurrentCamera
				local localOrigin = getLocalTargetingOrigin()

				if not currentCamera then
					return nil
				end

				for _, player in ipairs(Players:GetPlayers()) do
					if player == localPlayer then
						continue
					end

					if shouldSkipFriendTarget(player) then
						continue
					end

					local character = player.Character
					local aimPart = getCharacterAimPart(character)
					if not character or not aimPart then
						continue
					end

					local worldDist = (origin - aimPart.Position).Magnitude
					if worldDist >= maxTargetDistance then
						continue
					end

					if localOrigin and (localOrigin - aimPart.Position).Magnitude > REAL_WORLD_TARGET_DISTANCE then
						continue
					end

					local screenPoint, onScreen = currentCamera:WorldToViewportPoint(aimPart.Position)
					if not onScreen then
						continue
					end

					local distance = (mousePosition - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
					if distance < closestDistance then
						closestDistance = distance
						closestPlayer = player
					end
				end

				return closestPlayer
			end

			local function getClosestExpandedHitboxCharacter(origin, maxTargetDistance, expandedSize)
				local closestCharacter = nil
				local closestScreenDistance = math.huge
				local mousePosition = UserInputService:GetMouseLocation()
				local currentCamera = workspace.CurrentCamera
				local localOrigin = getLocalTargetingOrigin()

				if not currentCamera then
					return nil
				end

				for _, player in ipairs(Players:GetPlayers()) do
					if player == localPlayer then
						continue
					end

					if shouldSkipFriendTarget(player) then
						continue
					end

					local character = player.Character
					local primary = getCharacterAimPart(character)
					local humanoid = character and character:FindFirstChild("Humanoid")
					if not primary or not humanoid then
						continue
					end

					local worldDist = (primary.Position - origin).Magnitude
					if worldDist >= maxTargetDistance then
						continue
					end

					if localOrigin and (localOrigin - primary.Position).Magnitude > REAL_WORLD_TARGET_DISTANCE then
						continue
					end

					local screenDistance =
						getProjectedBoxMouseDistance(currentCamera, primary.CFrame, expandedSize, mousePosition)
					if screenDistance and screenDistance < closestScreenDistance then
						closestScreenDistance = screenDistance
						closestCharacter = character
					end
				end

				return closestCharacter
			end

			local projectileAimerState = env.tvlProjectileAimerState
			local currentHitboxExpanderSize = 9

			local function getFallbackProjectileAimerTargetPart()
				local currentCamera = workspace.CurrentCamera
				local mousePosition = UserInputService:GetMouseLocation()
				local origin = getLocalTargetingOrigin()
				local closestAimPart = nil
				local closestScreenDistance = math.huge

				if not currentCamera or not origin then
					return nil
				end

				for _, player in ipairs(Players:GetPlayers()) do
					if player == localPlayer or shouldSkipFriendTarget(player) then
						continue
					end

					local character = player.Character
					local aimPart = getCharacterAimPart(character)
					if not aimPart then
						continue
					end

					if (origin - aimPart.Position).Magnitude >= TARGETING_MAX_DISTANCE then
						continue
					end

					local screenPoint, onScreen = currentCamera:WorldToViewportPoint(aimPart.Position)
					if not onScreen or screenPoint.Z <= 0 then
						continue
					end

					local screenDistance = (mousePosition - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
					if screenDistance < closestScreenDistance then
						closestScreenDistance = screenDistance
						closestAimPart = aimPart
					end
				end

				return closestAimPart
			end

			local function getPreferredProjectileAimerTargetPart()
				local origin = getLocalTargetingOrigin()
				if origin then
					if closestToMouseEnabled then
						local closestPlayer = getClosestPlayerToMouseFromOrigin(origin, TARGETING_MAX_DISTANCE)
						local closestCharacter = closestPlayer and closestPlayer.Character
						local closestAimPart = getCharacterAimPart(closestCharacter)
						if closestAimPart then
							return closestAimPart
						end
					end

					if hitboxExpanderEnabled then
						local expandedSize =
							Vector3.new(currentHitboxExpanderSize, currentHitboxExpanderSize, currentHitboxExpanderSize)
						local closestCharacter =
							getClosestExpandedHitboxCharacter(origin, TARGETING_MAX_DISTANCE, expandedSize)
						local closestAimPart = closestCharacter and getCharacterAimPart(closestCharacter)
						if closestAimPart then
							return closestAimPart
						end
					end
				end

				return getFallbackProjectileAimerTargetPart()
			end

			if projectileAimerState then
				projectileAimerState.getProjectileMouseTargetPart = getPreferredProjectileAimerTargetPart
				projectileAimerState.getChokeOutMouseTargetPart = getPreferredProjectileAimerTargetPart
			end

			-- ui variables
			local expanderToggle
			local closestToMouseToggle
			local stakeHitDetectionToggle

			-- HITBOX EXPANDER
			do
				-- main functionality
				local updateToken = 0
				local function setHitboxExpanderSize(newSize)
					currentHitboxExpanderSize = tonumber(newSize) or currentHitboxExpanderSize
					local expandedSize =
						Vector3.new(currentHitboxExpanderSize, currentHitboxExpanderSize, currentHitboxExpanderSize)

					function HitDetection.Hitscan(self)
						if not hitboxExpanderEnabled then
							return getenv().oldHitscan(self)
						end
						local activeAbility = AbilityHandler.activeAbility
						if noHBEAbilities[self._name] or (activeAbility and noHBEAbilities[activeAbility._name]) then
							return getenv().oldHitscan(self)
						end
						if not self._character or not self._character.PrimaryPart then
							return nil
						end
						local character = getClosestExpandedHitboxCharacter(
							self._character.PrimaryPart.Position,
							TARGETING_MAX_DISTANCE,
							expandedSize
						)
						local targetPlayer = character and Players:GetPlayerFromCharacter(character)
						if not character or not targetPlayer then
							return nil
						end

						if
							(self._character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
							> self._range
						then
							return nil
						end

						if not AbilityHandler.canBeAffected(targetPlayer, self._name) then
							return nil
						end

						return character
					end

					function GameCollision.Hitscan(origin, direction, length, raycastParams)
						if not hitboxExpanderEnabled then
							return getenv().oldGameCollisionHitscan(origin, direction, length, raycastParams)
						end
						local maxLength = math.clamp(length, 0, 512)
						if maxLength <= 0 then
							return nil
						end

						local dirMag = direction.Magnitude
						if dirMag <= 0 then
							return nil
						end

						local rayDirection = direction.Unit * maxLength
						local result =
							filterFriendlyRaycastResult(workspace:Raycast(origin, rayDirection, raycastParams))

						if direction ~= -Vector3.yAxis then
							local ability = AbilityHandler.activeAbility
							if ability and noHBEAbilities[ability._name] then
								return result
							end

							local closestCharacter =
								getClosestExpandedHitboxCharacter(origin, TARGETING_MAX_DISTANCE, expandedSize)
							if closestCharacter and closestCharacter.PrimaryPart then
								local toTarget = closestCharacter.PrimaryPart.Position - origin
								local targetDistance = toTarget.Magnitude

								if targetDistance > 0 then
									local clampedDistance = math.min(targetDistance, maxLength)
									if clampedDistance > 0 then
										return buildCharacterRaycastResult(origin, closestCharacter) or result
									end
								end
							end
						end

						return result
					end

					updateToken += 1
					local token = updateToken
					task.delay(1, function()
						if token ~= updateToken then
							return
						end
						notify(
							"Hitbox Expansion",
							"Hitbox size set to " .. tostring(currentHitboxExpanderSize) .. " studs"
						)
					end)
				end

				-- ui toggle
				expanderToggle = main:CreateToggle({
					Name = "Hitbox Expansion",
					CurrentValue = false,
					Flag = "hitboxExpanderToggle", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
					Callback = function(value)
						hitboxExpanderEnabled = value or false
						if hitboxExpanderEnabled then
							setHitboxExpanderSize(currentHitboxExpanderSize)
							notify("Hitbox Expansion", "Enabled hitbox expansion")
							-- disable closest
							if closestToMouseEnabled then
								if not closestToMouseToggle then
									repeat
										task.wait(0.1)
									until closestToMouseToggle
								end
								closestToMouseToggle:Set(false)
							end
						else
							notify("Hitbox Expansion", "Disabled hitbox expansion")
						end
					end,
				})

				addUiElement("toggles", expanderToggle)

				-- ui element
				local hitboxExpander = main:CreateSlider({
					Name = "Hitbox Size",
					Range = { 0, 30 },
					Increment = 0.5,
					Suffix = "studs",
					CurrentValue = 9,
					Flag = "hitboxExpanderSize", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
					Callback = setHitboxExpanderSize,
				})
				addUiElement("sliders", hitboxExpander)

				-- protect friends
				local friendExclusionToggle = main:CreateToggle({
					Name = "Exclude Friends from Hitbox Expansion",
					CurrentValue = false,
					Flag = "friendHitboxExclusionToggle",
					Callback = function(value)
						friendHitboxExclusionEnabled = value or false

						if friendHitboxExclusionEnabled then
							notify("Hitbox Expansion", "Friends will be excluded from targeting")
						else
							notify("Hitbox Expansion", "Friends can be targeted")
						end
					end,
				})
				addUiElement("toggles", friendExclusionToggle)
			end

			-- SILENT AIM
			do
				-- main functionality
				local function setClosestToMouseEnabled(value)
					closestToMouseEnabled = value or false
					notify("Silent Aim", closestToMouseEnabled and "Enabled silent aim" or "Disabled silent aim")

					if closestToMouseEnabled then
						HitDetection.Hitscan = function(self)
							if not closestToMouseEnabled then
								return getenv().oldHitscan(self)
							end
							if not self._character or not self._character.PrimaryPart then
								return nil
							end

							local closestPlayer = getClosestPlayerToMouseFromOrigin(
								self._character.PrimaryPart.Position,
								TARGETING_MAX_DISTANCE
							)

							if not closestPlayer then
								return nil
							end

							local character = closestPlayer.Character
							if not character or not character.PrimaryPart then
								return nil
							end

							if
								(self._character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
								> self._range
							then
								return nil
							end

							if not AbilityHandler.canBeAffected(closestPlayer, self._name) then
								return nil
							end

							return character
						end

						GameCollision.Hitscan = function(origin, direction, length, raycastParams)
							if not closestToMouseEnabled then
								return getenv().oldGameCollisionHitscan(origin, direction, length, raycastParams)
							end

							local maxLength = math.clamp(length, 0, 512)
							if maxLength <= 0 then
								return nil
							end

							local dirMag = direction.Magnitude
							if dirMag <= 0 then
								return nil
							end

							local rayDirection = direction.Unit * maxLength
							local result =
								filterFriendlyRaycastResult(workspace:Raycast(origin, rayDirection, raycastParams))

							if direction ~= -Vector3.yAxis then
								local mousePos = Vector2.new(mouse.X, mouse.Y)
								local cam = workspace.CurrentCamera
								if not cam then
									return result
								end

								local closestCharacter = nil
								local closestScreenDistance = math.huge

								for _, player in ipairs(Players:GetPlayers()) do
									if player == localPlayer or shouldSkipFriendTarget(player) then
										continue
									end

									local character = player.Character
									local primary = getCharacterAimPart(character)
									if primary then
										local worldDist = (primary.Position - origin).Magnitude
										if worldDist >= TARGETING_MAX_DISTANCE then
											continue
										end
										local localOrigin = getLocalTargetingOrigin()
										if
											localOrigin
											and (localOrigin - primary.Position).Magnitude > REAL_WORLD_TARGET_DISTANCE
										then
											continue
										end
										local screenPoint, onScreen = cam:WorldToViewportPoint(primary.Position)
										if onScreen then
											local screenDist = (mousePos - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
											if screenDist < closestScreenDistance then
												closestScreenDistance = screenDist
												closestCharacter = character
											end
										end
									end
								end

								if closestCharacter and closestCharacter.PrimaryPart then
									local toTarget = closestCharacter.PrimaryPart.Position - origin
									local targetDistance = toTarget.Magnitude

									if targetDistance > 0 then
										local clampedDistance = math.min(targetDistance, maxLength)
										if clampedDistance > 0 then
											return buildCharacterRaycastResult(origin, closestCharacter) or result
										end
									end
								end
							end

							return result
						end

						function StakeModule.hitDetection(self)
							if not stakeHitDetectionEnabled then
								return getenv().oldStakeHitDetection(self)
							end

							local closestPlayer = getClosestPlayerToMouseFromOrigin(
								self._character.PrimaryPart.Position,
								TARGETING_MAX_DISTANCE
							)
							if not closestPlayer then
								return nil
							end

							local character = closestPlayer.Character
							if not character or not character.PrimaryPart then
								return nil
							end

							if
								(self._character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
								> self._range
							then
								return nil
							end

							if not ToolHandler.canBeAffected(closestPlayer, self._name) then
								return nil
							end

							return character
						end

						if hitboxExpanderEnabled and expanderToggle then
							expanderToggle:Set(false)
						end
					else
						GameCollision.Hitscan = getenv().oldGameCollisionHitscan
					end
				end

				-- ui toggle
				closestToMouseToggle = main:CreateToggle({
					Name = "Silent Aim",
					CurrentValue = false,
					Flag = "closestToMouseHitdetectionToggle", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
					Callback = setClosestToMouseEnabled,
				})
			end

			-- RANGE EXPANSION
			do
				local function setRangeExpanderMultiplier(value)
					rangeExpanderMultiplier = value or 1.75
					env.tvlCarryRangeState.multiplier = rangeExpanderMultiplier
					applyExpandedRange(AbilityHandler.activeAbility, originalAbilityRanges, rangeExpansionEnabled)
					applyExpandedRange(ToolHandler.activeTool, originalToolRanges, toolRangeExpansionEnabled)
					refreshCarryRangeExpansion()
					notify("Range Expansion", "Multiplier set to " .. tostring(rangeExpanderMultiplier) .. "x")
				end

				local function setRangeExpanderEnabled(enabled)
					rangeExpansionEnabled = enabled == true
					if rangeExpansionConnection then
						rangeExpansionConnection:Disconnect()
						rangeExpansionConnection = nil
					end

					if not rangeExpansionEnabled then
						applyExpandedRange(AbilityHandler.activeAbility, originalAbilityRanges, false)
						notify("Range Expansion", "Disabled range expansion")
						return
					end

					applyExpandedRange(AbilityHandler.activeAbility, originalAbilityRanges, true)
					rangeExpansionConnection = RunService.Heartbeat:Connect(function()
						applyExpandedRange(AbilityHandler.activeAbility, originalAbilityRanges, rangeExpansionEnabled)
					end)

					addGuiConnection(rangeExpansionConnection)
					notify("Range Expansion", "Enabled range expansion")
				end

				local rangeExpanderToggle = main:CreateToggle({
					Name = "Range Expansion",
					CurrentValue = false,
					Flag = "rangeExpanderToggle",
					Callback = setRangeExpanderEnabled,
				})
				addUiElement("toggles", rangeExpanderToggle)

				local rangeExpanderSlider = main:CreateSlider({
					Name = "Range Expansion Multiplier",
					Range = { 1, 3 },
					Increment = 0.05,
					Suffix = "x",
					CurrentValue = 1.75,
					Flag = "rangeExpanderMultiplierValue", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
					Callback = setRangeExpanderMultiplier,
				})
				addUiElement("sliders", rangeExpanderSlider)
			end

			-- STAKE MODIFICATION
			do
				-- ui toggle
				main:CreateToggle({
					Name = "Stake Hitbox Modification",
					CurrentValue = true,
					Flag = "stakeHitboxModificationToggle", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
					Callback = function(value)
						stakeHitDetectionEnabled = value or false
						if stakeHitDetectionEnabled then
							notify("Stake Hitbox Modification", "Enabled stake hitbox modification")
						else
							notify("Stake Hitbox Modification", "Disabled stake hitbox modification")
						end
					end,
				})
			end

			-- Tool RANGE EXPANSION
			do
				local function setRangeExpanderEnabled(enabled)
					toolRangeExpansionEnabled = enabled == true
					if toolRangeExpansionConnection then
						toolRangeExpansionConnection:Disconnect()
						toolRangeExpansionConnection = nil
					end

					if not toolRangeExpansionEnabled then
						applyExpandedRange(ToolHandler.activeTool, originalToolRanges, false)
						notify("Tool Range Expansion", "Disabled tool range expansion")
						return
					end

					applyExpandedRange(ToolHandler.activeTool, originalToolRanges, true)
					toolRangeExpansionConnection = RunService.Heartbeat:Connect(function()
						applyExpandedRange(ToolHandler.activeTool, originalToolRanges, toolRangeExpansionEnabled)
					end)

					addGuiConnection(toolRangeExpansionConnection)
					notify("Tool Range Expansion", "Enabled tool range expansion")
				end

				local rangeExpanderToggle = main:CreateToggle({
					Name = "Tool Range Expansion",
					CurrentValue = false,
					Flag = "toolRangeExpanderToggle",
					Callback = setRangeExpanderEnabled,
				})
				addUiElement("toggles", rangeExpanderToggle)

				local carryRangeExpanderToggle = main:CreateToggle({
					Name = "Carry Range Expansion",
					CurrentValue = false,
					Flag = "carryRangeExpanderToggle",
					Callback = function(enabled)
						carryRangeExpansionEnabled = enabled == true
						if env.setCarryRangeExpansionEnabled then
							env.setCarryRangeExpansionEnabled(carryRangeExpansionEnabled)
						end
						notify(
							"Carry Range Expansion",
							carryRangeExpansionEnabled and "Enabled carry range expansion"
								or "Disabled carry range expansion"
						)
					end,
				})
				addUiElement("toggles", carryRangeExpanderToggle)
			end

			main:CreateSection("Defense")

			-- ANTI FLING
			do
				-- main functionality
				local VELOCITY_THRESHOLD = 500
				local originalCollisionStates = {}

				local function setEntityCollisions(entity, disableCollisions)
					if not entity then
						return
					end

					for _, descendant in ipairs(entity:GetDescendants()) do
						if descendant:IsA("BasePart") then
							if disableCollisions then
								if originalCollisionStates[descendant] == nil then
									originalCollisionStates[descendant] = {
										canCollide = descendant.CanCollide,
									}
								end
								descendant.CanCollide = false
							else
								local originalValue = originalCollisionStates[descendant]
								if originalValue ~= nil and descendant.Parent then
									descendant.CanCollide = originalValue.canCollide
								end
								originalCollisionStates[descendant] = nil
							end
						end
					end
				end

				local function updateOtherEntityCollisions(disableCollisions)
					local entitiesFolder = workspace:FindFirstChild("Entities")
					if not entitiesFolder then
						return
					end

					for _, entity in ipairs(entitiesFolder:GetChildren()) do
						if entity ~= localPlayer.Character then
							setEntityCollisions(entity, disableCollisions)
						end
					end
				end

				local function setupCharacter(character)
					local rootPart = character:WaitForChild("HumanoidRootPart")

					antiFlingConnection = RunService.Heartbeat:Connect(function()
						if not rootPart or not rootPart.Parent then
							return
						end

						updateOtherEntityCollisions(true)

						local linearVelocity = rootPart.AssemblyLinearVelocity.Magnitude
						local angularVelocity = rootPart.AssemblyAngularVelocity.Magnitude

						if linearVelocity > VELOCITY_THRESHOLD or angularVelocity > VELOCITY_THRESHOLD then
							rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
							rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
						end
					end)

					addGuiConnection(antiFlingConnection)
				end

				local function setAntiFlingEnabled(enabled)
					if antiFlingConnection then
						antiFlingConnection:Disconnect()
						antiFlingConnection = nil
					end
					if antiFlingCharacterConnection then
						antiFlingCharacterConnection:Disconnect()
						antiFlingCharacterConnection = nil
					end

					if enabled then
						updateOtherEntityCollisions(true)

						if localPlayer.Character then
							setupCharacter(localPlayer.Character)
						end

						antiFlingCharacterConnection = localPlayer.CharacterAdded:Connect(setupCharacter)

						addGuiConnection(antiFlingCharacterConnection)
						notify("Anti Fling", "Enabled anti fling")
					else
						updateOtherEntityCollisions(false)
						notify("Anti Fling", "Disabled anti fling")
					end
				end

				local antiFlingToggle = main:CreateToggle({
					Name = "Anti Fling",
					CurrentValue = false,
					Flag = "antiFlingToggle",
					Callback = setAntiFlingEnabled,
				})
				addUiElement("toggles", antiFlingToggle)
			end
		end
	end

	buildCombatTab()
	buildProjectileAimerSection(combatTab)

	-- OUTSPAMMER
	do
		local main = automationTab
		main:CreateSection("Outspammer")
		local outspammerFlags = {
			enabled = false,
			excludeInvisibleTargetsEnabled = false,
			protectFriendsEnabled = false,
		}
		local outspammerCatalog = {
			allAbilityKeys = {},
			abilityDisplayByKey = {},
			abilityKeyByDisplay = {},
			allAbilityDisplayOptions = {},
		}
		local outspammerSelections = {
			selectedAbilityByKey = {},
			selectedOffenseByKey = {},
			selectedAbilities = {},
			offenseAbilities = {},
		}
		local outspammerUi = {
			offenseDropdown = nil,
		}
		local outspammerStorage = {
			saveFolder = "briansTvlGui",
			saveFile = "briansTvlGui/outspammer_abilities.json",
			validAbilityKeySet = {},
		}

		for key, _ in pairs(AbilityName) do
			if typeof(key) == "string" then
				local abilityEnum = AbilityName[key]
				local abilityData = abilityEnum and AbilityData[abilityEnum]
				local isHolding = abilityData and abilityData.holding == true
				local abilityGroup = abilityData and abilityData.abilityGroup
				local isCustomGroup = abilityGroup == "Custom" or tostring(abilityGroup) == "Custom"
				if not isHolding and not isCustomGroup then
					table.insert(outspammerCatalog.allAbilityKeys, key)
				end
			end
		end
		table.sort(outspammerCatalog.allAbilityKeys)

		for _, key in ipairs(outspammerCatalog.allAbilityKeys) do
			local display = AbilityName[key] or key
			if outspammerCatalog.abilityKeyByDisplay[display] then
				display = string.format("%s (%s)", display, key)
			end
			outspammerCatalog.abilityDisplayByKey[key] = display
			outspammerCatalog.abilityKeyByDisplay[display] = key
			table.insert(outspammerCatalog.allAbilityDisplayOptions, display)
		end

		for _, key in ipairs(outspammerCatalog.allAbilityKeys) do
			outspammerStorage.validAbilityKeySet[key] = true
		end

		local function readOutspammerSelections()
			if not (readfile and isfile) then
				return {}, {}
			end

			local okIsFile, isConfigFile = pcall(isfile, outspammerStorage.saveFile)
			if not okIsFile or not isConfigFile then
				return {}, {}
			end

			local okRead, raw = pcall(readfile, outspammerStorage.saveFile)
			if not okRead or typeof(raw) ~= "string" or #raw == 0 then
				return {}, {}
			end

			local okDecode, decoded = pcall(function()
				return HttpService:JSONDecode(raw)
			end)
			if not okDecode or typeof(decoded) ~= "table" then
				return {}, {}
			end

			local loadedAbilities = {}
			local loadedOffense = {}

			if typeof(decoded.abilities) == "table" then
				for _, key in ipairs(decoded.abilities) do
					if typeof(key) == "string" and outspammerStorage.validAbilityKeySet[key] then
						loadedAbilities[key] = true
					end
				end
			end

			if typeof(decoded.offense) == "table" then
				for _, key in ipairs(decoded.offense) do
					if typeof(key) == "string" and outspammerStorage.validAbilityKeySet[key] then
						loadedOffense[key] = true
					end
				end
			end

			return loadedAbilities, loadedOffense
		end

		local function saveOutspammerSelections()
			if not writefile then
				return
			end

			if makefolder then
				if isfolder then
					local okIsFolder, folderExists = pcall(isfolder, outspammerStorage.saveFolder)
					if okIsFolder and not folderExists then
						pcall(makefolder, outspammerStorage.saveFolder)
					end
				else
					pcall(makefolder, outspammerStorage.saveFolder)
				end
			end

			local abilityList = {}
			local offenseList = {}
			for _, key in ipairs(outspammerCatalog.allAbilityKeys) do
				if outspammerSelections.selectedAbilityByKey[key] then
					table.insert(abilityList, key)
				end
				if outspammerSelections.selectedOffenseByKey[key] then
					table.insert(offenseList, key)
				end
			end

			local okEncode, encoded = pcall(function()
				return HttpService:JSONEncode({
					abilities = abilityList,
					offense = offenseList,
				})
			end)
			if not okEncode then
				return
			end

			pcall(writefile, outspammerStorage.saveFile, encoded)
		end

		local function getSelectedAbilityDisplayOptions()
			local selected = {}
			for _, key in ipairs(outspammerCatalog.allAbilityKeys) do
				if outspammerSelections.selectedAbilityByKey[key] then
					table.insert(selected, outspammerCatalog.abilityDisplayByKey[key] or key)
				end
			end
			return selected
		end

		local function rebuildAbilityMaps()
			outspammerSelections.selectedAbilities = {}
			outspammerSelections.offenseAbilities = {}

			for key, isEnabled in pairs(outspammerSelections.selectedAbilityByKey) do
				if isEnabled then
					local abilityEnum = AbilityName[key]
					if abilityEnum then
						outspammerSelections.selectedAbilities[abilityEnum] = true
						if outspammerSelections.selectedOffenseByKey[key] then
							outspammerSelections.offenseAbilities[abilityEnum] = true
						end
					end
				end
			end
		end

		local function setSelectedOffense(options)
			outspammerSelections.selectedOffenseByKey = {}

			if typeof(options) == "table" then
				for _, option in ipairs(options) do
					if typeof(option) == "string" then
						local key = outspammerCatalog.abilityKeyByDisplay[option] or option
						if outspammerStorage.validAbilityKeySet[key] then
							outspammerSelections.selectedOffenseByKey[key] = true
						end
					end
				end
			elseif typeof(options) == "string" then
				local key = outspammerCatalog.abilityKeyByDisplay[options] or options
				if outspammerStorage.validAbilityKeySet[key] then
					outspammerSelections.selectedOffenseByKey[key] = true
				end
			end

			rebuildAbilityMaps()
			saveOutspammerSelections()
		end

		local function refreshOffenseDropdown()
			if not outspammerUi.offenseDropdown then
				return
			end

			local offenseOptions = getSelectedAbilityDisplayOptions()
			outspammerUi.offenseDropdown:Refresh(offenseOptions)

			local currentOffenseSelection = {}
			for _, key in ipairs(outspammerCatalog.allAbilityKeys) do
				if
					outspammerSelections.selectedAbilityByKey[key] and outspammerSelections.selectedOffenseByKey[key]
				then
					table.insert(currentOffenseSelection, outspammerCatalog.abilityDisplayByKey[key] or key)
				end
			end
			outspammerUi.offenseDropdown:Set(currentOffenseSelection)
		end

		local function setSelectedAbilities(options)
			outspammerSelections.selectedAbilityByKey = {}

			if typeof(options) == "table" then
				for _, option in ipairs(options) do
					if typeof(option) == "string" then
						local key = outspammerCatalog.abilityKeyByDisplay[option] or option
						if outspammerStorage.validAbilityKeySet[key] then
							outspammerSelections.selectedAbilityByKey[key] = true
						end
					end
				end
			elseif typeof(options) == "string" then
				local key = outspammerCatalog.abilityKeyByDisplay[options] or options
				if outspammerStorage.validAbilityKeySet[key] then
					outspammerSelections.selectedAbilityByKey[key] = true
				end
			end

			for key in pairs(outspammerSelections.selectedOffense