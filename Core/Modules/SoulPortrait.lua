SoulPortraitMixin = {}

function SoulPortraitMixin:Initialize(unit)
    self.unit = unit
    self:SetScript("OnEvent", self.OnEvent)
    self:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE",unit)
    self:RegisterEvent("PORTRAITS_UPDATED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

function SoulPortraitMixin:Update()
    SetPortraitTexture(self.Portrait, self.unit,true);
end

function SoulPortraitMixin:OnEvent(event, ...)
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