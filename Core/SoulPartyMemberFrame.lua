SoulPartyMemberFrameMixin={}

function SoulPartyMemberFrameMixin:GetUnit()
	-- Override unit is set when we get in a vehicle
	-- Override unit will always be the original (most likely player/party member)
	return self.overrideUnit or self.unit
end

function SoulPartyMemberFrameMixin:UpdateArt()
	self:ToPlayerArt()
end

function SoulPartyMemberFrameMixin:ToPlayerArt()
    if self:IsForbidden() then return end
    if InCombatLockdown() then return end

	self.state = "player"
	self.overrideUnit = nil

    --Role
    local role = UnitGroupRolesAssigned(self:GetUnit())
    local showPowerBar = false or role=="HEALER"
    if SPF_DB then
        showPowerBar = SPF_DB.show_power_bars or role=="HEALER"
    end

	self.Texture:Show()

    if (showPowerBar) then
        self:PowerBarPlayerArt()
    else
        self:NoPowerBarPlayerArt()
    end

    self:HealthBarArt()
    self:StatusArt()

	--securecall("UnitFrame_SetUnit", self, self.unit, self.HealthBar, self.ManaBar)
	--securecall("UnitFrame_Update", self, true)
end

function SoulPartyMemberFrameMixin:NoPowerBarPlayerArt()
    self.Texture:SetAtlas("plunderstorm-UI-HUD-UnitFrame-Player-PortraitOn-2x")

    self.Flash:SetAtlas("plunderstorm-UI-HUD-UnitFrame-Player-PortraitOn-InCombat-2x", TextureKitConstants.UseAtlasSize)

    self.HealthBar:SetWidth(124)
    --self.HealthBar:SetPoint("TOPLEFT", 85, -41)

    self.HealthBar.HealthBarMask:SetPoint("TOPLEFT", self.HealthBar, "TOPLEFT", -2, -1)

    self.HealthBar:SetHeight(31)
    self.HealthBar.HealthBarMask:SetAtlas("plunderstorm-UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health-Mask-2x", TextureKitConstants.UseAtlasSize)
    self.HealthBar.HealthBarMask:SetHeight(30)
    --self.HealthBar.HealthBarMask:SetWidth(124)

    self.ManaBar:SetHeight(0)
    self.ManaBar:SetWidth(0)
end

function SoulPartyMemberFrameMixin:PowerBarPlayerArt()
    self.Texture:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn")

    self.Flash:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-InCombat", TextureKitConstants.UseAtlasSize)

    self.HealthBar:SetWidth(124)
    self.HealthBar:SetPoint("TOPLEFT", 85, -41)

    self.HealthBar.HealthBarMask:SetPoint("TOPLEFT", self.HealthBar, "TOPLEFT", -2, 6)

    self.HealthBar:SetHeight(19)
    self.HealthBar.HealthBarMask:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health-Mask")
    self.HealthBar.HealthBarMask:SetHeight(31)

	self.ManaBar:SetHeight(10)
    self.ManaBar:SetWidth(129)
end

function SoulPartyMemberFrameMixin:HealthBarArt()
    local classHealth = true
    if SPF_DB then
        classHealth = SPF_DB.class_color_health_bars
    end

    if (classHealth) then
        local _,class = UnitClass(self:GetUnit())
        local r,g,b = GetClassColor(class)
        self.HealthBar:SetColor(r,g,b)
        self.HealthBar.HealthBarTexture:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health-Status")
    else
		self.HealthBar:SetColor(1,1,1)
        self.HealthBar.HealthBarTexture:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health")
    end

    --Update prediction textures
    self.HealthBar.MyHealPredictionBar.Fill:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health-Status")
    self.HealthBar.OtherHealPredictionBar.Fill:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health-Status")
	self.HealthBar.HealAbsorbBar.Fill:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health-Status")
    self.HealthBar.DamagePredictionBar.Fill:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health-Status")
	self.HealthBar.DamagePredictionBar:SetPoint("BOTTOMRIGHT",self.HealthBar,"BOTTOMRIGHT",-1,1)
end

function SoulPartyMemberFrameMixin:StatusArt()

    self.StatusFlash:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Status", TextureKitConstants.UseAtlasSize)
    self:AddPulseAnimation(self.StatusFlash)
    self:AddPulseAnimation(self.Flash)
end

function SoulPartyMemberFrameMixin:AddPulseAnimation(frame)
    if not frame.PulseAnimation then
        frame.PulseAnimation = frame:CreateAnimationGroup()
        local animGroup = frame.PulseAnimation
        animGroup.Pulse = animGroup:CreateAnimation("Alpha")
        animGroup.Pulse:SetDuration(0.75)
        animGroup.Pulse:SetFromAlpha(0.5)
        animGroup.Pulse:SetToAlpha(1)
        animGroup.Pulse:SetSmoothing("IN_OUT")
        
        animGroup:SetLooping("BOUNCE")
        animGroup:Play()
    end
