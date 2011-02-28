package
{
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.utils.ByteArray;
	import flash.events.Event;
	
	public class Mixer extends EventDispatcher
	{
		private var sourcesounds:Vector.<MixerSoundData>;		
		
		//sounds with offset added
		private var preparedsounds:Vector.<ByteArray>;
		
		public var _dirty:Boolean;
		private var _trackcount:int;
		private var _sound:Sound;
		private var _channel:SoundChannel;
		
		private var _waveData:ByteArray;
		private var _waveDataPos:uint;						// Current position in the waveData
		private var _waveDataLength:uint;					// Number of bytes in the waveData
		private var _waveDataBytes:uint;					// Number of bytes to write to the soundcard
		private var _updateCallback:Function;
		private var _zeros:ByteArray;
		
		public function Mixer()
		{
			_dirty=true;
			_zeros = new ByteArray();
			for (var i:int=0;i<400000;i++)
			{
				_zeros.writeFloat(0.0);
			}
		}
		
		public function Clear():void
		{
			sourcesounds = new Vector.<MixerSoundData>();
			_dirty=true;
		}
		
		public function AddTrack(b:MixerSoundData):void
		{
			sourcesounds.push(b);
			_dirty=true;
		}
		
		public function Play(updateCallback:Function=null):void
		{
			_updateCallback=updateCallback;
			
			_trackcount = sourcesounds.length;
			for (var i:int=0;i<_trackcount;i++)
			{
				sourcesounds[i].bytes.position=0;
			}
			
			//copy tracks over and add whitespace
			preparedsounds = new Vector.<ByteArray>();
			for (i=0;i<_trackcount;i++)
			{
				var b:ByteArray = new ByteArray();
			
				var silentbytes:int = int(sourcesounds[i].onset*44100)*4;
				
				// create starting silence.
				while(silentbytes>0)
				{
					var bytestocopy:int=Math.min(silentbytes,_zeros.length);
					
					b.writeBytes(_zeros,0,bytestocopy);
					
					silentbytes-=bytestocopy;
				}
				
				b.writeBytes(sourcesounds[i].bytes);
				
				b.position=0;
				preparedsounds.push(b);
			}
			
			if (_channel)
			{
				_channel.stop();
			}
			
			if (_dirty)
			{
				Mix();
			}			
			
			_waveData.position = 0;
			_waveDataLength = _waveData.length;
			_waveDataBytes = 24576;
			_waveDataPos = 0; 	
			_caching=true;
			if (!_sound) (_sound = new Sound()).addEventListener(SampleDataEvent.SAMPLE_DATA, onSoundData);
		
			_channel = _sound.play();
		}
		
		private function Mix():void
		{
			_waveData = new ByteArray();
			
			for (var i:int=0;i<preparedsounds.length;i++)
			{
				preparedsounds[i].position=0;
			}
			
			var added:Boolean=true;
			while (added)
			{
				added=false;
				var val:Number=0;
				for (i=0;i<_trackcount;i++)
				{
					if (preparedsounds[i].position<preparedsounds[i].length-4)
					{
						val+=preparedsounds[i].readFloat()*sourcesounds[i].amplitudemodifier;
						added=true;
					}
				}
				
				_waveData.writeFloat(val);
			}
			

			
			_dirty=false;
		}
		
		private var _caching:Boolean=false;
		
		private function onSoundData(e:SampleDataEvent) : void
		{		
			if (_updateCallback!=null)
			{
				_updateCallback(_waveDataPos/(4*44100));
			}
			
			if (_caching)
			{
				if(_waveDataPos + _waveDataBytes > _waveDataLength)
				{
					_waveDataBytes = _waveDataLength - _waveDataPos;
					dispatchEvent(new Event(SfxrSynth.PLAY_COMPLETE));	
				}
				
				if(_waveDataBytes > 0) e.data.writeBytes(_waveData, _waveDataPos, _waveDataBytes);
							
				//if too short..append data
				if (e.data.length<_waveDataBytes) 
				{
					_caching=false;
					while (e.data.length<_waveDataBytes)
					{
						e.data.writeFloat(0.0);
					}
				}
				
				_waveDataPos += _waveDataBytes;	
			}
		}
		
	}
}