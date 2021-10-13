--[[
   Copyright 2007-2020 The OpenRA Developers (see AUTHORS)
   This file is part of OpenRA, which is free software. It is made
   available to you under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of
   the License, or (at your option) any later version. For more
   information, see COPYING.
]]

if Map.LobbyOption("growthrate") == "sloweco" then
	Utils.Do(Map.NamedActors, function(actor)
	  if actor.Type == "mine" then
		actor.GrantCondition("growthslow")
	  end
	  if actor.Type == "gmine" then
		actor.GrantCondition("growthslow")
	  end
	end)
elseif Map.LobbyOption("growthrate") == "normaleco" then
	Utils.Do(Map.NamedActors, function(actor)
	  if actor.Type == "mine" then
		actor.GrantCondition("growthnormal")
	  end
	  if actor.Type == "gmine" then
		actor.GrantCondition("growthnormal")
	  end
	end)
elseif Map.LobbyOption("growthrate") == "fasteco" then
	Utils.Do(Map.NamedActors, function(actor)
	  if actor.Type == "mine" then
		actor.GrantCondition("growthfast")
	  end
	  if actor.Type == "gmine" then
		actor.GrantCondition("growthfast")
	  end
	end)
end