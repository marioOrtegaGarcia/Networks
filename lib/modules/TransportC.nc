//#include "../../packet.h"
#include "../../includes/socket.h"
#include "../../includes/tcp_packet.h"

configuration TransportC{
     provides interface Transport;
}

implementation{
     components TransportP;
     Transport = TransportP;

     components RandomC as Random;
     TransportP.Random -> Random;

     components new SimpleSendC(AM_PACK);
     TransportP.Sender -> SimpleSendC;

     components new HashmapC(socket_store_t, 10);
     TransportP.sockets -> HashmapC;

     components new TimerMilliC() as  TimerT1;
     TransportP.TimedOut -> TimerT1;

     components new TimerMilliC() as  TimerT2;
     TransportP.AckTimer -> TimerT2;


}
/*




0:1:42.507812910 DEBUG (2): Where we insert to  the array
0:1:42.507812910 DEBUG (2): Attempting to make string
0:1:42.507812910 DEBUG (2): ----------> HERE
0:1:42.507812910 DEBUG (2): Char(h) -> Int(104)
0:1:42.507812910 DEBUG (2): Char(e) -> Int(101)
0:1:42.507812910 DEBUG (2): Char() -> Int(0)
0:1:42.507812910 DEBUG (2): Char(?) -> Int(208)
0:1:42.507812910 DEBUG (2): Char() -> Int(0)
0:1:42.507812910 DEBUG (2): Char(?) -> Int(192)
0:1:42.507812910 DEBUG (2): Char() -> Int(0)
0:1:42.507812910 DEBUG (2): Char( ) -> Int(32)
0:1:42.507812910 DEBUG (2): Char() -> Int(1)
0:1:42.507812910 DEBUG (2): Char(.) -> Int(46)
0:1:42.507812910 DEBUG (2): Char(?) -> Int(192)
0:1:42.507812910 DEBUG (2): Char() -> Int(2)
0:1:42.507812910 DEBUG (2): Char(?) -> Int(208)
0:1:42.507812910 DEBUG (2): Char() -> Int(16)
0:1:42.507812910 DEBUG (2): Char(?) -> Int(160)
0:1:42.507812910 DEBUG (2): Char(") -> Int(34)
0:1:42.507812910 DEBUG (2): Char() -> Int(2)
0:1:42.507812910 DEBUG (2): Char(?) -> Int(153)
0:1:42.507812910 DEBUG (2): ----------> HERE








*/
