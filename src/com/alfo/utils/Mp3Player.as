// From http://unformatt.com/news/as3-mp3-player/
package com.alfo.utils {

	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.media.ID3Info;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	import com.greensock.*;
	import com.greensock.plugins.*;
	
	public class Mp3Player extends EventDispatcher {
		
		static public const EVENT_TIME_CHANGE:String = 'Mp3Player.TimeChange';
		static public const EVENT_VOLUME_CHANGE:String = 'Mp3Player.VolumeChange';
		static public const EVENT_PAN_CHANGE:String = 'Mp3Player.PanningChange';
		static public const EVENT_PAUSE:String = 'Mp3Player.Pause';
		static public const EVENT_UNPAUSE:String = 'Mp3Player.Unpause';
		static public const EVENT_PLAY:String = 'Mp3Player.Play';
		static public const EVENT_ID3:String = 'Mp3Player.ID3';
		static public const EVENT_STACKEMPTY:String = 'Mp3Player.StackEmpty';
		static public const EVENT_COMPLETE:String = 'Mp3Player.SongComplete';
		//
		public var playing:Boolean;
		public var playlist:Array=new Array();
		public var currentUrl:String;
		public var playlistIndex:int = -1;
		public var isUser:Boolean=false;
		public var currentID3:ID3Info=new ID3Info();
		//
		protected var sound:Sound;
		protected var soundChannel:SoundChannel;
		protected var soundTrans:SoundTransform;
		protected var progressInt:Number;
		
		private var shuffle:Boolean=true;
		
		public var musicPath:String="";
		
		public function Mp3Player(useStack:Boolean,shuffle:Boolean=true) {
			TweenPlugin.activate([VolumePlugin]); 
			trace("Mp3Player Init"+useStack);
			isUser=useStack;
			this.shuffle=shuffle;
		}
		
		public function play( url:String ):void {
			//clearInterval(progressInt);
			trace("play command"+url);
			if ( sound ) {
				soundChannel.stop();
				try {sound.close();}catch(error:Error){trace(error);}
			}
			currentUrl = musicPath+File.separator+url;
			sound = new Sound();
			sound.addEventListener(Event.SOUND_COMPLETE, onLoadSong);
			sound.addEventListener(Event.ID3, onId3Info);
			
			sound.load(new URLRequest(currentUrl));
			
			soundChannel = sound.play();
			trace("called play");
			if ( soundTrans ) {
				soundChannel.soundTransform = soundTrans;
			} else {
				soundTrans = soundChannel.soundTransform;
			}
			soundChannel.addEventListener(Event.COMPLETE, onSongEnd);
			playing = true;
			//clearInterval(progressInt);
			trace("progressint before:"+progressInt);
			progressInt = setInterval(updateProgress, 30);
			//clearInterval(progressInt);
			trace("progressint after:"+progressInt);
			trace("called setinterval");
			dispatchEvent(new Event(EVENT_PLAY));
		}
		
		public function pause():void {
			clearInterval(progressInt);
			playing = false;
			if ( soundChannel ) {
				trace("PAUSE");
				TweenLite.to(soundChannel, 1, {volume:0,onComplete:pauseEvent});

				
			}
		}
		protected function pauseEvent() {
			soundChannel.stop();
			dispatchEvent(new Event(EVENT_PAUSE));
		}
		public function unpause():void {
			if ( playing ) return;
			if ( soundChannel.position < sound.length ) {
				trace("unpause fadein");
				soundChannel = sound.play(soundChannel.position);
				soundChannel.soundTransform = soundTrans;
				next();
				TweenLite.to(soundChannel, 1, {volume:1});

			} else {
				trace("unpause PLAY fadein");
				next();
				TweenLite.to(soundChannel, 1, {volume:1});
				soundChannel = sound.play();
			}
			dispatchEvent(new Event(EVENT_UNPAUSE));
			playing = true;
		}
		public function seek( percent:Number ):void {
			soundChannel.stop();
			soundChannel = sound.play(sound.length * percent);
		}
		public function prev():void {
			playlistIndex--;
			if ( playlistIndex < 0 ) playlistIndex = playlist.length - 1;
			play(playlist[playlistIndex]);
		}
		public function next():void {
			//if(progressInt != null) {
			//clearInterval(progressInt);
			//}
			trace("next");
			if(isUser) {
				if(playlist.length==0) {
					soundChannel.removeEventListener(Event.COMPLETE, onSongEnd);
					clearInterval(progressInt);
					soundChannel.stop();
					playing=false;
					trace("END OF USER PLAYLIST");
					dispatchEvent(new Event(EVENT_STACKEMPTY));
				} else {
					var currentSong:String=playlist[0];
					trace("NEXT SONG SPLICE:"+currentSong);
					playlist.splice(0,1);
					play(currentSong);
				}
			} else if(shuffle) {
				trace("im shuffling");
				playlistIndex=Math.floor( Math.random() * playlist.length );
				play(playlist[playlistIndex]);
			} else {
				
				playlistIndex++;
				trace("Playlist index:"+playlistIndex);
				if ( playlistIndex == playlist.length ) {
					playlistIndex = 0;
					trace("Rewind playlist");
				}
				trace("Now playing:"+playlist[playlistIndex]);
				play(playlist[playlistIndex]);
			}
		}
		public function get volume():Number {
			if (!soundTrans) return 0;
			return soundTrans.volume;
		}
		public function set volume( n:Number ):void {
			if ( !soundTrans ) return;
			soundTrans.volume = n;
			soundChannel.soundTransform = soundTrans;
			dispatchEvent(new Event(EVENT_VOLUME_CHANGE));
		}
		public function get pan():Number {
			if (!soundTrans) return 0;
			return soundTrans.pan;
		}
		public function set pan( n:Number ):void {
			if ( !soundTrans ) return;
			soundTrans.pan = n;
			soundChannel.soundTransform = soundTrans;
			dispatchEvent(new Event(EVENT_PAN_CHANGE));
		}
		public function get length():Number {
			return sound.length;
		}
		public function get time():Number {
			return soundChannel.position;
		}
		public function get timePretty():String {
			var secs:Number = soundChannel.position / 1000;
			var mins:Number = Math.floor(secs / 60);
			secs = Math.floor(secs % 60);
			return mins + ":" + (secs < 10 ? "0" : "") + secs;
		}
		public function get timePercent():Number {
			if ( !sound.length ) return 0;
			return soundChannel.position / sound.length;
		}
		protected function onLoadSong( e:Event ):void {
			trace("song loaded:"+playlistIndex);
		}
		protected function onSongEnd( e:Event ):void {
			trace("END OF SONG:"+playlistIndex+ "playter:"+isUser);
			dispatchEvent(new Event(EVENT_COMPLETE));
			if ( playlist && playing ) {
				next();
			}
		}
		protected function onId3Info( e:Event ):void {
			trace("internal id3");
			currentID3=e.target.id3;
			dispatchEvent(new Event(EVENT_ID3, e.target.id3));
		}
		protected function updateProgress():void {
			dispatchEvent(new Event(EVENT_TIME_CHANGE));
			//trace("%"+timePercent+"user:"+isUser);
			if ( timePercent >= .99 ) {
				onSongEnd(new Event(Event.COMPLETE));
				clearInterval(progressInt);
			}
		}
	}
}

