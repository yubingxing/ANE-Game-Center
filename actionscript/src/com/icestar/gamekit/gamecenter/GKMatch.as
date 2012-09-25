package com.icestar.gamekit.gamecenter
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class GKMatch extends EventDispatcher
	{
		public var players:Vector.<GKPlayer>;
		
		public function GKMatch()
		{
			super();
		}
	}
}