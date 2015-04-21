local SI = {}

-- MultiCraft Global Variable
MultiCraftAddon = MultiCraftAddon or {}

MultiCraftAddon.name = "MultiCraft"
MultiCraftAddon.debugenabled = false
MultiCraftAddon.debugenabled = false

-- Inits
MultiCraftAddon.repetitions = 1
MultiCraftAddon.sliderValue = 1
MultiCraftAddon.isWorking = false

-- Tables
MultiCraftAddon.provisioner = {}
MultiCraftAddon.enchanting = {}
MultiCraftAddon.alchemy = {}

-- Smithing, wood and clothing use exactly same methods, they're called "smithing" in MC
MultiCraftAddon.smithing = {}

MultiCraftAddon.selectedCraft = nil 	-- this will hold a pointer to the currently open crafting station

MultiCraftAddon.settings = {
	sliderDefault = false,
	traitsEnabled = true,
	callDelay = 500
}

-- register SIs
SI.USAGE_1		= "SI_USAGE_1"
SI.USAGE_2		= "SI_USAGE_2"
SI.USAGE_3		= "SI_USAGE_3"
SI.USAGE_4		= "SI_USAGE_4"
SI.DEFAULT_MAX	= "SI_DEFAULT_MAX"
SI.DEFAULT_MIN	= "SI_DEFAULT_MIN"
SI.TRAITS_ON	= "SI_TRAITS_ON"
SI.TRAITS_OFF	= "SI_TRAITS_OFF"
SI.CALL_DELAY	= "SI_CALL_DELAY"

-- Utility functions
function SI.get(key, n)
    assert(key ~= nil)
    return assert(GetString(_G[key], n))
end

-- Still need to find the usage of SI
MultiCraftAddon.SI = SI

-- Local copy of global constants
-- Enchanting
MultiCraftAddon.ENCHANTING_MODE_CREATION = ENCHANTING_MODE_CREATION
MultiCraftAddon.ENCHANTING_MODE_EXTRACTION = ENCHANTING_MODE_EXTRACTION
-- Smithing
MultiCraftAddon.SMITHING_MODE_REFINEMENT = SMITHING_MODE_REFINMENT
MultiCraftAddon.SMITHING_MODE_CREATION = SMITHING_MODE_CREATION
MultiCraftAddon.SMITHING_MODE_DECONSTRUCTION = SMITHING_MODE_DECONSTRUCTION

MultiCraftAddon.GENERAL_MODE_CREATION = 1								-- Alchemy, Provisionner

-- Will output to chat a debug message if MultiCraftAddon.debug is enabled
function MultiCraftAddon.debug(message)
	if MultiCraftAddon.debugenabled then
		d(message)
	end
end

-- Triggers when EVENT_CRAFTING_STATION_INTERACT
function MultiCraftAddon.SelectCraftingSkill(eventCode, craftingType, sameStation)

	-- Provisionner
	if craftingType == CRAFTING_TYPE_PROVISIONING then
		MultiCraftAddon.selectedCraft = MultiCraftAddon.provisioner
		MultiCraft:SetHidden(false)
		MultiCraftAddon.debug(".SelectCraftingSkill->CRAFTING_TYPE_PROVISIONING")
	-- Enchanting
	elseif craftingType == CRAFTING_TYPE_ENCHANTING then
		MultiCraftAddon.selectedCraft = MultiCraftAddon.enchanting
		MultiCraftAddon.debug(".SelectCraftingSkill->CRAFTING_TYPE_ENCHANTING")
	-- Alchemy
	elseif craftingType == CRAFTING_TYPE_ALCHEMY then
		MultiCraftAddon.selectedCraft = MultiCraftAddon.alchemy
		MultiCraft:SetHidden(false)
		MultiCraftAddon.debug(".SelectCraftingSkill->CRAFTING_TYPE_ALCHEMY")
	-- Blacksmithing
	elseif craftingType == CRAFTING_TYPE_BLACKSMITHING then
		MultiCraftAddon.selectedCraft = MultiCraftAddon.smithing
		MultiCraftAddon.debug(".SelectCraftingSkill->CRAFTING_TYPE_BLACKSMITHING")
	-- Clothier
	elseif craftingType == CRAFTING_TYPE_CLOTHIER then
		MultiCraftAddon.selectedCraft = MultiCraftAddon.smithing
		MultiCraftAddon.debug(".SelectCraftingSkill->CRAFTING_TYPE_CLOTHIER")
	-- Woodworking
	elseif craftingType == CRAFTING_TYPE_WOODWORKING then
		MultiCraftAddon.selectedCraft = MultiCraftAddon.smithing
		MultiCraftAddon.debug(".SelectCraftingSkill->CRAFTING_TYPE_WOODWORKING")
	end
	
	-- Init Slider
	MultiCraftAddon.ResetSlider()
	
	-- Prevent UI bug due to fast Esc
	CALLBACK_MANAGER:FireCallbacks("CraftingAnimationsStopped")
	
