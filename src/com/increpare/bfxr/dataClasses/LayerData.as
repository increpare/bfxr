package com.increpare.bfxr.dataClasses
{
	public class LayerData extends ItemData
	{
		public function LayerData(_label:String, _data:String, _id:int)
		{
			super(_label, _data, _id);
		}
			
		public static function Deserialize(source:String):LayerData
		{
			var a:Array = source.split(":");
			
			return new LayerData(a[0],a[1],int(a[2]));
		}
	}
}