package com.increpare.bfxr.synthesis.Mixer
{
	import com.increpare.bfxr.synthesis.ISerializable;
	import com.increpare.bfxr.synthesis.Synthesizer.SfxrSynth;
	
	import dataClasses.SoundData;

	public class MixerTrackPlayer implements ISerializable
	{
		public var data:MixerTrackData;
		public var synth:SfxrSynth;

		
		public function MixerTrackPlayer()
		{
			data = new MixerTrackData();
			synth = new SfxrSynth();
			//synth.Load(data.synthdata);
		}
		
		public function IsSet():Boolean
		{
			return data.synthdata!="";
		}
		
		public function LoadSynth(sd:SoundData):void
		{
			if (sd!=null)
			{
				data.id=sd.id;
				data.synthdata=sd.data;
				synth.Load(data.synthdata);
			}
			else
			{
				data.id=-1;
				data.synthdata="";
			}
		}		
		
		public function Serialize():String
		{
			return data.Serialize();
		}
		
		public function Deserialize(settings:String):void
		{
			data.Deserialize(settings);
			synth.Load(data.synthdata);
		}
	}
}