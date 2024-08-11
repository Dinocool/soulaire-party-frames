SpellDebug={}

local AceGUI = LibStub("AceGUI-3.0")
local AceTimer = LibStub("AceTimer-3.0")

local TABLE_FONT = CreateFont("SOUL_TABLE_FONT")
TABLE_FONT:CopyFontObject(TextStatusBarText)
TABLE_FONT:SetJustifyV("MIDDLE")


function SpellDebug:Show()
    self:Initialize()
end

function SpellDebug:Hide()
    self.frame:ReleaseChildren()
    AceGUI:Release(self.frame)
end

function SpellDebug:Initialize()
    self.frame = AceGUI:Create("Frame")
    self.frame:SetTitle("Spell Debug Window")
    self.frame:SetWidth(1000)
    self.frame:SetLayout("Flow")
    self.frame:SetCallback("OnClose", function() self:Hide() end)

    --[[
    local button = AceGUI:Create("Button")
    button:SetText("Wipe Data")
    button:SetWidth(100)
    button:SetCallback("OnClick", function()
         SPF_DB.spell_data={} 
         self:Refresh(self)
        end)
    self.frame:AddChild(button)
    ]]--
    local button = AceGUI:Create("Button")
    button:SetText("Recalculate Data")
    button:SetWidth(180)
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

    local searchFilter = AceGUI:Create("EditBox")
    searchFilter:SetLabel("Search")
    searchFilter:DisableButton(true)
    searchFilter:SetText(self.searchString)
    searchFilter:SetCallback("OnEnterPressed", function(widget)
        self:Search(widget:GetText())
    end)

    self.frame:AddChild(searchFilter)

    local checkbox = AceGUI:Create("CheckBox")
    checkbox:SetValue(self.showModified)
    checkbox:SetLabel("Show Modified Spells")
    checkbox:SetCallback("OnValueChanged", function(value) 
        self.showModified=value:GetValue()
        self:Refresh()
    end)
    self.frame:AddChild(checkbox)

    local headers = self:AddHeaders(self.frame)
    headers:SetFullHeight(false)
    local scrollContainer = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true) -- probably?
    scrollContainer:SetLayout("Fill") -- important!
    --scrollContainer:SetHeight(200)

    self.frame:AddChild(scrollContainer)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetUserData("rows",self.frame:GetUserData("rows"))
    scroll:SetLayout("List") -- probably?
    scrollContainer:AddChild(scroll)
    for k,v in pairs(SPF_DB.spell_data) do
        self:AddSpellRow(scroll,v)
    end
    self:AddRow(scroll)
    self.frame:DoLayout()
end

function SpellDebug:Search(value)
    self.searchString = value
    if self.searchString == "" then
        self.searchString = nil
    end
    self:Refresh()
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
    
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Spell ID
    local column = self:AddColumn(row,100)
    local label = AceGUI:Create("Label")
    label:SetText("Spell ID")
    
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Spell Damage
    local column = self:AddColumn(row,100)
    label = AceGUI:Create("Label")
    label:SetText("Spell Damage")
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Area
    local column = self:AddColumn(row,32)
    label = AceGUI:Create("Label")
    label:SetText("Area")
    
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Zone
    local column = self:AddColumn(row,32)
    label = AceGUI:Create("Label")
    label:SetText("Zone")
    
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Magic
    local column = self:AddColumn(row,40)
    label = AceGUI:Create("Label")
    label:SetText("Magic")
    
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Delay
    local column = self:AddColumn(row,60)
    label = AceGUI:Create("Label")
    label:SetText("Cast Time")
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Duration
    local column = self:AddColumn(row,60)
    label = AceGUI:Create("Label")
    label:SetText("DOT")
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Tick Rate
    local column = self:AddColumn(row,60)
    label = AceGUI:Create("Label")
    label:SetText("Tick Rate")
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Duration
    local column = self:AddColumn(row,60)
    label = AceGUI:Create("Label")
    label:SetText("Duration")
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Delayed Damage
    local column = self:AddColumn(row,120)
    label = AceGUI:Create("Label")
    label:SetText("Delayed Damage")
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)
    

    --Modified
    local column = self:AddColumn(row,50)
    label = AceGUI:Create("Label")
    label:SetText("Modified")
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    return row
end

--Modifies the selected spell
function SpellDebug:ModifySpell(checkbox,spellInfo,field)
    spellInfo.modified = true
    spellInfo[field]=checkbox:GetValue()
    self:Refresh()
