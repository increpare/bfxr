package
{
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;

	//class mainly to stop warning messages about being unable to bind properties
	[Bindable]
	public class MixerListEntryDat extends EventDispatcher
	{
		public var id:int=0;
		public var bggroup:int		= 0;
		public var label:String		= "";
		public var data:String 		= "";
		public var synth:SfxrSynth 	= null;
		public var cached:Boolean 	= false;
		public var synthset:Boolean = false;
		public var dilation:Number  = 30;
		public var absolutePlayCallback:Function = null;
		public var PlayStartCallback:Function = null;
		public var PlayStopCallback:Function = null;
		public var SetDilationCallback:Function = null;
		public var CalcLengthCallback:Function = null;
		
		public var onset:Number = 0 ;
		public var amplitudemodifier:Number = 1;
		//set in order to trigger the container to fill out its data when initialized with data from a mixeritem
		public var preset:Boolean=false;
		
		public function MixerListEntryDat(id:int)
		{
			this.id=id;
		}
		
	}
}