package dataClasses
{
	public class MixerItemParams
	{
			public var id:int=0;
			public var data:String;
			public var onset:Number = 0 ;
			public var amplitudemodifier:Number = 1;
			
			public function MixerItemParams(id:int, data:String, onset:Number, amplitudemodifier:Number)
			{
				this.id=id;
				this.onset=onset;
				this.data=data;
				this.amplitudemodifier=amplitudemodifier;
			}
		
	}
}