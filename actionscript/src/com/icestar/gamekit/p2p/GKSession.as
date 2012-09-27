package com.icestar.gamekit.p2p
{
	public class GKSession {
		public static const peers:Vector.<GKPeer> = new Vector.<GKPeer>;
		public static const detectedServers:Vector.<GKPeer> = new Vector.<GKPeer>;
		public static var mode:int;
		
		public function GKSession(id:String="") {
		}
		
		public static function init():void {
			peers.splice(0, peers.length);
			detectedServers.splice(0, detectedServers.length);
			mode = GKSessionMode.PEER;
		}
		
		public static function addPeer(peer:GKPeer):void{
			if(!hasPeer(peer)){
				peers.push(peer);
			}
		}
		public static function removePeer(peerID:String):void{
			for(var i:int=0;i<peers.length;i++){
				if(peers[i].peerID == peerID){
					peers.splice(i,1);
					return;
				}
			}
		}
		public static function hasPeer(peer:GKPeer):Boolean{
			for each(var p:GKPeer in peers){
				if(p.peerID == peer.peerID){
					return true;
				}
			}
			return false;
		}
		
		public static function addServer(peer:GKPeer):void{
			if(!hasServer(peer)){
				detectedServers.push(peer);
			}
		}
		public static function removeServer(peerID:String):void{
			for(var i:int=0;i<detectedServers.length;i++){
				if(detectedServers[i].peerID == peerID){
					detectedServers.splice(i,1);
					return;
				}
			}
		}
		public static function hasServer(peer:GKPeer):Boolean{
			for each(var p:GKPeer in detectedServers){
				if(p.peerID == peer.peerID){
					return true;
				}
			}
			return false;
		}

	}
}