end

function SoulPartyMemberFrameMixin:UpdateHealthBarTextAnchors()
	local healthBarTextOffsetX = 0
	local healthBarTextOffsetY = 0
	if (LOCALE_koKR) then
		healthBarTextOffsetY = 1
	elseif (LOCALE_zhCN) then
		healthBarTextOffsetY = 2
	end

	self.HealthBar.CenterText:SetPoint("CENTER", self.HealthBar, "CENTER", 0, healthBarTextOffsetY)
	self.HealthBar.LeftText:SetPoint("LEFT", self.HealthBar, "LEFT", healthBarTextOffsetX, healthBarTextOffsetY)
	self.HealthBar.RightText:SetPoint("RIGHT", self.HealthBar, "RIGHT", -healthBarTextOffsetX, healthBarTextOffsetY)
end

function SoulPartyMemberFrameMixin:UpdateManaBarTextAnchors()
	local manaBarTextOffsetY = 0
	if (LOCALE_koKR) then
		manaBarTextOffsetY = 1
	elseif (LOCALE_zhCN) then
		manaBarTextOffsetY = 2
	end

	self.ManaBar.CenterText:SetPoint("CENTER", self.ManaBar, "CENTER", 2, manaBarTextOffsetY)
	self.ManaBar.RightText:SetPoint("RIGHT", self.ManaBar, "RIGHT", 0, manaBarTextOffsetY)

	if(self.state == "player") then
		self.ManaBar.LeftText:SetPoint("LEFT", self.ManaBar, "LEFT", 4, manaBarTextOffsetY)
	else
		self.ManaBar.LeftText:SetPoint("LEFT", self.ManaBar, "LEFT", 3, manaBarTextOffsetY)
	end
end

function SoulPartyMemberFrameMixin:Setup()
    self.soulaireFrame = true
	self.unit = "party"..self.layoutIndex
	self.petUnitToken = "partypet"..self.layoutIndex

	self.debuffCountdown = 0
	self.numDebuffs = 0

	self.statusCounter = 0
	self.statusSign = -1
	self.unitHPPercent = 1

	--Setup the healthbar
	self.HealthBar:Initialize(self.unit,true)
	self.ManaBar:Initialize(self.unit,true)
	self.PortraitFrame:Initialize(self.unit)

	-- Mask the various bar assets, to avoid any overflow with the frame shape.
	self.HealthBar:GetStatusBarTexture():AddMaskTexture(self.HealthBar.HealthBarMask)

	self.ManaBar:GetStatusBarTexture():AddMaskTexture(self.ManaBar.ManaBarMask)

	self:CreateAuras()
	self:UpdateName()
	self:UpdateMember()
	self:UpdateLeader()
	self:RegisterEvents()
	
	local showmenu = function()
		ToggleDropDownMenu(1, nil, self.DropDown, self, 47, 15)
	end
	SecureUnitButton_OnLoad(self, self.unit, showmenu)

	self:UpdateArt()
	self:SetFrameLevel(2)
	self:UpdateNotPresentIcon()

	UIDropDownMenu_SetInitializeFunction(self.DropDown, PartyMemberFrameMixin.InitializePartyFrameDropDown)
	UIDropDownMenu_SetDisplayMode(self.DropDown, "MENU")

	UnitPowerBarAlt_Initialize(self.PowerBarAlt, self.unit, 0.5, "GROUP_ROSTER_UPDATE")
	
	--Range Check
	SPF:ScheduleRepeatingTimer(self.UpdateDistance,0.2,self)

	self.initialized = true
end

-- Registers Events this frame should listen to
function SoulPartyMemberFrameMixin:RegisterEvents()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("UPDATE_ACTIVE_BATTLEFIELD")
	self:RegisterEvent("PARTY_LEADER_CHANGED")
	self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
	self:RegisterEvent("MUTELIST_UPDATE")
	self:RegisterEvent("IGNORELIST_UPDATE")
	self:RegisterEvent("UNIT_FACTION")
	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("READY_CHECK")
	self:RegisterEvent("READY_CHECK_CONFIRM")
	self:RegisterEvent("READY_CHECK_FINISHED")
	self:RegisterEvent("UNIT_CONNECTION")
	self:RegisterEvent("PARTY_MEMBER_ENABLE")
	self:RegisterEvent("PARTY_MEMBER_DISABLE")
	self:RegisterEvent("UNIT_PHASE")
	self:RegisterEvent("UNIT_CTR_OPTIONS")
	self:RegisterEvent("UNIT_FLAGS")
	self:RegisterEvent("UNIT_OTHER_PARTY_CHANGED")
	self:RegisterEvent("INCOMING_SUMMON_CHANGED")
	self:RegisterUnitEvent("UNIT_NAME_UPDATE",self.unit)
	self:RegisterUnitEvent("UNIT_AURA", self.unit, self.petUnitToken)
	self:RegisterUnitEvent("UNIT_PET",  self.unit, self.petUnitToken)
