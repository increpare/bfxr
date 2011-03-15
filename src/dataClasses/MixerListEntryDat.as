package dataClasses
{
	import com.increpare.bfxr.synthesis.SfxrSynth;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;

	//class mainly to stop warning messages about being unable to bind properties
	[Bindable]
	[Event(REFRESH_SYNTH)]
	public class MixerListEntryDat extends EventDispatcher
	{
		public static const REFRESH_SYNTH:String = "RefreshSynth";
		
		private var _id:int=-1;
		public function get id():int
		{
			return _id;
		}

		public function setID(newid:int,app:sfxr_interface):void
		{
			_id=newid;
			if (_id>=0)
			{
				var index:int = app.GetIndexOfSoundItemWithID(_id);
				if (index>=0)
				{
					var sd:SoundData = app.soundItems.getItemAt(index) as SoundData;
					synth.Load(sd.data);
				}
				app.mixerInterface.RecalcDilation();
			}
		}
		
		public var bggroup:int		= 0;
		public var label:String		= "";
		public var data:String 		= "";
		public var synth:SfxrSynth 	= new SfxrSynth();
		public var cached:Boolean 	= false;
		public var dilation:Number  = 30;
		public var absolutePlayCallback:Function = null;
		public var PlayStartCallback:Function = null;
		public var PlayStopCallback:Function = null;
		public var SetDilationCallback:Function = null;		
		public var onset:Number = 0 ;
		public var amplitudemodifier:Number = 1;
		//set in order to trigger the container to fill out its data when initialized with data from a mixeritem
		public var preset:Boolean=false;
		
		public function MixerListEntryDat(id:int,app:sfxr_interface)
		{
			this.setID(id,app);
		}
		
	}
}