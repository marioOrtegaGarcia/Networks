

generic module DVRTableC(typedef t){
     provides interface DVRTable<t>;
}

implementation{
     typedef struct DVRtouple{
        uint8_t dest;
        uint8_t dist;
        uint8_t nextHop;
     }DVRtouple;

     DVRtouple table[19];

     command void DVRTable.insert(uint8_t dest, uint8_t cost, uint8_t nextHop){
          //input data to a touple
          DVRtouple input = {dest, cost, nextHop};
     }

     command void remove(uint8_t dest){

     }

     command void clear(){

     }


}
