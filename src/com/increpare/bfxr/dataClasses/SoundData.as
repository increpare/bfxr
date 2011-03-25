package com.increpare.bfxr.dataClasses
{
	public class SoundData extends ItemData
	{
		public function SoundData(_label:String, _data:String, _id:int)
		{
			super(_label, _data, _id);
		}
		
		
		public static function Deserialize(source:String):SoundData
		{
			var a:Array = source.split(":");
			
			return new SoundData(a[0],a[1],int(a[2]));
		}
	}
}