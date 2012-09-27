package com.icestar.gamekit
{
	internal final class GKNativeMethods
	{
		internal static const isBluetoothAvailable : String = "isBluetoothAvailable";
		internal static const alert : String = "GC_alert";
		internal static const getSystemLocaleLanguage : String = "GC_getSystemLocaleLanguage";
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
		internal static const sendDataToGCPlayers : String = "GC_sendDataToGCPlayers";
		internal static const disconnectFromGCMatch : String = "GC_disconnectFromGCMatch";
		// add local p2p func
		internal static const requestPeerMatch : String = "LP_requestPeerMatch";
		internal static const joinServer : String = "LP_joinServer";
		internal static const acceptPeer : String = "LP_acceptPeer";
		internal static const denyPeer : String = "LP_denyPeer";
		internal static const sendDataToPeers : String = "LP_sendDataToPeers";
		internal static const lockSession : String = "LP_lockSession";
		internal static const disconnectFromAllPeers : String = "LP_disconnectFromAllPeers";
		internal static const disconnectFromPeer : String = "LP_disconnectFromPeer";
	}
}
