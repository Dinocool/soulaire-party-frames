SoulPartyFrameMixin = {}

function SoulPartyFrameMixin:OnLoad()
    local function PartyMemberFrameReset(framePool, frame)
		frame.layoutIndex = nil
		FramePool_HideAndClearAnchors(framePool, frame)
	end

    self.PartyMemberFramePool = CreateFramePool("BUTTON", self, "SoulPartyMemberFrameTemplate", PartyMemberFrameReset)
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
    self:RegisterForDrag("LeftButton")
    self:EnableMouse(true)
    self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		if SPF_DB then
			local point, _, relativePoint, x, y = self:GetPoint()
			SPF_DB.party_point = point
			SPF_DB.party_relative_point = relativePoint
			SPF_DB.party_position_x = x
			SPF_DB.party_position_y = y
		end
	end)

    SoulPartyFrame_Lock()
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
	self:InitializePartyMemberFrames()
	self:UpdatePartyFrames()

	
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
function SoulPartyFrameMixin:OnEvent(event, ...)
	if event == "PLAYER_TALENT_UPDATE" then
		self.dispels = SOUL_GetClassDispels("player")
	else
		self:UpdatePartyFrames()
		self:Layout()
	end
end

function SoulPartyFrameMixin:ShouldShow()
	return ShouldShowPartyFrames()
end

function SoulPartyFrameMixin:InitializePartyMemberFrames()
	local memberFramesToSetup = {}

	self.PartyMemberFramePool:ReleaseAll()
	for i = 1, MAX_PARTY_MEMBERS do
		local memberFrame = self.PartyMemberFramePool:Acquire()

		-- Set for debugging purposes.
		memberFrame:SetParentKey("MemberFrame"..i)
		_G["SoulPartyFrame"..i] = memberFrame

		memberFrame:SetAttribute("unit", "party"..i)
		memberFrame:RegisterForClicks("AnyUp")
		memberFrame:SetAttribute("*type1", "target") -- Target unit on left click
		memberFrame:SetAttribute("*type2", "togglemenu") -- Toggle units menu on left click
		memberFrame:SetAttribute("*type3", "assist") -- On middle click, target the target of the clicked unit

		memberFrame:SetPoint("TOPLEFT")
		memberFrame.layoutIndex = i
		memberFramesToSetup[i] = memberFrame
		memberFrame:SetShown(self:ShouldShow())
	end
	for _, frame in ipairs(memberFramesToSetup) do
		frame:Setup()
	end
    
	self:UpdatePaddingAndLayout()
end

function SoulPartyFrameMixin:UpdateMemberFrames()
	for memberFrame in self.PartyMemberFramePool:EnumerateActive() do
		memberFrame:UpdateMember()
	end

	self:Layout()
end

function SoulPartyFrameMixin:HidePartyFrames()
	for memberFrame in self.PartyMemberFramePool:EnumerateActive() do
		memberFrame:Hide()
	end
end

function SoulPartyFrameMixin:UpdatePaddingAndLayout()
	self.leftPadding = 10
	self.rightPadding = 10
    self.topPadding = 10
    self.bottomPadding = 10

	self:Layout()
end

function SoulPartyFrameMixin:UpdatePartyFrames()
	local showPartyFrames = self:ShouldShow()
	for memberFrame in self.PartyMemberFramePool:EnumerateActive() do
		if showPartyFrames then
			memberFrame:UpdateMember()
		else
			memberFrame:Hide()
		end
	end

	self:UpdatePaddingAndLayout()
end

function SoulPartyFrame_Unlock()
	SoulPartyFrame:SetMovable(true)
    SoulPartyFrame:EnableMouse(true)
	SoulPartyFrame.Background:Show();
	for i=1, MAX_PARTY_MEMBERS do
		local PartyMemberFrame = SoulPartyFrame["MemberFrame" .. i]
		if PartyMemberFrame then
			PartyMemberFrame:EnableMouse(false)
		end
	end
end

function SoulPartyFrame_Lock()
	SoulPartyFrame:SetMovable(false)
    SoulPartyFrame:EnableMouse(false)
	SoulPartyFrame.Background:Hide();
	for i=1, MAX_PARTY_MEMBERS do
		local PartyMemberFrame = SoulPartyFrame["MemberFrame" .. i]
		if PartyMemberFrame then
			PartyMemberFrame:EnableMouse(true)
		end
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