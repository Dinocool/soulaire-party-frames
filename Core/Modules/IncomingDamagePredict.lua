local AceTimer = LibStub("AceTimer-3.0")

IncomingDamagePredictMixin={}
DAMAGE_PATTERNS={
    INFLICT="inflict *(%d[,.%d]*) (%a*)",
    INFLICTS="inflicts *(%d[,.%d]*) (%a*)",
    INFLICTING="inflicting *(%d[,.%d]*) (%a*)",
    INFLICTING_AN_INITIAL="inflicting an initial *(%d[,.%d]*) (%a*)"
}

SINGLE_TARGET_PATTERNS={
    BOLT="^inflicts *(%d[,.%d]*) (%a*) damage.$", --sometimes bolts mention no target, must be an exact match
    SWING="^inflicts *(%d[,.%d]*) (%a*) damage to an enemy.$", --sometimes swings mention no target, must be an exact match
    CURRENT_ENEMY_TARGET="current enemy target",
    THE_TARGET="the target",
    HIS_TARGET="his target",
    HER_TARGET="her target",
    HER_CURRENT_PLAYER_TARGET="her current player target",
    THEIR_TARGET="their target",
    RANDOM_TARGET="random target",
    RANDOM_PLAYER="random player",
    TARGET_PLAYER="target player",
    STRIKE_A_PLAYER="strikes a player"
}

GLOBAL_AREA_PATTERNS={
    WITHIN_YARDS="enemies within",
    WITHIN_YDS="to players within",
    ALL_PLAYERS="all players"
}

DISTANCE_PATTERNS={
    WITHIN_YARDS="within (%d*) yards",
    WITHIN_YDS="within (%d*) yds",
}

ZONE_PATTERNS={
    IN_FRONT="in front"
}

TICK_PATTERNS={
    EVERY_SEC="every (%d[,.%d]*) sec",
    EVERY_SEC_FOR="every (%d[,.%d]*) sec"
}

DURATION_PATTERNS={
    EVERY_SEC="for (%d[,.%d]*) sec",
    AFTER="after (%d[,.%d]*) sec"
}

DAMAGE_TYPE_PATTERNS={
    PHYSICAL="physical"
}

function IncomingDamagePredictMixin:Initialize()
    self:RegisterEvent("UNIT_SPELLCAST_START")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_SPELLCAST_STOP")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    self:SetScript("OnEvent", self.OnEvent)
    --quick frame lookup
    self.party={}
    for i = 1, MAX_PARTY_MEMBERS do
        self.party["party"..i]={}
        local partyMember = self.party["party"..i]
        partyMember.frame =  _G["SoulPartyFrame"]["MemberFrame"..i]
        partyMember.estimatedPhysicalDR=1
        partyMember.estimatedMagicalDR=1
        partyMember.estimatedAOEDR=1
    end
end

function IncomingDamagePredictMixin:ResolvePartyMemeber(target)
    local guid = UnitGUID(target)
    return self:ResolvePartyMemeberFromGuid(guid)
end

function IncomingDamagePredictMixin:ResolvePartyMemeberFromGuid(guid)
    for i = 1, MAX_PARTY_MEMBERS do
        if guid == UnitGUID("party"..i) then
            return "party"..i
        end
    end
    return nil
end

function IncomingDamagePredictMixin:OnEvent(event, ...) 
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:CombatLogEvent(event,...)
    else
        local unit, castGUID, spellID = ...
        --Schedule the event as it lets targets evaluate
        AceTimer:ScheduleTimer(function ()
            local target = unit.."target"
    
            if UnitIsFriend(target,"player") and UnitIsEnemy(unit,target) then
                --Check if the target is a party member
                target = self:ResolvePartyMemeber(target)
                if not target then
                    return
                end
                local spellInfo, created = self:GetSpellInfo(spellID)
                --ignore spells that have no cast time
                if spellInfo.castTime == 0 then return end
                if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
                    if created then
                        local spell = Spell:CreateFromSpellID(spellID)
                        spell:ContinueOnSpellLoad(function()
                            self:ParseTooltip(spell:GetSpellDescription(),spellInfo)
                            --Update our healthbar with predicted damage
                            self:SetDamagePrediction(target,castGUID,spellInfo)
                        end)
                    else
                        --Update our healthbar with predicted damage
                        self:SetDamagePrediction(target,castGUID,spellInfo)
                    end
                else
                    if spellInfo then
                        self:ResolveDamagePrediction(target,castGUID,spellInfo)
                    end
                end
            end  
        end,0.01)

    end
