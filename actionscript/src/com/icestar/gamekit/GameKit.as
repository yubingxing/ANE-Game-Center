package com.icestar.gamekit
{
	import com.icestar.gamekit.event.GameCenterEvent;
	import com.icestar.gamekit.event.GameKitEvent;
	import com.icestar.gamekit.event.PeerSessionEvent;
	import com.icestar.gamekit.gamecenter.GCMatch;
	import com.icestar.gamekit.gamecenter.GCPlayer;
	import com.icestar.gamekit.interfaces.IGameDelegate;
	import com.icestar.gamekit.p2p.Peer;
	import com.icestar.gamekit.p2p.Session;
	import com.icestar.gamekit.p2p.SessionMode;
	
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	
	final public class GameKit {
		private static const EXTENSION_ID:String = "com.icestar.GameKit";
		private static const dispatcher:EventDispatcher = new EventDispatcher;
		
		private static var _isAuthenticating : Boolean;
		private static var _delegate:IGameDelegate;
		
		private static var _match:Match;
		private static var _expectedPlayerCount:int = 2;
		private static var _curConnectionType:int = ConnectionType.LOCAL;
		
		private static var _gameCenterSupported : Boolean;
		private static var _p2pSupported : Boolean;
		private static var _isAuthenticated : Boolean;
		private static var _isAuthenticatedTested : Boolean;
		
		private static var _gcMatch:GCMatch;
		private static var _gcLocalPlayer:GCPlayer;
		
		private static var _session:Session;
		private static var _p2pLocalPlayer:Peer;
		
		private static var _localPlayer : Player;
		private static var _localPlayerTested : Boolean;
		
		private static var ext : ExtensionContext = null;
		private static var _initialised : Boolean = false;
		
		// Error messages dispatched from here
		internal static const notSupportedError : String = "Game Kit is not supported on this device.";
		internal static const authenticationNotAttempted : String = "You must call authenticateLocalPlayer to get the local player's Game Kit credentials.";
		internal static const NOT_AUTHENTICATED:String = "NotAuthenticated";
		internal static const notAuthenticatedError : String = "The local player is not authenticated on Game Kit.";
		
		private static var _myName:String = null;
		
		/**
		 * Initialise the extension
		 */
		public static function init(delegate:IGameDelegate) : void
		{
			_delegate = delegate;
			if ( !_initialised )
			{
				_initialised = true;
				_gameCenterSupported = ext.call( NativeMethods.isSupported ) as Boolean;
				_p2pSupported = ext.call( NativeMethods.isBluetoothAvailable ) as Boolean;
				
				_localPlayer = new Player;
				_p2pLocalPlayer = new Peer;
				_p2pLocalPlayer.displayName = "";
				
				ext = ExtensionContext.createExtensionContext( EXTENSION_ID, null );
				ext.addEventListener( StatusEvent.STATUS, handleStatusEvent );
			}
		}
		
		public static function get delegate():IGameDelegate {
			return _delegate;
		}
		
		/**
		 * Is the extension supported
		 */
		public static function get isGameCenterSupported() : Boolean {
			return _gameCenterSupported;
		}
		
		public static function get isP2PSupported():Boolean {
			return _p2pSupported;
		}
		
		private static function assertIsSupported() : void
		{
			if( !_initialised )
				throw new Error( notSupportedError );
		}
		
		/**
		 * Is the local player authenticated
		 */
		public static function get isAuthenticated() : Boolean
		{
			return _isAuthenticated;
		}
		
		private static function assertIsAuthenticatedTested() : void
		{
			assertIsSupported();
			if( !_isAuthenticatedTested )
			{
				throw new Error( authenticationNotAttempted );
			}
		}
		
		private static function assertIsAuthenticated() : void
		{
			assertIsAuthenticatedTested();
			if( !_isAuthenticated )
			{
				throw new Error( notAuthenticatedError );
			}
		}
		
		public static function get isLocal():Boolean {
			return _curConnectionType == ConnectionType.LOCAL;
		}
		
		public static function get isHost():Boolean {
			return _localPlayer.id == _match.hostPlayerID;
		}
		
		public static function get isServer():Boolean {
			return _curConnectionType == ConnectionType.SERVER_CLIENT && isHost;
		}
		
		public static function get isClient():Boolean {
			return _curConnectionType == ConnectionType.SERVER_CLIENT && !isHost;
		}
		
		/**
		 * Authenticate the local player
		 */
		public static function get localPlayer() : Player
		{
			assertIsAuthenticatedTested();
			if( _isAuthenticated && !_localPlayerTested )
			{
				_localPlayer = ext.call( NativeMethods.getLocalPlayer ) as Player;
			}
			return _localPlayer;
		}
		
		public static function get match():Match {
			return _match;
		}
		
		public static function get detectedServers():Vector.<Peer> {
			return _session.detectedServers;
		}
		
		public static function set expectedPlayerCount(value:int):void {
			_expectedPlayerCount = value;
		}
		
		public static function get expectedPlayerCount():int {
			return _expectedPlayerCount;
		}
		
		public static function set peerDisplayName(value:String):void {
			_p2pLocalPlayer.displayName = value;
		}
		
		public static function get peerDisplayName():String {
			return _p2pLocalPlayer.displayName;
		}
		
		public static function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void {
			dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public static function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void {
			dispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public static function hadEventListener(type:String):Boolean {
			return dispatcher.hasEventListener(type);
		}
		
		private static function onAuthenticateStatusChanged(e:StatusEvent):void {
			var connected:Boolean;
			if(e.level!=""){
				var p:Object = JSON.parse(e.level);
				if(_gcLocalPlayer){
					if(_gcLocalPlayer.playerID == String(p.id)){
						/**Same player authenticated.
						 * */
						connected = true;
					}else{
						/**Authenticated as other players,
						 * should quit current match.
						 * */
						connected = false;
					}
				}else{
					/**The first time authenticated.
					 * */
					_gcLocalPlayer = new GCPlayer();
					connected = true;
				}
				_gcLocalPlayer.playerID = String(p.id);
				_gcLocalPlayer.alias = String(p.alias);
				_isAuthenticated = true;
			}else{
				_gcLocalPlayer = null;
				_isAuthenticated = false;
				connected = false;
			}
			//alert("connection type",String(_current_connection_type));
			if(_curConnectionType == ConnectionType.GAME_CENTER){
				if(_gcLocalPlayer){
					localPlayer.id = _gcLocalPlayer.playerID;
					localPlayer.alias = _gcLocalPlayer.alias;
					//alert("_gcLocalPlayer","1");
				}else{
					_localPlayer = new Player();
					//alert("_gcLocalPlayer","2");
				}
				delegate.onPlayerConnectionStatusChanged(localPlayer.id, connected);
			}
			
			//alert("localplayer",localPlayer.id);
			delegate.onGameCenterAuthenticatedChanged();
		}
		private static function onMatchRequestComplete(e:*):void{
			//_gkmatch = new GKMatch();
			delegate.onMatchRequestComplete();
		}
		private static function onMatchRequestCanceled(e:*):void{
			delegate.onMatchRequestCanceled();
		}
		private static function onMatchRequestError(e:*):void{
			delegate.onMatchRequestError();
		}
		private static function onMatchPlayersInitialized(e:*):void{
			if(_curConnectionType == ConnectionType.PEER_2_PEER){
				onMatchRequestComplete(null);
			}
			if(e.level && e.level.charAt(0) == '['){
				_match.initializePlayers(JSON.parse(e.level) as Array,localPlayer);
				//alert("Initialized",localPlayer.id+","+_match.hostPlayerID);
				if(isHost){
					/**
					 * For each connection type, there always has a host, who generates the objective variables, such as map items
					 * and random positions.
					 * */
					broadcastToOthers(String(_match.generatePlayersJSON()));
					delegate.initializeMatchAsHost();
				}else{
					/** Waiting for the initialization information from host */
				}
			}
		}
		/**
		 *Handle a request from a client or a peer.
		 **/
		private static function onClientRequest(e:StatusEvent):void{
			if(e.level && e.level.charAt() == '{'){
				var p:Object = JSON.parse(e.level);
			}
			var peer:Peer = new Peer();
			peer.peerID = p.id;
			peer.displayName = p.alias;
			if(_session){
				if(_session.peers.length < _match.maxPlayers){
					acceptPeer(peer.peerID);
				}else{
					denyPeer(peer.peerID);
				}
			}
		}
		private static function onPlayerStatusChanged(e:StatusEvent):void{
			var p:Object = JSON.parse(e.level);
			/**
			 * Availibility only works in
			 * Server-Client and Peers connection modes.
			 * 
			 * */
			switch(p.status){
				case PlayerStatus.AVAILABLE:
					if(isClient){
						/**If it is Server Client mode, show avaible servers to client for accept.
						 * */
						var peer:Peer = new Peer();
						peer.peerID = p.id;
						peer.displayName = p.alias;
						_session.addServer(peer);
						delegate.onPlayerAvailabilityChanged();
					}else{
						/**
						 * If it is Peers mode, connect the peer directly.
						 * */
						joinServer(p.id);
					}
					break;
				case PlayerStatus.UNAVAILABLE:
					if(isClient){
						_session.removeServer(p.id);
						delegate.onPlayerAvailabilityChanged();
					}else{
						onPlayerDisconnected(p.id);
					}
					break;
				case PlayerStatus.CONNECTED:
					onPlayerConnected(p.id,p.alias);
					break;
				case PlayerStatus.DISCONNECTED:
					onPlayerDisconnected(p.id);
					break;
			}
		}
		private static function handleStatusEvent( e : StatusEvent ) : void
		{
			//trace( "internal event", event.level );
			switch( e.code )
			{
				//==================PeerSessionEvent=================
				case PeerSessionEvent.RECEIVED_CLIENT_REQUEST:
					onClientRequest(e);
					break;
				//==================GameKitEvent==================
				case GameKitEvent.RECEIVED_DATA_FROM:
					Router.receive(e.level);
					break;
				case GameKitEvent.CONNECTION_FAILED:
					dispatcher.dispatchEvent(new GameKitEvent(GameKitEvent.CONNECTION_FAILED));
					break;
				case GameKitEvent.MATCH_PLAYERS_INITIALIZED:
					onMatchPlayersInitialized(e);
					break;
				case GameKitEvent.PLAYER_AVAILABILITY_CHANGED:
					break;
				case GameKitEvent.PLAYER_STATUS_CHANGED:
					onPlayerStatusChanged(e);
					break;
				case GameKitEvent.REQUEST_MATCH_COMPLETE:
					onMatchRequestComplete(e);
					break;
				//==================GameCenterEvent=================
				case GameCenterEvent.LOCALPLAYER_AUTHENTICATED :
					_isAuthenticating = false;
					_isAuthenticated = true;
					_isAuthenticatedTested = true;
					_localPlayerTested = false;
					if(!_gcLocalPlayer)_gcLocalPlayer = new GCPlayer;
					_gcLocalPlayer.playerID = localPlayer.id;
					_gcLocalPlayer.alias = localPlayer.alias;
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOCALPLAYER_AUTHENTICATED));
					onAuthenticateStatusChanged(e);
					break;
				case GameCenterEvent.LOCALPLAYER_NOT_AUTHENTICATED :
					_isAuthenticating = false;
					_isAuthenticated = false;
					_isAuthenticatedTested = true;
					_localPlayerTested = false;
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOCALPLAYER_NOT_AUTHENTICATED));
					onAuthenticateStatusChanged(e);
					break;
				case NOT_AUTHENTICATED :
					throw new Error( notAuthenticatedError );
					break;
				case GameCenterEvent.SCORE_REPORTED :
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.SCORE_REPORTED));
					break;
				case GameCenterEvent.SCORE_NOT_REPORTED :
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.SCORE_NOT_REPORTED));
					break;
				case GameCenterEvent.ACHIEVEMENT_REPORTED :
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.ACHIEVEMENT_REPORTED));
					break;
				case GameCenterEvent.ACHIEVEMENT_NOT_REPORTED :
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.ACHIEVEMENT_NOT_REPORTED));
					break;
				case GameCenterEvent.LOAD_FRIENDS_COMPLETE :
					var friends : Array = getReturnedPlayers( e.level );
					if( friends )
						dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_FRIENDS_COMPLETE, friends));
					else
						dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_FRIENDS_FAILED));
					break;
				case GameCenterEvent.LOAD_FRIENDS_FAILED :
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_FRIENDS_FAILED));
					break;
				case GameCenterEvent.LOAD_LOCALPLAYER_SCORE_COMPLETE :
					var score : GCLeaderboard = getReturnedLocalPlayerScore( e.level );
					if( score )
						dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_LOCALPLAYER_SCORE_COMPLETE, score));
					else
						dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_LOCALPLAYER_SCORE_FAILED));
					break;
				case GameCenterEvent.LOAD_LOCALPLAYER_SCORE_FAILED :
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_LOCALPLAYER_SCORE_FAILED));
					break;
				case GameCenterEvent.GAMECENTER_VIEW_REMOVED :
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.GAMECENTER_VIEW_REMOVED));
					break;
				case GameCenterEvent.LOAD_LEADERBOARD_COMPLETE :
					var leaderboard : GCLeaderboard = getStoredLeaderboard( e.level );
					if( leaderboard )
						dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_LEADERBOARD_COMPLETE, leaderboard));
					else
						dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_LEADERBOARD_FAILED));
					break;
				case GameCenterEvent.LOAD_LEADERBOARD_FAILED :
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_LEADERBOARD_FAILED));
					break;
				case GameCenterEvent.LOAD_ACHIEVEMENTS_COMPLETE :
					var achievements : Vector.<GCAchievement> = getStoredAchievements( e.level );
					if( achievements )
						dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_ACHIEVEMENTS_COMPLETE, achievements));
					else
						dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_ACHIEVEMENTS_FAILED));
					break;
				case GameCenterEvent.LOAD_ACHIEVEMENTS_FAILED :
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_ACHIEVEMENTS_FAILED));
					break;
			}
		}
		
		public static function alert(title:String, msg:String):void {
			ext.call(NativeMethods.alert, title, msg);
		}
		
		public static function getSystemLocaleLanguage():String {
			return ext.call(NativeMethods.getSystemLocaleLanguage) as String;
		}
		
		public static function isBluetoothAvailable():Boolean {
			return ext.call(NativeMethods.isBluetoothAvailable) as Boolean;
		}
		
		/**
		 * Authenticate the local player
		 */
		public static function authenticateLocalPlayer() : void
		{
			assertIsSupported();
			_isAuthenticating = true;
			ext.call( NativeMethods.authenticateLocalPlayer );
		}
		
		/**
		 * Report a score to Game Center
		 */
		public static function reportScore( category : String, value : int ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				ext.call( NativeMethods.reportScore, category, value );
			}
		}
		
		/**
		 * Report a achievement to Game Center
		 */
		public static function reportAchievement( category : String, value : Number, banner : Boolean = false ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				ext.call( NativeMethods.reportAchievement, category, value, banner );
			}
		}
		
		public static function showStandardLeaderboard( category : String = "", timeScope : int = -1 ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				if( category )
				{
					if( timeScope != -1 )
					{
						ext.call( NativeMethods.showStandardLeaderboardWithCategoryAndTimescope, category, timeScope );
					}
					else
					{
						ext.call( NativeMethods.showStandardLeaderboardWithCategory, category );
					}
				}
				else if( timeScope != -1 )
				{
					ext.call( NativeMethods.showStandardLeaderboardWithTimescope, timeScope );
				}
				else
				{
					ext.call( NativeMethods.showStandardLeaderboard );
				}
			}
		}
		
		public static function showStandardAchievements() : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				ext.call( NativeMethods.showStandardAchievements );
			}
		}
		
		public static function getLocalPlayerFriends() : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				ext.call( NativeMethods.getLocalPlayerFriends );
			}
		}
		
		public static function getLocalPlayerScore( category : String, playerScope : int = 0, timeScope : int = 2 ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				ext.call( NativeMethods.getLocalPlayerScore, category, playerScope, timeScope );
			}
		}
		
		public static function getLeaderboard( category : String, playerScope : int = 0, timeScope : int = 2, rangeStart : int = 1, rangeLength : int = 25 ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				ext.call( NativeMethods.getLeaderboard, category, playerScope, timeScope, rangeStart, rangeLength );
			}
		}
		
		public static function getAchievements() : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				ext.call( NativeMethods.getAchievements );
			}
		}
		
		private static function getStoredLeaderboard( key : String ) : GCLeaderboard
		{
			return ext.call( NativeMethods.getStoredLeaderboard, key ) as GCLeaderboard;
		}
		
		private static function getStoredAchievements( key : String ) : Vector.<GCAchievement>
		{
			return ext.call( NativeMethods.getStoredAchievements, key ) as Vector.<GCAchievement>;
		}
		
		private static function getReturnedLocalPlayerScore( key : String ) : GCLeaderboard
		{
			return ext.call( NativeMethods.getStoredLocalPlayerScore, key ) as GCLeaderboard;
		}
		
		private static function getReturnedPlayers( key : String ) : Array
		{
			return ext.call( NativeMethods.getStoredPlayers, key ) as Array;
		}
		
		public static function showMatchMaker( minPlayers:int, maxPlayers:int ):void {
			ext.call( NativeMethods.showMatchMaker, minPlayers, maxPlayers);
		}
		
		public static function requestPeerMatch(myName:String, sessionMode:int=SessionMode.PEER, expectedPlayerCount:int=2):String {
			return ext.call( NativeMethods.requestPeerMatch, myName, sessionMode, expectedPlayerCount) as String;
		}
		
		public static function joinServer(peerId:String):void {
			ext.call( NativeMethods.joinServer, peerId);
		}
		
		public static function acceptPeer(peerID:String):void {
			ext.call( NativeMethods.acceptPeer, peerID);
		}
		
		public static function denyPeer(peerID:String):void {
			ext.call( NativeMethods.denyPeer, peerID);
		}
		
		public function disconnectFromPeer(peerID:String):void{
			ext.call(NativeMethods.denyPeer, peerID);
			_session.removePeer(peerID);
			syncMatchPlayers(_session.peers);
			delegate.onPlayerConnectionStatusChanged(peerID,false);
		}

		public static function requestMatch(type:int, sessionMode:int=SessionMode.PEER, minPlayers:int=2, maxPlayers:int=4):void {
			_curConnectionType = type;
			_match = new Match();
			_match.connectionType = _curConnectionType;
			_match.minPlayers = minPlayers;
			_match.maxPlayers = maxPlayers;
			
			switch(type) {
				case ConnectionType.LOCAL:
					_localPlayer = new Player();
					_localPlayer.id = "1";
					_localPlayer.alias = "My Name";
					_match.hostPlayerID = _localPlayer.id;
					delegate.initializeMatchAsHost();
					break;
				case ConnectionType.GAME_CENTER:
					_localPlayer = new Player;
					_localPlayer.id = _gcLocalPlayer.playerID;
					_localPlayer.alias = _gcLocalPlayer.alias;
					ext.call( NativeMethods.showMatchMaker, minPlayers, maxPlayers);
					break;
				case ConnectionType.PEER_2_PEER:
					_session = new Session;
					_session.mode = sessionMode;
					_session.addPeer(_p2pLocalPlayer);
					
					_p2pLocalPlayer.peerID = ext.call(NativeMethods.requestPeerMatch, peerDisplayName, sessionMode, expectedPlayerCount) as String;
					
					_localPlayer = new Player;
					_localPlayer.id = _p2pLocalPlayer.peerID;
					_localPlayer.alias = _p2pLocalPlayer.displayName;
					
					if(sessionMode == SessionMode.SERVER){
						_match.hostPlayerID = _localPlayer.id;
					} else if (sessionMode == SessionMode.PEER) {
						_match.maxPlayers = expectedPlayerCount;
					}
					
					syncMatchPlayers(_session.peers);
					break;
				case ConnectionType.SERVER_CLIENT:
					break;
			}
		}
		
		private static function syncMatchPlayers(players:*):void {
			_match.syncPlayers(players);
		}
		/**
		 * This function is called by host only;
		 * */
		public static function prepareForEnteringMatch():void{
			if(_curConnectionType == ConnectionType.GAME_CENTER){
				
			}else{
				/**
				 * For Server, Client or Peers, all need lock session.
				 * */
				ext.call(NativeMethods.lockSession);
			}
			delegate.onMatchRequestComplete();
			broadcastToOthers("<entering/>");
			delegate.initializeMatchAsHost();
		}
		
		public static function disconnectFromAll():void{
			quitMatch();
			Router.reset();
		}
		
		private static function onPlayerConnected(playerID:String,playerAlias:String):void{
			var peer:Peer;
			
			if(_curConnectionType == ConnectionType.GAME_CENTER){
				
			}else if(_curConnectionType == ConnectionType.SERVER_CLIENT){
				//trace(_match.hostPlayerID,_localPlayer.id, playerID);
				if(isHost){
					peer = new Peer();
					peer.peerID = playerID;
					peer.displayName = playerAlias;
					_session.addPeer(peer);
					syncMatchPlayers(_session.peers);
					/**
					 * For a Server - Client connection, client only connects to server,
					 * so server need broadcast the whole player list to each client.
					 * */
					broadcastToOthers(_match.generatePlayersJSON());
				}else{
					/** A client can only get the connectivity infomation from server.*/
					_match.hostPlayerID = playerID;
				}
			}else if(_curConnectionType == ConnectionType.PEER_2_PEER){
				peer = new Peer();
				peer.peerID = playerID;
				peer.displayName = playerAlias;
				_session.addPeer(peer);
				syncMatchPlayers(_session.peers);
			}
			delegate.onPlayerConnectionStatusChanged(playerID,true);
		}
		
		private static function onPlayerDisconnected(playerID:String):void{
			Router.disconnectPlayer(playerID);
			if(_curConnectionType == ConnectionType.GAME_CENTER){
			}else if(_curConnectionType == ConnectionType.SERVER_CLIENT){
				
				if(isHost){
					_session.removePeer(playerID);
					syncMatchPlayers(_session.peers);
					broadcastToOthers(_match.generatePlayersJSON());
				}else{
					/** A client can only get the connectivity infomation from server.*/
					//_match.hostPlayerID = null;
				}
				
			}else if(_curConnectionType == ConnectionType.PEER_2_PEER){
				_session.removePeer(playerID);
				syncMatchPlayers(_session.peers);
			}
			delegate.onPlayerConnectionStatusChanged(playerID,false);
		}
		/**
		 * @param playerID
		 * @param data
		 */		
		public static function onReceivedDataFrom(playerID:String, data:*):void {
			if(data == null)return;
			var d:Object = JSON.parse(data);
			//alert("Received!...",String(xml));
			/**
			 * Update player list;
			 * */
			if('pl' in d){
				syncMatchPlayers(_match.extractPlayersFromJSON(data));
			}
			
			/**
			 * Entering match;
			 * */
			if('entering' in d){
				delegate.onMatchRequestComplete();
			}
			
			/**
			 * Initialized from Host
			 * */
			if('init' in d){
				delegate.initializeMatchAsClient(d.init);;
			}
			delegate.onReceivedDataFrom(playerID, d);
		}
		
		public static function sendDataTo(playerIDs:Vector.<String>, data:String):void{
			if(_curConnectionType == ConnectionType.GAME_CENTER){
				ext.call(NativeMethods.sendDataToGCPlayers, playerIDs.join(","), data);
			}else if(_curConnectionType == ConnectionType.PEER_2_PEER){
				ext.call(NativeMethods.sendDataToPeers, playerIDs.join(","), data);
			}
		}
		
		public static function broadcastToOthers(data:String):void{
			Router.send(_match.getOtherPlayerIDs(localPlayer.id), data);
		}
		public static function callServer(data:String):void{
			var vec:Vector.<String> = new Vector.<String>;
			vec.push(_match.hostPlayerID);
			Router.send(vec,data);
		}
		public static function onPlayerActionFinished(playerID:String):void{
			Router.nextActionOfPlayer(playerID);
		}
		public static function quitMatch():void{
			if(_curConnectionType == ConnectionType.GAME_CENTER){
				ext.call(NativeMethods.disconnectFromGCMatch);
			}else if(_curConnectionType == ConnectionType.PEER_2_PEER){
				ext.call(NativeMethods.disconnectFromAllPeers);
			}
		}
		/**
		 * Clean up the extension - only if you no longer need it or want to free memory. All listeners will be removed.
		 */
		public static function dispose() : void
		{
			if ( ext )
			{
				_match = null;
				_session = null;
				_localPlayer = null;
				ext.dispose();
				ext = null;
			}
			_initialised = false;
		}
	}
}
import com.icestar.gamekit.GameKit;
import com.icestar.gamekit.pack.Package;
import com.icestar.gamekit.pack.PlayerPackageBuffer;

