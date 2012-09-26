package com.icestar.gamekit.gamecenter
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class GCPlayer extends EventDispatcher
	{
		public var playerID:String;
		public var alias:String;
		public var isHost:Boolean;
		public var isFriend : Boolean;
		
		public function GCPlayer()
		{
			super();
		}
	}
}