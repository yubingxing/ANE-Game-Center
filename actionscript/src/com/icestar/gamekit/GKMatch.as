package com.icestar.gamekit
{
	import com.icestar.gamekit.gamecenter.GCPlayer;
	import com.icestar.gamekit.p2p.GKPeer;
	
	import flash.events.EventDispatcher;

	public class GKMatch extends EventDispatcher
	{ 
		public var id:String;
		public var connectionType:int;
		public var players:Vector.<GKPlayer>;
		public var hostPlayerID:String;
		
		public var minPlayers:int;
		public var maxPlayers:int;

		public function GKMatch()
		{
		}
		
		public function initializePlayers(players:Array,localPlayer:GKPlayer):void{
			players = new Vector.<GKPlayer>;
			
			var resortArray:Array = [localPlayer];
			for each(var p:Object in players){
				resortArray.push(p as GKPlayer);
			}
			if(connectionType == GKConnectionType.GAME_CENTER){
				resortArray.sortOn("id",Array.CASEINSENSITIVE);
			}else if(connectionType == GKConnectionType.PEER_2_PEER || connectionType == GKConnectionType.SERVER_CLIENT){
				resortArray.sortOn("id",Array.NUMERIC);
			}
			
			for each(var pl:GKPlayer in resortArray){
				players.push(pl);
			}
			
			hostPlayerID = players[0].id;
			
			randomSortPlayers();
		}
		
		private function randomSortPlayers():void{
			var tmpPlayers:Vector.<GKPlayer> = new Vector.<GKPlayer>;
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
			players = new Vector.<GKPlayer>;
			var player:GKPlayer;
			
			if(pPlayers is Vector.<GKPlayer>){
				players = pPlayers;
			}else if(pPlayers is Vector.<GCPlayer>){
				for each(var p:GCPlayer in pPlayers){
					player = new GKPlayer();
					player.id = p.playerID;
					player.alias = p.alias;
					players.push(player);
				}
				
			}else if(pPlayers is Vector.<GKPeer>){
				for each(var pr:GKPeer in pPlayers){
					player = new GKPlayer();
					player.id = pr.peerID;
					player.alias = pr.displayName;
					players.push(player);
				}
			}
			
			if(connectionType == GKConnectionType.GAME_CENTER){
				hostPlayerID = players[0].id;
			}
		}
		
		public function getOtherPlayerIDs(exceptPlayerID:String=""):Vector.<String>{
			var ids:Vector.<String> = new Vector.<String>;
			for each(var p:GKPlayer in players){
				if(exceptPlayerID != p.id){
					ids.push(p.id);
				}
			}
			return ids;
		}
		
		public function generatePlayersJSON():String{
			return JSON.stringify(players);
		}
		
		public function extractPlayersFromJSON(json:String):Vector.<GKPlayer>{
			if(json && json.charAt() == '[' && json.charAt(json.length-1) == ']'){
				var arr:Array = JSON.parse(json) as Array;
				return Vector.<GKPlayer>(arr);
			}
			return new Vector.<GKPlayer>;
		}
	}
}