#region Copyright & License Information
/*
 * Copyright 2015- OpenRA.Mods.AS Developers (see AUTHORS)
 * This file is a part of a third-party plugin for OpenRA, which is
 * free software. It is made available to you under the terms of the
 * GNU General Public License as published by the Free Software
 * Foundation. For more information, see COPYING.
 */
#endregion

using System.Linq;
using OpenRA.Mods.Common.Traits;
using OpenRA.Primitives;
using OpenRA.Traits;

namespace OpenRA.Mods.CA.Traits
{
	[Desc("Grants a condition when this actor is damaged.")]
	class GrantConditionOnDamageInfo : ConditionalTraitInfo
	{
		[Desc("The `DamageTypes` received which are allowed to trigger. If empty, all damages trigger.")]
		public readonly BitSet<DamageType> Types = default(BitSet<DamageType>);

		[FieldLoader.Require]
		[GrantedConditionReference]
		public readonly string Condition = null;

		[Desc("Use `TimedConditionBar` for visualization.")]
		public readonly int Duration = 0;

		public override object Create(ActorInitializer init) { return new GrantConditionOnDamage(this); }
	}

	class GrantConditionOnDamage : ConditionalTrait<GrantConditionOnDamageInfo>, INotifyCreated, ITick, INotifyDamage
	{
		int conditionToken = Actor.InvalidConditionToken;
		int duration;
		IConditionTimerWatcher[] watchers;

		public GrantConditionOnDamage(GrantConditionOnDamageInfo info)
			: base(info) { }

		void INotifyDamage.Damaged(Actor self, AttackInfo e)
		{
			if (IsTraitDisabled || (!Info.Types.IsEmpty && !Info.Types.Overlaps(e.Damage.DamageTypes)))
				return;

			duration = Info.Duration;

			if (conditionToken == Actor.InvalidConditionToken)
				conditionToken = self.GrantCondition(Info.Condition);
		}

		bool Notifies(IConditionTimerWatcher watcher) { return watcher.Condition == Info.Condition; }

		protected override void Created(Actor self)
		{
			watchers = self.TraitsImplementing<IConditionTimerWatcher>().Where(Notifies).ToArray();

			base.Created(self);
		}

		void ITick.Tick(Actor self)
		{
			if (conditionToken != Actor.InvalidConditionToken && Info.Duration > 0)
			{
				if (--duration < 0)
				{
					conditionToken = self.RevokeCondition(conditionToken);
					foreach (var w in watchers)
						w.Update(0, 0);
				}
				else
					foreach (var w in watchers)
						w.Update(Info.Duration, duration);
			}
		}
	}
}
