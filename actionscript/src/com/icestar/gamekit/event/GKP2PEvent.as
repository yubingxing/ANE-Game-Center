package com.icestar.gamekit.event
{
	import flash.events.Event;
	
	public class GKP2PEvent extends Event
	{
		public static const RECEIVED_CLIENT_REQUEST:String = "received_client_request";
		//public static const 
		public var params:Array;
		public function GKP2PEvent(type:String, prms:Array = null,bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			params = prms;
		}
	}
}