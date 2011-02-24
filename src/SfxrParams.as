package   
{
	/**
	 * SfxrParams
	 * 
	 * Copyright 2010 Thomas Vian
	 *
	 * Licensed under the Apache License, Version 2.0 (the "License");
	 * you may not use this file except in compliance with the License.
	 * You may obtain a copy of the License at
	 *
	 * 	http://www.apache.org/licenses/LICENSE-2.0
	 *
	 * Unless required by applicable law or agreed to in writing, software
	 * distributed under the License is distributed on an "AS IS" BASIS,
	 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 * See the License for the specific language governing permissions and
	 * limitations under the License.
	 * 
	 * @author Thomas Vian
	 */
	public class SfxrParams
	{
		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------
		
		/** If the parameters have been changed since last time (shouldn't used cached sound) */
		public var paramsDirty:Boolean;			
		
		private var _waveType			:uint = 	0;		// Shape of the wave (0:square, 1:saw, 2:sin or 3:noise)
		
		private var _masterVolume		:Number = 	0.5;	// Overall volume of the sound (0 to 1)
		
		private var _attackTime			:Number =	0.0;	// Length of the volume envelope attack (0 to 1)
		private var _sustainTime		:Number = 	0.0;	// Length of the volume envelope sustain (0 to 1)
		private var _sustainPunch		:Number = 	0.0;	// Tilts the sustain envelope for more 'pop' (0 to 1)
		private var _decayTime			:Number = 	0.0;	// Length of the volume envelope decay (yes, I know it's called release) (0 to 1)
		
		private var _startFrequency		:Number = 	0.0;	// Base note of the sound (0 to 1)
		private var _minFrequency		:Number = 	0.0;	// If sliding, the sound will stop at this frequency, to prevent really low notes (0 to 1)
		
		private var _slide				:Number = 	0.0;	// Slides the note up or down (-1 to 1)
		private var _deltaSlide			:Number = 	0.0;	// Accelerates the slide (-1 to 1)
		
		private var _vibratoDepth		:Number = 	0.0;	// Strength of the vibrato effect (0 to 1)
		private var _vibratoSpeed		:Number = 	0.0;	// Speed of the vibrato effect (i.e. frequency) (0 to 1)
		
		private var _changePeriod		:Number = 	0.0;	// How fast the note shift happens (only happens once) (0 to 1)
		
		private var _changeAmount		:Number = 	0.0;	// Shift in note, either up or down (-1 to 1)
		private var _changeSpeed		:Number = 	0.0;	// How fast the note shift happens (only happens once) (0 to 1)
		
		private var _changeAmount2		:Number = 	0.0;	// Shift in note, either up or down (-1 to 1)
		private var _changeSpeed2		:Number = 	0.0;	// How fast the note shift happens (only happens once) (0 to 1)
		
		private var _squareDuty			:Number = 	0.0;	// Controls the ratio between the up and down states of the square wave, changing the tibre (0 to 1)
		private var _dutySweep			:Number = 	0.0;	// Sweeps the duty up or down (-1 to 1)
		
		private var _repeatSpeed		:Number = 	0.0;	// Speed of the note repeating - certain variables are reset each time (0 to 1)
		
		private var _phaserOffset		:Number = 	0.0;	// Offsets a second copy of the wave by a small phase, changing the tibre (-1 to 1)
		private var _phaserSweep		:Number = 	0.0;	// Sweeps the phase up or down (-1 to 1)
		
		private var _lpFilterCutoff		:Number = 	0.0;	// Frequency at which the low-pass filter starts attenuating higher frequencies (0 to 1)
		private var _lpFilterCutoffSweep:Number = 	0.0;	// Sweeps the low-pass cutoff up or down (-1 to 1)
		private var _lpFilterResonance	:Number = 	0.0;	// Changes the attenuation rate for the low-pass filter, changing the timbre (0 to 1)
		
		private var _hpFilterCutoff		:Number = 	0.0;	// Frequency at which the high-pass filter starts attenuating lower frequencies (0 to 1)
		private var _hpFilterCutoffSweep:Number = 	0.0;	// Sweeps the high-pass cutoff up or down (0 to 1)
		
		private var _overtones		:Number = 	0.0;	// Frequency at which the high-pass filter starts attenuating lower frequencies (0 to 1)
		private var _overtoneFalloff:Number = 	0.0;	// Sweeps the high-pass cutoff up or down (0 to 1)
		
		private var _lockedParams : Vector.<String> = new Vector.<String>(); // stores list of strings, these strings represent parameters that will be locked during randomization/mutation
		
		//--------------------------------------------------------------------------
		//
		//  Getters / Setters
		//
		//--------------------------------------------------------------------------
		
		/** Shape of the wave (0:square, 1:saw, 2:sin, 3:noise, or 4:triangle) */
		public function get waveType():uint { return _waveType; }
		public function set waveType(value:uint):void { _waveType = value > 5 ? 0 : value; paramsDirty = true; }
		
		/** Overall volume of the sound (0 to 1) */
		public function get masterVolume():Number { return _masterVolume; }
		public function set masterVolume(value:Number):void { _masterVolume = clamp1(value); paramsDirty = true; }
		
		/** Length of the volume envelope attack (0 to 1) */
		public function get attackTime():Number { return _attackTime; }
		public function set attackTime(value:Number):void { _attackTime = clamp1(value); paramsDirty = true; }
		
		/** Length of the volume envelope sustain (0 to 1) */
		public function get sustainTime():Number { return _sustainTime; }
		public function set sustainTime(value:Number):void { _sustainTime = clamp1(value); paramsDirty = true; }
		
		/** Tilts the sustain envelope for more 'pop' (0 to 1) */
		public function get sustainPunch():Number { return _sustainPunch; }
		public function set sustainPunch(value:Number):void { _sustainPunch = clamp1(value); paramsDirty = true; }
		
		/** Length of the volume envelope decay (yes, I know it's called release) (0 to 1) */
		public function get decayTime():Number { return _decayTime; }
		public function set decayTime(value:Number):void { _decayTime = clamp1(value); paramsDirty = true; }

		/** Base note of the sound (0 to 1) */
		public function get startFrequency():Number { return _startFrequency; }
		public function set startFrequency(value:Number):void { _startFrequency = clamp1(value); paramsDirty = true; }
		
		/** If sliding, the sound will stop at this frequency, to prevent really low notes (0 to 1) */
		public function get minFrequency():Number { return _minFrequency; }
		public function set minFrequency(value:Number):void { _minFrequency = clamp1(value); paramsDirty = true; }
		
		/** Slides the note up or down (-1 to 1) */
		public function get slide():Number { return _slide; }
		public function set slide(value:Number):void { _slide = clamp2(value); paramsDirty = true; }
		
		/** Accelerates the slide (-1 to 1) */
		public function get deltaSlide():Number { return _deltaSlide; }
		public function set deltaSlide(value:Number):void { _deltaSlide = clamp2(value); paramsDirty = true; }
		
		/** Strength of the vibrato effect (0 to 1) */
		public function get vibratoDepth():Number { return _vibratoDepth; }
		public function set vibratoDepth(value:Number):void { _vibratoDepth = clamp1(value); paramsDirty = true; }
		
		/** Speed of the vibrato effect (i.e. frequency) (0 to 1) */
		public function get vibratoSpeed():Number { return _vibratoSpeed; }
		public function set vibratoSpeed(value:Number):void { _vibratoSpeed = clamp1(value); paramsDirty = true; }
		
		/** Shift in note, either up or down (0 to 1) */
		public function get changePeriod():Number { return _changePeriod; }
		public function set changePeriod(value:Number):void { _changePeriod = clamp2(value); paramsDirty = true; }
		
		
		/** Shift in note, either up or down (-1 to 1) */
		public function get changeAmount():Number { return _changeAmount; }
		public function set changeAmount(value:Number):void { _changeAmount = clamp2(value); paramsDirty = true; }
		
		/** Shift in note, either up or down (-1 to 1) */
		public function get changeAmount2():Number { return _changeAmount2; }
		public function set changeAmount2(value:Number):void { _changeAmount2 = clamp2(value); paramsDirty = true; }
		
		/** How fast the note shift happens (only happens once) (0 to 1) */
		public function get changeSpeed():Number { return _changeSpeed; }
		public function set changeSpeed(value:Number):void { _changeSpeed = clamp1(value); paramsDirty = true; }
		
		/** How fast the note shift happens (only happens once) (0 to 1) */
		public function get changeSpeed2():Number { return _changeSpeed2; }
		public function set changeSpeed2(value:Number):void { _changeSpeed2 = clamp1(value); paramsDirty = true; }
		
		/** Controls the ratio between the up and down states of the square wave, changing the tibre (0 to 1) */
		public function get squareDuty():Number { return _squareDuty; }
		public function set squareDuty(value:Number):void { _squareDuty = clamp1(value); paramsDirty = true; }
		
		/** Sweeps the duty up or down (-1 to 1) */
		public function get dutySweep():Number { return _dutySweep; }
		public function set dutySweep(value:Number):void { _dutySweep = clamp2(value); paramsDirty = true; }
		
		/** Speed of the note repeating - certain variables are reset each time (0 to 1) */
		public function get repeatSpeed():Number { return _repeatSpeed; }
		public function set repeatSpeed(value:Number):void { _repeatSpeed = clamp1(value); paramsDirty = true; }
		
		/** Offsets a second copy of the wave by a small phase, changing the tibre (-1 to 1) */
		public function get phaserOffset():Number { return _phaserOffset; }
		public function set phaserOffset(value:Number):void { _phaserOffset = clamp2(value); paramsDirty = true; }
		
		/** Sweeps the phase up or down (-1 to 1) */
		public function get phaserSweep():Number { return _phaserSweep; }
		public function set phaserSweep(value:Number):void { _phaserSweep = clamp2(value); paramsDirty = true; }
		
		/** Frequency at which the low-pass filter starts attenuating higher frequencies (0 to 1) */
		public function get lpFilterCutoff():Number { return _lpFilterCutoff; }
		public function set lpFilterCutoff(value:Number):void { _lpFilterCutoff = clamp1(value); paramsDirty = true; }
		
		/** Sweeps the low-pass cutoff up or down (-1 to 1) */
		public function get lpFilterCutoffSweep():Number { return _lpFilterCutoffSweep; }
		public function set lpFilterCutoffSweep(value:Number):void { _lpFilterCutoffSweep = clamp2(value); paramsDirty = true; }
		
		/** Changes the attenuation rate for the low-pass filter, changing the timbre (0 to 1) */
		public function get lpFilterResonance():Number { return _lpFilterResonance; }
		public function set lpFilterResonance(value:Number):void { _lpFilterResonance = clamp1(value); paramsDirty = true; }
		
		/** Frequency at which the high-pass filter starts attenuating lower frequencies (0 to 1) */
		public function get hpFilterCutoff():Number { return _hpFilterCutoff; }
		public function set hpFilterCutoff(value:Number):void { _hpFilterCutoff = clamp1(value); paramsDirty = true; }
		
		/** Sweeps the high-pass cutoff up or down (-1 to 1) */
		public function get hpFilterCutoffSweep():Number { return _hpFilterCutoffSweep; }
		public function set hpFilterCutoffSweep(value:Number):void { _hpFilterCutoffSweep = clamp2(value); paramsDirty = true; }
		
		/** Sweeps the high-pass cutoff up or down (-1 to 1) */
		public function get overtones():Number { return _overtones; }
		public function set overtones(value:Number):void { _overtones = clamp2(value); paramsDirty = true; }
		
		public function get overtoneFalloff():Number { return _overtoneFalloff; }
		public function set overtoneFalloff(value:Number):void { _overtoneFalloff = clamp2(value); paramsDirty = true; }
		
		/** Returns true if this parameter is locked */
		public function lockedParam(param:String):Boolean
		{
			return _lockedParams.indexOf(param)>=0;
		}
		
		public function setParamLocked(param:String, locked:Boolean):void
		{
			var index:int = _lockedParams.indexOf(param);
			
			if (locked)
			{
				if (index==-1)
				{
					_lockedParams.push(param);
					paramsDirty = true;
				}
			}
			else
			{
				if (index>=0)
				{
					_lockedParams.splice(index,1);
					paramsDirty = true;
				}
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  Generator Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Sets the parameters to generate a pickup/coin sound
		 */
		public function generatePickupCoin():void
		{
			resetParams();
			
			_startFrequency = 0.4 + Math.random() * 0.5;
			
			_sustainTime = Math.random() * 0.1;
			_decayTime = 0.1 + Math.random() * 0.4;
			_sustainPunch = 0.3 + Math.random() * 0.3;
			
			if(Math.random() < 0.5) 
			{
				_changeSpeed = 0.5 + Math.random() * 0.2;
				_changeAmount = 0.2 + Math.random() * 0.4;
			}
			
		}
		
		/**
		 * Sets the parameters to generate a laser/shoot sound
		 */
		public function generateLaserShoot():void
		{
			resetParams();
			
			_waveType = uint(Math.random() * 3);
			if(_waveType == 2 && Math.random() < 0.5) _waveType = uint(Math.random() * 2);
			
			_startFrequency = 0.5 + Math.random() * 0.5;
			_minFrequency = _startFrequency - 0.2 - Math.random() * 0.6;
			if(_minFrequency < 0.2) _minFrequency = 0.2;
			
			_slide = -0.15 - Math.random() * 0.2;
			
			if(Math.random() < 0.33)
			{
				_startFrequency = 0.3 + Math.random() * 0.6;
				_minFrequency = Math.random() * 0.1;
				_slide = -0.35 - Math.random() * 0.3;
			}
			
			if(Math.random() < 0.5) 
			{
				_squareDuty = Math.random() * 0.5;
				_dutySweep = Math.random() * 0.2;
			}
			else
			{
				_squareDuty = 0.4 + Math.random() * 0.5;
				_dutySweep =- Math.random() * 0.7;	
			}
			
			_sustainTime = 0.1 + Math.random() * 0.2;
			_decayTime = Math.random() * 0.4;
			if(Math.random() < 0.5) _sustainPunch = Math.random() * 0.3;
			
			if(Math.random() < 0.33)
			{
				_phaserOffset = Math.random() * 0.2;
				_phaserSweep = -Math.random() * 0.2;
			}
			
			if(Math.random() < 0.5) _hpFilterCutoff = Math.random() * 0.3;
		}
		
		/**
		 * Sets the parameters to generate an explosion sound
		 */
		public function generateExplosion():void
		{
			resetParams();
			_waveType = 3;
			
			if(Math.random() < 0.5)
			{
				_startFrequency = 0.1 + Math.random() * 0.4;
				_slide = -0.1 + Math.random() * 0.4;
			}
			else
			{
				_startFrequency = 0.2 + Math.random() * 0.7;
				_slide = -0.2 - Math.random() * 0.2;
			}
			
			_startFrequency *= _startFrequency;
			
			if(Math.random() < 0.2) _slide = 0.0;
			if(Math.random() < 0.33) _repeatSpeed = 0.3 + Math.random() * 0.5;
			
			_sustainTime = 0.1 + Math.random() * 0.3;
			_decayTime = Math.random() * 0.5;
			_sustainPunch = 0.2 + Math.random() * 0.6;
			
			if(Math.random() < 0.5)
			{
				_phaserOffset = -0.3 + Math.random() * 0.9;
				_phaserSweep = -Math.random() * 0.3;
			}
			
			if(Math.random() < 0.33)
			{
				_changeSpeed = 0.6 + Math.random() * 0.3;
				_changeAmount = 0.8 - Math.random() * 1.6;
			}
		}
		
		/**
		 * Sets the parameters to generate a powerup sound
		 */
		public function generatePowerup():void
		{
			resetParams();
			
			if(Math.random() < 0.5) _waveType = 1;
			else 					_squareDuty = Math.random() * 0.6;
			
			if(Math.random() < 0.5)
			{
				_startFrequency = 0.2 + Math.random() * 0.3;
				_slide = 0.1 + Math.random() * 0.4;
				_repeatSpeed = 0.4 + Math.random() * 0.4;
			}
			else
			{
				_startFrequency = 0.2 + Math.random() * 0.3;
				_slide = 0.05 + Math.random() * 0.2;
				
				if(Math.random() < 0.5)
				{
					_vibratoDepth = Math.random() * 0.7;
					_vibratoSpeed = Math.random() * 0.6;
				}
			}
			
			_sustainTime = Math.random() * 0.4;
			_decayTime = 0.1 + Math.random() * 0.4;
		}
		
		/**
		 * Sets the parameters to generate a hit/hurt sound
		 */
		public function generateHitHurt():void
		{
			resetParams();
			
			_waveType = uint(Math.random() * 3);
			if(_waveType == 2) _waveType = 3;
			else if(_waveType == 0) _squareDuty = Math.random() * 0.6;
			
			_startFrequency = 0.2 + Math.random() * 0.6;
			_slide = -0.3 - Math.random() * 0.4;
			
			_sustainTime = Math.random() * 0.1;
			_decayTime = 0.1 + Math.random() * 0.2;
			
			if(Math.random() < 0.5) _hpFilterCutoff = Math.random() * 0.3;
		}
		
		/**
		 * Sets the parameters to generate a jump sound
		 */
		public function generateJump():void
		{
			resetParams();
			
			_waveType = 0;
			_squareDuty = Math.random() * 0.6;
			_startFrequency = 0.3 + Math.random() * 0.3;
			_slide = 0.1 + Math.random() * 0.2;
			
			_sustainTime = 0.1 + Math.random() * 0.3;
			_decayTime = 0.1 + Math.random() * 0.2;
			
			if(Math.random() < 0.5) _hpFilterCutoff = Math.random() * 0.3;
			if(Math.random() < 0.5) _lpFilterCutoff = 1.0 - Math.random() * 0.6;
		}
		
		/**
		 * Sets the parameters to generate a blip/select sound
		 */
		public function generateBlipSelect():void
		{
			resetParams();
			
			_waveType = uint(Math.random() * 2);
			if(_waveType == 0) _squareDuty = Math.random() * 0.6;
			
			_startFrequency = 0.2 + Math.random() * 0.4;
			
			_sustainTime = 0.1 + Math.random() * 0.1;
			_decayTime = Math.random() * 0.2;
			_hpFilterCutoff = 0.1;
		}
		
		/**
		 * Resets the parameters, used at the start of each generate function
		 */
		protected function resetParams():void
		{
			paramsDirty = true;
			
			_waveType = 0;
			_startFrequency = 0.3;
			_minFrequency = 0.0;
			_slide = 0.0;
			_deltaSlide = 0.0;
			_squareDuty = 0.0;
			_dutySweep = 0.0;
			
			_vibratoDepth = 0.0;
			_vibratoSpeed = 0.0;
			
			_attackTime = 0.0;
			_sustainTime = 0.3;
			_decayTime = 0.4;
			_sustainPunch = 0.0;
			
			_lpFilterResonance = 0.0;
			_lpFilterCutoff = 1.0;
			_lpFilterCutoffSweep = 0.0;
			_hpFilterCutoff = 0.0;
			_hpFilterCutoffSweep = 0.0;
			
			_phaserOffset = 0.0;
			_phaserSweep = 0.0;
			
			_repeatSpeed = 0.0;
			
			_changePeriod = 1.0;
			
			_changeSpeed = 0.0;
			_changeAmount = 0.0;
			
			_changeSpeed2 = 0.0;
			_changeAmount2 = 0.0;
			
			_overtoneFalloff=0;
			_overtones=0;
			
			_lockedParams = new Vector.<String>();
			
		}
		
		//--------------------------------------------------------------------------
		//
		//  Randomize Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Randomly adjusts the parameters ever so slightly
		 */
		public function mutate(mutation:Number = 0.05):void
		{			
	
			if (!lockedParam("startFrequency"))
				if (Math.random() < 0.5) startFrequency += 		Math.random() * mutation*2 - mutation;			
			if (!lockedParam("minFrequency"))
				if (Math.random() < 0.5) minFrequency += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("slide"))
				if (Math.random() < 0.5) slide += 				Math.random() * mutation*2 - mutation;
			if (!lockedParam("deltaSlide"))
				if (Math.random() < 0.5) deltaSlide += 			Math.random() * mutation*2 - mutation;
			if (!lockedParam("squareDuty"))
				if (Math.random() < 0.5) squareDuty += 			Math.random() * mutation*2 - mutation;
			if (!lockedParam("dutySweep"))
				if (Math.random() < 0.5) dutySweep += 			Math.random() * mutation*2 - mutation;
			if (!lockedParam("vibratoDepth"))
				if (Math.random() < 0.5) vibratoDepth += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("vibratoSpeed"))
				if (Math.random() < 0.5) vibratoSpeed += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("attackTime"))
				if (Math.random() < 0.5) attackTime += 			Math.random() * mutation*2 - mutation;
			if (!lockedParam("sustainTime"))
				if (Math.random() < 0.5) sustainTime += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("decayTime"))
				if (Math.random() < 0.5) decayTime += 			Math.random() * mutation*2 - mutation;
			if (!lockedParam("decayTime"))
				if (Math.random() < 0.5) sustainPunch += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("lpFilterCutoff"))
				if (Math.random() < 0.5) lpFilterCutoff += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("lpFilterCutoffSweep"))
				if (Math.random() < 0.5) lpFilterCutoffSweep += Math.random() * mutation*2 - mutation;
			if (!lockedParam("lpFilterResonance"))
				if (Math.random() < 0.5) lpFilterResonance += 	Math.random() * mutation*2 - mutation;
			if (!lockedParam("hpFilterCutoff"))
				if (Math.random() < 0.5) hpFilterCutoff += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("hpFilterCutoffSweep"))
				if (Math.random() < 0.5) hpFilterCutoffSweep += Math.random() * mutation*2 - mutation;
			if (!lockedParam("phaserOffset"))
				if (Math.random() < 0.5) phaserOffset += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("phaserSweep"))
				if (Math.random() < 0.5) phaserSweep += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("repeatSpeed"))
				if (Math.random() < 0.5) repeatSpeed += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("changePeriod"))
				if (Math.random() < 0.5) changePeriod += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("changeSpeed"))
				if (Math.random() < 0.5) changeSpeed += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("changeAmount"))
				if (Math.random() < 0.5) changeAmount += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("changeSpeed2"))
				if (Math.random() < 0.5) changeSpeed2 += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("changeAmount2"))
				if (Math.random() < 0.5) changeAmount2 += 		Math.random() * mutation*2 - mutation;
			if (!lockedParam("overtoneFalloff"))
				if (Math.random() < 0.5) overtoneFalloff += 	Math.random() * mutation*2 - mutation;
			if (!lockedParam("overtones"))
				if (Math.random() < 0.5) overtones += 			Math.random() * mutation*2 - mutation;
		}
		
		/**
		 * Sets all parameters to random values
		 * If passed null, no fields constrained
		 */
		public function randomize():void
		{
		
			paramsDirty = true;
			
			if (!lockedParam("waveType"))
				_waveType = uint(Math.random() * 6);
			
			if (!lockedParam("attackTime"))
				_attackTime =  		pow(Math.random()*2-1, 4);
			
			if (!lockedParam("sustainTime"))
				_sustainTime =  	pow(Math.random()*2-1, 2);
						
			if (!lockedParam("sustainPunch"))
				_sustainPunch =  	pow(Math.random()*0.8, 2);
						
			if (!lockedParam("decayTime"))
				_decayTime =  		Math.random();
			
			
			if (!lockedParam("startFrequency"))
				_startFrequency =  	(Math.random() < 0.5) ? pow(Math.random()*2-1, 2) : (pow(Math.random() * 0.5, 3) + 0.5);
			
			if (!lockedParam("minFrequency"))
				_minFrequency =  	0.0;
			
			if (!lockedParam("slide"))
				_slide =  			pow(Math.random()*2-1, 5);
			if (!lockedParam("deltaSlide"))
				_deltaSlide =  		pow(Math.random()*2-1, 3);
			
			if (!lockedParam("vibratoDepth"))
				_vibratoDepth =  	pow(Math.random()*2-1, 3);
			if (!lockedParam("vibratoSpeed"))
				_vibratoSpeed =  	Math.random()*2-1;
			
			if (!lockedParam("changePeriod"))
				_changePeriod = Math.random();
			
			if (!lockedParam("changeAmount"))
				_changeAmount =  	Math.random()*2-1;
			if (!lockedParam("changeSpeed"))
				_changeSpeed =  	Math.random()*2-1;
			
			if (!lockedParam("changeAmount2"))
				_changeAmount2 =  	Math.random()*2-1;
			if (!lockedParam("changeSpeed2"))
				_changeSpeed2 =  	Math.random()*2-1;
			
			if (!lockedParam("squareDuty"))
				_squareDuty =  		Math.random()*2-1;
			if (!lockedParam("dutySweep"))
				_dutySweep =  		pow(Math.random()*2-1, 3);
			
			if (!lockedParam("repeatSpeed"))
				_repeatSpeed =  	Math.random()*2-1;
			
			if (!lockedParam("phaserOffset"))
				_phaserOffset =  	pow(Math.random()*2-1, 3);
			if (!lockedParam("phaserSweep"))
				_phaserSweep =  	pow(Math.random()*2-1, 3);
			
			if (!lockedParam("lpFilterCutoff"))
				_lpFilterCutoff =  		1 - pow(Math.random(), 3);
			if (!lockedParam("lpFilterCutoffSweep"))
				_lpFilterCutoffSweep = 	pow(Math.random()*2-1, 3);
			if (!lockedParam("lpFilterResonance"))
				_lpFilterResonance =  	Math.random()*2-1;
			
			if (!lockedParam("hpFilterCutoff"))
				_hpFilterCutoff =  		pow(Math.random(), 5);
			if (!lockedParam("hpFilterCutoffSweep"))
				_hpFilterCutoffSweep = 	pow(Math.random()*2-1, 5);
			
			if (!lockedParam("overtones"))
				_overtones = Math.random();
			if (!lockedParam("overtoneFalloff"))
				_overtoneFalloff = Math.random();
			
			if ((!lockedParam("sustainTime")) && (!lockedParam("decayTime")))
			{
				if(_attackTime + _sustainTime + _decayTime < 0.2)
				{
					_sustainTime = 0.2 + Math.random() * 0.3;
					_decayTime = 0.2 + Math.random() * 0.3;
				}
			}
			
			if (!lockedParam("slide"))
			{
				if((_startFrequency > 0.7 && _slide > 0.2) || (_startFrequency < 0.2 && _slide < -0.05)) 
				{
					_slide = -_slide;
				}
			}
			
			if (!lockedParam("lpFilterCutoffSweep"))
			{
				if(_lpFilterCutoff < 0.1 && _lpFilterCutoffSweep < -0.05) 
				{
					_lpFilterCutoffSweep = -_lpFilterCutoffSweep;
				}
			}
		}
		
		
		//--------------------------------------------------------------------------
		//	
		//  Settings String Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Returns a string representation of the parameters for copy/paste sharing
		 * @return	A comma-delimited list of parameter values
		 */
		public function getSettingsString():String
		{
			var string:String = String(waveType);
			string += "," + to4DP(_attackTime) + 			"," + to4DP(_sustainTime) 
					+ "," + to4DP(_sustainPunch) + 			"," + to4DP(_decayTime) 
					+ "," + to4DP(_startFrequency) + 		"," + to4DP(_minFrequency)
					+ "," + to4DP(_slide) + 				"," + to4DP(_deltaSlide)
					+ "," + to4DP(_vibratoDepth) + 			"," + to4DP(_vibratoSpeed)
					+ "," + to4DP(_changePeriod)
					+ "," + to4DP(_changeAmount) + 			"," + to4DP(_changeSpeed)
					+ "," + to4DP(_changeAmount2) + 		"," + to4DP(_changeSpeed2)
					+ "," + to4DP(_squareDuty) + 			"," + to4DP(_dutySweep)
					+ "," + to4DP(_repeatSpeed) + 			"," + to4DP(_phaserOffset)
					+ "," + to4DP(_phaserSweep) + 			"," + to4DP(_lpFilterCutoff)
					+ "," + to4DP(_lpFilterCutoffSweep) + 	"," + to4DP(_lpFilterResonance)
					+ "," + to4DP(_hpFilterCutoff)+ 		"," + to4DP(_hpFilterCutoffSweep)
					+ "," + to4DP(_overtones) + 			"," + to4DP(_overtoneFalloff)
					+ "," + to4DP(_masterVolume);
			
			for (var i:int=0;i<this._lockedParams.length;i++)
			{
				string+=","+_lockedParams[i];
			}
			
			return string;
		}
		
		/**
		 * Parses a settings string into the parameters
		 * @param	string	Settings string to parse
		 * @return			If the string successfully parsed
		 */
		public function setSettingsString(string:String):Boolean
		{
			if (string==null)
				return false;
			
			var values:Array = string.split(",");
			
			if (values.length < 29) return false;
			
			waveType = 				uint(values[0]) || 0;
			attackTime =  			Number(values[1]) || 0;
			sustainTime =  			Number(values[2]) || 0;
			sustainPunch =  		Number(values[3]) || 0;
			decayTime =  			Number(values[4]) || 0;
			startFrequency =  		Number(values[5]) || 0;
			minFrequency =  		Number(values[6]) || 0;
			slide =  				Number(values[7]) || 0;
			deltaSlide =  			Number(values[8]) || 0;
			vibratoDepth =  		Number(values[9]) || 0;
			vibratoSpeed =  		Number(values[10]) || 0;
			changePeriod =  		Number(values[11]) || 0;
			changeAmount =  		Number(values[12]) || 0;
			changeSpeed =  			Number(values[13]) || 0;
			changeAmount2 =  		Number(values[14]) || 0;
			changeSpeed2 = 			Number(values[15]) || 0;
			squareDuty =  			Number(values[16]) || 0;
			dutySweep =  			Number(values[17]) || 0;
			repeatSpeed =  			Number(values[18]) || 0;
			phaserOffset =  		Number(values[19]) || 0;
			phaserSweep =  			Number(values[20]) || 0;
			lpFilterCutoff =  		Number(values[21]) || 0;
			lpFilterCutoffSweep =  	Number(values[22]) || 0;
			lpFilterResonance =  	Number(values[23]) || 0;
			hpFilterCutoff =  		Number(values[24]) || 0;
			hpFilterCutoffSweep =  	Number(values[25]) || 0;
			overtones =  			Number(values[26]) || 0;
			overtoneFalloff =  		Number(values[27]) || 0;
			masterVolume = 			Number(values[28]) || 0;
						
			_lockedParams = new Vector.<String>();
			for (var i:int=29;i<values.length;i++)
			{
				_lockedParams.push(values[i]);
			}
			
			return true;
		}   
		
		
		//--------------------------------------------------------------------------
		//	
		//  Copying Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Returns a copy of this SfxrParams with all settings duplicated
		 * @return	A copy of this SfxrParams
		 */
		public function clone():SfxrParams
		{
			var out:SfxrParams = new SfxrParams();
			out.copyFrom(this);		
			
			return out;
		}
		
		/**
		 * Copies parameters from another instance
		 * @param	params	Instance to copy parameters from
		 */
		public function copyFrom(params:SfxrParams, makeDirty:Boolean = false):void
		{
			_waveType = 			params.waveType;
			_attackTime =           params.attackTime;
			_sustainTime =          params.sustainTime;
			_sustainPunch =         params.sustainPunch;
			_decayTime =			params.decayTime;
			_startFrequency = 		params.startFrequency;
			_minFrequency = 		params.minFrequency;
			_slide = 				params.slide;
			_deltaSlide = 			params.deltaSlide;
			_vibratoDepth = 		params.vibratoDepth;
			_vibratoSpeed = 		params.vibratoSpeed;
			_changePeriod = 		params.changePeriod;
			_changeAmount = 		params.changeAmount;
			_changeSpeed = 			params.changeSpeed;
			_changeAmount2 = 		params.changeAmount2;
			_changeSpeed2 = 		params.changeSpeed2;
			_squareDuty = 			params.squareDuty;
			_dutySweep = 			params.dutySweep;
			_repeatSpeed = 			params.repeatSpeed;
			_phaserOffset = 		params.phaserOffset;
			_phaserSweep = 			params.phaserSweep;
			_lpFilterCutoff = 		params.lpFilterCutoff;
			_lpFilterCutoffSweep = 	params.lpFilterCutoffSweep;
			_lpFilterResonance = 	params.lpFilterResonance;
			_hpFilterCutoff = 		params.hpFilterCutoff;
			_hpFilterCutoffSweep = 	params.hpFilterCutoffSweep;
			_overtones = 			params.overtones;
			_overtoneFalloff = 		params.overtoneFalloff;
			_masterVolume = 		params.masterVolume;
			
			if (makeDirty) paramsDirty = true;
		}   
		
		
		//--------------------------------------------------------------------------
		//
		//  Util Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Clams a value to betwen 0 and 1
		 * @param	value	Input value
		 * @return			The value clamped between 0 and 1
		 */
		private function clamp1(value:Number):Number { return (value > 1.0) ? 1.0 : ((value < 0.0) ? 0.0 : value); }
		
		/**
		 * Clams a value to betwen -1 and 1
		 * @param	value	Input value
		 * @return			The value clamped between -1 and 1
		 */
		private function clamp2(value:Number):Number { return (value > 1.0) ? 1.0 : ((value < -1.0) ? -1.0 : value); }
		
		/**
		 * Quick power function
		 * @param	base		Base to raise to power
		 * @param	power		Power to raise base by
		 * @return				The calculated power
		 */
		private function pow(base:Number, power:int):Number
		{
			switch(power)
			{
				case 2: return base*base;
				case 3: return base*base*base;
				case 4: return base*base*base*base;
				case 5: return base*base*base*base*base;
			}
			
			return 1.0;
		}
		
		
		/**
		 * Returns the number as a string to 4 decimal places
		 * @param	value	Number to convert
		 * @return			Number to 4dp as a string
		 */
		private function to4DP(value:Number):String
		{
			if (value < 0.0001 && value > -0.0001) return "";
			
			var string:String = String(value);
			var split:Array = string.split(".");
			if (split.length == 1) 	
			{
				return string;
			}
			else 					
			{
				var out:String = split[0] + "." + split[1].substr(0, 4);
				while (out.substr(out.length - 1, 1) == "0") out = out.substr(0, out.length - 1);
				
				return out;
			}
		}
	}
}