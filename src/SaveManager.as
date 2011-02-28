package
{
	import flash.net.SharedObject;
	
	import mx.collections.ArrayList;
	
	public class SaveManager
	{
		private var _saveDat:SharedObject;
		private var _parent:sfxr_interface;
		
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
		
		public function get selectedItemID():int
		{
			return _saveDat.data.selectedItemID;
		}
		
		public function SaveManager(parent:sfxr_interface)
		{
			_parent=parent;
			_saveDat = null;		
		}
		
		public function commitGlobal(samplerate:int,bitdepth:int,playonchange:Boolean, selectedItemID:int):void
		{
			//don't need to worry about tripping over other people's values			
			_saveDat.data.samplerate = samplerate;
			_saveDat.data.bitdepth = bitdepth;
			_saveDat.data.playonchange = playonchange;
			_saveDat.data.selectedItemID = selectedItemID;			
			OnChange();	
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
		
		public function RemoveItemWithID(id:int):void
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
		
		//potentially dangerous
		public function PushSound(sound:SoundData):void
		{
			_saveDat.data.soundList.push(sound.Clone());
			
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
			
			return curmax+1;
		}
		
		public function GetSoundDataWithID(id:int):SoundData
		{
			var soundarray:Array = _saveDat.data.soundList;
			var curmax:int=0;
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
		
		
		//returns true if changes were made (if current version is out of date)
		public function LoadData():void
		{
			if (_saveDat==null)
			{
				_saveDat = SharedObject.getLocal("com.increpare.as3sfxr-b2");
				//_saveDat.clear();
				if (_saveDat.data.version == undefined )
				{			
					//Default values
					_saveDat.data.soundList = new Array();
					_saveDat.data.selectedItemID = -1;
					_saveDat.data.version = SfxrSynth.version;
					_saveDat.data.samplerate = 0;
					_saveDat.data.bitdepth = 0;
					_saveDat.data.playonchange = true;
				}
				else if (_saveDat.data.version == 103)
				{
					_saveDat.data.selectedItemID = -1;	
					var itemlist:Array = _saveDat.data.soundList;
					for (var s:String in itemlist)
					{
						trace("string id = " + s);
						itemlist[s].id=s;
					}
					_saveDat.data.version = SfxrSynth.version;
				}
				
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
		public function UpdateItem(newdata:SoundData):Boolean
		{
			var soundarray:Array = _saveDat.data.soundList;
			var curmax:int=0;
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
		
	}
}