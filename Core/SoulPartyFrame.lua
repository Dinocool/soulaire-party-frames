SoulPartyFrameMixin = {}

function SoulPartyFrameMixin:OnLoad()
	_G["SoulPartyFrame"] = self
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
end

local EditModeLib = LibStub:GetLibrary("EditModeExpanded-1.0")
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local function InitializeUnit(header, frameName)
	local frame = _G[frameName]

	frame:RegisterForClicks("AnyUp")
	if not frame.unitFrame then
		frame.unitFrame= CreateFrame("Frame", nil, frame, "SoulPartyMemberFrameTemplate")
	end
	frame.unitFrame:SetAllPoints(frame)
	frame.unitFrame:Initialize()
end

local function LayoutValueChanged(self,layout,dropdown,checked)
	layout().value = self.value
	LibDD:UIDropDownMenu_SetText(dropdown, self.value)
	SoulPartyFrame:UpdateLayout()
end

function SoulPartyFrameMixin:CreateHeader()

	local type = "party"
	local headerFrame = CreateFrame("Frame", "SUFHeader" .. type, nil, "PingTopLevelPassThroughAttributeTemplate, ResizeLayoutFrame, SecureGroupHeaderTemplate")
	self.headerFrame = headerFrame

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
end

function SoulPartyFrameMixin:LoadProfile()
	if not self.headerFrame then return end
	--Do registration
	if not EditModeLib:IsRegistered(self.headerFrame) then
		EditModeLib:RegisterFrame(self.headerFrame, "Party Frames", SPF_DB.party.frame)
		EditModeLib:RegisterResizable(self.headerFrame)
		
		EditModeLib:RegisterCustomCheckbox(self.headerFrame,"Show Player",
		function ()
			SoulPartyFrame.showPlayer=true;
			self.headerFrame:SetAttribute("showPlayer",true)
		end,
		function ()
			SoulPartyFrame.showPlayer=false;
			self.headerFrame:SetAttribute("showPlayer",false)
		end)

		local dropdown,layout = EditModeLib:RegisterDropdown(self.headerFrame,LibDD,"layout")

		LibDD:UIDropDownMenu_Initialize(dropdown,
		function(frame,level,menuList)
			local info = LibDD:UIDropDownMenu_CreateInfo()
			info.text = "Horizontal"
			info.checked = layout().value=="Horizontal"
			info.func = LayoutValueChanged
			info.arg1=layout
			info.arg2 = dropdown
			LibDD:UIDropDownMenu_AddButton(info)
			info.text = "Vertical"
			info.checked = layout().value=="Vertical"
			LibDD:UIDropDownMenu_AddButton(info)
		end
	)

			
		LibDD:UIDropDownMenu_SetText(dropdown,layout().value)
		SoulPartyFrame.layout=layout

		if layout().value == "Horizontal" then
			self.headerFrame:SetAttribute("point","LEFT")
		else
			self.headerFrame:SetAttribute("point","TOP")
		end
	end
end

function SoulPartyFrameMixin:OnShow()
	self:CreateHeader()

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
		if not InCombatLockdown() then
			self.headerFrame:Hide()
		end
	else
		if not self:IsVisible() then
			if not InCombatLockdown() then
				self.headerFrame:Show()
				self.headerFrame:SetAttribute("forceUpdate",time())
			end
		end
	end
end

function SoulPartyFrameMixin:OnEvent(event, ...)
	if event == "PLAYER_TALENT_UPDATE" then
		self.dispels = SOUL_GetClassDispels("player")
		--SPF:ChangeRole()
		--Reload our profile if it's already been loaded
		if self.headerFrame then
        	--self:LoadProfile()
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		self:CheckIfParty()
	end
end

function SoulPartyFrameMixin:UpdateLayout()
	if self.layout().value == "Horizontal" then
		for i = 1, (MAX_PARTY_MEMBERS + 1) do
			if not self.headerFrame[i] then break end
			local memberFrame = self.headerFrame[i]
			--memberFrame:ClearPoint("TOP")
		end
		--self.headerFrame:SetAttribute("point","LEFT")
	else
		for i = 1, (MAX_PARTY_MEMBERS + 1) do
			if not self.headerFrame[i] then break end
			local memberFrame = self.headerFrame[i]
			--memberFrame:ClearPoint("LEFT")
		end
		
		--self.headerFrame:SetAttribute("point","TOP")
	end

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
	if self.layout == "Vertical" then
		return self.VerticalLayout
	else
		return self.HorizontalLayout
	end
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