end

function SoulPartyMemberFrameMixin:UpdateVoiceActivityNotification()
	if self.voiceNotification then
		self.voiceNotification:ClearAllPoints()
		if self.NotPresentIcon:IsShown() then
			self.voiceNotification:SetPoint("LEFT", self.NotPresentIcon, "RIGHT", 0, 0)
		else
			self.voiceNotification:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, -12)
		end
	end
end

function SoulPartyMemberFrameMixin:VoiceActivityNotificationCreatedCallback(notification)
	self.voiceNotification = notification
	self.voiceNotification:SetParent(self)
	self:UpdateVoiceActivityNotification()
	notification:Show()
end

function SoulPartyMemberFrameMixin:UpdateMember()
	local showFrame
	if EditModeManagerFrame:ArePartyFramesForcedShown() then
		showFrame = true
	else
		showFrame = UnitExists(self.unit)
	end

	if showFrame then
		if not self:IsForbidden() and not InCombatLockdown() then
			self:Show()
		end
		if VoiceActivityManager then
			local guid = UnitGUID(self:GetUnit())
			VoiceActivityManager:RegisterFrameForVoiceActivityNotifications(self, guid, nil, "VoiceActivityNotificationPartyTemplate", "Button", PartyMemberFrameMixin.VoiceActivityNotificationCreatedCallback)
		end

		self:UpdateName()
		self.HealthBar:EventUpdate()
		self.ManaBar:UpdatePowerType()
		self:UpdateDistance()
	else
		if VoiceActivityManager then
			VoiceActivityManager:UnregisterFrameForVoiceActivityNotifications(self)
			self.voiceNotification = nil
		end
		if not self:IsForbidden() and not InCombatLockdown() then
			self:Hide()
		end
	end

	self:UpdateAuras()
	self:UpdatePvPStatus()
	self:UpdateVoiceStatus()
	self:UpdateReadyCheck()
	self:UpdateOnlineStatus()
	self:UpdateNotPresentIcon()
	self:UpdateArt()

end

function SoulPartyMemberFrameMixin:UpdateMemberHealth(elapsed)
	if ( (self.unitHPPercent > 0) and (self.unitHPPercent <= 0.2) ) then
		local alpha = 255
		local counter = self.statusCounter + elapsed
		local sign    = self.statusSign

		if ( counter > 0.5 ) then
			sign = -sign
			self.statusSign = sign
		end
		counter = mod(counter, 0.5)
		self.statusCounter = counter

		if ( sign == 1 ) then
			alpha = (127  + (counter * 256)) / 255
		else
			alpha = (255 - (counter * 256)) / 255
		end
		self.PortraitFrame.PortraitFrame.Portrait:SetAlpha(alpha)
	end
end

function SoulPartyMemberFrameMixin:UpdateDistance()
	local inRange, _ = UnitInRange(self.unit)

    if inRange then
        self:SetAlpha(1.0)
    else
        self:SetAlpha(0.30)
    end
end

function SoulPartyMemberFrameMixin:UpdateLeader()
	local leaderIcon = self.PartyMemberOverlay.LeaderIcon
	local guideIcon = self.PartyMemberOverlay.GuideIcon

	if UnitIsGroupLeader(self:GetUnit()) then
		if ( HasLFGRestrictions() ) then
			guideIcon:Show()
			leaderIcon:Hide()
		else
			leaderIcon:Show()
			guideIcon:Hide()
		end
	else
		guideIcon:Hide()
		leaderIcon:Hide()
	end
end

function SoulPartyMemberFrameMixin:UpdatePvPStatus()
	local icon = self.PartyMemberOverlay.PVPIcon
	local factionGroup = UnitFactionGroup(self:GetUnit())
	if UnitIsPVPFreeForAll(self:GetUnit()) then
		icon:SetAtlas("ui-hud-unitframe-player-pvp-ffaicon", true)
		icon:Show()
	elseif factionGroup and factionGroup ~= "Neutral" and UnitIsPVP(self:GetUnit()) then
		local atlas = (factionGroup == "Horde") and "ui-hud-unitframe-player-pvp-hordeicon" or "ui-hud-unitframe-player-pvp-allianceicon"
		icon:SetAtlas(atlas, true)
		icon:Show()
	else
		icon:Hide()
	end