end

-- Triggers when EVENT_CRAFT_STARTED and Called at Cleanup
function MultiCraftAddon.HideUI()
	-- Hide XML
	MultiCraftSlider:SetHidden(true)
end

-- Triggers when EVENT_END_CRAFTING_STATION_INTERACT
function MultiCraftAddon.Cleanup(eventCode)
	
	-- Hide UI
	MultiCraftAddon.debug(".Cleanup")
	
	-- Remove button
	-- Aya: RemoveKeybindButton was not done before ?
	-- Use flag removeKeybindDescriptor because cause the UI to bug if we remove a UI_SHORTCUT_PRIMARY
	
	if MultiCraftAddon.removeKeybindDescriptor then
		MultiCraftAddon.debug(".Cleanup->RemoveKeybindButton")
		KEYBIND_STRIP:RemoveKeybindButton(MultiCraftAddon.keybindDescriptor)
	end
	
	MultiCraftAddon.HideUI()
	MultiCraftAddon.isWorking = false
	MultiCraftAddon.selectedCraft = nil
	
	MultiCraftAddon.debug(".Cleanup->Cleaned")

end

function MultiCraftAddon.EnableOrDisableUI()
	
	MultiCraftAddon.debug(".EnableOrDisableUI()")
	
	-- Init
	local hidden = true
	local mode = MultiCraftAddon.selectedCraft:GetMode()
	
	-- Provisioning & Alchemy
	if MultiCraftAddon.selectedCraft == MultiCraftAddon.provisioner or
	   MultiCraftAddon.selectedCraft == MultiCraftAddon.alchemy then
		if MultiCraftAddon.selectedCraft:IsCraftable() then
			MultiCraftAddon.debug(".EnableOrDisableUI->false()")
			hidden = false
		end
	-- Enchanting
	elseif MultiCraftAddon.selectedCraft == MultiCraftAddon.enchanting then
		if (mode == MultiCraftAddon.ENCHANTING_MODE_CREATION and MultiCraftAddon.selectedCraft:IsCraftable()) or
		   (mode == MultiCraftAddon.ENCHANTING_MODE_EXTRACTION and MultiCraftAddon.selectedCraft:IsExtractable()) then
			MultiCraftAddon.debug(".EnableOrDisableUI->false()")
			hidden = false
		end
	-- Smithing (Smithing, Wood, Clothing)
	elseif MultiCraftAddon.selectedCraft == MultiCraftAddon.smithing then
		-- there is a game bug where this returns erroneously true in refinement after completing an extract that results in having less
		-- than 10 items but still having the item selected
		-- TODO: fix it
		if (mode == MultiCraftAddon.SMITHING_MODE_REFINEMENT and MultiCraftAddon.selectedCraft:IsExtractable()) or
		   --Aya: Buggy with UI_SHORTCUT_SECONDARY, it will bug the UI ->
		   (mode == MultiCraftAddon.SMITHING_MODE_CREATION and MultiCraftAddon.selectedCraft:IsCraftable()) or
		   (mode == MultiCraftAddon.SMITHING_MODE_CREATION and MultiCraftAddon.selectedCraft:IsCraftable()) or
		   (mode == MultiCraftAddon.SMITHING_MODE_DECONSTRUCTION and MultiCraftAddon.selectedCraft:IsDeconstructable()) then
			MultiCraftAddon.debug(".EnableOrDisableUI->false()")
			hidden = false
		end
	end
	
	MultiCraftAddon.debug(".EnableOrDisableUI->hidden = " .. tostring(hidden))
	
	-- Hide or Show XML
	MultiCraft:SetHidden(hidden)
	
end

