package synthesis
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class Mixer extends EventDispatcher
	{				
		private var sourcesounds:Vector.<MixerSoundData>;		
		
		//sounds with offset added
		private var preparedsounds:Vector.<ByteArray>;
		
		public var params:MixerParams;
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
			params = new MixerParams();
		}
		
		public function Clear():void
		{
			sourcesounds = new Vector.<MixerSoundData>();
			_dirty=true;
		}
		
		public function AddTrack(b:MixerSoundData):void
		{
			trace("adding track to mixer w/ id " + b.id);
			sourcesounds.push(b);
			_dirty=true;
		}
		
		public function Play(updateCallback:Function=null):void
		{
			_updateCallback=updateCallback;
			
			_trackcount = sourcesounds.length;
			if (_trackcount==0)
				return;
			
			for (var i:int=0;i<_trackcount;i++)
			{
				sourcesounds[i].bytes.position=0;
			}
			
			
			if (_dirty)
			{
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
							
				Mix();
			}			
			
			if (_channel)
			{
				_channel.stop();
			}
			
			_waveData.position = 0;
			_waveDataLength = _waveData.length;
			_waveDataBytes = 24576;
			_waveDataPos = 0; 	
			_caching=true;
			if (!_sound) (_sound = new Sound()).addEventListener(SampleDataEvent.SAMPLE_DATA, onSoundData);
		
			_channel = _sound.play();
		}
		
		/** param is whether to work in bytes, shorts, or floats (1,2,4)*/
		private function Mix(unitsize:int=4):void
		{
			_waveData = new ByteArray();
			
			for (var i:int=0;i<preparedsounds.length;i++)
			{
				preparedsounds[i].position=0;
			}
			
			var added:Boolean=true;
			
			switch(unitsize)
			{
				case 1:
					while (added)
					{
						added=false;
						var val:int=0;
						for (i=0;i<_trackcount;i++)
						{
							if (preparedsounds[i].position<preparedsounds[i].length-unitsize)
							{
								val += preparedsounds[i].readByte()*sourcesounds[i].amplitudemodifier;
								added=true;
							}
						}
						
						if (val >= (1<<7))
							val=1<<7;
						if (val<= -(1<<7))
							val=-(1<<7);
						
						_waveData.writeByte(val);
					}
					break;
				case 2:
					while (added)
					{
						added=false;
						val=0;
						for (i=0;i<_trackcount;i++)
						{
							if (preparedsounds[i].position<preparedsounds[i].length-unitsize)
							{
								val+=preparedsounds[i].readShort()*sourcesounds[i].amplitudemodifier;
								added=true;
							}
						}
						
						
						if (val >= (1<<15))
							val=1<<15;
						if (val<= -(1<<15))
							val=-(1<<15);
						
						_waveData.writeShort(val);
					}
					break;
				case 4:
					while (added)
					{
						added=false;
						var valf:Number=0;
						for (i=0;i<_trackcount;i++)
						{
							if (preparedsounds[i].position<preparedsounds[i].length-unitsize)
							{
								valf+=preparedsounds[i].readFloat()*sourcesounds[i].amplitudemodifier;
								added=true;
							}
						}
						
						_waveData.writeFloat(valf);
					}
					break;
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
		
		/**
		 * Stops the currently playing sound
		 */
		public function stop():void
		{
			if(_channel) 
			{
				_channel.stop();
				_channel = null;
			}
		}
		
		private function getWavByteArray(sampleRate:uint = 44100, bitDepth:uint = 16):ByteArray
		{
			//synth all individual wave files
			var waves : Vector.<ByteArray> = new Vector.<ByteArray>();			
						
			_trackcount = sourcesounds.length;
			preparedsounds = new Vector.<ByteArray>();
			
			for (var i:int=0;i<_trackcount;i++)
			{
				var b:ByteArray = new ByteArray();
				
				var silentbytes:int= int(sourcesounds[i].onset*44100);
				
				if (bitDepth==16)
					silentbytes*=2;
				if (sampleRate == 44100)
					silentbytes*=2;
				
				// create starting silence.
				while(silentbytes>0)
				{
					var bytestocopy:int=Math.min(silentbytes,_zeros.length);
					
					b.writeBytes(_zeros,0,bytestocopy);
					
					silentbytes-=bytestocopy;
				}
				
				//assumes sourcesounds already populated by wav-compatible waves
				// 36 = skip past header info
				b.writeBytes(sourcesounds[i] .bytes,36);				
				
				b.position=0;
				preparedsounds.push(b);
			}
			
			//now to mix
			Mix(bitDepth==16 ? 2 : 1);
			
			
			return _waveData;
		}
		/**
		 * Returns a ByteArray of the wave in the form of a .wav file, ready to be saved out
		 * @param	sampleRate		Sample rate to generate the .wav at	
		 * @param	bitDepth		Bit depth to generate the .wav at	
		 * @return					Wave in a .wav file
		 */
		public function getWavFile(sampleRate:uint = 44100, bitDepth:uint = 16):ByteArray
		{
			stop();			
			
			var waveDataBody : ByteArray = getWavByteArray(sampleRate,bitDepth);
			
			if (sampleRate != 44100) sampleRate = 22050;
			if (bitDepth != 16) bitDepth = 8;
			
			var soundLength:uint = waveDataBody.length;
			//if (bitDepth == 16) soundLength *= 2;
			//if (sampleRate == 22050) soundLength /= 2;
			
			var filesize:int = 36 + soundLength;
			var blockAlign:int = bitDepth / 8;
			var bytesPerSec:int = sampleRate * blockAlign;
			
			var wav:ByteArray = new ByteArray();
			
			// Header
			wav.endian = Endian.BIG_ENDIAN;
			wav.writeUnsignedInt(0x52494646);		// Chunk ID "RIFF"
			wav.endian = Endian.LITTLE_ENDIAN;
			wav.writeUnsignedInt(filesize);			// Chunck Data Size
			wav.endian = Endian.BIG_ENDIAN;
			wav.writeUnsignedInt(0x57415645);		// RIFF Type "WAVE"
			
			// Format Chunk
			wav.endian = Endian.BIG_ENDIAN;
			wav.writeUnsignedInt(0x666D7420);		// Chunk ID "fmt "
			wav.endian = Endian.LITTLE_ENDIAN;
			wav.writeUnsignedInt(16);				// Chunk Data Size
			wav.writeShort(1);						// Compression Code PCM
			wav.writeShort(1);						// Number of channels
			wav.writeUnsignedInt(sampleRate);		// Sample rate
			wav.writeUnsignedInt(bytesPerSec);		// Average bytes per second
			wav.writeShort(blockAlign);				// Block align
			wav.writeShort(bitDepth);				// Significant bits per sample
			
			// Data Chunk
			wav.endian = Endian.BIG_ENDIAN;
			wav.writeUnsignedInt(0x64617461);		// Chunk ID "data"
			wav.endian = Endian.LITTLE_ENDIAN;
			wav.writeUnsignedInt(soundLength);		// Chunk Data Size
			
			wav.writeBytes(waveDataBody);
			
			wav.position = 0;
			
			return wav;
		}
		
		
	}
}