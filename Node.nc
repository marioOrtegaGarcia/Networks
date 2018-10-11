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
//#include "includes/DVRTable.h"
//  Tried using this am types header to add a flood address but not sure if it didn't work cause it wasn't compiling due code errors
//#include "includes/am_types.h"

module Node {

        //  Wiring from .nc File
        uses interface Boot;

        uses interface SplitControl as AMControl;
        uses interface Receive;

        uses interface SimpleSend as Sender;

        uses interface CommandHandler;

        uses interface List <pack> as PackLogs;

        uses interface List <uint16_t> as NeighborList;

        uses interface Random as Random;

        uses interface Timer<TMilli> as Timer;

        uses interface Timer<TMilli> as TableUpdateTimer;

        //uses interface DVRTableC <uint8_t> as Table;
}

implementation {

        pack sendPackage;
        uint16_t nodeSeq = 0;
        uint8_t MAX_HOP = 18;
        bool fired = FALSE;
        bool initialized = FALSE;
        uint8_t numroutes = 0;


        typedef struct DVRtouple {
           uint8_t dest;
           uint8_t cost;
           uint8_t nextHop;
        } DVRtouple;
        /*
        typedef struct DVRTable {
                DVRtouple* table[19];
        } DVRTable;
        */
        //DVRTable* DVTable;
        uint8_t routing[255][2];
        //DVRTable table;

        //  Here we can lis all the neighbors for this mote
        //  We getting an error with neighbors

        //  Prototypes
        void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
        void logPacket(pack* payload);
        bool hasSeen(pack* payload);
        void addNeighbor(uint8_t Neighbor);
        void relayToNeighbors(pack* recievedMsg);
        bool destIsNeighbor(pack* recievedMsg);
        void scanNeighbors();
        void clearNeighbors();
        //DV Table Functions
        void initialize();
        void insert(uint8_t dest, uint8_t cost, uint8_t nextHop);
        void sendTableToNeighbors();
        void sendTableTo(uint8_t dest);
        void mergeTables(uint8_t* sharedTable);

        void removeFromTable(uint8_t dest);
        void sendDVRTable();
        bool mergeRoute(uint8_t* newRoute);
        void splitHorizon(uint8_t nextHop);


        //  Node boot time calls
        event void Boot.booted(){
                uint32_t t0, dt;
                //  Booting/Starting our lowest networking layer exposed in TinyOS which is also called active messages (AM)
                call AMControl.start();

                // t0 Timer start time, dt Timer interval time
                t0 = 500 + call Random.rand32() % 1000;
                dt = 25000 + (call Random.rand32() % 10000);
                call Timer.startPeriodicAt(t0, dt);

                dbg(GENERAL_CHANNEL, "\tBooted\n");


        }

        //  This function is ran after t0 Milliseconds the node is alive, and fires every dt seconds.
        event void Timer.fired() {
                // We might wanna remove this since the timer fires fro every 25 seconds to 35 Seconds
                uint32_t t0, dt;
                //dbg(GENERAL_CHANNEL, "//////////////////////////////////////////////////////////////////////////////////////\n");
                //signal CommandHandler.printNeighbors();
                //clearNeighbors();
                scanNeighbors();

                t0 = 15000 + call Random.rand32() % 1000;
                dt = 25000 + (call Random.rand32() % 10000);
                if(!fired){
                     call TableUpdateTimer.startPeriodicAt(t0, dt);
                     fired = TRUE;
                }

                //signal CommandHandler.printRouteTable();

                //dbg(GENERAL_CHANNEL, "\tFired time: %d\n", call Timer.getNow());
                //dbg(GENERAL_CHANNEL, "\tTimer Fired!\n");
        }

        event void TableUpdateTimer.fired() {

             if(initialized == FALSE) {
                  initialize();
                  initialized = TRUE;
                  signal CommandHandler.printNeighbors();
                  signal CommandHandler.printRouteTable();
             } else {
                dbg (ROUTING_CHANNEL, "\tNode %d is Sharing his table with Neighbors\n", TOS_NODE_ID);
                sendTableToNeighbors();
             }


        }

        //  Make sure all the Radios are turned on
        event void AMControl.startDone(error_t err){
                if(err == SUCCESS)
                        dbg(GENERAL_CHANNEL, "\tRadio On\n");
                else
                        call AMControl.start();
        }

        event void AMControl.stopDone(error_t err){
        }

        //  Handles all the Packs we are receiving.
        event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
                pack* recievedMsg;
                bool alteredRoute = FALSE;
                recievedMsg = (pack *)payload;

                if (len == sizeof(pack)) {
                        //  Dead Packet: Timed out
                        if (recievedMsg->TTL == 0) {
                                dbg(GENERAL_CHANNEL, "\tPackage(%d,%d) Dead of old age\n", recievedMsg->src, recievedMsg->dest);
                                return msg;
                        }

                        //  Old Packet: Has been seen
                        else if (hasSeen(recievedMsg)) {
                                //dbg(GENERAL_CHANNEL, "\tPackage(%d,%d) Seen Before\n", recievedMsg->src, recievedMsg->dest);
                                return msg;
                        }

                        //  Ping to me
                        if (recievedMsg->protocol == PROTOCOL_PING && recievedMsg->dest == TOS_NODE_ID) {
                                dbg(FLOODING_CHANNEL, "\tPackage(%d,%d) -------------------------------------------------->>>>Ping: %s\n", recievedMsg->src, recievedMsg->dest,  recievedMsg->payload);
                                logPacket(&sendPackage);

                                // Sending Ping Reply
                                nodeSeq++;
                                makePack(&sendPackage, recievedMsg->dest, recievedMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, nodeSeq, (uint8_t*)recievedMsg->payload, len);
                                logPacket(&sendPackage);
                                call Sender.send(sendPackage, AM_BROADCAST_ADDR);

                                //signal CommandHandler.printNeighbors();
                                signal CommandHandler.printRouteTable();
                                return msg;
                        }

                        //  Ping Reply to me
                        else if (recievedMsg->protocol == PROTOCOL_PINGREPLY && recievedMsg->dest == TOS_NODE_ID) {
                                dbg(FLOODING_CHANNEL, "\tPackage(%d,%d) -------------------------------------------------->>>>Ping Reply: %s\n", recievedMsg->src, recievedMsg->dest, recievedMsg->payload);
                                logPacket(&sendPackage);
                                return msg;
                        }

                        //  Neighbor Discovery: Timer
                        else if (recievedMsg->protocol == PROTOCOL_PING && recievedMsg->dest == AM_BROADCAST_ADDR) {
                                //dbg(GENERAL_CHANNEL, "\tNeighbor Discovery Ping Recieved\n");
                                // Log as neighbor
                                //dbg(GENERAL_CHANNEL, "Neighbor Discovery packet SRC: %d\n", recievedMsg->src);
                                addNeighbor(recievedMsg->src);
                                logPacket(recievedMsg);
                                return msg;
                        }

                        // Receiving DV Table
                        else if(recievedMsg->dest == TOS_NODE_ID && recievedMsg->protocol == PROTOCOL_DV) {
                             //dbg(GENERAL_CHANNEL, "CALLING MERGERROUTE!!\n");
                             //signal CommandHandler.printRouteTable();
                             alteredRoute = mergeRoute((uint8_t*)recievedMsg->payload);
                             if(alteredRoute){
                                  sendTableToNeighbors();
                             }
                             return msg;
                        }

                        // Relaying Packet: Not for us
                        else if (recievedMsg->dest != TOS_NODE_ID && recievedMsg->dest != AM_BROADCAST_ADDR) {
                                //dbg(GENERAL_CHANNEL, "\tPackage(%d,%d) Relay\n", recievedMsg->src, recievedMsg->dest);

                                // Forward and logging package
                                recievedMsg->TTL--;
                                makePack(&sendPackage, recievedMsg->src, recievedMsg->dest, recievedMsg->TTL, recievedMsg->protocol, recievedMsg->seq, (uint8_t*)recievedMsg->payload, len);
                                logPacket(&sendPackage);

                                /**********FOR LATER: Reduce Spamming the network**************
                                 * Need to use node-specific neighbors for destination
                                 * rather than AM_BROADCAST_ADDR after we implement
                                 * neighbor discovery
                                 */
                                //signal CommandHandler.printNeighbors();
                                relayToNeighbors(&sendPackage);
                                return msg;
                        }

                        // If Packet get here we have not expected it and it will fail
                        dbg(GENERAL_CHANNEL, "\tUnknown Packet Type %d\n", len);
                        return msg;
                }// End of Currupt if statement

                dbg(GENERAL_CHANNEL, "\tPackage(%d,%d) Currrupted", recievedMsg->src, recievedMsg->dest);
                return msg;
        }

        //  This is how we send a Ping to one another
        event void CommandHandler.ping(uint16_t destination, uint8_t *payload) {
                nodeSeq++;

                dbg(GENERAL_CHANNEL, "\tPackage(%d,%d) Ping Sent\n", TOS_NODE_ID, destination);
                makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL+5, PROTOCOL_PING, nodeSeq, payload, PACKET_MAX_PAYLOAD_SIZE);
                logPack(&sendPackage);
                //logPacket(&sendPackage);
                call Sender.send(sendPackage, AM_BROADCAST_ADDR);
        }

        //  This are functions we are going to be implementing in the future.
        event void CommandHandler.printNeighbors() {
                int i;
                if(call NeighborList.size() !=  0) {
                     dbg(GENERAL_CHANNEL, "NeighborList Size: %d\n", call NeighborList.size());
                        for(i = 0; i < (call NeighborList.size()); i++) {
                                dbg(NEIGHBOR_CHANNEL, "%d -> %d\n", TOS_NODE_ID, call  NeighborList.get(i));
                        }
                } else {
                        dbg(NEIGHBOR_CHANNEL, "\tNeighbors List Empty\n");
                }
        }

        /*
        ██████  ██████  ██ ███    ██ ████████ ██████   ██████  ██    ██ ████████ ███████ ████████  █████  ██████  ██      ███████
        ██   ██ ██   ██ ██ ████   ██    ██    ██   ██ ██    ██ ██    ██    ██    ██         ██    ██   ██ ██   ██ ██      ██
        ██████  ██████  ██ ██ ██  ██    ██    ██████  ██    ██ ██    ██    ██    █████      ██    ███████ ██████  ██      █████
        ██      ██   ██ ██ ██  ██ ██    ██    ██   ██ ██    ██ ██    ██    ██    ██         ██    ██   ██ ██   ██ ██      ██
        ██      ██   ██ ██ ██   ████    ██    ██   ██  ██████   ██████     ██    ███████    ██    ██   ██ ██████  ███████ ███████
        */


        event void CommandHandler.printRouteTable() {
                int i;
                dbg(GENERAL_CHANNEL, "\t~~~~~~~Mote %d's Routing Table~~~~~~~\n", TOS_NODE_ID);
                dbg(GENERAL_CHANNEL, "\tDest\tCost\tNext Hop:\n");
                for (i = 0; i < 20; i++) {
                        dbg(GENERAL_CHANNEL, "\t  %d \t  %d \t    %d \n", i, routing[i][0], routing[i][1]);
                }
        }

        event void CommandHandler.printLinkState(){
        }

        event void CommandHandler.printDistanceVector(){
        }

        event void CommandHandler.setTestServer(){
        }

        event void CommandHandler.setTestClient(){
        }

        event void CommandHandler.setAppServer(){
        }

        event void CommandHandler.setAppClient(){
        }

        /*
██████   █████   ██████ ██   ██     ██   ██  █████  ███    ██ ██████  ██      ███████ ██      ██ ███    ██  ██████
██   ██ ██   ██ ██      ██  ██      ██   ██ ██   ██ ████   ██ ██   ██ ██      ██      ██      ██ ████   ██ ██
██████  ███████ ██      █████       ███████ ███████ ██ ██  ██ ██   ██ ██      █████   ██      ██ ██ ██  ██ ██   ███
██      ██   ██ ██      ██  ██      ██   ██ ██   ██ ██  ██ ██ ██   ██ ██      ██      ██      ██ ██  ██ ██ ██    ██
██      ██   ██  ██████ ██   ██     ██   ██ ██   ██ ██   ████ ██████  ███████ ███████ ███████ ██ ██   ████  ██████
*/



        void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
                Package->src = src;
                Package->dest = dest;
                Package->TTL = TTL;
                Package->seq = seq;
                Package->protocol = protocol;
                memcpy(Package->payload, payload, length);
        }

        //  Logging Packets: Knowledge of seen Packets
        void logPacket(pack* payload) {

                uint16_t src = payload->src;
                uint16_t seq = payload->seq;
                pack loggedPack;

                //if packet log isnt empty and contains the src key
                if(call PackLogs.size() == 64) {
                        //remove old key value pair and insert new one
                        call PackLogs.popfront();
                }
                //logPack(payload);
                makePack(&loggedPack, payload->src, payload->dest, payload->TTL, payload->protocol, payload->seq, (uint8_t*) payload->payload, sizeof(pack));
                call PackLogs.pushback(loggedPack);

                if (payload->protocol == PROTOCOL_PING) {
                   //dbg(FLOODING_CHANNEL, "\tPackage(%d,%d)---Ping: Updated Seen Packs List\n", payload->src, payload->dest);
                   } else if (payload->protocol == PROTOCOL_PINGREPLY) {
                   //dbg(FLOODING_CHANNEL, "\tPackage(%d,%d)~~~Ping Reply: Updated Seen Packs List\n", payload->src, payload->dest);
                   } else {

                   }
        }

        bool hasSeen(pack* packet) {
                pack stored;
                int i, size;
                size = call PackLogs.size();
                //dbg(FLOODING_CHANNEL, "\t%i Packets in the list\n", size);
                //dbg(FLOODING_CHANNEL, "\tPackage(%d,%d) S_Checking Message:%s\n", payload->src, payload->dest, payload->payload);
                if(size > 0) {
                        //dbg(FLOODING_CHANNEL, "\tPackage(%d,%d) PackLogs not Empty:%s\n", payload->src, payload->dest, payload->payload);
                        for (i = 0; i < size; i++) {
                                //dbg(FLOODING_CHANNEL, "\t%i th Packet in the list\n", i);
                                stored = call PackLogs.get(i);
                                if (stored.src == packet->src && stored.seq == packet->seq) {
                                        //dbg(FLOODING_CHANNEL, "\t%s\n", stored.payload);
                                        return 1;
                                }
                        }
                }
                return 0;
        }

        /*
███    ██ ███████ ██  ██████  ██   ██ ██████   ██████  ██████      ██████  ██ ███████  ██████  ██████  ██    ██ ███████ ██████  ██    ██
████   ██ ██      ██ ██       ██   ██ ██   ██ ██    ██ ██   ██     ██   ██ ██ ██      ██      ██    ██ ██    ██ ██      ██   ██  ██  ██
██ ██  ██ █████   ██ ██   ███ ███████ ██████  ██    ██ ██████      ██   ██ ██ ███████ ██      ██    ██ ██    ██ █████   ██████    ████
██  ██ ██ ██      ██ ██    ██ ██   ██ ██   ██ ██    ██ ██   ██     ██   ██ ██      ██ ██      ██    ██  ██  ██  ██      ██   ██    ██
██   ████ ███████ ██  ██████  ██   ██ ██████   ██████  ██   ██     ██████  ██ ███████  ██████  ██████    ████   ███████ ██   ██    ██
*/



        void addNeighbor(uint8_t Neighbor) {
             //why BUG BUG BUG maybe
                int size = call NeighborList.size();
                int i;
                bool duplicate = FALSE;
                 //see if src is logged already
                 for(i = 0; i < size; ++i){
                      if(call NeighborList.get(i) == Neighbor){
                           //we have logged this src already so return
                           duplicate = TRUE;
                      }
                 }
                if(duplicate == FALSE){
                     call NeighborList.pushback(Neighbor);
                } else {
                     //dbg(GENERAL_CHANNEL, "DUPLICATE NEIGHBOR: %d\n", Neighbor);
                     //signal CommandHandler.printNeighbors();
                }
                //dbg(GENERAL_CHANNEL, "Neighbor %d pushed\n", Neighbor);
                //dbg(NEIGHBOR_CHANNEL, "\tNeighbors Discovered: %d\n", Neighbor);

        }

        //  sends message to all known neighbors in neighbor list; if list is empty, forwards to everyone within range using AM_BROADCAST_ADDR.
        void relayToNeighbors(pack* recievedMsg) {
                if(destIsNeighbor(recievedMsg)) {
                        dbg(NEIGHBOR_CHANNEL, "\tDeliver Message to Destination\n");
                        call Sender.send(sendPackage, recievedMsg->dest);
                } else {
                        //dbg(NEIGHBOR_CHANNEL, "\tTrynna Forward To Neighbors\n");
                        call Sender.send(sendPackage, AM_BROADCAST_ADDR);
                }
        }

        bool destIsNeighbor(pack* recievedMsg) {
                int i, size;
                uint16_t loggedNeighbor;
                uint16_t destination = recievedMsg->dest;

                if(!call NeighborList.isEmpty()) {
                        size = call NeighborList.size();
                        for(i = 0; i < size; i++) {
                                loggedNeighbor = call NeighborList.get(i);
                                if( loggedNeighbor == destination)
                                        return 1;
                        }
                }
                return 0;
        }

        //  Used for neighbor discovery, sends a Ping w/ TTL of 1 to AM_BROADCAST_ADDR.
        void scanNeighbors() {
                nodeSeq++;
                makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, PROTOCOL_PING, nodeSeq, "Looking-4-Neighbors", PACKET_MAX_PAYLOAD_SIZE);
                call Sender.send(sendPackage, AM_BROADCAST_ADDR);
        }

