package com.increpare.bfxr_interface.mixerinterface
{
	import flash.display.Bitmap;

	[Bindable]
	public class MixerTrackView
	{
		//controller functions called by the renderer
		public var OnMixerDropdownClick:Function;
		public var OnMixerVolumeClick:Function;
		public var OnMixerOnsetClick:Function;
		public var OnMixerPlayClick:Function;
		public var OnMixerReverseClick:Function;
		public var OnMixerStartDrag:Function;//used to stop playback
		
		public var trackindex:int=-1;		//index, not ID
		public var volume:Number=0;
		public var onset:int=0;				//in pixels
		public var graphic:Bitmap;			//if null, hides
		public var playbarposition:int=-1; 	//in pixels, -1 means not visible
		public var reverse:Boolean = false;
		
		public function MixerTrackView()
		{
		}
	}
}