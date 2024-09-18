SoulPortraitMixin = {}

function SoulPortraitMixin:Initialize(unit)
    self.unit = unit
    self:SetScript("OnEvent", self.OnEvent)
    self:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE",unit)
    self:RegisterEvent("PORTRAITS_UPDATED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")

    
    --[[
    local r,g,b = 0,0,0.1;
    --3D Portrait testing...

    self.mask = self:CreateMaskTexture()
    self.mask:SetPoint("TOPLEFT",-0,-0)
    self.mask:SetSize(60,60)
    self.mask:SetTexture("Interface\\AddOns\\SoulairePartyFrames\\Portrait-Mask")
    self.Portrait:AddMaskTexture(self.mask)
    self.Portrait:SetColorTexture(r,g,b)

    --self.Portrait:Hide()

    self.modelLayer = CreateFrame("PlayerModel",nil,self)
    local inset = 8
    self.modelLayer:SetPoint("TOPLEFT",self,"TOPLEFT",inset,-inset)
    self.modelLayer:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT",-inset,inset)
    self.modelLayer:SetFrameLevel(0)
    self.modelLayer:SetModelDrawLayer("ARTWORK")
    self.modelLayer:SetViewInsets(-inset,-inset,-inset,-inset)
    self.modelLayer:SetSize(60,60)
    self.modelLayer:SetUnit(unit)
    self.modelLayer:SetAnimation(804)
    self.modelLayer:SetRotation(0)
    self.modelLayer:SetPortraitZoom(1.00)

    
    self.background = self.modelLayer:CreateTexture()
    self.background:SetPoint("TOPLEFT",self,-0,-0)
    self.background:SetSize(60,60)
    self.background:SetColorTexture(r,g,b)
    self.background:SetDrawLayer("BACKGROUND",7)
    self.background:AddMaskTexture(self.PortraitMask)
    ]]--
    

    --Setup extra portrait details

        local ccTexture = self:CreateTexture(nil, "OVERLAY")
        ccTexture:SetHeight(60)
        ccTexture:SetWidth(62)
        self.ccTexture = ccTexture
        
        ccTexture:SetPoint ("topleft", self, "topleft", 0, 0)
        
        local ccCooldown= CreateFrame("Cooldown", nil,  self)
        ccCooldown:SetSwipeTexture("interface/hud/uiunitframeplayerportraitmask2x")
        ccCooldown:SetSwipeColor(0, 0, 0, 0.5)
        ccCooldown:SetSize(60, 60)
        
        ccCooldown:SetPoint ("topleft", self, "topleft", 0, 0)
        --ccCooldown:SetPoint ("bottomright", self, "bottomleft", 48, -16)
        local ccTimer = ccCooldown:GetRegions()
        ccTimer:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
        self.ccCooldown = ccCooldown
        --ccCooldown.SwipeTexture:AddMaskTexture(self.PortraitMask)
        ccTexture:AddMaskTexture(self.PortraitMask)
end

function SoulPortraitMixin:Update()
    SetPortraitTexture(self.Portrait, self.unit,true);
end

function SoulPortraitMixin:OnEvent(event, ...)
    if not SOUL_ShouldUpdate(self) then return end
    local arg1 = ...;
    if ( event == "CVAR_UPDATE" ) then
	elseif ( event == "VARIABLES_LOADED" ) then
		self:UnregisterEvent("VARIABLES_LOADED")
    elseif SOUL_ShouldUpdate(self) then
        if ( event == "UNIT_CONNECTION" and arg1==self.unit) then
            self:Update()
        else
            self:Update()
        end
    end
end

function SoulPortraitMixin:UpdateCCAura(spellID, expirationTime, duration)
    local hasCC = spellID and expirationTime
    if hasCC then
        self.ccCooldown:SetCooldown(expirationTime - duration, duration)
        if spellID ~= nil then
            local icon = select(1, C_Spell.GetSpellInfo(spellID))
            if icon then
                self.ccTexture:SetTexture(icon["iconID"])
            end
        end
        self.ccTexture:Show()
    else
        self.ccTexture:Hide()
    end
end