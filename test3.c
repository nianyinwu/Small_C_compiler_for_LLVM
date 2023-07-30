#include <stdio.h>
int  plus10(int b){
    printf("func b: %d\n",b);
    b = b +10;
	return b;
}
struct D{
	int b;
	char c;
	float f;
};
void main()
{
    int a = 10;
    while(a > 0){
        if(a%2==0)  printf("even:%d\n",a);
        else if( a > 5 ) printf("%d\n",a);
        else printf("odd:%d\n",a);
        a--;
    }

    char ch = 'A' ;
    ch = ch + '1';
    printf("%c\n",ch);

    int b = plus10(a);
    printf("%d\n", b);
     b = plus10(10);
    printf("%d\n", b);        
}
