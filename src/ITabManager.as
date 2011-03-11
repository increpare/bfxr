package
{
	import flash.events.Event;

	public interface ITabManager
	{
		function Play():void;
		function RefreshUI():void;
		function OnParameterChanged(audible:Boolean = true, underlyingModification:Boolean = true, forceplay:Boolean = false):void;
		function ComponentChangeCallback(tag:String,e:Event):void;
		function Serialize():String;
		function Deserialize(data:String):Boolean;
		function DeserializeFromClipboard(str:String):void;
		
		/** Update components, like master volume and play button, shared between managers */
		function UpdateSharedComponents():void;
	}
}