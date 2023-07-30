void main()
{
   float a = 15;
   double b = a+a;
   int i = 5;
   if( a > b){
      if ( a == 15 ){
          a = a*2;
         printf("%f\n",a);
      }
      else{ 
         printf("%f\n",a);
      }
      printf("a Greater than b\n");
   }
   else if ( a == b){
      if ( a == 15 ){ 
          a = a*2;
         printf("%f\n",a);
      }
      else{ 
         a = a/2;
         printf("%f\n",a);
      }
      printf("a Equal b\n");
   }
   else{
      if ( a == 15 ){
         a = a*2;
         printf("%f\n",a);
      }
      else{ 
         a = a/2;
         printf("%f\n",a);
      }
      printf("a Less than b\n");
   }
}