end

function SoulPartyMemberFrameMixin:UpdateAssignedRoles()
	local icon = self.PartyMemberOverlay.RoleIcon
	local role = UnitGroupRolesAssignedEnum(self:GetUnit())
	if role == Enum.LFGRole.Tank then
		icon:SetAtlas("UI-LFG-RoleIcon-Tank")
		icon:Show()
	elseif role == Enum.LFGRole.Healer then
		icon:SetAtlas("UI-LFG-RoleIcon-Healer")
		icon:Show()
	elseif role == Enum.LFGRole.Damage then
		icon:SetAtlas("UI-LFG-RoleIcon-DPS")
		icon:Show()
	else
		icon:Hide()
	end
end

function SoulPartyMemberFrameMixin:UpdateVoiceStatus()
	if not UnitName(self:GetUnit()) then
		--No need to update if the frame doesn't have a unit.
		return
	end

	local mode
	local inInstance, instanceType = IsInInstance()

	if ( (instanceType == "pvp") or (instanceType == "arena") ) then
		mode = "Battleground"
	elseif ( IsInRaid() ) then
		mode = "raid"
	else
		mode = "party"
	end
end

function SoulPartyMemberFrameMixin:UpdateReadyCheck()
	local readyCheckFrame = self.ReadyCheck
	
	local readyCheckStatus = GetReadyCheckStatus(self:GetUnit())
	if UnitName(self:GetUnit()) and UnitIsConnected(self:GetUnit()) and readyCheckStatus then
		if ( readyCheckStatus == "ready" ) then
			ReadyCheck_Confirm(readyCheckFrame, 1)
		elseif ( readyCheckStatus == "notready" ) then
			ReadyCheck_Confirm(readyCheckFrame, 0)
		else -- "waiting"
			ReadyCheck_Start(readyCheckFrame)
		end
	else
		readyCheckFrame:Hide()
	end
end

function SoulPartyMemberFrameMixin:UpdateNotPresentIcon()
	self.NotPresentIcon.Status:Hide()
	if UnitInOtherParty(self:GetUnit()) then
		self.NotPresentIcon.texture:SetAtlas("groupfinder-eye-single", true)
		self.NotPresentIcon.texture:SetTexCoord(0, 1, 0, 0.9)
		self.NotPresentIcon.tooltip = PARTY_IN_PUBLIC_GROUP_MESSAGE
		self.NotPresentIcon:Show()
	elseif C_IncomingSummon.HasIncomingSummon(self:GetUnit()) then
		local status = C_IncomingSummon.IncomingSummonStatus(self:GetUnit())
		if status == Enum.SummonStatus.Pending then
			self.NotPresentIcon.texture:SetTexture("3084684")
			self.NotPresentIcon.texture:SetTexCoord(0, 1, 0, 1)
			self.NotPresentIcon.tooltip = INCOMING_SUMMON_TOOLTIP_SUMMON_PENDING
			self.NotPresentIcon:Show()
		elseif status == Enum.SummonStatus.Accepted then
			self.NotPresentIcon.texture:SetTexture("3084684")
			self.NotPresentIcon.texture:SetTexCoord(0, 1, 0, 1)
			self.NotPresentIcon.tooltip = INCOMING_SUMMON_TOOLTIP_SUMMON_ACCEPTED
			self.NotPresentIcon:Show()
			self.NotPresentIcon.Status.SetAtlas("UI-LFG-ReadyMark-Raid")
			self.NotPresentIcon.Status:Show()
		elseif status == Enum.SummonStatus.Declined then
			self.NotPresentIcon.texture:SetTexture("3084684")
			self.NotPresentIcon.texture:SetTexCoord(0, 1, 0, 1)
			self.NotPresentIcon.tooltip = INCOMING_SUMMON_TOOLTIP_SUMMON_DECLINED
			self.NotPresentIcon:Show()
			self.NotPresentIcon.Status.SetAtlas("UI-LFG-DeclineMark-Raid")
			self.NotPresentIcon.Status:Show()
		end
	else
		local phaseReason = UnitIsConnected(self:GetUnit()) and UnitPhaseReason(self:GetUnit()) or nil
		if phaseReason then
			self.NotPresentIcon.texture:SetTexture(4914669)
			self.NotPresentIcon.texture:SetVertexColor(0.5,1,1)
			self.NotPresentIcon.tooltip = PartyUtil.GetPhasedReasonString(phaseReason, self:GetUnit())
			self.NotPresentIcon:Show()
		else
			--Set Alpha based on distance
			self:UpdateDistance()
			self.NotPresentIcon:Hide()
		end
	end

	self:UpdateVoiceActivityNotification()
