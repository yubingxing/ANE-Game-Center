package com.icestar.gamekit.con
{
	import com.icestar.gamekit.GameKit;
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class Router extends EventDispatcher
	{
		private static var inst:Router;
		
		private var packageNumber:int = 0;
		private var packageIndexPool:Object;
		private var packages:Vector.<Package>;
		private var playerPackageBuffers:Vector.<PlayerPackageBuffer>;
		
		private var timer:Timer;
		private var interval:int = 300;
		
		private var currentPulseIndex:int=0;

		
		public function Router()
		{
			super();
			packages = new Vector.<Package>;
			packageIndexPool = new Object;
			playerPackageBuffers = new Vector.<PlayerPackageBuffer>;
			
			timer = new Timer(interval);
			timer.addEventListener(TimerEvent.TIMER, timerHandler);
		}
		
		public static function get manager():Router{
			if(!(inst is Router)){
				inst = new Router();
			}
			return inst;
		}
		
		
		
		public function send(playerIDs:Vector.<String>, data:String):void{
			//trace(data);
			var pck:Package = new Package();
			
			for each(var p:String in playerIDs){
				if(packageIndexPool[p]==null){
					packageIndexPool[p] = 0;
				}else{
					packageIndexPool[p] ++;
				}
				pck.addPlayer(p,packageIndexPool[p]);
			}
			pck.data = data;
			packages.push(pck);
		
			
			if(!timer.running){
				start();
			}
			
		}
		
		/**
		 * <data>
		 * <i>sender player id</i>
		 * 
		 * <fb/>
		 * 
		 * <p>
		 * 	<i>player1_ID</i>
		 * 	<k>0</k>
		 * </p>
		 * <p>
		 * 	<i>player2_ID</i>
		 * 	<k>4</k>
		 * </p>
		 * <p>
		 * 	<i>player3_ID</i>
		 * 	<k>2</k>
		 * </p>
		 * 
		 * <d>data in here</d>
		 * 
		 * </data>
		 * 
		 * */
		public function receive(pData:XMLList):void{
			var k:int = getIndexForMe(pData);
			if(k!=-1){
				if(pData.fb !=undefined){
					handleFeedbackFrom(String(pData.i),k);
				}else{
					giveFeedbackTo(String(pData.i),k);
					addToBuffer(String(pData.i), k,String(pData.d));
				}
			}
			
		}
		private function getIndexForMe(pData:XMLList):int{
			for(var i:int=0;i<pData.children().length();i++){
				var c:XMLList = pData.child(i);
				if(c.name() == "p"){
					if(String(c.i) == GameKit.manager.localPlayer.id){
						return int(c.k);
					}
				}
			}
			return -1;
		}
		
		private function giveFeedbackTo(playerID:String,index:int):void{
			var pck:Package = new Package();
			pck.addPlayer(playerID,index);
			pck.isFeedback = true;
			//packages.push(pck);
			/*if(!timer.running){
				start();
			}*/
			GameKit.manager.sendDataTo(pck.playerIDs,pck.generateData());
		}
		
		private function handleFeedbackFrom(playerID:String,index:int):void{
			for(var i:int=0;i<packages.length;i++){
				var p:Package = packages[i];
				if(p.getPlayerIndex(playerID) == index){
					p.removePlayer(playerID);
					if(p.playerIDs.length == 0){
						packages.splice(i,1);
						if(packages.length == 0){
							pause();
						}
					}
					return;
				}
			}
		}
		
		private function sendPulse():void{
			/*if(packages.length>0){
				var pck:Package = packages[currentPulseIndex];
				GameKit.manager.sendDataTo(pck.playerIDs,pck.generateData());
				if(pck.isFeedback){
					packages.splice(currentPulseIndex--,1);
				}
				
				currentPulseIndex ++;
				if(currentPulseIndex >= packages.length){
					currentPulseIndex = 0;
				}
			}else{
				pause();
			}*/
			for each(var pck:Package in packages){
				GameKit.manager.sendDataTo(pck.playerIDs,pck.generateData());
			}
		}
		
		private function getBufferById(playerID:String):PlayerPackageBuffer{
			for each(var buffer:PlayerPackageBuffer in playerPackageBuffers){
				if(buffer.playerID == playerID){
					return buffer;
				}
			}
			return null;
		}
		
		private function addToBuffer(playerID:String, index:int,data:String):void{
			var buffer:PlayerPackageBuffer = this.getBufferById(playerID);
			if(buffer==null){
				buffer = new PlayerPackageBuffer(playerID);
				playerPackageBuffers.push(buffer);
			}
			
			var pck:Package = new Package();
			pck.addPlayer(playerID,index);
			pck.data = data;

			buffer.push(pck);
			
			nextActionOfPlayer(playerID);
		}
		
		public function nextActionOfPlayer(playerID:String):void{
			var buffer:PlayerPackageBuffer = this.getBufferById(playerID);
			if(buffer){
				var action:XMLList = buffer.shiftAction();
				if(action!=null){
					GameKit.manager.onReceivedDataFrom(playerID, action);
				}
			}
			
		}
		
		
		public function disconnectPlayer(playerID:String):void{
			/**
			 * Remove sending data queue.
			 * */
			for(var i:int=0;i<packages.length;i++){
				var p:Package = packages[i];
				p.removePlayer(playerID);
				if(p.playerIDs.length==0){
					packages.splice(i,1);
				}
				if(packages.length==0){
					pause();
				}	
			}
			/**
			 * Remove action queue.
			 * */
			for(var b:int=0;b<playerPackageBuffers.length;b++){
				if(playerPackageBuffers[b].playerID == playerID){
					playerPackageBuffers.splice(b,1);
					return;
				}
			}
		}
		
		public function pause():void{
			timer.stop();
		}
		public function start():void{
			timer.start();
		}
		public function restart():void{
			timer.reset();
			timer.start();
		}
		
		public function reset():void{
			pause();
			packages = new Vector.<Package>;
			packageIndexPool = new Object;
			playerPackageBuffers = new Vector.<PlayerPackageBuffer>;
		}
		
		private function timerHandler(pEvent:TimerEvent):void{
			sendPulse();
		}
	}
}