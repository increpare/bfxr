package utility
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class WavGenerator
	{
		public static function Generate(waveDataBody:ByteArray,sampleRate:int,bitDepth:int):ByteArray
		{			
			if (sampleRate != 44100) sampleRate = 22050;
			if (bitDepth != 16) bitDepth = 8;
			
			var soundLength:uint = waveDataBody.length;
			//if (bitDepth == 16) soundLength *= 2;
			//if (sampleRate == 22050) soundLength /= 2;
			
			var filesize:int = 36 + soundLength;
			var blockAlign:int = bitDepth / 8;
			var bytesPerSec:int = sampleRate * blockAlign;
			
			var wav:ByteArray = new ByteArray();
			
			// Header
			wav.endian = Endian.BIG_ENDIAN;
			wav.writeUnsignedInt(0x52494646);		// Chunk ID "RIFF"
			wav.endian = Endian.LITTLE_ENDIAN;
			wav.writeUnsignedInt(filesize);			// Chunck Data Size
			wav.endian = Endian.BIG_ENDIAN;
			wav.writeUnsignedInt(0x57415645);		// RIFF Type "WAVE"
			
			// Format Chunk
			wav.endian = Endian.BIG_ENDIAN;
			wav.writeUnsignedInt(0x666D7420);		// Chunk ID "fmt "
			wav.endian = Endian.LITTLE_ENDIAN;
			wav.writeUnsignedInt(16);				// Chunk Data Size
			wav.writeShort(1);						// Compression Code PCM
			wav.writeShort(1);						// Number of channels
			wav.writeUnsignedInt(sampleRate);		// Sample rate
			wav.writeUnsignedInt(bytesPerSec);		// Average bytes per second
			wav.writeShort(blockAlign);				// Block align
			wav.writeShort(bitDepth);				// Significant bits per sample
			
			// Data Chunk
			wav.endian = Endian.BIG_ENDIAN;
			wav.writeUnsignedInt(0x64617461);		// Chunk ID "data"
			wav.endian = Endian.LITTLE_ENDIAN;
			wav.writeUnsignedInt(soundLength);		// Chunk Data Size
			
			wav.writeBytes(waveDataBody);
			
			wav.position = 0;
			
			return wav;
		}
	}
}