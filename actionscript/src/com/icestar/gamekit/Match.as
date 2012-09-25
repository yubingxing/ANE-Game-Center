package com.icestar.gamekit
{
	import com.icestar.gamekit.ConnectionType;
	import com.icestar.gamekit.Player;
	import com.icestar.gamekit.gamecenter.GKPlayer;
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
		
		public function initializePlayers(playerXML:XMLList,localPlayer:Player):void{
			players = new Vector.<Player>;
			
			var resortArray:Array = new Array(localPlayer);
			for(var i:int=0;i<playerXML.children().length();i++){
				var p:Player = new Player();
				p.id = playerXML.child(i).i;
				p.alias = playerXML.child(i).a;
				resortArray.push(p);
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
			}else if(pPlayers is Vector.<GKPlayer>){
				for each(var p:GKPlayer in pPlayers){
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
		
		public function generatePlayerXML():XMLList{
			var xmllist:XMLList = new XMLList("<p></p>");
			for(var i:int=0;i<players.length;i++){
				var p:Player = players[i];
				xmllist.appendChild("<p><i>"+p.id+"</i><a>"+p.alias+"</a></p>");
			}
			return xmllist;
		}
		public function extractPlayersFromXML(xml:XMLList):Vector.<Player>{
			var pls:Vector.<Player> = new Vector.<Player>;;
			
			for(var i:int=0;i<xml.children().length();i++){
				if(xml.child(i).name()=="p"){
					var player:Player = new Player();
					player.id = xml.child(i).i;
					player.alias = xml.child(i).a;
					pls.push(player);
					//trace(player.alias);
				}
			}
			return pls;
		}
		
	}
}