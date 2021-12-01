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

using OpenRA.Activities;
using OpenRA.Mods.CA.Activities;
using OpenRA.Mods.Common.Traits;
using OpenRA.Primitives;
using OpenRA.Traits;

namespace OpenRA.Mods.CA.Traits
{
	[Desc("Move onto the target then execute the attack.")]
	public class AttackInfectInfo : AttackFrontalInfo, Requires<MobileInfo>
	{
		[Desc("Range of the final joust of the infector.")]
		public readonly WDist JoustRange = WDist.Zero;

		[Desc("Conditions that last from start of the joust until the attack.")]
		[GrantedConditionReference]
		public readonly string JoustCondition = "jousting";

		[FieldLoader.Require]
		[Desc("How much damage to deal.")]
		public readonly int Damage;

		[FieldLoader.Require]
		[Desc("How often to deal the damage.")]
		public readonly int DamageInterval;

		[Desc("Damage types for the infection damage.")]
		public readonly BitSet<DamageType> DamageTypes = default;

		[Desc("If an external actor delivers more damage than this value, the infector is killed immediately.",
			"Use -1 to never kill the infector.")]
		public readonly int SuppressionDamageThreshold = -1;

		[Desc("If the infected actor receives more damage from external sources than this value, the infector is killed immediately.",
			"Use -1 to never kill the infector.")]
		public readonly int SuppressionSumThreshold = -1;

		[Desc("If the infected actor receives damage more times from external sources than this value, the infector is killed immediately.",
			"Only counted if the value is above 0.")]
		public readonly int SuppressionCountThreshold = 0;

		[Desc("Damage type used for the suppression calculations.")]
		public readonly BitSet<DamageType> SuppressionDamageType = default;

		[Desc("Damage types which allows the infector survive when it's host dies.")]
		public readonly BitSet<DamageType> SurviveHostDamageTypes = default;

		public override object Create(ActorInitializer init) { return new AttackInfect(init.Self, this); }
	}

	public class AttackInfect : AttackFrontal
	{
		readonly AttackInfectInfo info;

		int joustToken = Actor.InvalidConditionToken;

		public AttackInfect(Actor self, AttackInfectInfo info)
			: base(self, info)
		{
			this.info = info;
		}

		protected override bool CanAttack(Actor self, in Target target)
		{
			if (target.Type != TargetType.Actor)
				return false;

			if (self.Location == target.Actor.Location && HasAnyValidWeapons(target))
				return true;

			return base.CanAttack(self, target);
		}

		public void GrantJoustCondition(Actor self)
		{
			joustToken = self.GrantCondition(info.JoustCondition);
		}

		public void RevokeJoustCondition(Actor self)
		{
			if (joustToken != Actor.InvalidConditionToken)
				joustToken = self.RevokeCondition(joustToken);
		}

		public override Activity GetAttackActivity(Actor self, AttackSource source, in Target newTarget, bool allowMove, bool forceAttack, Color? targetLineColor)
		{
			return new Infect(self, newTarget, this, info, targetLineColor);
		}
	}
}
