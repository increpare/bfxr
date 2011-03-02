package
{
	import flash.events.Event;
	
	import spark.components.CheckBox;
	import spark.components.DropDownList;
	import spark.components.List;

	public class GlobalState
	{
		public var playOnChange:Boolean
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
			var gle:LayerData = ddl.selectedItem as LayerData;
			this.selectedLayerItemID=gle.id;
		}
		
		public function OnSoundListSelectionChanged(event:Event):void
		{
			var ddl:List = event.target as List;
			var gle:SoundData = ddl.selectedItem as SoundData;
			this.selectedSoundItemID=gle.id;			
		}
		
		
		public function OnPlayOnChangeChange(event:Event):void
		{
			var cb:CheckBox = event.target as CheckBox;
			playOnChange = cb.selected;
		}
		
		public function GlobalState()
		{
		}
	}
}