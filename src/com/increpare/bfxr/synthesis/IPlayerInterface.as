package com.increpare.bfxr.synthesis
{
	import flash.utils.ByteArray;

	public interface IPlayerInterface
	{
		function Load(data:String):void;
		
		function Play(volume:Number=1):void;		
		
		function Cache():void;
		 
		function CacheMutations(amount:Number= 0.05,count:int=16):void;
	}
}