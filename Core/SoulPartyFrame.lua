SoulPartyFrameMixin = {}

function SoulPartyFrameMixin:OnLoad()
	_G["SoulPartyFrame"] = self
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
    self:RegisterForDrag("LeftButton")
    self:EnableMouse(true)
    self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", function()
		self:StopDrag()
	end)

    SoulPartyFrame_Lock()
end

function SoulPartyFrameMixin:StopDrag()
	self:StopMovingOrSizing()
	if SPF_DB then
		local point, _, relativePoint, x, y = self:GetPoint()
		SPF_DB.party_point = point
		SPF_DB.party_relative_point = relativePoint
		SPF_DB.party_position_x = x
		SPF_DB.party_position_y = y
	end
end

function SoulPartyFrame_UpdateSettingFrameSize()
	local scale = 1
	if SPF_DB then
		scale = SPF_DB.party_scale
	end
	SoulPartyFrame:SetScale(scale)
end

function SoulPartyFrame_UpdateSettingFramePoint()
	local point = "TOPLEFT"
	local relativePoint = "TOPLEFT"
	local x = 0
	local y = 0
	if SPF_DB then
		point = SPF_DB.party_point
		relativePoint = SPF_DB.party_relative_point
		x = math.floor(SPF_DB.party_position_x)
		y = math.floor(SPF_DB.party_position_y)
	end
	SoulPartyFrame:ClearAllPoints()
	SoulPartyFrame:SetPoint(point, UIParent, relativePoint, x, y)
end

function SoulPartyFrameMixin:OnShow()
	--Load settings from profile
	self:LoadSettings()

	--Populate what dispells our player knows
	self.dispels=SOUL_GetClassDispels("player")
	
	--Insert Into omnicd
	if OmniCD and not self.injectedIntoOmni then
		table.insert(OmniCD[1].unitFrameData,{ [1] = "SoulairePartyFrames",[2] = "SoulPartyFrame",[3] = "unit",})
		self.injectedIntoOmni=true
	end

	--Setup damage prediction
	if SPF_DB.show_damage_prediction then
		self.DamagePrediction = CreateFrame("Frame","DamagePrediction")
		self.DamagePrediction = Mixin(self.DamagePrediction,IncomingDamagePredictMixin)
		self.DamagePrediction:Initialize()
	end
end

function SoulPartyFrameMixin:CheckIfParty()

	local count = GetNumGroupMembers()
	if count == 0 then
		count = GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE)-1;
	end
	if (count > 5 or count <=1) then
		if not InCombatLockdown() then
			self:Hide()
		end
	else
		if not self:IsVisible() then
			if not InCombatLockdown() then
				self:Show()
				self:SetAttribute("forceUpdate",time())
			end
		end
	end
end

function SoulPartyFrameMixin:OnEvent(event, ...)
	if event == "PLAYER_TALENT_UPDATE" then
		self.dispels = SOUL_GetClassDispels("player")
		SPF:ChangeRole()
	elseif event == "GROUP_ROSTER_UPDATE" then
		self:CheckIfParty()
	end
end

function SoulPartyFrameMixin:LoadSettings()
	

	self:SetAttributeNoHandler("showPlayer",SPF_DB.show_player_frame)

	if SPF_DB.party_layout == "HORIZONTAL" then
		self:SetAttributeNoHandler("point","LEFT")
		for i = 1, (MAX_PARTY_MEMBERS + 1) do
			local memberFrame = self[i]
			if not memberFrame then return end
			memberFrame:ClearPoint("TOP")
		end
	else
		self:SetAttributeNoHandler("point","TOP")
		for i = 1, (MAX_PARTY_MEMBERS + 1) do
			local memberFrame = self[i]
			if not memberFrame then return end
			memberFrame:ClearPoint("LEFT")
		end
	end
end

function SoulPartyFrameMixin:UpdateLayout()
	self:LoadSettings()
	
	self:SetAttribute("forceUpdate",time())

	for i = 1, (MAX_PARTY_MEMBERS + 1) do
		local memberFrame = self[i]
		if not memberFrame then return end
		memberFrame:UpdateAuraAnchors()
	end
end

function SoulPartyFrameMixin:UpdateMemberFrames()
	for i = 1, (MAX_PARTY_MEMBERS + 1) do
		local memberFrame = self[i]
		if not memberFrame then return end
		memberFrame:UpdateMember()
	end
end

function SoulPartyFrameMixin:GetLayout()
	if SPF_DB.party_layout == "VERTICAL" then
		return self.VerticalLayout
	else
		return self.HorizontalLayout
	end
end

