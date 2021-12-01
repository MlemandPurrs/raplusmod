#region Copyright & License Information
/*
 * Copyright 2015- OpenRA.Mods.AS Developers (see AUTHORS)
 * This file is a part of a third-party plugin for OpenRA, which is
 * free software. It is made available to you under the terms of the
 * GNU General Public License as published by the Free Software
 * Foundation. For more information, see COPYING.
 */
#endregion

using OpenRA.Mods.Common.Traits;
using OpenRA.Primitives;
using OpenRA.Traits;

namespace OpenRA.Mods.CA.Traits
{
	[Desc("Grants a condition after this actor gets captured")]
	public class GrantConditionOnCaptureInfo : TraitInfo
	{
		[GrantedConditionReference]
		[Desc("The condition to grant")]
		public readonly string Condition = null;

		[Desc("Grant condition only if the capturer's CaptureTypes overlap with these types. Leave empty to allow all types.")]
		public readonly BitSet<CaptureType> CaptureTypes = default(BitSet<CaptureType>);

		public override object Create(ActorInitializer init) { return new GrantConditionOnCapture(init.Self, this); }
	}

	public class GrantConditionOnCapture : INotifyCapture
	{
		readonly GrantConditionOnCaptureInfo info;

		int token = Actor.InvalidConditionToken;

		public GrantConditionOnCapture(Actor self, GrantConditionOnCaptureInfo info)
		{
			this.info = info;
		}

		void GrantCondition(Actor self, string cond)
		{
			if (string.IsNullOrEmpty(cond))
				return;

			if (token == Actor.InvalidConditionToken)
				token = self.GrantCondition(cond);
		}

		void INotifyCapture.OnCapture(Actor self, Actor captor, Player oldOwner, Player newOwner, BitSet<CaptureType> captureTypes)
		{
			if (info.CaptureTypes.IsEmpty || info.CaptureTypes.Overlaps(captureTypes))
				GrantCondition(self, info.Condition);
		}
	}
}
