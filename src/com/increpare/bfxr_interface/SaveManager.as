package com.increpare.bfxr_interface
{
	import com.increpare.bfxr.dataClasses.LayerData;
	import com.increpare.bfxr.dataClasses.SoundData;
	import com.increpare.bfxr.synthesis.Synthesizer.SfxrSynth;
	import com.increpare.bfxr_interface.components.Bfxr_interface;
	
	import flash.net.SharedObject;
	
	import flashx.textLayout.elements.GlobalSettings;
	
	import mx.collections.ArrayList;
	
	public class SaveManager
	{
		private var _saveDat:SharedObject;
		private var _parent:Bfxr_interface;
		
		public function get samplerate():int
		{
			return _saveDat.data.samplerate;
		}
		
		public function get bitdepth():int
		{
			return _saveDat.data.bitdepth;
		}
		
		public function get playonchange():Boolean
		{
			return _saveDat.data.playonchange;
		}
		
		public function get selectedSoundItemID():int
		{
			return _saveDat.data.selectedSoundItemID;
		}
		public function get selectedLayerItemID():int
		{
			return _saveDat.data.selectedSoundItemID;
		}
		
		public function SaveManager(parent:Bfxr_interface)
		{
			_parent=parent;
			_saveDat = null;		
		}
		
		public function commitGlobal(gs:GlobalState ):void
		{
			//don't need to worry about tripping over other people's values			
			_saveDat.data.playonchange = gs.playOnChange;
			_saveDat.data.createNew = gs.createNew;
			_saveDat.data.selectedSoundItemID = gs.selectedSoundItemID;	
			_saveDat.data.selectedLayerItemID = gs.selectedLayerItemID;			
			OnChange();	
		}
		
		
		public function loadGlobal():GlobalState
		{
			var gs:GlobalState = new GlobalState();
			
			if (_saveDat.data.playonchange !== undefined)
			{
				gs.playOnChange = _saveDat.data.playonchange;
				gs.createNew = _saveDat.data.createNew;
				gs.selectedSoundItemID = _saveDat.data.selectedSoundItemID;	
				gs.selectedLayerItemID = _saveDat.data.selectedLayerItemID;
			}
			
			return gs;
		}
		
		
		public function LoadSavedSoundsFromSharedObject(soundList:ArrayList):void
		{
			soundList.removeAll();
			for (var s:String in _saveDat.data.soundList)
			{
				var o:Object = _saveDat.data.soundList[s];
				var sd:SoundData = new SoundData(o.label,o.data,o.id);
				soundList.addItem(sd);
			}
		}
		
		public function LoadSavedLayersFromSharedObject(layerList:ArrayList):void
		{
			layerList.removeAll();
			for (var s:String in _saveDat.data.layerList)
			{
				var o:Object = _saveDat.data.layerList[s];
				var ld:LayerData = new LayerData(o.label,o.data,o.id);
				layerList.addItem(ld);
			}
		}
		
		/** updates the name only */
		public function UpdateSoundName(sd:SoundData):void
		{
			var sl:Array = _saveDat.data.soundList as Array;
			for (var i:int=0;i<sl.length;i++)
			{
				var o:Object  = sl[i];
				if (o.id==sd.id)
				{
					o.label = sd.label;
					OnChange();
					return;
				
				}
			}
			
			throw new Error("nothing found with id " + sd.id);
		}
		
		
		/** updates the name only */
		public function UpdateLayerName(sd:LayerData):void
		{
			var sl:Array = _saveDat.data.layerList as Array;
			for (var i:int=0;i<sl.length;i++)
			{
				var o:Object  = sl[i];
				if (o.id==sd.id)
				{
					o.label = sd.label;
					OnChange();
					return;
					
				}
			}
			
			throw new Error("nothing found with id " + sd.id);
		}
		
		public function RemoveSoundItemWithID(id:int):void
		{
			var sl:Array = _saveDat.data.soundList as Array;
			for (var i:int=0;i<sl.length;i++)
			{
				var o:Object  = sl[i];
				if (o.id==id)
				{
					sl.splice(i,1);
					OnChange();
					return;
				}
			}			
			
			throw new Error("nothing found with id " + id);
		}
		
		public function RemoveLayerItemWithID(id:int):void
		{
			var ll:Array = _saveDat.data.layerList as Array;
			for (var i:int=0;i<ll.length;i++)
			{
				var o:Object  = ll[i];
				if (o.id==id)
				{
					ll.splice(i,1);
					OnChange();
					return;
				}
			}			
			
			throw new Error("nothing found with id " + id);
		}
		
		//Rebuilds save from scratch using current application settings
		public function RefreshSaveWithAppData():void
		{
			//global first
			commitGlobal(_parent.globalState);
			//synths next
			PushSoundList(_parent.soundItems);
			//mixes last
			PushLayerList(_parent.layerItems);
		}
		
		//potentially quite dangerous?
		public function PushSoundList(items:ArrayList):void
		{
			_saveDat.data.soundList = new Array();
			for (var i:int=0;i<items.length;i++)
			{
				var o:SoundData  = items.getItemAt(i) as SoundData;
				_saveDat.data.soundList.push(o.Clone());
			}
			OnChange();
		}
		
		//potentially quite dangerous?
		public function PushLayerList(items:ArrayList):void
		{
			_saveDat.data.layerList = new Array();
			for (var i:int=0;i<items.length;i++)
			{
				var o:LayerData  = items.getItemAt(i) as LayerData;
				_saveDat.data.layerList.push(o.Clone());
			}
			OnChange();
		}
		
		//potentially dangerous
		public function PushSound(sound:SoundData):void
		{
			_saveDat.data.soundList.push(sound.Clone());
			
			OnChange();
		}
		
		//potentially dangerous
		public function PushLayer(layer:LayerData):void
		{
			_saveDat.data.layerList.push(layer.Clone());
			
			OnChange();
		}
		
		//how dangerous is this?  might be good to make sure the object is locked when called
		public function GetID():int
		{
			var soundarray:Array = _saveDat.data.soundList;
			var curmax:int=0;
			for(var s:String in soundarray)
			{
				if (soundarray[s].id>curmax)
				{
					curmax=soundarray[s].id;
				}
			}
			
			var layerarray:Array = _saveDat.data.layerList;
			for(s in layerarray)
			{
				if (layerarray[s].id>curmax)
				{
					curmax=layerarray[s].id;
				}
			}
			
			return curmax+1;
		}
		
		public function GetSounds():Vector.<SoundData>
		{
			var result:Vector.<SoundData> = new Vector.<SoundData>();
			var soundarray:Array = _saveDat.data.soundList;
			for(var s:String in soundarray)
			{
				var o:Object = soundarray[s];
				var sd:SoundData = new SoundData(o.label,o.data,o.id);
				result.push(sd);
			}
			return result;
		}
		
		public function GetLayers():Vector.<LayerData>
		{
			var result:Vector.<LayerData> = new Vector.<LayerData>();
			var layerarray:Array = _saveDat.data.layerList;
			for(var s:String in layerarray)
			{
				var o:Object = layerarray[s];
				var ld:LayerData = new LayerData(o.label,o.data,o.id);
				result.push(ld);
			}
			return result;				
		}
		
		public function GetSoundDataWithID(id:int):SoundData
		{
			var soundarray:Array = _saveDat.data.soundList;
			for(var s:String in soundarray)
			{
				var o:Object = soundarray[s];
				var sd:SoundData = new SoundData(o.label,o.data,o.id);
				
				if (sd.id==id)
				{					
					return sd;
				}
			}
			throw new Error("couldn't find sound with id = " + id);			
		}
		
		public function GetLayerDataWithID(id:int):LayerData
		{
			var layerarray:Array = _saveDat.data.layerList;
			for(var s:String in layerarray)
			{
				var o:Object = layerarray[s];
				var ld:LayerData = new LayerData(o.label,o.data,o.id);
				
				if (ld.id==id)
				{					
					return ld;
				}
			}
			throw new Error("couldn't find layer with id = " + id);			
		}
		
		//returns true if changes were made (if current version is out of date)
		public function LoadData():void
		{
			if (_saveDat==null)
			{
				_saveDat = SharedObject.getLocal("com.increpare.bfxr-r4");
				//_saveDat.clear();
				
				if (_saveDat.data.version == undefined )
				{			
					//Default values
					_saveDat.data.soundList = new Array();
					_saveDat.data.layerList = new Array();
					_saveDat.data.selectedSoundItemID = -1;
					_saveDat.data.selectedLayerItemID = -1;
					_saveDat.data.version = SfxrSynth.version;
					_saveDat.data.samplerate = 0;
					_saveDat.data.bitdepth = 0;
					_saveDat.data.playonchange = true;
					_saveDat.data.createNew = true;
				}
				
				loadGlobal()
				
				OnChange();	
			}
			else
			{
				/*
				_saveDat.flush();
				_saveDat.close();
				_saveDat = null;
				_saveDat = SharedObject.getLocal("as3sfxr");
				*/
			}
		}

		
		private function OnChange():void
		{
			_saveDat.flush();
			/*
			workingversion++;
			trace("workingversion saving = " + workingversion);
			_saveDat.data.workingversion=this.workingversion;
			_saveDat.flush();*/
			//_saveDat.close();
			//_saveDat = null;
			//_saveDat = SharedObject.getLocal("as3sfxr");
		}
		
		/** returns -1 if no object found */
		public function UpdateSoundItem(newdata:SoundData):Boolean
		{
			var soundarray:Array = _saveDat.data.soundList;
			for(var s:String in soundarray)
			{
				if (soundarray[s].id==newdata.id)
				{
					soundarray[s] = newdata.Clone();
					return true;
				}
			}
			
			OnChange();

			return false;
		}
		
		/** returns -1 if no object found */
		public function UpdateLayerItem(newdata:LayerData):Boolean
		{
			var layerarray:Array = _saveDat.data.layerList;
			for(var s:String in layerarray)
			{
				if (layerarray[s].id==newdata.id)
				{
					layerarray[s] = newdata.Clone();
					return true;
				}
			}
			
			OnChange();
			
			return false;
		}
	}
}