-- We don't add the keybind, it's the game itself which add it. We only update it
function MultiCraftAddon.UpdateSliderValueAndKeybind()

	-- Slider come from XML and inherits from ZO_Slider object, selected value is the slider one
	MultiCraftAddon.sliderValue = zo_floor(MultiCraftSlider:GetValue())
	if MultiCraftAddon.sliderValue == 0 then
		-- When opening the window for the first time with nothing selected, it can be 0 (ex: Alchemy, Enchanting), protect against this by forcing 1
		MultiCraftAddon.sliderValue = 1
	end
	
	MultiCraftAddon.debug(".UpdateSliderValueAndKeybind->sliderValue = " .. tostring(MultiCraftAddon.sliderValue))
	
	-- This code is only executed if we're actually on a crafting station
	if MultiCraftAddon.selectedCraft:GetSecondaryKeybindStripDescriptor().visible() then
	
		-- Modification because UI bugs, if Smithing, need to do a UI_SHORTCUT_PRIMARY on SMITHING_MODE_CREATION
		if MultiCraftAddon.selectedCraft == MultiCraftAddon.smithing then
			
			MultiCraftAddon.selectedCraft:GetMode()
			if mode == MultiCraftAddon.SMITHING_MODE_CREATION then
				MultiCraftAddon.keybindDescriptor = {
					alignment = KEYBIND_STRIP_ALIGN_CENTER,
					name = MultiCraftAddon.selectedCraft:GetSecondaryKeybindStripDescriptor().name(),
					keybind = "UI_SHORTCUT_SECONDARY",
					callback = MultiCraftAddon.selectedCraft:GetSecondaryKeybindStripDescriptor().callback,
				}
				MultiCraftAddon.removeKeybindDescriptor = true
			else
				MultiCraftAddon.keybindDescriptor = {
					alignment = KEYBIND_STRIP_ALIGN_CENTER,
					name = MultiCraftAddon.selectedCraft:GetSecondaryKeybindStripDescriptor().name() .. " " .. MultiCraftAddon.sliderValue,
					keybind = "UI_SHORTCUT_SECONDARY",
					callback = MultiCraftAddon.selectedCraft:GetSecondaryKeybindStripDescriptor().callback,
				}
				MultiCraftAddon.removeKeybindDescriptor = true
			end
		else
			MultiCraftAddon.keybindDescriptor = {
				alignment = KEYBIND_STRIP_ALIGN_CENTER,
				name = MultiCraftAddon.selectedCraft:GetSecondaryKeybindStripDescriptor().name() .. " " .. MultiCraftAddon.sliderValue,
				keybind = "UI_SHORTCUT_SECONDARY",
				callback = MultiCraftAddon.selectedCraft:GetSecondaryKeybindStripDescriptor().callback,
			}
			MultiCraftAddon.removeKeybindDescriptor = true
		end
		
		KEYBIND_STRIP:UpdateKeybindButton(MultiCraftAddon.keybindDescriptor)
		
	end
	
end

