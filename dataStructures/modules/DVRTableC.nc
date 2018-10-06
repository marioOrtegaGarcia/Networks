

generic module DVRTable((typedef t,int h, int n){
     provides interface DVRTable;
}

implementation{
     const uint8_t MAX_DIST = h;
     const uint8_t MAX_NODE_ID = n;

     typedef nx_struct DVRTable{
       //Array length 255, each element should directly correspond to a matching nodeid
       t nodeIDs[MAX_NODE_ID][3];
     }DVRtable;

     command void DVRTable.insert(uint8_t cost, uint8_t dist, uint8_t nextHop){

     }

     command void remove(uint8_t dest){

     }

     command void clear(){

     }


}
