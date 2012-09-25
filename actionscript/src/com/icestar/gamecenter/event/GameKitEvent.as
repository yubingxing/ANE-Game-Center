package com.icestar.gamecenter.event
{
	import flash.events.Event;
	
	public class GameKitEvent extends Event
	{
		public static const PLAYER_STATUS_CHANGED:String = "player_status_changed";
		public static const PLAYER_AVAILABILITY_CHANGED:String = "player_availability_changed";
		
		public static const REQUEST_MATCH_COMPLETE:String = "request_match_complete";
		public static const MATCH_PLAYERS_INITIALIZED:String = "match_players_initialized";
		
		public static const RECEIVED_DATA_FROM:String = "received_data_from";
		
		public var params:Array;
		public function GameKitEvent(type:String, prms:Array = null,bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			params = prms;
		}
	}
}