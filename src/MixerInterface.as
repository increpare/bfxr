package
{
	import Synthesis.Mixer;
	import Synthesis.MixerSoundData;
	import Synthesis.SfxrSynth;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayList;
	
	import spark.components.HSlider;

	public class MixerInterface
	{
		private var _mixer:Mixer;
		
		private var _globalState:GlobalState;
		
		private var _volumeSlider:HSlider;
		
		private var _app:sfxr_interface;
		
		private var _mixerList:ArrayList;
		
		public function MixerInterface(app:sfxr_interface, globalState:GlobalState,volumeSlider:HSlider,mixerList:ArrayList)
		{			
			_app=app;
			_globalState = globalState;
			_volumeSlider = volumeSlider;
			_mixer = new Mixer();
			_mixer.addEventListener(SfxrSynth.PLAY_COMPLETE, MixerPlayStop);
			_mixerList=mixerList;
		}
		
		public function UIUpdateTrigger():void
		{
			trace("refreshing layer pane");
//			_mixerList.removeAll();
			//this.mixerList.addIte .removeAll();
			for (var i:int = 0; i < _mixer.params.items.length; i++)
			{
				var item:MixerItemParams = _mixer.params.items[i];
				var dat:MixerListEntryDat = new MixerListEntryDat(item.id);
				dat.amplitudemodifier = item.amplitudemodifier;
				dat.onset = item.onset;
				dat.preset = true;
				_mixerList.setItemAt(dat, i);
				
				//layerItems.ad
			}
		}
			
		
		
		public function RecalcDilation():void
		{
			trace("recalcdilation");
			var maxlength:Number = 0.1;
			//step 1: find max dilation
			for (var i:int = 0; i < _mixerList.length; i++)
			{
				var mled:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				if (mled.CalcLengthCallback == null)
				{
					return;
				}
				
				var cand:Number = mled.CalcLengthCallback();
				if (cand > maxlength)
				{
					maxlength = cand;
				}
			}
			
			//find the appropriate dilation value
			const boxwidth:Number = 191; //double-check, eh?
			//dilation => 1 second = d pixels
			var dilation:Number = boxwidth / (2 * maxlength);
			
			//let all the data things know
			for (i = 0; i < _mixerList.length; i++)
			{
				mled = _mixerList.getItemAt(i) as MixerListEntryDat;
				mled.SetDilationCallback(dilation);
			}
			
		}
		
		// called when synth and visuals have been synced
		// audible if we want to retrigger a play 
		//(e.g. changing lock status of a field shouldn't trigger a replay)
		public function OnMixerParameterChanged(audible:Boolean = true, underlyingModification:Boolean = true):void
		{
			//apply applications to selected item's data
			if (underlyingModification)
			{
				var ld:LayerData = _app.layerItems.getItemAt(_app.layerList.selectedIndex) as LayerData;
				ld.data = _mixer.params.getSettingsString();
				
				_app.EnableApplyButton(true);
			}
			
			//_synth.params.wave
			if (audible && _globalState.playOnChange)
			{
				Play();
			}
		}
		
		public function Play():void
		{
			trace("mixerplay");
			_mixer.Clear();
			for (var i:int = 0; i < _mixerList.length; i++)
			{
				var dat:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				//synth.();
				if (dat.synthset)
				{
					var msd:MixerSoundData = new MixerSoundData(dat.id, dat.synth.cachedWave, dat.onset, dat.amplitudemodifier);
					_mixer.AddTrack(msd);
				}
			}
			
			MixerPlayStart();
			_mixer.Play(MixerPlayCallback);
		}
		
		private function MixerPlayCallback(n:Number):void
		{
			
			for (var i:int = 0; i < _mixerList.length; i++)
			{
				var mled:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				mled.absolutePlayCallback(n);
			}
		}

		public function MixerPlayStart():void
		{
			trace("mixerplaystart");
			for (var i:int = 0; i < this._mixerList.length; i++)
			{
				var mled:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				mled.PlayStartCallback();
			}
		}
		
		public function MixerPlayStop(event:Event = null):void
		{
			
			trace("mixerplaystop");
			for (var i:int = 0; i < this._mixerList.length; i++)
			{
				var mled:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				mled.PlayStopCallback();
			}
		}
		public function mixer_volume_sliderChanged(e:Event = null):void
		{
			
			trace("mixervolumesliderchanged");
			///uch, just update all the volumes
			for (var i:int = 0; i < this._mixerList.length; i++)
			{
				var msd:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				_mixer.params.items[i].amplitudemodifier = msd.amplitudemodifier;
			}
			
			OnMixerParameterChanged();
		}
		
		public function mixer_onset_sliderChanged(e:Event = null):void
		{
			trace("mixeronsetsliderchanged");
			///uch, just update all the volumes
			for (var i:int = 0; i < this._mixerList.length; i++)
			{
				var msd:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				_mixer.params.items[i].onset = msd.onset;
			}
			
			OnMixerParameterChanged();
		}
		
		public function mixer_id_soundChanged(e:Event = null):void
		{
			trace("mixer_onset_soundidChanged");
			///uch, just update all the volumes
			for (var i:int = 0; i < this._mixerList.length; i++)
			{
				var msd:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				_mixer.params.items[i].id = msd.id;
			}
			
			OnMixerParameterChanged(false);			
		}
		
		public function getSettingsString():String
		{
			return _mixer.params.getSettingsString();
		}
		
		public function getClipboardString():String
		{
			var result:String = "";
			//mixer string first
			result = _mixer.params.getSettingsString();
			
			var o:Array = new Array();
			for (var i:int = 0; i < _mixer.params.items.length; i++)
			{
				var mpi:MixerItemParams = _mixer.params.items[i];
				
				if (((mpi.id in o) == false) && (mpi.id>=0))
				{
					var soundindex:int = _app.GetIndexOfSoundItemWithID(mpi.id);
					o[mpi.id] = (_app.soundItems.getItemAt(soundindex) as SoundData).data;
				}
			}
			
			for (var s:String in o)
			{
				result += "|" + s + "," + o[s];
			}
			return result;
		}
		
		//the clipboard string also includes the data of all sounds attached to it.
		public function setClipboardString(data:String):void
		{
			var chunks:Array = data.split("|");
			//first part is layer data itself
			_mixer.params.items = new Vector.<MixerItemParams>();
			
			trace(" mix description  = " + chunks[0]);
			//will need to update the IDs here as I read the other strings in, in case there're clashes
			_mixer.params.setSettingsString(chunks[0]);
			
			for (var i:int = 1; i < chunks.length; i++)
			{
				var chunk:String = chunks[i];
				var firstcomma:int = chunk.indexOf(",");
				var idpart:int = int(chunk.substr(0, firstcomma));
				var descriptionpart:String = chunk.substr(firstcomma + 1);
				if (_app.GetIndexOfSoundItemWithID(idpart)>=0)
				{
					var newid:int = _app.saveManager.GetID();
					//rename id in mixer
					for (var j:int = 0; j < _mixer.params.items.length; j++)
					{
						if (_mixer.params.items[j].id == idpart)
						{
							_mixer.params.items[j].id = newid;
							//there could be several uses of this id, so shouldn't break;
						}
					}
					idpart = newid;
				}
				
				//now that everything's added, can paste sound in as normal(?)
				
				_app.AddToSoundList("Sound", true, true, idpart);
				trace(" sound description  = " + descriptionpart);
				_app.synthInterface.setSettingsString(descriptionpart);
				
				_app.OnSoundParameterChanged(false, false);
				
			}
			
			//now push the  mixer settings and load them as if you had clicked on them
			_app.AddToLayerList("Pasted", true);
			
			UIUpdateTrigger();
			
			_app.DisableApplyButton(false);
		}
		
		public function setSettingsString(str:String):Boolean
		{
			return _mixer.params.setSettingsString(str);
		}
		
		
		public function getWavFile():ByteArray
		{			
			_mixer.Clear();
			for (var i:int = 0; i < _mixerList.length; i++)
			{
				var dat:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				if (dat.synthset)
				{
					var msd:MixerSoundData = new MixerSoundData(dat.id, dat.synth.getWavFile(_globalState.sampleRate,_globalState.bitDepth), dat.onset, dat.amplitudemodifier);
					_mixer.AddTrack(msd);
				}
			}
			
			return _mixer.getWavFile(_globalState.sampleRate,_globalState.bitDepth);
		}
		
		public function AddNewMixerLayer(event:MouseEvent):void
		{
			this._mixerList.addItemAt(new MixerListEntryDat(-1), 0);
			_mixer.params.items.splice(0, 0, new MixerItemParams(-1, 0, 1));
			
			OnMixerParameterChanged(false);
		}
		
		public function mixer_on_item_removed(audible:Boolean, dat:Object):void
		{
			//if (_mixerList.length==1)
			//	return;
			
			var index:int = _mixerList.getItemIndex(dat);
			var mled:MixerListEntryDat = _mixerList.getItemAt(index) as MixerListEntryDat;
			_mixerList.removeItemAt(index);
			//items.dispatchEvent(FlexEvent.REMOVE);
			
			OnMixerParameterChanged(true, true);
			
			/* 	var index:int = layerItems.getItemIndex(dat);
			
			layerItems.removeItemAt(index);
			_mixer.params.items.splice(index,1);
			
			OnLayerParameterChanged(audible,true); */
		}
	}
}