-- This function reset the slider to the correct values (min = 1, max = qty craftable, and maybe the default value)
function MultiCraftAddon.ResetSlider(mode,setvalue)

	MultiCraftAddon.debug(".ResetSlider()")

	-- Can really occurs ?
	if not MultiCraftAddon.selectedCraft then return end
	-- DisableSlider or show ?
	MultiCraftAddon.EnableOrDisableUI()
	
	local sliderValue = 1
	
	local numCraftable = 1
	
	-- handle mode and setvalue override parameters
	if setvalue == nil and type(mode) == "boolean" then
		setvalue = mode
		mode = nil
	end
	
	if setvalue == nil then
		setvalue = true
	end
	
	-- On which tab are we ? MultiCraftAddon.selectedCraft is wrapped by OverrideXXX
	mode = mode or MultiCraftAddon.selectedCraft:GetMode()
	
	-- Get qty craftable
	-- For Provisionner
	if MultiCraftAddon.selectedCraft == MultiCraftAddon.provisioner then
		--Aya: Still need to improve switching tabs between food and drink to avoid 0 craft in 1 of the 2 tabs
		if MultiCraftAddon.selectedCraft:IsCraftable() then
			local data = PROVISIONER.recipeTree:GetSelectedData()
			numCraftable = data.numCreatable
		else
			-- Only a try to hide when we cannot do anything, need to be reworked, can occurs if we can do 1 food and 0 drink
			numCraftable = 0
		end
	-- For Enchanting
	elseif MultiCraftAddon.selectedCraft == MultiCraftAddon.enchanting then
		-- 1st tab, making glyphs
		if mode == MultiCraftAddon.ENCHANTING_MODE_CREATION then
			if MultiCraftAddon.selectedCraft:IsCraftable() then
				-- We look in craftingInventory (Bagpack+Bank) how much items we got, and we select the min, cause enchanting use 1 rune per glyph
				for k, v in pairs(ENCHANTING.runeSlots) do
					if k == 1 then
						numCraftable = v.craftingInventory.itemCounts[v.itemInstanceId]
					else
						numCraftable = zo_min(numCraftable, v.craftingInventory.itemCounts[v.itemInstanceId])
					end
					MultiCraftAddon.debug("in for numCraftable = " .. tostring(zo_floor(numCraftable)))
				end
			end
		-- 2nd tab, deconstruct Glyphs
		elseif mode == MultiCraftAddon.ENCHANTING_MODE_EXTRACTION then
			if MultiCraftAddon.selectedCraft:IsExtractable() then
				-- We count how many Glyphs we got in craftingInventory (Bagpack+Bank)
				numCraftable = ENCHANTING.extractionSlot.craftingInventory.itemCounts[ENCHANTING.extractionSlot.itemInstanceId]
			end
		end
	-- Alchemy
	elseif MultiCraftAddon.selectedCraft == MultiCraftAddon.alchemy then
		if MultiCraftAddon.selectedCraft:IsCraftable() then
			
			-- Same as enchanting, our Qty will be the min between each solvant and reagents
			-- Solvant
			numCraftable = ALCHEMY.solventSlot.craftingInventory.itemCounts[ALCHEMY.solventSlot.itemInstanceId]
			
			-- Reagents
			for k, v in pairs(ALCHEMY.reagentSlots) do
				if v:MeetsUsabilityRequirement() then			
					if v.craftingInventory.itemCounts[v.itemInstanceId] ~= nil then
						numCraftable = zo_min(numCraftable, v.craftingInventory.itemCounts[v.itemInstanceId])
						MultiCraftAddon.debug("in for numCraftable = " .. tostring(zo_floor(numCraftable)))
					end
				end
			end
			
		end
	-- Smithing (Wood/Smith/Clothing)
	elseif MultiCraftAddon.selectedCraft == MultiCraftAddon.smithing then
		-- 1st tab, refinement
		if mode == MultiCraftAddon.SMITHING_MODE_REFINEMENT then
			-- Count how many Items we got in craftingInventory and divide per stack size needed to refine
			if MultiCraftAddon.selectedCraft:IsExtractable() then
				numCraftable = SMITHING.refinementPanel.extractionSlot.craftingInventory.itemCounts[SMITHING.refinementPanel.extractionSlot.itemInstanceId]
				numCraftable = zo_floor(numCraftable / GetRequiredSmithingRefinementStackSize())
			end
		-- 2nd tab, creation
		elseif mode == MultiCraftAddon.SMITHING_MODE_CREATION then
			if MultiCraftAddon.selectedCraft:IsCraftable() then
				
				MultiCraftAddon.debug("SMITHING Creation")
				-- Determine qty to craft
				-- patternIndex is ID of item to do (glove, chest, sword..)
				-- materialIndex is ID of material to use (galatite, iron, etc)
				-- materialQuantity is Qty of material to use (10, 12, etc..)
				-- styleIndex is ID of style to use, qty is always 1
				-- traitIndex is ID of trait to use, qty is always 1
				local patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex = SMITHING.creationPanel:GetAllCraftingParameters()
				
				-- How many material do we got for this item ?
				local materialCount = GetCurrentSmithingMaterialItemCount(patternIndex, materialIndex) / materialQuantity
				-- How many stones ?
				local styleItemCount = GetCurrentSmithingStyleItemCount(styleIndex)
				-- How many trait stones ?
				local traitCount = GetCurrentSmithingTraitItemCount(traitIndex)
				
				-- Because trait is optional, start with the min of material and style which is always needed
				numCraftable = zo_min(materialCount, styleItemCount)
				
				-- A trait has been selected, 1 is No trait, and if no trait min is already known
				if traitIndex ~= 1 then
					
					-- Can be disabled in option, default is true
					if MultiCraftAddon.settings.traitsEnabled then
						-- Min is maybe traits stones value ?
						numCraftable = zo_min(numCraftable, traitCount)
					else
						-- Protection asked by user
						numCraftable = 1
					end
				end
				
			end
		-- 3rd tab, deconstruction
		elseif mode == MultiCraftAddon.SMITHING_MODE_DECONSTRUCTION then
			if MultiCraftAddon.selectedCraft:IsDeconstructable() then
				-- Count how many Items we got in craftingInventory
				numCraftable = SMITHING.deconstructionPanel.extractionSlot.craftingInventory.itemCounts[SMITHING.deconstructionPanel.extractionSlot.itemInstanceId]
			end
		end
	end
	
	if numCraftable > 0 then
		-- DisableSlider or show ?
		MultiCraftAddon.debug(".ResetSlider->numCraftable = " .. numCraftable)
		MultiCraftAddon.EnableOrDisableUI()
	end
	
	MultiCraftAddon.debug(".ResetSlider->numCraftable = " .. tostring(zo_floor(numCraftable)))
	
	-- Protection against divisions
	numCraftable = zo_floor(numCraftable)
	
	-- Don't show slider if Qty = 1
	-- MultiCraftSlider is handled by XML and inherits from ZO_Slider
	if numCraftable == 1 then
		MultiCraftAddon.debug(".ResetSlider->Hide slider")
		MultiCraftSlider:SetHidden(true)
	else
		MultiCraftAddon.debug(".ResetSlider->Show slider")
		MultiCraftSlider:SetHidden(false)
		MultiCraftSlider:SetMinMax(1, numCraftable)
	end
	
	if setvalue == true then 

		-- set to max value for refining and deconstructing.
		if (MultiCraftAddon.selectedCraft == MultiCraftAddon.smithing and (mode == MultiCraftAddon.SMITHING_MODE_REFINEMENT or mode == MultiCraftAddon.SMITHING_MODE_DECONSTRUCTION))
		or (MultiCraftAddon.selectedCraft == MultiCraftAddon.enchanting and mode == MultiCraftAddon.ENCHANTING_MODE_EXTRACTION) then
			MultiCraftSlider:SetValue(numCraftable)
		elseif MultiCraftAddon.settings.sliderDefault then
		-- clamp
			MultiCraftSlider:SetValue(math.min(numCraftable,math.max(MultiCraftAddon.settings.sliderDefault,1)))
		else
			MultiCraftSlider:SetValue(1)
		end
	else
		-- clamp again
		MultiCraftSlider:SetValue(math.min(numCraftable,math.max(MultiCraftSlider:GetValue(),1)))
	end
	-- Set Slider Value and its Keybind (generally R button)
	MultiCraftAddon.UpdateSliderValueAndKeybind()
	
