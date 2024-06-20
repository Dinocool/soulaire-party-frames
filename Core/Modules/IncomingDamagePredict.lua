IncomingDamagePredictMixin={}

function IncomingDamagePredictMixin:Initialize()
    self:RegisterEvent("UNIT_SPELLCAST_START")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_SPELLCAST_STOP")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    self:SetScript("OnEvent", self.OnEvent)
    self.predictions={}
end

function IncomingDamagePredictMixin:OnEvent(event, ...) 
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:CombatLogEvent(event,...)
    elseif event == "UNIT_SPELLCAST_START" then
        local unit, castGUID, spellID = ...
        local target = unit.."target"

        if UnitIsFriend(target,"player") and UnitIsEnemy(unit,target) then
            if not self.predictions[spellID] then
                
            local spell = Spell:CreateFromSpellID(spellID)
            print(unit.. " is casting a bad spell on " .. GetUnitName(target) .. " "..spell:GetSpellDescription())
            local spellDamage = 
                table.insert(spellID,{})
            end
        end
    end
end

function IncomingDamagePredictMixin:CombatLogEvent(event, ...)
    local _, subevent, _, sourceGUID, _, _, _, _, destName = CombatLogGetCurrentEventInfo()
	local spellId, amount, critical
end