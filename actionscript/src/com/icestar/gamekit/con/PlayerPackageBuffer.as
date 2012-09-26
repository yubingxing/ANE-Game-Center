package com.icestar.gamekit.con
{
	public class PlayerPackageBuffer
	{
		private var currentIndex:int = -1;
		
		private var packages:Vector.<Package>;
		
		public var playerID:String;
		
		
		public function PlayerPackageBuffer(id:String)
		{
			packages = new Vector.<Package>();
			playerID = id;
		}
		
		public function push(pPackage:Package):void{
			/**Check whether the income package is out of date.
			 * */
			var packageIndex:int = pPackage.getPlayerIndex(playerID);
			if( packageIndex <= currentIndex)return;
			
			for each(var pck:Package in packages){
				if(pck.getPlayerIndex(playerID) == packageIndex){
					/** already have the same message, do nothing.*/
					return;
				}
			}
			packages.push(pPackage);
			sortPackage();
		}
		
		private function sortPackage():void{
			var tempArr:Array = new Array();
			for each(var pck:Package in packages){
				tempArr.push({pck:pck,index:pck.getPlayerIndex(playerID)});
			}
			tempArr.sortOn("index",Array.NUMERIC);
			packages = new Vector.<Package>();
			for(var i:int=0;i<tempArr.length;i++){
				packages.push(tempArr[i]["pck"]);
			}
		}
		
		public function shiftAction():XMLList{
			if(packages.length==0){
				return null;
			}
			var pck:Package = packages[0] as Package;
			var packageIndex:int = pck.getPlayerIndex(playerID);
			if( packageIndex == currentIndex + 1){
				/**
				 * If there is no action package on the way.*/
				
				currentIndex = packageIndex;
				pck = packages.shift() as Package;
				return  new XMLList(pck.data);
			}
			/** Wait for the ealier sent message.*/
			return null;
		}
	}
}