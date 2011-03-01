package
{
	import flash.events.EventDispatcher;
	
	// triggers whether or not to display a * next to the name
	[Event(name="changeStart", type="mx.events.FlexEvent")]
	[Event(name="changeEnd", type="mx.events.FlexEvent")]
	
	[Bindable]
	public class LayerData extends EventDispatcher
	{	
		public var label:String;
		public var data:String;
		public var id:int;
		public var modified:Boolean=false;
		
		public function LayerData(_label:String, _data:String,_id:int) 
		{
			label=_label;
			data=_data;
			id=_id;
		}
		
		public function Clone():SoundData
		{
			var result:SoundData = new SoundData(label,data,id);
			result.modified=modified;
			return result;
		}
		public function ToObject():Object
		{
			var o:Object = new Object();
			o.label=label;
			o.data=data;
			o.id=id;
			return o;
		}
	}
}