end

-- Executed when user start to craft (press the keybind)
-- Only for : PROVISIONER:Create(), ENCHANTING:Create(), ALCHEMY:Create(), SMITHING.creationPanel:Create(), SMITHING.deconstructionPanel:Extract(), SMITHING.refinementPanel:Extract()
-- When this function is executed, result is always a success, qties and skill have already been verified
function MultiCraftAddon.Work(workFunc)
	
	MultiCraftAddon.debug(".Work")
	
	-- selectedCraft is set when entering the craft station, isWorking is for prevent MultiCraft loops, this function is called only at 1st launch
	if MultiCraftAddon.selectedCraft and not MultiCraftAddon.isWorking then
		-- We're working
		MultiCraftAddon.isWorking = true
		-- When a craft is completed, execute :ContinueWork to find if we need to continue work
		EVENT_MANAGER:RegisterForEvent(MultiCraftAddon.name, EVENT_CRAFT_COMPLETED, function() MultiCraftAddon.ContinueWork(workFunc) end)
		-- We did 1 craft, so slider is decremented, .repetitions is the number of craft to do after this one
		MultiCraftAddon.repetitions = MultiCraftAddon.sliderValue - 1
	end
	
end

-- Executed when EVENT_CRAFT_COMPLETED is triggered, set just before craft has been started
function MultiCraftAddon.ContinueWork(workFunc)
	
	MultiCraftAddon.debug(".ContinueWork")
	
	-- Need to do somework ?
	if MultiCraftAddon.repetitions > 0 then
		-- Let's do another one
		MultiCraftAddon.repetitions = MultiCraftAddon.repetitions - 1
		-- It will call itself with a delay of XX ms
		zo_callLater(workFunc, MultiCraftAddon.settings.callDelay)
	else
		-- Work is finished, unregisters itselfs
		EVENT_MANAGER:UnregisterForEvent(MultiCraftAddon.name, EVENT_CRAFT_COMPLETED)
		-- Reset slider to 1, and change work flag
		MultiCraftAddon.isWorking = false
		MultiCraftAddon.ResetSlider(false)
	end
