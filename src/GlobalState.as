package
{
	import dataClasses.LayerData;
	import dataClasses.SoundData;
	
	import flash.events.Event;
	
	import spark.components.CheckBox;
	import spark.components.DropDownList;
	import spark.components.List;

	public class GlobalState
	{
		public var playOnChange:Boolean
		public var modifyExisting:Boolean;
		public var sampleRate:int;
		public var bitDepth:int;
		public var selectedSoundItemID:int;
		public var selectedLayerItemID:int;
		
		public function OnSampleRateChange(event:Event):void
		{
			var ddl:DropDownList = event.target as DropDownList;
			var gle:GenericListEntry = ddl.selectedItem as GenericListEntry;
			sampleRate = int(gle.data);
		}
		
		public function OnBitDepthChange(event:Event):void
		{
			var ddl:DropDownList = event.target as DropDownList;
			var gle:GenericListEntry = ddl.selectedItem as GenericListEntry;
			bitDepth = int(gle.data);			
		}
		
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
		
		
		public function OnModifyExistingChange(event:Event):void
		{
			var cb:CheckBox = event.target as CheckBox;
			modifyExisting = cb.selected;
		}
		
		
		public function GlobalState()
		{
		}
		
		public function Serialize():String
		{
			return playOnChange.toString()+","
					+modifyExisting.toString()+","
					+sampleRate.toString()+","
					+bitDepth.toString()+","
					+selectedSoundItemID.toString()+","
					+selectedLayerItemID.toString();
		}
		
		public function Deserialize(dat:String):void
		{
			var ar:Array = dat.split(",");
			playOnChange=ar[0]=="false"?false:true;
			modifyExisting=ar[1]=="false"?false:true;
			sampleRate=ar[2];
			bitDepth=ar[3];
			selectedSoundItemID=ar[4];
			selectedLayerItemID=ar[5];
		}
	}
}