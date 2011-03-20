/*
class taken from http://www.firstpr.com.au/dsp/pink-noise/#Filtering
*/
package com.increpare.bfxr.synthesis.Synthesizer
{
	public class PinkNumber
	{
		private var max_key:int;
		private var key:int;
		private var white_values:Vector.<int> = new Vector.<int>();
		private var range:uint;
		
		public function	PinkNumber()
		{
			max_key = 0x1f; // Five bits set
			this.range = 128;
			key = 0;
			for (var i:int = 0; i < 5; i++)
				white_values.push(Math.random() * (range/5))
		}
		
		
		//returns number between -1 and 1		
		public function GetNextValue():Number
		{
			var last_key:int = key;
			var sum:uint;
			
			key++;
			if (key > max_key)
				key = 0;
			// Exclusive-Or previous value with current value. This gives
			// a list of bits that have changed.
			var diff:int = last_key ^ key;
			sum = 0;
			for (var i:int = 0; i < 5; i++)
			{
				// If bit changed get new random number for corresponding
				// white_value
				if (diff & (1 << i))
					white_values[i] = Math.random() * (range/5);
				sum += white_values[i];
			}
			return sum/64.0-1.0;
		}
	}; 
}