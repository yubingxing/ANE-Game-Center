package com.icestar.gamekit
{
	import com.icestar.gamekit.event.GCEvent;
	import com.icestar.gamekit.event.GKEvent;
	import com.icestar.gamekit.event.GKP2PEvent;
	import com.icestar.gamekit.gamecenter.GCMatch;
	import com.icestar.gamekit.gamecenter.GCPlayer;
	import com.icestar.gamekit.interfaces.IGameDelegate;
	import com.icestar.gamekit.p2p.GKPeer;
	import com.icestar.gamekit.p2p.GKSession;
	import com.icestar.gamekit.p2p.GKSessionMode;
	
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	
	/**
	 * The utils of GameCenter and P2P local game
	 * @author IceStar
	 */
	final public class GameKit {
		private static const EXTENSION_ID:String = "com.icestar.GameKit";
		private static const dispatcher:EventDispatcher = new EventDispatcher;
		
		private static var _isAuthenticating : Boolean;
		private static var _delegate:IGameDelegate;
		
		private static var _match:GKMatch;
		private static var _expectedPlayerCount:int = 2;
		private static var _curGKConnectionType:int = GKConnectionType.LOCAL;
		
		private static var _gameCenterSupported : Boolean;
		private static var _p2pSupported : Boolean;
		private static var _isAuthenticated : Boolean;
		private static var _isAuthenticatedTested : Boolean;
		
		private static var _gcMatch:GCMatch;
		private static var _gcLocalPlayer:GCPlayer;
		
		private static var _p2pLocalPlayer:GKPeer;
		
		private static var _localPlayer : GKPlayer;
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
		public static function init(delegate:IGameDelegate, gameCenterEnable:Boolean=true) : void
		{
			_delegate = delegate;
			if ( !_initialised )
			{
				_initialised = true;
				_gameCenterSupported = ext.call( GKNativeMethods.isSupported ) as Boolean;
				_p2pSupported = ext.call( GKNativeMethods.isBluetoothAvailable ) as Boolean;
				
				_localPlayer = new GKPlayer;
				_p2pLocalPlayer = new GKPeer;
				_p2pLocalPlayer.displayName = "";
				
				ext = ExtensionContext.createExtensionContext( EXTENSION_ID, null );
				ext.addEventListener( StatusEvent.STATUS, handleStatusEvent );
				if(gameCenterEnable){
					if(isGameCenterSupported){
						authenticateLocalPlayer();
					}
				}
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
			return _curGKConnectionType == GKConnectionType.LOCAL;
		}
		
		public static function get isHost():Boolean {
			return _localPlayer.id == _match.hostPlayerID;
		}
		
		public static function get isServer():Boolean {
			return _curGKConnectionType == GKConnectionType.SERVER_CLIENT && isHost;
		}
		
		public static function get isClient():Boolean {
			return _curGKConnectionType == GKConnectionType.SERVER_CLIENT && !isHost;
		}
		
		/**
		 * Authenticate the local player
		 */
		public static function get localPlayer() : GKPlayer
		{
			assertIsAuthenticatedTested();
			if( _isAuthenticated && !_localPlayerTested )
			{
				_localPlayer = ext.call( GKNativeMethods.getLocalPlayer ) as GKPlayer;
			}
			return _localPlayer;
		}
		
		public static function get match():GKMatch {
			return _match;
		}
		
		public static function get detectedServers():Vector.<GKPeer> {
			return GKSession.detectedServers;
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
			if(_curGKConnectionType == GKConnectionType.GAME_CENTER){
				if(_gcLocalPlayer){
					localPlayer.id = _gcLocalPlayer.playerID;
					localPlayer.alias = _gcLocalPlayer.alias;
					//alert("_gcLocalPlayer","1");
				}else{
					_localPlayer = new GKPlayer();
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
			if(_curGKConnectionType == GKConnectionType.PEER_2_PEER){
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
			var peer:GKPeer = new GKPeer();
			peer.peerID = p.id;
			peer.displayName = p.alias;
			if(GKSession){
				if(GKSession.peers.length < _match.maxPlayers){
					acceptPeer(peer.peerID);
				}else{
					denyPeer(peer.peerID);
				}
			}
		}
		private static function onGKPlayerStatusChanged(e:StatusEvent):void{
			var p:Object = JSON.parse(e.level);
			/**
			 * Availibility only works in
			 * Server-Client and Peers connection modes.
			 * 
			 * */
			switch(p.status){
				case GKPlayerStatus.AVAILABLE:
					if(isClient){
						/**If it is Server Client mode, show avaible servers to client for accept.
						 * */
						var peer:GKPeer = new GKPeer();
						peer.peerID = p.id;
						peer.displayName = p.alias;
						GKSession.addServer(peer);
						delegate.onPlayerAvailabilityChanged();
					}else{
						/**
						 * If it is Peers mode, connect the peer directly.
						 * */
						joinServer(p.id);
					}
					break;
				case GKPlayerStatus.UNAVAILABLE:
					if(isClient){
						GKSession.removeServer(p.id);
						delegate.onPlayerAvailabilityChanged();
					}else{
						onPlayerDisconnected(p.id);
					}
					break;
				case GKPlayerStatus.CONNECTED:
					onPlayerConnected(p.id,p.alias);
					break;
				case GKPlayerStatus.DISCONNECTED:
					onPlayerDisconnected(p.id);
					break;
			}
		}
		private static function handleStatusEvent( e : StatusEvent ) : void
		{
			//trace( "internal event", event.level );
			switch( e.code )
			{
				//==================GKP2PEvent=================
				case GKP2PEvent.RECEIVED_CLIENT_REQUEST:
					onClientRequest(e);
					break;
				//==================GKEvent==================
				case GKEvent.RECEIVED_DATA_FROM:
					Router.receive(e.level);
					break;
				case GKEvent.CONNECTION_FAILED:
					dispatcher.dispatchEvent(new GKEvent(GKEvent.CONNECTION_FAILED));
					break;
				case GKEvent.MATCH_PLAYERS_INITIALIZED:
					onMatchPlayersInitialized(e);
					break;
				case GKEvent.PLAYER_AVAILABILITY_CHANGED:
					break;
				case GKEvent.PLAYER_STATUS_CHANGED:
					onGKPlayerStatusChanged(e);
					break;
				case GKEvent.REQUEST_MATCH_COMPLETE:
					onMatchRequestComplete(e);
					break;
				//==================GCEvent=================
				case GCEvent.LOCALPLAYER_AUTHENTICATED :
					_isAuthenticating = false;
					_isAuthenticated = true;
					_isAuthenticatedTested = true;
					_localPlayerTested = false;
					if(!_gcLocalPlayer)_gcLocalPlayer = new GCPlayer;
					_gcLocalPlayer.playerID = localPlayer.id;
					_gcLocalPlayer.alias = localPlayer.alias;
					dispatcher.dispatchEvent(new GCEvent(GCEvent.LOCALPLAYER_AUTHENTICATED));
					onAuthenticateStatusChanged(e);
					break;
				case GCEvent.LOCALPLAYER_NOT_AUTHENTICATED :
					_isAuthenticating = false;
					_isAuthenticated = false;
					_isAuthenticatedTested = true;
					_localPlayerTested = false;
					dispatcher.dispatchEvent(new GCEvent(GCEvent.LOCALPLAYER_NOT_AUTHENTICATED));
					onAuthenticateStatusChanged(e);
					break;
				case NOT_AUTHENTICATED :
					throw new Error( notAuthenticatedError );
					break;
				case GCEvent.SCORE_REPORTED :
					dispatcher.dispatchEvent(new GCEvent(GCEvent.SCORE_REPORTED));
					break;
				case GCEvent.SCORE_NOT_REPORTED :
					dispatcher.dispatchEvent(new GCEvent(GCEvent.SCORE_NOT_REPORTED));
					break;
				case GCEvent.ACHIEVEMENT_REPORTED :
					dispatcher.dispatchEvent(new GCEvent(GCEvent.ACHIEVEMENT_REPORTED));
					break;
				case GCEvent.ACHIEVEMENT_NOT_REPORTED :
					dispatcher.dispatchEvent(new GCEvent(GCEvent.ACHIEVEMENT_NOT_REPORTED));
					break;
				case GCEvent.LOAD_FRIENDS_COMPLETE :
					var friends : Array = getReturnedPlayers( e.level );
					if( friends )
						dispatcher.dispatchEvent(new GCEvent(GCEvent.LOAD_FRIENDS_COMPLETE, friends));
					else
						dispatcher.dispatchEvent(new GCEvent(GCEvent.LOAD_FRIENDS_FAILED));
					break;
				case GCEvent.LOAD_FRIENDS_FAILED :
					dispatcher.dispatchEvent(new GCEvent(GCEvent.LOAD_FRIENDS_FAILED));
					break;
				case GCEvent.LOAD_LOCALPLAYER_SCORE_COMPLETE :
					var score : GCLeaderboard = getReturnedLocalPlayerScore( e.level );
					if( score )
						dispatcher.dispatchEvent(new GCEvent(GCEvent.LOAD_LOCALPLAYER_SCORE_COMPLETE, score));
					else
						dispatcher.dispatchEvent(new GCEvent(GCEvent.LOAD_LOCALPLAYER_SCORE_FAILED));
					break;
				case GCEvent.LOAD_LOCALPLAYER_SCORE_FAILED :
					dispatcher.dispatchEvent(new GCEvent(GCEvent.LOAD_LOCALPLAYER_SCORE_FAILED));
					break;
				case GCEvent.GAMECENTER_VIEW_REMOVED :
					dispatcher.dispatchEvent(new GCEvent(GCEvent.GAMECENTER_VIEW_REMOVED));
					break;
				case GCEvent.LOAD_LEADERBOARD_COMPLETE :
					var leaderboard : GCLeaderboard = getStoredLeaderboard( e.level );
					if( leaderboard )
						dispatcher.dispatchEvent(new GCEvent(GCEvent.LOAD_LEADERBOARD_COMPLETE, leaderboard));
					else
						dispatcher.dispatchEvent(new GCEvent(GCEvent.LOAD_LEADERBOARD_FAILED));
					break;
				case GCEvent.LOAD_LEADERBOARD_FAILED :
					dispatcher.dispatchEvent(new GCEvent(GCEvent.LOAD_LEADERBOARD_FAILED));
					break;
				case GCEvent.LOAD_ACHIEVEMENTS_COMPLETE :
					var achievements : Vector.<GCAchievement> = getStoredAchievements( e.level );
					if( achievements )
						dispatcher.dispatchEvent(new GCEvent(GCEvent.LOAD_ACHIEVEMENTS_COMPLETE, achievements));
					else
						dispatcher.dispatchEvent(new GCEvent(GCEvent.LOAD_ACHIEVEMENTS_FAILED));
					break;
				case GCEvent.LOAD_ACHIEVEMENTS_FAILED :
					dispatcher.dispatchEvent(new GCEvent(GCEvent.LOAD_ACHIEVEMENTS_FAILED));
					break;
			}
		}
		
		public static function alert(title:String, msg:String):void {
			ext.call(GKNativeMethods.alert, title, msg);
		}
		
		public static function getSystemLocaleLanguage():String {
			return ext.call(GKNativeMethods.getSystemLocaleLanguage) as String;
		}
		
		public static function isBluetoothAvailable():Boolean {
			return ext.call(GKNativeMethods.isBluetoothAvailable) as Boolean;
		}
		
		/**
		 * Authenticate the local player
		 */
		public static function authenticateLocalPlayer() : void
		{
			assertIsSupported();
			_isAuthenticating = true;
			ext.call( GKNativeMethods.authenticateLocalPlayer );
		}
		
		/**
		 * Report a score to Game Center
		 */
		public static function reportScore( category : String, value : int, onResult:Function=null ) : void
		{
			assertIsAuthenticated();
			if(onResult != null) {
				function removeListener():void {
					removeEventListener(GCEvent.SCORE_REPORTED, scoreReportSuccess);
					removeEventListener(GCEvent.SCORE_NOT_REPORTED, scoreReportFailed);
				}
				function scoreReportSuccess(e:GCEvent):void {
					removeListener();
					if(onResult != null)
						onResult.call(null, true);
					trace("scoreReportSuccess");
				}
				function scoreReportFailed(e:GCEvent):void {
					removeListener();
					if(onResult != null)
						onResult.call(null, false);
					trace("scoreReportFailed");
				}
				addEventListener(GCEvent.SCORE_REPORTED, scoreReportSuccess);
				addEventListener(GCEvent.SCORE_NOT_REPORTED, scoreReportFailed);
			}
			if( localPlayer )
			{
				ext.call( GKNativeMethods.reportScore, category, value );
			}
		}
		
		/**
		 * Report a achievement to Game Center
		 */
		public static function reportAchievement( category : String, value : Number, banner : Boolean = false, onResult:Function = null ) : void
		{
			assertIsAuthenticated();
			if(onResult != null) {
				function removeListener():void {
					removeEventListener(GCEvent.ACHIEVEMENT_REPORTED, achievementReportSuccess);
					removeEventListener(GCEvent.ACHIEVEMENT_NOT_REPORTED, achievementReportFailed);
				}
				function achievementReportSuccess(e:GCEvent):void {
					removeListener();
					if(onResult != null)
						onResult.call(null, false);
					trace("achievementReportSuccess");
				}
				function achievementReportFailed(e:GCEvent):void {
					removeListener();
					if(onResult != null)
						onResult.call(null, false);
					trace("achievementReportFailed");
				}
				addEventListener(GCEvent.ACHIEVEMENT_REPORTED, achievementReportSuccess);
				addEventListener(GCEvent.ACHIEVEMENT_NOT_REPORTED, achievementReportFailed);
			}
			if( localPlayer )
			{
				ext.call( GKNativeMethods.reportAchievement, category, value, banner );
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
						ext.call( GKNativeMethods.showStandardLeaderboardWithCategoryAndTimescope, category, timeScope );
					}
					else
					{
						ext.call( GKNativeMethods.showStandardLeaderboardWithCategory, category );
					}
				}
				else if( timeScope != -1 )
				{
					ext.call( GKNativeMethods.showStandardLeaderboardWithTimescope, timeScope );
				}
				else
				{
					ext.call( GKNativeMethods.showStandardLeaderboard );
				}
			}
		}
		
		public static function showStandardAchievements() : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				ext.call( GKNativeMethods.showStandardAchievements );
			}
		}
		
		public static function getLocalPlayerFriends(onResult:Function) : void
		{
			assertIsAuthenticated();
			if(onResult != null) {
				function removeListener():void {
					removeEventListener(GCEvent.LOAD_FRIENDS_COMPLETE, localPlayerFriendsLoaded);
					removeEventListener(GCEvent.LOAD_FRIENDS_FAILED, localPlayerFriendsFailed);
				}
				function localPlayerFriendsLoaded(e:GCEvent):void {
					removeListener();
					var friends:Array = e.data;
					if(onResult != null)
						onResult.call(null, friends);
					trace("localPlayerFriendsLoaded");
				}
				function localPlayerFriendsFailed(e:GCEvent):void {
					removeListener();
					if(onResult != null)
						onResult.call(null, []);
					trace("localPlayerFriendsFailed");
				}
				addEventListener(GCEvent.LOAD_FRIENDS_COMPLETE, localPlayerFriendsLoaded);
				addEventListener(GCEvent.LOAD_FRIENDS_FAILED, localPlayerFriendsFailed);
			}
			if( localPlayer )
			{
				ext.call( GKNativeMethods.getLocalPlayerFriends );
			}
		}
		
		public static function getLocalPlayerScore( category : String, playerScope : int = 0, timeScope : int = 2, onResult:Function = null ) : void
		{
			assertIsAuthenticated();
			if(onResult != null) {
				function removeListener():void {
					removeEventListener(GCEvent.LOAD_LOCALPLAYER_SCORE_COMPLETE, _localPlayerScoreLoaded);
					removeEventListener(GCEvent.LOAD_LOCALPLAYER_SCORE_FAILED, _localPlayerScoreFailed);
				}
				function _localPlayerScoreLoaded(e:GCEvent):void {
					removeListener();
					var leaderboard:GCLeaderboard = e.data;
					if(leaderboard.localPlayerScore && onResult != null){
						onResult.call(null, leaderboard.localPlayerScore);
					}
				}
				function _localPlayerScoreFailed(e:GCEvent):void {
					removeListener();
					if(onResult != null)
						onResult.call();
					trace("localPlayerScoreFailed");
				}
				addEventListener(GCEvent.LOAD_LOCALPLAYER_SCORE_COMPLETE, _localPlayerScoreLoaded);
				addEventListener(GCEvent.LOAD_LOCALPLAYER_SCORE_FAILED, _localPlayerScoreFailed);
			}
			if( localPlayer ) {
				ext.call( GKNativeMethods.getLocalPlayerScore, category, playerScope, timeScope );
			}
		}
		
		public static function getLeaderboard( category : String, playerScope : int = 0, timeScope : int = 2, rangeStart : int = 1, rangeLength : int = 25, onResult:Function = null ) : void
		{
			assertIsAuthenticated();
			if(onResult != null) {
				function removeListener():void {
					removeEventListener(GCEvent.LOAD_LEADERBOARD_COMPLETE, leaderboardLoaded);	
					removeEventListener(GCEvent.LOAD_LEADERBOARD_FAILED, leaderboardFailed);	
				}
				function leaderboardLoaded(e:GCEvent):void {
					removeListener();
					var leaderboard:GCLeaderboard = e.data;
					if(onResult != null){
						onResult.call(null, leaderboard);
					}
				}
				function leaderboardFailed(e:GCEvent):void {
					removeListener();
					if(onResult != null)
						onResult.call();
					trace("localPlayerScoreFailed");
				}
				addEventListener(GCEvent.LOAD_LEADERBOARD_COMPLETE, leaderboardLoaded);	
				addEventListener(GCEvent.LOAD_LEADERBOARD_FAILED, leaderboardFailed);	
			}
			if( localPlayer )
			{
				ext.call( GKNativeMethods.getLeaderboard, category, playerScope, timeScope, rangeStart, rangeLength );
			}
		}
		
		public static function getAchievements(onResult:Function=null) : void
		{
			assertIsAuthenticated();
			if(onResult != null) {
				function removeListener():void {
					removeEventListener(GCEvent.LOAD_ACHIEVEMENTS_COMPLETE, achievementLoaded);	
					removeEventListener(GCEvent.LOAD_ACHIEVEMENTS_FAILED, achievementFailed);	
				}
				function achievementLoaded(e:GCEvent):void {
					removeListener();
					var achievements:Vector.<GCAchievement> = e.data;
					if(onResult != null){
						onResult.call(null, achievements);
					}
				}
				function achievementFailed(e:GCEvent):void {
					removeListener();
					if(onResult != null){
						onResult.call();
					}
					trace("localPlayerScoreFailed");
				}
				removeEventListener(GCEvent.LOAD_ACHIEVEMENTS_COMPLETE, achievementLoaded);	
				removeEventListener(GCEvent.LOAD_ACHIEVEMENTS_FAILED, achievementFailed);	
			}
			if( localPlayer )
			{
				ext.call( GKNativeMethods.getAchievements );
			}
		}
		
		private static function getStoredLeaderboard( key : String ) : GCLeaderboard
		{
			return ext.call( GKNativeMethods.getStoredLeaderboard, key ) as GCLeaderboard;
		}
		
		private static function getStoredAchievements( key : String ) : Vector.<GCAchievement>
		{
			return ext.call( GKNativeMethods.getStoredAchievements, key ) as Vector.<GCAchievement>;
		}
		
		private static function getReturnedLocalPlayerScore( key : String ) : GCLeaderboard
		{
			return ext.call( GKNativeMethods.getStoredLocalPlayerScore, key ) as GCLeaderboard;
		}
		
		private static function getReturnedPlayers( key : String ) : Array
		{
			return ext.call( GKNativeMethods.getStoredPlayers, key ) as Array;
		}
		
		public static function showMatchMaker( minPlayers:int=2, maxPlayers:int=4 ):void {
			ext.call( GKNativeMethods.showMatchMaker, minPlayers, maxPlayers);
		}
		
		public static function showPeerPicker(myName:String, sessionMode:int=1):void {
			ext.call( GKNativeMethods.showPeerPicker, myName, sessionMode);
		}
		
		public static function requestPeerMatch(myName:String, sessionMode:int=1, expectedPlayerCount:int=2):String {
			return ext.call( GKNativeMethods.requestPeerMatch, myName, sessionMode, expectedPlayerCount) as String;
		}
		
		public static function joinServer(peerId:String):void {
			ext.call( GKNativeMethods.joinServer, peerId);
		}
		
		public static function acceptPeer(peerID:String):void {
			ext.call( GKNativeMethods.acceptPeer, peerID);
		}
		
		public static function denyPeer(peerID:String):void {
			ext.call( GKNativeMethods.denyPeer, peerID);
		}
		
		public function disconnectFromPeer(peerID:String):void{
			ext.call(GKNativeMethods.denyPeer, peerID);
			GKSession.removePeer(peerID);
			syncMatchPlayers(GKSession.peers);
			delegate.onPlayerConnectionStatusChanged(peerID,false);
		}
		
		public static function requestMatch(type:int, sessionMode:int=1, minPlayers:int=2, maxPlayers:int=4):void {
			_curGKConnectionType = type;
			_match = new GKMatch();
			_match.connectionType = _curGKConnectionType;
			_match.minPlayers = minPlayers;
			_match.maxPlayers = maxPlayers;
			
			switch(type) {
				case GKConnectionType.LOCAL:
					_localPlayer = new GKPlayer();
					_localPlayer.id = "1";
					_localPlayer.alias = "My Name";
					_match.hostPlayerID = _localPlayer.id;
					delegate.initializeMatchAsHost();
					break;
				case GKConnectionType.GAME_CENTER:
					_localPlayer = new GKPlayer;
					_localPlayer.id = _gcLocalPlayer.playerID;
					_localPlayer.alias = _gcLocalPlayer.alias;
					ext.call( GKNativeMethods.showMatchMaker, minPlayers, maxPlayers);
					break;
				case GKConnectionType.PEER_2_PEER:
					GKSession.init();
					GKSession.mode = sessionMode;
					GKSession.addPeer(_p2pLocalPlayer);
					
					_p2pLocalPlayer.peerID = ext.call(GKNativeMethods.requestPeerMatch, peerDisplayName, sessionMode, expectedPlayerCount) as String;
					
					_localPlayer = new GKPlayer;
					_localPlayer.id = _p2pLocalPlayer.peerID;
					_localPlayer.alias = _p2pLocalPlayer.displayName;
					
					if(sessionMode == GKSessionMode.SERVER){
						_match.hostPlayerID = _localPlayer.id;
					} else if (sessionMode == GKSessionMode.PEER) {
						_match.maxPlayers = expectedPlayerCount;
					}
					
					syncMatchPlayers(GKSession.peers);
					break;
				case GKConnectionType.SERVER_CLIENT:
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
			if(_curGKConnectionType == GKConnectionType.GAME_CENTER){
				
			}else{
				/**
				 * For Server, Client or Peers, all need lock session.
				 * */
				ext.call(GKNativeMethods.lockSession);
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
			var peer:GKPeer;
			
			if(_curGKConnectionType == GKConnectionType.GAME_CENTER){
				
			}else if(_curGKConnectionType == GKConnectionType.SERVER_CLIENT){
				//trace(_match.hostPlayerID,_localPlayer.id, playerID);
				if(isHost){
					peer = new GKPeer();
					peer.peerID = playerID;
					peer.displayName = playerAlias;
					GKSession.addPeer(peer);
					syncMatchPlayers(GKSession.peers);
					/**
					 * For a Server - Client connection, client only connects to server,
					 * so server need broadcast the whole player list to each client.
					 * */
					broadcastToOthers(_match.generatePlayersJSON());
				}else{
					/** A client can only get the connectivity infomation from server.*/
					_match.hostPlayerID = playerID;
				}
			}else if(_curGKConnectionType == GKConnectionType.PEER_2_PEER){
				peer = new GKPeer();
				peer.peerID = playerID;
				peer.displayName = playerAlias;
				GKSession.addPeer(peer);
				syncMatchPlayers(GKSession.peers);
			}
			delegate.onPlayerConnectionStatusChanged(playerID,true);
		}
		
		private static function onPlayerDisconnected(playerID:String):void{
			Router.disconnectPlayer(playerID);
			if(_curGKConnectionType == GKConnectionType.GAME_CENTER){
			}else if(_curGKConnectionType == GKConnectionType.SERVER_CLIENT){
				
				if(isHost){
					GKSession.removePeer(playerID);
					syncMatchPlayers(GKSession.peers);
					broadcastToOthers(_match.generatePlayersJSON());
				}else{
					/** A client can only get the connectivity infomation from server.*/
					//_match.hostPlayerID = null;
				}
				
			}else if(_curGKConnectionType == GKConnectionType.PEER_2_PEER){
				GKSession.removePeer(playerID);
				syncMatchPlayers(GKSession.peers);
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
			if(_curGKConnectionType == GKConnectionType.GAME_CENTER){
				ext.call(GKNativeMethods.sendDataToGCPlayers, playerIDs.join(","), data);
			}else if(_curGKConnectionType == GKConnectionType.PEER_2_PEER){
				ext.call(GKNativeMethods.sendDataToPeers, playerIDs.join(","), data);
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
			if(_curGKConnectionType == GKConnectionType.GAME_CENTER){
				ext.call(GKNativeMethods.disconnectFromGCMatch);
			}else if(_curGKConnectionType == GKConnectionType.PEER_2_PEER){
				ext.call(GKNativeMethods.disconnectFromAllPeers);
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
				_localPlayer = null;
				GKSession.init();
				ext.dispose();
				ext = null;
			}
			_initialised = false;
		}
	}
}
import com.icestar.gamekit.GameKit;
import com.icestar.gamekit.pack.GKPackage;
import com.icestar.gamekit.pack.GKPlayerPackageBuffer;

import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.utils.Dictionary;
import flash.utils.Timer;

internal class Router {
	private static const packageIndexPool:Dictionary = new Dictionary;
	private static const packages:Vector.<GKPackage> = new Vector.<GKPackage>;
	private static const playerPackageBuffers:Vector.<GKPlayerPackageBuffer> = new Vector.<GKPlayerPackageBuffer>;
	
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
		var pck:GKPackage = new GKPackage();
		
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
		var pck:GKPackage = new GKPackage();
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
		for each (var p:GKPackage in packages) {
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
		var pck:GKPackage = packages[currentPulseIndex];
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
		for each(var pck:GKPackage in packages){
			GameKit.sendDataTo(pck.playerIDs, pck.toJson());
		}
	}
	
	private static function getBufferById(playerID:String):GKPlayerPackageBuffer{
		for each(var buffer:GKPlayerPackageBuffer in playerPackageBuffers){
			if(buffer.playerID == playerID){
				return buffer;
			}
		}
		return null;
	}
	
	private static function addToBuffer(playerID:String, index:int, data:*):void{
		var buffer:GKPlayerPackageBuffer = getBufferById(playerID);
		if(buffer==null){
			buffer = new GKPlayerPackageBuffer(playerID);
			playerPackageBuffers.push(buffer);
		}
		
		var pck:GKPackage = new GKPackage();
		pck.addPlayer(playerID,index);
		pck.data = data;
		
		buffer.push(pck);
		
		nextActionOfPlayer(playerID);
	}
	
	public static function nextActionOfPlayer(playerID:String):void{
		var buffer:GKPlayerPackageBuffer = getBufferById(playerID);
		if(buffer){
			GameKit.onReceivedDataFrom(playerID, buffer.shiftAction());
		}
	}
	
	public static function disconnectPlayer(playerID:String):void{
		/**
		 * Remove sending data queue.
		 * */
		var i:int = 0;
		for each(var p:GKPackage in packages){
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
		for each (var pf:GKPlayerPackageBuffer in playerPackageBuffers) {
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
