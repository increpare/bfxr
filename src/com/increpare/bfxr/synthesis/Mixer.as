package com.increpare.bfxr.synthesis
{	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class Mixer extends EventDispatcher implements PlayerInterface
	{				
		public var _dirty:Boolean;
		public var _cachedWaveData:ByteArray;
		
		private var sourcesounds:Vector.<MixerSoundData>;		
		
		//sounds with offset added
		private var preparedsounds:Vector.<ByteArray>;
		
		public var params:MixerParams;
		private var _trackcount:int;
		private var _sound:Sound;
		private var _channel:SoundChannel;
		
		private var _waveData:ByteArray;
		private var _waveDataPos:uint;						// Current position in the waveData
		private var _waveDataLength:uint;					// Number of bytes in the waveData
		private var _waveDataBytes:uint;					// Number of bytes to write to the soundcard
		private var _updateCallback:Function;
		private var _zeros:ByteArray;
		
		private var _mutation:Boolean;						// If the current sound playing or caching is a mutation
		
		private var _cachingMutation:int;					// Current caching ID
		private var _cachedMutation:ByteArray;				// Current caching wave data for mutation
		private var _cachedMutations:Vector.<ByteArray>;	// Cached mutated wave data
		private var _cachedMutationsNum:uint;				// Number of cached mutations
		private var _cachedMutationAmount:Number;			// Amount to mutate during cache
		
		/** PlayerInterface implementation: */
		public function Load(data:String):void
		{
			params.Deserialize(data);
		}
		
		public function Play(volume:Number=1):void
		{			
			if (this._mutation)
			{
				playMutated(0.05,15,volume);
			}
			else
			{
				play(null,volume);
			}
		}
		
		public function Cache(callback:Function = null, maxTimePerFrame:uint = 5):void
		{
			if (_dirty)
			{
				GenerateSourceSounds(
										function():void
										{
											CacheWave(); 
											callback();
										},
										maxTimePerFrame);
			}
		}
		
		private function GenerateSourceSounds(onComplete:Function, maxTimePerFrame:Number=5):void
		{
			sourcesounds= new Vector.<MixerSoundData>();
			
			_sourcesoundindex=-1;
			_sourceSoundOnCompleteCallback=onComplete;
			_sourcesoundMaxTimePerFrame=maxTimePerFrame;
			_lastSynth=null;
			_lastSoundParams=null;
			generateSourceSound();
		}
		
		private var _sourcesoundindex:int;
		private var _sourcesoundMaxTimePerFrame:Number;
		private var _sourceSoundOnCompleteCallback:Function;
		private var _lastSynth:SfxrSynth;
		private var _lastSoundParams:MixerItemParams;
		
		private function generateSourceSound():void
		{
			if (_lastSynth!=null)
			{
				generateSourceSoundApply();				
			}
			_sourcesoundindex++;
			if (_sourcesoundindex>=params.items.length)
			{
				if (_lastSynth!=null)
				{
					generateSourceSoundApply();				
				}
				_sourceSoundOnCompleteCallback();
				return;
			}
			
			_lastSoundParams = params.items[_sourcesoundindex] as MixerItemParams;
			_lastSynth = new SfxrSynth();
			_lastSynth.params.Deserialize(_lastSoundParams.data);
			_lastSynth.Cache(generateSourceSound,_sourcesoundMaxTimePerFrame);
		}
		
		private function generateSourceSoundApply():void
		{
			var msd:MixerSoundData = new MixerSoundData(
				_lastSoundParams.id,
				_lastSoundParams.data,
				_lastSynth.cachedWave,
				_lastSoundParams.onset,
				_lastSoundParams.amplitudemodifier
			);
		}
		
		public function CacheMutations(amount:Number=0.05,count:int=16,callback:Function = null, maxTimePerFrame:uint = 5):void
		{
			if (callback != null)
			{
				throw new Error("Bfxr doesn't support asynchronous callbacks for mixed functions yet."); 
			}
			
			var original_parameters:String = this.Serialize();
			
			this._cachedMutations = new Vector.<ByteArray>();
			for (var i:int=0;i<count;i++)
			{
				this.sourcesounds = new Vector.<MixerSoundData>();
				
				for (var j:int=0;j<this.params.items.length;j++)
				{
					var mip:MixerItemParams = params.items[j] as MixerItemParams;
					var s:SfxrSynth = new SfxrSynth();
					s.params.Deserialize(mip.data);
					s.params.mutate(amount);
					s.Cache();
					var bytes:ByteArray = s.getCachedWave();					
					var msd:MixerSoundData = new MixerSoundData(
													mip.id,
													mip.data,
													bytes,
													mip.onset,
													mip.amplitudemodifier
											);
					this.sourcesounds.push(msd);
					//params.items[j].
				}
				this.Deserialize(original_parameters);
			}
			this._dirty=false;			
			this._mutation=true;
			//cacheMutations(count,amount);			
		}
		
		public function Serialize():String
		{
			return this.params.Serialize();
		}
		
		public function Deserialize(data:String):void
		{		
			this.params.Deserialize(data);			
		}
		
		public function getCachedWave():ByteArray
		{
			if (_dirty)
			{
				CacheWave();
			}
			
			return this._cachedWaveData;
		}
		
		public function getCachedMutationCount():int
		{
			return _cachedMutationsNum;
		}
		
		public function getCachedMutationWave(index:int=-1):ByteArray
		{
			if (index==-1)
			{
				index=Math.random()*_cachedMutations.length;
			}
			
			return _cachedMutations[index];
		}	
		
		
		public function Mixer()
		{
			_dirty = true;
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
			sourcesounds.push(b);
			_dirty=true;
		}
		
		public function playMutated(mutationAmount:Number = 0.05, mutationsNum:uint = 15, volume:Number = 1):void
		{
			if (_dirty)
			{
				
			}					
		}
		
		public function play(updateCallback:Function=null,volume:Number=1):void
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
				CacheWave();
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
		
			_channel = _sound.play(0,0,new SoundTransform(volume));
			_channel.addEventListener(Event.SOUND_COMPLETE,function():void { dispatchEvent(new Event(SfxrSynth.PLAY_COMPLETE));	});
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
			
			var masterVolume:Number = this.params.volume;

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
						
						val *= masterVolume;
						
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
						
						val *= masterVolume;
						
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
						
						valf *= masterVolume;
						
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
				}
				
				if(_waveDataBytes > 0) e.data.writeBytes(_waveData, _waveDataPos, _waveDataBytes);
							
				//if too short..append data
				if (e.data.position<24576) 
				{
					while (e.data.position<24576)
					{
						e.data.writeFloat(0.0);
						_waveDataBytes+=4;
					}
					_caching=false;
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
		
		private function CacheWave():void
		{
			//copy tracks over and add whitespace
			preparedsounds = new Vector.<ByteArray>();
			for (var i:int=0;i<_trackcount;i++)
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