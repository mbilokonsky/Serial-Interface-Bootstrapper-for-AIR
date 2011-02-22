from sys import argv, stdin
from serial import Serial
import threading

try:
    baudRate = int(argv[-1])
    serialPort = argv[1:-1]
except ValueError:
    #some nice default
    baudRate = 9600
    serialPort = argv[1:]

#support paths with spaces. Windows maybe?
serialPort = ' '.join(serialPort)
if not serialPort:
    exit("Please specify a serial port")

print( "opening connection to %r@%i ..." % (serialPort, baudRate) )
ser = Serial(serialPort, baudRate, timeout=1)    



class readerThread(threading.Thread):
    def __init__(self, threadID, name):
        threading.Thread.__init__(self)
        self.threadID = threadID
        self.name = name
  
    def run(self):
       while True:
           if ser.inWaiting() > 0:
               print( ser.readline() )
               

class writerThread(threading.Thread): 
    def __init__(self, threadID, name):
        threading.Thread.__init__(self)
        self.threadID = threadID
        self.name = name
    def run(self):
        while True:
            input = stdin.readline()
            print ("\tYou input %s" % input.strip())
            ser.write(input.strip())    
        
thread1 = readerThread(1, "readerThread")
thread2 = writerThread(2, "writerThread")

thread1.start()
thread2.start()