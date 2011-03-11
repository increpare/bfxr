package com.increpare.bfxr.synthesis
{
	import flash.utils.ByteArray;

	public interface PlayerInterface
	{
		function Load(data:String):void;
		
		function Play(volume:Number=1):void;
		
		function Cache(callback:Function = null, maxTimePerFrame:uint = 5):void;
		function CacheMutations(amount:Number= 0.05,count:int=16,callback:Function = null, maxTimePerFrame:uint = 5):void;
		
		function getCachedWave():ByteArray;

		function getCachedMutationCount():int;
		function getCachedMutationWave(index:int=-1):ByteArray;
			
		
	}
}