end

function IncomingDamagePredictMixin:GetSpellInfo(spellID)
    local spellInfo = SPF_DB.spell_data[spellID]
    if not spellInfo then
        spellInfo = {}
        SPF_DB.spell_data[spellID] = spellInfo
        spellInfo.spellID = spellID
        local _, _, _, castTime = GetSpellInfo(spellID)
        spellInfo.castTime = castTime/1000
        return spellInfo, true
    else
        return spellInfo, false
    end
end

function IncomingDamagePredictMixin:SetDamagePrediction(target, castGUID, spellInfo)
    if not spellInfo.damage then return end

    --Update our healthbar with predicted damage
    if not spellInfo.area then
        local dr = self:CalculateDR(target,spellInfo.magic,spellInfo.area)
        self.party[target].frame.HealthBar:SetDamagePrediction(castGUID, spellInfo.damage*dr)
    else
        if not spellInfo.zone then
            for i = 1, MAX_PARTY_MEMBERS do
                local partyMember = self.party["party"..i]
                local dr = self:CalculateDR("party"..i,spellInfo.magic,spellInfo.area)
                partyMember.frame.HealthBar:SetDamagePrediction(castGUID, spellInfo.damage*dr)
            end 
        end
    end
    
    --Queue up a message to untrigger after the cast time, some spells don't do events correctly
    AceTimer:ScheduleTimer(function ()
        self:ResolveDamagePrediction(target,castGUID,spellInfo)
    end,spellInfo.castTime*1.3)
end

function IncomingDamagePredictMixin:ResolveDamagePrediction(target, castGUID, spellInfo)
    --Update our healthbar with predicted damage
    if not spellInfo.area then
        self.party[target].frame.HealthBar:ResolveDamagePrediction(castGUID)
    else
        if not spellInfo.zone then
            for i = 1, MAX_PARTY_MEMBERS do
                local partyMember = self.party["party"..i]
                partyMember.frame.HealthBar:ResolveDamagePrediction(castGUID)
            end 
        end
    end
end

local function IsNumeric(value)
    if value == tostring(tonumber(value)) then
        return true
    else
        return false
    end
end

