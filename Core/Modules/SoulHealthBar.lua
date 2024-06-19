SoulHealthBarMixin=CreateFromMixins(SoulTextStatusBarMixin) -- A Health Bar Is a type of text status bar

--Intializes the healthbar
function SoulHealthBarMixin:Initialize(unit, frequentUpdates)
    self.frequentUpdates=frequentUpdates
    self:SetUnit(unit)
    self:SetScript("OnEvent", self.OnEvent)
    self:InitializeHealPrediction()

    --Cap numeric display in our text status bar
    self.capNumericDisplay=true
    self:TextStatusBarInitialize()
    --self:SetScript("OnValueChanged", self.OnValueChanged)
end

function SoulHealthBarMixin:InitializeHealPrediction()
    if (self.OverAbsorbGlow) then

        self.OverAbsorbGlow:ClearAllPoints()
        self.OverAbsorbGlow:SetPoint("TOPLEFT",self.TotalAbsorbBar.TiledFillOverlay,"TOPRIGHT",-4, 7)
        self.OverAbsorbGlow:SetPoint("BOTTOMRIGHT",self.TotalAbsorbBar.TiledFillOverlay,"BOTTOMRIGHT",4, -7)  
	end

	if (self.OverHealAbsorbGlow) then
		self.OverHealAbsorbGlow:ClearAllPoints();
		self.OverHealAbsorbGlow:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 7, 0);
		self.OverHealAbsorbGlow:SetPoint("TOPRIGHT", self, "TOPLEFT", 7, 0);
	end

    self:RegisterHealPredictionEvents()
end

--Sets the update event based on if we need frequentUpdates and we have health prediction enabled
function SoulHealthBarMixin:RefreshUpdateEvent()
	if ( GetCVarBool("predictedHealth") and self.frequentUpdates ) then
		self:SetScript("OnUpdate", self.OnFrequentUpdate)
		self:UnregisterEvent("UNIT_HEALTH")
	else
		self:SetScript("OnUpdate", nil)
		self:RegisterUnitEvent("UNIT_HEALTH", self.unit)
	end
    
    self:RegisterUnitEvent("UNIT_MAXHEALTH", self.unit)
end



--This is called extremely frequently, so don't put anything expensive here
function SoulHealthBarMixin:OnFrequentUpdate()
    if ( not self.disconnected ) then
        local currValue = UnitHealth(self.unit)
        self:SetValue(currValue)
        self:UpdateTextString()
    end
end

--Update triggered from an event rather then per-frame
function SoulHealthBarMixin:EventUpdate()
    local maxValue = max(UnitHealthMax(self.unit),1)

    --Health is between 0 and the units health... duh
    self:SetMinMaxValues(0, maxValue)

    --Check if the unit is connected
    self.disconnected = not UnitIsConnected(self.unit);
    if ( self.disconnected ) then
        --TODO: Custom styling for a disconnected player
        self:SetValue(maxValue)
    else
        local currValue = UnitHealth(self.unit)
        self:SetValue(currValue)
    end
    self:UpdateTextString()

    --Every regular health event is also a valid event for heal prediction
    self:HealPredictionBarsUpdate()
end

function SoulHealthBarMixin:OnEvent(event, ...)
    if ( event == "CVAR_UPDATE" ) then
		self:TextStatusBarOnEvent(event, ...)
    elseif ( event == "VARIABLES_LOADED" ) then
        self:UnregisterEvent("VARIABLES_LOADED")
	elseif self:IsShown() then
		if ( UnitGUID(self.unit) ) then
            if ( event == "UNIT_MAXHEALTH"  ) then
                self:HealPredictionBarsUpdate()
                self:EventUpdate()
            elseif ( event == "UNIT_ABSORB_AMOUNT_CHANGED" 
            or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" 
            or event == "UNIT_HEAL_PREDICTION" ) then
                self:HealPredictionBarsUpdate()
            else
			    self:EventUpdate()
            end
		end
	end
end

--Sets the unit we're monitoring and updates our events to monitor this new unit
function SoulHealthBarMixin:SetUnit(unit)
    self.unit = unit
    self:RefreshUpdateEvent()
    --Force trigger an event update
    self:EventUpdate()
end

function SoulHealthBarMixin:RegisterHealPredictionEvents()
    if ( not self.MyHealPredictionBar and not self.OtherHealPredictionBar and not self.HealAbsorbBar and not self.TotalAbsorbBar ) then
		return;
	end

    self:RegisterUnitEvent("UNIT_HEAL_PREDICTION", self.unit)
    self:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", self.unit)
    self:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", self.unit)
    self:RegisterUnitEvent("UNIT_HEAL_PREDICTION", self.unit)
end

