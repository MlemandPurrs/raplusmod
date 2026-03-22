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

using System;
using System.Collections.Generic;
using OpenRA.Mods.Common;
using OpenRA.Mods.Common.Traits;
using OpenRA.Traits;

namespace OpenRA.Mods.CA.Traits.Sound
{
	[Desc("Plays a looping audio file at the actor position. Attach this to the `World` actor to cover the whole map.")]
	class AmbientSoundCAInfo : ConditionalTraitInfo
	{
		[FieldLoader.Require]
		public readonly string[] SoundFiles = null;

		[Desc("Initial delay (in ticks) before playing the sound for the first time.",
			"Two values indicate a random delay range.")]
		public readonly int[] Delay = { 0 };

		[Desc("Interval between playing the sound (in ticks).",
			"Two values indicate a random delay range.")]
		public readonly int[] Interval = { 0 };

		[Desc("Do the sounds play under shroud or fog.")]
		public readonly bool AudibleThroughFog = false;

		[Desc("Multiply volume with this factor.")]
		public readonly float VolumeMultiplier = 1f;

		public override object Create(ActorInitializer init) { return new AmbientSoundCA(init.Self, this); }
	}

	class AmbientSoundCA : ConditionalTrait<AmbientSoundCAInfo>, ITick, INotifyRemovedFromWorld
	{
		readonly bool loop;
		HashSet<ISound> currentSounds = new HashSet<ISound>();
		WPos cachedPosition;
		int delay;

		public AmbientSoundCA(Actor self, AmbientSoundCAInfo info)
			: base(info)
		{
			delay = RandomDelay(self.World, info.Delay);
			loop = Info.Interval.Length == 0 || (Info.Interval.Length == 1 && Info.Interval[0] == 0);
		}

		void ITick.Tick(Actor self)
		{
			if (IsTraitDisabled)
				return;

			currentSounds.RemoveWhere(s => s == null || s.Complete);

			if (self.OccupiesSpace != null)
			{
				var pos = self.CenterPosition;
				if (pos != cachedPosition)
				{
					foreach (var s in currentSounds)
						s.SetPosition(pos);

					cachedPosition = pos;
				}
			}

			if (delay < 0)
				return;

			if (--delay < 0)
			{
				StartSound(self);
				if (!loop)
					delay = RandomDelay(self.World, Info.Interval);
			}
		}

		void StartSound(Actor self)
		{
			var sound = Info.SoundFiles.RandomOrDefault(Game.CosmeticRandom);
			var shouldStart = Info.AudibleThroughFog || (!self.World.ShroudObscures(self.CenterPosition) && !self.World.FogObscures(self.CenterPosition));

			ISound s;
			if (self.OccupiesSpace != null)
			{
				cachedPosition = self.CenterPosition;
				s = loop ? Game.Sound.Play(SoundType.World, sound, cachedPosition, shouldStart ? Info.VolumeMultiplier : 0f) :
					Game.Sound.Play(SoundType.World, sound, self.CenterPosition, shouldStart ? Info.VolumeMultiplier : 0f);
			}
			else
				s = loop ? Game.Sound.Play(SoundType.World, sound, shouldStart ? Info.VolumeMultiplier : 0f) :
					Game.Sound.Play(SoundType.World, sound, shouldStart ? Info.VolumeMultiplier : 0f);

			currentSounds.Add(s);
		}

		void StopSound()
		{
			foreach (var s in currentSounds)
				Game.Sound.StopSound(s);

			currentSounds.Clear();
		}

		protected override void TraitEnabled(Actor self) { delay = RandomDelay(self.World, Info.Delay); }
		protected override void TraitDisabled(Actor self) { StopSound(); }

		void INotifyRemovedFromWorld.RemovedFromWorld(Actor self) { StopSound(); }

		static int RandomDelay(OpenRA.World world, int[] range)
		{
			if (range == null || range.Length == 0)
				return 0;

			if (range.Length == 1)
				return range[0];

			var min = Math.Min(range[0], range[1]);
			var max = Math.Max(range[0], range[1]);

			if (min == max)
				return min;

			// Match existing usage of MersenneTwister.Next(min, max) (upper bound exclusive).
			return world.SharedRandom.Next(min, max);
		}
	}
}
