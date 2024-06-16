SPF_Config = SPF:NewModule("SF_Config")

function SPF_Config:OnEnable()
    -- Create Menu
     local options = {
        type = 'group',
        args = {
            moreoptions={
                name = 'General',
                type = 'group',
                childGroups = 'select',
                args={
                    partyframesHeader = {
                        type = 'header',
                        name = 'Party Frames Options',
                        order = 1
                    },
                    party_unlock = {
                        type = 'execute',
                        order = 2,
                        name = 'Unlock Party Frame',
                        desc = 'Unlock the Party Frame to move it',
                        hidden = SoulairePartyFrame_IsUnlocked,
                        func = function()
                            SoulairePartyFrame_Unlock()
                        end
                    },
                    party_lock = {
                        type = 'execute',
                        order = 2,
                        name = 'Lock Party Frame',
                        desc = 'Lock the Party Frame',
                        hidden = SoulairePartyFrame_IsLocked,
                        func = function()
                            SoulairePartyFrame_Lock()
                        end
                    },
                    party_scale = {
                        type = 'range',
                        min = 0.1,
                        max = 2,
                        step = 0.1,
                        order = 3,
                        name = 'Party Frame Scale',
                        desc = 'Set the scale of the Party Frame',
                        set = function(_, val)
                            SPF_DB.party_scale = val

                            SoulairePartyFrame_UpdateSettingFrameSize()
                        end,
                        get = function()
                            return SPF_DB.party_scale
                        end
                    },
                    auraHeader = {
                        type = 'header',
                        name = 'Auras Options',
                        order = 10
                    },
                    max_party_buffs = {
                        type = 'range',
                        min = 3,
                        max = 20,
                        step = 1,
                        order = 12,
                        name = 'Max Party Buffs (*)',
                        desc = 'Set the maximum number of visible buffs',
                        set = function(_, val)
                            SPF_DB.max_party_buffs = val
                        end,
                        get = function()
                            return SPF_DB.max_party_buffs
                        end
                    },
                    max_party_debuffs = {
                        type = 'range',
                        min = 3,
                        max = 20,
                        step = 1,
                        order = 13,
                        name = 'Max Party Debuffs (*)',
                        desc = 'Set the maximum number of visible debuffs',
                        set = function(_, val)
                            SPF_DB.max_party_debuffs = val
                        end,
                        get = function()
                            return SPF_DB.max_party_debuffs
                        end
                    },
                    reload_ui_warning = {
                        type = 'description',
                        name = '(*) These options require a reload of the ui.',
                        order = -1
                    }
                }
            }
        }
    }

    -- Register Menu
    LibStub('AceConfig-3.0'):RegisterOptionsTable('Soulaire Party Frames', options)
    local SPF_ConfigPanel = LibStub('AceConfigDialog-3.0'):AddToBlizOptions('Soulaire Party Frames')

    -- Register Slash Command
    SPF:RegisterChatCommand('SPF', function(_)
        InterfaceOptionsFrame_OpenToCategory(SPF_ConfigPanel)
    end)   
end