SPF.PartyAuras = CreateFrame("Frame", "SPF_PartyAuras")

local function CreateAura(partyMember, auraIndex, auraType, anchor, x, y)
    local partyMemberAuraFrame = "SPF_PartyAuras"..partyMember..auraType
    local auraButtonName = partyMemberAuraFrame..auraIndex

    local aura = CreateFrame("Button", auraButtonName, _G["SoulairePartyFrame"]["MemberFrame"..partyMember])

    aura:SetFrameLevel(7)
    aura:SetWidth(24)
    aura:SetHeight(24)
    aura:SetID(auraIndex)
    aura:ClearAllPoints()
    if auraIndex == 1 then
        aura:SetPoint("RIGHT", _G["SoulairePartyFrame"]["MemberFrame"..partyMember], anchor, x, y)
    else
        aura:SetPoint("LEFT", _G[partyMemberAuraFrame..auraIndex-1], "RIGHT", 6, 0)
    end
    aura:SetAttribute("unit", "party"..partyMember)
    RegisterUnitWatch(aura)

    aura.Icon = aura:CreateTexture(auraButtonName.."Icon", "ARTWORK")
    aura.Icon:SetAllPoints(aura)

    aura.Cooldown = CreateFrame("Cooldown", auraButtonName.."Cooldown", aura, "CooldownFrameTemplate")
    aura.Cooldown:SetFrameLevel(8)
    aura.Cooldown:SetReverse(true)
    aura.Cooldown:ClearAllPoints()
    aura.Cooldown:SetAllPoints(aura.Icon)
    aura.Cooldown:SetParent(aura)
    aura.Cooldown:SetHideCountdownNumbers(true)

    aura.CooldownText = aura.Cooldown:CreateFontString(auraButtonName.."CooldownText", "OVERLAY")
    aura.CooldownText:SetFont(GameFontNormal:GetFont(), 12, "OUTLINE")
    aura.CooldownText:SetTextColor(1, 1, 1)--(1, 0.75, 0)
    aura.CooldownText:ClearAllPoints()
    aura.CooldownText:SetPoint("BOTTOM", aura.Icon, "CENTER", 1, -17)

    aura.CountText = aura.Cooldown:CreateFontString(auraButtonName.."CountText", "OVERLAY")
    aura.CountText:SetFont(GameFontNormal:GetFont(), 12, "OUTLINE")
    aura.CountText:SetTextColor(1, 1, 1)
    aura.CountText:ClearAllPoints()
    aura.CountText:SetPoint("CENTER", aura.Icon, "TOPRIGHT", 0, 0)

    aura.Border = aura:CreateTexture(auraButtonName.."Border", "OVERLAY")
    aura.Border:SetAtlas("talents-node-choiceflyout-square-sheenmask")
    aura.Border:SetWidth(24+2)
    aura.Border:SetHeight(24+2)
    --aura.Border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    aura.Border:ClearAllPoints()
    aura.Border:SetPoint("TOPLEFT", aura, "TOPLEFT", -1, 1)

    aura:EnableMouse(true)
    aura:SetScript("OnLeave",function()
        GameTooltip:Hide()
    end)
end

local function GetSortedAuras(partyMember, auraType)
    local sortedAuras = {}
    local auraIndex = 1
    while UnitAura("party"..partyMember, auraIndex, auraType) do
        local _, icon, count, dispellType, duration, expires, source = UnitAura("party"..partyMember, auraIndex, auraType)
        table.insert(sortedAuras, {icon=icon, count=count, dispellType=dispellType, duration=duration, expires=expires, source=source, auraIndex=auraIndex})
        auraIndex = auraIndex + 1
    end
    table.sort(sortedAuras, function(a, b)
        if a.expires == 0 then return false end
        if b.expires == 0 then return true end
        return a.expires < b.expires
    end)

    return sortedAuras
end

local function SetAura(aura, auraType, partyMember, auraIndex)
    local partyMemberAuraFrame = "SPF_PartyAuras"..partyMember..auraType
    local auraButtonName = partyMemberAuraFrame..auraIndex

    local auraButton = _G[auraButtonName]

    if aura then
        auraButton:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetUnitAura("party"..partyMember, aura.auraIndex, auraType == "Buff" and "HELPFUL" or "HARMFUL")
        end)

        local counttext = ""
        local timetext = ""
        if aura.count > 1 then
            counttext = aura.count
        end
        auraButton.Icon:SetTexture(aura.icon)
        auraButton:SetAlpha(1)
        CooldownFrame_Set(auraButton.Cooldown, aura.expires - aura.duration, aura.duration, true)
        if aura.duration > 0 then
            local timeleft = aura.expires - GetTime()
            local alpha = 1
            if timeleft > 3600 then
                timetext = math.floor(timeleft/3600) .. "h"
            elseif timeleft > 60 then
                timetext = math.floor(timeleft/60) .. "m"
            else
                timetext = tostring(math.floor(timeleft))
            end
            auraButton.CooldownText:SetAlpha(alpha)
        end
        local borderColor = {r=0.7, g=0.7, b=0.7}
        --auraButton.Border:Hide()
        if auraType == "Debuff" then
            
            if not aura.dispellType then
                aura.dispellType=""
            end
            borderColor = DebuffTypeColor[aura.dispellType]
            if (auraIndex == 1 and aura.dispellType ~= "") then
                local partyFrame = _G["SoulairePartyFrame"]["MemberFrame"..partyMember]
                partyFrame.Flash:Show()
                partyFrame.Flash:SetVertexColor(borderColor.r, borderColor.g, borderColor.b)
            end
        end
        auraButton.Border:SetVertexColor(borderColor.r, borderColor.g, borderColor.b)
        auraButton.CooldownText:SetText(timetext)
        auraButton.CountText:SetText(counttext)
    else
        CooldownFrame_Clear(auraButton.Cooldown)
        auraButton:SetAlpha(0)
    end
end

function SPF:AurasUpdate()
    for partyMember = 1, MAX_PARTY_MEMBERS do
        if UnitExists("party"..partyMember) then
            local partyFrame = _G["SoulairePartyFrame"]["MemberFrame"..partyMember]
            partyFrame.Flash:Hide()
            -- sort buffs by duration and add them from the shortest to the longest
            local sortedBuffs = GetSortedAuras(partyMember, "HELPFUL")
            for auraIndex = 1, SPF_DB.MaxBuffs do
                SetAura(sortedBuffs[auraIndex], "Buff", partyMember, auraIndex)
            end
            local sortedDebuffs = GetSortedAuras(partyMember, "HARMFUL")
            for auraIndex = 1, SPF_DB.MaxDebuffs do
                SetAura(sortedDebuffs[auraIndex], "Debuff", partyMember, auraIndex)
            end
        end
    end
end

function SPF:EnablePartyAuras()
    SPF_DB.MaxBuffs = SPF_DB.max_party_buffs
    SPF_DB.MaxDebuffs = SPF_DB.max_party_debuffs

    for partyMember = 1, MAX_PARTY_MEMBERS do
        for auraIndex = 1, SPF_DB.MaxBuffs do
            CreateAura(partyMember, auraIndex, "Buff", "TOPRIGHT", 7, -32)
        end
        for auraIndex = 1, SPF_DB.MaxDebuffs do
            CreateAura(partyMember, auraIndex, "Debuff", "BOTTOMRIGHT", 7, 32)
        end
    end

    SPF.PartyAuras:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer >= 0.1 then
            SPF:AurasUpdate()
            self.timer = 0
        end
    end)
end