package com.increpare.bfxr
{
	import com.increpare.bfxr.synthesis.Mixer;
	import com.increpare.bfxr.synthesis.IPlayerInterface;
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
		
		public function Cache(callback:Function = null, maxTimePerFrame:uint = 5):void
		{
			_active.Cache(callback,maxTimePerFrame);
		}
		
		public function CacheMutations(mutationAmount:Number = 0.05, count:int=15,callback:Function = null, maxTimePerFrame:uint = 5):void
		{
			_active.CacheMutations(mutationAmount,count,callback,maxTimePerFrame);
		}
		
		private var _synth:SfxrSynth;		
		private var _mixer:Mixer;
		private var _active:IPlayerInterface;
		
		public function Bfxr(data:String="")
		{			
			_synth = new SfxrSynth();
			_mixer = new Mixer();
			
			if(data!="")
			{
				Load(data);
			}
		}
	}
}