end

function SoulPartyMemberFrameMixin:OnEvent(event, ...)
	--securecall("UnitFrame_OnEvent", self, event, ...)

	local arg1, arg2, arg3 = ...

	if event == "UNIT_NAME_UPDATE" and arg1 == self.unit then
		self:UpdateName()
	elseif event == "PLAYER_ENTERING_WORLD" then
		if UnitExists(self:GetUnit()) then
			self:UpdateMember()
			self:UpdateOnlineStatus()
			self:UpdateAssignedRoles()
		end
	elseif event == "GROUP_ROSTER_UPDATE" or event == "UPDATE_ACTIVE_BATTLEFIELD" then
		self:UpdateMember()
		self:UpdateArt()
		self:UpdateAssignedRoles()
		self:UpdateLeader()
	elseif event == "PARTY_LEADER_CHANGED" then
		self:UpdateLeader()
	elseif event == "MUTELIST_UPDATE" or event == "IGNORELIST_UPDATE" then
		self:UpdateVoiceStatus()
	elseif event == "UNIT_FACTION" then
		if arg1 == self:GetUnit() then
			self:UpdatePvPStatus()
		end
	elseif ( event == "READY_CHECK" or
		 event == "READY_CHECK_CONFIRM" ) then
		self:UpdateReadyCheck()
	elseif event == "READY_CHECK_FINISHED" then
		if UnitExists(self:GetUnit()) then
			local finishTime = DEFAULT_READY_CHECK_STAY_TIME
			ReadyCheck_Finish(self.ReadyCheck, finishTime)
		end
	elseif event == "UNIT_CONNECTION" and arg1 == self:GetUnit() then
		self:UpdateArt()
	elseif event == "UNIT_PHASE" or event == "PARTY_MEMBER_ENABLE" or event == "PARTY_MEMBER_DISABLE" or event == "UNIT_FLAGS" or event == "UNIT_CTR_OPTIONS" then
		if event ~= "UNIT_PHASE" or arg1 == self:GetUnit() then
			self:UpdateNotPresentIcon()
		end
	elseif event == "UNIT_OTHER_PARTY_CHANGED" and arg1 == self:GetUnit() then
		self:UpdateNotPresentIcon()
	elseif event == "INCOMING_SUMMON_CHANGED" then
		self:UpdateNotPresentIcon()
	elseif event =="UNIT_AURA" then
		if arg1 == self:GetUnit() then
			local unitAuraUpdateInfo = arg2;
			self:UpdateAuras(unitAuraUpdateInfo);
		--TODO: Pet Handling
		--else
		--if arg1 == self.petUnitToken then
		--self.PetFrame:UpdateAuras(unitAuraUpdateInfo);
		--end
		end
	end
end

function SoulPartyMemberFrameMixin:UpdateName()
	local nameText = GetUnitName(self.unit);
	if ( nameText ) then
		if ( UnitInPartyIsAI(self.unit) and C_LFGInfo.IsInLFGFollowerDungeon() ) then
			nameText = LFG_FOLLOWER_NAME_PREFIX:format(nameText);
		end
		self.Name:SetText(nameText);
	end
end

function SoulPartyMemberFrameMixin:OnUpdate(elapsed)
	if self.initialized then
		self:UpdateMemberHealth(elapsed)
	end
end

function SoulPartyMemberFrameMixin:OnEnter()
	UnitFrame_OnEnter(self)
end

function SoulPartyMemberFrameMixin:OnLeave()
	UnitFrame_OnLeave(self)
end

function SoulPartyMemberFrameMixin:UpdateOnlineStatus()
	local healthBar = self.HealthBar

	if not UnitIsConnected(self:GetUnit()) then
		-- Handle disconnected state
		local unitHPMin, unitHPMax = healthBar:GetMinMaxValues()

		healthBar:SetValue(unitHPMax)
		healthBar:SetStatusBarDesaturated(true)
		SetDesaturation(self.PortraitFrame.Portrait, true)
		self.PartyMemberOverlay.Disconnect:Show()
	else
		healthBar:SetStatusBarDesaturated(false)
		SetDesaturation(self.PortraitFrame.Portrait, false)
		self.PartyMemberOverlay.Disconnect:Hide()
	end
end

