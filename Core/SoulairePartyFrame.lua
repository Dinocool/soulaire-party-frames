SoulairePartyFrameMixin = {}

function SoulairePartyFrameMixin:OnLoad()
    local function PartyMemberFrameReset(framePool, frame)
		frame.layoutIndex = nil
		FramePool_HideAndClearAnchors(framePool, frame)
	end

    self.PartyMemberFramePool = CreateFramePool("BUTTON", self, "SoulairePartyMemberFrameTemplate", PartyMemberFrameReset)

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

    if not SPF:IsHooked("UnitFrameHealPredictionBars_Update") then
        SPF:SecureHook("UnitFrameHealPredictionBars_Update",UpdateHealPrediction)
    end

    SoulairePartyFrame_Lock()
end

function SoulairePartyFrame_UpdateSettingFrameSize()
	local scale = 1
	if SPF_DB then
		scale = SPF_DB.party_scale
	end
	SoulairePartyFrame:SetScale(scale)
end

function SoulairePartyFrame_UpdateSettingFramePoint()
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
	SoulairePartyFrame:ClearAllPoints()
	SoulairePartyFrame:SetPoint(point, UIParent, relativePoint, x, y)
end

function SoulairePartyFrameMixin:OnShow()
	self:InitializePartyMemberFrames()
	self:UpdatePartyFrames()
	--Insert Into omnicd
	if OmniCD and not self.injectedIntoOmni then
		table.insert(OmniCD[1].unitFrameData,{ [1] = "SoulairePartyFrames",[2] = "SoulairePartyFrame",[3] = "unit",})
		self.injectedIntoOmni=true
	end
end

function SoulairePartyFrameMixin:OnEvent(event, ...)
	self:Layout()
end

function SoulairePartyFrameMixin:ShouldShow()
	return ShouldShowPartyFrames()
end

function SoulairePartyFrameMixin:InitializePartyMemberFrames()
	local memberFramesToSetup = {}

	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:SetScript("OnEvent", function(self, event, ...)
		self:UpdatePartyFrames()
	end)

	self.PartyMemberFramePool:ReleaseAll()
	for i = 1, MAX_PARTY_MEMBERS do
		local memberFrame = self.PartyMemberFramePool:Acquire()

		-- Set for debugging purposes.
		memberFrame:SetParentKey("MemberFrame"..i)
		_G["SoulairePartyFrame"..i] = memberFrame

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

function SoulairePartyFrameMixin:UpdateMemberFrames()
	for memberFrame in self.PartyMemberFramePool:EnumerateActive() do
		memberFrame:UpdateMember()
	end

	self:Layout()
end

function SoulairePartyFrameMixin:HidePartyFrames()
	for memberFrame in self.PartyMemberFramePool:EnumerateActive() do
		memberFrame:Hide()
	end
end

function SoulairePartyFrameMixin:UpdatePaddingAndLayout()
	self.leftPadding = 10
	self.rightPadding = 10
    self.topPadding = 10
    self.bottomPadding = 10

	self:Layout()
end

function SoulairePartyFrameMixin:UpdatePartyFrames()
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

function SoulairePartyFrame_Unlock()
	SoulairePartyFrame:SetMovable(true)
    SoulairePartyFrame:EnableMouse(true)
	for i=1, MAX_PARTY_MEMBERS do
		local PartyMemberFrame = SoulairePartyFrame["MemberFrame" .. i]
		if PartyMemberFrame then
			PartyMemberFrame:SetMovable(true)
		end
	end
end

function SoulairePartyFrame_Lock()
	SoulairePartyFrame:SetMovable(false)
    SoulairePartyFrame:EnableMouse(false)
	for i=1, MAX_PARTY_MEMBERS do
		local PartyMemberFrame = SoulairePartyFrame["MemberFrame" .. i]
		if PartyMemberFrame then
			PartyMemberFrame:SetMovable(false)
		end
	end
end

function SoulairePartyFrame_IsLocked()
	return not SoulairePartyFrame:IsMovable()
end

function SoulairePartyFrame_IsUnlocked()
	return SoulairePartyFrame:IsMovable()
end

function UpdateHealPrediction(frame)
    if not frame.soulaireFrame then return end
    
    local healthBar = frame.HealthBar;
    if not healthBar or healthBar:IsForbidden() then
        return
    end
    
    local absorbBar = frame.HealthBar.TotalAbsorbBar;
    if not absorbBar or absorbBar:IsForbidden() then
        return
    end
    
    local absorbOverlay = frame.HealthBar.TotalAbsorbBar.TiledFillOverlay;
    if not absorbOverlay or absorbOverlay:IsForbidden() then
        return
    end
    local _, maxHealth = healthBar:GetMinMaxValues();
    if maxHealth <= 0 then
        return
    end
    
    if not frame:GetUnit() then
        return
    end
    
    local totalAbsorb = UnitGetTotalAbsorbs(frame:GetUnit()) or 0;
    if totalAbsorb > maxHealth then
        totalAbsorb = maxHealth;
    end
    
    if totalAbsorb > 0 then -- show overlay when there's a positive absorb amount
        absorbOverlay:ClearAllPoints()
        
        local totalWidth, totalHeight = healthBar:GetSize();
        
        if absorbBar:IsShown() then -- If absorb bar is shown, attach absorb overlay to it; otherwise, attach to health bar.
            absorbOverlay:SetParent(absorbBar);
            
            local offset = 1-(healthBar.currValue/maxHealth)
            absorbOverlay:SetPoint("TOPRIGHT", absorbBar.FillMask, "TOPRIGHT", 0, 0);
            absorbOverlay:SetPoint("BOTTOMRIGHT", absorbBar.FillMask, "BOTTOMRIGHT", 0, 0);
            
            healthBar.OverAbsorbGlow:ClearAllPoints()
            healthBar.OverAbsorbGlow:SetPoint("TOPLEFT",healthBar.TotalAbsorbBar.TiledFillOverlay,"TOPRIGHT",-4, 7)
            healthBar.OverAbsorbGlow:SetPoint("BOTTOMRIGHT",healthBar.TotalAbsorbBar.TiledFillOverlay,"BOTTOMRIGHT",4, -7)  
        else
            absorbOverlay:SetParent(healthBar);
            absorbOverlay:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0);
            absorbOverlay:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0);
            
            healthBar.OverAbsorbGlow:ClearAllPoints()
            healthBar.OverAbsorbGlow:SetPoint("TOPLEFT",healthBar.TotalAbsorbBar.TiledFillOverlay,"TOPLEFT",-4, 7)
            healthBar.OverAbsorbGlow:SetPoint("BOTTOMRIGHT",healthBar.TotalAbsorbBar.TiledFillOverlay,"BOTTOMLEFT",4, -7)  
        end
        local barSize = totalAbsorb / maxHealth * totalWidth;
        
        absorbOverlay:Show();
        absorbOverlay:SetWidth(barSize)
        
        frame.overAbsorbGlow:Show();    --uncomment this if you want to ALWAYS show the glow to the left of the shield overlay
    else
        absorbOverlay:Hide();
    end
end