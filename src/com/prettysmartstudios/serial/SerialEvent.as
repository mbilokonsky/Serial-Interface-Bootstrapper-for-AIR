package com.prettysmartstudios.serial
{
	import flash.events.Event;
	
	public class SerialEvent extends Event
	{
		public static const PYTHON_NOT_FOUND:String = "python not found";
		
		public static const NATIVE_PROCESS_STARTED:String = "native process starting";
		public static const NATIVE_PROCESS_ENDED:String = "native process ended";
		
		public static const STANDARD_OUTPUT:String = "standard output";
		public static const STANDARD_ERROR:String = "standard error";
		
		public var message:String;
		
		public function SerialEvent(type:String, message:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.message = message;
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event {
			return new SerialEvent(type, message, bubbles, cancelable);
		}
	}
}