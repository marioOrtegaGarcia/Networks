/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{

    //  This is the other part of Wiring
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;
}


implementation{
  //  This is where we are saving the pack (or package we are sending over to the other Nodes)
   pack sendPackage;
   uint16_t nodeSeq = 0;
   //  Here we can lis all the neighbors for this mote
   //List neighbors;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
     //  Booting/Starting our lowest networking layer exposed in TinyOS which is also called active messages (AM)
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   //  This function makes sure all the Radios are turned on
   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
         //  Maybe timer for neighbor discovery
      }else{
         //Retry until successful

         call AMControl.start();
      }
   }
   //  **Might have to implement this one later
   event void AMControl.stopDone(error_t err){}

     //  type message_t contains our AM pack
     //  We need to send to everyone, and just check with this function if it's meant for us.
     event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
     //  Know if it's a ping/pingReply
     //  Check to see if i've received it or not, check list
     //  Checking if its for self first, if it is let sender know I got it
     //  If not, then forward the message to AMBroadcast
     //

     //  Pack found
     dbg(GENERAL_CHANNEL, "Packet Received\n");
     //  Checking if file is modified
     if (len==sizeof(pack)) {
       pack* myMsg=(pack*) payload;
       // Checking if this is a Ping Protocol
       if (myMsg->protocol == PROTOCOL_PING) {
        // Checking if package is at Destination
        if (myMsg->dest == TOS_NODE_ID) {
          dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
          return msg;
        } else {
          // if Pack not home and alive then send it
          // My Message time to live is 0
          if (myMsg->TTL == 0) {
             dbg(GENERAL_CHANNEL, "MESSAGE DIED \n");
        } else {
          makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL--, myMsg->protocol, myMsg->seq, myMsg->payload, len);
          call Sender.send(sendPackage, destination);
        }
       } else if (myMsg->protocol == PROTOCOL_PINGREPLY) {
         //WHAT TO DO WHEN ITS A REPLY
       }
     }

   }
   dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
   return msg;
  /*
       //something something
       //Testing github



        if(nPack->dest != TOS_NODE_ID) {
          // If Active Message is dead
          if(nPack->TTL == 0){
            // If AM is still alive
          } else {
            //makePack(&sendPackage, nPack->src, nPack->dest, nPack->TTL--, nPack->protocol, nPack->seq , nPack->payload, sizeof(nPack->payload));
          }
        // If the Ping is your's
        } else {
          if(len==sizeof(pack)){
             pack* myMsg=(pack*) payload;
             dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
             return msg;
          }
          dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
          return msg;
        }
        // If it's a Ping reply
      } else if (nPack->protocol = PROTOCOL_PINGREPLY) {
        }
      // If the Ping is your's
      } else {
        if(len==sizeof(pack)){
           pack* myMsg=(pack*) payload;
           dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
           return msg;
        }
        dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
        return msg;
      }
    } else if (nPack->protocol = PROTOCOL_PINGREPLY) {
>>>>>>> ffa9dcf40243761348eaa186c6dba9184ab42d91

      }*/
     }

   // This is how we send a message to one another
   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");

      makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, nodeSeq++, payload, PACKET_MAX_PAYLOAD_SIZE);

      call Sender.send(sendPackage, destination);
   }

   //  This are functions we are going to be implementing in the future.
   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