end

function MultiCraftAddon.onAddonLoaded(eventCode, addonName)
	
	-- Protect
	if addonName ~= MultiCraftAddon.name then return end
	
	-- Get Vars
	MultiCraftAddon.settings = ZO_SavedVars:NewAccountWide(MultiCraftAddon.name .. 'SV', 1, nil, MultiCraftAddon.settings)
	
	-- Set up function overrides
	MultiCraftAddon.OverrideProvisionner()
	MultiCraftAddon.OverrideEnchanting()
	MultiCraftAddon.OverrideAlchemy()
	MultiCraftAddon.OverrideSmithing()
	
	-- Hook everything up
	-- Will Hook Real function with MultiCraft ones (MultiCraft function will be executed before real ones)
	ZO_PreHook(PROVISIONER, 'Create', function() MultiCraftAddon.Work(MultiCraftAddon.provisioner.Create) end)
	ZO_PreHook(ENCHANTING, 'Create', function() MultiCraftAddon.Work(MultiCraftAddon.enchanting.Create) end)
	ZO_PreHook(ALCHEMY, 'Create', function() MultiCraftAddon.Work(MultiCraftAddon.alchemy.Create) end)
	ZO_PreHook(SMITHING.creationPanel, 'Create', function() MultiCraftAddon.Work(MultiCraftAddon.smithing.Create) end)
	ZO_PreHook(SMITHING.deconstructionPanel, 'Extract', function() MultiCraftAddon.Work(MultiCraftAddon.smithing.Deconstruct) end)
	ZO_PreHook(SMITHING.refinementPanel, 'Extract', function() MultiCraftAddon.Work(MultiCraftAddon.smithing.Extract) end)
	
	-- Slider come from XML and inherits from ZO_Slider object, function will run each time value is changed on the slider
	MultiCraftSlider:SetHandler("OnValueChanged", MultiCraftAddon.UpdateSliderValueAndKeybind)
	
	EVENT_MANAGER:UnregisterForEvent(MultiCraftAddon.name, EVENT_ADD_ON_LOADED)
	
end

function MultiCraftAddon.OnMouseWheel(self, delta)
	
	local valmin, valmax = MultiCraftSlider:GetMinMax()
	local newval = MultiCraftSlider:GetValue() + delta
	
	if newval >= valmin and newval <= valmax then
		MultiCraftSlider:SetValue(newval)
	end

end

function MultiCraftAddon.OverrideProvisionner()

	-- Provisioner
	MultiCraftAddon.provisioner.SelectNode = PROVISIONER.recipeTree.SelectNode
	
	PROVISIONER.recipeTree.SelectNode = function(...)
		MultiCraftAddon.provisioner.SelectNode(...)
		MultiCraftAddon.ResetSlider()
	end
	
	-- Create function
	MultiCraftAddon.provisioner.Create = function()
		PROVISIONER:Create()
	end
	
	-- for polymorphism
	MultiCraftAddon.provisioner.GetMode = function()
		return MultiCraftAddon.GENERAL_MODE_CREATION
	end
	
	-- Wrapper to check if an item is craftable
	MultiCraftAddon.provisioner.IsCraftable = function()
		return PROVISIONER:IsCraftable()
	end
	
	-- wrapper to get the keybind descriptor for the craft button
	-- Aya: 1.5 dropped KeybindStripDescriptor for PROVISIONER: Replaced by mainKeybindStripDescriptor
	MultiCraftAddon.provisioner.GetSecondaryKeybindStripDescriptor = function()
		return PROVISIONER.mainKeybindStripDescriptor[1]
	end

end

