local node_child_iter = mods.multiverse.node_child_iter
local vter = mods.multiverse.vter
local emptyReq = Hyperspace.ChoiceReq()
local blueReq = Hyperspace.ChoiceReq()
blueReq.object = "pilot"
blueReq.blue = true
blueReq.max_level = mods.multiverse.INT_MAX
blueReq.max_group = -1

local rainbowColours = {
	"FF0000",
	"FF5500",
	"FF9900",
	"FFCC00",
	"FFFF00",
	"BBFF00",
	"66FF00",
	"00FF00",
	"00FFAA",
	"00FFFF",
	"00AAFF",
	"0055FF",
	"0000FF",
	"4400FF",
	"8800FF",
	"BB00FF",
	"EE00FF",
	"FF00DD",
	"FF00AA",
	"FF0055"
}
local loop_time = 1.5
local current_time = loop_time

--Code improved by @ranhai to handle multibyte characters
local function colourTextRainbow(s, t)
    local currentIndex = t
    local newS = ""
    
    -- Iterate over UTF-8 characters properly
    for pos, codepoint in utf8.codes(s) do
        local c = utf8.char(codepoint)
        currentIndex = currentIndex + 1

        local colourIndex = (currentIndex - 1) % #rainbowColours + 1
        local colour = rainbowColours[colourIndex]

        local full_prefix = "[style[color:" .. colour .. "]]"

        newS = newS .. full_prefix .. c .. "[[/style]]"
    end
    return newS
end

local function removeStyle(s)
	local prefixRemoved = s:gsub("%[style%[color:.-%]%]", "")
	local suffixRemoved = prefixRemoved:gsub("%[%[/style%]%]", "")
	return suffixRemoved
end

local weightedWeapons = {}
local weightSumWeapons = 0
for weapon in vter(Hyperspace.Blueprints:GetBlueprintList("LIST_WEAPONS_ALL_CRAPBUCKET")) do
	local blueprint = Hyperspace.Blueprints:GetWeaponBlueprint(weapon)
	local weight = math.ceil( (math.min(blueprint.desc.cost, 150)/10) )
	if weight > 0 then
		weightSumWeapons = weightSumWeapons + weight
		table.insert(weightedWeapons, {
			blueprint = blueprint,
			weight = weight
		})
	end
end
local function selectRandomWeapon()
	local rnd = math.random(weightSumWeapons);
	for i = 1, #weightedWeapons do
		if rnd <= weightedWeapons[i].weight then
			return weightedWeapons[i].blueprint
		end
		rnd = rnd - weightedWeapons[i].weight
	end
	error("Weighted selection error - reached end of options without making a choice!")
end

local weightedDrones = {}
local weightSumDrones = 0
for drone in vter(Hyperspace.Blueprints:GetBlueprintList("LIST_DRONES_ALL_CRAPBUCKET")) do
	local blueprint = Hyperspace.Blueprints:GetDroneBlueprint(drone)
	local weight = math.ceil( (math.min(blueprint.desc.cost, 150)/10) )
	if weight > 0 then
		weightSumDrones = weightSumDrones + weight
		table.insert(weightedDrones, {
			blueprint = blueprint,
			weight = weight
		})
	end
end
local function selectRandomDrone()
	local rnd = math.random(weightSumDrones);
	for i = 1, #weightedDrones do
		if rnd <= weightedDrones[i].weight then
			return weightedDrones[i].blueprint
		end
		rnd = rnd - weightedDrones[i].weight
	end
	error("Weighted selection error - reached end of options without making a choice!")
end

local weightedCrew = {}
local weightSumCrew = 0
for crew in vter(Hyperspace.Blueprints:GetBlueprintList("LIST_CREW_ALL_CRAPBUCKET")) do
	local blueprint = Hyperspace.Blueprints:GetCrewBlueprint(crew)
	local weight = math.ceil( (math.min(blueprint.desc.cost, 150)/10) )
	if weight > 0 then
		weightSumCrew = weightSumCrew + weight
		table.insert(weightedCrew, {
			blueprint = blueprint,
			weight = weight
		})
	end
