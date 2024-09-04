SoulManaBarMixin=CreateFromMixins(SoulTextStatusBarMixin) -- A Mana Bar Is a type of text status bar

--Intializes the manabar
function SoulManaBarMixin:Initialize(partyFrame, frequentUpdates)
    self.frequentUpdates=frequentUpdates
    
    self:RegisterEvent("UNIT_DISPLAYPOWER");
	self.partyFrame = partyFrame
    self:SetUnit(partyFrame.unit)
    self:SetScript("OnEvent", self.OnEvent)
    
    --Cap numeric display in our text status bar
    self.capNumericDisplay=true
    self:TextStatusBarInitialize()
end

--Sets the unit we're monitoring and updates our events to monitor this new unit
function SoulManaBarMixin:SetUnit(unit)
    self.unit = unit
    self:RefreshUpdateEvent()
    --Update our power type for this unit, this also triggers an event update
    self:UpdatePowerType()
end

--Update triggered from an event rather then per-frame
function SoulManaBarMixin:EventUpdate()
    if not SOUL_ShouldUpdate(self.partyFrame) then return end
    local maxValue = max(UnitPowerMax(self.unit),1)

    --Health is between 0 and the units health... duh
    self:SetMinMaxValues(0, maxValue)

    --Check if the unit is connected
    self.disconnected = not UnitIsConnected(self.unit);
    if ( self.disconnected ) then
        --TODO: Custom styling for a disconnected player
        self:SetValue(maxValue)
    else
        local currValue = UnitPower(self.unit)
        self:SetValue(currValue)
    end
    self:UpdateTextString()
end

function SoulManaBarMixin:OnEvent(event, ...)
    if ( event == "CVAR_UPDATE" ) then
		self:TextStatusBarOnEvent(event, ...)
	elseif ( event == "VARIABLES_LOADED" ) then
		self:UnregisterEvent("VARIABLES_LOADED")
	elseif ( SOUL_ShouldUpdate(self) ) then
			self:EventUpdate()
	end
end


--Updates the mana bars power type to display
function SoulManaBarMixin:UpdatePowerType()
    local powerType, powerToken, altR, altG, altB = UnitPowerType(self.unit);

    --Information defined by blizzard on how to display this power
    local info = PowerBarColor[powerToken];
    local manaBarTexture;
    if (info and info.atlasElementName) then
        --TODO: Add support for animations (cool!)
        manaBarTexture = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-"..info.atlasElementName;
        self:SetStatusBarColor(1, 1, 1);
    else
        -- If we cannot find the info for what the mana bar should be, default either to Mana or Mana-Status (colorable).
        if (altR) then
		    manaBarTexture = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-Mana-Status";
            self:SetStatusBarColor(altR, altG, altB);
        else    
            manaBarTexture = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-Mana";
        end
    end
    self:SetStatusBarTexture(manaBarTexture);
    self:EventUpdate()
end

--Sets the update event based on if we need frequentUpdates and we have health prediction enabled
function SoulManaBarMixin:RefreshUpdateEvent()
	if ( self.frequentUpdates ) then
		self:SetScript("OnUpdate", self.OnFrequentUpdate)
		self:UnregisterEvent("UNIT_POWER_UPDATE")
	else
		self:SetScript("OnUpdate", nil)
		self:RegisterUnitEvent("UNIT_POWER_UPDATE", self.unit)
	end
    
    self:RegisterUnitEvent("UNIT_MAXPOWER", self.unit)
end

--This is called extremely frequently, so don't put anything expensive here
function SoulManaBarMixin:OnFrequentUpdate()
    if ( not self.disconnected ) then
        local currValue = UnitPower(self.unit)
        self:SetValue(currValue)
        self:UpdateTextString()
    end
end