import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.utils.Dictionary;
import flash.utils.Timer;

internal class Router {
	private static const packageIndexPool:Dictionary = new Dictionary;
	private static const packages:Vector.<Package> = new Vector.<Package>;
	private static const playerPackageBuffers:Vector.<PlayerPackageBuffer> = new Vector.<PlayerPackageBuffer>;
	
	private static var packageNumber:int = 0;
	private static var interval:int = 300;
	private static var _timer:Timer;
	
	private var currentPulseIndex:int=0;

	public static function get timer():Timer {
		if(_timer == null) {
			_timer = new Timer(interval);
			_timer.addEventListener(TimerEvent.TIMER, timerHandler);
		}
		return _timer;
	}
	
	public static function send(playerIDs:Vector.<String>, data:String):void{
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
	 * pData: {
	 * 		id: playerId,
	 * 		idx: {id:index, ...},
	 *		data: data,
	 *		fb: 1/0
	 * 	}
	 **/
	public static function receive(pData:String):void{
		if(pData && pData.charAt() == "{"){
			var data:Object = JSON.parse(pData);
			var k:int = -1;
			if(data.idx is Object){
				k = data.idx[GameKit.localPlayer.id];
			}
			if(k!=-1){
				if(data.fb !=undefined){
					handleFeedbackFrom(data.id,k);
				}else{
					giveFeedbackTo(data.id,k);
					addToBuffer(data.id, k, data.data);
				}
			}
		}
	}
	
	private static function giveFeedbackTo(playerID:String,index:int):void{
		var pck:Package = new Package();
		pck.addPlayer(playerID,index);
		pck.isFeedback = true;
		//packages.push(pck);
		/*if(!timer.running){
		start();
		}*/
		GameKit.sendDataTo(pck.playerIDs, pck.toJson());
	}
	
	private static function handleFeedbackFrom(playerID:String,index:int):void{
		var i:int = 0;
		for each (var p:Package in packages) {
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
			i++;
		}
	}
	
	private static function sendPulse():void{
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
			GameKit.sendDataTo(pck.playerIDs, pck.toJson());
		}
	}
	