function SoulPartyMemberFrameMixin:PartyMemberHealthCheck(value)
	local unitHPMax, unitCurrHP
	_, unitHPMax = self.HealthBar:GetMinMaxValues()

	unitCurrHP = self.HealthBar:GetValue()
	if unitHPMax > 0 then
		self.unitHPPercent = unitCurrHP / unitHPMax
	else
		self.unitHPPercent = 0
	end

	local unit = self:GetUnit()
	local unitIsDead = UnitIsDead(unit)
	local unitIsGhost = UnitIsGhost(unit)
	if PARTY_FRAME_RESURRECTABLE_TOOLTIP then
		local playerIsDeadOrGhost = UnitIsDeadOrGhost("player")
		local unitIsDeadOrGhost = unitIsDead or unitIsGhost
		self.ResurrectableIndicator:SetShown(not playerIsDeadOrGhost and unitIsDeadOrGhost)
	end

	if unitIsDead then
		self.PortraitFrame.Portrait:SetVertexColor(0.35, 0.35, 0.35, 1.0)
	elseif unitIsGhost then
		self.PortraitFrame.Portrait:SetVertexColor(0.2, 0.2, 0.75, 1.0)
	elseif (self.unitHPPercent > 0) and (self.unitHPPercent <= 0.2) then
		self.PortraitFrame.Portrait:SetVertexColor(1.0, 0.0, 0.0)
	else
		self.PortraitFrame.Portrait:SetVertexColor(1.0, 1.0, 1.0, 1.0)
	end
end

function SoulPartyMemberFrameMixin:InitializePartyFrameDropDown()
	local dropdown = UIDROPDOWNMENU_OPEN_MENU or self.DropDown
	UnitPopup_ShowMenu(dropdown, "PARTY", "party"..dropdown:GetParent().layoutIndex)
end

function SoulPartyMemberFrameMixin:UpdateAuras(unitAuraUpdateInfo)
	local debuffsChanged = false;
	local buffsChanged = false;

	if unitAuraUpdateInfo == nil or unitAuraUpdateInfo.isFullUpdate or self.debuffs == nil then
		self:ParseAllAuras(false, false, false, false);
		debuffsChanged = true;
		buffsChanged = true;
	else
		if unitAuraUpdateInfo.addedAuras ~= nil then
			for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
				local type = AuraUtil.ProcessAura(aura, false, false, false, false);

				if type == AuraUtil.AuraUpdateChangedType.Debuff or type == AuraUtil.AuraUpdateChangedType.Dispel then
					self.debuffs[aura.auraInstanceID] = aura;
					debuffsChanged = true;
				elseif type == AuraUtil.AuraUpdateChangedType.Buff then
					self.buffs[aura.auraInstanceID] = aura;
					buffsChanged = true;
				end
			end
		end

		if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
			for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
				if self.debuffs[auraInstanceID] ~= nil then
					local newAura = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unit, auraInstanceID);
					local oldDebuffType = self.debuffs[auraInstanceID].debuffType;
					if newAura ~= nil then
						newAura.debuffType = oldDebuffType;
					end
					self.debuffs[auraInstanceID] = newAura;
					debuffsChanged = true;
				elseif self.buffs[auraInstanceID] ~= nil then
					local newAura = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unit, auraInstanceID);
					if newAura ~= nil then
						newAura.isBuff = true;
					end
					self.buffs[auraInstanceID] = newAura;
					buffsChanged = true;
				end
			end
		end

		if unitAuraUpdateInfo.removedAuraInstanceIDs ~= nil then
			for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
				if self.debuffs[auraInstanceID] ~= nil then
					self.debuffs[auraInstanceID] = nil;
					debuffsChanged = true;
				elseif self.buffs[auraInstanceID] ~= nil then
					self.buffs[auraInstanceID] = nil;
					buffsChanged = true;
				end
			end
		end
	end
	if buffsChanged or debuffsChanged then
		self:AurasUpdate(buffsChanged,debuffsChanged)
	end
end

function SoulPartyMemberFrameMixin:ParseAllAuras() 
	if self.debuffs == nil then
		self.debuffs = TableUtil.CreatePriorityTable(AuraUtil.UnitFrameDebuffComparator, TableUtil.Constants.AssociativePriorityTable);
		self.buffs = TableUtil.CreatePriorityTable(AuraUtil.DefaultAuraCompare, TableUtil.Constants.AssociativePriorityTable);
	else
		self.debuffs:Clear();
		self.buffs:Clear();
	end

	local batchCount = nil;
	local usePackedAura = true;
	local function HandleAura(aura)
		local type = AuraUtil.ProcessAura(aura, false, false, false, false);
		if type == AuraUtil.AuraUpdateChangedType.Debuff or type == AuraUtil.AuraUpdateChangedType.Dispel then
			self.debuffs[aura.auraInstanceID] = aura;
		elseif type == AuraUtil.AuraUpdateChangedType.Buff then
			self.buffs[aura.auraInstanceID] = aura;
		end
	end
	AuraUtil.ForEachAura(self.unit, AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful), batchCount, HandleAura, usePackedAura);
	AuraUtil.ForEachAura(self.unit, AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Helpful), batchCount, HandleAura, usePackedAura);
	AuraUtil.ForEachAura(self.unit, AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful, AuraUtil.AuraFilters.Raid), batchCount, HandleAura, usePackedAura);
