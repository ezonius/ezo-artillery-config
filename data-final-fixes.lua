-- data-final-fixes.lua for ezo-artillery-config.
-- Applies startup setting multipliers to ALL artillery prototypes
-- (vanilla and modded) generically. No entity or projectile names are
-- hard-coded; artillery projectiles are discovered by walking each
-- turret/wagon's trigger chains (ammo_type.action, action_delivery,
-- final_action, target_effects) and following every projectile reference
-- found there.

local range_mult = settings.startup["ezo-artillery-config-range-multiplier"].value
local cooldown_mult = settings.startup["ezo-artillery-config-gun-cooldown-multiplier"].value
local rotation_mult = settings.startup["ezo-artillery-config-turret-rotation-multiplier"].value
local damage_mult = settings.startup["ezo-artillery-config-shell-damage-multiplier"].value
local radius_mult = settings.startup["ezo-artillery-config-splash-radius-multiplier"].value
local min_range_mult = settings.startup["ezo-artillery-config-min-range-multiplier"].value

local scale_trigger_item -- forward declarations (the trigger walk is mutually recursive)
local scale_projectile

--- Call fn once per trigger item: val may be a single table or an array of tables.
local function for_each_trigger(val, fn)
	if type(val) == "table" then
		if val[1] ~= nil and type(val[1]) == "table" then
			for _, item in ipairs(val) do
				fn(item)
			end
		else
			fn(val)
		end
	end
end

--- Scale target_effects of a trigger delivery.
local function scale_target_effects(effects)
	if type(effects) ~= "table" then
		return
	end
	for_each_trigger(effects, function(effect)
		if type(effect) ~= "table" then
			return
		end
		-- Damage payload: { type = "damage", damage = { amount = ... } }
		if effect.type == "damage" and type(effect.damage) == "table" and type(effect.damage.amount) == "number" then
			effect.damage.amount = effect.damage.amount * damage_mult
		end
		-- Explosion / area radius on any effect that carries one.
		if type(effect.radius) == "number" then
			effect.radius = effect.radius * radius_mult
		end
	end)
end

--- Scale one action-delivery item, following projectile references.
local function scale_delivery(delivery, visited)
	if type(delivery) ~= "table" then
		return
	end
	-- Follow any projectile reference to the actual projectile prototype.
	local projectile_name = delivery.projectile
	if type(projectile_name) == "string" and not visited[projectile_name] and data.raw["projectile"][projectile_name] then
		visited[projectile_name] = true
		scale_projectile(data.raw["projectile"][projectile_name], visited)
	end
	scale_target_effects(delivery.target_effects)
	scale_target_effects(delivery.source_effects)
	-- Trigger deliveries may chain further via final_action.
	for_each_trigger(delivery.final_action, function(item)
		scale_trigger_item(item, visited)
	end)
end

--- Scale one TriggerItem (e.g. { type = "direct", action_delivery = ... }).
---@param trigger_item table
function scale_trigger_item(trigger_item, visited)
	if type(trigger_item) ~= "table" then
		return
	end
	for_each_trigger(trigger_item.action_delivery, function(delivery)
		scale_delivery(delivery, visited)
	end)
	for_each_trigger(trigger_item.final_action, function(item)
		scale_trigger_item(item, visited)
	end)
end

--- Scale a projectile prototype's nested trigger payloads.
---@param projectile table
scale_projectile = function(projectile, visited)
	for_each_trigger(projectile.action, function(item)
		scale_trigger_item(item, visited)
	end)
	for_each_trigger(projectile.final_action, function(item)
		scale_trigger_item(item, visited)
	end)
end

local visited = {}
local guns_scaled = {} -- gun item prototypes may be shared (vanilla turret and wagon share "artillery-wagon-cannon")

--- Scale the attack_parameters of the gun item referenced by entity.gun.
-- Artillery turrets and wagons have no attack_parameters of their own;
-- their range/cooldown live on the gun item prototype.
local function scale_gun(gun_name)
	if type(gun_name) ~= "string" or guns_scaled[gun_name] then
		return
	end
	guns_scaled[gun_name] = true
	local gun = data.raw["gun"][gun_name]
	local attack_parameters = gun and gun.attack_parameters
	if type(attack_parameters) == "table" then
		if type(attack_parameters.cooldown) == "number" then
			attack_parameters.cooldown = attack_parameters.cooldown * cooldown_mult
		end
		if type(attack_parameters.range) == "number" then
			attack_parameters.range = attack_parameters.range * range_mult
		end
		if type(attack_parameters.min_range) == "number" then
			attack_parameters.min_range = attack_parameters.min_range * min_range_mult
		end
		-- Discover projectiles via the gun's ammo trigger chain.
		local ammo_type = attack_parameters.ammo_type
		if type(ammo_type) == "table" then
			for_each_trigger(ammo_type.action, function(item)
				scale_trigger_item(item, visited)
			end)
		end
	end
end

-- Scale all artillery turrets and wagons generically.
for _, category in ipairs({ "artillery-turret", "artillery-wagon" }) do
	for _, entity in pairs(data.raw[category] or {}) do
		if type(entity) == "table" then
			-- Turret rotation speed.
			if type(entity.turret_rotation_speed) == "number" then
				entity.turret_rotation_speed = entity.turret_rotation_speed * rotation_mult
			end
			-- NOTE: manual_range_modifier (on the entity, in the gun's
			-- attack_parameters, or inside any modded entity-level
			-- attack_parameters) is intentionally NOT scaled. The manual range is
			-- computed as (gun range) * manual_range_modifier, so scaling the
			-- range alone scales the manual range by exactly the same multiplier;
			-- scaling the modifier too would square the effect.
			-- Scale the gun item carrying range/cooldown/projectile triggers.
			scale_gun(entity.gun)
			local attack_parameters = entity.attack_parameters
			if type(attack_parameters) == "table" then
				if type(attack_parameters.cooldown) == "number" then
					attack_parameters.cooldown = attack_parameters.cooldown * cooldown_mult
				end
				if type(attack_parameters.range) == "number" then
					attack_parameters.range = attack_parameters.range * range_mult
				end
				if type(attack_parameters.min_range) == "number" then
					attack_parameters.min_range = attack_parameters.min_range * min_range_mult
				end
				-- Discover projectiles via the ammo trigger chain.
				local ammo_type = attack_parameters.ammo_type
				if type(ammo_type) == "table" then
					for_each_trigger(ammo_type.action, function(item)
						scale_trigger_item(item, visited)
					end)
				end
			end
		end
	end
end
