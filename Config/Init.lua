SPF = LibStub("AceAddon-3.0"):NewAddon("SPF","AceConsole-3.0","AceHook-3.0", "AceTimer-3.0")

function SPF:OnInitialize()
    -- Database Default profile
    local defaults = {
        profile = {
            party_point = "TOPLEFT",
            party_relative_point = "TOPLEFT",
            party_position_x = 300,
            party_position_y = -300,
            party_locked = true,
            party_scale = 1,
            show_power_bars=false,
            class_color_health_bars=true,
            max_party_buffs=10,
            max_party_debuffs=10,
            flash_threshold=0.1,
            show_damage_prediction=false,
            spell_data={},
            layout="VERTICAL"
        },
    }

    -- Register Database
    self.db = LibStub("AceDB-3.0"):New("SoulaireFramesDB", defaults, true)

    -- Assign DB to a global variable
    SPF_DB = self.db.profile;

    SoulPartyFrame_UpdateSettingFrameSize()
	SoulPartyFrame_UpdateSettingFramePoint()

    SoulPartyFrame:Show()
end