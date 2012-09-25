package com.icestar.gamecenter
{
	import flash.events.Event;
	
	public final class GameCenterEvent extends Event {
		public static const LOCALPLAYER_AUTHENTICATED:String  = "LocalPlayerAuthenticated";
		public static const LOCALPLAYER_NOT_AUTHENTICATED:String = "LocalPlayerNotAuthenticated";
		public static const SCORE_REPORTED:String = "ScoreReported";
		public static const SCORE_NOT_REPORTED:String = "ScoreNotReported";
		public static const ACHIEVEMENT_REPORTED:String = "AchievementReported";
		public static const ACHIEVEMENT_NOT_REPORTED:String = "AchievementNotReported";
		public static const GAMECENTER_VIEW_REMOVED:String = "GameCenterViewRemoved";
		public static const LOAD_FRIENDS_COMPLETE:String = "LoadFriendsComplete";
		public static const LOAD_FRIENDS_FAILED:String = "LoadFriendsFailed";
		public static const LOAD_LOCALPLAYER_SCORE_COMPLETE:String = "LoadLocalPlayerScoreComplete";
		public static const LOAD_LOCALPLAYER_SCORE_FAILED:String = "LoadLocalPlayerScoreFailed";
		public static const LOAD_LEADERBOARD_COMPLETE:String = "LoadLeaderboardComplete";
		public static const LOAD_LEADERBOARD_FAILED:String = "LoadLeaderboardFailed";
		public static const LOAD_ACHIEVEMENTS_COMPLETE:String = "LoadAchievementsComplete";
		public static const LOAD_ACHIEVEMENTS_FAILED:String = "LoadAchievementsFailed";
		//==============add gamecenter match func======================
		public static const MATCH_STARTED:String = "MatchStarted";
		public static const MATCH_ENDED:String = "MatchEnded";
		public static const INVITE_RECEIVED:String = "InviteReceived";
		//==============add local p2p connection================
		public static const PLAYER_STATUS_CHANGE:String = "playerStatusChanged";
		public static const RECEIVED_CLIENT_REQUEST:String = "receivedClientRequest";
		//==============received data==================
		public static const RECEIVED_DATA:String = "receivedData";
		
		public function GameCenterEvent(type:String, data:*=null, bubbles:Boolean=false, cancelable:Boolean=false) {
			this._data = data;
			super(type, bubbles, cancelable);
		}
		
		public function get data():* {
			return _data;
		}
		
		/** @private */
		private var _data:* = null;
	}
}