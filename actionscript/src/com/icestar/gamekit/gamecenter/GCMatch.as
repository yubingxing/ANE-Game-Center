package com.icestar.gamekit.gamecenter
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class GCMatch extends EventDispatcher
	{
		public var players:Vector.<GCPlayer>;
		
		public function GCMatch()
		{
			super();
		}
	}
}