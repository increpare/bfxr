package Mixer
{
	import com.increpare.bfxr.synthesis.Mixer.MixerPlayer;
	import com.increpare.bfxr.synthesis.Mixer.MixerTrackPlayer;
	import com.increpare.bfxr.synthesis.Synthesizer.SfxrSynth;
	
	import components.MixerRowRenderer;
	
	import dataClasses.SoundData;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import spark.primitives.Graphic;

	public class MixerTrackController
	{
		private var _index:int=-1;//its position in the track list
		private var _app:sfxr_interface;
		private var _parent:MixerController;
		private var _trackView:MixerTrackView;
		private var _trackPlayer:MixerTrackPlayer;
		
		public function RegisterView(mtv:MixerTrackView,index:int,parent:MixerController):void
		{
			_index=index;
			_parent=parent;
			_trackView = mtv;
			_trackPlayer = parent.mixerPlayer.tracks[_index];	
			
			_trackPlayer.synth.addEventListener(SfxrSynth.PLAY_COMPLETE,PlayCallback_OnFinished);				
			
			mtv.OnMixerDropdownClick=	this.OnMixerDropdownClick;
			mtv.OnMixerVolumeClick=		this.OnMixerVolumeClick;
			mtv.OnMixerOnsetClick=		this.OnMixerMixerOnsetClick;
			mtv.OnMixerPlayClick=		this.OnPlayClick;
			mtv.OnMixerClearClick=		this.OnMixerClearClick;
			mtv.OnMixerStartDrag=		this.OnMixerStartDrag;
		}
		
		/* 
			these updates are supposed to update the relevant MixerTrackData fields as well as doing any additional ui calculations/updates that might be called for.
		*/
		
		private function OnMixerDropdownClick():void 
		{ 
			var id:int;
			if (_trackView.trackindex>=0)
			{
				var sd:SoundData = SoundData(_app.soundItems.getItemAt(_trackView.trackindex));
				_trackPlayer.LoadSynth(sd);
				_parent.RecalcTrackLength();
			}
			else
			{
				//won't be hidden unless made null.
				_trackPlayer.data.onset=0;
				_trackView.onset=0;
				_trackPlayer.data.volume=1;
				_trackView.volume=1;
				
				_trackPlayer.LoadSynth(null);
				_parent.RecalcTrackLength();
			}
			_app.mixerInterface.OnParameterChanged(true,true);
		}		
		
		public function DrawWave():void
		{
				
			var mtp:MixerTrackPlayer = _trackPlayer;
			var mtv:MixerTrackView = _trackView;
			
			if (mtp.IsSet()==false)
			{
				mtv.graphic=null;
				return;
			}
			
			var trackLength:Number = _parent.TrackLength();
			
			mtv.onset = mtp.data.onset*MixerRowRenderer.GraphWidth/trackLength;			
			
			var sliderimage:Bitmap = new Bitmap();				
			sliderimage.bitmapData = new BitmapData(Math.max(1,mtp.synth.GetLength()*MixerRowRenderer.GraphWidth/trackLength),MixerRowRenderer.GraphHeight,false,0xe7d1a7);
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
		
		private function OnMixerVolumeClick():void 
		{ 			
			_trackPlayer.data.volume = _trackView.volume;		
			DrawWave();			
			_app.mixerInterface.OnParameterChanged(true,true);
		}
		
		private function OnMixerMixerOnsetClick():void 
		{ 
			//convert view onset to actual onset
			
			var tl:Number = _parent.TrackLength();
			
			_trackPlayer.data.onset = _trackView.onset * tl / MixerRowRenderer.GraphWidth;
			_app.mixerInterface.OnParameterChanged(true,true);
		}
		
		private function OnPlayClick():void 
		{ 			
			_trackView.playbarposition=0;
			_trackPlayer.synth.play(PlayCallback_Track);
		}
		
		private function PlayCallback_Track(playingtime:Number):void
		{
			var tl:Number = _parent.TrackLength();			
			_trackView.playbarposition=_trackView.onset + (playingtime * MixerRowRenderer.GraphWidth / tl);
		}
		
		public function PlayCallback_Mixer(playingtime:Number):void
		{
			var tl:Number = _parent.TrackLength();			
			_trackView.playbarposition=playingtime * MixerRowRenderer.GraphWidth / tl;
		}
		
		private function PlayCallback_OnFinished(e:Event=null):void
		{
			_trackView.playbarposition=-1;
		}
		
		private function OnMixerClearClick():void 
		{ 			
			_trackView.trackindex=-1;
			OnMixerDropdownClick();
		}
		
		/* called when a person starts changing the onset or volume, stops play */
		private function OnMixerStartDrag():void
		{
			_parent.MixerStopAll();
		}
		
		public function MixerTrackController(app:sfxr_interface)
		{
			_app=app;
			
		}				
	}
}