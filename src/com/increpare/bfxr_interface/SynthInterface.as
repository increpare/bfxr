package com.increpare.bfxr_interface
{
    import com.increpare.bfxr.dataClasses.SoundData;
    import com.increpare.bfxr.dataClasses.SoundListRowData;
    import com.increpare.bfxr.synthesis.Synthesizer.SfxrParams;
    import com.increpare.bfxr.synthesis.Synthesizer.SfxrSynth;
    import com.increpare.bfxr_interface.components.Bfxr_interface;
    import com.increpare.bfxr_interface.components.SoundParameterRowRenderer;
    
    import flash.events.Event;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    
    import mx.binding.utils.*;
    import mx.collections.ArrayList;
    import mx.controls.Alert;
    import mx.core.UIComponent;
    
    import spark.components.CheckBox;
    import spark.components.HSlider;
    import spark.components.Label;
    import spark.components.ToggleButton;

    public class SynthInterface implements ITabManager
    {

        private var _synth:SfxrSynth; // Synthesizer instance

		private var _globalState:GlobalState;
		
		private var _app:Bfxr_interface;
		
        public function SynthInterface(app:Bfxr_interface, globalState:GlobalState)
        {
			_app=app;
			_globalState = globalState;
            _synth = new SfxrSynth();
			_synth.params.randomize();	
			
			var lastgroup:int=-1;
			var odd:Boolean=true;
			_app.SoundParameterList = new ArrayList();
			var soundParamList:ArrayList = _app.SoundParameterList;
			for (var i:int=0;i<SfxrParams.ParamData.length;i++)
			{
				var slrd:SoundListRowData = new SoundListRowData();
				slrd.label = 		SfxrParams.ParamData[i][0];
								
				
				slrd.tooltip = 		SfxrParams.ParamData[i][1];
				slrd.bggroup = 		SfxrParams.ParamData[i][2];
				slrd.tag = 			SfxrParams.ParamData[i][3];
				
				
				if (SfxrParams.ExcludeParams.indexOf(slrd.tag)>=0)
					continue;
				
				slrd.defaultvalue = SfxrParams.ParamData[i][4];				
				slrd.min = 			SfxrParams.ParamData[i][5];
				slrd.max = 			SfxrParams.ParamData[i][6];
				slrd.square = 		SfxrParams.SquareParams.indexOf(slrd.tag)>=0;
				
				//if (lastgroup!=slrd.bggroup)
					odd=!odd;
				
				slrd.odd = 		odd;
				slrd.enabled =	true;
				slrd.value = _synth.params.getParam(slrd.tag);
				
				slrd.addEventListener(SoundListRowData.DEFAULT_CLICK,function(e:Event):void{ComponentChangeCallback("reset",e);});
				slrd.addEventListener(SoundListRowData.LOCKEDNESS_CHANGE,function(e:Event):void{ComponentChangeCallback("locked",e);});
				slrd.addEventListener(SoundListRowData.LOCKEDNESS_ALLCHANGE,function(e:Event):void{ComponentChangeCallback("alllocked",e);});
				slrd.addEventListener(SoundListRowData.SLIDER_CHANGE,function(e:Event):void{ComponentChangeCallback("slider",e);});
				//slrd.addEventListener(SoundListRowData.SLIDER_BEGIN_CHANGE,function(e:Event):void{ComponentBeginChangeCallback("slider",e);});				
				
				lastgroup =		slrd.bggroup;
				
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
		
		public function ComponentChangeCallback(tag:String,e:Event):void
		{
			var sprd:SoundListRowData = e.target as SoundListRowData;	
			var updateui:Boolean=false;
			var audible:Boolean=true;
			
			switch(tag)
			{
				case "reset":
					_synth.params.resetParams([ sprd.tag ]);
					updateui=true;
					break;
				case "locked":
					_synth.params.setParamLocked(sprd.tag,sprd.locked);	
					audible=false;
					break;
				case "alllocked":
					_synth.params.setAllLocked(sprd.locked);
					updateui=true;
					audible=false;
					break;
				case "slider":
					_synth.params.setParam(sprd.tag, sprd.value);
					break;
				case "wavetype":    
					_synth.params.setParamLocked("waveType", _app.lockwave.selected);
					audible=false;					
					break;
				case "alllockedwavetype":
					_synth.params.setAllLocked(!_app.lockwave.selected);
					audible=false;
					updateui=true;
					break;
				case "volume":					
					_synth.params.setParam("masterVolume", _app.volumeslider.value);
					break;
				default:
					throw new Error("tag not identified");
			}
			
			OnParameterChanged(audible);	
			
			if (updateui)
			{
				RefreshUI();
			}			
		}	
		
		/** Called right now only when a person begins to drag a volume slider */
		public function ComponentBeginChangeCallback(tag:String,e:Event):void
		{
			
			switch(tag)
			{
				case "slider":
					_app.StopAll();
					break;				
				default:
					throw new Error("tag not identified");
			}	
		}

		public function Stop():void
		{
			_synth.stop();
		}
		
        // called when synth and visuals have been synced
        // audible if we want to retrigger a play 
        //(e.g. changing lock status of a field shouldn't trigger a replay)
        public function OnParameterChanged(audible:Boolean = true, underlyingModification:Boolean = true, forceplay:Boolean = false):void
        {						
			//apply applications to selected item's data
			if (underlyingModification)
			{
				var sd:SoundData = _app.soundItems.getItemAt(_app.soundList.selectedIndex) as SoundData;
				sd.data = Serialize();
				
				_app.EnableApplyButton(true);
			}
			
            //_synth.params.wave
            if ((audible && _globalState.playOnChange)||forceplay)
            {
                _synth.play();
            }
        }

		public function Serialize():String
		{
			return _synth.params.Serialize();
		}
		
		
		public function DeserializeSFS(file:ByteArray,allowplay:Boolean=true):void
		{						
			_app.AddToSoundList("Sfxr Synth", true,false);
			
			
			_synth.params.resetParams();
			_synth.params.setParam("compressionAmount",0);
			
			file.position = 0;
			file.endian = Endian.LITTLE_ENDIAN;		
			
			var version:int = file.readInt();
			
			if(version != 100 && version != 101 && version != 102) return;			
			
			_synth.params.setParam("waveType", file.readInt());
			_synth.params.setParam("masterVolume",(version == 102) ? file.readFloat() : 0.5);
			
			_synth.params.setParam("startFrequency",file.readFloat());
			_synth.params.setParam("minFrequency",file.readFloat());
			_synth.params.setParam("slide",file.readFloat());
			_synth.params.setParam("deltaSlide",(version >= 101) ? file.readFloat() : 0.0);
			
			_synth.params.setParam("squareDuty",file.readFloat());
			_synth.params.setParam("dutySweep",file.readFloat());
			
			_synth.params.setParam("vibratoDepth",file.readFloat());
			_synth.params.setParam("vibratoSpeed",file.readFloat());
			var unusedVibratoDelay:Number = file.readFloat();
			
			_synth.params.setParam("attackTime",file.readFloat());
			_synth.params.setParam("sustainTime",file.readFloat());
			_synth.params.setParam("decayTime",file.readFloat());
			_synth.params.setParam("sustainPunch",file.readFloat());
			
			var unusedFilterOn:Boolean = file.readBoolean();
			_synth.params.setParam("lpFilterResonance",file.readFloat());
			_synth.params.setParam("lpFilterCutoff",file.readFloat());
			_synth.params.setParam("lpFilterCutoffSweep",file.readFloat());
			_synth.params.setParam("hpFilterCutoff",file.readFloat());
			_synth.params.setParam("hpFilterCutoffSweep",file.readFloat());
			
			_synth.params.setParam("flangerOffset",file.readFloat());
			_synth.params.setParam("flangerSweep",file.readFloat());
			
			_synth.params.setParam("repeatSpeed",file.readFloat());
						
			_synth.params.setParam("changeSpeed",(version >= 101) ? file.readFloat() : 0.0);
			_synth.params.setParam("changeAmount",(version >= 101) ? file.readFloat() : 0.0);
			
			RefreshUI();
			OnParameterChanged(allowplay, true);
			_app.clickApplySound();
		}
		
		
		public function Deserialize(str:String):void
		{
			_synth.params.Deserialize(str);
		}
		
		public function DeserializeFromClipboard(str:String,allowplay:Boolean=true):void
		{			
			_app.AddToSoundList("Paste", true,false);
			Deserialize(str);
			RefreshUI();
			OnParameterChanged(allowplay, true);
			_app.clickApplySound();
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
			
			OnParameterChanged();
		}
		
		public function RefreshUI():void
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
			if (_app.tabs.selectedIndex==0)
			{
				UpdateSharedComponents();
			}			
		}
		
		public function UpdateSharedComponents():void
		{			
			_app.createNew.enabled=true;
			_app.volumeslider.value = _synth.params.getParam("masterVolume");
			_app.PlayButton.enabled=true;
			_app.exportwav.enabled=true;
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
			return _synth.getWavFile();
		}
    }
}