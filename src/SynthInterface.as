package
{
    import Components.SoundParameterRowRenderer;
    
    import Synthesis.SfxrParams;
    import Synthesis.SfxrSynth;
    
    import flash.events.Event;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    
    import mx.core.UIComponent;
    
    import spark.components.CheckBox;
    import spark.components.HSlider;
    import spark.components.Label;
    import spark.components.ToggleButton;

    public class SynthInterface
    {

        private var _synth:SfxrSynth; // Synthesizer instance

        private var _sliderList:Array = new Array();

        private var _squareSlider:Array = new Array();

		private var _globalState:GlobalState;
		
		private var _volumeSlider:HSlider;
		
		private var _lockWave : CheckBox;
		
		private var _app:sfxr_interface;
		
        public function SynthInterface(app:sfxr_interface, globalState:GlobalState,volumeSlider:HSlider)
        {
			_app=app;
			_globalState = globalState;
			_volumeSlider = volumeSlider;
            _synth = new SfxrSynth();
			_synth.params.randomize();
        }

		public function Play():void
		{
			_synth.play();
		}
		
		
		public function sliderChanged(e:Event):void
		{
			var s:HSlider = e.target as HSlider;
			var renderercb:SoundParameterRowRenderer = s.parent.parent as SoundParameterRowRenderer;
			
			_synth.params[renderercb.data.tag] = s.value;
			OnSoundParameterChanged();
		}
		
		public function lockChanged(tag:String, locked:Boolean):void
		{
			_synth.params.setParamLocked(tag, locked);
			OnSoundParameterChanged(false);
		}
		
        private var lockablecheckboxes:Object = new Object();

        public function RegisterLockableParam(tag:String, checkbox:CheckBox):void
        {
            lockablecheckboxes[tag] = checkbox;
        }

        public function WaveTypeLockClicked():void
        {
            _synth.params.setParamLocked("waveType", _lockWave.selected);
			OnSoundParameterChanged(false,true);
        }

        public function RegisterWaveTypeLock(lockwave:CheckBox):void
        {
			_lockWave=lockwave;
            RegisterLockableParam("waveType", lockwave);
        }

        public function RegisterParameterSlider(c:SoundParameterRowRenderer):void
        {
            _sliderList[c.data.tag] = c;
        }

        public function RegisterSquareSlider(label:Label, s:HSlider):void
        {
            _squareSlider.push(label);
            _squareSlider.push(s);
        }

        public function ResetSoundParameterValue(paramname:String):void
        {
            _synth.params.resetParams([ paramname ]);
            OnSoundParameterChanged();
            UIUpdateTrigger();
        }

        // called when synth and visuals have been synced
        // audible if we want to retrigger a play 
        //(e.g. changing lock status of a field shouldn't trigger a replay)
        public function OnSoundParameterChanged(audible:Boolean = true, underlyingModification:Boolean = true):void
        {						
			//apply applications to selected item's data
			if (underlyingModification)
			{
				var sd:SoundData = _app.soundItems.getItemAt(_app.soundList.selectedIndex) as SoundData;
				sd.data = getSettingsString();
				
				_app.EnableApplyButton(true);
			}
			
            //_synth.params.wave
            if (audible && _globalState.playOnChange)
            {
                _synth.play();
            }
        }

		public function getSettingsString():String
		{
			return _synth.params.getSettingsString();
		}
		
		public function setSettingsString(str:String):Boolean
		{
			return _synth.params.setSettingsString(str);
		}
		
		
		public function WaveformSelect(event:Event):void
		{
			var tb:ToggleButton = event.target as ToggleButton;
			
			var ind:int = parseInt(tb.id.charAt(1));
			
			//deselect other buttons
			for (var i:int = 0; i < SfxrParams.WAVETYPECOUNT; i++)
			{
				(_app["W" + i] as ToggleButton).selected = i == ind;
			}
			_synth.params.waveType = ind;
			
			CalculateSquareSliderEnabledness();
			
			OnSoundParameterChanged();
		}
		
		public function UIUpdateTrigger():void
		{
			//#1 update all fields
			
			_volumeSlider.value = 2 * _synth.params.masterVolume;
			
			// waveform
			for (var i:int = 0; i < SfxrParams.WAVETYPECOUNT; i++)
			{
				var tb:ToggleButton = _app["W" + i] as ToggleButton;
				tb.selected = _synth.params.waveType == i;
			}
			
			CalculateSquareSliderEnabledness();
			
			//update lockable checkboxes
			for (var key:String in lockablecheckboxes)
			{
				var checkbox:CheckBox = lockablecheckboxes[key] as CheckBox;
				checkbox.selected = _synth.params.lockedParam(key);
			}
			
			//parameter sliders
			for (var tag:String in _sliderList)
			{
				var cb:SoundParameterRowRenderer = _sliderList[tag] as SoundParameterRowRenderer;
				cb.slider.value = _synth.params[tag];
			}
			
			//where are the waveforms update?
		}
		
		
		public function VolumeChanged(event:Event):void
		{
			_synth.params.masterVolume = _volumeSlider.value / 2;
			OnSoundParameterChanged();
		}
		
		public function GeneratePreset(tag:String):void
		{						
			_synth.params[tag]();
		}
		
		private function CalculateSquareSliderEnabledness():void
		{
			for (var i:int = 0; i < _squareSlider.length; i++)
			{
				var sldr:Object = _squareSlider[i];
				var cmp:UIComponent = sldr as UIComponent;
				cmp.enabled = _synth.params.waveType == 0;
			}
			
		}
		
		
		
		
		/**
		 * Writes the current parameters to a ByteArray and returns it
		 * Compatible with the original Sfxr files
		 * @return	ByteArray of settings data
		 */
		public function getSettingsFile():ByteArray
		{
			var file:ByteArray = new ByteArray();
			file.endian = Endian.LITTLE_ENDIAN;
			
			file.writeInt(SfxrSynth.version);
			file.writeInt(_synth.params.waveType);
			file.writeFloat(_synth.params.masterVolume);
			
			file.writeFloat(_synth.params.startFrequency);
			file.writeFloat(_synth.params.minFrequency);
			file.writeFloat(_synth.params.slide);
			file.writeFloat(_synth.params.deltaSlide);
			
			file.writeFloat(_synth.params.squareDuty);
			file.writeFloat(_synth.params.dutySweep);
			
			file.writeFloat(_synth.params.vibratoDepth);
			file.writeFloat(_synth.params.vibratoSpeed);
			file.writeFloat(0);
			
			file.writeFloat(_synth.params.attackTime);
			file.writeFloat(_synth.params.sustainTime);
			file.writeFloat(_synth.params.decayTime);
			file.writeFloat(_synth.params.sustainPunch);
			
			file.writeBoolean(false);
			file.writeFloat(_synth.params.lpFilterResonance);
			file.writeFloat(_synth.params.lpFilterCutoff);
			file.writeFloat(_synth.params.lpFilterCutoffSweep);
			file.writeFloat(_synth.params.hpFilterCutoff);
			file.writeFloat(_synth.params.hpFilterCutoffSweep);
			
			file.writeFloat(_synth.params.phaserOffset);
			file.writeFloat(_synth.params.phaserSweep);
			
			file.writeFloat(_synth.params.repeatSpeed);
			
			file.writeFloat(_synth.params.changePeriod);
			file.writeFloat(_synth.params.changeSpeed);
			file.writeFloat(_synth.params.changeAmount);
			file.writeFloat(_synth.params.changeSpeed2);
			file.writeFloat(_synth.params.changeAmount2);
			
			file.writeFloat(_synth.params.overtones);
			file.writeFloat(_synth.params.overtoneFalloff);
			
			file.writeBoolean(_synth.params.lockedParam("waveType"));
			file.writeBoolean(_synth.params.lockedParam("startFrequency"));
			
			file.writeBoolean(_synth.params.lockedParam("minFrequency"));
			file.writeBoolean(_synth.params.lockedParam("slide"));
			file.writeBoolean(_synth.params.lockedParam("deltaSlide"));
			
			file.writeBoolean(_synth.params.lockedParam("squareDuty"));
			file.writeBoolean(_synth.params.lockedParam("dutySweep"));
			
			file.writeBoolean(_synth.params.lockedParam("vibratoDepth"));
			file.writeBoolean(_synth.params.lockedParam("vibratoSpeed"));
			
			file.writeBoolean(_synth.params.lockedParam("attackTime"));
			file.writeBoolean(_synth.params.lockedParam("sustainTime"));
			file.writeBoolean(_synth.params.lockedParam("decayTime"));
			file.writeBoolean(_synth.params.lockedParam("sustainPunch"));
			
			file.writeBoolean(_synth.params.lockedParam("lpFilterResonance"));
			file.writeBoolean(_synth.params.lockedParam("lpFilterCutoff"));
			file.writeBoolean(_synth.params.lockedParam("lpFilterCutoffSweep"));
			file.writeBoolean(_synth.params.lockedParam("hpFilterCutoff"));
			file.writeBoolean(_synth.params.lockedParam("hpFilterCutoffSweep"));
			
			file.writeBoolean(_synth.params.lockedParam("phaserOffset"));
			file.writeBoolean(_synth.params.lockedParam("phaserSweep"));
			
			file.writeBoolean(_synth.params.lockedParam("repeatSpeed"));
			
			file.writeBoolean(_synth.params.lockedParam("changePeriod"));
			file.writeBoolean(_synth.params.lockedParam("changeSpeed"));
			file.writeBoolean(_synth.params.lockedParam("changeAmount"));
			file.writeBoolean(_synth.params.lockedParam("changeSpeed2"));
			file.writeBoolean(_synth.params.lockedParam("changeAmount2"));
			
			file.writeBoolean(_synth.params.lockedParam("overtones"));
			file.writeBoolean(_synth.params.lockedParam("overtoneFalloff"));
			
			return file;
		}
		
		/**
		 * Reads parameters from a ByteArray file
		 * Compatible with the original Sfxr files
		 * @param	file	ByteArray of settings data
		 */
		public function setSettingsFile(file:ByteArray):void
		{
			file.position = 0;
			file.endian = Endian.LITTLE_ENDIAN;
			
			var version:int = file.readInt();
			
			if (version != 100 && version != 101 && version != 102 && version != 103)
			{
				return;
			}
			
			_synth.params.waveType = file.readInt();
			_synth.params.masterVolume = (version >= 102) ? file.readFloat() : 0.5;
			
			_synth.params.startFrequency = file.readFloat();
			_synth.params.minFrequency = file.readFloat();
			_synth.params.slide = file.readFloat();
			_synth.params.deltaSlide = (version >= 101) ? file.readFloat() : 0.0;
			
			_synth.params.squareDuty = file.readFloat();
			_synth.params.dutySweep = file.readFloat();
			
			_synth.params.vibratoDepth = file.readFloat();
			_synth.params.vibratoSpeed = file.readFloat();
			var unusedVibratoDelay:Number = file.readFloat();
			
			_synth.params.attackTime = file.readFloat();
			_synth.params.sustainTime = file.readFloat();
			_synth.params.decayTime = file.readFloat();
			_synth.params.sustainPunch = file.readFloat();
			
			var unusedFilterOn:Boolean = file.readBoolean();
			_synth.params.lpFilterResonance = file.readFloat();
			_synth.params.lpFilterCutoff = file.readFloat();
			_synth.params.lpFilterCutoffSweep = file.readFloat();
			_synth.params.hpFilterCutoff = file.readFloat();
			_synth.params.hpFilterCutoffSweep = file.readFloat();
			
			_synth.params.phaserOffset = file.readFloat();
			_synth.params.phaserSweep = file.readFloat();
			
			_synth.params.repeatSpeed = file.readFloat();
			
			_synth.params.changePeriod = (version >= 103) ? file.readFloat() : 1.0;
			
			_synth.params.changeSpeed = (version >= 101) ? file.readFloat() : 0.0;
			_synth.params.changeAmount = (version >= 101) ? file.readFloat() : 0.0;
			_synth.params.changeSpeed2 = (version >= 103) ? file.readFloat() : 0.0;
			_synth.params.changeAmount2 = (version >= 103) ? file.readFloat() : 0.0;
			_synth.params.overtones = (version >= 103) ? file.readFloat() : 0.0;
			_synth.params.overtoneFalloff = (version >= 103) ? file.readFloat() : 0.0;
			
			if (version >= 103)
			{
				_synth.params.setParamLocked("waveType", file.readBoolean());
				_synth.params.setParamLocked("startFrequency", file.readBoolean());
				
				_synth.params.setParamLocked("minFrequency", file.readBoolean());
				_synth.params.setParamLocked("slide", file.readBoolean());
				_synth.params.setParamLocked("deltaSlide", file.readBoolean());
				
				_synth.params.setParamLocked("squareDuty", file.readBoolean());
				_synth.params.setParamLocked("dutySweep", file.readBoolean());
				
				_synth.params.setParamLocked("vibratoDepth", file.readBoolean());
				_synth.params.setParamLocked("vibratoSpeed", file.readBoolean());
				
				_synth.params.setParamLocked("attackTime", file.readBoolean());
				_synth.params.setParamLocked("sustainTime", file.readBoolean());
				_synth.params.setParamLocked("decayTime", file.readBoolean());
				_synth.params.setParamLocked("sustainPunch", file.readBoolean());
				
				_synth.params.setParamLocked("lpFilterResonance", file.readBoolean());
				_synth.params.setParamLocked("lpFilterCutoff", file.readBoolean());
				_synth.params.setParamLocked("lpFilterCutoffSweep", file.readBoolean());
				_synth.params.setParamLocked("hpFilterCutoff", file.readBoolean());
				_synth.params.setParamLocked("hpFilterCutoffSweep", file.readBoolean());
				
				_synth.params.setParamLocked("phaserOffset", file.readBoolean());
				_synth.params.setParamLocked("phaserSweep", file.readBoolean());
				
				_synth.params.setParamLocked("repeatSpeed", file.readBoolean());
				
				_synth.params.setParamLocked("changePeriod", file.readBoolean());
				_synth.params.setParamLocked("changeSpeed", file.readBoolean());
				_synth.params.setParamLocked("changeAmount", file.readBoolean());
				_synth.params.setParamLocked("changeSpeed2", file.readBoolean());
				_synth.params.setParamLocked("changeAmount2", file.readBoolean());
				
				_synth.params.setParamLocked("overtones", file.readBoolean());
				_synth.params.setParamLocked("overtoneFalloff", file.readBoolean());
			}
		}
		
		public function getWavFile():ByteArray
		{
			return _synth.getWavFile(_globalState.sampleRate,_globalState.bitDepth);
		}
    }
}