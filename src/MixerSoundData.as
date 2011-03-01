package
{
	import flash.utils.ByteArray;
	
	public class MixerSoundData
	{
		public var bytes:ByteArray;
		public var id:int;
		public var onset:Number;
		public var amplitudemodifier:Number;
		
		public function MixerSoundData(id:int,bytes:ByteArray, onset:Number, amplitudemodifier:Number)
		{
			this.id=id;
			this.bytes=bytes;
			this.onset=onset;
			this.amplitudemodifier=amplitudemodifier;
		}
	}
}