SoulPortraitMixin = {}

function SoulPortraitMixin:Initialize(unit)
    self.unit = unit
    self:Update()
    self:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE",unit)
    self:RegisterEvent("PORTRAITS_UPDATED")
end

function SoulPortraitMixin:Update()
    SetPortraitTexture(self.Portrait, self.unit,true);
end