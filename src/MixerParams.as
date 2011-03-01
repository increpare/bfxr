package
{
	public class MixerParams implements ISerializable
	{
		public var items:Vector.<MixerItemParams>;
		public var volume:Number;
		
		public function MixerParams()
		{
			items = new Vector.<MixerItemParams>();
			
		}
		
		public function getSettingsString():String
		{
			var result:String = "";
			for (var i:int=0;i<this.items.length;i++)
			{
				if (i>0)
					result+=",";
				
				result += items[i].id+","+items[i].onset+","+items[i].amplitudemodifier;
			}
			return result;
		}
		
		public function setSettingsString(settings:String):Boolean
		{
			//stop all caching
			
			//remove everything
			items = new Vector.<MixerItemParams>()
			
			var params:Array = settings.split(",");
			//start adding stuff
			
			for (var i:int=1;i<params.length;i+=3)
			{
				items.push(new MixerItemParams(int(params[i-1]),Number(params[i]),Number(params[i+1])));
			}
			//cache everything
			return true;	
		}
	
	}
}