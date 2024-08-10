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
                        hidden = SoulPartyFrame_IsUnlocked,
                        func = function()
                            SoulPartyFrame:Unlock()
                        end
                    },
                    party_lock = {
                        type = 'execute',
                        order = 2,
                        name = 'Lock Party Frame',
                        desc = 'Lock the Party Frame',
                        hidden = SoulPartyFrame_IsLocked,
                        func = function()
                            SoulPartyFrame:Lock()
                        end
                    },
                    party_layout = {
                        type = 'select',
                        order = 3,
                        name = 'Party Frame Layout',
                        values = {VERTICAL="Vertical",HORIZONTAL="Horizontal" },
                        width = 'double',
                        desc = 'the way the frames are laid out (Requires reload)',
                        set = function(_, val)
                            SPF_DB.party_layout = val
                            SoulPartyFrame:UpdateLayout()
                        end,
                        get = function()
                            return SPF_DB.party_layout
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

                            SoulPartyFrame_UpdateSettingFrameSize()
                        end,
                        get = function()
                            return SPF_DB.party_scale
                        end
                    },
                    party_show_powerbars = {
                        type = 'toggle',
                        order = 4,
                        name = 'Show Power Bars On Non-Healers',
                        width = 'double',
                        desc = 'Enables power bars for non-healers',
                        set = function(_, val)
                            SPF_DB.show_power_bars = val

                            SoulPartyFrame:UpdateMemberFrames()
                        end,
                        get = function()
                            return SPF_DB.show_power_bars
                        end
                    },
                    class_color_health_bars = {
                        type = 'toggle',
                        order = 5,
                        name = 'Class Colored Health Bars',
                        width = 'double',
                        desc = 'Colors healthbars in their class respective colors',
                        set = function(_, val)
                            SPF_DB.class_color_health_bars = val

                            SoulPartyFrame:UpdateMemberFrames()
                        end,
                        get = function()
                            return SPF_DB.class_color_health_bars
                        end
                    },
                    flash_threshold = {
                        type = 'range',
                        min = 0.0,
                        max = 1.0,
                        step = 0.01,
                        order = 6,
                        name = 'Damage Flash Threshold',
                        desc = 'The Threshold at which a party frame will flash to indicate heavy damage taken',
                        set = function(_, val)
                            SPF_DB.flash_threshold = val
                        end,
                        get = function()
                            return SPF_DB.flash_threshold
                        end
                    },
                    show_player_frame = {
                        type = 'toggle',
                        order = 7,
                        name = 'Show Player Frame in Party Frame',
                        width = 'double',
                        desc = 'Shows the player frame inside the party frame',
                        set = function(_, val)
                            SPF_DB.show_player_frame = val
                            SoulPartyFrame:UpdateLayout()
                        end,
                        get = function()
                            return SPF_DB.show_player_frame
                        end
                    },
                    party_damage_prediction = {
                        type = 'toggle',
                        order = 7,
                        name = 'Calculate and show Damage Prediction (WIP)',
                        width = 'double',
                        desc = 'Attempts to predict large damage events and displays them, requires a reload',
                        set = function(_, val)
                            SPF_DB.show_damage_prediction = val
                        end,
                        get = function()
                            return SPF_DB.show_damage_prediction
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
    LibStub("AceConfig-3.0"):RegisterOptionsTable('Soulaire Party Frames', options)
    local SPF_ConfigPanel = LibStub('AceConfigDialog-3.0'):AddToBlizOptions('Soulaire Party Frames')

    -- Register Slash Command
    SPF:RegisterChatCommand('SPF', function(_)
        InterfaceOptionsFrame_OpenToCategory(SPF_ConfigPanel)
    end)   

    SPF:RegisterChatCommand('SD', function(_)
        SpellDebug:Show()
    end)  
end