/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

/*
 * This class is the Top Layer Configuration of our app.
 * Here we have components and their configurations
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

    components new ListC(pack, 64) as PackLogsC;
    components new HashmapC(uint16_t, 64) as NeighborListC;
    /*
     * Testing timer format from online Presentation
     * We need to initiate unique timers so the right node fires.
    */
    //components TimerC;
    components new TimerMilliC() as TimerC;

    // Wiring interfaces
    //<usr.interface -> dev.interface>;
    Node -> MainC.Boot;

    Node.Receive -> GeneralReceive;

    Node.PackLogs -> PackLogsC;
    Node.NeighborList -> NeighborListC;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components RandomC as Random;
    Node.Random -> Random;

    //Node.Timer -> TimerC;
    Node.Timer -> TimerC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;


}
