

UnitTypes = { "2tnk", "1tnk", "jeep", "apc" }
BeachUnitTypes = { "e1", "e1", "e1", "e3", "e3", "1tnk", "jeep", "jeep" }
ShipUnitTypes = { "ftrk", "ftrk", "4tnk", "3tnk", "ttnk" }
HelicopterUnitTypes = { "e1", "e1", "e1", "e3", "e3" }
ProxyType = "powerproxy.paratroopers"
ProducedUnitTypes =
{
	{ factory = AlliedBarracks1, types = { "e1", "e3", "e1" } },
	{ factory = AlliedBarracks2, types = { "e1", "e3", "e1" } },
	{ factory = AlliedBarracks3, types = { "e1", "e3", "e1" } },
	{ factory = SovietBarracks1, types = { "dog", "e1", "e3", "e4", "shok" } },
	{ factory = SovietBarracks2, types = { "dog", "e1", "e3", "e4", "shok" } },
	{ factory = AlliedWarFactory1, types = { "jeep", "1tnk", "2tnk", "apc", "ctnk" } },
	{ factory = SovietWarFactory1, types = { "ftrk", "apc.soviet", "4tnk" } },
	{ factory = SovietWarFactory2, types = { "3tnk", "v2rl", "ttnk"} }
}

ParadropWaypoints = { Paradrop1, Paradrop2, Paradrop3, Paradrop4, Paradrop5, Paradrop6, Paradrop7, Paradrop8 }
Mig1Waypoints = { Mig11, Mig12, Mig13, Mig14 }
Mig2Waypoints = { Mig21, Mig22, Mig23, Mig24 }

BindActorTriggers = function(a)
	if a.HasProperty("Hunt") then
		if a.Owner == soviets then
			Trigger.OnIdle(a, function(a)
				if a.IsInWorld then
					a.Hunt()
				end
			end)
		else
			Trigger.OnIdle(a, function(a)
				if a.IsInWorld then
					a.AttackMove(SovietTechnologyCenter.Location)
				end
			end)
		end
	end

	if a.HasProperty("HasPassengers") then
		Trigger.OnDamaged(a, function()
			if a.HasPassengers then
				a.Stop()
				a.UnloadPassengers()
			end
		end)
	end
end

SendAlliedUnits = function(entryCell, unitTypes, interval)
	local units = Reinforcements.Reinforce(allies, unitTypes, { entryCell }, interval)
	Utils.Do(units, function(unit)
		BindActorTriggers(unit)
	end)
	Trigger.OnAllKilled(units, function() SendAlliedUnits(entryCell, unitTypes, interval) end)
end

SetupSovietUnits = function()
	Utils.Do(Map.NamedActors, function(a)
		if a.Owner == soviets and a.HasProperty("AcceptsCondition") and a.AcceptsCondition("unkillable") then
			a.GrantCondition("unkillable")
			a.Stance = "Defend"
		end
	end)
end

SendHelis = function(waypoints)
	local migEntryPath = { waypoints[1].Location, waypoints[2].Location }
	local migs = Reinforcements.Reinforce(allies, { "heli" }, migEntryPath, 4)
	Utils.Do(migs, function(mig)
		mig.Move(waypoints[3].Location)
		mig.Move(waypoints[4].Location)
		mig.Destroy()
	end)

	Trigger.AfterDelay(DateTime.Seconds(40), function() SendHelis(waypoints) end)
end

ShipSovietUnits = function()
	local units = Reinforcements.ReinforceWithTransport(soviets, "lst",
		ShipUnitTypes, { LstEntry.Location, LstUnload.Location }, { LstEntry.Location })[2]

	Utils.Do(units, function(unit)
		BindActorTriggers(unit)
	end)

	Trigger.AfterDelay(DateTime.Seconds(60), ShipSovietUnits)
end

InsertAlliedChinookReinforcements = function(entry, hpad)
	local units = Reinforcements.ReinforceWithTransport(allies, "tran",
		HelicopterUnitTypes, { entry.Location, hpad.Location + CVec.New(1, 2) }, { entry.Location })[2]

	Utils.Do(units, function(unit)
		BindActorTriggers(unit)
	end)

	Trigger.AfterDelay(DateTime.Seconds(60), function() InsertAlliedChinookReinforcements(entry, hpad) end)
end

ChronoshiftAlliedUnits = function()
	local cells = Utils.ExpandFootprint({ ChronoshiftLocation.Location }, false)
	local units = { }
	for i = 1, #cells do
		local unit = Actor.Create("ctnk", true, { Owner = allies, Facing = Angle.North })
		BindActorTriggers(unit)
		units[unit] = cells[i]
	end
	Chronosphere.Chronoshift(units)
	Trigger.AfterDelay(DateTime.Seconds(60), ChronoshiftAlliedUnits)
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

SetupFactories = function()
	Utils.Do(ProducedUnitTypes, function(production)
		Trigger.OnProduction(production.factory, function(_, a) BindActorTriggers(a) end)
	end)
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
	SetupSovietUnits()
	SetupFactories()
	ShipSovietUnits()
	InsertAlliedChinookReinforcements(Chinook1Entry, HeliPad1)
	InsertAlliedChinookReinforcements(Chinook2Entry, HeliPad2)
	powerproxy = Actor.Create(ProxyType, false, { Owner = soviets })
	ParadropSovietUnits()
	Trigger.AfterDelay(DateTime.Seconds(5), ChronoshiftAlliedUnits)
	Utils.Do(ProducedUnitTypes, ProduceUnits)
	Trigger.AfterDelay(DateTime.Seconds(30), function() SendHelis(Mig1Waypoints) end)
	Trigger.AfterDelay(DateTime.Seconds(30), function() SendHelis(Mig2Waypoints) end)
	SendAlliedUnits(Entry1.Location, UnitTypes, 50)
	SendAlliedUnits(Entry2.Location, UnitTypes, 50)
	SendAlliedUnits(Entry3.Location, UnitTypes, 50)
	SendAlliedUnits(Entry4.Location, UnitTypes, 50)
	SendAlliedUnits(Entry5.Location, UnitTypes, 50)
	SendAlliedUnits(Entry6.Location, UnitTypes, 50)	
	SendAlliedUnits(Entry7.Location, BeachUnitTypes, 15)
end
