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

   uses interface List <pack> as PackLogs;

   uses interface List <uint32_t> as NeighborList;

   uses interface Timer<TMilli> as Timer;
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
   // Increases each time the node sends something.
   uint16_t nodeSeq = 0;

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
      call Timer.startPeriodicAt(10, 20000);
      //start timer
      //  We need to initiate the node Timer first
      //call NodeTimerC.startOneShot(1000);
      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void Timer.fired() {
     int c = 0;
     if ((c % 9) == 0) {
       dbg(GENERAL_CHANNEL, "Timer Fired!!\n");
       c++;
     }
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

     pack* recievedMsg;
     int size, index;
     bool foundMatch;

     // If the Pack is Corrupt we dont want it
     if (len == sizeof(pack)) {
       recievedMsg =(pack*) payload;

       if (recievedMsg->TTL == 0) {
        dbg(GENERAL_CHANNEL, "Package Dead\n");
        return msg;

       //  Debugs for when Pack is being cut off
      } else if (hasSeen(recievedMsg)) {
           dbg(GENERAL_CHANNEL, "Package Seen B4 <--> SRC: %d SEQ: %d\n", recievedMsg->src, recievedMsg->seq);
           return msg;
         }

       //  Pings to us in 2 Cases: Ping & pingReply when pinging back to me
      else if (recievedMsg->dest == TOS_NODE_ID) {

        // Ping to US
        if (recievedMsg->protocol == PROTOCOL_PING) {
          //    Log the message
          dbg(FLOODING_CHANNEL, "!!!    Received Package Payload: %s  Src: %d  !!!!\n", recievedMsg->payload, recievedMsg->dest);
          //    Make Ping pingReply packet reset TTL & increase nodeSeq
           nodeSeq++;
           makePack(&sendPackage, recievedMsg->dest, recievedMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, nodeSeq, (uint8_t*)recievedMsg->payload, len);
           updatePack(&sendPackage);
           //    Reply with a Ping pingReply packet
           call Sender.send(sendPackage, AM_BROADCAST_ADDR);
          //dbg(GENERAL_CHANNEL, "PING SEQUENCE: %d", nodeSeq);
          return msg;

          //  Ping Reply to US
        } else if (recievedMsg->protocol == PROTOCOL_PINGREPLY) {
          dbg(FLOODING_CHANNEL, "~~~     Ping Reply  from: %d\n", recievedMsg->src);
          //   Log
          //updatePack(&recievedMsg);
          return msg;
        } else {
          //Do Something
          dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
          return msg;
        }

        // Neighbor Discovery
      } else if (recievedMsg->protocol == PROTOCOL_PINGNEIGHBOR) {
        size = call NeighborList.size();
        foundMatch = 0;
        for (index = 0; index < size ; index++) {
          if(call NeighborList.get(index) == recievedMsg->src)
            foundMatch = 1;
        }
        if (!foundMatch) {
          call NeighborList.pushback(recievedMsg->src);
        }

        //     (Recieving obviously)
        //     Save sender under list of neighbors
        //     PingBack with our ID
      } else {// Relay

        dbg(GENERAL_CHANNEL, " Relaying Package for:  %d\n", recievedMsg->src);
        //    new packet w/ TTL - 1
        if(recievedMsg->TTL > 0) recievedMsg->TTL -=  1;
        makePack(&sendPackage, recievedMsg->src, recievedMsg->dest, recievedMsg->TTL, recievedMsg->protocol, recievedMsg->seq, (uint8_t*)recievedMsg->payload, len);
        updatePack(&sendPackage);
        //    If it's not for us then we just rellay the message to all out neighbors
        call Sender.send(sendPackage, AM_BROADCAST_ADDR);
        return msg;
      }
        dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
        return msg;
     }
     dbg(GENERAL_CHANNEL, "Corrupt Packet Type %d\n", len);
     return msg;
}