end
for crew in vter(Hyperspace.Blueprints:GetBlueprintList("LIST_CREW_UNIQUE_CRAPBUCKET")) do
	local blueprint = Hyperspace.Blueprints:GetCrewBlueprint(crew)
	local weight = math.ceil( (math.min(blueprint.desc.cost, 150)/10) )
	if weight > 0 then
		weightSumCrew = weightSumCrew + weight
		table.insert(weightedCrew, {
			blueprint = blueprint,
			weight = weight
		})
	end
end
local function selectRandomCrew()
	local rnd = math.random(weightSumCrew);
	for i = 1, #weightedCrew do
		if rnd <= weightedCrew[i].weight then
			return weightedCrew[i].blueprint
		end
		rnd = rnd - weightedCrew[i].weight
	end
	error("Weighted selection error - reached end of options without making a choice!")
end

local lockedAugments = {}
do
	local doc = RapidXML.xml_document("data/hyperspace.xml")
	for node in node_child_iter(doc:first_node("FTL") or doc) do
		if node:name() == "augments" then
			print("found augments")
			for childNode in node_child_iter(node) do
				if childNode:name() == "aug" then
					local augName = childNode:first_attribute("name"):value()
					for augNode in node_child_iter(childNode) do
						if augNode:name() == "locked" then
							lockedAugments[augName] = true
						end
					end
				end
			end
		end
	end
	doc:clear()
end

local excludedAugments = {}
excludedAugments["CRYSTAL_SHARDS"] = true
excludedAugments["NANO_MEDBAY"] = true
excludedAugments["DRONE_SPEED"] = true
excludedAugments["SYSTEM_CASING"] = true
excludedAugments["ION_ARMOR"] = true
excludedAugments["CLOAK_FIRE"] = true
excludedAugments["REPAIR_ARM"] = true
excludedAugments["SCRAP_COLLECTOR"] = true
excludedAugments["ADV_SCANNERS"] = true
excludedAugments["AUTO_COOLDOWN"] = true
excludedAugments["SHIELD_RECHARGE"] = true
--excludedAugments["WEAPON_PREIGNITE"] = true
excludedAugments["FTL_BOOSTER"] = true
excludedAugments["FTL_JUMPER"] = true
excludedAugments["DRONE_RECOVERY"] = true
excludedAugments["FTL_JAMMER"] = true
excludedAugments["STASIS_POD"] = true
excludedAugments["FTL_JUMPER_GOOD"] = true
excludedAugments["BOARDER_RECOVERY"] = true
excludedAugments["MIND_ORDER"] = true
excludedAugments["ARTILLERY_ORDER"] = true
excludedAugments["TELEPORT_RECALL"] = true
excludedAugments["AUGMENT_SLOT"] = true
excludedAugments["CARGO_SLOT"] = true
excludedAugments["CREW_STIMS_ULTRA"] = true
excludedAugments["FLAGSHIP_SHIELD"] = true
excludedAugments["FLAGSHIP_SHIELD_FULL"] = true
excludedAugments["SYSTEM_UNBREAKING"] = true
excludedAugments["HULL_UNBREAKING"] = true
excludedAugments["ENEMY_RESIST_50"] = true
excludedAugments["NO_SUFFOCATE"] = true

local weightedAugments = {}
local weightSumAugment = 0
for _, file in ipairs(mods.multiverse.blueprintFiles) do
	local doc = RapidXML.xml_document(file)
	for node in node_child_iter(doc:first_node("FTL") or doc) do
		if node:name() == "augBlueprint" then
			local descValid = false
			local isLocked = lockedAugments[node:first_attribute("name"):value()]
			local cost = 0
			for childNode in node_child_iter(node) do
				--print(childNode:name().." value:"..tostring(childNode:value()))
				local seeThis, _ = childNode:value():find("YOU SHOULD NEVER SEE THIS")
				if childNode:name() == "desc" and type(childNode:value()) == "string" and not seeThis then
					descValid = true
				elseif childNode:name() == "cost" then
					cost = tonumber(childNode:value())
				end
			end
			--log(node:first_attribute("name"):value().." valid:"..tostring(descValid).." cost:"..tostring(cost))
			if descValid and not (isLocked or excludedAugments[node:first_attribute("name"):value()]) then
				local blueprint = Hyperspace.Blueprints:GetAugmentBlueprint(node:first_attribute("name"):value())
				local weight = math.ceil( (math.min(cost, 150)/10) )
				if weight > 0 then
					weightSumAugment = weightSumAugment + weight
					table.insert(weightedAugments, {
						blueprint = blueprint,
						weight = weight
					})
				end
			end
		end
	end
	doc:clear()
