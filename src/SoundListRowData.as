package
{
	import flash.events.EventDispatcher;

	[Bindable]
	public class SoundListRowData extends EventDispatcher {
		public var odd:int;
		public var square:Boolean;
		public var bggroup:int;
		public var min:Number;
		public var max:Number;
		public var value:Number;
		public var locked:Boolean;
		public var tag:String;
		public var label:String;	
		public var enabled:Boolean = true;
	}
}