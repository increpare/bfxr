package com.increpare.bfxr
{
	import com.increpare.bfxr.synthesis.IPlayerInterface;
	import com.increpare.bfxr.synthesis.Mixer.MixerPlayer;
	import com.increpare.bfxr.synthesis.Synthesizer.SfxrSynth;

	public class Bfxr 
	{
		public function Load(data:String):void
		{		
			if (data.indexOf("|")==-1)
			{
				_active = _synth;
			}
			else
			{
				_active = _mixer;
			}
			_active.Load(data);
		}
		
		public function Play(volume:Number=1):void
		{
			_active.Play(volume);
		}		
		
		public function Cache():void
		{
			_active.Cache();
		}
		
		public function CacheMutations(mutationAmount:Number = 0.05, count:int=15):void
		{
			_active.CacheMutations(mutationAmount,count);
		}
		
		private var _synth:SfxrSynth;		
		private var _mixer:MixerPlayer;
		private var _active:IPlayerInterface;
		
		public function Bfxr()
		{			
			_synth = new SfxrSynth();
			_mixer = new MixerPlayer();			
		}
	}
}