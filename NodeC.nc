/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"

configuration NodeC{
}
// components are basically an "Object"
implementation {
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;
    components new HashmapC(uint32_t, 18) as PackLogsC;
    //components new TimerMilliC() as NodeTimerC;

    //  This is where we are Wiring our whole program.
    //  We are basically wiring objects together so they can talk to each other, this is their interface.
    Node -> MainC.Boot;

    Node.Receive -> GeneralReceive;
    Node.PackLogs -> PackLogsC;

    //NodeTimerC.

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;




}
