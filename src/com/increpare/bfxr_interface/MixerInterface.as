package com.increpare.bfxr_interface
{
	import com.increpare.bfxr_interface.mixerinterface.MixerController;
	import com.increpare.bfxr_interface.mixerinterface.MixerTrackController;
	
	import com.increpare.bfxr.synthesis.*;
	import com.increpare.bfxr.synthesis.Mixer.*;
	
	import com.increpare.bfxr.dataClasses.LayerData;
	import com.increpare.bfxr.dataClasses.SoundData;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayList;
	import mx.events.FlexEvent;
	
	import spark.components.HSlider;
	import com.increpare.bfxr_interface.components.Bfxr_interface;
	
	public class MixerInterface implements ITabManager
	{		
		[Bindable]
		public var mixerController:MixerController;
		
		private var _app:Bfxr_interface;
		private var _globalState:GlobalState;		
		
		public function MixerInterface(app:Bfxr_interface, globalState:GlobalState)
		{
			_app=app;
			_globalState = globalState;
			mixerController = new MixerController(_app);
		}
		
		public function Play():void
		{
			mixerController.Play();
		}
		
		
		public function RefreshUI():void
		{
			//the following calls UpdateSharedComponents
			mixerController.RefreshUI();			
		}
		
		public function UpdateSharedComponents():void
		{		
			_app.createNew.enabled=false;
			
			_app.volumeslider.value = mixerController.mixerPlayer.volume;
			
			var trackFound:Boolean=false;
			for (var i:int=0;i<mixerController.mixerPlayer.tracks.length;i++)
			{
				var mtp:MixerTrackPlayer = mixerController.mixerPlayer.tracks[i];
				if (mtp.IsSet())
				{
					trackFound=true;
					break;
				}
			}
			
			_app.PlayButton.enabled=trackFound;	
			_app.exportwav.enabled=trackFound;
		}
		
		public function OnParameterChanged(audible:Boolean = true, underlyingModification:Boolean = true, forceplay:Boolean = false):void
		{
			//apply applications to selected item's data
			if (underlyingModification)
			{
				var ld:LayerData = _app.layerItems.getItemAt(_app.mixesList.selectedIndex) as LayerData;
				ld.data = mixerController.Serialize() ;				
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
		
		public function RemoveOrphanSounds():void
		{
			var mtp:MixerTrackPlayer;
			var mtc:MixerTrackController;
			
			for (var i:int=0;i<mixerController.mixerPlayer.tracks.length;i++)
			{
				mtc = mixerController.trackControllers[i];				
				mtp = mixerController.mixerPlayer.tracks[i];
				if (mtp.IsSet())
				{
					// check if synth still exists in list
					if (_app.GetIndexOfSoundItemWithID(mtp.data.id)<0)
					{
						mtc.ClearTrack(false);				
					}		
				}
			}
			
			//changes made above will be remade in list data...no biggie I guess...
			var changedany:Boolean=false;
			//remove references in other mixes as well
			for (i=0;i<_app.layerItems.length;i++)
			{
				var changed:Boolean=false;
				var ld:LayerData = LayerData(_app.layerItems.getItemAt(i));
				var mp:MixerPlayer = new MixerPlayer();
				mp.Deserialize(ld.data);
				for (var j:int=0;j<mp.tracks.length;j++)
				{
					mtp = mp.tracks[j];
					if (mtp.IsSet())
					{						
						if( _app.GetIndexOfSoundItemWithID(mtp.data.id)<0)
						{
							mtp.LoadSynth(null);
							changed=true;
							changedany=true;
						}
					}
				}
				if (changed)
				{					
					ld.data=mp.Serialize();
					ld.dispatchEvent(new FlexEvent(FlexEvent.CHANGE_END));
				}
			}
			
			if (changedany)
			{
				_app.saveManager.PushLayerList(_app.layerItems);
			}
			
			RefreshUI();
		}		
		
		public function CheckIfSoundsOutOfDate():void
		{
			var modified:Boolean=false;
			for (var i:int=0;i<mixerController.mixerPlayer.tracks.length;i++)
			{
				var mtp:MixerTrackPlayer = mixerController.mixerPlayer.tracks[i];
				if (mtp.data.id>=0)
				{
					var index:int = _app.GetIndexOfSoundItemWithID(mtp.data.id);
					// check if synth still exists in list
					if (index>=0)
					{
						var sd:SoundData = _app.soundItems.getItemAt(index) as SoundData;
						
						//compare strings (should only really compare audible parts...not locking stuff...but that can wait
						if (mtp.data.synthdata!=sd.data)
						{
							//they're not the same, need to update							
							mtp.LoadSynth(sd);
							modified=true;
						}						
					}
				}
			}	
			
			if (modified)
			{
				RefreshUI();
			}
		}	
		
		public function ComponentChangeCallback(tag:String,e:Event):void
		{
			
			switch (tag)
			{
				case "volume":
					mixerController.mixerPlayer.volume = _app.volumeslider.value;
					OnParameterChanged(true,true);
					break;
				default:
					throw new Error("tag not identified : " + tag);	
			}
		}
		
		public function Serialize():String
		{
			return mixerController.Serialize();
		}
		
		public function Deserialize(data:String):void
		{
			mixerController.Deserialize(data);
		}
		
		public function Stop():void
		{
			mixerController.MixerStopAll();
		}
		
		public function DeserializeFromClipboard(data:String,allowplay:Boolean=true):void
		{
			//now push the  mixer settings and load them as if you had clicked on them
			_app.AddToLayerList("Pasted", true);
			
			//if synth IDs overlap, then rename
			mixerController.Deserialize(data);
			
			//1: get list of IDs used
			var idlist:Vector.<int> = new Vector.<int>;
			var descriptions:Vector.<String> = new Vector.<String>;
			for (i=0;i<mixerController.mixerPlayer.tracks.length;i++)
			{
				var id:int=mixerController.mixerPlayer.tracks[i].data.id;
				
				if (id==-1)
				{
					continue;
				}
				
				if (idlist.indexOf(id)==-1)
				{
					idlist.push(id);
					descriptions.push(mixerController.mixerPlayer.tracks[i].data.synthdata);
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
					for (var j:int=0;j<mixerController.mixerPlayer.tracks.length;j++)
					{
						if (mixerController.mixerPlayer.tracks[j].data.id==id)
						{
							mixerController.mixerPlayer.tracks[j].data.id=newid;
						}
					}
					id=newid;
				}
				
				//add new id to list
				_app.AddToSoundList("Sound",true,false,id);
				_app.synthInterface.Deserialize(descriptions[i]);
				_app.synthInterface.OnParameterChanged(false,true);
				_app.clickApplySound();
			}			
			
			OnParameterChanged(allowplay,true);
			_app.clickApplyLayer();
			RefreshUI();			
		}
				
		public function getWavFile():ByteArray
		{
			
			return mixerController.mixerPlayer.getWavFile();
		}
		
		
		
				
	}
}