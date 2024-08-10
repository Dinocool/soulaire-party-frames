--Helper method to hide blizzard frames
--Taken from ShadowUF
--Helpers for hiding blizzard frames
SPF.noop = function () end
SPF.hiddenFrame = CreateFrame("Frame")
SPF.hiddenFrame:Hide()

local rehideFrame = function(self)
	if( not InCombatLockdown() ) then
		self:Hide()
	end
end

local function basicHideBlizzardFrames(...)
	for i=1, select("#", ...) do
		local frame = select(i, ...)
		frame:UnregisterAllEvents()
		frame:HookScript("OnShow", rehideFrame)
		frame:Hide()
	end
end

local function hideBlizzardFrames(taint, ...)
	for i=1, select("#", ...) do
		local frame = select(i, ...)
		UnregisterUnitWatch(frame)
		frame:UnregisterAllEvents()
		frame:Hide()

		if( frame.manabar ) then frame.manabar:UnregisterAllEvents() end
		if( frame.healthbar ) then frame.healthbar:UnregisterAllEvents() end
		if( frame.spellbar ) then frame.spellbar:UnregisterAllEvents() end
		if( frame.powerBarAlt ) then frame.powerBarAlt:UnregisterAllEvents() end

		if( taint ) then
			frame.Show = SPF.noop
		else
			frame:SetParent(SPF.hiddenFrame)
			frame:HookScript("OnShow", rehideFrame)
		end
	end
end

local active_hiddens = {}
function SPF:HideBlizzardFrames()

	if( not active_hiddens.party ) then
		if( PartyFrame ) then
			hideBlizzardFrames(false, PartyFrame)
			for memberFrame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
				if memberFrame.HealthBarContainer and memberFrame.HealthBarContainer.HealthBar then
					hideBlizzardFrames(false, memberFrame, memberFrame.HealthBarContainer.HealthBar, memberFrame.ManaBar)
				else
					hideBlizzardFrames(false, memberFrame, memberFrame.HealthBar, memberFrame.ManaBar)
				end
			end
			PartyFrame.PartyMemberFramePool:ReleaseAll()
		else
			for i=1, MAX_PARTY_MEMBERS do
				local name = "PartyMemberFrame" .. i
				hideBlizzardFrames(false, _G[name], _G[name .. "HealthBar"], _G[name .. "ManaBar"])
			end
		end

		-- This stops the compact party frame from being shown
		UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

		-- This just makes sure
		if( CompactPartyFrame ) then
			hideBlizzardFrames(false, CompactPartyFrame)
		end
	end
end
