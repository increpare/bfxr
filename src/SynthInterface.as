package
{
    import components.SoundParameterRowRenderer;
    
    import synthesis.SfxrParams;
    import synthesis.SfxrSynth;
    
    import flash.events.Event;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    
    import mx.binding.utils.*;
    import mx.collections.ArrayList;
    import mx.core.UIComponent;
    
    import spark.components.CheckBox;
    import spark.components.HSlider;
    import spark.components.Label;
    import spark.components.ToggleButton;
    import dataClasses.SoundData;
    import dataClasses.SoundListRowData;

    public class SynthInterface
    {

        private var _synth:SfxrSynth; // Synthesizer instance

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
			
			var lastgroup:int=-1;
			var odd:Boolean=true;
			_app.SoundParameterList = new ArrayList();
			var soundParamList:ArrayList = _app.SoundParameterList;
			for (var i:int=0;i<SfxrParams.ParamData.length;i++)
			{
				var slrd:SoundListRowData = new SoundListRowData();
				slrd.label = 	SfxrParams.ParamData[i][0];
								
				
				slrd.tooltip = 	SfxrParams.ParamData[i][1];
				slrd.bggroup = 	SfxrParams.ParamData[i][2];
				slrd.tag = 		SfxrParams.ParamData[i][3];
				
				if (SfxrParams.ExcludeParams.indexOf(slrd.tag)>=0)
					continue;
				
				slrd.min = 		SfxrParams.ParamData[i][5];
				slrd.max = 		SfxrParams.ParamData[i][6];
				slrd.square = 	SfxrParams.SquareParams.indexOf(slrd.tag)>=0;
				
				if (lastgroup!=slrd.bggroup)
					odd=!odd;
				
				slrd.odd = 		odd;
				slrd.enabled =	true;
				slrd.value = _synth.params.getParam(slrd.tag);
				
				lastgroup =		slrd.bggroup;
				slrd.addEventListener(SoundListRowData.DEFAULT_CLICK,SLRD_On_Default_Clicked);
				slrd.addEventListener(SoundListRowData.LOCKEDNESS_CHANGE,SLRD_On_Lockedness_Changed);
				slrd.addEventListener(SoundListRowData.SLIDER_CHANGE,SLRD_On_Slider_Changed);
				
				//ChangeWatcher.watch(slrd,"locked",LockStatusChanged);
				//ChangeWatcher.watch(slrd,"value",SliderValueChanged);
				soundParamList.addItem(slrd);
			}
        }

		public function randomize():void
		{
			_synth.params.randomize();
		}
		
		public function Play():void
		{
			_synth.play();
		}
		
		public function SLRD_On_Default_Clicked(event:Event):void
		{
			var sprd:SoundListRowData = event.target as SoundListRowData;			
			ResetSoundParameterValue(sprd.tag);			
		}
		
		public function SLRD_On_Lockedness_Changed(event:Event):void
		{
			var sprd:SoundListRowData = event.target as SoundListRowData;
			_synth.params.setParamLocked(sprd.tag,sprd.locked);	
			OnSoundParameterChanged(false);		
		}
		
		public function SLRD_On_Slider_Changed(event:Event):void
		{
			var sprd:SoundListRowData = event.target as SoundListRowData;
			
			_synth.params.setParam(sprd.tag, sprd.value);
			OnSoundParameterChanged();			
		}
		
		
		public function sliderChanged(e:Event):void
		{
			var s:HSlider = e.target as HSlider;
			var renderercb:SoundParameterRowRenderer = s.parent.parent as SoundParameterRowRenderer;
			
			_synth.params.setParam(renderercb.data.tag, s.value);
			OnSoundParameterChanged();
		}
		public function lockChanged(tag:String, locked:Boolean):void
		{
			_synth.params.setParamLocked(tag, locked);
			OnSoundParameterChanged(false);
		}
		

        public function WaveTypeLockClicked():void
        {
            _synth.params.setParamLocked("waveType", _lockWave.selected);
			OnSoundParameterChanged(false,true);
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
			_synth.params.setParam("waveType", ind);
			
			CalculateSquareSliderEnabledness();
			
			OnSoundParameterChanged();
		}
		
		public function UIUpdateTrigger():void
		{			
			// waveform
			for (var i:int = 0; i < SfxrParams.WAVETYPECOUNT; i++)
			{
				var tb:ToggleButton = _app["W" + i] as ToggleButton;
				tb.selected = int(_synth.params.getParam("waveType")) == i;
			}
			
			CalculateSquareSliderEnabledness();
			
			//update lockable checkboxes
			for (i=0;i<_app.SoundParameterList.length;i++)
			{
				var slrd:SoundListRowData = _app.SoundParameterList.getItemAt(i) as SoundListRowData;
				slrd.locked = _synth.params.lockedParam(slrd.tag);
			}
			_app.lockwave.selected = _synth.params.lockedParam("waveType");
			
			//parameter sliders
			for (i=0;i<_app.SoundParameterList.length;i++)
			{
				slrd = _app.SoundParameterList.getItemAt(i) as SoundListRowData;
				slrd.value = _synth.params.getParam(slrd.tag);
			}
			
			//volume slider
			_app.volumeslider.value = _synth.params.getParam("masterVolume");
			
		}
		
		
		public function VolumeChanged(event:Event):void
		{
			_synth.params.setParam("masterVolume", _volumeSlider.value);
			OnSoundParameterChanged(true,true);
			UIUpdateTrigger();
		}
		
		public function GeneratePreset(tag:String):void
		{						
			//call the preset generation function
			_synth.params[tag]();
		}
		
		private function CalculateSquareSliderEnabledness():void
		{
			
			for (var i:int=0;i<_app.SoundParameterList.length;i++)
			{
				var slrd:SoundListRowData = _app.SoundParameterList.getItemAt(i) as SoundListRowData;
				if (slrd.square)
				{
					slrd.enabled=int(_synth.params.getParam("waveType")) == 0;
				}
			}
			
			
		}							
		
		public function getWavFile():ByteArray
		{
			return _synth.getWavFile(_globalState.sampleRate,_globalState.bitDepth);
		}
    }
}