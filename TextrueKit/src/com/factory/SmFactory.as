package com.factory
{
	import com.consts.ActionConst;
	import com.consts.GameConst;
	import com.data.ActionFormatVO;
	import com.utils.FileUtil;
	
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	/**
	 * @time 2018-1-17
	 * @author nos(liupengpeng)
	 * @descr 
	 */
	public class SmFactory extends BaseFactory
	{
		public function SmFactory(sid:int)
		{
			super(sid);
			this.type=GameConst.SUFFIX_SM;
		}
		
		private var tDict:Dictionary;
		public override function parse(file:File,dict:Dictionary):void{
			tDict=dict;
			
			parseDataFormat(FileUtil.getBytesByFile(file));
		}
		
		private function parseDataFormat(bytes:ByteArray):void{
			
			if(bytes==null){
				recover();
				return;
			}
			
			bytes.position=0;
			try{
				bytes.uncompress();
			}catch(e:Error){
				
			}
			var avtId:String=bytes.readUTF();
			var actLen:int=bytes.readByte();
			var vo:ActionFormatVO=null;
			
			var i:int=0;
			
			var actions:Array=[];
			
			while(i<actLen){
				vo=new ActionFormatVO();
				vo.id=avtId;
				var actName:String=bytes.readUTF();
				vo.actionName=actName;
				
				var actFrames:int=bytes.readByte();
				var actSpeed:int=bytes.readShort();
				if(actName==ActionConst.ATTACK){
					actSpeed -=10;
				}
				var actReplay:int=bytes.readInt();
				var act_skill_frame:int=bytes.readByte();
				var act_hit_frame:int=bytes.readByte();
				var act_total_dir:int=bytes.readByte();
				
				vo.totalFrames=actFrames;
				vo.actionSpeed=actSpeed;
				vo.replay=actReplay;
				vo.skillFrame=act_skill_frame==0?actFrames-2:act_skill_frame;
				vo.hitFrame=act_hit_frame;
				vo.totalDir=act_total_dir;
				
				if(vo.replay==0)vo.replay=1;
				
				vo.totalTime=0;
				
				var j:int=0;
				while(j<actFrames){
					var offset_speed:int=bytes.readInt();
					vo.intervalTimes.push(actSpeed+offset_speed);
					vo.totalTime +=actSpeed+offset_speed;
					j++;
				}
				var k:int=0;
				while(k<act_total_dir){
					vo.dirOffsetX[k]=bytes.readInt();
					vo.dirOffsetX[k]=bytes.readInt();
					k++;
				}
				
				k=0;
				while(k<act_total_dir){
					
					var ws:Vector.<uint> =new Vector.<uint>();
					var hs:Vector.<uint> =new Vector.<uint>();
					var txs:Vector.<int> =new Vector.<int>();
					var tys:Vector.<int> =new Vector.<int>();
					
					var bitmapDatas:Vector.<String> =new Vector.<String>();
					
					j=0;
					while(j<actFrames){
						var width:int=bytes.readShort();
						var height:int=bytes.readShort();
						var tx:int=bytes.readShort();
						var ty:int=bytes.readShort();
						
						tx -=400;
						ty -=300;
						
						ws.push(width);
						hs.push(height);
						txs.push(tx);
						tys.push(ty);
						bitmapDatas.push(vo.getLink(k,j));
						j++;
					}
					vo.widths.push(ws);
					vo.heights.push(hs);
					vo.txs.push(txs);
					vo.tys.push(tys);
					vo.bitmapdatas.push(bitmapDatas);
					
					checkAction(vo,k);
					k++;
				}
				actions.push(vo);
				i++;
			}
//			
//			var avtvo:Object=new Object();
//			avtvo.id=avtId;
//			avtvo.list=actions;
//			
//			content=avtvo;
//			
			
		}
		
		
		private function checkAction(vo:ActionFormatVO,dir:int):void{
			var assetName:String=vo.id+"_"+vo.actionName+"_"+dir+".av";
			var assetFile:File=tDict[assetName];
			if(assetFile){
				parseAsset(assetFile,vo);
			}
		}
//		actkeys=[error,stand,attack,walk,run,skill,hit,death]
//		format:[utf(2),utf,byte,byte,byte,bmds]
//		png,name,act,dir,frames,files:[{int,bytes}]
//		bytes:short,short,pixels
//		
//		sceneid
//		part1=(tx+int(sceneid/2))
//		part2=(-ty+int(sceneid/3))
//		part3=(sceneid-(tx+ty))
//		words=part1+part3+part2
		private var actionNames:Array=["error",'stand','attack','run','skill','hit','death'];
		public function parseAsset(file:File,vo:ActionFormatVO):void{
			var bytes:ByteArray=FileUtil.getBytesByFile(file);
			bytes.position=0;
			var file_format:String=bytes.readUTFBytes(2);
			var file_name:String=bytes.readUTF();
			var act:int=bytes.readByte();
			var dir:int=bytes.readByte();
			var frames:int=bytes.readByte();
			for (var i:int = 0; i < frames; i++) 
			{
				var byteLen:int=bytes.readInt();
				var fileBytes:ByteArray =new ByteArray();
				bytes.readBytes(fileBytes,0,byteLen);
				var path:String=getOutputPath()+"/"+vo.id+"/"+vo.actionName+"/"+dir+"/"+i+"."+file_format;
				FileUtil.saveBytesFile(path,fileBytes);
			}
		}
		
	}
}