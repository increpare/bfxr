package com.increpare.bfxr.dataClasses
{
	import flash.events.EventDispatcher;
	
	// triggers whether or not to display a * next to the name
	[Event(name="changeStart", type="mx.events.FlexEvent")]
	[Event(name="changeEnd", type="mx.events.FlexEvent")]
	
	[Bindable]
	public class ItemData extends EventDispatcher
	{	
		public var label:String;
		public var data:String;
		public var id:int;
		public var modified:Boolean=false;
		
		public function ItemData(_label:String, _data:String,_id:int) 
		{
			label=_label;
			data=_data;
			id=_id;
		}
		
		public function Clone():ItemData
		{
			var result:ItemData = new ItemData(label,data,id);
			result.modified=modified;
			return result;
		}
		
		public function Serialize():String
		{
			return label+":"+data+":"+id;
		}		
	}
}