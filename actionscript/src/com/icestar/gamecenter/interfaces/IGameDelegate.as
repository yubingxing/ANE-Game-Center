package com.icestar.gamecenter.interfaces
{
	import com.icestar.gamecenter.Match;
	import com.icestar.gamecenter.Player;
	import com.icestar.gamecenter.p2p.Peer;
	


	public interface IGameDelegate
	{
		function get isGameCenterSupported():Boolean;
		function get isP2PSupported():Boolean;
		function get isAuthenticated():Boolean;
		function set peerDisplayName(pVal:String):void;
		function get peerDisplayName():String;
		function get detectedServers():Vector.<Peer>;
		function get isLocal():Boolean;
		function get isHost():Boolean;
		function get isServer():Boolean;
		function get isClient():Boolean;
		function get match():Match;
		function get localPlayer():Player;
		function set expectedPlayerCount(pVal:int):void;
		function get expectedPlayerCount():int;
		
		function requestMatch(type:int,sessionMode:int=1,minPlayers:int=2,maxPlayers:int=4):void;
		function initializeMatchAsHost():void;
		function initializeMatchAsClient(data:*):void
		function onMatchRequestComplete():void;
		function onMatchRequestCanceled():void;
		function onMatchRequestError():void;
		//function onMatchPlayersInitialized():void;
		function onPlayerAvailabilityChanged():void;
		function onPlayerConnectionStatusChanged(playerID:String,connected:Boolean):void;
		function onGameCenterAuthenticatedChanged():void;
		function onReceivedDataFrom(playerID:String,data:*):void;
		function broadcastToOthers(data:*):void
		function callServer(data:*):void;
		function quitMatch():void;
	}
}