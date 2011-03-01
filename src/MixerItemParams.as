package
{
	public class MixerItemParams
	{
			public var id:int=0;
			public var onset:Number = 0 ;
			public var amplitudemodifier:Number = 1;
			
			public function MixerItemParams(id:int, onset:Number, amplitudemodifier:Number)
			{
				this.id=id;
				this.onset=onset;
				this.amplitudemodifier=amplitudemodifier;
			}
		
	}
}