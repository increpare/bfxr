package
{
	[Bindable]
	public class SoundData
	{	
		public var label:String;
		public var data:String;
		public var id:int;
		
		public function SoundData(_label:String, _data:String,_id:int)
		{
			label=_label;
			data=_data;
			id=_id;
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