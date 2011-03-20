package com.increpare.bfxr.synthesis
{
	public interface ISerializable
	{
	 	function Serialize():String;
	 	function Deserialize(settings:String):void;
	}
}