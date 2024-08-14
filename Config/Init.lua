SPF = LibStub("AceAddon-3.0"):NewAddon("SPF","AceConsole-3.0","AceHook-3.0", "AceTimer-3.0")

-- Database Default profile
local defaults = {
    profile = {
        party={
            frame={
            }
        },
        party_point = "TOPLEFT",
        party_relative_point = "TOPLEFT",
        party_position_x = 300,
        party_position_y = -300,
        party_locked = true,
        party_layout="VERTICAL",
        party_scale = 1.0,
        show_power_bars=false,
        show_player_frame=false,
        class_color_health_bars=true,
        max_party_buffs=10,
        max_party_debuffs=10,
        flash_threshold=0.1,
        show_damage_prediction=false,
        spell_data={},
    },
}

function SPF:OnInitialize()

    -- Register Database
    self.db = LibStub("AceDB-3.0"):New("SoulaireFramesDB", defaults, true)

    SPF_PROFILE = self.db
    -- Assign DB to a global variable
    SPF_DB = self.db.profile;
end

function SPF:OnEnable()
    SPF:HideBlizzardFrames()
    SoulPartyFrame:Show()
    SoulPartyFrame:LoadProfile()
end

function SPF:ChangeRole()
    --Change profile
    local currentSpec = GetSpecialization()
    local specRole = GetSpecializationRole(currentSpec)
    if specRole and  specRole ~= "HEALER" then
        specRole="Default"
    end
    if specRole then
        self.db:SetProfile(specRole)
        SPF_DB = self.db.profile;
        if not SPF_DB.initialized then
            self.db:RegisterDefaults(defaults)
            self.db:ResetProfile()
            SPF_DB.initialized=true
        end
    end
end