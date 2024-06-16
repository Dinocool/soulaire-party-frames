SPF = LibStub("AceAddon-3.0"):NewAddon("SPF","AceConsole-3.0","AceHook-3.0")

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
        },
    }

    -- Register Database
    self.db = LibStub("AceDB-3.0"):New("SoulaireFramesDB", defaults, true)

    -- Assign DB to a global variable
    SPF_DB = self.db.profile;

    SoulairePartyFrame_UpdateSettingFrameSize()
	SoulairePartyFrame_UpdateSettingFramePoint()

    SoulairePartyFrame:Show()
end