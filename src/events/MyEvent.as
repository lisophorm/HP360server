package events
{
	import flash.events.Event;
	
	public class MyEvent extends Event
	{
		public var message:String="";
		public static var STATUS_CHANGE:String="statusChange";
		
		public function MyEvent(type:String, message:String,bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.message=message;
			super(type, bubbles, cancelable);
		}
	}
}