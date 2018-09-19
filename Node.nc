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

   uses interface Hashmap <uint32_t> as PackLogs;
}
/* Pseudo Code from Lab TA
*  First Part of Project
* TOS_NODE_ID current node ID
* Make Pack again and broadcast again if its not yours
* When you've seen the package you are supposed to ignore it using the sequence Number
***  Ping Reply
*  Flip source and destination and set it as the ping protocol
*** Sequence number starts at 0 only increment when you ping
* TTL is based on number of nodes so we can set it to 20
* Decrease TTL-- each time you send
*
*** Neighbor Discovery
*** we can make our own protocol from neighbor Discovery
*
*/

implementation{
  //  This is where we are saving the pack (or package we are sending over to the other Nodes)
   pack sendPackage;
   uint16_t nodeSeq = 0;
   int index = 0;

   //  Here we can lis all the neighbors for this mote
  // We getting an error with neighbors

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   void updatePack(pack* payload);
   bool hasSeen(pack* payload);
   //void savePack(pack* payload);

   event void Boot.booted(){
     //  Booting/Starting our lowest networking layer exposed in TinyOS which is also called active messages (AM)
      call AMControl.start();
      //start timer
      //  We need to initiate the node Timer first
      //call NodeTimerC.startOneShot(1000);
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

     //check packets to see if they have passed through this node beofore
     void updatePack(pack* payload) {

       uint32_t src = payload->src;
       uint32_t seq = payload->seq;

       //if packet log isnt empty and contains the src key
      if(!hasSeen(payload)){
        //remove old key value pair and insert new one

        call PackLogs.remove(src);
       }
       //logPack(payload);
       call PackLogs.insert(src, seq);
     }

     bool hasSeen(pack* payload) {
       uint32_t seq = payload->seq;
       uint32_t src = payload->src;

       //if packet log isnt empty and contains the src key
       //and if the value at the src key is less than the current packet's sequence, then we know we haven't seen this packet before
       if(! call PackLogs.isEmpty())
         if(call PackLogs.contains(src))
            if((call PackLogs.get(seq)) <= seq)
              return 1;
      //otherwise we havent seen the packet before
       return 0;
     }

     //  type message_t contains our AM pack
     //  We need to send to everyone, and just check with this function if it's meant for us.
   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
     pack* myMsg =(pack*) payload;
     //  Know if it's a ping/pingReply
     //  Check to see if i've received it or not, check list
     //  Checking if its for self first, if it is let sender know I got it
     //  If not, then forward the message to AMBroadcast
     //
     //dbg(GENERAL_CHANNEL, "Packet Received\n");
     //pack* myMsg;
     //myMsg=(pack*) payload;

     // Take out Packs that are corrupted or dead
     if (len !=sizeof(pack) || myMsg->TTL == 0) {
       // Kill
       //~~dbg(FLOODING_CHANNEL, "Package Dead\n");
       return msg;
     }

     //  Ping Protocol
     if (myMsg->protocol == PROTOCOL_PING) {

       // My Message
       if (myMsg->dest == TOS_NODE_ID) {
         if (!hasSeen(myMsg)) {
           //  Recieve message
           //~~Sdbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
           dbg(FLOODING_CHANNEL, "<> Received Package Payload: %s\n", myMsg->payload);
           //  Ping reply
           nodeSeq++;
           makePack(&sendPackage, myMsg->dest, myMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, nodeSeq, (uint8_t*)myMsg->payload, len);
           call Sender.send(sendPackage, AM_BROADCAST_ADDR);
           //  Package Log
           logPack(myMsg);
           logPack(&sendPackage);
           updatePack(myMsg);
         }

       // Not my Message
       } else {
         //Forward to printNeighbors
         if (myMsg->TTL > 0) myMsg->TTL -= /*(nx_uint8_t)*/ 1;
         makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL, myMsg->protocol, myMsg->seq, (uint8_t*)myMsg->payload, len);
         call Sender.send(sendPackage, AM_BROADCAST_ADDR);
         //Ping Reply?
         //Log Pack
         //logPack(myMsg);
         updatePack(myMsg);
       }

     } // End of Ping Protocol

     //  Ping Reply Protocol
     if (myMsg->protocol == PROTOCOL_PINGREPLY) {
       //package is mine
       if (!hasSeen(myMsg)) {

         if (myMsg->dest == TOS_NODE_ID) {

           dbg(FLOODING_CHANNEL, "MADE IT!!!!!!!!!!!!!!!!!!!!!!\n");
           updatePack(myMsg);
           return msg;
         } else {
           if(myMsg->TTL > 0) myMsg->TTL -= /*(nx_uint8_t)*/ 1;
           makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL, myMsg->protocol, myMsg->seq, (uint8_t*)myMsg->payload, len);
           call Sender.send(sendPackage, AM_BROADCAST_ADDR);
           //logPack(myMsg);
           updatePack(myMsg);
         }

       }
     } // End of Ping Reply Protocol

    return msg;
   }

   // This is how we send a message to one another
   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){

      dbg(GENERAL_CHANNEL, "PING EVENT \n");

      nodeSeq++;
      makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, nodeSeq, payload, PACKET_MAX_PAYLOAD_SIZE);
      //logPack(&sendPackage);

      call Sender.send(sendPackage, AM_BROADCAST_ADDR);
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
