package com.icestar.gamekit
{
	import com.icestar.gamekit.gamecenter.GCPlayer;
	import com.icestar.gamekit.p2p.Peer;
	
	import flash.events.EventDispatcher;

	public class Match extends EventDispatcher
	{ 
		public var id:String;
		public var connectionType:int;
		public var players:Vector.<Player>;
		public var hostPlayerID:String;
		
		public var minPlayers:int;
		public var maxPlayers:int;

		public function Match()
		{
		}
		
		public function initializePlayers(players:Array,localPlayer:Player):void{
			players = new Vector.<Player>;
			
			var resortArray:Array = [localPlayer];
			for each(var p:Object in players){
				resortArray.push(p as Player);
			}
			if(connectionType == ConnectionType.GAME_CENTER){
				resortArray.sortOn("id",Array.CASEINSENSITIVE);
			}else if(connectionType == ConnectionType.PEER_2_PEER || connectionType == ConnectionType.SERVER_CLIENT){
				resortArray.sortOn("id",Array.NUMERIC);
			}
			
			for each(var pl:Player in resortArray){
				players.push(pl);
			}
			
			hostPlayerID = players[0].id;
			
			randomSortPlayers();
		}
		
		private function randomSortPlayers():void{
			var tmpPlayers:Vector.<Player> = new Vector.<Player>;
			var len:int = players.length;
			for(var i:int=0;i<len;i++){
				var index:int = int(Math.random()* players.length);
				tmpPlayers.push(players[index]);
				players.splice(index,1);
			}
			players = tmpPlayers;
		}
		
		public function setHost():void{
			if(players.length>1){
				players[0].isHost = true;
			}
		}
		
		public function syncPlayers(pPlayers:*):void{
			players = new Vector.<Player>;
			var player:Player;
			
			if(pPlayers is Vector.<Player>){
				players = pPlayers;
			}else if(pPlayers is Vector.<GCPlayer>){
				for each(var p:GCPlayer in pPlayers){
					player = new Player();
					player.id = p.playerID;
					player.alias = p.alias;
					players.push(player);
				}
				
			}else if(pPlayers is Vector.<Peer>){
				for each(var pr:Peer in pPlayers){
					player = new Player();
					player.id = pr.peerID;
					player.alias = pr.displayName;
					players.push(player);
				}
			}
			
			if(connectionType == ConnectionType.GAME_CENTER){
				hostPlayerID = players[0].id;
			}
		}
		
		public function getOtherPlayerIDs(exceptPlayerID:String=""):Vector.<String>{
			var ids:Vector.<String> = new Vector.<String>;
			for each(var p:Player in players){
				if(exceptPlayerID != p.id){
					ids.push(p.id);
				}
			}
			return ids;
		}
		
		public function generatePlayersJSON():String{
			return JSON.stringify(players);
		}
		
		public function extractPlayersFromJSON(json:String):Vector.<Player>{
			if(json && json.charAt() == '[' && json.charAt(json.length-1) == ']'){
				var arr:Array = JSON.parse(json) as Array;
				return Vector.<Player>(arr);
			}
			return new Vector.<Player>;
		}
	}
}