end

function SpellDebug:AddSpellRow(frame,spellInfo)
    --ignore spells with no cast time
    if spellInfo.castTime == 0 then return end
    local row = self:AddRow(frame)
    local name, _, texture = GetSpellInfo(spellInfo.spellID)
 
    --Filter out modified spells
    if not self.showModified and spellInfo.modified then return end
    --Don't show the spell if we're not searching for it
    if self.searchString and not string.find(string.lower(name),self.searchString) and not string.find(spellInfo.spellID,self.searchString) then return end
    --Icon
    local column = self:AddColumn(row)
    local spellIcon = AceGUI:Create("Icon")
    spellIcon:SetImage(texture)
    spellIcon:SetImageSize(32,32)
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
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Spell ID
    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(spellInfo.spellID)
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Spell Damage
    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(spellInfo.damage)
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    --Is an AOE Spell
    local column = self:AddColumn(row)
    local checkbox = AceGUI:Create("CheckBox")
    checkbox:SetValue(spellInfo.area)
    checkbox:SetLabel("")
    checkbox:SetCallback("OnValueChanged",function(value) self:ModifySpell(value,spellInfo,"area") end)
    column:AddChild(checkbox)

    local column = self:AddColumn(row)
    local checkbox = AceGUI:Create("CheckBox")
    checkbox:SetValue(spellInfo.zone)
    checkbox:SetLabel("")
    checkbox:SetCallback("OnValueChanged",function(value) self:ModifySpell(value,spellInfo,"zone") end)
    column:AddChild(checkbox)

    local column = self:AddColumn(row)
    local checkbox = AceGUI:Create("CheckBox")
    checkbox:SetValue(spellInfo.magic)
    checkbox:SetLabel("")
    checkbox:SetCallback("OnValueChanged",function(value) self:ModifySpell(value,spellInfo,"magic") end)
    column:AddChild(checkbox)

    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(tostring(spellInfo.castTime))
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    local column = self:AddColumn(row)
    local checkbox = AceGUI:Create("CheckBox")
    checkbox:SetValue(spellInfo.dot)
    checkbox:SetLabel("")
    checkbox:SetCallback("OnValueChanged",function(value) self:ModifySpell(value,spellInfo,"dot") end)
    column:AddChild(checkbox)

    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(spellInfo.tickRate)
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(spellInfo.duration)
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    local column = self:AddColumn(row)
    local label = AceGUI:Create("Label")
    label:SetText(spellInfo.delayedDamage)
    label:SetFontObject(TABLE_FONT)
    column:AddChild(label)

    local column = self:AddColumn(row)
    local checkbox = AceGUI:Create("CheckBox")
    checkbox:SetValue(spellInfo.modified)
    checkbox:SetLabel("")
    checkbox:SetCallback("OnValueChanged",function(value) self:ModifySpell(value,spellInfo,"modified") end)
    column:AddChild(checkbox)

    
end

function SpellDebug:AddRow(frame)
    if not frame:GetUserData("rows") then frame:SetUserData("rows",{}) end
    local rows = frame:GetUserData("rows")
    local row = AceGUI:Create("SimpleGroup")
    row:SetUserData("table",frame)
    row:SetLayout("Flow")
    row:SetFullWidth(true)
    row:SetHeight(16)
    row:SetAutoAdjustHeight(true)
    frame:AddChild(row)
    rows[#rows+1] = row
    return row
end

function SpellDebug:AddColumn(row,width)
    if not row:GetUserData("columns") then row:SetUserData("columns",{}) end
    local columns = row:GetUserData("columns")
    local column = AceGUI:Create("SimpleGroup")
    local columnEntry = { widget=column}
    column:SetHeight(32)
    column:SetAutoAdjustHeight(true)
    if width then
        columnEntry.width = width
        column:SetWidth(width)
    else
        --Grab the width from the header
        local headerRow = row:GetUserData("table"):GetUserData("rows")[1]
        local headerColumn = headerRow:GetUserData("columns")[#columns+1]
        if headerColumn and headerColumn.width then
            column:SetWidth( headerColumn.width)
        else
            print("COULDNT FIND WIDTH: " .. (#columns+1))
        end
    end
    column:SetLayout("Flow")
    row:AddChild(column)
    columns[#columns+1] = columnEntry
    return column
end