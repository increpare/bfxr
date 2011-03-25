/*
	Normal list, but with triggers OnChange event when clicking on an already-selected item.

*/
package com.increpare.bfxr_interface.components
{
	import flash.events.MouseEvent;	
	
	import spark.components.List;
	import spark.events.IndexChangeEvent;
	
	public class ListWithRetriggerOnClickingAlreadySelected extends List
	{
		public function ListWithRetriggerOnClickingAlreadySelected()
		{
			super();
		}
		
		/**
		 *  @private
		 *  Handles <code>MouseEvent.MOUSE_DOWN</code> events from any of the 
		 *  item renderers. This method handles the updating and commitment 
		 *  of selection as well as remembers the mouse down point and
		 *  attaches <code>MouseEvent.MOUSE_MOVE</code> and
		 *  <code>MouseEvent.MOUSE_UP</code> listeners in order to handle
		 *  drag gestures.
		 *
		 *  @param event The MouseEvent object.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		override protected function item_mouseDownHandler(event:MouseEvent):void
		{
			var oldindex:int=this.selectedIndex;
			super.item_mouseDownHandler(event);
			var newindex:int=this.selectedIndex;
			if (oldindex==newindex)
			{
				//push selection event
				
				var e:IndexChangeEvent = new IndexChangeEvent(IndexChangeEvent.CHANGE);
				e.oldIndex = newindex;
				e.newIndex = newindex;
				dispatchEvent(e);		
			}
		}

	}
}