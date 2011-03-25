package com.increpare.bfxr_interface
{
	import com.increpare.bfxr.synthesis.ISerializable;
	
	import flash.events.Event;
	import flash.utils.ByteArray;

	public interface ITabManager extends ISerializable
	{
		function Play():void;
		function RefreshUI():void;
		function OnParameterChanged(audible:Boolean = true, underlyingModification:Boolean = true, forceplay:Boolean = false):void;
		function ComponentChangeCallback(tag:String,e:Event):void;
		function DeserializeFromClipboard(str:String,allowplay:Boolean=true):void;
		function getWavFile():ByteArray;
		
		/** Update components, like master volume and play button, shared between managers */
		function UpdateSharedComponents():void;
	}
}