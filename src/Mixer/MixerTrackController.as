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
			
			mtv.OnMixerDropdownClick=this.OnMixerDropdownClick;
			mtv.OnMixerVolumeClick=this.OnMixerVolumeClick;
			mtv.OnMixerOnsetClick=this.OnMixerMixerOnsetClick;
			mtv.OnMixerPlayClick=this.OnPlayClick;
			mtv.OnMixerClearClick=this.OnMixerClearClick;
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
				_trackPlayer.LoadSynth(null);
				_parent.RecalcTrackLength();
			}
			_app.mixerInterface.OnParameterChanged(true,true);
		}		
		
		private function OnMixerVolumeClick():void 
		{ 
			
			_app.mixerInterface.OnParameterChanged(true,true);
		}
		
		private function OnMixerMixerOnsetClick():void 
		{ 
			//convert view onset to actual onset
			
			var tl:Number = _parent.TrackLength();
			
			_trackPlayer.data.offset = _trackView.onset * tl / MixerRowRenderer.GraphWidth;
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
		
		public function MixerTrackController(app:sfxr_interface)
		{
			_app=app;
			
		}				
	}
}