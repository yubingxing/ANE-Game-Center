package com.icestar.gamekit.p2p
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class Peer extends EventDispatcher
	{
		public var peerID:String;
		public var displayName:String;
		
		public function Peer()
		{
			super();
		}
	}
}