function MultiCraftAddon.OverrideEnchanting()

	-- Enchanting
	-- Tab change
	MultiCraftAddon.enchanting.SetEnchantingMode = ENCHANTING.SetEnchantingMode
	
	ENCHANTING.SetEnchantingMode = function(...)
		MultiCraftAddon.enchanting.SetEnchantingMode(...)
		MultiCraftAddon.ResetSlider()
	end
	
	-- For polymorphism
	MultiCraftAddon.enchanting.GetMode = function()
		return ENCHANTING:GetEnchantingMode()
	end
	
	-- Rune slot change
	MultiCraftAddon.enchanting.SetRuneSlotItem = ENCHANTING.SetRuneSlotItem
	
	ENCHANTING.SetRuneSlotItem = function(...)
		MultiCraftAddon.enchanting.SetRuneSlotItem(...)
		-- Reset Slider each time a Runeslot is changed
		MultiCraftAddon.ResetSlider()
	end
	
	-- Extraction selection change
	MultiCraftAddon.enchanting.OnSlotChanged = ENCHANTING.OnSlotChanged
	
	ENCHANTING.OnSlotChanged = function(...)
		MultiCraftAddon.enchanting.OnSlotChanged(...)
		-- Reset Slider each time Glyph is changed
		MultiCraftAddon.ResetSlider()
	end
	
	-- Create and extract function
	MultiCraftAddon.enchanting.Create = function()
		ENCHANTING:Create()
	end
	
	-- wrapper to check if an item is craftable
	MultiCraftAddon.enchanting.IsCraftable = function()
		return ENCHANTING:IsCraftable()
	end
	
	-- ?
	MultiCraftAddon.enchanting.IsExtractable = MultiCraftAddon.enchanting.IsCraftable
	
	-- Wrapper to get the keybind descriptor for the craft button
	MultiCraftAddon.enchanting.GetSecondaryKeybindStripDescriptor = function()
		return ENCHANTING.keybindStripDescriptor[2]
	end

end

function MultiCraftAddon.OverrideAlchemy()

	-- Alchemy
	-- Selection Change
	MultiCraftAddon.alchemy.OnSlotChanged = ALCHEMY.OnSlotChanged
	ALCHEMY.OnSlotChanged = function(...)
		MultiCraftAddon.alchemy.OnSlotChanged(...)
		-- Reset slider each time a solvant or a plant is changed
		MultiCraftAddon.ResetSlider()
	end
	
	-- Create function
	MultiCraftAddon.alchemy.Create = function()
		ALCHEMY:Create()
	end
	
	-- For polymorphism
	MultiCraftAddon.alchemy.GetMode = function()
		return MultiCraftAddon.GENERAL_MODE_CREATION
	end
	
	-- Wrapper to check if an item is craftable
	MultiCraftAddon.alchemy.IsCraftable = function()
		return ALCHEMY:IsCraftable()
	end
	
	-- Xrapper to get the keybind descriptor for the craft button
	MultiCraftAddon.alchemy.GetSecondaryKeybindStripDescriptor = function()
		return ALCHEMY.keybindStripDescriptor[2]
	end
	
end

