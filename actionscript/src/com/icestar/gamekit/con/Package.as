package  com.icestar.gamekit.con
{
	import com.icestar.gamekit.GameKit;

	public class Package
	{
		public var playerIndexes:Object;
		public var playerIDs:Vector.<String>;
		
		public var data:String="";
		
		public var isFeedback:Boolean =false;
		
		public function Package()
		{
			playerIndexes = new Object();
			playerIDs = new Vector.<String>;
		}
		
		public function addPlayer(playerID:String,index:int):void{
			for(var i:int=0;i<playerIDs.length;i++){
				if(playerIDs[i] == playerID){
					return;
				}
			}
			playerIDs.push(playerID);
			playerIndexes[playerID] = index;
		}
		
		public function removePlayer(playerID:String):void{
			for(var i:int=0;i<playerIDs.length;i++){
				if(playerIDs[i] == playerID){
					playerIDs.splice(i,1);
					playerIndexes[playerID] = null;
					return;
				}
			}
		}
		public function getPlayerIndex(playerID:String):int{
			return playerIndexes[playerID];
		}
		/**
		 * <data>
		 * <i>local player id</i>
		 * 
		 * <fb/>
		 * 
		 * <p>
		 * 	<i>player1_ID</i>
		 * 	<k>0</k>
		 * </p>
		 * <p>
		 * 	<i>player2_ID</i>
		 * 	<k>4</k>
		 * </p>
		 * <p>
		 * 	<i>player3_ID</i>
		 * 	<k>2</k>
		 * </p>
		 * 
		 * <d>data in here</d>
		 * 
		 * </data>
		 * 
		 * */
		public function generateData():String{
			var str:String = "<data>";
			str +="<i>"+GameKit.manager.localPlayer.id + "</i>";
			if(isFeedback){
				str +="<fb/>";
			}
			for(var id:String in playerIndexes){
				str +="<p><i>"+id+"</i><k>"+playerIndexes[id]+"</k></p>";
			}
			str += "<d>"+data+"</d>";
			str +="</data>";
			
			return str;
			
		}
	}
}