--Taken from blizzard's unitframe.lua
local MAX_INCOMING_HEAL_OVERFLOW = 1.0;
function SoulHealthBarMixin:HealPredictionBarsUpdate()
    if ( not self.MyHealPredictionBar and not self.OtherHealPredictionBar and not self.HealAbsorbBar and not self.TotalAbsorbBar ) then
		return;
	end

	local _, maxHealth = self:GetMinMaxValues();
	local health = self:GetValue();

	if ( maxHealth <= 0 ) then
		return;
	end

	local myIncomingHeal = UnitGetIncomingHeals(self.unit, "player") or 0;
	local allIncomingHeal = UnitGetIncomingHeals(self.unit) or 0;
	local totalAbsorb = UnitGetTotalAbsorbs(self.unit) or 0;

	local myCurrentHealAbsorb = 0;
	if ( self.HealAbsorbBar ) then
		myCurrentHealAbsorb = UnitGetTotalHealAbsorbs(self.unit) or 0;

		--We don't fill outside the health bar with healAbsorbs.  Instead, an overHealAbsorbGlow is shown.
		if ( health < myCurrentHealAbsorb ) then
			self.OverHealAbsorbGlow:Show();
			myCurrentHealAbsorb = health;
		else
			self.OverHealAbsorbGlow:Hide();
		end
	end

	--See how far we're going over the health bar and make sure we don't go too far out of the frame.
	if ( health - myCurrentHealAbsorb + allIncomingHeal > maxHealth * MAX_INCOMING_HEAL_OVERFLOW ) then
		allIncomingHeal = maxHealth * MAX_INCOMING_HEAL_OVERFLOW - health + myCurrentHealAbsorb;
	end

	local otherIncomingHeal = 0;

	--Split up incoming heals.
	if ( allIncomingHeal >= myIncomingHeal ) then
		otherIncomingHeal = allIncomingHeal - myIncomingHeal;
	else
		myIncomingHeal = allIncomingHeal;
	end

	--We don't fill outside the the health bar with absorbs.  Instead, an overAbsorbGlow is shown.
	local overAbsorb = false;
	if ( health - myCurrentHealAbsorb + allIncomingHeal + totalAbsorb >= maxHealth or health + totalAbsorb >= maxHealth ) then
		if ( totalAbsorb > 0 ) then
			overAbsorb = true;
		end

		if ( allIncomingHeal > myCurrentHealAbsorb ) then
			--totalAbsorb = max(0,maxHealth - (health - myCurrentHealAbsorb + allIncomingHeal));
		else
			--totalAbsorb = max(0,maxHealth - health);
		end
	end

    -- If Over Absorbing, reverse the direction of the absorb over the health bar
	if ( overAbsorb ) then
        
	    self.OverAbsorbGlow:ClearAllPoints();
		self.OverAbsorbGlow:SetPoint("TOPLEFT",self.TotalAbsorbBar.TiledFillOverlay,"TOPLEFT",-4, 7)
        self.OverAbsorbGlow:SetPoint("BOTTOMRIGHT",self.TotalAbsorbBar.TiledFillOverlay,"BOTTOMLEFT",4, -7)  
		--self.OverAbsorbGlow:Show();
	else
        
        self.OverAbsorbGlow:ClearAllPoints()
        self.OverAbsorbGlow:SetPoint("TOPLEFT",self.TotalAbsorbBar.TiledFillOverlay,"TOPRIGHT",-4, 7)
        self.OverAbsorbGlow:SetPoint("BOTTOMRIGHT",self.TotalAbsorbBar.TiledFillOverlay,"BOTTOMRIGHT",4, -7)  
		--self.OverAbsorbGlow:Hide();
	end
    if (totalAbsorb > 0) then
        self.OverAbsorbGlow:Show()
    else
        self.OverAbsorbGlow:Hide()
    end
    --self.TotalAbsorbBar.TiledFillOverlay:SetWidth(barSize)
    --self.TotalAbsorbBar:Show()

	local healthTexture = self:GetStatusBarTexture();
	local myCurrentHealAbsorbPercent = 0;
	local healAbsorbTexture = nil;

	if ( self.HealAbsorbBar ) then
		myCurrentHealAbsorbPercent = myCurrentHealAbsorb / maxHealth;

		--If allIncomingHeal is greater than myCurrentHealAbsorb, then the current
		--heal absorb will be completely overlayed by the incoming heals so we don't show it.
		if ( myCurrentHealAbsorb > allIncomingHeal ) then
			local shownHealAbsorb = myCurrentHealAbsorb - allIncomingHeal;
			local shownHealAbsorbPercent = shownHealAbsorb / maxHealth;

			healAbsorbTexture = self.HealAbsorbBar:UpdateFillPosition(healthTexture, shownHealAbsorb, -shownHealAbsorbPercent);

			--If there are incoming heals the left shadow would be overlayed by the incoming heals
			--so it isn't shown.
			self.HealAbsorbBar.LeftShadow:SetShown(allIncomingHeal <= 0);

			-- The right shadow is only shown if there are absorbs on the health bar.
			self.HealAbsorbBar.RightShadow:SetShown(totalAbsorb > 0)
		else
			self.HealAbsorbBar:Hide();
		end
	end

	--Show myIncomingHeal on the health bar.
	local incomingHealTexture;
	if ( self.MyHealPredictionBar ) then
		incomingHealTexture = self.MyHealPredictionBar:UpdateFillPosition(healthTexture, myIncomingHeal, -myCurrentHealAbsorbPercent);
	end

	local otherHealLeftTexture = (myIncomingHeal > 0) and incomingHealTexture or healthTexture;
	local xOffset = (myIncomingHeal > 0) and 0 or -myCurrentHealAbsorbPercent;

	--Append otherIncomingHeal on the health bar
	if ( self.OtherHealPredictionBar ) then
		incomingHealTexture = self.OtherHealPredictionBar:UpdateFillPosition(otherHealLeftTexture, otherIncomingHeal, xOffset);
	end

	--Append absorbs to the correct section of the health bar.
	local appendTexture = nil;
	if ( healAbsorbTexture ) then
		--If there is a healAbsorb part shown, append the absorb to the end of that.
		appendTexture = healAbsorbTexture;
	else
		--Otherwise, append the absorb to the end of the the incomingHeals or health part;
		appendTexture = incomingHealTexture or healthTexture;
	end

	if ( self.TotalAbsorbBar ) then
        if (overAbsorb) then
            totalAbsorb = -totalAbsorb
        end
		self.TotalAbsorbBar:UpdateFillPosition(appendTexture, totalAbsorb);
	end
end