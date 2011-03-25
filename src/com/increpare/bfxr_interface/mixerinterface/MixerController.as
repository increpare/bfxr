package com.increpare.bfxr_interface.mixerinterface
{
	import com.increpare.bfxr.synthesis.ISerializable;
	import com.increpare.bfxr.synthesis.Mixer.MixerPlayer;
	import com.increpare.bfxr.synthesis.Mixer.MixerSynth;
	import com.increpare.bfxr.synthesis.Mixer.MixerTrackPlayer;
	import com.increpare.bfxr.synthesis.Synthesizer.SfxrSynth;
	
	import com.increpare.bfxr_interface.components.MixerRowRenderer;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayList;
	import com.increpare.bfxr_interface.components.Bfxr_interface;

	public class MixerController implements ISerializable
	{
		
		public var mixerPlayer:MixerPlayer;
		
		[Bindable]
		public var trackViews:ArrayList;
		
		public var trackControllers:Vector.<MixerTrackController>;
		
		private var _app:Bfxr_interface;
		
		public function MixerController(app:Bfxr_interface)
		{
			_app=app;
			
			mixerPlayer = new MixerPlayer();
			trackViews = new ArrayList();
			trackControllers = new Vector.<MixerTrackController>();
			
			for (var i:int=0;i<MixerSynth.TRACK_COUNT;i++)
			{
				var mtv:MixerTrackView = new MixerTrackView();
				trackViews.addItem(mtv);
				var mtc:MixerTrackController = new MixerTrackController(app);
				mtc.RegisterView(mtv,i,this);
				trackControllers.push(mtc);
			}
			
			mixerPlayer.addEventListener(SfxrSynth.PLAY_COMPLETE, MixerPlayOnComplete);
		}
		
		public function Serialize():String
		{
			return mixerPlayer.Serialize();
		}
		
		public function Deserialize(settings:String):void
		{
			mixerPlayer.Deserialize(settings);
			RefreshUI();
		}		
		
		public function RefreshUI():void
		{
			//update onset + graphic
			RecalcTrackLength();
			
			for (var i:int=0;i<mixerPlayer.tracks.length;i++)
			{
				// update volume
				var mtp:MixerTrackPlayer = mixerPlayer.tracks[i];
				var mtv:MixerTrackView = trackViews.getItemAt(i) as MixerTrackView;
				mtv.volume = mtp.data.volume;
				mtv.reverse=mtp.data.reverse;
								
				// update dropdown id
				mtv.trackindex = _app.GetIndexOfSoundItemWithID(mtp.data.id);				
			}
			
			
			// update shared components			
			if (_app.tabs.selectedIndex==1)
			{
				_app.mixerInterface.UpdateSharedComponents();
			}
		}
		
		public function TrackLength():Number
		{
			var trackLength:Number = -1;			
			var mtp:MixerTrackPlayer;
			
			for (var i:int=0;i<mixerPlayer.tracks.length;i++)
			{
				mtp = mixerPlayer.tracks[i];
				if (mtp.IsSet()==false)
				{
					continue;
				}
				
				var l:Number = mtp.synth.GetLength();
				
				if (l>trackLength)
				{
					trackLength=l;
				}
			}
								
			//actually, tracklength is twice the length of the max sound length;
			trackLength*=2;
			
			//safe enough I guess - all graphics should be disabled by this time, so.
			if (trackLength<0)
				trackLength=1;
			
			return trackLength;
		}
		
		public function RecalcTrackLength(allowredraw:Boolean=true):void
		{
			//calc the length (in seconds)
			var trackLength:Number = TrackLength();
			
			//clamp the onsets as appropriate
					
			for (var i:int=0;i<mixerPlayer.tracks.length;i++)
			{
				var mtp:MixerTrackPlayer = mixerPlayer.tracks[i];
				if (mtp.IsSet()==false)
				{
					continue;
				}
				if (mtp.data.onset+mtp.synth.GetLength()>trackLength)
				{
					mtp.data.onset=trackLength - mtp.synth.GetLength();
				}
			}
			
			//regenerate onsets + graphics in view
			if (allowredraw)
			{
				RefreshWaveView(trackLength);
			}
		}
		
		private function RefreshWaveView(trackLength:Number):void
		{
			var i:int;
			for (i=0;i<mixerPlayer.tracks.length;i++)
			{				
				var mtc:MixerTrackController = this.trackControllers[i];
				mtc.DrawWave();
			}
		}
					
		public function Play():void
		{
			PrepareForPlay();
			mixerPlayer.play(MixerPlayCallback);
		}				
		
		private function MixerPlayCallback(n:Number):void
		{
			
			for (var i:int = 0; i < trackControllers.length; i++)
			{
				var mtc:MixerTrackController = this.trackControllers[i];
				mtc.PlayCallback_Mixer(n);
			}
		}
		
		private function PrepareForPlay():void
		{
			//indirectly calls mixerstopall
			_app.StopAll();
		}
		
		public function MixerStopAll(event:Event = null):void
		{
			mixerPlayer.stop();
			for (var i:int = 0; i < this.trackViews.length; i++)
			{
				var mtv:MixerTrackView = trackViews.getItemAt(i) as MixerTrackView;
				var mtp:MixerTrackPlayer = this.mixerPlayer.tracks[i];

				mtp.synth.stop();
				mtp.waveplayer.stop();
				mtv.playbarposition=-1;				
			}
		}
						
		public function MixerPlayOnComplete(event:Event = null):void
		{
			for (var i:int = 0; i < this.trackViews.length; i++)
			{
				var mtv:MixerTrackView = trackViews.getItemAt(i) as MixerTrackView;				
				mtv.playbarposition=-1;				
			}
		}
		
		
	}
}