end

function SoulPartyMemberFrameMixin:CreateAura(auraIndex, auraType)
	if not self.auras then self.auras={} end

    local auraButtonName = auraType..auraIndex
    local aura = CreateFrame("Button", auraButtonName, self)
	self.auras[auraButtonName] = aura
    aura:SetFrameLevel(7)
    aura:SetWidth(24)
    aura:SetHeight(24)
    aura:SetID(auraIndex)
    aura:SetAttribute("unit", "party"..self.layoutIndex)
    RegisterUnitWatch(aura)

    aura.Icon = aura:CreateTexture(auraButtonName.."Icon", "BACKGROUND")
    aura.Icon:SetAllPoints(aura)
	aura.IconMask = aura:CreateMaskTexture()
	aura.IconMask:SetPoint("TOPLEFT",0,0)
	aura.IconMask:SetPoint("BOTTOMRIGHT",22,-22)
	aura.IconMask:SetTexture("interface/common/commoniconmask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	--aura.Icon:AddMaskTexture(aura.IconMask)
    aura.Cooldown = CreateFrame("Cooldown", auraButtonName.."Cooldown", aura, "CooldownFrameTemplate")
    aura.Cooldown:SetFrameLevel(8)
    aura.Cooldown:SetReverse(true)
    aura.Cooldown:ClearAllPoints()
    aura.Cooldown:SetAllPoints(aura.Icon)
    aura.Cooldown:SetParent(aura)
    --aura.Cooldown:SetHideCountdownNumbers(true)
	aura.Cooldown:SetCountdownFont("SystemFont_Shadow_Med3")
    --aura.CooldownText = aura.Cooldown:CreateFontString(auraButtonName.."CooldownText", "OVERLAY")
    --aura.CooldownText:SetFont(GameFontNormal:GetFont(), 12, "OUTLINE")
    --aura.CooldownText:SetTextColor(1, 1, 1)--(1, 0.75, 0)
    --aura.CooldownText:ClearAllPoints()
    --aura.CooldownText:SetPoint("BOTTOM", aura.Icon, "CENTER", 1, -17)

    aura.CountText = aura.Cooldown:CreateFontString(auraButtonName.."CountText", "OVERLAY")
    aura.CountText:SetFont(GameFontNormal:GetFont(), 12, "OUTLINE")
    aura.CountText:SetTextColor(1, 1, 1)
    aura.CountText:ClearAllPoints()
    aura.CountText:SetPoint("CENTER", aura.Icon, "TOPRIGHT", 0, 0)

	aura.BorderFrame = CreateFrame("Frame","BorderFrame",aura)
    aura.Border = aura.BorderFrame:CreateTexture(auraButtonName.."Border", "OVERLAY")
    aura.Border:SetAtlas("talents-node-choiceflyout-square-sheenmask")
    aura.Border:SetWidth(24+2)
    aura.Border:SetHeight(24+2)
    --aura.Border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    aura.Border:ClearAllPoints()
    aura.Border:SetPoint("TOPLEFT", aura, "TOPLEFT", -1, 1)

	aura.SheenFrame = CreateFrame("Frame","SheenFrame",aura)
	aura.SheenFrame:SetWidth(64)
    aura.SheenFrame:SetHeight(32)
	aura.SheenFrame:SetPoint("TOPLEFT")
	aura.Sheen = aura.SheenFrame:CreateTexture("AuraSheen","OVERLAY")
	aura.Sheen:SetPoint("TOPLEFT",-32,23)
	aura.Sheen:SetAtlas("loottoast-sheen")
	aura.Sheen:SetBlendMode("ADD")
	aura.Sheen:SetWidth(64)
    aura.Sheen:SetHeight(64)
	aura.Sheen:AddMaskTexture(aura.IconMask)
	aura.Sheen:Hide()
	self:AddSwipeAnimation(aura.Sheen)
	
    aura:EnableMouse(true)
    aura:SetScript("OnLeave",function()
        GameTooltip:Hide()
    end)
end

function SoulPartyMemberFrameMixin:AddSwipeAnimation(frame)
    if not frame.SwipeAnimation then
        frame.SwipeAnimation = frame:CreateAnimationGroup()
        local animGroup = frame.SwipeAnimation
        animGroup.Swipe = animGroup:CreateAnimation("Translation")
        animGroup.Swipe:SetDuration(0.75)
        animGroup.Swipe:SetOffset(64*1.5,0)
        animGroup.Swipe:SetSmoothing("OUT")
        animGroup:HookScript("OnPlay",function(self) frame:Show() end)
		animGroup:HookScript("OnFinished",function(self) frame:Hide() end)
        animGroup:SetLooping("NONE")
    end
end

function SoulPartyMemberFrameMixin:SetAura(aura, auraType, auraIndex)
    local auraButtonName = auraType..auraIndex

    local auraButton = self.auras[auraButtonName]
	local layoutIndex = self.layoutIndex

    if aura then
		auraButton:EnableMouse(true)
        auraButton:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetUnitBuffByAuraInstanceID("party"..layoutIndex, aura.auraInstanceID, auraType == "Buff" and "HELPFUL" or "HARMFUL")
        end)

		local counttext = ""
        if aura.applications > 1 then
            counttext = aura.applications
        end

		--Play an animation for new auras
		if not aura.playedAnimation then
			auraButton.Sheen.SwipeAnimation:Play()
			auraButton.Sheen:SetVertexColor(1,1,1)
			aura.playedAnimation=true
		end

        auraButton.Icon:SetTexture(aura.icon)
        auraButton:SetAlpha(1)
        CooldownFrame_Set(auraButton.Cooldown, aura.expirationTime - aura.duration, aura.duration, aura.duration>0, true)
        local borderColor = {r=0.5, g=0.5, b=0.5}
        --auraButton.Border:Hide()
        if aura.isHarmful then
            if not aura.dispelName then
                aura.dispelName=""
            end
            borderColor = DebuffTypeColor[aura.dispelName]
            if auraIndex == 1 and SoulPartyFrame.dispels and SoulPartyFrame.dispels[string.lower(aura.dispelName)] and next(SoulPartyFrame.dispels[string.lower(aura.dispelName)]) ~= nil then
                self.Flash:Show()
                self.Flash:SetVertexColor(borderColor.r, borderColor.g, borderColor.b)
            end
			auraButton.Sheen:SetVertexColor(borderColor.r, borderColor.g, borderColor.b)
		elseif aura.isFromPlayerOrPlayerPet then
			borderColor = {r=0.0, g=0.7, b=0.3}
			auraButton.Sheen:SetVertexColor(borderColor.r, borderColor.g, borderColor.b)
        end
        auraButton.Border:SetVertexColor(borderColor.r, borderColor.g, borderColor.b)
		auraButton.CountText:SetText(counttext)
    else
		auraButton:EnableMouse(false)
        CooldownFrame_Clear(auraButton.Cooldown)
        auraButton:SetAlpha(0)
    end
