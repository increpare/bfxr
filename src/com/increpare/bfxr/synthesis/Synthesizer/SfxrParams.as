package com.increpare.bfxr.synthesis.Synthesizer   
{
	import com.increpare.bfxr.synthesis.ISerializable;
	
	import mx.utils.StringUtil;

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
	public class SfxrParams implements ISerializable
	{
		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------
		
		/** If the parameters have been changed since last time (shouldn't used cached sound) */
		public var paramsDirty:Boolean;			
		
		//interface uses this to disable square sliders when non-square wavetype selected
		public static const SquareParams:Array = ["squareDuty","dutySweep"];
		
		//params to exclude from list
		public static const ExcludeParams:Array = ["waveType","masterVolume"];
		
		public static const ParamData:Array = [
		// real name, decription
		//   grouping,name, default, min, max, 
		["Wave Type","Shape of the wave.",
			0,"waveType",2,0,WAVETYPECOUNT-0.0001], // the 6.999 thing is because this is really an int parameter...		
		
		["Master Volume","Overall volume of the sound.",
			1,"masterVolume",0.5,0,1], 	
		["Attack Time","Length of the volume envelope attack.",
			1,"attackTime",0,0,1],		
		["Sustain Time","Length of the volume envelope sustain.",
			1,"sustainTime",0.3,0,1], 	
		["Punch","Tilts the sustain envelope for more 'pop'.",
			1,"sustainPunch",0,0,1], 		
		["Decay Time","Length of the volume envelope decay (yes, I know it's called release).",
			1,"decayTime",0.4,0,1], 	
		
		["Compression","Pushes amplitudes together into a narrower range to make them stand out more.  Very good for sound effects, where you want them to stick out against background music.",
			15,"compressionAmount",0.3,0,1],
		
		["Frequency","Base note of the sound.",
			2,"startFrequency",0.3,0,1], 		
		["Frequency Cutoff","If sliding, the sound will stop at this frequency, to prevent really low notes.  If unlocked, this is set to zero during randomization.",
			2,"minFrequency",0.0,0,1], 		
		
		["Frequency Slide","Slides the frequency up or down.",
			3,"slide",0.0,-1,1], 	
		["Delta Slide","Accelerates the frequency slide.  Can be used to get the frequency to change direction.",
			3,"deltaSlide",0.0,-1,1], 		
		
		["Vibrato Depth","Strength of the vibrato effect.",
			4,"vibratoDepth",0,0,1], 		
		["Vibrato Speed","Speed of the vibrato effect (i.e. frequency).",
			4,"vibratoSpeed",0,0,1], 		
		
		["Harmonics","Overlays copies of the waveform with copies and multiples of its frequency.  Good for bulking out or otherwise enriching the texture of the sounds (warning: this is the number 1 cause of bfxr slowdown!).",
			13,"overtones",0,0,1], 		
		["Harmonics Falloff","The rate at which higher overtones should decay.",
			13,"overtoneFalloff",0,0,1], 
		
		["Pitch Jump Repeat Speed","Larger Values means more pitch jumps, which can be useful for arpeggiation.",
			5,"changeRepeat",0,0,1], 		
		
		["Pitch Jump Amount 1","Jump in pitch, either up or down.",
			5,"changeAmount",0,-1,1], 		
		["Pitch Jump Onset 1","How quickly the note shift happens.",
			5,"changeSpeed",0,0,1], 		
		
		["Pitch Jump Amount 2","Jump in pitch, either up or down.",
			5,"changeAmount2",0,-1,1], 	
		["Pitch Jump Onset 2","How quickly the note shift happens.",
			5,"changeSpeed2",0,0,1], 		
		
		["Square Duty","Square waveform only : Controls the ratio between the up and down states of the square wave, changing the tibre.",
			8,"squareDuty",0,0,1], 		
		["Duty Sweep","Square waveform only : Sweeps the duty up or down.",
			8,"dutySweep",0,-1,1], 		
		
		["Repeat Speed","Speed of the note repeating - certain variables are reset each time.",
			9,"repeatSpeed",0,0,1], 	
		
		["Flanger Offset","Offsets a second copy of the wave by a small phase, changing the tibre.",
			10,"flangerOffset",0,-1,1], 		
		["Flanger Sweep","Sweeps the phase up or down.",
			10,"flangerSweep",0,-1,1], 
		
		["Low-pass Filter Cutoff","Frequency at which the low-pass filter starts attenuating higher frequencies.  Named most likely to result in 'Huh why can't I hear anything?' at her high-school grad. ",
			11,"lpFilterCutoff",1,0,1], 		
		["Low-pass Filter Cutoff Sweep","Sweeps the low-pass cutoff up or down.",
			11,"lpFilterCutoffSweep",0,-1,1], 	
		["Low-pass Filter Resonance","Changes the attenuation rate for the low-pass filter, changing the timbre.",
			11,"lpFilterResonance",0,0,1], 		
		
		["High-pass Filter Cutoff","Frequency at which the high-pass filter starts attenuating lower frequencies.",
			12,"hpFilterCutoff",0,0,1], 	
		["High-pass Filter Cutoff Sweep","Sweeps the high-pass cutoff up or down.",
			12,"hpFilterCutoffSweep",0,-1,1], 	
						
		["Bit Crush","Resamples the audio at a lower frequency.",
			14,"bitCrush",0,0,1] ,
		["Bit Crush Sweep","Sweeps the Bit Crush filter up or down.",
			14,"bitCrushSweep",0,-1,1]  
		
		];
		
		private var _params:Object; // stores values for all the parameters above
		private var _lockedParams : Vector.<String>; // stores list of strings, these strings represent parameters that will be locked during randomization/mutation
		
		//--------------------------------------------------------------------------
		//
		//  Getters / Setters
		//
		//--------------------------------------------------------------------------
		
		public static const WAVETYPECOUNT:int = 9;
		
		public function SfxrParams()
		{
			//initialize param object 
			_params = new Object();			
			for (var i:int=0;i<ParamData.length;i++)
			{
				_params[ParamData[i][3]]=-100;
			}
			
			resetParams();
		}
		
		public function getDefault(param:String):Number
		{
			return getProperty(param,4);
		}
		
		public function getMin(param:String):Number
		{
			return getProperty(param,5);
		}
		
		public function getMax(param:String):Number
		{
			return getProperty(param,6);
		}
		
		private function getProperty(param:String,index:int):Number
		{
			for (var i:int=0;i<ParamData.length;i++)
			{
				if (ParamData[i][3]==param)
				{
					return ParamData[i][index];
				}
			}
			throw new Error("Could not find param with name " + param );			
		}
		
		public function getParam(param:String):Number
		{
			if (! (param in _params))
			{
				throw new Error("Could not get param.  Param not found " + param);
			}
			
			return _params[param];			
		}
		
		public function setParam(param:String,value:Number):void
		{
			if (! (param in _params))
			{
				throw new Error("Could not set param.  Param not found " + param);
			}
			
			_params[param]=clamp(value,getMin(param),getMax(param));
			paramsDirty = true;
		}
		
		/** Returns true if this parameter is locked */
		public function lockedParam(param:String):Boolean
		{
			return _lockedParams.indexOf(param)>=0;
		}
		
		public function setAllLocked(locked:Boolean):void
		{
			_lockedParams = new Vector.<String>();
			
			if (locked)
			{
				for (var i:int=0;i<ParamData.length;i++)
				{
					_lockedParams.push(ParamData[i][3]);
				}
			}
			paramsDirty=true;
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
			
			setParam("startFrequency",0.4+Math.random()*0.5);
			
			setParam("sustainTime", Math.random() * 0.1);
			setParam("decayTime", 0.1 + Math.random() * 0.4);
			setParam("sustainPunch", 0.3 + Math.random() * 0.3);
			
			if(Math.random() < 0.5) 
			{
				setParam("changeSpeed", 0.5 + Math.random() * 0.2);
				var cnum:int = int(Math.random()*7)+1;
				var cden:int = cnum+int(Math.random()*7)+2;
				
				setParam("changeAmount", Number(cnum)/Number(cden));
			}
			
		}
		
		/**
		 * Sets the parameters to generate a laser/shoot sound
		 */
		public function generateLaserShoot():void
		{
			resetParams();
			
			setParam("waveType",uint(Math.random() * 3));
			if( int(getParam("waveType")) == 2 && Math.random() < 0.5) 
			{
				setParam("waveType", 
					uint(Math.random() * 2));
			}
			
			setParam("startFrequency", 
				0.5 + Math.random() * 0.5);
			setParam("minFrequency", 
				getParam("startFrequency") - 0.2 - Math.random() * 0.6);
			
			if(getParam("minFrequency") < 0.2) 
				setParam("minFrequency",0.2);
			
			setParam("slide", -0.15 - Math.random() * 0.2);			
			 
			if(Math.random() < 0.33)
			{
				setParam("startFrequency", Math.random() * 0.6);
				setParam("minFrequency", Math.random() * 0.1);
				setParam("slide", -0.35 - Math.random() * 0.3);
			}
			
			if(Math.random() < 0.5) 
			{
				setParam("squareDuty", Math.random() * 0.5);
				setParam("dutySweep", Math.random() * 0.2);
			}
			else
			{
				setParam("squareDuty", 0.4 + Math.random() * 0.5);
				setParam("dutySweep",- Math.random() * 0.7);	
			}
			
			setParam("sustainTime", 0.1 + Math.random() * 0.2);
			setParam("decayTime", Math.random() * 0.4);
			if(Math.random() < 0.5) setParam("sustainPunch", Math.random() * 0.3);
			
			if(Math.random() < 0.33)
			{
				setParam("flangerOffset", Math.random() * 0.2);
				setParam("flangerSweep", -Math.random() * 0.2);
			}
			
			if(Math.random() < 0.5) setParam("hpFilterCutoff", Math.random() * 0.3);
		}
		
		/**
		 * Sets the parameters to generate an explosion sound
		 */
		public function generateExplosion():void
		{
			resetParams();
			setParam("waveType", 3);
			
			if(Math.random() < 0.5)
			{
				setParam("startFrequency", 0.1 + Math.random() * 0.4);
				setParam("slide", -0.1 + Math.random() * 0.4);
			}
			else
			{
				setParam("startFrequency", 0.2 + Math.random() * 0.7);
				setParam("slide", -0.2 - Math.random() * 0.2);
			}
			
			setParam("startFrequency", getParam("startFrequency") * getParam("startFrequency"));
			
			if(Math.random() < 0.2) setParam("slide", 0.0);
			if(Math.random() < 0.33) setParam("repeatSpeed", 0.3 + Math.random() * 0.5);
			
			setParam("sustainTime", 0.1 + Math.random() * 0.3);
			setParam("decayTime", Math.random() * 0.5);
			setParam("sustainPunch", 0.2 + Math.random() * 0.6);
			
			if(Math.random() < 0.5)
			{
				setParam("flangerOffset", -0.3 + Math.random() * 0.9);
				setParam("flangerSweep", -Math.random() * 0.3);
			}
			
			if(Math.random() < 0.33)
			{
				setParam("changeSpeed", 0.6 + Math.random() * 0.3);
				setParam("changeAmount", 0.8 - Math.random() * 1.6);
			}
		}
		
		/**
		 * Sets the parameters to generate a powerup sound
		 */
		public function generatePowerup():void
		{
			resetParams();
			
			if(Math.random() < 0.5) setParam("waveType", 1);
			else 					setParam("squareDuty", Math.random() * 0.6);
			
			if(Math.random() < 0.5)
			{
				setParam("startFrequency", 0.2 + Math.random() * 0.3);
				setParam("slide", 0.1 + Math.random() * 0.4);
				setParam("repeatSpeed", 0.4 + Math.random() * 0.4);
			}
			else
			{
				setParam("startFrequency", 0.2 + Math.random() * 0.3);
				setParam("slide", 0.05 + Math.random() * 0.2);
				
				if(Math.random() < 0.5)
				{
					setParam("vibratoDepth", Math.random() * 0.7);
					setParam("vibratoSpeed", Math.random() * 0.6);
				}
			}
			
			setParam("sustainTime", Math.random() * 0.4);
			setParam("decayTime", 0.1 + Math.random() * 0.4);
		}
		
		/**
		 * Sets the parameters to generate a hit/hurt sound
		 */
		public function generateHitHurt():void
		{
			resetParams();
			
			setParam("waveType", uint(Math.random() * 3));
			if(int(getParam("waveType")) == 2) 
				setParam("waveType", 3);
			else if(int(getParam("waveType")) == 0) 
				setParam("squareDuty", Math.random() * 0.6);
			
			setParam("startFrequency", 0.2 + Math.random() * 0.6);
			setParam("slide", -0.3 - Math.random() * 0.4);
			
			setParam("sustainTime", Math.random() * 0.1);
			setParam("decayTime", 0.1 + Math.random() * 0.2);
			
			if(Math.random() < 0.5) setParam("hpFilterCutoff", Math.random() * 0.3);
		}
		
		/**
		 * Sets the parameters to generate a jump sound
		 */
		public function generateJump():void
		{
			resetParams();
			
			setParam("waveType", 0);
			setParam("squareDuty", Math.random() * 0.6);
			setParam("startFrequency", 0.3 + Math.random() * 0.3);
			setParam("slide", 0.1 + Math.random() * 0.2);
			
			setParam("sustainTime", 0.1 + Math.random() * 0.3);
			setParam("decayTime", 0.1 + Math.random() * 0.2);
			
			if(Math.random() < 0.5) setParam("hpFilterCutoff", Math.random() * 0.3);
			if(Math.random() < 0.5) setParam("lpFilterCutoff", 1.0 - Math.random() * 0.6);
		}
		
		/**
		 * Sets the parameters to generate a blip/select sound
		 */
		public function generateBlipSelect():void
		{
			resetParams();
			
			setParam("waveType", uint(Math.random() * 2));
			if(int(getParam("waveType")) == 0) 
				setParam("squareDuty", Math.random() * 0.6);
			
			setParam("startFrequency", 0.2 + Math.random() * 0.4);
			
			setParam("sustainTime", 0.1 + Math.random() * 0.1);
			setParam("decayTime", Math.random() * 0.2);
			setParam("hpFilterCutoff", 0.1);
		}
		
		/**
		 * Resets the parameters, used at the start of each generate function
		 */
		public function resetParams(paramsToReset:Array = null):void
		{
			paramsDirty = true;
			
			for (var param:String in _params)
			{
				if (paramsToReset==null || paramsToReset.indexOf(param)>=0)
					_params[param]=getDefault(param);
			}
			
			if (paramsToReset==null || paramsToReset.indexOf("lockedParams")>=0)
			{
				_lockedParams = new Vector.<String>();
				//lock this one by default
				_lockedParams.push("masterVolume");
			}
			
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
			for (var param:String in _params)
			{
				if (!lockedParam(param))
				{
					if (Math.random()<0.5)
					{
						setParam(param, getParam(param) + Math.random()*mutation*2 - mutation);
					}
				}
			}
		}
		
		//some constants used for weighting random values 
		
		private const RandomizationPower:Object = 
			{
				attackTime:4,
				sustainTime:2,
				sustainPunch:2,
				overtones:3,
				overtoneFalloff:0.25,
				vibratoDepth:3,
				dutySweep:3,
				flangerOffset:3,
				flangerSweep:3,
				lpFilterCutoff:0.3,
				lpFilterSweep:3,
				hpFilterCutoff:5,
				hpFilterSweep:5,
				bitCrush:4,			
				bitCrushSweep:5
			}
			
		private const WaveTypeWeights:Array = 
			[
				1,//0:square
				1,//1:saw
				1,//2:sin
				1,//3:noise
				1,//4:triangle
				1,//5:pink
				1,//6:tan
				1,//7:whistle
				1//8:breaker
			];
			
		/**
		 * Sets all parameters to random values
		 * If passed null, no fields constrained
		 */
		public function randomize():void
		{
			
			for (var param:String in _params)
			{
				if (!lockedParam(param))
				{
					var min:Number = getMin(param);
					var max:Number = getMax(param);
					var r:Number = Math.random();
					if (param in RandomizationPower)
						r=Math.pow(r,RandomizationPower[param]);
					_params[param] = min  + (max-min)*r;
				}
			}
			
			paramsDirty = true;
			
			if (!lockedParam("waveType"))
			{
				var count:int=0;
				for (var i:int=0;i<WaveTypeWeights.length;i++)
				{
					count+=WaveTypeWeights[i];
				}
				r = Math.random()*count;
				for (i=0;i<WaveTypeWeights.length;i++)
				{
					r-=WaveTypeWeights[i];
					if (r<=0)
					{
						setParam("waveType",i);
						break;
					}
				}
				
			}
			
			if (!lockedParam("repeatSpeed"))
			{
				if (Math.random()<0.5)
					setParam("repeatSpeed",0);
			}
						
			if (!lockedParam("slide"))
			{
				r=Math.random()*2-1;
				r=Math.pow(r,5);
				setParam("slide",r);
			}
			if (!lockedParam("deltaSlide"))
			{
				r=Math.random()*2-1;
				r=Math.pow(r,3);
				setParam("deltaSlide",r);
			}
			
			if (!lockedParam("minFrequency"))
				setParam("minFrequency",0);
			
			if (!lockedParam("startFrequency"))
				setParam("startFrequency",  	(Math.random() < 0.5) ? pow(Math.random()*2-1, 2) : (pow(Math.random() * 0.5, 3) + 0.5));
			
			if ((!lockedParam("sustainTime")) && (!lockedParam("decayTime")))
			{
				if(getParam("attackTime") + getParam("sustainTime") + getParam("decayTime") < 0.2)
				{
					setParam("sustainTime", 0.2 + Math.random() * 0.3);
					setParam("decayTime", 0.2 + Math.random() * 0.3);
				}
			}
			
			if (!lockedParam("slide"))
			{
				if((getParam("startFrequency") > 0.7 && getParam("slide") > 0.2) || (getParam("startFrequency") < 0.2 && getParam("slide") < -0.05)) 
				{
					setParam("slide", -getParam("slide"));
				}
			}
			
			if (!lockedParam("lpFilterCutoffSweep"))
			{
				if(getParam("lpFilterCutoff") < 0.1 && getParam("lpFilterCutoffSweep") < -0.05) 
				{
					setParam("lpFilterCutoffSweep", -getParam("lpFilterCutoffSweep"));
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
		public function Serialize():String
		{			
			var string:String="";
			for (var i:int=0; i< SfxrParams.ParamData.length;i++)
			{
				var param:String = SfxrParams.ParamData[i][3];
				
				if (i>0)
					string+=",";
				
				string += to4DP(getParam(param)); 
			}
			
			for (i=0;i<this._lockedParams.length;i++)
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
		public function Deserialize(string:String):void
		{
			if (string==null)
			{
				throw new Error("passed null string to SfxrParams.Deserialize");
			}
			
			var values:Array = string.split(",");
			
			var string:String;
			for (var i:int=0; i< SfxrParams.ParamData.length;i++)
			{
				var param:String = SfxrParams.ParamData[i][3];
				setParam(param,Number(values[i]));
			}						
						
			_lockedParams = new Vector.<String>();
			for (;i<values.length;i++)
			{
				_lockedParams.push(values[i]);
			}
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
			for (var param:String in _params)
			{
				_params[param] = params.getParam(param);
			}
			
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
		 * Clams a value to betwen a and b
		 * @param	value	Input value
		 * @param	min		min value
		 * @param	max		max value
		 * @return			The value clamped between min and max
		 */
		private function clamp(value:Number, min:Number, max:Number):Number { return (value > max) ? max : ((value < min) ? min : value); }
		
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