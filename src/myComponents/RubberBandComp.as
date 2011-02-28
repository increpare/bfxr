package myComponents
{
	import mx.core.UIComponent;

	public class RubberBandComp extends UIComponent
	{
		public function RubberBandComp()
		{
			super();
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
				
			// Draw rubber band with a 1 pixel border, and a grey fill. 				
			graphics.clear();								
			graphics.lineStyle(1);
			graphics.beginFill(0xCCCCCC, 0.5);
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
		}
		
	}
}