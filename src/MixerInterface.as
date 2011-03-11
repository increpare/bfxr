package
{
	import com.increpare.bfxr.synthesis.Mixer;
	import com.increpare.bfxr.synthesis.MixerItemParams;
	import com.increpare.bfxr.synthesis.MixerSoundData;
	import com.increpare.bfxr.synthesis.SfxrSynth;
	
	import dataClasses.LayerData;
	import dataClasses.MixerListEntryDat;
	import dataClasses.SoundData;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayList;
	
	import spark.components.HSlider;

	public class MixerInterface implements ITabManager
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
		
		public function RefreshUI():void
		{
			for (var i:int = 0; i < _mixer.params.items.length; i++)
			{
				var item:MixerItemParams = _mixer.params.items[i];
				var dat:MixerListEntryDat = new MixerListEntryDat(item.id);
				dat.amplitudemodifier = item.amplitudemodifier;
				dat.onset = item.onset;
				dat.preset = true;
				_mixerList.setItemAt(dat, i);
			}
			
			if (_app.tabs.selectedIndex==1)
			{
				UpdateSharedComponents();
			}
		}					
		
		public function RecalcDilation():void
		{
			var mled:MixerListEntryDat;
			
			var maxlength:Number = 0.1;
			//step 1: find max dilation
			for (var i:int = 0; i < _mixerList.length; i++)
			{
				mled = _mixerList.getItemAt(i) as MixerListEntryDat;
				if (mled.id==-1)
				{
					continue;
				}
				
				var cand:Number = mled.synth.GetLength();
				if (cand > maxlength)
				{
					maxlength = cand;
				}
			}
			
			//clamp onsets where needed
			
			var clamped:Boolean=false;
			for (i = 0; i < _mixerList.length; i++)
			{
				mled = _mixerList.getItemAt(i) as MixerListEntryDat;
				if (mled.id==-1)
				{
					continue;
				}
				
				var len:Number = mled.synth.GetLength();
				
				if (mled.onset + len > 2*maxlength)
				{
					mled.onset = 0;
					clamped=true;
				}
			}
			
			if (clamped)
			{				
				_app.mixerInterface.ComponentChangeCallback("onset",null);
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
		public function OnParameterChanged(audible:Boolean = true, underlyingModification:Boolean = true, forceplay:Boolean = false):void
		{
			//apply applications to selected item's data
			if (underlyingModification)
			{
				var ld:LayerData = _app.layerItems.getItemAt(_app.layerList.selectedIndex) as LayerData;
				ld.data = _mixer.params.Serialize();
				
				_app.EnableApplyButton(true);				
			}
			
			if ((audible && _globalState.playOnChange)||forceplay)
			{
				Play();
			}			
			
			//changing tracks can alter enabledness of the 'play' button
			if (_app.tabs.selectedIndex==1)
			{
				UpdateSharedComponents();
			}
		}
		
		
		public function UpdateSharedComponents():void
		{			
			_app.modifyexisting.enabled=false;

			_app.volumeslider.value = _mixer.params.volume;
						
			var trackFound:Boolean=false;
			for (var i:int=0;i<_mixerList.length;i++)
			{
				var dat:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				if (dat.id>=0)
				{
					trackFound=true;
					break;
				}
			}
				
			_app.PlayButton.enabled=trackFound;
		}
		
		public function Play():void
		{
			_mixer.Clear();
			for (var i:int = 0; i < _mixerList.length; i++)
			{
				var dat:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				//synth.();
				if (dat.synthset)
				{
					var msd:MixerSoundData = new MixerSoundData(dat.id,dat.data, dat.synth.cachedWave, dat.onset, dat.amplitudemodifier);
					_mixer.AddTrack(msd);
				}
			}
			
			MixerPlayStart();
			_mixer.play(MixerPlayCallback);
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
			MixerPlayStop();
			for (var i:int = 0; i < this._mixerList.length; i++)
			{
				var mled:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				mled.PlayStartCallback();
			}
		}
		
		public function MixerPlayStop(event:Event = null):void
		{
			_mixer.stop();
			for (var i:int = 0; i < this._mixerList.length; i++)
			{
				var mled:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				mled.synth.stop();
				mled.PlayStopCallback();
			}
		}
				
		public function ComponentChangeCallback(tag:String,e:Event):void
		{
			var audible:Boolean=true;
			
			switch (tag)
			{
				case "volume":
					_mixer.params.volume = _app.volumeslider.value;
					
					for (var i:int = 0; i < this._mixerList.length; i++)
					{
						var msd:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
						_mixer.params.items[i].amplitudemodifier = msd.amplitudemodifier;
					}
					break;
				case "onset":
					for (i = 0; i < this._mixerList.length; i++)
					{
						msd = _mixerList.getItemAt(i) as MixerListEntryDat;
						_mixer.params.items[i].onset = msd.onset;
					}
					break;
				case "id":
					audible=true;
					for (i = 0; i < this._mixerList.length; i++)
					{
						msd = _mixerList.getItemAt(i) as MixerListEntryDat;
						_mixer.params.items[i].id = msd.id;
					}
					break;					
				default:
					throw new Error("tag not identified");					
			}
			OnParameterChanged(audible);
		}
		
		
		public function Serialize():String
		{
			return _mixer.params.Serialize();
		}
		
		public function getClipboardString():String
		{
			//collate object data
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
			
			//update data in the mixer
			for (i=0;i<_mixer.params.items.length;i++)
			{
				var mip:MixerItemParams = _mixer.params.items[i];
				mip.data = o[mip.id];
			}
			
			//mixer string first
			var result:String  = _mixer.params.Serialize();

			return result;
		}
		
		//the clipboard string also includes the data of all sounds attached to it.
		public function DeserializeFromClipboard(str:String):void
		{	
			//now push the  mixer settings and load them as if you had clicked on them
			_app.AddToLayerList("Pasted", true);
			
			//set basic mixer data
			_mixer.params.items = new Vector.<MixerItemParams>();
			
			//if synth IDs overlap, then rename
			_mixer.params.Deserialize(str);
			
			//1: get list of IDs used
			var idlist:Vector.<int> = new Vector.<int>;
			var descriptions:Vector.<String> = new Vector.<String>;
			for (i=0;i<_mixer.params.items.length;i++)
			{
				var id:int=_mixer.params.items[i].id;
				
				if (id==-1)
				{
					continue;
				}
				
				if (idlist.indexOf(id)==-1)
				{
					idlist.push(id);
					descriptions.push(_mixer.params.items[i].data);
				}
			}
			
			//2: see if ids are already in use
			for (var i:int=0;i<idlist.length;i++)
			{
				id=idlist[i];
				if (_app.GetIndexOfSoundItemWithID(id)>=0)
				{
					//then calculate new id and change all references to this id
					var newid:int=_app.saveManager.GetID();
					for (var j:int=0;j<_mixer.params.items.length;j++)
					{
						if (_mixer.params.items[j].id==id)
						{
							_mixer.params.items[j].id=newid;
						}
					}
					id=newid;
				}
				
				//add new id to list
				_app.AddToSoundList("Sound",true,false,id);
				_app.synthInterface.Deserialize(descriptions[i]);
				_app.synthInterface.OnParameterChanged(true,true);
			}			
			
			OnParameterChanged(false,true);
			RefreshUI();
			
			_app.DisableApplyButton(false);
		}
		
		public function Deserialize(str:String):Boolean
		{
			return _mixer.params.Deserialize(str);
		}		
		
		public function getWavFile():ByteArray
		{			
			_mixer.Clear();
			for (var i:int = 0; i < _mixerList.length; i++)
			{
				var dat:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				if (dat.synthset)
				{
					var msd:MixerSoundData = new MixerSoundData(dat.id, dat.data, dat.synth.getWavFile(_globalState.sampleRate,_globalState.bitDepth), dat.onset, dat.amplitudemodifier);
					_mixer.AddTrack(msd);
				}
			}
			
			return _mixer.getWavFile(_globalState.sampleRate,_globalState.bitDepth);
		}
		
		public function RemoveOrphanSounds():void
		{
			for (var i:int=0;i<_mixerList.length;i++)
			{
				var dat:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				if (dat.synthset)
				{
					// check if synth still exists in list
					if (_app.GetIndexOfSoundItemWithID(dat.id)<0)
					{
						dat.synthset=false;
					}		
				}
			}
		}
		
		public function CheckIfSoundsOutOfDate():void
		{
			for (var i:int=0;i<_mixerList.length;i++)
			{
				var dat:MixerListEntryDat = _mixerList.getItemAt(i) as MixerListEntryDat;
				if (dat.synthset)
				{
					var index:int = _app.GetIndexOfSoundItemWithID(dat.id);
					// check if synth still exists in list
					if (index>=0)
					{
						var sd:SoundData = _app.soundItems.getItemAt(index) as SoundData;
						
						//compare strings (should only really compare audible parts...not locking stuff...but that can wait
						if (dat.synth.params.Serialize()!=sd.data)
						{
							//they're not the same, need to update
							dat.dispatchEvent(new Event(MixerListEntryDat.REFRESH_SYNTH));
						}
						
					}
				}
			}			
		}	
		
	}
}