package Mixer
{
	import com.increpare.bfxr.synthesis.ISerializable;
	import com.increpare.bfxr.synthesis.Mixer.MixerPlayer;
	import com.increpare.bfxr.synthesis.Mixer.MixerSynth;
	import com.increpare.bfxr.synthesis.Mixer.MixerTrackPlayer;
	import com.increpare.bfxr.synthesis.Synthesizer.SfxrSynth;
	
	import components.MixerRowRenderer;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayList;

	public class MixerController implements ISerializable
	{
		
		public var mixerPlayer:MixerPlayer;
		public var trackViews:ArrayList;
		public var trackControllers:Vector.<MixerTrackController>;
		
		private var _app:sfxr_interface;
		
		public function MixerController(app:sfxr_interface)
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
		
		public function RecalcTrackLength():void
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
				if (mtp.data.offset+mtp.synth.GetLength()>=trackLength)
				{
					mtp.data.offset=trackLength - mtp.synth.GetLength();
				}
			}
			
			//regenerate onsets + graphics in view
			RefreshWaveView(trackLength);
		}
		
		private function RefreshWaveView(trackLength:Number):void
		{
			var i:int;
			for (i=0;i<mixerPlayer.tracks.length;i++)
			{
				var mtp:MixerTrackPlayer = mixerPlayer.tracks[i];
				var mtv:MixerTrackView = trackViews.getItemAt(i) as MixerTrackView;
				mtv.onset = mtp.data.offset*MixerRowRenderer.GraphWidth/trackLength;
				
				if (mtp.IsSet()==false)
				{
					mtv.graphic=null;
					continue;
				}
				
				
						
				var sliderimage:Bitmap = new Bitmap();				
				sliderimage.bitmapData = new BitmapData(mtp.synth.GetLength()*MixerRowRenderer.GraphWidth/trackLength,MixerRowRenderer.GraphHeight,false,0xe7d1a7);
				sliderimage.width = sliderimage.bitmapData.width;
				sliderimage.height = sliderimage.bitmapData.height;
				
				var synth:SfxrSynth = mtp.synth;
				var cachedWave:ByteArray = mtp.synth.cachedWave;
				var dilation:Number=10;
				var length:Number = Math.max(3,cachedWave.length*dilation/(4*44100.0));
				
				var d:int = int(cachedWave.length/(4*sliderimage.width))*4;
				var points : Vector.<Number> = new Vector.<Number>();
				var amplitudemodifier:Number =  mtp.data.volume;
				for (var j:int=0;j<sliderimage.width-1;j++)
				{
					//sample fivepoints in this range, and take the max
					
					cachedWave.position = int(cachedWave.length/(sliderimage.width*4))*j*4; 
					
					var curmax:Number=0;
					for (var k:int=0;k<10;k++)
					{
						var cand:Number = Math.abs(cachedWave.readFloat());
						if (cand>curmax)
							curmax=cand;
						cachedWave.position=cachedWave.position+int(d/(4*10))*4-4;
					}
					//scale + clamp
					curmax=Math.min(curmax*amplitudemodifier,4);
					points.push(curmax);
				}						
				
				for (j=0;j<sliderimage.width-1;j++)
				{					
					sliderimage.bitmapData.fillRect(new Rectangle(j,sliderimage.height/2-points[j]*sliderimage.height/2,1,2*points[j]*sliderimage.height/2),0x000000);
				}
				mtv.graphic=sliderimage;
				
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
			MixerPlayStopAll();
			for (var i:int=0;i<this.trackViews.length;i++)
			{
				
			}
		}
		
		public function MixerPlayStopAll(event:Event = null):void
		{
			mixerPlayer.stop();
			for (var i:int = 0; i < this.trackViews.length; i++)
			{
				var mtv:MixerTrackView = trackViews.getItemAt(i) as MixerTrackView;
				var mtp:MixerTrackPlayer = this.mixerPlayer.tracks[i];

				mtp.synth.stop();
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