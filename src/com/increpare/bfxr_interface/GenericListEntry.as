package com.increpare.bfxr_interface
{
	import flash.events.EventDispatcher;

	//class mainly to stop warning messages about being unable to bind properties
	[Bindable]
	public class GenericListEntry extends EventDispatcher
	{
		public var bggroup:int;
		public var label:String;
		public var data:String;
	}
}