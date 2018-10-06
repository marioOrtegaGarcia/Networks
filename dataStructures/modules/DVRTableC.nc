

generic module DVRTableC(typedef t){
     provides interface DVRTable<t>;
}

implementation{

     uint8_t MAX_HOP = 18;

     typedef struct DVRtouple{
        uint8_t dest;
        uint8_t cost;
        uint8_t nextHop;
     }DVRtouple;

     DVRtouple table[19];

     command void DVRTable.initialize(){
          int i = 0;
          for(i = 0; i < 19; i++){
                  table[i].dest         = NULL;
                  table[i].cost         = MAX_HOP;
                  table[i].nextHop      = NULL;
          }
     }

     command void DVRTable.insert(uint8_t dest, uint8_t cost, uint8_t nextHop){
          //input data to a touple
          DVRtouple input = {dest, cost, nextHop};
     }

     command void remove(uint8_t dest){
          int i = 0;
             for(i = 0, i < 19, i++) {
                     if(table[i].dest  == dest) {
                             table[i].dest = NULL;
                             table[i].cost = MAX_HOP;
                             table[i].nextHop = NULL;

                     }
             }
     }

     command void clear(){
             int i = 0;
             DVRtouple temp = {NULL, MAX_HOP, NULL};
             for(i = 0; i < 19; i++)
                     table[i] = temp;
     }


}