end
local function selectRandomAugment()
	local rnd = math.random(weightSumAugment);
	for i = 1, #weightedAugments do
		if rnd <= weightedAugments[i].weight then
			return weightedAugments[i].blueprint
		end
		rnd = rnd - weightedAugments[i].weight
	end
	error("Weighted selection error - reached end of options without making a choice!")
end

local crewNames = {}
do
	local doc = RapidXML.xml_document("data/names.xml")
	for node in node_child_iter(doc:first_node("FTL") or doc) do
		if node:name() == "nameList" then
			for nameNode in node_child_iter(node) do
				crewNames[nameNode:value()] = true
				--print("crewName:"..nameNode:value())
			end
		end
	end
	doc:clear()
end

local excludedEvents = {"STORAGE_CHECK", "COMBAT_CHECK"}

local renderRainbowText = false
script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(event)
	renderRainbowText = false
	local eventManager = Hyperspace.Event
	if event.eventName == "RAINBOW_MODE_SELECT" then renderRainbowText = true end
	if Hyperspace.playerVariables.rainbow_enabled ~= 1 then return end
	
	if event.eventName == "RAINBOW_SELECT_START_2" or event.eventName == "RAINBOW_SELECT_3" then
		renderRainbowText = true
	elseif event.eventName == "RAINBOW_SELECT_1" then
		renderRainbowText = true
		event:RemoveChoice(0)
		event.stuff.weapon = nil
		for i = 1, 4 do
			local weapon = selectRandomWeapon()
			local drone = selectRandomDrone()
			local weaponEvent = eventManager:CreateEvent("RAINBOW_SELECT_2", 0, false)
			weaponEvent.stuff.weapon = weapon
			local droneEvent = eventManager:CreateEvent("RAINBOW_SELECT_2", 0, false)
			droneEvent.stuff.drone = drone
			event:AddChoice(weaponEvent, "Pick this:", emptyReq, false)
			event:AddChoice(droneEvent, "Pick this:", emptyReq, false)
		end
	elseif event.eventName == "RAINBOW_SELECT_2" then
		renderRainbowText = true
		event:RemoveChoice(0)
		local augment = selectRandomAugment()
		local augmentEvent = eventManager:CreateEvent("RAINBOW_SELECT_3", 0, false)
		augmentEvent.stuff.augment = augment
		event:AddChoice(augmentEvent, "Pick this:", emptyReq, false)
		for i = 1, 4 do
			local crew = selectRandomCrew()
			local crewEvent = eventManager:CreateEvent("RAINBOW_SELECT_3", 0, false)
			crewEvent.stuff.crew = 1
			crewEvent.stuff.crewBlue = crew
			event:AddChoice(crewEvent, "Pick this:", emptyReq, false)
		end
	else
		local excludedMatch = false
		for _, eventPrefix in ipairs(excludedEvents) do
			local startIndex, _ = event.eventName:find(eventPrefix)
			if startIndex then 
				excludedMatch = true 
				--print(event.eventName.." excluded")
			end
		end
		if not excludedMatch then
			local resourceEvent = event.stuff
			local removeItem = false
			if resourceEvent.weapon then
				removeItem = "weapon"
				resourceEvent.weapon = nil
			end
			if resourceEvent.drone then
				removeItem = "drone"
				resourceEvent.drone = nil
			end
			if resourceEvent.augment then
				removeItem = "augmentation"
				resourceEvent.augment = nil
			end
			--if resourceEvent.crew > 0 then print(resourceEvent.crewBlue.crewNameLong) end
			if resourceEvent.crew > 0 and (crewNames[resourceEvent.crewBlue.crewNameLong:GetText()] or Hyperspace.metaVariable.rainbow_namedCrew == 0) then
				removeItem = "crew member"
				resourceEvent.crew = 0
				--resourceEvent.crewBlue = nil
			end

			resourceEvent = event.reward
			if resourceEvent.weapon then
				removeItem = "weapon"
				resourceEvent.weapon = nil
			end
			if resourceEvent.drone then
				removeItem = "drone"
				resourceEvent.drone = nil
			end
			if resourceEvent.augment then
				removeItem = "augmentation"
				resourceEvent.augment = nil
			end
			if resourceEvent.crew > 0 and (crewNames[resourceEvent.crewBlue.crewNameLong:GetText()] or Hyperspace.metaVariable.rainbow_namedCrew == 0) then
				removeItem = "crew member"
				resourceEvent.crew = 0
				--resourceEvent.crewBlue = nil
			end

			if removeItem then
				noun = "it"
				if removeItem == "crew member" then noun = "them" end
				event.text.data = event.text:GetText().."\n\n".."The "..removeItem.." you recieved dissolves into "..colourTextRainbow("rainbow coloured dust", 0).." as you bring "..noun.." onboard."
				modularEvent.text.isLiteral = true
			end
		end
	end