end

function SoulPartyMemberFrameMixin:AurasUpdate(buffsChanged, debuffsChanged)
    self.Flash:Hide()
    -- sort buffs by duration and add them from the shortest to the longest
    if buffsChanged and self.buffs then
        for auraIndex = 1, 10 do
            self:SetAura(self.buffs[auraIndex], "Buff", auraIndex)
        end
    end
    if debuffsChanged and self.debuffs then
        for auraIndex = 1, 10 do
            self:SetAura(self.debuffs[auraIndex], "Debuff", auraIndex)
        end
    end
end

function SoulPartyMemberFrameMixin:GetAuraAnchor(debuff)
	if SPF_DB.party_layout == "VERTICAL"  then
		if debuff then
			return "BOTTOMRIGHT", 7, 32
		else
			return "TOPRIGHT", 7, -32
		end
	else
		if debuff then
			return "TOPLEFT", 50, 32
		else
			return "TOPLEFT", 50, 0
		end
	end
end

function SoulPartyMemberFrameMixin:UpdateAuraAnchors()
	for auraIndex = 1, 10 do
		self:SetAuraAnchor(auraIndex, "Buff", self:GetAuraAnchor(false))
		self:SetAuraAnchor(auraIndex, "Debuff", self:GetAuraAnchor(true))
	end
end

function SoulPartyMemberFrameMixin:SetAuraAnchor(auraIndex, auraType, anchor, x, y)
    local auraButtonName = auraType..auraIndex
    local aura = self.auras[auraButtonName]

    aura:ClearAllPoints()
    if auraIndex == 1 then
        aura:SetPoint("RIGHT", self, anchor, x, y)
    else
        aura:SetPoint("LEFT", self.auras[auraType..auraIndex-1], "RIGHT", 6, 0)
    end

end

function SoulPartyMemberFrameMixin:CreateAuras()
    local maxBuffs=10
	local maxDebuffs=10
    for auraIndex = 1, maxBuffs do
        self:CreateAura(auraIndex, "Buff")
    end
    for auraIndex = 1, maxDebuffs do
        self:CreateAura(auraIndex, "Debuff")
    end
	self:UpdateAuraAnchors()
end