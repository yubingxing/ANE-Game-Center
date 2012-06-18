package com.sticksports.nativeExtensions.gameCenter
{
	import com.sticksports.nativeExtensions.gameCenter.signals.GCSignal0;
	import com.sticksports.nativeExtensions.gameCenter.signals.GCSignal1;

	public class GameCenter
	{
		public static var localPlayerAuthenticated : GCSignal0 = new GCSignal0();
		public static var localPlayerNotAuthenticated : GCSignal0 = new GCSignal0();
		public static var localPlayerFriendsLoadComplete : GCSignal1 = new GCSignal1( Array );
		public static var localPlayerFriendsLoadFailed : GCSignal0 = new GCSignal0();
		public static var leaderboardLoadComplete : GCSignal1 = new GCSignal1( GCLeaderboard );
		public static var leaderboardLoadFailed : GCSignal0 = new GCSignal0();
		public static var localPlayerScoreLoadComplete : GCSignal1 = new GCSignal1( GCLeaderboard );
		public static var localPlayerScoreLoadFailed : GCSignal0 = new GCSignal0();
		public static var localPlayerScoreReported : GCSignal0 = new GCSignal0();
		public static var localPlayerScoreReportFailed : GCSignal0 = new GCSignal0();
		public static var localPlayerAchievementReported : GCSignal0 = new GCSignal0();
		public static var localPlayerAchievementReportFailed : GCSignal0 = new GCSignal0();
		public static var achievementsLoadComplete : GCSignal1 = new GCSignal1( Vector );
		public static var achievementsLoadFailed : GCSignal0 = new GCSignal0();
		public static var gameCenterViewRemoved : GCSignal0 = new GCSignal0();
		
		public static var isAuthenticating : Boolean;
		
		public static function init() : void
		{
		}
		
		/**
		 * Is the extension supported
		 */
		public static function get isSupported() : Boolean
		{
			return false;
		}
		
		private static function throwNotSupportedError() : void
		{
			throw new Error( "Game Kit is not supported on this device." );
		}

		/**
		 * Authenticate the local player
		 */
		public static function authenticateLocalPlayer() : void
		{
			throwNotSupportedError();
		}

		public static function get isAuthenticated() : Boolean
		{
			return false;
		}

		/**
		 * Authenticate the local player
		 */
		public static function get localPlayer() : GCLocalPlayer
		{
			throwNotSupportedError();
			return null;
		}

		/**
		 * Report a score to Game Kit
		 */
		public static function reportScore( category : String, value : int ) : void
		{
			throwNotSupportedError();
		}
		
		/**
		 * Report a achievement to Game Kit
		 */
		public static function reportAchievement( category : String, value : Number ) : void
		{
			throwNotSupportedError();
		}

		public static function showStandardLeaderboard( category : String = "", timeScope : int = -1 ) : void
		{
			throwNotSupportedError();
		}
		
		public static function showStandardAchievements() : void
		{
			throwNotSupportedError();
		}

		public static function getLocalPlayerFriends() : void
		{
			throwNotSupportedError();
		}
		
		public static function getLocalPlayerScore( category : String, playerScope : int = 0, timeScope : int = 2 ) : void
		{
			throwNotSupportedError();
		}

		public static function getLeaderboard( category : String, playerScope : int = 0, timeScope : int = 2, rangeStart : int = 1, rangeLength : int = 25 ) : void
		{
			throwNotSupportedError();
		}
		
		public static function getAchievements() : void
		{
			throwNotSupportedError();
		}

		/**
		 * Clean up the extension - only if you no longer need it or want to free memory.
		 */
		public static function dispose() : void
		{
			localPlayerAuthenticated.removeAll();
			localPlayerNotAuthenticated.removeAll();
			localPlayerFriendsLoadComplete.removeAll();
			localPlayerFriendsLoadFailed.removeAll();
			localPlayerScoreLoadComplete.removeAll();
			localPlayerScoreLoadFailed.removeAll();
			localPlayerScoreReported.removeAll();
			localPlayerScoreReportFailed.removeAll();
			localPlayerAchievementReported.removeAll();
			localPlayerAchievementReportFailed.removeAll();
			leaderboardLoadComplete.removeAll();
			leaderboardLoadFailed.removeAll();
			achievementsLoadComplete.removeAll();
			achievementsLoadFailed.removeAll();
			gameCenterViewRemoved.removeAll();
		}
	}
}
