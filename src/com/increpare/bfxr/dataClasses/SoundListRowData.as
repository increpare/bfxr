package com.increpare.bfxr.dataClasses
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	[Bindable]
	[Event(name=SLIDER_CHANGE, type="flash.events.Event")]
	[Event(name=SLIDER_BEGIN_CHANGE, type="flash.events.Event")]
	[Event(name=LOCKEDNESS_CHANGE, type="flash.events.Event")]
	[Event(name=LOCKEDNESS_ALLCHANGE, type="flash.events.Event")]
	[Event(name=DEFAULT_CLICK, type="flash.events.Event")]
	public class SoundListRowData extends EventDispatcher {
		
		public static const SLIDER_BEGIN_CHANGE:String="SliderBeginChange";
		public static const SLIDER_CHANGE:String="SliderChange";
		public static const LOCKEDNESS_CHANGE:String="LockednessChange";
		public static const LOCKEDNESS_ALLCHANGE:String="LockednessAllChange";
		public static const DEFAULT_CLICK:String="DefaultClick";
		
		public var odd:Boolean;//used for alternative background colors
		public var square:Boolean;
		public var bggroup:int;
		public var min:Number;
		public var max:Number;
		public var defaultvalue:Number;
		public var value:Number;
		public var locked:Boolean;
		public var tag:String;
		public var label:String;	
		public var enabled:Boolean = true;
		public var tooltip:String;
	}
}