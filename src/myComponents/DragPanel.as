package myComponents
{
	import spark.components.BorderContainer;
	import mx.core.UIComponent;
	import mx.core.SpriteAsset;
	import mx.events.FlexEvent;
	import flash.events.MouseEvent;
	import mx.events.*;
	import flash.events.Event;
	
	public class DragPanel extends BorderContainer
	{
		// Add the creationCOmplete event handler.
		public function DragPanel()
		{
			super();
			addEventListener( FlexEvent.CREATION_COMPLETE, creationCompleteHandler);
		}
		
					
		private function creationCompleteHandler(event:Event):void
		{
			// Add the resizing event handler.	
			addEventListener(MouseEvent.MOUSE_DOWN, resizeHandler);
		}

		override protected function createChildren():void
		{
				super.createChildren();
			/*
			// Create the SpriteAsset's for the min/restore icons and 
			// add the event handlers for them.
			minShape = new SpriteAsset();
			minShape.addEventListener(MouseEvent.MOUSE_DOWN, minPanelSizeHandler);
			titleBar.addChild(minShape);

			restoreShape = new SpriteAsset();
			restoreShape.addEventListener(MouseEvent.MOUSE_DOWN, restorePanelSizeHandler);
			titleBar.addChild(restoreShape);*/
		}
			
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
	
			// Draw resize graphics if not minimzed.				
			graphics.clear()
			if (isMinimized == false)
			{
				graphics.lineStyle(2);
				graphics.moveTo(unscaledWidth - 6, unscaledHeight - 1)
				graphics.curveTo(unscaledWidth - 3, unscaledHeight - 3, unscaledWidth - 1, unscaledHeight - 6);						
				graphics.moveTo(unscaledWidth - 6, unscaledHeight - 4)
				graphics.curveTo(unscaledWidth - 5, unscaledHeight - 5, unscaledWidth - 4, unscaledHeight - 6);						
			}
		}
					
		private var myRestoreHeight:int;
		private var isMinimized:Boolean = false; 
				


		// Define static constant for event type.
		public static const RESIZE_CLICK:String = "resizeClick";

		// Resize panel event handler.
		public  function resizeHandler(event:MouseEvent):void
		{
			// Determine if the mouse pointer is in the lower right 7x7 pixel
			// area of the panel. Initiate the resize if so.
			
			// Lower left corner of panel
			var lowerLeftX:Number = x + width; 
			var lowerLeftY:Number = y + height;
				
			// Upper left corner of 7x7 hit area
			var upperLeftX:Number = lowerLeftX-7;
			var upperLeftY:Number = lowerLeftY-7;
				
			// Mouse positionin Canvas
			var panelRelX:Number = event.localX + x;
			var panelRelY:Number = event.localY + y;


					event.stopPropagation();		
					var rbEvent:MouseEvent = new MouseEvent(RESIZE_CLICK, true);
					// Pass stage coords to so all calculations using global coordinates.
					rbEvent.localX = event.stageX;
					rbEvent.localY = event.stageY;
					dispatchEvent(rbEvent);	
		
		}		
	}
}