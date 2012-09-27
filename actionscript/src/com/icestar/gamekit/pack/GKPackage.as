package  com.icestar.gamekit.pack
{
	import com.icestar.gamekit.GameKit;
	
	import flash.utils.Dictionary;

	public class GKPackage
	{
		public const playerIndexes:Dictionary = new Dictionary;
		public const playerIDs:Vector.<String> = new Vector.<String>;
		
		public var data:*=null;
		
		public var isFeedback:Boolean =false;
		
		public function GKPackage(){
		}
		
		public function addPlayer(playerID:String,index:int):void{
			if(playerIDs.indexOf(playerID) < 0){
				playerIDs.push(playerID);
				playerIndexes[playerID] = index;
			}
		}
		
		public function removePlayer(playerID:String):void{
			var index:int = playerIDs.indexOf(playerID);
			if(index >= 0) {
				playerIDs.splice(index, 1);
				delete playerIndexes[playerID];
			}
		}
		public function getPlayerIndex(playerID:String):int{
			return playerIndexes[playerID];
		}
		/**
		 * data:{
		 * 	id: playerId,
		 * 	idx: {id:index, ...},
		 * 	data: data,
		 *  fb: 1/0
		 * }
		 **/
		public function toJson():String{
			var obj:Object = {
				id:GameKit.localPlayer.id, 
				idx:playerIndexes, 
				data:data
			};
			if(isFeedback)
				obj.fb = 1;
			return JSON.stringify(obj);
		}
	}
}