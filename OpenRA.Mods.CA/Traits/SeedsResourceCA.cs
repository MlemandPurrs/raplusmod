#region Copyright & License Information
/*
 * Copyright 2007-2020 The OpenRA Developers (see AUTHORS)
 * This file is part of OpenRA, which is free software. It is made
 * available to you under the terms of the GNU General Public License
 * as published by the Free Software Foundation, either version 3 of
 * the License, or (at your option) any later version. For more
 * information, see COPYING.
 */
#endregion

using System.Linq;
using OpenRA.Mods.Common;
using OpenRA.Mods.Common.Traits;
using OpenRA.Traits;

namespace OpenRA.Mods.CA.Traits
{
	[Desc("Lets the actor spread resources around it in a circle.")]
	class SeedsResourceCAInfo : ConditionalTraitInfo
	{
		public readonly int Interval = 75;
		public readonly string ResourceType = "Ore";
		public readonly int MaxRange = 100;

		public override object Create(ActorInitializer init) { return new SeedsResourceCA(init.Self, this); }
	}

	class SeedsResourceCA : ConditionalTrait<SeedsResourceCAInfo>, ITick, ISeedableResource
	{
		public new readonly SeedsResourceCAInfo Info;

		readonly IResourceLayer resourceLayer;

		public SeedsResourceCA(Actor self, SeedsResourceCAInfo info)
			: base(info)
		{
			Info = info;
			resourceLayer = self.World.WorldActor.Trait<IResourceLayer>();
		}

		int ticks;

		void ITick.Tick(Actor self)
		{
			if (IsTraitDisabled)
				return;

			if (--ticks <= 0)
			{
				Seed(self);
				ticks = Info.Interval;
			}
		}

		public void Seed(Actor self)
		{
			var cell = Util.RandomWalk(self.Location, self.World.SharedRandom)
				.Take(Info.MaxRange)
				.SkipWhile(p => resourceLayer.GetResource(p).Type == Info.ResourceType && !resourceLayer.CanAddResource(Info.ResourceType, p))
				.Cast<CPos?>().FirstOrDefault();

			if (cell != null && resourceLayer.CanAddResource(Info.ResourceType, cell.Value))
				resourceLayer.AddResource(Info.ResourceType, cell.Value);
		}
	}
}
