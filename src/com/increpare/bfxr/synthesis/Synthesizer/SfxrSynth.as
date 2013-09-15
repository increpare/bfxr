package com.increpare.bfxr.synthesis.Synthesizer 
{
	import com.increpare.bfxr.synthesis.IPlayerInterface;
	import com.increpare.bfxr.synthesis.WaveWriter;
	
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;

	/**
	 * SfxrSynth
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
	public class SfxrSynth extends EventDispatcher implements IPlayerInterface
	{
		//--------------------------------------------------------------------------
		//
		//  Sound Parameters
		//
		//--------------------------------------------------------------------------
		
		public static const MIN_LENGTH:Number = 0.18;
		public static const version:int = 104;
		public static const CACHED:String = "cached";		// triggered when the synth stored in this is fully cached (either via a cache command, or play()).
		public static const PLAY_COMPLETE:String = "playcomplete";		// triggered when the synth stored in this is fully cached (either via a cache command, or play()).		
		//should be <32
		private const LoResNoisePeriod:int = 8;
		
		private var _params:SfxrParams;	// Params instance
		
		private var _sound:Sound;							// Sound instance used to play the sound
		private var _channel:SoundChannel;					// SoundChannel instance of playing Sound
		
		private var _mutation:Boolean;						// If the current sound playing or caching is a mutation
		
		private var _cachedWave:ByteArray;					// Cached wave data from a cacheSound() call
		private var _cachingNormal:Boolean;					// If the synth is caching a normal sound
		
		private var _cachingMutation:int;					// Current caching ID
		private var _cachedMutation:ByteArray;				// Current caching wave data for mutation
		private var _cachedMutations:Vector.<ByteArray>;	// Cached mutated wave data
		private var _cachedMutationsNum:uint;				// Number of cached mutations
		private var _cachedMutationAmount:Number;			// Amount to mutate during cache
		
		private var _cachingAsync:Boolean;					// If the synth is currently caching asynchronously
		private var _cacheTimePerFrame:uint;				// Maximum time allowed per frame to cache sound asynchronously
		private var _cachedCallback:Function;				// Function to call when finished caching asynchronously
		private var _cacheTicker:Shape;						// Shape used for enterFrame event
		
		private var _waveData:ByteArray;					// Full wave, read out in chuncks by the onSampleData method
		private var _waveDataPos:uint;						// Current position in the waveData
		private var _waveDataLength:uint;					// Number of bytes in the waveData
		private var _waveDataBytes:uint;					// Number of bytes to write to the soundcard
		
		private var _original:SfxrParams;					// Copied properties for mutation base
		
		//--------------------------------------------------------------------------
		//
		//  Synth Variables
		//
		//--------------------------------------------------------------------------
		
		private var _finished:Boolean;						// If the sound has finished
		
		private var _masterVolume:Number;					// masterVolume * masterVolume (for quick calculations)
		
		private var _waveType:uint;							// The type of wave to generate
		
		private var _envelopeVolume:Number;					// Current volume of the envelope
		private var _envelopeStage:int;						// Current stage of the envelope (attack, sustain, decay, end)
		private var _envelopeTime:Number;					// Current time through current enelope stage
		private var _envelopeLength:Number;					// Length of the current envelope stage
		private var _envelopeLength0:Number;				// Length of the attack stage
		private var _envelopeLength1:Number;				// Length of the sustain stage
		private var _envelopeLength2:Number;				// Length of the decay stage
		private var _envelopeOverLength0:Number;			// 1 / _envelopeLength0 (for quick calculations)
		private var _envelopeOverLength1:Number;			// 1 / _envelopeLength1 (for quick calculations)
		private var _envelopeOverLength2:Number;			// 1 / _envelopeLength2 (for quick calculations)
		private var _envelopeFullLength:Number;				// Full length of the volume envelop (and therefore sound)
		
		private var _sustainPunch:Number;					// The punch factor (louder at begining of sustain)
		
		private var _phase:int;								// Phase through the wave
		private var _pos:Number;							// Phase expresed as a Number from 0-1, used for fast sin approx
		private var _period:Number;							// Period of the wave
		private var _periodTemp:Number;						// Period modified by vibrato
		private var _maxPeriod:Number;						// Maximum period before sound stops (from minFrequency)
		
		private var _slide:Number;							// Note slide
		private var _deltaSlide:Number;						// Change in slide
		private var _minFreqency:Number;					// Minimum frequency before stopping
		private var _muted:Boolean;							// Whether or not min frequency has been attained
		
		
		private var _overtones:int;					// Minimum frequency before stopping
		private var _overtoneFalloff:Number;					// Minimum frequency before stopping
		
		private var _vibratoPhase:Number;					// Phase through the vibrato sine wave
		private var _vibratoSpeed:Number;					// Speed at which the vibrato phase moves
		private var _vibratoAmplitude:Number;				// Amount to change the period of the wave by at the peak of the vibrato wave
		
		private var _changePeriod:Number;
		private var _changePeriodTime:int;
		
		private var _changeAmount:Number;					// Amount to change the note by
		private var _changeTime:int;						// Counter for the note change
		private var _changeLimit:int;						// Once the time reaches this limit, the note changes
		private var _changeReached:Boolean;
		
		private var _changeAmount2:Number;					// Amount to change the note by
		private var _changeTime2:int;						// Counter for the note change
		private var _changeLimit2:int;						// Once the time reaches this limit, the note changes
		private var _changeReached2:Boolean;
		
		
		private var _squareDuty:Number;						// Offset of center switching point in the square wave
		private var _dutySweep:Number;						// Amount to change the duty by
		
		private var _repeatTime:int;						// Counter for the repeats
		private var _repeatLimit:int;						// Once the time reaches this limit, some of the variables are reset
		
		private var _flanger:Boolean;						// If the flanger is active
		private var _flangerOffset:Number;					// Phase offset for flanger effect
		private var _flangerDeltaOffset:Number;				// Change in phase offset
		private var _flangerInt:int;							// Integer flanger offset, for bit maths
		private var _flangerPos:int;							// Position through the flanger buffer
		private var _flangerBuffer:Vector.<Number>;			// Buffer of wave values used to create the out of phase second wave
		
		private var _filters:Boolean;						// If the filters are active
		private var _lpFilterPos:Number;					// Adjusted wave position after low-pass filter
		private var _lpFilterOldPos:Number;					// Previous low-pass wave position
		private var _lpFilterDeltaPos:Number;				// Change in low-pass wave position, as allowed by the cutoff and damping
		private var _lpFilterCutoff:Number;					// Cutoff multiplier which adjusts the amount the wave position can move
		private var _lpFilterDeltaCutoff:Number;			// Speed of the low-pass cutoff multiplier
		private var _lpFilterDamping:Number;				// Damping muliplier which restricts how fast the wave position can move
		private var _lpFilterOn:Boolean;					// If the low pass filter is active
		
		private var _hpFilterPos:Number;					// Adjusted wave position after high-pass filter
		private var _hpFilterCutoff:Number;					// Cutoff multiplier which adjusts the amount the wave position can move
		private var _hpFilterDeltaCutoff:Number;			// Speed of the high-pass cutoff multiplier
		
		private var _noiseBuffer:Vector.<Number>;			// Buffer of random values used to generate noise
		private var _pinkNoiseBuffer:Vector.<Number>;			// Buffer of random values used to generate noise
		private var _loResNoiseBuffer:Vector.<Number>;			// Buffer of random values used to generate noise
		
		private var _pinkNumber:PinkNumber;
		
		private var _superSample:Number;					// Actual sample writen to the wave
		private var _sample:Number;							// Sub-sample calculated 8 times per actual sample, averaged out to get the super sample
		private var _sampleCount:uint;						// Number of samples added to the buffer sample
		private var _bufferSample:Number;					// Another supersample used to create a 22050Hz wave
		
		private var _bitcrush_freq:Number;					// inversely proportional to the number of samples to skip 
		private var _bitcrush_freq_sweep:Number;			// change of the above
		private var _bitcrush_phase:Number;					// samples when this > 1
		private var _bitcrush_last:Number;					// last sample value
		
		private var _compression_factor:Number;
		
		//--------------------------------------------------------------------------
		//	
		//  Getters / Setters
		//
		//--------------------------------------------------------------------------
		
		/** The sound parameters */
		public function get params():SfxrParams { return _params; }
		public function set params(value:SfxrParams):void
		{
			_params = value;
			_params.paramsDirty = true;
		}
		
		private var updateCallback:Function;
		
		public function SfxrSynth()
		{
			params = new SfxrParams();
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Sound Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Plays the sound. If the parameters are dirty, synthesises sound as it plays, caching it for later. 
		 * If they're not, plays from the cached sound. 
		 * Won't play if caching asynchronously. 
		 */
		public function play(updateCallback:Function = null,volume:Number=1):void
		{
			//trace("playing : " + this.params.Serialize());
			
			if (_cachingAsync) return;
			
			this.updateCallback = updateCallback;
			
			stop();
			
			_mutation = false;
			
			if (Dirty()) 
			{
				// Needs to cache new data
				_cachedWave = new ByteArray;
				_cachingNormal = true;
				_waveData = null;
				
				reset(true);
			}
			else
			{
				// Play from cached data
				_waveData = _cachedWave;
				_waveData.position = 0;
				_waveDataLength = _waveData.length;
				_waveDataBytes = 24576;
				_waveDataPos = 0; 
			}
			
			if (!_sound) (_sound = new Sound()).addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			
			_channel = _sound.play(0,0,new SoundTransform(volume));
		}
		
		/**
		 * Plays a mutation of the sound.  If the parameters are dirty, synthesises sound as it plays, caching it for later. 
		 * If they're not, plays from the cached sound. 
		 * Won't play if caching asynchronously. 
		 * @param	mutationAmount	Amount of mutation
		 * @param	mutationsNum	The number of mutations to cache before picking from them
		 */
		public function playMutated(mutationAmount:Number = 0.05, mutationsNum:uint = 15, volume:Number = 1):void
		{
			stop();
			
			if (_cachingAsync) return;
			
			_mutation = true;
			
			_cachedMutationsNum = mutationsNum;
			
			if (_params.paramsDirty || !_cachedMutations) 
			{
				// New set of mutations
				_cachedMutations = new Vector.<ByteArray>();
				_cachingMutation = 0;
			}
			
			if (_cachingMutation != -1)
			{
				// Continuing caching new mutations
				_cachedMutation = new ByteArray;
				_cachedMutations[_cachingMutation] = _cachedMutation;
				_waveData = null;
				
				_original = _params.clone();
				_params.mutate(mutationAmount);
				reset(true);
			}
			else
			{
				// Play from random cached mutation
				_waveData = _cachedMutations[uint(_cachedMutations.length * Math.random())];
				_waveData.position = 0;
				_waveDataLength = _waveData.length;
				_waveDataBytes = 24576;
				_waveDataPos = 0;
			}
			
			if (!_sound) (_sound = new Sound()).addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			
			_channel = _sound.play(0,0,new SoundTransform(volume));
		}
		
		/**
		 * Stops the currently playing sound
		 */
		public function stop():void
		{
			if(_channel) 
			{
				_channel.stop();
				_channel = null;
			}
			
			if(_original)
			{
				_params.copyFrom(_original);
				_original = null;
			}
		}
		
		/**
		 * If there is a cached sound to play, reads out of the data. 
		 * If there isn't, synthesises new chunch of data, caching it as it goes. 
		 * @param	e	SampleDataEvent to write data to
		 */
		private function onSampleData(e:SampleDataEvent):void
		{
			
			if (updateCallback!=null)
			{
				updateCallback(_waveDataPos/(4*44100));
			}
			
			if(_waveData)
			{
				if(_waveDataPos + _waveDataBytes > _waveDataLength) 
				{
					_waveDataBytes = _waveDataLength - _waveDataPos;
					dispatchEvent(new Event(SfxrSynth.PLAY_COMPLETE));	
				}

				if(_waveDataBytes > 0) 
				{
					e.data.writeBytes(_waveData, _waveDataPos, _waveDataBytes);
				}
				
				_waveDataPos += _waveDataBytes;
			}
			else
			{	
				var length:uint;
				var i:uint, l:uint;
				
				if (_mutation)
				{
					if (_original)
					{
						_waveDataPos = _cachedMutation.position;
						
						if (synthWave(_cachedMutation, 3072, true))
						{
							_params.copyFrom(_original);							
							_original = null;
							
							_cachingMutation++;
							
							if ((length = _cachedMutation.length) < 24576)
							{
								// If the sound is smaller than the buffer length, add silence to allow it to play
								_cachedMutation.position = length;														
								while (_cachedMutation.length<24576) _cachedMutation.writeFloat(0.0);
							}
							
							if (_cachingMutation >= _cachedMutationsNum)
							{
								_cachingMutation = -1;
							}
							
							this.dispatchEvent(new Event(SfxrSynth.CACHED));
							dispatchEvent(new Event(SfxrSynth.PLAY_COMPLETE));
							updateCallback=null;
						}
						
						_waveDataBytes = _cachedMutation.length - _waveDataPos;
						
						e.data.writeBytes(_cachedMutation, _waveDataPos, _waveDataBytes);
					}
				}
				else
				{
					if (_cachingNormal)
					{
						_waveDataPos = _cachedWave.position;
						
						if (synthWave(_cachedWave, 3072, true))
						{
							
							// If the sound is smaller than the buffer length, add silence to allow it to play
							while (_cachedWave.length<24576) _cachedWave.writeFloat(0.0);
							
							_cachingNormal = false;							
							
							
							if ((length = _cachedWave.length) < 24576)
							{
								// If the sound is smaller than the buffer length, add silence to allow it to play
								_cachedWave.position = length;														
								while (_cachedWave.length<24576) _cachedWave.writeFloat(0.0);
							}
							
							this.dispatchEvent(new Event(SfxrSynth.CACHED));
							dispatchEvent(new Event(SfxrSynth.PLAY_COMPLETE));
							updateCallback=null;
						}
						
						_waveDataBytes = _cachedWave.length - _waveDataPos;
						
						e.data.writeBytes(_cachedWave, _waveDataPos, _waveDataBytes);
					}
				}
			}
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Cached Sound Methods
		//
		//--------------------------------------------------------------------------
		
		/* whether or not it is cached*/
		public function Dirty():Boolean
		{
			return _params.paramsDirty || _cachingNormal || !_cachedWave;
		}
		
		private function Caching():Boolean
		{
			return _cachingNormal;
		}
		
		public function get cachedWave():ByteArray
		{
			if (Dirty())
				this.cacheSound();
			_cachedWave.position=0;
			return _cachedWave;
		}				
		
		/** PlayerInterface implementation: */
		public function Load(data:String):void
		{
			params.Deserialize(data);
		}
		
		public function Play(volume:Number=1):void
		{			
			if (this._mutation)
			{
				playMutated(0.05,15,volume);
			}
			else
			{
				play(null,volume);
			}
		}
		
		public function Cache():void
		{
			cacheSound();
		}
		
		public function CacheMutations(amount:Number = 0.05,count:int = 16):void
		{
			cacheMutations(count,amount);
		}
		
		public function getCachedWave():ByteArray
		{
			return cachedWave;
		}
		
		public function getCachedMutationCount():int
		{
			return _cachedMutationsNum;
		}
		
		public function getCachedMutationWave(index:int=-1):ByteArray
		{
			if (index==-1)
			{
				index=Math.random()*_cachedMutations.length;
			}
				
			return _cachedMutations[index];
		}		
		
		/**
		 * Cache the sound for speedy playback. 
		 * If a callback is passed in, the caching will be done asynchronously, taking maxTimePerFrame milliseconds 
		 * per frame to cache, them calling the callback when it's done. 
		 * If not, the whole sound is cached imidiately - can freeze the player for a few seconds, especially in debug mode. 
		 * @param	callback			Function to call when the caching is complete
		 * @param	maxTimePerFrame		Maximum time in milliseconds the caching will use per frame
		 */
		public function cacheSound(callback:Function = null, maxTimePerFrame:uint = 5):void
		{
			if (!Dirty())
				return;
			
			stop();
			
			if (_cachingAsync) return;
			
			reset(true);
			
			_cachedWave = new ByteArray();
			
			if (callback!=null) 
			{
				_mutation = false;
				_cachingNormal = true;
				_cachingAsync = true;
				_cacheTimePerFrame = maxTimePerFrame;
				
				_cachedCallback = callback;
				
				if (!_cacheTicker) _cacheTicker = new Shape;
				
				_cacheTicker.addEventListener(Event.ENTER_FRAME, cacheSection);
			}
			else
			{
				_cachingNormal = false;
				_cachingAsync = false;
				
				synthWave(_cachedWave, _envelopeFullLength, true);
				
				var length:uint = _cachedWave.length;
				
				if(length < 24576)
				{
					// If the sound is smaller than the buffer length, add silence to allow it to play
					_cachedWave.position = length;
					while (_cachedWave.length<24576) _cachedWave.writeFloat(0.0);
				}
				
				this.dispatchEvent(new Event(SfxrSynth.CACHED));
				dispatchEvent(new Event(SfxrSynth.PLAY_COMPLETE));
			}
		}
		
		/**
		 * Caches a series of mutations on the source sound. 
		 * If a callback is passed in, the caching will be done asynchronously, taking maxTimePerFrame milliseconds 
		 * per frame to cache, them calling the callback when it's done. 
		 * If not, the whole sound is cached imidiately - can freeze the player for a few seconds, especially in debug mode. 
		 * @param	mutationsNum		Number of mutations to cache
		 * @param	mutationAmount		Amount of mutation
		 * @param	callback			Function to call when the caching is complete
		 * @param	maxTimePerFrame		Maximum time in milliseconds the caching will use per frame
		 */
		public function cacheMutations(mutationsNum:uint, mutationAmount:Number = 0.05, callback:Function = null, maxTimePerFrame:uint = 5):void
		{
			stop();
			
			if (_cachingAsync) 
			{
				return;
			}
			
			_cachedMutationsNum = mutationsNum;
			_cachedMutations = new Vector.<ByteArray>();
			
			_mutation = true;
			
			if (callback!=null)
			{			
				_cachingMutation = 0;
				_cachedMutation = new ByteArray;
				_cachedMutations[0] = _cachedMutation;
				_cachedMutationAmount = mutationAmount;
				
				
				_original = _params.clone();
				_params.mutate(mutationAmount);
				
				reset(true);
				
				_cachingAsync = true;
				_cacheTimePerFrame = maxTimePerFrame;
				
				_cachedCallback = callback;
				
				if (!_cacheTicker) _cacheTicker = new Shape;
				
				_cacheTicker.addEventListener(Event.ENTER_FRAME, cacheSection);
			}
			else
			{
				var original:SfxrParams = _params.clone();
				
				for(var i:uint = 0; i < _cachedMutationsNum; i++)
				{
					_params.mutate(mutationAmount);
					cacheSound();
					_cachedMutations[i] = _cachedWave;
					_params.copyFrom(original);
				}
				
				_cachingMutation = -1;
			}
		}
		
		/**
		 * Performs the asynchronous cache, working for up to _cacheTimePerFrame milliseconds per frame
		 * @param	e	enterFrame event
		 */
		private function cacheSection(e:Event):void 
		{
			var cacheStartTime:uint = getTimer();
			
			while (getTimer() - cacheStartTime < _cacheTimePerFrame)
			{
				if (_mutation)
				{
					_waveDataPos = _cachedMutation.position;
					
					if (synthWave(_cachedMutation, 500, true))
					{						
						_params.copyFrom(_original);
						_params.mutate(_cachedMutationAmount);
						reset(true);
						
						_cachingMutation++;
						_cachedMutation = new ByteArray;
						_cachedMutations[_cachingMutation] = _cachedMutation;
						
						if (_cachingMutation >= _cachedMutationsNum)
						{
							_cachingMutation = -1;
							_cachingAsync = false;
							
							_params.paramsDirty = false;
							
							_cachedCallback();
							_cachedCallback = null;
							_cacheTicker.removeEventListener(Event.ENTER_FRAME, cacheSection);
							
							this.dispatchEvent(new Event(SfxrSynth.CACHED));
							dispatchEvent(new Event(SfxrSynth.PLAY_COMPLETE));
							
							return;
						}
					}
				}
				else
				{
					_waveDataPos = _cachedWave.position;
					
					if (synthWave(_cachedWave, 500, true))
					{
						_cachingNormal = false;
						_cachingAsync = false;
						
						_cachedCallback();
						_cachedCallback = null;
						_cacheTicker.removeEventListener(Event.ENTER_FRAME, cacheSection);
						
						this.dispatchEvent(new Event(SfxrSynth.CACHED));
						dispatchEvent(new Event(SfxrSynth.PLAY_COMPLETE));
						
						return;
					}
				}
			}
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Synth Methods
		//
		//--------------------------------------------------------------------------
		
		/* Length in quarter-seconds */
		public function GetLength():Number
		{			
			clampTotalLength();
			
			var p:SfxrParams = _params;
			var envelopeLength0:Number = p.getParam("attackTime") * p.getParam("attackTime") * 100000.0;
			var envelopeLength1:Number = p.getParam("sustainTime") * p.getParam("sustainTime") * 100000.0;
			var envelopeLength2:Number = p.getParam("decayTime") * p.getParam("decayTime") * 100000.0 + 10;
			return (envelopeLength0 + envelopeLength1 + envelopeLength2)*2/(44100);

		}
		
		private function clampTotalLength():void
		{
			var p:SfxrParams = _params;
			var totalTime:Number = p.getParam("attackTime") + p.getParam("sustainTime") + p.getParam("decayTime");
			if (totalTime < MIN_LENGTH ) 
			{
				var multiplier:Number = MIN_LENGTH / totalTime;
				p.setParam("attackTime",p.getParam("attackTime") * multiplier);
				p.setParam("sustainTime",p.getParam("sustainTime") * multiplier);
				p.setParam("decayTime",p.getParam("decayTime") * multiplier);
			}
		}
		
		/**
		 * Resets the runing variables from the params
		 * Used once at the start (total reset) and for the repeat effect (partial reset)
		 * @param	totalReset	If the reset is total
		 */
		private function reset(totalReset:Boolean):void
		{
			// Shorter reference
			var p:SfxrParams = _params;
			
			_period = 100.0 / (p.getParam("startFrequency") * p.getParam("startFrequency") + 0.001);
			_maxPeriod = 100.0 / (p.getParam("minFrequency") * p.getParam("minFrequency") + 0.001);
			
			
			_slide = 1.0 - p.getParam("slide") * p.getParam("slide") * p.getParam("slide") * 0.01;
			_deltaSlide = -p.getParam("deltaSlide") * p.getParam("deltaSlide") * p.getParam("deltaSlide") * 0.000001;
			
			if (int(p.getParam("waveType")) == 0)
			{
				_squareDuty = 0.5 - p.getParam("squareDuty") * 0.5;
				_dutySweep = -p.getParam("dutySweep") * 0.00005;
			}
			
			_changePeriod = Math.max(((1-p.getParam("changeRepeat"))+0.1)/1.1) * 20000 + 32;
			_changePeriodTime = 0;
			
			if (p.getParam("changeAmount") > 0.0) 	_changeAmount = 1.0 - p.getParam("changeAmount") * p.getParam("changeAmount") * 0.9;
			else 						_changeAmount = 1.0 + p.getParam("changeAmount") * p.getParam("changeAmount") * 10.0;
			
			_changeTime = 0;
			_changeReached=false;
			
			if(p.getParam("changeSpeed") == 1.0) 	_changeLimit = 0;
			else 						_changeLimit = (1.0 - p.getParam("changeSpeed")) * (1.0 - p.getParam("changeSpeed")) * 20000 + 32;
			
			
			if (p.getParam("changeAmount2") > 0.0) 	_changeAmount2 = 1.0 - p.getParam("changeAmount2") * p.getParam("changeAmount2") * 0.9;
			else 						_changeAmount2 = 1.0 + p.getParam("changeAmount2") * p.getParam("changeAmount2") * 10.0;
			
			
			_changeTime2 = 0;			
			_changeReached2=false;
			
			if(p.getParam("changeSpeed2") == 1.0) 	_changeLimit2 = 0;
			else 						_changeLimit2 = (1.0 - p.getParam("changeSpeed2")) * (1.0 - p.getParam("changeSpeed2")) * 20000 + 32;
			
			_changeLimit*=(1-p.getParam("changeRepeat")+0.1)/1.1;
			_changeLimit2*=(1-p.getParam("changeRepeat")+0.1)/1.1;
			
			if(totalReset)
			{
				p.paramsDirty = false;
				
				_masterVolume = p.getParam("masterVolume") * p.getParam("masterVolume");
				
				_waveType = uint(p.getParam("waveType"));
				
				if (p.getParam("sustainTime") < 0.01) p.setParam("sustainTime", 0.01);
				
				clampTotalLength();
				
				_sustainPunch = p.getParam("sustainPunch");
				
				_phase = 0;
				
				_minFreqency = p.getParam("minFrequency");
				_muted=false;
				_overtones = p.getParam("overtones")*10;
				_overtoneFalloff = p.getParam("overtoneFalloff");
								
				_bitcrush_freq = 1 - Math.pow(p.getParam("bitCrush"),1.0/3.0);				
				_bitcrush_freq_sweep = -p.getParam("bitCrushSweep")* 0.000015;
				_bitcrush_phase=0;
				_bitcrush_last=0;				
				
				_compression_factor = 1/(1+4*p.getParam("compressionAmount"));
				
				_filters = p.getParam("lpFilterCutoff") != 1.0 || p.getParam("hpFilterCutoff") != 0.0;				
				
				_lpFilterPos = 0.0;
				_lpFilterDeltaPos = 0.0;
				_lpFilterCutoff = p.getParam("lpFilterCutoff") * p.getParam("lpFilterCutoff") * p.getParam("lpFilterCutoff") * 0.1;
				_lpFilterDeltaCutoff = 1.0 + p.getParam("lpFilterCutoffSweep") * 0.0001;
				_lpFilterDamping = 5.0 / (1.0 + p.getParam("lpFilterResonance") * p.getParam("lpFilterResonance") * 20.0) * (0.01 + _lpFilterCutoff);
				if (_lpFilterDamping > 0.8) _lpFilterDamping = 0.8;
				_lpFilterDamping = 1.0 - _lpFilterDamping;
				_lpFilterOn = p.getParam("lpFilterCutoff") != 1.0;
				
				_hpFilterPos = 0.0;
				_hpFilterCutoff = p.getParam("hpFilterCutoff") * p.getParam("hpFilterCutoff") * 0.1;
				_hpFilterDeltaCutoff = 1.0 + p.getParam("hpFilterCutoffSweep") * 0.0003;
				
				_vibratoPhase = 0.0;
				_vibratoSpeed = p.getParam("vibratoSpeed") * p.getParam("vibratoSpeed") * 0.01;
				_vibratoAmplitude = p.getParam("vibratoDepth") * 0.5;
				
				_envelopeVolume = 0.0;
				_envelopeStage = 0;
				_envelopeTime = 0;
				_envelopeLength0 = p.getParam("attackTime") * p.getParam("attackTime") * 100000.0;
				_envelopeLength1 = p.getParam("sustainTime") * p.getParam("sustainTime") * 100000.0;
				_envelopeLength2 = p.getParam("decayTime") * p.getParam("decayTime") * 100000.0 + 10;
				_envelopeLength = _envelopeLength0;
				_envelopeFullLength = _envelopeLength0 + _envelopeLength1 + _envelopeLength2;
				
				_envelopeOverLength0 = 1.0 / _envelopeLength0;
				_envelopeOverLength1 = 1.0 / _envelopeLength1;
				_envelopeOverLength2 = 1.0 / _envelopeLength2;
				
				_flanger = p.getParam("flangerOffset") != 0.0 || p.getParam("flangerSweep") != 0.0;
				
				_flangerOffset = p.getParam("flangerOffset") * p.getParam("flangerOffset") * 1020.0;
				if(p.getParam("flangerOffset") < 0.0) _flangerOffset = -_flangerOffset;
				_flangerDeltaOffset = p.getParam("flangerSweep") * p.getParam("flangerSweep") * p.getParam("flangerSweep") * 0.2;
				_flangerPos = 0;
				
				if(!_flangerBuffer) _flangerBuffer = new Vector.<Number>(1024, true);
				if(!_noiseBuffer) _noiseBuffer = new Vector.<Number>(32, true);
				if(!_pinkNoiseBuffer) _pinkNoiseBuffer = new Vector.<Number>(32, true);
				if(!_loResNoiseBuffer) _loResNoiseBuffer = new Vector.<Number>(32, true);
				if (!_pinkNumber) _pinkNumber = new PinkNumber();
				
				for(var i:uint = 0; i < 1024; i++) _flangerBuffer[i] = 0.0;
				for(i = 0; i < 32; i++) _noiseBuffer[i] = Math.random() * 2.0 - 1.0;
				for(i = 0; i < 32; i++) _pinkNoiseBuffer[i] = _pinkNumber.GetNextValue();
				for(i = 0; i < 32; i++) _loResNoiseBuffer[i] = ((i%LoResNoisePeriod)==0) ? Math.random()*2.0-1.0 : _loResNoiseBuffer[i-1];							
			
				_repeatTime = 0;
				
				if (p.getParam("repeatSpeed") == 0.0) 	_repeatLimit = 0;
				else 						_repeatLimit = int((1.0-p.getParam("repeatSpeed")) * (1.0-p.getParam("repeatSpeed")) * 20000) + 32;
			}
		}
		
		/**
		 * Writes the wave to the supplied buffer ByteArray
		 * @param	buffer		A ByteArray to write the wave to
		 * @param	waveData	If the wave should be written for the waveData
		 * @return				If the wave is finished
		 */
		private function synthWave(buffer:ByteArray, length:uint, waveData:Boolean = false, sampleRate:uint = 44100, bitDepth:uint = 16):Boolean
		{
			_finished = false;
			
			_sampleCount = 0;
			_bufferSample = 0.0;
			
			for(var i:uint = 0; i < length; i++)
			{
				if (_finished) 
				{
					return true;					
				}
				
				// Repeats every _repeatLimit times, partially resetting the sound parameters
				if(_repeatLimit != 0)
				{
					if(++_repeatTime >= _repeatLimit)
					{
						_repeatTime = 0;
						reset(false);
					}
				}
				
				_changePeriodTime++;
				if (_changePeriodTime>=_changePeriod)
				{				
					_changeTime=0;
					_changeTime2=0;
					_changePeriodTime=0;
					if (_changeReached)
					{
						_period /= _changeAmount;
						_changeReached=false;
					}
					if (_changeReached2)
					{
						_period /= _changeAmount2;
						_changeReached2=false;
					}
				}
				
				// If _changeLimit is reached, shifts the pitch
				if(!_changeReached)
				{
					if(++_changeTime >= _changeLimit)
					{
						_changeReached = true;
						_period *= _changeAmount;
					}
				}
				
				// If _changeLimit is reached, shifts the pitch
				if(!_changeReached2)
				{
					if(++_changeTime2 >= _changeLimit2)
					{
						_period *= _changeAmount2;
						_changeReached2=true;
					}
				}
				
				// Acccelerate and apply slide
				_slide += _deltaSlide;
				_period *= _slide;
				
				// Checks for frequency getting too low, and stops the sound if a minFrequency was set
				if(_period > _maxPeriod)
				{
					_period = _maxPeriod;
					if(_minFreqency > 0.0) {
							_muted = true;
					}										
				}
				
				_periodTemp = _period;
				
				// Applies the vibrato effect
				if(_vibratoAmplitude > 0.0)
				{
					_vibratoPhase += _vibratoSpeed;
					_periodTemp = _period * (1.0 + Math.sin(_vibratoPhase) * _vibratoAmplitude);
				}
				
				_periodTemp = int(_periodTemp);
				if(_periodTemp < 8) _periodTemp = 8;
				
				// Sweeps the square duty
				if (_waveType == 0)
				{
					_squareDuty += _dutySweep;
						 if(_squareDuty < 0.0) _squareDuty = 0.0;
					else if (_squareDuty > 0.5) _squareDuty = 0.5;
				}
				
				// Moves through the different stages of the volume envelope
				if(++_envelopeTime > _envelopeLength)
				{
					_envelopeTime = 0;
					
					switch(++_envelopeStage)
					{
						case 1: _envelopeLength = _envelopeLength1; break;
						case 2: _envelopeLength = _envelopeLength2; break;
					}
				}
				
				// Sets the volume based on the position in the envelope
				switch(_envelopeStage)
				{
					case 0: _envelopeVolume = _envelopeTime * _envelopeOverLength0; 									break;
					case 1: _envelopeVolume = 1.0 + (1.0 - _envelopeTime * _envelopeOverLength1) * 2.0 * _sustainPunch; break;
					case 2: _envelopeVolume = 1.0 - _envelopeTime * _envelopeOverLength2; 								break;
					case 3: _envelopeVolume = 0.0; _finished = true; 													break;
				}
				
				// Moves the flanger offset
				if (_flanger)
				{
					_flangerOffset += _flangerDeltaOffset;
					_flangerInt = int(_flangerOffset);
						 if(_flangerInt < 0) 	_flangerInt = -_flangerInt;
					else if (_flangerInt > 1023) _flangerInt = 1023;
				}
				
				// Moves the high-pass filter cutoff
				if(_filters && _hpFilterDeltaCutoff != 0.0)
				{
					_hpFilterCutoff *= _hpFilterDeltaCutoff;
						 if(_hpFilterCutoff < 0.00001) 	_hpFilterCutoff = 0.00001;
					else if(_hpFilterCutoff > 0.1) 		_hpFilterCutoff = 0.1;
				}
				
				_superSample = 0.0;
				for(var j:int = 0; j < 8; j++)
				{
					// Cycles through the period
					_phase++;
					if(_phase >= _periodTemp)
					{
						_phase = _phase - _periodTemp;
						
						// Generates new random noise for this period
						if(_waveType == 3) 
						{ 
							for(var n:uint = 0; n < 32; n++) _noiseBuffer[n] = Math.random() * 2.0 - 1.0;
						}
						else if (_waveType == 5)
						{
							for(n = 0; n < 32; n++) _pinkNoiseBuffer[n] = _pinkNumber.GetNextValue();							
						}
						else if (_waveType == 6)
						{
							for(n = 0; n < 32; n++) _loResNoiseBuffer[n] = ((n%LoResNoisePeriod)==0) ? Math.random()*2.0-1.0 : _loResNoiseBuffer[n-1];							
						}
					}
					
					_sample=0;
					var overtonestrength:Number=1;
					for (var k:int=0;k<=_overtones;k++)
					{
						var tempphase:Number = (_phase*(k+1))%_periodTemp;
						// Gets the sample from the oscillator
						switch(_waveType)
						{
							case 0: // Square wave
							{
								_sample += overtonestrength*(((tempphase / _periodTemp) < _squareDuty) ? 0.5 : -0.5);
								break;
							}
							case 1: // Saw wave
							{
								_sample += overtonestrength*(1.0 - (tempphase / _periodTemp) * 2.0);
								break;
							}
							case 2: // Sine wave (fast and accurate approx)
							{								
								 _pos = tempphase / _periodTemp;
								 _pos = _pos > 0.5 ? (_pos - 1.0) * 6.28318531 : _pos * 6.28318531;
								var _tempsample:Number = _pos < 0 ? 1.27323954 * _pos + .405284735 * _pos * _pos : 1.27323954 * _pos - 0.405284735 * _pos * _pos;
								_sample += overtonestrength*(_tempsample < 0 ? .225 * (_tempsample *-_tempsample - _tempsample) + _tempsample : .225 * (_tempsample * _tempsample - _tempsample) + _tempsample);								
								break;
							}
							case 3: // Noise
							{
								_sample += overtonestrength*(_noiseBuffer[uint(tempphase * 32 / int(_periodTemp))%32]);
								break;
							}
							case 4: // Triangle Wave
							{						
								_sample += overtonestrength*(Math.abs(1-(tempphase / _periodTemp)*2)-1);
								break;
							}
							case 5: // Pink Noise
							{						
								_sample += overtonestrength*(_pinkNoiseBuffer[uint(tempphase * 32 / int(_periodTemp))%32]);
								break;
							}
							case 6: // tan
							{
								//detuned
								_sample += Math.tan(Math.PI*tempphase/_periodTemp)*overtonestrength;
								break;
							}
							case 7: // Whistle 
							{				
								// Sin wave code
								_pos = tempphase / _periodTemp;
								_pos = _pos > 0.5 ? (_pos - 1.0) * 6.28318531 : _pos * 6.28318531;
								_tempsample = _pos < 0 ? 1.27323954 * _pos + .405284735 * _pos * _pos : 1.27323954 * _pos - 0.405284735 * _pos * _pos;
								var value:Number = 0.75*(_tempsample < 0 ? .225 * (_tempsample *-_tempsample - _tempsample) + _tempsample : .225 * (_tempsample * _tempsample - _tempsample) + _tempsample);
								//then whistle (essentially an overtone with frequencyx20 and amplitude0.25
								
								_pos = ((tempphase*20) % _periodTemp) / _periodTemp;
								_pos = _pos > 0.5 ? (_pos - 1.0) * 6.28318531 : _pos * 6.28318531;
								_tempsample = _pos < 0 ? 1.27323954 * _pos + .405284735 * _pos * _pos : 1.27323954 * _pos - 0.405284735 * _pos * _pos;
								value += 0.25*(_tempsample < 0 ? .225 * (_tempsample *-_tempsample - _tempsample) + _tempsample : .225 * (_tempsample * _tempsample - _tempsample) + _tempsample);
								
								_sample += overtonestrength*value;//main wave
								
								break;
							}
							case 8: // Breaker
							{	
								var amp:Number = tempphase/_periodTemp;								
								_sample += overtonestrength*(Math.abs(1-amp*amp*2)-1);
								break;
							}
						}
						overtonestrength*=(1-_overtoneFalloff);
						
					}					
					
					// Applies the low and high pass filters
					if (_filters)
					{
						_lpFilterOldPos = _lpFilterPos;
						_lpFilterCutoff *= _lpFilterDeltaCutoff;
							 if(_lpFilterCutoff < 0.0) _lpFilterCutoff = 0.0;
						else if(_lpFilterCutoff > 0.1) _lpFilterCutoff = 0.1;
						
						if(_lpFilterOn)
						{
							_lpFilterDeltaPos += (_sample - _lpFilterPos) * _lpFilterCutoff;
							_lpFilterDeltaPos *= _lpFilterDamping;
						}
						else
						{
							_lpFilterPos = _sample;
							_lpFilterDeltaPos = 0.0;
						}
						
						_lpFilterPos += _lpFilterDeltaPos;
						
						_hpFilterPos += _lpFilterPos - _lpFilterOldPos;
						_hpFilterPos *= 1.0 - _hpFilterCutoff;
						_sample = _hpFilterPos;
					}
					
					// Applies the flanger effect
					if (_flanger)
					{
						_flangerBuffer[_flangerPos&1023] = _sample;
						_sample += _flangerBuffer[(_flangerPos - _flangerInt + 1024) & 1023];
						_flangerPos = (_flangerPos + 1) & 1023;
					}
					
					_superSample += _sample;
				}
				
				// Clipping if too loud
				if(_superSample > 8.0) 	_superSample = 8.0;
				else if(_superSample < -8.0) 	_superSample = -8.0;					 				 				
				
				// Averages out the super samples and applies volumes
				_superSample = _masterVolume * _envelopeVolume * _superSample * 0.125;				
				
				
				//BIT CRUSH				
				_bitcrush_phase+=_bitcrush_freq;
				if (_bitcrush_phase>1)
				{
					_bitcrush_phase=0;
					_bitcrush_last=_superSample;	 
				}
				_bitcrush_freq = Math.max(Math.min(_bitcrush_freq+_bitcrush_freq_sweep,1),0);
				
				_superSample=_bitcrush_last; 				
			
					 
					 
				 //compressor
					 
				 if (_superSample>0)
				 {
					 _superSample = Math.pow(_superSample,_compression_factor);
				 }
				 else
				 {
					 _superSample = -Math.pow(-_superSample,_compression_factor);
				 }
				 
				 if (_muted)
				 {
					 _superSample = 0;
				 }
				 
				if(waveData)
				{
					// Writes same value to left and right channels
					buffer.writeFloat(_superSample);
					buffer.writeFloat(_superSample);
				}
				else
				{
					_bufferSample += _superSample;
					
					_sampleCount++;
					
					// Writes mono wave data to the .wav format
					if(sampleRate == 44100 || _sampleCount == 2)
					{
						_bufferSample /= _sampleCount;
						_sampleCount = 0;
						
						if(bitDepth == 16) 	buffer.writeShort(int(32000.0 * _bufferSample));
						else 				buffer.writeByte(_bufferSample * 127 + 128);
						
						_bufferSample = 0.0;
					}
				}
			}
			
			return false;
		}
		
		
		//--------------------------------------------------------------------------
		//	
		//  .wav File Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Returns a ByteArray of the wave in the form of a .wav file, ready to be saved out
		 * @return					Wave in a .wav file
		 */
		public function getWavFile():ByteArray
		{
			stop();								
			var ww:WaveWriter = new WaveWriter(false,16);						
			
			var padded:ByteArray = new ByteArray();
			padded.writeBytes(cachedWave);
			for (var i:int=0;i<2000;i++)
			{
				padded.writeFloat(0);
				padded.writeFloat(0);
			}
			
			ww.addSamples(padded,true);			
			ww.finalize();			
			return ww.outBuffer;
		}
	}
}