//why packlogs and not neighborlist
        void clearNeighbors() {
                int size;
                size = call NeighborList.size();
                while (size > 1) {
                        call NeighborList.popfront();
                        size--;
                }
        }

        /*
        ██████  ██    ██     ████████  █████  ██████  ██      ███████
        ██   ██ ██    ██        ██    ██   ██ ██   ██ ██      ██
        ██   ██ ██    ██        ██    ███████ ██████  ██      █████
        ██   ██  ██  ██         ██    ██   ██ ██   ██ ██      ██
        ██████    ████          ██    ██   ██ ██████  ███████ ███████
        */



        void initialize() {
                int i, j, neighbor;
                bool contains;
                dbg(ROUTING_CHANNEL, "\tMOTE(%d) Initializing DVR Table\n");
                //signal CommandHandler.printNeighbors();
                //Setting the default values of the table
                // |     DVR Table Schema
                // | Dest | Cost | Next Hop |
                //routing[0][0] = TOS_NODE_ID;


                for(i = 1; i < 20; ++i) {
                        routing[i][0] = MAX_HOP;
                        routing[i][1] = 0;
                }

                routing[TOS_NODE_ID][0] = 0;
                routing[TOS_NODE_ID][1] = TOS_NODE_ID;

                //check neighborlist against table to see if each neighbor has been listed before
                for(j = 0; j < call NeighborList.size(); ++j) {
                     //if current list item isnt 0
                     if(call NeighborList.get(j) != 0){
                          neighbor = call NeighborList.get(j);
                          insert(neighbor, 1, neighbor);
                     }
                }
           }
             //signal CommandHandler.printNeighbors();

        void insert(uint8_t dest, uint8_t cost, uint8_t nextHop) {
                //input data to a touple
                routing[dest][0] = cost;
                routing[dest][1] = nextHop;
        }

        void sendTableToNeighbors() {
                int i;
                for (i = 0; i < call NeighborList.size(); i++)
                        sendTableTo(call NeighborList.get(i));
        }

        //void *memcpy(void *str1, const void *str2, size_t n)
        void sendTableTo(uint8_t dest) {
                uint8_t* payload;
                nodeSeq++;
                makePack(&sendPackage, TOS_NODE_ID, dest, 1, PROTOCOL_DV, nodeSeq, (uint8_t*)routing, sizeof(routing));
                call Sender.send(sendPackage, dest);
        }
        /*
        void mergeTables(uint8_t* sharedTable) {
                int i, j;

                // Using Dijkstra's Algorithm to
                for (i = 0; i < 19; i++) {
                        for (j = 0; j < 19; ++j) {
                                // Dest are same and our Distance is larger
                                if ((*(sharedTable + (i * 3 + 1)) + 1) < routing[j][1] && *(sharedTable + (i * 3)) == routing[j][0]) {
                                        // Update Cost and Next Hop
                                        routing[j][1] = *(sharedTable + (i * 3 + 1)) + 1;
                                        routing[j][2] = *(sharedTable + (i * 3 + 2));
                                }
                        }
                }


        }
        */
        void removeFromTable(uint8_t dest){
             initialize();
             /*
             int i;
             //DVRTable* temp = DVTable;

                for(i = 0; i < 19; i++) {


                        if(temp->table[i]->dest  == dest) {
                                temp->table[i]->dest = 0;
                                temp->table[i]->cost = MAX_HOP;
                                temp->table[i]->nextHop = 0;
                        }
                        */
                }

        //void *memcpy(void *str1, const void *str2, size_t n)
        /*void sendDVRTable() {
                uint8_t* payload; int i;
                //memcpy(payload, routes[TOS_NODE_ID], sizeof(routes));
                dbg(ROUTING_CHANNEL, "");
                for(i = 0; i < call NeighborList.size(); ++i){
                        //dbg(GENERAL_CHANNEL,"TRYING TO sendDVRTable: MAKING DV PACK\n");
                        nodeSeq++;
                        makePack(&sendPackage, TOS_NODE_ID, call NeighborList.get(i), 1, PROTOCOL_DV, nodeSeq, (uint8_t*)routing, sizeof(routing));
                        call Sender.send(sendPackage, sendPackage.dest);
                        //dbg(GENERAL_CHANNEL,"sendDVRTable:FINISHED DV PACK\n");
                }

                void* payload;
                int i;

                payload = malloc(sizeof(DVTable));
                        dbg(GENERAL_CHANNEL,"TRYING TO sendDVRTable: MEMCPY\n");
                        dbg(GENERAL_CHANNEL,"TRYING TO sendDVRTable: Size of Table is %d\n", sizeof(DVTable));
                memcpy(&payload, &DVTable, sizeof(DVTable));
                        dbg(GENERAL_CHANNEL,"TRYING TO Loop through sendDVRTable: NeighborList\n");
                for(i = 0; i < call NeighborList.size(); ++i) {
                                dbg(GENERAL_CHANNEL,"TRYING TO sendDVRTable: MAKING DV PACK\n");
                                dbg(GENERAL_CHANNEL, "TRYING TO sendDVRTable: sending to Neighbor %d \n", call NeighborList.get(i));
                        nodeSeq++;
                        makePack(&sendPackage, TOS_NODE_ID, call NeighborList.get(i), 1, PROTOCOL_DV, nodeSeq, DVTable, (uint8_t) sizeof(DVTable));

                        sendPackage.src = TOS_NODE_ID;
                        sendPackage.dest = call NeighborList.get(i);
                        sendPackage.TTL = 1;
                        sendPackage.seq = nodeSeq;
                        sendPackage.protocol = PROTOCOL_DV;
                        memcpy(sendPackage.payload, DVTable, sizeof(DVRTable));
                                //dbg(GENERAL_CHANNEL,"sendDVRTable:FINISHED DV PACK\n");
                        //call Sender.send(sendPackage, sendPackage.dest);
        }*/

        //function provided in book
        bool mergeRoute(uint8_t *newRoute){
                     int i;
                     bool alteredRoute = FALSE;
                     //iterate over table
                     for(i = 0; i < 20; ++i){
                             dbg(ROUTING_CHANNEL, "Checking for Node: %d\n", i);
                              //compare cost of newRoute to cost of current route
                              //TODO this portion almost works but check the output and see what you can figure out
                               if(*(newRoute + (i * 2)) + 1 <= routing[i][0]){
                                    //better route
                                    //dbg(GENERAL_CHANNEL, "Found better route\n");
                                    //update cost
                                    routing[i][0] = *(newRoute + (i * 2)) + 1;
                                    //update nextHop
                                    routing[i][1] = *(newRoute + (i * 2 + 1));
                                    alteredRoute = TRUE;

                               } //  TODO fix this portion of the code cuz its breaking things somehow but im not really sure how
                               else if(*(newRoute + (i * 2)) == routing[i][0] && i != TOS_NODE_ID){
                                    //path cost may have increased
                                    //update cost
                                    routing[i][0] = *(newRoute + (i * 2)) + 1;
                                    //update nextHop
                                    routing[i][1] = *(newRoute + (i * 2 + 1));
                                    alteredRoute = TRUE;
                               }
                               else {
                                    //dbg(GENERAL_CHANNEL, "Route is irrelevant\n");
                                    //route is irrelevant
                               }
                     }
                     signal CommandHandler.printRouteTable();
                     return alteredRoute;
        }

        void splitHorizon(uint8_t nextHop){
             int i;
             for(i = 1; i < 20; ++i){
                  if(nextHop == routing[i][1]){
                      routing[i][0] = MAX_HOP;
                      return;
                  }
             }
        }
}
