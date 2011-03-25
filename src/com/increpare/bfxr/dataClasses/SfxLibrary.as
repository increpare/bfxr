package com.increpare.bfxr.dataClasses
{
	import com.increpare.bfxr.synthesis.*;
	import com.increpare.bfxr.synthesis.Synthesizer.SfxrSynth;

	public class SfxLibrary
	{
		public var globals:String;//array of global variables
		public var synths:Array;//ids are indices
		public var mixes:Array;//ids are indices

		public function SfxLibrary()
		{
			globals = "";
			synths = new Array();
			mixes = new Array();
		}
		
		public static function LoadFrom(data:String):SfxLibrary
		{
			var result:SfxLibrary = new SfxLibrary();
			
			//first compile strings - 
			// they'll be of form
			// VERSION\n\nGLOBAL1,Global2,\n\nSOUNDNAME1=SOUNDDAT1\nSOUNDNAME2=SOUNDDAT2\n\nCOMPOUNDNAME1=COMPOUNDDAT1\n&c.
			// 
			var lines:Array = data.split("\n");		
			var version:int=int(lines[i]);
			if (lines[1]!="")
				throw new Error("file not of correct format");
			
			//read global variables
			
			result.globals = lines[2];
			
			var i:int=4;
			while (i<lines.length && lines[i]!="")
			{
				result.synths.push(SoundData.Deserialize(lines[i]));
				i++;
			}
			i++;
			while (i<lines.length && lines[i]!="")
			{
				result.mixes.push(LayerData.Deserialize(lines[i]));
				i++;
			}			
			
			return result;
		}
		
		
		/** Assumes members have already been populated */
		public function Save():String
		{
			// VERSION\n\nGLOBAL1,Global2,\n\nSOUNDNAME1=SOUNDDAT1\nSOUNDNAME2=SOUNDDAT2\n\nCOMPOUNDNAME1=COMPOUNDDAT1\n&c.
			
			var result:String = SfxrSynth.version.toString();
			
			result+="\n\n";
			
			result+=globals;

			result+="\n\n";
			
			//first compile strings - 			
			for (var i:int=0;i<synths.length;i++)
			{
				result+=(synths[i] as SoundData).Serialize()+"\n";
			}
			
			result+="\n";
			//then add layers			
			for (i=0;i<mixes.length;i++)
			{
				result+=(mixes[i] as LayerData).Serialize()+"\n";				
			}
						
			return result;
		}
	}
}