	private static function getBufferById(playerID:String):PlayerPackageBuffer{
		for each(var buffer:PlayerPackageBuffer in playerPackageBuffers){
			if(buffer.playerID == playerID){
				return buffer;
			}
		}
		return null;
	}
	
	private static function addToBuffer(playerID:String, index:int, data:*):void{
		var buffer:PlayerPackageBuffer = getBufferById(playerID);
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
	
	public static function nextActionOfPlayer(playerID:String):void{
		var buffer:PlayerPackageBuffer = getBufferById(playerID);
		if(buffer){
			GameKit.onReceivedDataFrom(playerID, buffer.shiftAction());
		}
	}
	
	public static function disconnectPlayer(playerID:String):void{
		/**
		 * Remove sending data queue.
		 * */
		var i:int = 0;
		for each(var p:Package in packages){
			p.removePlayer(playerID);
			if(p.playerIDs.length==0){
				packages.splice(i,1);
			}
			if(packages.length==0){
				pause();
			}	
			i++;
		}
		/**
		 * Remove action queue.
		 * */
		i = 0;
		for each (var pf:PlayerPackageBuffer in playerPackageBuffers) {
			if(pf.playerID == playerID){
				playerPackageBuffers.splice(i,1);
				return;
			}
			i++;
		}
	}
	
	public static function pause():void{
		timer.stop();
	}
	public static function start():void{
		timer.start();
	}
	public static function restart():void{
		timer.reset();
		timer.start();
	}
	
	public static function reset():void{
		pause();
		packages.splice(0, packages.length);
		for (var key:String in packageIndexPool) {
			delete packageIndexPool[key];
		}
		playerPackageBuffers.splice(0, playerPackageBuffers.length);
	}
	
	private static function timerHandler(pEvent:TimerEvent):void{
		sendPulse();
	}
}
