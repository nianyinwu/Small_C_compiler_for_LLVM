void main(){
    int a;
    int b = 3;
    a = 5;
    a = a&b;
    a=b+2*(100-1);
    printf("%d\n",a);
	scanf("%d", &a);
    while(a < 100){
        printf("%d\n",a);
        for(int i = 10 ; i >0 ;i--)
            for(int j = 0; j <5; j = j+1)
                printf("%d %d\n",i,j);
        a=a+20;
    }
   printf("Hello World\n");
}