end)

local chestAnimLoopTime = 4
local chestAnimTime = chestAnimLoopTime
local chestAnimFrames = 60
local lastT = nil
local lastChestI = nil
script.on_render_event(Defines.RenderEvents.CHOICE_BOX, function(choiceBox)
	if renderRainbowText then
		chestAnimTime = chestAnimTime - Hyperspace.FPS.SpeedFactor/16
		if chestAnimTime <= 0 then chestAnimTime = chestAnimTime + chestAnimLoopTime end
		local chestI = math.ceil( (chestAnimTime/chestAnimLoopTime) * chestAnimFrames)
		local blueprint = Hyperspace.Blueprints:GetWeaponBlueprint("RAINBOW_CHEST")
		if chestI ~= lastChestI then
			lastChestI = chestI
			blueprint.weaponArt = "rainbow_chest_"..chestI
		end

		current_time = current_time - Hyperspace.FPS.SpeedFactor/16
		if current_time <= 0 then current_time = current_time + loop_time end
		local t = math.ceil((current_time/loop_time)*(#rainbowColours))

		if t ~= lastT then
			lastT = t
			choiceBox.mainText = removeStyle(choiceBox.mainText)
			choiceBox.mainText = colourTextRainbow(choiceBox.mainText, t)
			for choice in vter(choiceBox:GetChoices()) do
				choice.text = removeStyle(choice.text)
				t = t % #rainbowColours + 1
				choice.text = colourTextRainbow(choice.text, t)
			end
		end
	end
end, function() end)

local enabledAnim = Hyperspace.Animations:GetAnimation("rainbow_mode_enabled")
enabledAnim.position.x = 11
enabledAnim.position.y = 13
enabledAnim.tracker.loop = true
enabledAnim:Start(true)

script.on_render_event(Defines.RenderEvents.SHIP_STATUS, function() end, function() 
	if Hyperspace.playerVariables.rainbow_enabled == 1 then
		enabledAnim:Update()
		enabledAnim:OnRender(1, Graphics.GL_Color(1, 1, 1, 1), false)
	end
end)

local rainbowQueued = false
local function queueRainbowChest()
	if not rainbowQueued then rainbowQueued = true end
end

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
	local commandGui = Hyperspace.App.gui
	if ship.iShipId == 0 and rainbowQueued and not commandGui.event_pause then
		print("load rainbow chest")
		rainbowQueued = false
		local worldManager = Hyperspace.App.world
		Hyperspace.CustomEventsParser.GetInstance():LoadEvent(worldManager,"RAINBOW_SELECT_START",false,-1)
	end
end)

script.on_game_event("ATLAS_MENU", false, queueRainbowChest)
script.on_game_event("ATLAS_MENU_NOEQUIPMENT", false, queueRainbowChest)