function SoulPartyFrame_Unlock()
	SoulPartyFrame:SetMovable(true)
    SoulPartyFrame:EnableMouse(true)
	SoulPartyFrame.Background:Show();

	for i = 1, (MAX_PARTY_MEMBERS + 1) do
		local memberFrame = SoulPartyFrame[i]
		if not memberFrame then return end
		memberFrame:EnableMouse(false)
	end
end

function SoulPartyFrame_Lock()
	SoulPartyFrame:SetMovable(false)
    SoulPartyFrame:EnableMouse(false)
	SoulPartyFrame.Background:Hide();
	for i = 1, (MAX_PARTY_MEMBERS + 1) do
		local memberFrame = SoulPartyFrame[i]
		if not memberFrame then return end
		memberFrame:EnableMouse(true)
	end
end

function SoulPartyFrame_IsLocked()
	return not SoulPartyFrame:IsMovable()
end

function SoulPartyFrame_IsUnlocked()
	return SoulPartyFrame:IsMovable()
end

function SOUL_GetClassDispels(unit)
    local _, class = UnitClass(unit)
    local spec = GetSpecialization()
    local dispels = {
        ["curse"] = {},
        ["disease"] = {},
        ["poison"] = {},
        ["magic"] = {},
    }
    if not (spec and class) then return dispels end
    
    if (class == "PALADIN") then
        if IsSpellKnownOrOverridesKnown(213644) then -- Cleanse Toxins
            dispels["poison"][213644]=true -- Cleanse Toxins
            dispels["disease"][213644]=true -- Cleanse Toxins
        end
        if IsSpellKnownOrOverridesKnown(4987) then 
            dispels["magic"][4987]=true -- Cleanse
            if IsPlayerSpell(393024) then -- Improved Cleanse
                dispels["poison"][4987]=true -- Cleanse
                dispels["disease"][4987]=true -- Cleanse
            end
        end
    elseif (class == "PRIEST") then
        if IsSpellKnownOrOverridesKnown(213634) then
            dispels["disease"][213634] = true -- Purify Disease
        end
        
        if IsSpellKnownOrOverridesKnown(527) then
            dispels["magic"][527] = true -- Purify
            if IsPlayerSpell(390632) then -- Improved Purify
                dispels["disease"][527] = true -- Purify
            end
        end
        
        if IsSpellKnownOrOverridesKnown(32375) then
            dispels["magic"][32375] = true -- Mass Dispel
        end
    elseif (class == "SHAMAN") then
        if IsSpellKnownOrOverridesKnown(51886) then
            dispels["curse"][51886] = true -- Cleanse Spirit
        end
        
        if IsSpellKnownOrOverridesKnown(77130) then
            dispels["magic"][77130] = true -- Purify Spirit
            if IsPlayerSpell(383016) then -- Improved Purify Spirit
                dispels["curse"][77130] = true -- Purify Spirit
            end
        end
    elseif (class == "MAGE") then
        if IsSpellKnownOrOverridesKnown(475) then
            dispels["curse"][475] = true -- Remove Curse
        end
    elseif (class == "MONK") then
        if IsSpellKnownOrOverridesKnown(218164) then 
            dispels["poison"][218164] = true -- Detox
            dispels["disease"][218164] = true -- Detox
        end
        
        if IsSpellKnownOrOverridesKnown(115450) then
            dispels["magic"][115450] = true -- Detox
            if IsPlayerSpell(388874) then -- Improved Detox
                dispels["poison"][115450] = true -- Detox
                dispels["disease"][115450] = true -- Detox
            end
        end
    elseif (class == "DRUID") then
        if IsSpellKnownOrOverridesKnown(2782) then        
            dispels["curse"][2782] = true -- Remove Corruption
            dispels["poison"][2782] = true -- Remove Corruption
        end
        
        if IsSpellKnownOrOverridesKnown(88423) then
            dispels["magic"][88423] = true -- Nature's Cure
            if IsPlayerSpell(392378) then -- Improved Nature's Cure
                dispels["curse"][88423] = true -- Nature's Cure
                dispels["poison"][88423] = true -- Nature's Cure
            end
        end
    elseif (class == "EVOKER") then
        if IsSpellKnownOrOverridesKnown(365585) then        
            dispels["poison"][365585] = true -- Expunge
            if IsPlayerSpell(360823) then -- Naturalize
                dispels["magic"][365585] = true -- Expunge
            end
        end
        
        if IsSpellKnownOrOverridesKnown(374251) then        
            dispels["curse"][374251] = true -- Cauterizing Flame
            dispels["poison"][374251] = true -- Cauterizing Flame
            dispels["disease"][374251] = true -- Cauterizing Flame
        end
    end
    return dispels
end