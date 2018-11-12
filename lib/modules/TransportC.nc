//#include "../../packet.h"
#include "../../includes/socket.h"

configuration TransportC{
     provides interface Transport;
}

implementation{
     components TransportP;
     Transport = TransportP;

     components new HashmapC(socket_store_t, 10);
     TransportP.sockets -> HashmapC;
}
/*
Traceback (most recent call last):
  File "TestSim.py", line 189, in <module>
    main()
  File "TestSim.py", line 157, in main
    s.newServer(3, 30);
  File "TestSim.py", line 129, in newServer
    self.sendCMD(self.CMD_TEST_SERVER, target, "{0}".format(chr(port)));
AttributeError: TestSim instance has no attribute 'CMD_TEST_SERVER'  
*/
