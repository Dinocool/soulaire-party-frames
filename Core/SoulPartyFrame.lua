SoulPartyFrameMixin = {}

function SoulPartyFrameMixin:OnLoad()
	_G["SoulPartyFrame"] = self
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("GROUP_JOINED")
	self:RegisterEvent("GROUP_FORMED")
	self:RegisterEvent("GROUP_LEFT")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("CINEMATIC_START")
	self:RegisterEvent("CINEMATIC_STOP")
	self:RegisterEvent("PLAY_MOVIE")
	self:RegisterEvent("STOP_MOVIE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end



local function InitializeUnit(header, frameName)
	local frame = _G[frameName]

	frame:RegisterForClicks("AnyUp")
	if not frame.unitFrame then
		frame.unitFrame= CreateFrame("Frame", nil, frame, "SoulPartyMemberFrameTemplate")
	end
	frame.unitFrame:SetAllPoints(frame)
	frame.unitFrame:Initialize()
end

function SoulPartyFrameMixin:CreateHeader()

	local type = "party"
	local headerFrame = CreateFrame("Frame", "SUFHeader" .. type, nil, "ResizeLayoutFrame, SecureGroupHeaderTemplate")
	headerFrame:SetParent(self)
	headerFrame:SetAttribute("template","SecureUnitButtonTemplate")
	headerFrame:SetAttribute("showParty",true)
	headerFrame:SetAttribute("showRaid",false)
	headerFrame:SetAttribute("showSolo",false)
	headerFrame:SetAttribute("groupBy","ROLE")
	headerFrame:SetAttribute("groupingOrder","1,2,3,4,5,6,7,8")
	headerFrame:SetClampedToScreen(true)
	headerFrame.initialConfigFunction = InitializeUnit

	local secureInitializeUnit = [[
	local header = self:GetParent()

	self:SetAttribute("*type1", "target")
	self:SetAttribute("*type2", "togglemenu")
	self:SetAttribute("type2", "togglemenu")

	self:SetWidth("232")
	self:SetHeight("100")

	header:CallMethod("initialConfigFunction", self:GetName())
]]

	headerFrame:SetAttribute("initialConfigFunction",secureInitializeUnit)
	--headerFrame:ClearAllPoints()
	--headerFrame:SetPoint("TOPLEFT",self,"TOPLEFT")
	headerFrame:Show()
	self.headerFrame = headerFrame
end

function SoulPartyFrameMixin:StopDrag()
	self.headerFrame:StopMovingOrSizing()
	if SPF_DB then
		local point, _, relativePoint, x, y = self.headerFrame:GetPoint()
		SPF_DB.party_point = point
		SPF_DB.party_relative_point = relativePoint
		SPF_DB.party_position_x = x
		SPF_DB.party_position_y = y
	end
end

function SoulPartyFrame_UpdateSettingFrameSize()
	
	if not SoulPartyFrame.headerFrame then return end;
	local scale = 1
	if SPF_DB then
		scale = SPF_DB.party_scale
	end
	SoulPartyFrame:SetScale(scale)
end

function SoulPartyFrame_UpdateSettingFramePoint()
	
	if not SoulPartyFrame.headerFrame then return end;
	local point = "TOPLEFT"
	local relativePoint = "TOPLEFT"
	local x = 0
	local y = 0
	if SPF_DB then
		point = SPF_DB.party_point;
		relativePoint = SPF_DB.party_relative_point;
		x = math.floor(SPF_DB.party_position_x)
		y = math.floor(SPF_DB.party_position_y)
	end
	SoulPartyFrame.headerFrame:ClearAllPoints()
	SoulPartyFrame.headerFrame:SetPoint(point, UIParent, relativePoint, x, y)
end

function SoulPartyFrameMixin:OnShow()
	self:CreateHeader()
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
	if not IsInGroup() or IsInRaid() then
		self:QueueHide()
	else
		if not self.headerFrame:IsVisible() then
			if not InCombatLockdown() and not IsInCinematicScene() and not InCinematic() then
				self:QueueShow()
				self.headerFrame:SetAttribute("forceUpdate",time())
			end
		end
	end
end

function SoulPartyFrameMixin:QueueHide()
	if not InCombatLockdown() then
		self:Hide()
		self:SetAlpha(1.0)
	else
		self:SetAlpha(0.0)
		self.queueHide=true
	end
end

function SoulPartyFrameMixin:QueueShow()
	if not InCombatLockdown() then
		self:Show()
	else
		self.queueShow=true
	end
end

function SoulPartyFrameMixin:OnEvent(event, ...)
	if event == "PLAYER_TALENT_UPDATE" then
		self.dispels = SOUL_GetClassDispels("player")
		SPF:ChangeRole()
	elseif event == "CINEMATIC_START" or event == "PLAY_MOVIE" then
		self:QueueHide()
	elseif event == "CINEMATIC_STOP" or event == "STOP_MOVIE" then
		self:QueueShow()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if self.queueShow then 
			self:SetAlpha(1.0)
			self.headerFrame:Show()
			self.queueShow=false
		end
		if self.queueHide then 
			self.headerFrame:Hide()
			self.queueHide=false
		end
	else
		self:CheckIfParty()
	end
end

function SoulPartyFrameMixin:LoadSettings()
	
	self.headerFrame:SetAttribute("showPlayer",SPF_DB.show_player_frame)

	if SPF_DB.party_layout == "HORIZONTAL" then
		self.headerFrame:SetAttributeNoHandler("point","LEFT")
		for i = 1, (MAX_PARTY_MEMBERS + 1) do
			if not self.headerFrame[i] then return end
			local memberFrame = self.headerFrame[i]
			memberFrame:ClearPoint("TOP")
		end
	else
		self.headerFrame:SetAttributeNoHandler("point","TOP")
		for i = 1, (MAX_PARTY_MEMBERS + 1) do
			if not self.headerFrame[i] then return end
			local memberFrame = self.headerFrame[i]
			memberFrame:ClearPoint("LEFT")
		end
	end
end

function SoulPartyFrameMixin:UpdateLayout()
	if not self.headerFrame then return end
	
	self:LoadSettings()
	
	self.headerFrame:SetAttribute("forceUpdate",time())

	for i = 1, (MAX_PARTY_MEMBERS + 1) do
		if not self.headerFrame[i] or not self.headerFrame[i].unitFrame then return end
		local memberFrame = self.headerFrame[i].unitFrame
		memberFrame:UpdateAuraAnchors()
	end
end

function SoulPartyFrameMixin:UpdateMemberFrames()
	for i = 1, (MAX_PARTY_MEMBERS + 1) do
		if not self.headerFrame[i] or not self.headerFrame[i].unitFrame then return end
		local memberFrame = self.headerFrame[i].unitFrame
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

function SoulPartyFrameMixin:Unlock()
	local frame = self.headerFrame

	if not frame then return end;
	
	frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:EnableMouse(true)
    frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function()
		self:StopDrag()
	end)

	for i = 1, (MAX_PARTY_MEMBERS + 1) do
		local memberFrame = frame[i]
		if not memberFrame then return end
		memberFrame:EnableMouse(false)
	end
end

function SoulPartyFrameMixin:Lock()
	local frame = self.headerFrame

	if not frame then return end;

	frame:SetMovable(false)
    frame:EnableMouse(false)
	
	for i = 1, (MAX_PARTY_MEMBERS + 1) do
		local memberFrame = frame[i]
		if not memberFrame then return end
		memberFrame:EnableMouse(true)
	end
end


function SoulPartyFrame_IsLocked()
	return not SoulPartyFrame.headerFrame:IsMovable()
end

function SoulPartyFrame_IsUnlocked()
	return SoulPartyFrame.headerFrame:IsMovable()
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