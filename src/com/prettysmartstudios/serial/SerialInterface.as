
/**
 *	This project has a few dependencies that have to resolved before it can work.
 * 	
 * 	1) This can only be used in an AIR 2.5+ application with access to the ExtendedDesktop profile. Anything else doesn't have access to the NativeProcess API.
 * 	2) This requires that you have python installed, and that you have the path to python.exe handy.
 * 	3) In addition to having a base Python install, this also requires that you install the PySerial module. This is very easy. Google it.
 *  4) This WILL NOT WORK if you remove or rename ThreadedSerialInterface.py, which is included in the source folder. This class is tightly coupled to that one. 
 * 		If you understand what it's doing you can feel free to edit it - it's not that complex. Just understand the ramifications.
 * 
 * 	Also, there is a workflow that must be followed to use this:
 * 	1) Instantiate SerialInterface as you would any other class.
 * 	2) Add listeners for the various SerialEvents - SerialEvent.PYTHON_NOT_FOUND is important, and SerialEvent.STANDARD_OUTPUT is practically necessary.
 *  3) VERY IMPORTANT: Be sure that your application calls the close() method on your instance of this Class. If not, ThreadedSerialInterface will continue to run
 * 		as an orphan process on your machine, tying up access to the serial port. If this happens, look for it in your OS's process manager and kill it the hard way.
 * 
 * 	This is very much an alpha build, but I hope that someone finds it useful. If you have any suggestions, please feel free to get in touch with me via Twitter.
 * 	I can usually be reached as "@mykola" fairly quickly. 
 * 
 *  
 */
package com.prettysmartstudios.serial
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.EventDispatcher;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;

	public class SerialInterface extends EventDispatcher
	{
		protected var _nativeProcess:NativeProcess;
		protected var _nativeProcessStartupInfo:NativeProcessStartupInfo;
		
		protected var _pythonLocation:String;
		protected var _port:String;
		protected var _baud:String;
		
				
		public function SerialInterface()
		{
			// nothing fancy here	
		}
		
		// PUBLIC METHODS
		
		public function startup(pythonLocation:String, port:String, baud:String):Boolean {
			var exec:File = File.applicationDirectory.resolvePath(pythonLocation);
			
			// check to see if the python path is correct. If so, initialize. If not, dispatch the SerialEvent.PYTHON_NOT_FOUND event.
			if (exec.exists) {
				
				_nativeProcess = new NativeProcess();
				_nativeProcessStartupInfo = new NativeProcessStartupInfo();
				
				_pythonLocation = pythonLocation;
				_port = port;
				_baud = baud;
				
				init(exec);
				return true;
			} else {
				dispatchEvent(new SerialEvent(SerialEvent.PYTHON_NOT_FOUND, "python not found. Check your python installation."));
				return false;
				// this should be ready for garbage collection now.
			}
		}
		
		/**
		 *	Always remember to call close() when your application closes, else the NativeProcess will be left running on your computer.
		 */
		public function close():void {
			_nativeProcess.exit(true);
		}
		
		/**
		 *	This method accepts a string that you want to write to the serial port. 
		 * 	@param textToSend This is the text that you want to send to the serial port.
		 * 
		 */		
		public function write(textToSend:String):void {
			_nativeProcess.standardInput.writeMultiByte(textToSend + "\n", File.systemCharset);
		}
		
		
		
		// PROTECTED METHODS
		/**
		 *	This method initializes the actual NativeProcess. It's called by the constructor if your python path is correct. 
		 * @param exec
		 * 
		 */		
		protected function init(exec:File):void {
			
			_nativeProcessStartupInfo.executable = exec; // assign "exec" to be the executable in our startup info.
			
			var args:Vector.<String> = new Vector.<String>; // create a vector to hold arguments - don't assign til the end.
			args[0] = "-u"; // python needs this to handle I/O correctly
			args[1] = File.applicationDirectory.resolvePath("ThreadedSerialInterface.py").nativePath; // this is the path to our python script, included with the AIR app.
			args[2] = _port; // this is the serial port, "COM3" etc on pc or "/dev/tty.usbserial-XXXXXX" on mac, etc.
			args[3] = _baud; // this is our baud rate.
			
			_nativeProcessStartupInfo.arguments = args; // assign the arguments to the startup info object.
			
			
			// add listeners for stdout, stderr and process exit.
			_nativeProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, stdoutHandler);
			_nativeProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, sterrHandler);
			_nativeProcess.addEventListener(NativeProcessExitEvent.EXIT, exitHandler);
			
			// start the NativeProcess
			_nativeProcess.start(_nativeProcessStartupInfo);
			dispatchEvent(new SerialEvent(SerialEvent.NATIVE_PROCESS_STARTED, this.toString()));
		}
		
		/**
		 *	Listens for input from stdout, parses it and dispatches it in a SerialEvent. 
		 *  @param e This is the event that this listens for, ProgressEvent.STANDARD_OUTPUT_DATA 
		 * 
		 */		
		protected function stdoutHandler(e:ProgressEvent):void {
			var output:String = e.currentTarget.standardOutput.readMultiByte(e.currentTarget.standardOutput.bytesAvailable, File.systemCharset);
			dispatchEvent(new SerialEvent(SerialEvent.STANDARD_OUTPUT, output));
		}
		
		
		/**
		 *	Listens for input from stderr, parses it and dispatches it in a SerialEvent. 
		 * 	@param e This is the event that this listens for, ProgressEvent.STANDARD_ERROR_DATA
		 * 
		 */		
		protected function sterrHandler(e:ProgressEvent):void {
			var output:String = e.currentTarget.standardError.readMultiByte(e.currentTarget.standardError.bytesAvailable, File.systemCharset);
			dispatchEvent(new SerialEvent(SerialEvent.STANDARD_ERROR, output));
		}
		
		
		/**
		 *	Listens for the NativeProcess to close, removes listeners and nulls out properties. Dispatches SerialEvent.NATIVE_PROCESS_ENDED
		 * 	when this object is ready for garbage collection.  
		 * 	@param e This is the event that this listens for, NativeProcessExitEvent.EXIT
		 * 
		 */		
		protected function exitHandler(e:NativeProcessExitEvent):void {
			_nativeProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, stdoutHandler);
			_nativeProcess.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, sterrHandler);
			_nativeProcess.removeEventListener(NativeProcessExitEvent.EXIT, exitHandler);
			
			_nativeProcessStartupInfo = null;
			_nativeProcess = null;
			_baud = null;
			_port = null;
			_pythonLocation = null;
			
			var output:String = "Native Process has Exited. This object is now ready for garbage collection.";
			
			dispatchEvent(new SerialEvent(SerialEvent.NATIVE_PROCESS_ENDED, output));
		}
		
		/**
		 *	Overriding toString to provide verbose traces. 
		 * @return Returns a string containing information about the port and baud rate used.
		 * 
		 */		
		override public function toString():String {
			return "[SerialInterface Port: " + _port + " Baud: " + _baud + "]";
		}
		
		
		
		
	}
}