function IncomingDamagePredictMixin:ParseTooltip(full_description, spellInfo, explain)

    --ignore
    if spellInfo.modifed then return end

    spellInfo.area = true
    spellInfo.zone = true
    spellInfo.magic = true
    spellInfo.dot = false
    spellInfo.tickRate = nil
    spellInfo.duration = nil
    spellInfo.damage = nil
    spellInfo.delayedDamage = nil

    full_description = string.lower(full_description)
    --break the description into sections based on newlines and only match the first
    for description in string.gmatch(full_description,"[^\r\n]+") do
        for k,v in pairs(DAMAGE_PATTERNS) do
            local damage, damageType = string.match(description,v)
            if damage then
                if explain then
                    print("Matched on: " .. v .. " damage: " .. tostring(damage) .. " damageType: " .. tostring(damageType))
                end
                if not spellInfo.damage then
                    spellInfo.damage = tonumber ((string.gsub(damage, ",", "")))
                else
                    spellInfo.delayedDamage = tonumber ((string.gsub(damage, ",", "")))
                end
                spellInfo.damageType = damageType
                for k,v in pairs(SINGLE_TARGET_PATTERNS) do
                    if string.match(description,v) then
                        if explain then
                            print("Matched on: " .. v)
                        end
                        spellInfo.area = false
                        spellInfo.zone = false
                        break
                    end
                end
                for k,v in pairs(GLOBAL_AREA_PATTERNS) do
                    if string.match(description,v) then
                        if explain then
                            print("Matched on: " .. v)
                        end
                        local foundDistance = false
                        for k,v in pairs(DISTANCE_PATTERNS) do
                            local distance = string.match(description,v)
                            local numeric = IsNumeric(distance)
                            if explain then
                                print("distance: " .. distance)
                            end
                            if numeric then
                                if tonumber(distance) >= 30 then
                                    if explain then
                                        print("Matched on: " .. v .. " distance: " .. distance)
                                    end
                                    spellInfo.zone = false
                                else
                                    if explain then
                                        print("Distance to small, distance: " .. distance)
                                    end
                                end
                                foundDistance=true
                                break
                            end
                        end
                        --No distance found in the tooltip, assume it hits all targets
                        if not foundDistance then
                            if explain then
                                print("no distance found, treating as unlimited distance")
                            end
                            spellInfo.zone = false
                        end
                    end
                end
                for k,v in pairs(ZONE_PATTERNS) do
                    if string.match(description,v) then
                        if explain then
                            print("Matched on: " .. v)
                        end
                        spellInfo.zone = true
                        break
                    end
                end
                for k,v in pairs(TICK_PATTERNS) do
                    local tick = string.match(description,v)
                    if tick then
                        if explain then
                            print("Matched on: " .. v .. " tick rate: " .. tick)
                        end
                        spellInfo.tickRate = tick
                        break
                    end
                end
                for k,v in pairs(DURATION_PATTERNS) do
                    local duration = string.match(description,v)
                    if duration then
                        if explain then
                            print("Matched on: " .. v .. " duration: " .. duration)
                        end
                        spellInfo.duration = duration
                        break
                    end
                end
                for k,v in pairs(DAMAGE_TYPE_PATTERNS) do
                    if string.match(damageType,v) then
                        if explain then
                            print("Matched on: " .. v)
                        end
                        spellInfo.magic = false
                        break
                    end
                end
                if spellInfo.tickRate and not spellInfo.duration then
                    if explain then
                        print("Found a tick rate but no duration component, scanning next paragraphs")
                    end
                else
                    return spellInfo
                end
            end
        end
    end
    print("Undected spell: " .. full_description)
    spellInfo.undetected=true
    return spellInfo
end

--calculates the amount of dr a target will have against a units ttack
function IncomingDamagePredictMixin:CalculateDR(target,magic,area)

    local dr = 1
    if magic then
        dr = dr*self.party[target].estimatedMagicalDR
    else
        dr = dr*self.party[target].estimatedPhysicalDR
    end
    if area then
        dr = dr*self.party[target].estimatedAOEDR
    end
    return dr
end

function IncomingDamagePredictMixin:CombatLogEvent(event, ...)
    local _, subevent, _, sourceGUID, _, _, _, destGuid, destName = CombatLogGetCurrentEventInfo()
	local spellId, amount, critical

    if subevent == "SPELL_DAMAGE" then
		spellId, _, _, amount, _, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
	end
    
    local spellInfo = SPF_DB.spell_data[spellId]
    if spellInfo ~= nil and spellInfo.damage then

        local target = self:ResolvePartyMemeberFromGuid(destGuid)
        if not target then return end

        local dr = self:CalculateDR(target,spellInfo.magic,spellInfo.area)
        local expectedDamage = spellInfo.damage*dr
        --print("spell did: " .. amount .. " we predicted " .. expectedDamage .. " to " .. target)
        --Check if the delta is now what we expected
        local delta = amount/expectedDamage
        if delta < 0.9 or delta > 1.1 then
            --print("discrepancy in damage taken found, adjusting")
            if SPF_DB.spell_data[spellId].magic then
                --Adjust magic dr
                self.party[target].estimatedMagicalDR=delta
            else
                --Adjust physical dr
                self.party[target].estimatedPhysicalDR=delta
            end
        end
    end
end