/*()
     // Take out Packs that are corrupted or dead or that we have seen
     if (len !=sizeof(pack)) {
       // Kill
       dbg(FLOODING_CHANNEL, "Package Corrupted\n");
       return msg;
     } else if (recievedMsg->TTL == 0) {
       dbg(FLOODING_CHANNEL, "Package Dead\n");
       return msg;
     } else if (hasSeen(recievedMsg)) {
       dbg(FLOODING_CHANNEL, "Package Seen B4 <-> SRC: %d SEQ: %d\n", recievedMsg->src, recievedMsg->seq);
       return msg;
     }

     //  Ping Protocol
    else if (recievedMsg->protocol == PROTOCOL_PING) {
       // My Message
       if (recievedMsg->dest == TOS_NODE_ID) {
           //  Recieve myMessage
           dbg(FLOODING_CHANNEL, "<> Received Package Payload: %s\n", recievedMsg->payload);
           updatePack(recievedMsg);

           //  Reply w/ pingReply
           nodeSeq++;
           dbg(GENERAL_CHANNEL, "PING SEQUENCE: %d", nodeSeq);
           makePack(&sendPackage, recievedMsg->dest, recievedMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, nodeSeq, (uint8_t*)recievedMsg->payload, len);

           updatePack(&sendPackage);
           call Sender.send(sendPackage, AM_BROADCAST_ADDR);

           //  Package Log
           //logPack(recievedMsg);
           logPack(&sendPackage);
       // Not my Message
       } else {
         //Forward to printNeighbors
         recievedMsg->TTL -=  1;
         updatePack(recievedMsg);

         makePack(&sendPackage, recievedMsg->src, recievedMsg->dest, recievedMsg->TTL, recievedMsg->protocol, recievedMsg->seq, (uint8_t*)recievedMsg->payload, len);

         call Sender.send(sendPackage, AM_BROADCAST_ADDR);
         //Ping Reply?
         //Log Pack
         logPack(recievedMsg);
       }

     } // End of Ping Protocol

     //  Ping Reply Protocol
     if (recievedMsg->protocol == PROTOCOL_PINGREPLY) {
       //package is mine
         if (recievedMsg->dest == TOS_NODE_ID) {
           dbg(FLOODING_CHANNEL, "MADE IT!!!!!!!!!!!!!!!!!!!!!!\n");

           updatePack(&recievedMsg);
           return msg;
           //
         } else {
           if (!hasSeen(recievedMsg)) {
             if(recievedMsg->TTL > 0) recievedMsg->TTL -=  1;
             makePack(&sendPackage, recievedMsg->src, recievedMsg->dest, recievedMsg->TTL, recievedMsg->protocol, recievedMsg->seq, (uint8_t*)recievedMsg->payload, len);
             call Sender.send(sendPackage, AM_BROADCAST_ADDR);
             logPack(recievedMsg);
             //updatePack(recievedMsg);
             updatePack(&sendPackage);
           }
         }
     } // End of Ping Reply Protocol
     // For neighbor discovery
     if () {

     }

    return msg;
    */
   //}

   // This is how we send a message to one another
   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){

      dbg(GENERAL_CHANNEL, "PING EVENT \n");

      nodeSeq++;
      dbg(GENERAL_CHANNEL, "PING SEQUENCE: %d\n", nodeSeq);
      makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, nodeSeq, payload, PACKET_MAX_PAYLOAD_SIZE);
      logPack(&sendPackage);
      updatePack(&sendPackage);
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
   //check packets to see if they have passed through this node beofore
   void updatePack(pack* payload) {

     uint32_t src = payload->src;
     uint32_t seq = payload->seq;
     pack temp;

     //if packet log isnt empty and contains the src key
    if(call PackLogs.size() == 64){
      //remove old key value pair and insert new one

      call PackLogs.popfront();
     }
     //logPack(payload);
     makePack(&temp, payload->src, payload->dest, payload->TTL, payload->protocol, payload->seq, (uint8_t*)payload->payload, sizeof(pack));
     call PackLogs.pushback(temp);
     dbg(FLOODING_CHANNEL, "UPDATING PACKET ------------------------>>>> SRC: %d SEQ: %d\n", payload->src, payload->seq);

   }

   bool hasSeen(pack* payload) {
     pack temp;
     int i;

     dbg(FLOODING_CHANNEL, "payload: %s, hash Key: %d, hashed Value : %d\n", payload->payload, payload->src, payload->seq);


     if(!call PackLogs.isEmpty()){
      for (i = 0; i < call PackLogs.size(); i++) {
        temp = call PackLogs.get(i);
       if (temp.src == payload->src && temp.seq <= payload->seq) {
         return 1;
       }
      }
    }
    return 0;
}


/*
     if(! call PackLogs.isEmpty()) {
       if(call PackLogs.contains(srcKey)) {
          if((call PackLogs.get(srcKey)) <= seq) {
            dbg(FLOODING_CHANNEL, "payload: %d, seq: %d, hashed balue : %d", payload->src, payload->seq,(call PackLogs.get(srcKey));
            return 1;
          }
        }
      }
      //otherwise we havent seen the packet before
      else return 0;
   }
   */
}
