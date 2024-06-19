SoulPartyFrameMixin = {}

function SoulPartyFrameMixin:OnLoad()
    local function PartyMemberFrameReset(framePool, frame)
		frame.layoutIndex = nil
		FramePool_HideAndClearAnchors(framePool, frame)
	end

    self.PartyMemberFramePool = CreateFramePool("BUTTON", self, "SoulPartyMemberFrameTemplate", PartyMemberFrameReset)

	self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterForDrag("LeftButton")
    self:EnableMouse(true)
    self:SetScript("OnDragStart", self.StartMoving)
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

    --if not SPF:IsHooked("UnitFrameHealPredictionBars_Update") then
    --    SPF:SecureHook("UnitFrameHealPredictionBars_Update",UpdateHealPrediction)
    --end

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
	--Insert Into omnicd
	if OmniCD and not self.injectedIntoOmni then
		table.insert(OmniCD[1].unitFrameData,{ [1] = "SoulPartyFrames",[2] = "SoulPartyFrame",[3] = "unit",})
		self.injectedIntoOmni=true
	end
end

function SoulPartyFrameMixin:OnEvent(event, ...)
	self:Layout()
end

function SoulPartyFrameMixin:ShouldShow()
	return ShouldShowPartyFrames()
end

function SoulPartyFrameMixin:InitializePartyMemberFrames()
	local memberFramesToSetup = {}

	self:SetScript("OnEvent", function(self, event, ...)
		self:UpdatePartyFrames()
	end)

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
	for i=1, MAX_PARTY_MEMBERS do
		local PartyMemberFrame = SoulPartyFrame["MemberFrame" .. i]
		if PartyMemberFrame then
			PartyMemberFrame:SetMovable(true)
		end
	end
end

function SoulPartyFrame_Lock()
	SoulPartyFrame:SetMovable(false)
    SoulPartyFrame:EnableMouse(false)
	for i=1, MAX_PARTY_MEMBERS do
		local PartyMemberFrame = SoulPartyFrame["MemberFrame" .. i]
		if PartyMemberFrame then
			PartyMemberFrame:SetMovable(false)
		end
	end
end

function SoulPartyFrame_IsLocked()
	return not SoulPartyFrame:IsMovable()
end

function SoulPartyFrame_IsUnlocked()
	return SoulPartyFrame:IsMovable()
end