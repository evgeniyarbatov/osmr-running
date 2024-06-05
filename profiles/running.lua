-- Include the original foot profile
local foot = require('foot')

-- Override the setup function
function foot.setup()
  -- Customize the profile parameters
  local profile = {
    default_mode            = mode.walking,
    default_speed           = 15,  -- Default speed in km/h
    traffic_light_penalty   = 0.1,  -- Penalty factor for traffic lights (10% of default speed)
    park_connector_bonus    = 1.5,  -- Bonus factor for 'Park Connector' paths (150% of default speed)

    properties = {
      weight_name                   = 'duration',
      max_speed_for_map_matching    = 3, -- kmph -> m/s
      call_tagless_node_function    = false,
      traffic_light_penalty         = 2,
      u_turn_penalty                = 2,
      continue_straight_at_waypoint = false,
      use_turn_restrictions         = false,
    },

    avoid = Set {
      'impassable',
      'proposed'
    },

    barrier_blacklist = Set {
      'yes',
      'wall',
      'fence'
    },

    access_tag_whitelist = Set {
      'yes',
      'foot',
      'permissive',
      'designated'
    },

    access_tag_blacklist = Set {
      'no',
      'agricultural',
      'forestry',
      'private',
      'delivery',
    },

    access_tags_hierarchy = Sequence {
      'foot',
      'access'
    },

    restricted_access_tag_list = Set { },

    restricted_highway_whitelist = Set { },
  }

  -- Return the profile table
  return profile
end

function handle_running_tags(profile ,way, result, data)
  -- Avoid traffic lights by increasing the penalty for ways with traffic lights
  local traffic_lights = way:get_value_by_key('highway')
  if traffic_lights == 'traffic_signals' then
    result.forward_speed = profile.default_speed * profile.traffic_light_penalty
    result.backward_speed = profile.default_speed * profile.traffic_light_penalty
  end

  -- Prefer ways with 'Park Connector' in the name by decreasing the penalty
  local name = way:get_value_by_key('name')
  if name and name:find('Park Connector') then
    result.forward_speed = profile.default_speed * profile.park_connector_bonus
    result.backward_speed = profile.default_speed * profile.park_connector_bonus
  end
end
  
-- Function to modify the properties of ways
function foot.process_way(profile, way, result)
  local data = {
    highway = way:get_value_by_key('highway'),
  }

  local handlers = Sequence {
    WayHandlers.default_mode,
    WayHandlers.blocked_ways,
    WayHandlers.access,
    handle_running_tags,
    WayHandlers.weights
  }

  WayHandlers.run(profile, way, result, data, handlers)
end

return foot
