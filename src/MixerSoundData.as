package
{
	import flash.utils.ByteArray;

	public class MixerSoundData
	{
		public var bytes:ByteArray;
		public var onset:Number;
		public var amplitudemodifier:Number;
		
		public function MixerSoundData(bytes:ByteArray, onset:Number, amplitudemodifier:Number)
		{
			this.bytes=bytes;
			this.onset=onset;
			this.amplitudemodifier=amplitudemodifier;
		}
	}
}