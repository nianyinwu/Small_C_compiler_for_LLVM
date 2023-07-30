int f=1;
struct st{
  int a;
  char b;
  int c;
  float d;
  double e;

};
void main(){

    long int p = 123465;
    long long int pp = p + p;
    short int gj = 213;
    short int b = gj - p;
    float fk = -0.5;
    fk ++;
    f = f +2;
    double dol = fk;
    dol++;
    char ti = 'A';
    ti--;
    printf("%ld %lld\n",p,pp);
    printf("%d %d\n",gj,b);
    printf("%d\n",f);
    printf("%f %f\n",fk,dol);
    printf("%c %c\n",ti, ti-'.');  
}
