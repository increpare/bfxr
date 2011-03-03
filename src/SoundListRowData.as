package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	[Bindable]
	[Event(name="SliderChange", type="flash.events.Event")]
	[Event(name="LockednessChange", type="flash.events.Event")]
	[Event(name="DefaultClick", type="flash.events.Event")]
	public class SoundListRowData extends EventDispatcher {
		public var odd:Boolean;//used for alternative background colors
		public var square:Boolean;
		public var bggroup:int;
		public var min:Number;
		public var max:Number;
		public var value:Number;
		public var locked:Boolean;
		public var tag:String;
		public var label:String;	
		public var enabled:Boolean = true;
		public var tooltip:String;
	}
}