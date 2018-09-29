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
#include "includes/am_types.h"

module Node{

    //  Wiring from .nc File
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses interface List <pack> as PackLogs;

   uses interface List <uint32_t> as NeighborList;

   uses interface Random as Random;

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

   pack sendPackage;
   uint16_t nodeSeq = 0;

   //  Here we can lis all the neighbors for this mote
  // We getting an error with neighbors

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   void updatePack(pack* payload);
   bool hasSeen(pack* payload);
   void addNeighbor();

   event void Boot.booted(){
     //  Booting/Starting our lowest networking layer exposed in TinyOS which is also called active messages (AM)
     uint32_t t0, dt;

      call AMControl.start();
      t0 = call Random.rand32() % 2500;
      dt = 20000 + (call Random.rand32() % 10000);

      call Timer.startPeriodicAt(t0, dt);
      //start timer
      //  We need to initiate the node Timer first
      //call NodeTimerC.startOneShot(1000);
      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void Timer.fired() {
     uint8_t* tempPayload = NULL;
     //ping protocol for neighbor
     //makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, PROTOCOL_PING, recievedMsg->seq, call Sender.send(sendPackage, AM_BROADCAST_ADDR);
     makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, PROTOCOL_PING, ++nodeSeq, tempPayload, PACKET_MAX_PAYLOAD_SIZE);
     //send new neighbor discovery ping
     call Sender.send(sendPackage, AM_FLOODING);

     }//Were using run timer sice this function is fired over a hundread times

   //  This function makes sure all the Radios are turned on
   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){
   }

   //  type message_t contains our AM pack
   //  We need to send to everyone, and just check with this function if it's meant for us.
   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {

     pack* recievedMsg;
     int size;
     /* , index; */
     bool foundMatch;

     recievedMsg = (pack *)payload;
     if (len == sizeof(pack)) {
         // Saving Payload
         /* recievedMsg = (pack *)payload; */
         logPack(recievedMsg);

         // Dead Packet: Timed out
         if (recievedMsg->TTL == 0) {
           dbg(GENERAL_CHANNEL, "Package(%d,%d) Dead of old age\n", recievedMsg->src, recievedMsg->seq);
           return msg;
         }

         // Old Packet: Has been seen
         if (hasSeen(recivevedMsg)) {
           dbg(GENERAL_CHANNEL, "Package(%d,%d) Seen\n", recievedMsg->src, recievedMsg->seq);
           return msg;
         }

         // Relaying Packet: Not for us
         if (recievedMsg->dest != TOS_NODE_ID ||
             recievedMsg->dest != AM_BROADCAST_ADDR) {
           dbg(GENERAL_CHANNEL, " Package(%d,%d) Relay\n", recievedMsg->src);

           // Forward and logging package
           recievedMsg->TTL--;
           makePack(&sendPackage, recievedMsg->src, recievedMsg->dest, recievedMsg->TTL, recievedMsg->protocol, recievedMsg->seq, (uint8_t*)recievedMsg->payload, len);
           updatePack(&sendPackage);
           call Sender.send(sendPackage, AM_BROADCAST_ADDR);
           return msg;
         }

         // Ping to me
         if (recievedMsg->protocol == PROTOCOL_PING && recievedMsg->dest == TOS_NODE_ID) {
           dbg(FLOODING_CHANNEL, "Package(%d,%d) Ping: %s\n", recievedMsg->src, recievedMsg->dest,  recievedMsg->payload);
           updatePack(&sendPackage);

           // Sending Ping Reply
           nodeSeq++;
           makePack(&sendPackage, recievedMsg->dest, recievedMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, nodeSeq, (uint8_t*)recievedMsg->payload, len);
           updatePack(&sendPackage);
           call Sender.send(sendPackage, AM_BROADCAST_ADDR);
           return msg;
         }

         // Ping Reply to me
         if (recievedMsg->protocol == PROTOCOL_PINGREPLY && recievedMsg->dest == TOS_NODE_ID) {
           dbg(FLOODING_CHANNEL, "Package(%d,%d) Ping Reply\n");
           updatePack(&sendPackage);
           return msg;
         }

         // Neighbor Discovery: Timer
         if (recievedMsg->protocol == PROTOCOL_PING && recievedMsg->dest == AM_FLOODING && recievedMsg->TTL == 1) {
           updatePack(recievedMsg);
           addNeighbor();
           // Log as neighbor
           return msg;
         }

         dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
         return msg;
         }// End of Currupt if statement

         dbg(GENERAL_CHANNEL, "Package(%d,%d) Currrupted", recievedMsg->src, recievedMsg->dest);
         return msg;
       }

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
   event void CommandHandler.printNeighbors(){
     //give me neigbors of 2
     for(index = 0; index < (call NeighborList.size()); index++) {
       dbg(NEIGHBOR_CHANNEL, "%d -> %d\n", TOS_NODE_ID, call NeighborList.get((int)index));
     }
   }

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

     dbg(FLOODING_CHANNEL, "payload: %s, Src: %d, Seq: %d\n", payload->payload, payload->src, payload->seq);


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

  void addNeighbor() {

  size = call NeighborList.size();
  foundMatch = 0;

  for (index = 0; index < size ; index++) {
    if(call NeighborList.get(index) == recievedMsg->src)
      foundMatch = 1;
  }

  if (!foundMatch) {
    call NeighborList.pushback(recievedMsg->src);
    dbg(NEIGHBOR_CHANNEL, "Neighbors Discovered: %d\n", call NeighborList.get(index) );
  }
  }

}
