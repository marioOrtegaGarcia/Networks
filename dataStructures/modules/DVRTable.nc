

generic module DVRTable(){
     provides interface DVRTable;
}

implementation{
     const MAX_NODE_ID = 255;
     const MAX_VAL = 16;

     typedef nx_struct DVRTable{
       //Array length 255, each element should directly correspond to a matching nodeid
       nx_uint8_t nodeIDs[MAX_NODE_ID][3];
     }DVRtable;

     
}
