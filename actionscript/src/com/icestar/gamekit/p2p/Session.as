package com.icestar.gamekit.p2p
{
	import flash.events.EventDispatcher;
	
	public class Session extends EventDispatcher
	{
		public var peers:Vector.<Peer>;
		public var mode:int;
		
		public var detectedServers:Vector.<Peer>;

		
		public function Session(id:String="")
		{
			super();
			
			peers = new Vector.<Peer>;
			detectedServers = new Vector.<Peer>;
		}
		
		
		
		
		public function addPeer(peer:Peer):void{
			if(!hasPeer(peer)){
				peers.push(peer);
			}
		}
		public function removePeer(peerID:String):void{
			for(var i:int=0;i<peers.length;i++){
				if(peers[i].peerID == peerID){
					peers.splice(i,1);
					return;
				}
			}
		}
		public function hasPeer(peer:Peer):Boolean{
			for each(var p:Peer in peers){
				if(p.peerID == peer.peerID){
					return true;
				}
			}
			return false;
		}
		
		public function addServer(peer:Peer):void{
			if(!hasServer(peer)){
				detectedServers.push(peer);
			}
		}
		public function removeServer(peerID:String):void{
			for(var i:int=0;i<detectedServers.length;i++){
				if(detectedServers[i].peerID == peerID){
					detectedServers.splice(i,1);
					return;
				}
			}
		}
		public function hasServer(peer:Peer):Boolean{
			for each(var p:Peer in detectedServers){
				if(p.peerID == peer.peerID){
					return true;
				}
			}
			return false;
		}

	}
}