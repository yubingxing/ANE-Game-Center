package com.icestar.gamekit
{
	internal class NativeMethods
	{
		internal static const alert : String = "GC_alert";
		internal static const getSystemLocaleLanguage : String = "GC_getSystemLocaleLanguage";
		internal static const isBluetoothAvailable : String = "GC_isBluetoothAvailable";
		internal static const isSupported : String = "GC_isSupported";
		internal static const authenticateLocalPlayer : String = "GC_authenticateLocalPlayer";
		internal static const getLocalPlayer : String = "GC_getLocalPlayer";
		internal static const reportScore : String = "GC_reportScore";
		internal static const reportAchievement : String = "GC_reportAchievement";
		internal static const showStandardLeaderboard : String = "GC_showStandardLeaderboard";
		internal static const showStandardLeaderboardWithCategory : String = "GC_showStandardLeaderboardWithCategory";
		internal static const showStandardLeaderboardWithTimescope : String = "GC_showStandardLeaderboardWithTimescope";
		internal static const showStandardLeaderboardWithCategoryAndTimescope : String = "GC_showStandardLeaderboardWithCategoryAndTimescope";
		internal static const showStandardAchievements : String = "GC_showStandardAchievements";
		internal static const getLocalPlayerFriends : String = "GC_getLocalPlayerFriends";
		internal static const getLocalPlayerScore : String = "GC_getLocalPlayerScore";
		internal static const getLeaderboard : String = "GC_getLeaderboard";
		internal static const getStoredLeaderboard : String = "GC_getStoredLeaderboard";
		internal static const getStoredLocalPlayerScore : String = "GC_getStoredLocalPlayerScore";
		internal static const getStoredPlayers : String = "GC_getStoredPlayers";
		internal static const getAchievements : String = "GC_getAchievements";
		internal static const getStoredAchievements : String = "GC_getStoredAchievements";
		// add gamecenter match func
		internal static const showMatchMaker : String = "GC_showMatchMaker";
		internal static const sendData : String = "GC_sendData";
		internal static const sendDataToGCPlayers : String = "GC_sendDataToGCPlayers";
		// add local p2p func
		internal static const requestPeerMatch : String = "LP_requestPeerMatch";
		internal static const joinServer : String = "LP_joinServer";
		internal static const acceptPeer : String = "LP_acceptPeer";
		internal static const denyPeer : String = "LP_denyPeer";
	}
}
