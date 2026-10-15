-- Startup settings for ezo-artillery-config.
-- All multipliers default to 1 (exact vanilla behavior).
-- These must be startup settings because prototype values can only be
-- modified in the data stage.

-- Names/descriptions are localized automatically via the
-- [mod-setting-name]/[mod-setting-description] sections in locale/en/locale.cfg.
local function add_multiplier_setting(name)
	return {
		type = "double-setting",
		name = name,
		setting_type = "startup",
		default_value = 1,
		minimum_value = 0,
	}
end

data:extend({
	add_multiplier_setting("ezo-artillery-config-range-multiplier"),
	add_multiplier_setting("ezo-artillery-config-gun-cooldown-multiplier"),
	add_multiplier_setting("ezo-artillery-config-turret-rotation-multiplier"),
	add_multiplier_setting("ezo-artillery-config-shell-damage-multiplier"),
	add_multiplier_setting("ezo-artillery-config-splash-radius-multiplier"),
	add_multiplier_setting("ezo-artillery-config-min-range-multiplier"),
})
