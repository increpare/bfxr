package com.increpare.bfxr.synthesis.Mixer
{
	import com.increpare.bfxr.synthesis.IPlayerInterface;
	import com.increpare.bfxr.synthesis.ISerializable;
	import com.increpare.bfxr.synthesis.Synthesizer.SfxrSynth;
	import com.increpare.bfxr.synthesis.WaveWriter;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class MixerPlayer extends EventDispatcher implements ISerializable, IPlayerInterface
	{
		public var id:int = -1;
		public var volume:Number = 1;
		public var tracks:Vector.<MixerTrackPlayer>;
		
		
		/*
			IPlayerInterface implementation
		*/
		
		
		public function Load(data:String):void
		{
			this.Deserialize(data);
		}
		
		public function Play(volume:Number=1):void
		{
			if (this._mutations.length==0)
			{
				this.play(null,volume);
			}
			else
			{
				this.playRandomMutation(volume);
			}
		}
		
		public function Cache():void
		{
			PrepareMixForPlay();
		}
		
		private var _mutations:Vector.<ByteArray> = new Vector.<ByteArray>();		
		public function CacheMutations(amount:Number = 0.05,count:int=16):void
		{
			_mutations = new Vector.<ByteArray>();
			
			var original:String = this.Serialize();
			
			for (var i:int=0;i<count;i++)
			{
				//mutate each track
				for (var j:int=0;j<tracks.length;j++)
				{
					tracks[j].synth.cacheMutations(count,amount);
				}
				
				PrepareMixForPlay(true)
				_mutations.push(_waveData);
			}
			
			_lastplayeddata="";
		}
		
		/*
			Other methods
		*/
		
		public function MixerPlayer() 
		{
			tracks = new Vector.<MixerTrackPlayer>();
			for (var i:int=0;i<MixerSynth.TRACK_COUNT;i++)
			{
				var mtp:MixerTrackPlayer = new MixerTrackPlayer();
				tracks.push(mtp);
			}		
			
			if (_zeros==null)
			{				
				_zeros = new ByteArray();
				for (i=0;i<400000;i++)
				{
					_zeros.writeFloat(0.0);
				}
			}
		}
		
		public static function Reverse(ba:ByteArray):ByteArray
		{
			var result:ByteArray = new ByteArray();
			var l:uint=ba.length;
			//subtract 8 because reading a float each time :P
			ba.position=ba.length-4;
			
			for (var pos:int=ba.length-4;pos>=0;pos-=4)
			{
				ba.position=pos;				
				result.writeFloat(ba.readFloat());				
			}
			return result;
		}
				
		public function Serialize():String
		{
			var result:String="";
			result += id.toString() + ">";
			result += volume.toString() + ">";
			for (var i:int=0;i<tracks.length;i++)
			{
				if (i>0)
					result+=">";
				
				result += tracks[i].Serialize();
			}
			return result;
		}
		
		public function Deserialize(settings:String):void
		{
			var ar:Array = settings.split(">");
			id = int(ar[0]);
			volume = Number(ar[1]);
			for (var i:int=2;i<ar.length;i++)
			{
				var s:String = ar[i];
				tracks[i-2].Deserialize(s);
			}
		}
				
		private var _updateCallback:Function=null;
		private var _lastplayeddata:String="";
		private var _caching:Boolean=false;
		private var _channel:SoundChannel;
		private var _sound:Sound;
		private var _waveData:ByteArray;
		private var _waveDataLength:int=-1;
		private var _waveDataBytes:int=-1;
		private var _waveDataPos:uint=0;
		private var _preparedsounds:Vector.<ByteArray>;
		private var _preparedvolumes:Vector.<Number>; //stores corresponding volumes
		private static var _zeros:ByteArray;
		
		private function PrepareMixForPlay(mutation:Boolean=false):void
		{
			var description:String = this.Serialize();
			if (_lastplayeddata!=description || mutation)
			{
				_lastplayeddata = description;
				
				//copy tracks over and add whitespace
				_preparedsounds = new Vector.<ByteArray>();
				_preparedvolumes = new Vector.<Number>();
				for (var i:int=0;i<tracks.length;i++)
				{
					if (tracks[i].IsSet()==false)
					{
						continue;
					}
					
					var b:ByteArray = new ByteArray();
					
					var silentbytes:int = int(tracks[i].data.onset*44100/2)*4*2;//ensure multiple of 8...
					
					// create starting silence.
					while(silentbytes>0)
					{
						var bytestocopy:int=Math.min(silentbytes,_zeros.length);
						
						b.writeBytes(_zeros,0,bytestocopy);
						
						silentbytes-=bytestocopy;
					}
					
					var cached:ByteArray = mutation==false 
												? tracks[i].synth.cachedWave 
												: tracks[i].synth.getCachedMutationWave(0);
					if (tracks[i].data.reverse)
					{
						cached=Reverse(cached);
					}
					
					b.writeBytes(cached);
					
					b.position=0;
					_preparedsounds.push(b);
					_preparedvolumes.push(tracks[i].data.volume);
				}
				
				Mix();
			}	
		}
		
		public function playRandomMutation(vol:Number=1):void
		{
			_waveData = _mutations[int(Math.random()*_mutations.length)];
			
			if (_preparedsounds.length==0)
			{
				return;
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
			
			_channel = _sound.play(0,0,new SoundTransform(vol,0));
		}
		
		public function play(updateCallback:Function=null, vol:Number=1):void
		{
			_updateCallback=updateCallback;
			
			PrepareMixForPlay();	
			
			if (_preparedsounds.length==0)
			{
				return;
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
			
			_channel = _sound.play(0,0,new SoundTransform(vol,0));
		}
		
		public function stop():void
		{
			if (_channel)
			{
				_channel.stop();
				_channel = null;
			}
		}
		
		/**
		 * Returns a ByteArray of the wave in the form of a .wav file, ready to be saved out
		 * @param	sampleRate		Sample rate to generate the .wav at	
		 * @param	bitDepth		Bit depth to generate the .wav at	
		 * @return					Wave in a .wav file
		 */
		public function getWavFile():ByteArray
		{
			stop();			
			
			PrepareMixForPlay();			
			
			var ww:WaveWriter = new WaveWriter(false,16);
			
			var padded:ByteArray = new ByteArray();
			padded.writeBytes(_waveData);
			for (var i:int=0;i<2000;i++)
			{
				padded.writeFloat(0);
				padded.writeFloat(0);
			}
			ww.addSamples(padded,true);
			ww.finalize();
			
			return ww.outBuffer;
		}
				
		/** param is whether to work in bytes, shorts, or floats (1,2,4)*/
		private function Mix(unitsize:int=4):void
		{
			var trackcount:int=_preparedsounds.length;
			_waveData = new ByteArray();
						
			var added:Boolean=true;
			
			var i:int;
			
			switch(unitsize)
			{
				case 1:
					while (added)
					{
						added=false;
						var val:int=0;
						for (i=0;i<trackcount;i++)
						{
							if (_preparedsounds[i].position<_preparedsounds[i].length-unitsize)
							{
								val += _preparedsounds[i].readByte()*_preparedvolumes[i];
								added=true;
							}
						}
						
						val*=volume;
						
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
						for (i=0;i<trackcount;i++)
						{
							if (_preparedsounds[i].position<_preparedsounds[i].length-unitsize)
							{
								val += _preparedsounds[i].readShort()*_preparedvolumes[i];
								added=true;
							}
						}
						
						val*=volume;						
						
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
						for (i=0;i<trackcount;i++)
						{
							if (_preparedsounds[i].position<_preparedsounds[i].length-unitsize)
							{
								valf += _preparedsounds[i].readFloat()*_preparedvolumes[i];
								added=true;
							}
						}
						
						valf*=volume;
						
						_waveData.writeFloat(valf);
					}
					break;
			}
			
			_waveData.position=0;
		}
						
		private function onSoundData(e:SampleDataEvent) : void
		{					
			if (_caching)
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
				
				if(_waveDataBytes > 0) e.data.writeBytes(_waveData, _waveDataPos, _waveDataBytes);
				
				//if too short..append data
				if (e.data.position<24576) 
				{
					_caching=false;
					while (e.data.position<24576)
					{
						e.data.writeFloat(0.0);
					}
				}
				
				_waveDataPos += _waveDataBytes;	
			}
		}
			
	
	}
}