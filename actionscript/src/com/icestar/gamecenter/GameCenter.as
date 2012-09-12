package com.icestar.gamecenter
{
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	
	final public class GameCenter {
		public static const EXTENSION_ID:String = "com.icestar.gamecenter";
		
		private static const dispatcher:EventDispatcher = new EventDispatcher;
		
		public static var isAuthenticating : Boolean;
		
		private static var _isSupported : Boolean;
		private static var _isSupportedTested : Boolean;
		private static var _isAuthenticated : Boolean;
		private static var _isAuthenticatedTested : Boolean;
		
		private static var _localPlayer : GCLocalPlayer;
		private static var _localPlayerTested : Boolean;
		
		private static var extensionContext : ExtensionContext = null;
		private static var initialised : Boolean = false;
		
		// Error messages dispatched from here
		internal static const notSupportedError : String = "Game Kit is not supported on this device.";
		internal static const authenticationNotAttempted : String = "You must call authenticateLocalPlayer to get the local player's Game Kit credentials.";
		internal static const notAuthenticatedError : String = "The local player is not authenticated on Game Kit.";
		
		private static const NOT_AUTHENTICATED:String = "NotAuthenticated";
		/**
		 * Initialise the extension
		 */
		public static function init() : void
		{
			if ( !initialised )
			{
				initialised = true;
				
				extensionContext = ExtensionContext.createExtensionContext( EXTENSION_ID, null );
				
				extensionContext.addEventListener( StatusEvent.STATUS, handleStatusEvent );
			}
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
		
		private static function handleStatusEvent( event : StatusEvent ) : void
		{
			//trace( "internal event", event.level );
			switch( event.level )
			{
				case GameCenterEvent.LOCALPLAYER_AUTHENTICATED :
					isAuthenticating = false;
					_isAuthenticated = true;
					_isAuthenticatedTested = true;
					_localPlayerTested = false;
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOCALPLAYER_AUTHENTICATED));
					break;
				case GameCenterEvent.LOCALPLAYER_NOT_AUTHENTICATED :
					isAuthenticating = false;
					_isAuthenticated = false;
					_isAuthenticatedTested = true;
					_localPlayerTested = false;
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOCALPLAYER_NOT_AUTHENTICATED));
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
					var friends : Array = getReturnedPlayers( event.code );
					if( friends )
						dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_FRIENDS_COMPLETE, friends));
					else
						dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_FRIENDS_FAILED));
					break;
				case GameCenterEvent.LOAD_FRIENDS_FAILED :
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_FRIENDS_FAILED));
					break;
				case GameCenterEvent.LOAD_LOCALPLAYER_SCORE_COMPLETE :
					var score : GCLeaderboard = getReturnedLocalPlayerScore( event.code );
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
					var leaderboard : GCLeaderboard = getStoredLeaderboard( event.code );
					if( leaderboard )
						dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_LEADERBOARD_COMPLETE, leaderboard));
					else
						dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_LEADERBOARD_FAILED));
					break;
				case GameCenterEvent.LOAD_LEADERBOARD_FAILED :
					dispatcher.dispatchEvent(new GameCenterEvent(GameCenterEvent.LOAD_LEADERBOARD_FAILED));
					break;
				case GameCenterEvent.LOAD_ACHIEVEMENTS_COMPLETE :
					var achievements : Vector.<GCAchievement> = getStoredAchievements( event.code );
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
		
		/**
		 * Is the extension supported
		 */
		public static function get isSupported() : Boolean
		{
			if( !_isSupportedTested )
			{
				_isSupportedTested = true;
				init();
				_isSupported = extensionContext.call( NativeMethods.isSupported ) as Boolean;
			}
			return _isSupported;
		}
		
		private static function assertIsSupported() : void
		{
			if( !isSupported )
				throw new Error( notSupportedError );
		}
		
		/**
		 * Authenticate the local player
		 */
		public static function authenticateLocalPlayer() : void
		{
			assertIsSupported();
			isAuthenticating = true;
			extensionContext.call( NativeMethods.authenticateLocalPlayer );
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
		
		/**
		 * Authenticate the local player
		 */
		public static function get localPlayer() : GCLocalPlayer
		{
			assertIsAuthenticatedTested();
			if( _isAuthenticated && !_localPlayerTested )
			{
				_localPlayer = extensionContext.call( NativeMethods.getLocalPlayer ) as GCLocalPlayer;
			}
			return _localPlayer;
		}
		
		/**
		 * Report a score to Game Center
		 */
		public static function reportScore( category : String, value : int ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.reportScore, category, value );
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
				extensionContext.call( NativeMethods.reportAchievement, category, value, banner );
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
						extensionContext.call( NativeMethods.showStandardLeaderboardWithCategoryAndTimescope, category, timeScope );
					}
					else
					{
						extensionContext.call( NativeMethods.showStandardLeaderboardWithCategory, category );
					}
				}
				else if( timeScope != -1 )
				{
					extensionContext.call( NativeMethods.showStandardLeaderboardWithTimescope, timeScope );
				}
				else
				{
					extensionContext.call( NativeMethods.showStandardLeaderboard );
				}
			}
		}
		
		public static function showStandardAchievements() : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.showStandardAchievements );
			}
		}
		
		public static function getLocalPlayerFriends() : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.getLocalPlayerFriends );
			}
		}
		
		public static function getLocalPlayerScore( category : String, playerScope : int = 0, timeScope : int = 2 ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.getLocalPlayerScore, category, playerScope, timeScope );
			}
		}
		
		public static function getLeaderboard( category : String, playerScope : int = 0, timeScope : int = 2, rangeStart : int = 1, rangeLength : int = 25 ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.getLeaderboard, category, playerScope, timeScope, rangeStart, rangeLength );
			}
		}
		
		public static function getAchievements() : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.getAchievements );
			}
		}
		
		private static function getStoredLeaderboard( key : String ) : GCLeaderboard
		{
			return extensionContext.call( NativeMethods.getStoredLeaderboard, key ) as GCLeaderboard;
		}
		
		private static function getStoredAchievements( key : String ) : Vector.<GCAchievement>
		{
			return extensionContext.call( NativeMethods.getStoredAchievements, key ) as Vector.<GCAchievement>;
		}
		
		private static function getReturnedLocalPlayerScore( key : String ) : GCLeaderboard
		{
			return extensionContext.call( NativeMethods.getStoredLocalPlayerScore, key ) as GCLeaderboard;
		}
		
		private static function getReturnedPlayers( key : String ) : Array
		{
			return extensionContext.call( NativeMethods.getStoredPlayers, key ) as Array;
		}
		
		/**
		 * Clean up the extension - only if you no longer need it or want to free memory. All listeners will be removed.
		 */
		public static function dispose() : void
		{
			if ( extensionContext )
			{
				extensionContext.dispose();
				extensionContext = null;
			}
			initialised = false;
		}
	}
}
