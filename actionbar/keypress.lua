

	local bongos = IsAddOnLoaded'Bongos_ActionBar'
	local orig 	 = {}
	local time   = nil

	orig.ActionButton_OnUpdate      = ActionButton_OnUpdate
	orig.PetActionBarFrame_OnUpdate = PetActionBarFrame_OnUpdate
	orig.ShapeshiftBar_UpdateState  = ShapeshiftBar_UpdateState

	local borders = function(nutime)
		if this:GetChecked() then this.checked = true modSkinColor(this, 1, 175/255, 155/255) end
		if this.keypress and modSkinned(this) then
			local i = nutime - this.keypress
			modSkinColor(this, .075/i, .05/i, .025/i)
		end
		if this.checked and not this:GetChecked() then
			modSkinColor(this, .2, .2, .2)
			this.checked = nil
		end
		if this.keypress and nutime > (this.keypress + .4) then
			modSkinColor(this, .2, .2, .2)
			this.keypress = nil
		end
	end

	local pet_borders = function()
		for i = 1, 10 do
			local bu = _G['PetActionButton'..i]
			local _, _, _, _, active = GetPetActionInfo(i)
			if active then
				modSkinColor(bu, 1, 175/255, 155/255)
			else
				modSkinColor(bu, .2, .2, .2)
			end
		end
	end

	function ActionButton_OnUpdate(elapsed)
		orig.ActionButton_OnUpdate(elapsed)
		local nutime = GetTime()
		borders(nutime)
	end

	function PetActionBarFrame_OnUpdate(elapsed)
		orig.PetActionBarFrame_OnUpdate(elapsed)
		pet_borders()
	end

	function ShapeshiftBar_UpdateState()
		orig.ShapeshiftBar_UpdateState()
		local numForms = GetNumShapeshiftForms()
		for i = 1, NUM_SHAPESHIFT_SLOTS do
			local _, _, active = GetShapeshiftFormInfo(i)
			local bu = _G['ShapeshiftButton'..i]
			if active then
				modSkinColor(bu, 1, 175/255, 155/255)
			else
				modSkinColor(bu, .2, .2, .2)
			end
		end
	end

	function ActionButtonDown(i)
		local time = GetTime()
		if not bongos then
			if BonusActionBarFrame:IsShown() then
				local bu = _G['BonusActionButton'..i]
				if  bu:GetButtonState() == 'NORMAL' then
					bu:SetButtonState'PUSHED'
					UseAction(ActionButton_GetPagedID(bu), 0)
					bu.keypress = time
				end
				return
			end
			local bu = _G['ActionButton'..i]
			if  bu:GetButtonState() == 'NORMAL' then
				bu:SetButtonState'PUSHED'
				UseAction(ActionButton_GetPagedID(bu), 0)
				bu.keypress = time
			end
		else
			local bu = _G['BActionButton'..i]
			local id = BActionButton.GetPagedID(i)
			if bu and bu:GetButtonState() == 'NORMAL' then bu:SetButtonState'PUSHED' end
			UseAction(id, 0)
			bu.keypress = time
		end
	end

	function ActionButtonUp(i, onSelf)
		if not bongos then
			if BonusActionBarFrame:IsShown() then
				local bu = _G['BonusActionButton'..i]
				if  bu:GetButtonState() == 'PUSHED' then
					bu:SetButtonState'NORMAL'
					if MacroFrame_SaveMacro then MacroFrame_SaveMacro() end
					if IsCurrentAction(ActionButton_GetPagedID(bu)) then bu:SetChecked(1)
					else bu:SetChecked(0) end
				end
				return
			end

			local bu = _G['ActionButton'..i]
			if bu and bu:GetButtonState() == 'PUSHED' then
				bu:SetButtonState'NORMAL'
				if MacroFrame_SaveMacro then MacroFrame_SaveMacro() end
				if IsCurrentAction(ActionButton_GetPagedID(bu)) then bu:SetChecked(1)
				else bu:SetChecked(0)
				end
			end
		else
			local bu = _G['BActionButton'..i]
			if bu and bu:GetButtonState() == 'PUSHED' then
				bu:SetButtonState'NORMAL'
				if MacroFrame_SaveMacro then MacroFrame_SaveMacro() end
				bu:SetChecked(IsCurrentAction(BActionButton.GetPagedID(i)))
			end
		end
	end

	function MultiActionButtonDown(bar, i)
		local time = GetTime()
		local bu = _G[bar..'Button'..i]
		if  bu:GetButtonState() == 'NORMAL' then
			bu:SetButtonState'PUSHED'
			UseAction(ActionButton_GetPagedID(bu), 0)
			bu.keypress = time
		end
	end

	function MultiActionButtonUp(bar, i, onSelf)
		local bu = _G[bar..'Button'..i]
		if  bu:GetButtonState() == 'PUSHED' then
			bu:SetButtonState'NORMAL'
			if MacroFrame_SaveMacro then MacroFrame_SaveMacro() end
			if IsCurrentAction(ActionButton_GetPagedID(bu)) then bu:SetChecked(1)
			else bu:SetChecked(0)
			end
		end
	end

	--