function MultiCraftAddon.OverrideSmithing()

	-- Smithing
	-- tab change
	MultiCraftAddon.smithing.SetMode = SMITHING.SetMode
	
	-- override set mode to fix change tab from de-construct to creation defaulting to maximum
	SMITHING.SetMode = function(self,mode,...)
		MultiCraftAddon.smithing.SetMode(self,mode,...)
		zo_callLater(function() MultiCraftAddon.ResetSlider(mode) end,1)
	end
	
	-- done by EVENT_CRAFTING_STATION_INTERACT
	
	-- For polymorphism
	MultiCraftAddon.smithing.GetMode = function()
		return SMITHING.mode
	end
	
	-- Pattern selection in creation
	MultiCraftAddon.smithing.OnSelectedPatternChanged = SMITHING.OnSelectedPatternChanged
	SMITHING.OnSelectedPatternChanged = function(...)
		MultiCraftAddon.smithing.OnSelectedPatternChanged(...)
		-- preserve current slider value (if in range)
		MultiCraftAddon.ResetSlider(false)
	end
	
	-- Item selection in deconstruction
	MultiCraftAddon.smithing.OnExtractionSlotChanged = SMITHING.OnExtractionSlotChanged
	SMITHING.OnExtractionSlotChanged = function(...)
		MultiCraftAddon.smithing.OnExtractionSlotChanged(...)
		MultiCraftAddon.ResetSlider()
	end
		
	-- Create function
	MultiCraftAddon.smithing.Create = function()
		SMITHING.creationPanel:Create()
	end
			
	-- Wrapper to check if an item is craftable
	MultiCraftAddon.smithing.IsCraftable = function()
		return SMITHING.creationPanel:IsCraftable()
	end
		
	-- Deconstruction extract function
	MultiCraftAddon.smithing.Deconstruct = function()
		SMITHING.deconstructionPanel:Extract()
	end
	
	-- Wrapper to check if an item is deconstructable
	MultiCraftAddon.smithing.IsDeconstructable = function()
		return SMITHING.deconstructionPanel:IsExtractable()
	end
	
	-- Refinement extract function
	MultiCraftAddon.smithing.Extract = function()
		SMITHING.refinementPanel:Extract()
	end
	
	-- Wrapper to check if an item is refinable
	MultiCraftAddon.smithing.IsExtractable = function()
		return SMITHING.refinementPanel:IsExtractable()
	end
	
	-- Wrapper to get the keybind descriptor for the craft button
	MultiCraftAddon.smithing.GetSecondaryKeybindStripDescriptor = function()
		return SMITHING.keybindStripDescriptor[2]
	end

end

local function CommandHandler(text)
	local input = string.lower(text)
	local cmd = {}
	local index = 1

	if input ~= nil then
		for value in string.gmatch(input,"%w+") do  
			  cmd[index] = value
				index = index + 1
			end
		end

	if cmd[1] == 'toggle' then
		MultiCraftAddon.ToggleSliderDefault()
		MultiCraftAddon.ResetSlider()
	elseif cmd[1] == "trait" then
		MultiCraftAddon.ToggleTraits()
		MultiCraftAddon.ResetSlider()
	elseif cmd[1] == "delay" then
		if tonumber(cmd[2]) ~= nil then
			MultiCraftAddon.SetCallDelay(zo_floor(tonumber(cmd[2])))
		end
		d(string.format(SI.get(SI.CALL_DELAY), MultiCraftAddon.settings.callDelay))
	else
		d(SI.get(SI.USAGE_1))
		d(SI.get(SI.USAGE_2))
		d(SI.get(SI.USAGE_3))
		d(SI.get(SI.USAGE_4))
	end
end

function MultiCraftAddon.ToggleSliderDefault()
	MultiCraftAddon.settings.sliderDefault = not MultiCraftAddon.settings.sliderDefault
	
	if MultiCraftAddon.settings.sliderDefault then
		d(SI.get(SI.DEFAULT_MAX))
	else
		d(SI.get(SI.DEFAULT_MIN))
	end
end

function MultiCraftAddon.ToggleTraits()
	MultiCraftAddon.settings.traitsEnabled = not MultiCraftAddon.settings.traitsEnabled
	
	if MultiCraftAddon.settings.traitsEnabled then
		d(SI.get(SI.TRAITS_ON))
	else
		d(SI.get(SI.TRAITS_OFF))
	end
end

function MultiCraftAddon.SetCallDelay(number)
	MultiCraftAddon.settings.callDelay = number
end

-- Register Slash commands
SLASH_COMMANDS["/mc"] = CommandHandler
SLASH_COMMANDS["/multicraft"] = CommandHandler

-- Initialize Addon
EVENT_MANAGER:RegisterForEvent(MultiCraftAddon.name,	EVENT_ADD_ON_LOADED,					MultiCraftAddon.onAddonLoaded)

-- Register events
-- Show UI and set it if needed (slider, #number of crafts)
EVENT_MANAGER:RegisterForEvent(MultiCraftAddon.name,	EVENT_CRAFTING_STATION_INTERACT, 		MultiCraftAddon.SelectCraftingSkill) -- -> done by SetMode
-- Hide UI while crafting
EVENT_MANAGER:RegisterForEvent(MultiCraftAddon.name,	EVENT_CRAFT_STARTED, 					MultiCraftAddon.HideUI)
-- Restore UID when leaving craft station
EVENT_MANAGER:RegisterForEvent(MultiCraftAddon.name,	EVENT_END_CRAFTING_STATION_INTERACT,	MultiCraftAddon.Cleanup)
