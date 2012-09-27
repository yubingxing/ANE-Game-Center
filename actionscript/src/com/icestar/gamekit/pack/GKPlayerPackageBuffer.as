package com.icestar.gamekit.pack
{
	public class GKPlayerPackageBuffer
	{
		private var currentIndex:int = -1;
		
		private var packages:Vector.<GKPackage>;
		
		public var playerID:String;
		
		
		public function GKPlayerPackageBuffer(id:String)
		{
			packages = new Vector.<GKPackage>();
			playerID = id;
		}
		
		public function push(pPackage:GKPackage):void{
			/**Check whether the income package is out of date.
			 * */
			var packageIndex:int = pPackage.getPlayerIndex(playerID);
			if( packageIndex <= currentIndex)return;
			
			for each(var pck:GKPackage in packages){
				if(pck.getPlayerIndex(playerID) == packageIndex){
					/** already have the same message, do nothing.*/
					return;
				}
			}
			packages.push(pPackage);
			sortPackage();
		}
		
		private function sortPackage():void{
			var tempArr:Array = [];
			for each(var pck:GKPackage in packages){
				tempArr.push({pck:pck,index:pck.getPlayerIndex(playerID)});
			}
			tempArr.sortOn("index",Array.NUMERIC);
			packages = new Vector.<GKPackage>();
			for(var i:int=0;i<tempArr.length;i++){
				packages.push(tempArr[i]["pck"]);
			}
		}
		
		public function shiftAction():String{
			if(packages.length==0){
				return null;
			}
			var pck:GKPackage = packages[0] as GKPackage;
			var packageIndex:int = pck.getPlayerIndex(playerID);
			if( packageIndex == currentIndex + 1){
				/**
				 * If there is no action package on the way.*/
				
				currentIndex = packageIndex;
				pck = packages.shift() as GKPackage;
				return pck.data;
			}
			/** Wait for the ealier sent message.*/
			return null;
		}
	}
}