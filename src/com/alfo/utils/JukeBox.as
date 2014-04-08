package com.alfo.utils
{

	
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.media.ID3Info;
	
	import mx.core.UIComponent;

	public class JukeBox extends UIComponent
	{
		public var libraryPath:String="";
		public var musicLibrary:Array=new Array();
		
		private var mp3Player:Mp3Player;
		
		public var directory:File;
		
		public function JukeBox() 
		{
			mp3Player=new Mp3Player(false);
			mp3Player.addEventListener("Mp3Player.Play",handleNextBck);
			mp3Player.addEventListener("Mp3Player.ID3",handleBckID3);
			mp3Player.addEventListener("Mp3Player.SongComplete",handleBackComplete);
		}
		
		public function pause():void {
			mp3Player.pause();
		}
		
		public function unPause():void {
			mp3Player.unpause();
		}
		
		
		function handleNextBck(e:Event)
		{
			trace("change dataprovider");
			
		}
		function handleBckID3(e:Event)
		{
			trace("id3 event");
			
		}
		private function handleBackComplete(e:Event) {
			trace("mp3 complete");
		}
		public function init(path:String) {
			scanDirectory(path);
		}
		
		private function scanDirectory(thePath:String) {
			musicLibrary=new Array();
			mp3Player.musicPath= File.applicationDirectory.resolvePath("assets/jukeboxmusic").url;
			directory = File.applicationDirectory.resolvePath("assets/jukeboxmusic");
			trace("directory:"+directory.url);
			try {
				var contents:Array = directory.getDirectoryListing();  
			} catch (e:Error) {
				trace("error reading directory:"+e.message);
			}
			for (var i:uint = 0; i < contents.length; i++)  
			{ 
				mp3Player.playlist.push(contents[i].name as String);
				musicLibrary.push(contents[i].name as String);
				trace(contents[i].name, contents[i].size);  
			} 
			trace("library length:"+musicLibrary.length);
			mp3Player.play(musicLibrary[0]);
		}
	}
}