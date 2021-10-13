--[[
   Copyright 2007-2020 The OpenRA Developers (see AUTHORS)
   This file is part of OpenRA, which is free software. It is made
   available to you under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of
   the License, or (at your option) any later version. For more
   information, see COPYING.
]]

UnitTypes = { "3tnk", "ftrk", "ttnk", "apc.soviet" }
RearUnitTypes = { "3tnk", "3tnk", "ftrk", "apc.soviet" }
BeachUnitTypes = { "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4" }
ProxyType = "powerproxy.paratroopers"
ProducedUnitTypes =
{
	{ factory = AlliedBarracks1, types = { "e1", "e3" } },
	{ factory = AlliedBarracks2, types = { "e1", "e3" } },
	{ factory = SovietBarracks1, types = { "dog", "e1", "e2", "e3", "e4", "shok" } },
	{ factory = SovietBarracks2, types = { "dog", "e1", "e2", "e3", "e4", "shok" } },
	{ factory = SovietBarracks3, types = { "dog", "e1", "e2", "e3", "e4", "shok" } },
	{ factory = AlliedWarFactory1, types = { "jeep", "1tnk", "2tnk", "arty", "apc" } },
	{ factory = AlliedWarFactory2, types = { "jeep", "1tnk", "2tnk", "arty", "jeep" } },
	{ factory = SovietWarFactory1, types = { "3tnk", "4tnk", "v2rl", "ttnk", "apc.soviet" } },
	{ factory = SovietWarFactory2, types = { "ftrk", "3tnk", "ttnk", "3tnk", "v2rl" } }
}
ShipWayPoints =
{
	{ LstEntry1.Location, LstUnload1.Location },
	{ LstEntry2.Location, LstUnload2.Location },
	{ LstEntry3.Location, LstUnload3.Location },
	{ LstEntry4.Location, LstUnload4.Location },
	{ LstEntry5.Location, LstUnload5.Location },
	{ LstEntry6.Location, LstUnload6.Location }
}
ShipUnitTypes = { "ftrk", "ftrk", "3tnk", "3tnk", "ttnk" };
HelicopterUnitTypes = { "e1", "e1", "e1", "e1", "e3", "e3" };
ParadropWaypoints = { Paradrop1, Paradrop2, Paradrop3, Paradrop4, Paradrop5, Paradrop6, Paradrop7, Paradrop8 }

BindActorTriggers = function(a)
	if a.HasProperty("Hunt") then
		if a.Owner == allies then
			Trigger.OnIdle(a, function(a)
				if a.IsInWorld then
					a.Hunt()
				end
			end)
		else
			Trigger.OnIdle(a, function(a)
				if a.IsInWorld then
					a.AttackMove(AlliedTechnologyCenter.Location)
				end
			end)
		end
	end

	if a.HasProperty("HasPassengers") then
		Trigger.OnPassengerExited(a, function(t, p)
			BindActorTriggers(p)
		end)
	end
end

SendSovietUnits = function(entryCell, unitTypes, interval)
	local units = Reinforcements.Reinforce(soviets, unitTypes, { entryCell }, interval)
	Utils.Do(units, function(unit)
		BindActorTriggers(unit)
	end)
	Trigger.OnAllKilled(units, function() SendSovietUnits(entryCell, unitTypes, interval) end)
end

ParadropSovietUnits = function()
	local lz = Utils.Random(ParadropWaypoints)
	local aircraft = powerproxy.TargetParatroopers(lz.CenterPosition)

	Utils.Do(aircraft, function(a)
		Trigger.OnPassengerExited(a, function(t, p)
			BindActorTriggers(p)
		end)
	end)

	Trigger.AfterDelay(DateTime.Seconds(35), ParadropSovietUnits)
end

ProduceUnits = function(t)
	local factory = t.factory
	if not factory.IsDead then
		local unitType = t.types[Utils.RandomInteger(1, #t.types + 1)]
		factory.Wait(Actor.BuildTime(unitType))
		factory.Produce(unitType)
		factory.CallFunc(function() ProduceUnits(t) end)
	end
end

SetupAlliedUnits = function()
	Utils.Do(Map.NamedActors, function(a)
		if a.Owner == allies and a.HasProperty("AcceptsCondition") and a.AcceptsCondition("unkillable") then
			a.GrantCondition("unkillable")
			a.Stance = "Defend"
		end
	end)
end

SetupFactories = function()
	Utils.Do(ProducedUnitTypes, function(production)
		Trigger.OnProduction(production.factory, function(_, a) BindActorTriggers(a) end)
	end)
end

InsertAlliedChinookReinforcements = function(entry, hpad)
	local units = Reinforcements.ReinforceWithTransport(allies, "tran",
		HelicopterUnitTypes, { entry.Location, hpad.Location + CVec.New(1, 2) }, { entry.Location })[2]

	Utils.Do(units, function(unit)
		BindActorTriggers(unit)
	end)

	Trigger.AfterDelay(DateTime.Seconds(60), function() InsertAlliedChinookReinforcements(entry, hpad) end)
end

ShipSovietUnits = function()
	local way = Utils.Random(ShipWayPoints)
	local units = Utils.Random(ShipUnitTypes)
	local attackUnits = Reinforcements.ReinforceWithTransport(soviets, "lst", { units }, way, { way[2], way[1] })[2]

	Utils.Do(attackUnits, function(unit)
		BindActorTriggers(unit)
	end)

	Trigger.AfterDelay(DateTime.Seconds(30), ShipSovietUnits)
end

ChronoshiftAlliedUnits = function()
	local cells = Utils.ExpandFootprint({ ChronoshiftLocation.Location }, false)
	local units = { }
	for i = 1, #cells do
		local unit = Actor.Create("ctnk", true, { Owner = allies, Facing = Angle.West })
		BindActorTriggers(unit)
		units[unit] = cells[i]
	end
	Chronosphere.Chronoshift(units)
	Trigger.AfterDelay(DateTime.Seconds(60), ChronoshiftAlliedUnits)
end

ticks = 0
speed = 5

Tick = function()
	ticks = ticks + 1

	local t = (ticks + 45) % (360 * speed) * (math.pi / 180) / speed;
	Camera.Position = viewportOrigin + WVec.New(19200 * math.sin(t), 20480 * math.cos(t), 0)
end

WorldLoaded = function()
	allies = Player.GetPlayer("Allies")
	soviets = Player.GetPlayer("Soviets")
	viewportOrigin = Camera.Position

	Trigger.AfterDelay(DateTime.Seconds(5), ShipSovietUnits)

	SetupAlliedUnits()
	SetupFactories()
	powerproxy = Actor.Create(ProxyType, false, { Owner = soviets })
	ParadropSovietUnits()
	Trigger.AfterDelay(DateTime.Seconds(5), ChronoshiftAlliedUnits)
	Utils.Do(ProducedUnitTypes, ProduceUnits)
	InsertAlliedChinookReinforcements(ChinookEntry1, HeliPad1)
	InsertAlliedChinookReinforcements(ChinookEntry2, HeliPad2)
	SendSovietUnits(Entry1.Location, UnitTypes, 50)
	SendSovietUnits(Entry2.Location, UnitTypes, 50)
	SendSovietUnits(Entry3.Location, UnitTypes, 50)
	SendSovietUnits(Entry4.Location, UnitTypes, 50)
	SendSovietUnits(Entry5.Location, UnitTypes, 50)
	SendSovietUnits(Entry6.Location, UnitTypes, 50)
	SendSovietUnits(Entry7.Location, BeachUnitTypes, 15)
	SendSovietUnits(Entry8.Location, RearUnitTypes, 80)
end
