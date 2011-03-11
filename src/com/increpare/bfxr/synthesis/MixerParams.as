package com.increpare.bfxr.synthesis
{
	public class MixerParams implements ISerializable
	{
		public var items:Vector.<MixerItemParams>;
		public var volume:Number;
		
		public static const CHANNELCOUNT:int=5;
		
		
		public function MixerParams()
		{
			items = new Vector.<MixerItemParams>();
			for (var i:int=0;i<CHANNELCOUNT;i++)
			{
				var mip:MixerItemParams = new MixerItemParams(-1,"",0,1);
				items.push(mip);
			}
		}
		
		public function getSettingsString():String
		{
			var result:String = "";
			for (var i:int=0;i<this.items.length;i++)
			{
				if (i>0)
					result+="|";
				
				result += items[i].id+"|"+items[i].data+"|"+ items[i].onset+"|"+items[i].amplitudemodifier;
			}
			return result;
		}
		
		public function setSettingsString(settings:String):Boolean
		{					
			//remove everything
			items = new Vector.<MixerItemParams>()
						
			var params:Array = settings.split("|");
			//start adding stuff
			
			for (var i:int=1;i<params.length;i+=4)
			{
				items.push(new MixerItemParams(int(params[i-1]),params[i],Number(params[i+1]),Number(params[i+2])));
			}
			//cache everything
			return true;	
		}
	
	}
}