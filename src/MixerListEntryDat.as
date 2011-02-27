package
{
	import flash.events.EventDispatcher;

	//class mainly to stop warning messages about being unable to bind properties
	[Bindable]
	public class MixerListEntryDat extends EventDispatcher
	{
		public var bggroup:int		= 0;
		public var label:String		= "";
		public var data:String 		= "";
		public var synth:SfxrSynth 	= null;
		public var cached:Boolean 	= false;
		public var synthset:Boolean = false;
		
		public var onset:Number = 0 ;
		public var amplitudemodifier:Number = 1;
		
	}
}