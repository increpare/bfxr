package com.increpare.bfxr.synthesis
{
	import com.increpare.bfxr.synthesis.Synthesizer.SfxrSynth;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;

	public class WavePlayer extends EventDispatcher
	{
		public function WavePlayer()
		{
		}
				
		private var _sound:Sound;
		private var _channel:SoundChannel;
		private var _updateCallback:Function;
		
		private var _waveData:ByteArray;					// Full wave, read out in chuncks by the onSampleData method
		private var _waveDataPos:uint;						// Current position in the waveData
		private var _waveDataLength:uint;					// Number of bytes in the waveData
		private var _waveDataBytes:uint;					// Number of bytes to write to the soundcard
				
		public function play(waveData:ByteArray,updateCallback:Function = null,volume:Number=1):void
		{
			stop();
			
			_waveData=waveData;
			_waveData.position=0;	
			_waveDataLength = _waveData.length;
			_waveDataBytes = 24576;
			_waveDataPos = 0;					
			_updateCallback=updateCallback;			
			
			if (!_sound) (_sound = new Sound()).addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			
			_channel = _sound.play(0,0,new SoundTransform(volume));
		}
			
		public function stop():void
		{
			if(_channel) 
			{
				_channel.stop();
				_channel = null;
			}
		}
		
		private function onSampleData(e:SampleDataEvent):void
		{			
			if (_updateCallback!=null)
			{
				_updateCallback(_waveDataPos/(4*44100));
			}
			
			if(_waveDataPos + _waveDataBytes > _waveDataLength) 
			{
				_waveDataBytes = _waveDataLength - _waveDataPos;
				dispatchEvent(new Event(SfxrSynth.PLAY_COMPLETE));	
			}
			
			if(_waveDataBytes > 0) 
			{
				e.data.writeBytes(_waveData, _waveDataPos, _waveDataBytes);
			}
			
			_waveDataPos += _waveDataBytes;						
		}
	}
}