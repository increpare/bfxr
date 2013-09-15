package com.increpare.bfxr.synthesis
{		
/*
	class by henke37, 
	from http://webcache.googleusercontent.com/search?q=cache:bx2VN_2MqUwJ:www.actionscript.org/forums/showthread.php3%3Ft%3D248418+0x666D7420+floating+point&cd=1&hl=en&ct=clnk&gl=uk&source=www.google.co.uk
	*/
	
	import flash.utils.*;
	
	public class WaveWriter {
		
		
		public var outBuffer:ByteArray;
		
		private var stereo:Boolean=true;
		private const sampleRate:uint=44100;
		private var bitsPerSample:uint=32;
		private var useFloat:Boolean=true;
		
		private var writePointer:uint;
		
		private var riffSizePointer:uint, dataSizePointer:uint, factSamplesPointer:uint;
				
		public function WaveWriter(stereo:Boolean,bits:uint=32,b:ByteArray=null) {			
			
			this.stereo=stereo;
			bitsPerSample=bits;
			useFloat=bits>=32;
						
			if(b) {
				outBuffer=b;
			} else {
				outBuffer=new ByteArray();
			}
			
			writeWAVEHeader();
			
		}
		
		private function writeWAVEHeader():void {
			outBuffer.endian=Endian.BIG_ENDIAN;
			
			outBuffer.writeUnsignedInt(0x52494646);//riff marker
			
			riffSizePointer=outBuffer.position;
			outBuffer.writeUnsignedInt(0);//Size, to be filled in later
			
			outBuffer.writeUnsignedInt(0x57415645);//wave marker
			
			//write the fmt  chunk now
			
			outBuffer.writeUnsignedInt(0x666D7420);//fmt marker
			
			outBuffer.endian=Endian.LITTLE_ENDIAN;
			
			var bytesPerSample:uint=bitsPerSample/8;
			var blockSize:uint=(stereo+1)*bytesPerSample;
			
			outBuffer.writeUnsignedInt((useFloat?(22+2):0)+16);//length of the chunk
			outBuffer.writeShort(useFloat?0xFFFE:1);//compression, uncompressed PCM or extended wave
			outBuffer.writeShort(stereo+1);//channel count
			outBuffer.writeUnsignedInt(sampleRate);//samplerate
			outBuffer.writeUnsignedInt(sampleRate*blockSize);//ByteRate
			outBuffer.writeShort(blockSize);//Block align
			outBuffer.writeShort(bitsPerSample);//bits per sample
			
			if(useFloat) {
				
				outBuffer.writeShort(22);//Extra data length
				outBuffer.writeShort(bitsPerSample);//valid bits per sample
				outBuffer.writeUnsignedInt(3);//channel order flag field thingy
				
				outBuffer.writeUnsignedInt(0x0003);//real type, float
				
				outBuffer.writeShort(0x0000);//rest of GUID
				outBuffer.writeShort(0x0010);
				outBuffer.writeByte(0x80);
				outBuffer.writeByte(0x00);
				outBuffer.writeByte(0x00);
				outBuffer.writeByte(0xaa);
				outBuffer.writeByte(0x00);
				outBuffer.writeByte(0x38);
				outBuffer.writeByte(0x9b);
				outBuffer.writeByte(0x71);
				
				//fact chunk
				outBuffer.endian=Endian.BIG_ENDIAN;
				outBuffer.writeUnsignedInt(0x66616374);//fact marker
				outBuffer.endian=Endian.LITTLE_ENDIAN;
				outBuffer.writeUnsignedInt(4);//chunk length, not counting the header
				factSamplesPointer=outBuffer.position
				outBuffer.writeUnsignedInt(1);//number of sample pairs, to be filled in later
			}
			
			//write the data chunk now
			outBuffer.endian=Endian.BIG_ENDIAN;
			outBuffer.writeUnsignedInt(0x64617461);//data marker
			outBuffer.endian=Endian.LITTLE_ENDIAN;
			
			dataSizePointer=outBuffer.position;
			outBuffer.writeUnsignedInt(0);//Size, to be filled in later
			
			writePointer=outBuffer.position;
			
		}
		
		public function finalize(): void {
			if( dataLength % 2 == 1) {//add one byte of padding to the data block, if needed
				outBuffer.position=writePointer;
				outBuffer.writeByte(0);
				writePointer=outBuffer.position;
			}
			updateSizeFields();
		}
		
		/** position difference from begining of data tag to end of data,
		 not counting the size field itself
		 */
		private function get dataLength():uint {
			return writePointer-(dataSizePointer+4);
		}
		
		public function updateSizeFields():void {
			//update length values that's not been updated during bulk writing
			
			
			var sampleByteLength:uint=dataLength;
			
			outBuffer.endian=Endian.LITTLE_ENDIAN;
			
			outBuffer.position=riffSizePointer;
			outBuffer.writeUnsignedInt(outBuffer.length-8);//RIFF header does not count in the RIFF header
			
			if(useFloat) {
				outBuffer.position=factSamplesPointer;
				outBuffer.writeUnsignedInt(sampleByteLength/(bitsPerSample/8));
			}
			
			outBuffer.position=dataSizePointer;
			outBuffer.writeUnsignedInt(sampleByteLength);
			
		}
		
		public function addSamples(sb:ByteArray,monoify:Boolean=false):void {	
			
			sb.position=0;
						
			outBuffer.position=writePointer;
			outBuffer.endian=Endian.LITTLE_ENDIAN;
			
			if(stereo && useFloat && bitsPerSample==32 && sb.endian==Endian.LITTLE_ENDIAN) {
				//endianness missmatch prevents a fast copy
				outBuffer.writeBytes(sb);
			} else if(stereo) {   
				while(sb.position<sb.length) {
					var left:Number=sb.readFloat();
					var right:Number=sb.readFloat();
					
					if(useFloat) {
						if(bitsPerSample==32) {
							outBuffer.writeFloat(left);
							outBuffer.writeFloat(right);
						} else {//assume 64 bit
							outBuffer.writeDouble(left);
							outBuffer.writeDouble(right);
						}
					} else {
						
						if(bitsPerSample==8) {
							//scale to unsigned byte
							outBuffer.writeByte(numberTo8bit(left));
							outBuffer.writeByte(numberTo8bit(right));
						} else {//assume signed 16 bit
							outBuffer.writeShort(numberTo16bit(left));
							outBuffer.writeShort(numberTo16bit(right));
						}
					}//end if use float
				}//end while
			} else {// mono
				while(sb.position<sb.length) {
					left=sb.readFloat();
					if (monoify)
					{
						if (sb.position>=sb.length)
							break;
						right=sb.readFloat();
					}
					
					if(useFloat) {
						if(bitsPerSample==32) {
							outBuffer.writeFloat(left);
						} else {//assume 64 bit
							outBuffer.writeDouble(left);
						}
					} else {
						
						if(bitsPerSample==8) {
							//scale to unsigned byte
							outBuffer.writeByte(numberTo8bit(left));
						} else {//assume signed 16 bit
							outBuffer.writeShort(numberTo16bit(left));
						}
					}//end if useFloat
				}//end while
			}//end if mono
			writePointer=outBuffer.position;
		}
		
		public static function numberTo8bit(x:Number):uint {
			return x*128+127;
		}
		
		public static function numberTo16bit(x:Number):uint {
			return int(x * 32767 +0.5);
		}
	}
}