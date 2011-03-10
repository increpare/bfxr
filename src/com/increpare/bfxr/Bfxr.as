package com.increpare.bfxr
{
	import com.increpare.bfxr.synthesis.Mixer;
	import com.increpare.bfxr.synthesis.PlayerInterface;
	import com.increpare.bfxr.synthesis.SfxrSynth;

	public class Bfxr
	{
		public function Load(data:String):void
		{		
			if (data.indexOf("|")>=0)
			{
				_active = _synth;
			}
			else
			{
				_active = _mixer;
			}
		}
		
		public function Play(volume:Number):void
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
		private var _mixer:Mixer;
		private var _active:PlayerInterface;
		
		public function Bfxr()
		{			
			_synth = new SfxrSynth();
			_mixer = new Mixer();
		}
	}
}