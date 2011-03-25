package com.increpare.bfxr_interface
{
	import com.increpare.bfxr.dataClasses.LayerData;
	import com.increpare.bfxr.dataClasses.SoundData;
	
	import flash.events.Event;
	
	import spark.components.CheckBox;
	import spark.components.DropDownList;
	import spark.components.List;

	public class GlobalState
	{
		public var playOnChange:Boolean
		public var createNew:Boolean;
		public var selectedSoundItemID:int;
		public var selectedLayerItemID:int;
				
		public function OnLayerListSelectionChanged(event:Event):void
		{
			var ddl:List = event.target as List;
			var o:Object = ddl.selectedItem;
			// Don't know how to get around this.  It *shouldn't* be null, but when 'loading all' it is. 
			if (o)
			{
				var gle:LayerData = o as LayerData;
				this.selectedLayerItemID=gle.id;
			}
		}
		
		public function OnSoundListSelectionChanged(event:Event):void
		{
			var ddl:List = event.target as List;
			var gle:SoundData = ddl.selectedItem as SoundData;
			if (gle)
			{
				this.selectedSoundItemID=gle.id;
			}
			else
			{
				trace("gle not found :/ ");
			}
		}
		
		
		public function OnPlayOnChangeChange(event:Event):void
		{
			var cb:CheckBox = event.target as CheckBox;
			playOnChange = cb.selected;
		}
		
		
		public function OnCreateNewChange(event:Event):void
		{
			var cb:CheckBox = event.target as CheckBox;
			createNew = cb.selected;
		}
		
		
		public function GlobalState()
		{
		}
		
		public function Serialize():String
		{
			return playOnChange.toString()+","
					+createNew.toString()+","
					+selectedSoundItemID.toString()+","
					+selectedLayerItemID.toString();
		}
		
		public function Deserialize(dat:String):void
		{
			var ar:Array = dat.split(",");
			playOnChange=ar[0]=="false"?false:true;
			createNew=ar[1]=="false"?false:true;
			selectedSoundItemID=int(ar[2]);
			selectedLayerItemID=int(ar[3]);
		}
	}
}