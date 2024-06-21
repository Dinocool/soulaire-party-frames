SpellDebug={}

local AceGUI = LibStub("AceGUI-3.0")
local AceTimer = LibStub("AceTimer-3.0")

function SpellDebug:Show()
    self:Initialize()
end

function SpellDebug:Hide()
    self.frame.rows={}
    self.frame:ReleaseChildren()
    AceGUI:Release(self.frame)
end

function SpellDebug:Initialize()
    self.frame = AceGUI:Create("Frame")
    self.frame:SetTitle("Example Frame")
    --self.frame:SetStatusText("Spell Debug Window")
    self.frame:SetWidth(1000)
    self.frame:SetLayout("Flow")
    self.frame:SetCallback("OnClose", function() self:Hide() end)

    local button = AceGUI:Create("Button")
    button:SetText("Wipe Data")
    button:SetWidth(100)
    button:SetCallback("OnClick", function()
         SPF_DB.spell_data={} 
         self:Refresh(self)
        end)
    self.frame:AddChild(button)
    local button = AceGUI:Create("Button")
    button:SetText("Recalculate Data")
    button:SetWidth(100)
    button:SetCallback("OnClick", function()
        for k,v in pairs(SPF_DB.spell_data) do
            if v.castTime > 0 then
                local spell = Spell:CreateFromSpellID(v.spellID)
                spell:ContinueOnSpellLoad(function()
                    IncomingDamagePredictMixin:ParseTooltip(spell:GetSpellDescription(),v)
                end)
            end
        end
        AceTimer:ScheduleTimer(function()
            self:Refresh()
        end,0.5)
        end)
    self.frame:AddChild(button)

    local headers = self:AddHeaders(self.frame)
    headers:SetFullHeight(false)
    local scrollContainer = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true) -- probably?
    scrollContainer:SetLayout("Fill") -- important!
    scrollContainer:SetHeight(400)

    self.frame:AddChild(scrollContainer)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll.rows=self.frame.rows
    scroll:SetLayout("List") -- probably?
    scrollContainer:AddChild(scroll)
    for k,v in pairs(SPF_DB.spell_data) do
        self:AddSpellRow(scroll,v)
    end
    self.frame:DoLayout()
end

function SpellDebug:Refresh()
    self:Hide()
    self:Show()
end

function SpellDebug:AddHeaders(frame)
    local row = self:AddRow(frame)
    --Icon
    local column = self:AddColumn(row,32)

    --Spell Name
    local column = self:AddColumn(row,150)
    local label = AceGUI:Create("Label")
    label:SetText("Spell Name")
    label:SetFontObject(TextStatusBarText)
    column:AddChild(label)

    --Spell ID
    local column = self:AddColumn(row,100)
    local label = AceGUI:Create("Label")
    label:SetText("Spell ID")
    label:SetFontObject(TextStatusBarText)
    column:AddChild(label)

    --Spell Damage
    local column = self:AddColumn(row,100)
    label = AceGUI:Create("Label")
    label:SetText("Spell Damage")
    label:SetFontObject(TextStatusBarText)
    column:AddChild(label)

    --Area
    local column = self:AddColumn(row,32)
    label = AceGUI:Create("Label")
    label:SetText("Area")
    label:SetFontObject(TextStatusBarText)
    column:AddChild(label)

    --Zone
    local column = self:AddColumn(row,32)
    label = AceGUI:Create("Label")
    label:SetText("Zone")
    label:SetFontObject(TextStatusBarText)
    column:AddChild(label)

    --Magic
    local column = self:AddColumn(row,40)
    label = AceGUI:Create("Label")
    label:SetText("Magic")
    label:SetFontObject(TextStatusBarText)
    column:AddChild(label)

    --Delay
    local column = self:AddColumn(row,50)
    label = AceGUI:Create("Label")
    label:SetText("Cast Time")
    label:SetFontObject(TextStatusBarText)
    column:AddChild(label)
    return row
end

function SpellDebug:AddSpellRow(frame,spellInfo)
    --ignore spells with no cast time
    if spellInfo.castTime == 0 or spellInfo.undetected then return end
    local row = self:AddRow(frame)
    local name, _, texture = GetSpellInfo(spellInfo.spellID)
 
    --Icon
    local column = self:AddColumn(row)
    local spellIcon = AceGUI:Create("Icon")
    spellIcon:SetImage(texture)
    spellIcon:SetImageSize(30,30)
    spellIcon:SetHeight(32)
    spellIcon:SetCallback("OnEnter",function(self)
        GameTooltip:SetOwner(self.frame, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(spellInfo.spellID)
    end)
    spellIcon:SetCallback("OnLeave",function()
        GameTooltip:Hide()
    end)
    spellIcon:SetCallback("OnClick", function()
            local spell = Spell:CreateFromSpellID(spellInfo.spellID)
            spell:ContinueOnSpellLoad(function()
                IncomingDamagePredictMixin:ParseTooltip(spell:GetSpellDescription(),spellInfo,true)
            end)
        end)
    column:AddChild(spellIcon)

    --Spell Name
    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(name)
    label:SetHeight(32)
    label:SetFontObject(TextStatusBarText)
    column:AddChild(label)

    --Spell ID
    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(spellInfo.spellID)
    label:SetFontObject(TextStatusBarText)
    label:SetHeight(32)
    column:AddChild(label)

    --Spell Damage
    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(spellInfo.damage)
    label:SetFontObject(TextStatusBarText)
    label:SetHeight(32)
    column:AddChild(label)

    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(tostring(spellInfo.area))
    label:SetFontObject(TextStatusBarText)
    label:SetHeight(32)
    column:AddChild(label)

    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(tostring(spellInfo.zone))
    label:SetFontObject(TextStatusBarText)
    label:SetHeight(32)
    column:AddChild(label)

    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(tostring(spellInfo.magic))
    label:SetFontObject(TextStatusBarText)
    label:SetHeight(32)
    column:AddChild(label)

    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(tostring(spellInfo.castTime))
    label:SetFontObject(TextStatusBarText)
    label:SetHeight(32)
    column:AddChild(label)
end

function SpellDebug:AddRow(frame)
    if not frame.rows then frame.rows={} end

    local row = AceGUI:Create("SimpleGroup")
    row.table = frame
    row:SetLayout("Flow")
    row:SetFullWidth(true)
    row:SetHeight(32)
    row:SetAutoAdjustHeight(false)
    frame:AddChild(row)
    frame.rows[#frame.rows+1] = row
    return row
end

function SpellDebug:AddColumn(row,width)
    if not row.columns then row.columns={} end

    local column = AceGUI:Create("SimpleGroup")
    local columnEntry = { widget=column}
    column:SetHeight(32)
    column:SetAutoAdjustHeight(false)
    if width then
        columnEntry.width = width
        column:SetWidth(width)
    else
        --Grab the width from the header
        local headerRow = row.table.rows[1]
        --DevTool:AddData(headerRow)
        local headerColumn = headerRow.columns[#row.columns+1]
        if headerColumn and headerColumn.width then
            column:SetWidth( headerColumn.width)
        end
        --DevTool:AddData(headerColumn)
    end
    column:SetLayout("Flow")
    row:AddChild(column)
    row.columns[#row.columns+1] = columnEntry
    return column
end