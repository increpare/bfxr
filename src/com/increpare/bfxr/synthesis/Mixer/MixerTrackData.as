package com.increpare.bfxr.synthesis.Mixer
{
	import com.increpare.bfxr.synthesis.ISerializable;

	public class MixerTrackData implements ISerializable
	{
		public var id:int			= -1 ; // id of target track
		public var offset:Number	=  0 ;
		public var volume:Number	=  1 ;
		public var synthdata:String	= "" ; // if this is "", then track not set
		
		public function MixerTrackData()
		{
		}
		
		public function Serialize():String
		{
			var result:String="";
			result += id.toString()+"|";
			result += synthdata+"|";
			result += offset+"|";
			result += volume;
			return result;
		}
		
		public function Deserialize(settings:String):void
		{
			var ar:Array = settings.split("|");
			id = int(ar[0]);
			synthdata = ar[1];
			offset = Number(ar[2]);
			volume = Number(ar[3]);
		}
	}
}