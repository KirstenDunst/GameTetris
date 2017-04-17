//
//  main.c
//  Tetris
//
//  Created by CSX on 2017/4/11.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#include<stdio.h>
#include<stdlib.h>
#include<time.h>

#include <termios.h>
#include <unistd.h>
#include <fcntl.h>
//百度找的kbhit
int kbhit(void)
{
    struct termios oldt, newt;
    int ch;
    int oldf;
    
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);
    
    ch = getchar();
    
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    fcntl(STDIN_FILENO, F_SETFL, oldf);
    
    if(ch != EOF)
    {
        ungetc(ch, stdin);
        return 1;
    }
    
    return 0;
}

static int ti=200000;
static int over=0;
static int grade=0;
static int d[4];
static int sj1=0; sj2=0;
static int b[4];
static int c=5;
static int cg=0;

int *differ(int n1,int n2);
int *stop(int *a);
int del(int *m,int cg);
int *draw();
void move_();

char delay(int i)
{
    char ch='s';
    while(i--)
    {
        if(kbhit())
        {
            ch=getchar();
            return ch;
        }
    }
    return ch;
}

char all[3*1200];

void display(int *a)
{
    int i=0,j,k;
    char *c1="★◎★◎★★◎★★◎★◎◎⊙";//1
    char *c3="■";//12
    int len = strlen(c3);
    char *c2="⊙◎★◎★◎★◎◎★◎◎★  \n";//1
    if (2 == len) {
        *c2="⊙◎★◎★◎★◎◎★◎◎★ \n";//1
    }
    
    char *c4="□";
    //char *all=(char *)malloc(sizeof(char)*1920);
    //*********char *all=(char *)malloc(sizeof(c3)*1200);
    for(i=0;i<24;i++)//修改后的方法，只用一个printf以节约时间，有闪烁
    {
        for(j=0;j<14 * len + 1;j++)//一个符号两个字节
            *(all+i*40*len+j)=*(c1+j);
        
        for(j=0;j<12;j++)
        {
            if(a[14*i+j+1]==2){//找到对应数组的位置，14个单位
                memcpy(all+i*40*len+14*len+j*len, c3, len);
                
            }
            else if(a[14*i+j+1]==4){
                memcpy(all+i*40*len+14*len+j*len, c4, len);
            }
            else break;
        }
        for(j=0;j<14 * len + 2;j++){
            *(all+i*40*len+26*len+j)=*(c2+j);
        }
    }
    if(!over)
    {
        printf("%s",all);
        printf("  ********************成绩：%d    ****  k键重新开始 *****  p键结束",grade);
    }
    else
    {
        system("clear");
        for(j=0;j<9;j++)
            printf("\n");
        printf("            *************************************************\n ");
        printf("    *****************     GAME      OVER     *****************************\n");
        printf("            ************************************************* \n      ");
        printf("                          总得分:%d",grade);
    }
    
    //*********free(all);
    /*for(i=0;i<336;i++)//这个方法是最开始使用的，明显延时太高
     {
     if(*(a+i)==1)
     printf("★◎★◎★★◎★★◎★◎◎⊙");
     if(*(a+i)==3)
     printf("⊙◎★◎★◎★◎◎★◎◎★★");
     if(*(a+i)==2)
     {
     printf("■");
     }
     if(*(a+i)==4)
     {
     printf("□");
     }
     }*/
}
void move_()
{
    int *k;
    int *a;
    char ch;
    int i,kk=0,j,kk1=0;
    c=-9;
    srand((int)time(NULL));
    sj1=(int)(rand()%5);
    while(1)
    {
        ch=delay(ti);
        a=draw();
        k=stop(a);
        switch(ch)
        {
            case 'a':
            case 'A':
                if(k[0] && !over)
                {
                    c-=1;
                    a=draw();
                    system("clear");
                    display(a);
                }
                break;
            case 's':
            case 'S':
                if(k[2] && !over)
                {
                    c+=14;
                    a=draw();
                    system("clear");
                    display(a);
                }
                break;
            case 'd':
            case 'D':
                if(k[1] && !over)
                {
                    c+=1;
                    a=draw();
                    system("clear");
                    display(a);
                }
                break;
            case 'w':
            case 'W':
                if(!over)
                {
                    for(i=0;i<4;i++)
                        if(d[i]<1||d[i]>334||d[i]%14<1||d[i]%14>12)
                            kk++;
                    for(i=0;i<4;i++)
                    {
                        for(j=0;j<4;j++)
                            if(d[i]!=b[j])
                                if(a[d[i]]==4)
                                    kk1++;
                        if(kk1==4&&a[d[i]]==4)
                            kk++;
                        kk1=0;
                    }
                    if(!kk)
                        sj2=(sj2+1)%4;
                    kk=0;
                    a=draw();
                    system("clear");
                    display(a);
                }
                break;
            case 'p':
            case 'P':
                free(a);
                exit(0);
            case 'K':
            case 'k':
                ti=200000;
                over=0;
                grade=0;
                cg=0;
                c=-9;
                system("clear");
                display(a);
                break;
            default:c=c;
        }
    }
}
int *draw(int ran)
{
    static int m[264];
    int *dif,*dif2;
    int *a=(int *)malloc(sizeof(int)*336);
    int *k;
    int i,j;
    for(i=0;i<24;i++)
    {
        a[14*i]=1;
        for(j=0;j<12;j++)
        {
            a[14*i+1+j]=2;
        }
        a[14*i+13]=3;
    }
    
    dif=differ(sj1,sj2);
    for(i=0;i<4;i++)
        b[i]=dif[i];
    
    dif2=differ(sj1,(sj2+1)%4);
    for(i=0;i<4;i++)
        d[i]=dif2[i];
    
    for(i=0;i<4;i++)
    {
        if(b[i]>0)
            a[b[i]]=4;
    }
    if(cg>0)//记录=4的背景
        for(i=0;i<cg;i++)
            a[m[i]]=4;
    k=stop(a);
    
    if(!k[2])
    {
        for(i=0;i<4;i++)
        {
            m[cg]=b[i];
            cg++;
        }
        for(j=0;j<4;j++)
            cg=del(m,cg);
        for(i=0;i<cg;i++)
            if(m[i]==5)
            {
                over=1;
            }
        c=-9;
        srand((int)time(NULL));
        sj1=(int)(rand()%5);
        return a;
    }
    return a;
}
int del(int *m,int cg)
{
    int i=23,j,k=0,n1=0,n2=0,jj;
    while(i>=0)
    {
        for(j=0;j<12;j++)
            for(jj=0;jj<cg;jj++)
                if(i*14+j+1==m[jj])
                    k++;
        if(k==12)
        {
            while(n1<cg)//重新赋值m数组
            {
                if(m[n1]/14>i)
                {
                    m[n2]=m[n1];
                    n2++;
                }
                if(m[n1]/14<i)
                {
                    m[n1]+=14;
                    m[n2]=m[n1];
                    n2++;
                }
                n1++;
            }
            cg-=12;
            grade++;
            if(ti>500)
                ti-=grade*50;
            return cg;
        }
        else
            i--;
        k=0;
    }
    return cg;
}
int *differ(int n1,int n2)
{
    int m[]={0,0,0,0,n1,n2};//前4个记录图形
    int *b=m;
    if(b[4]==0)//方块
    {
        b[0]=c;
        b[1]=b[0]+1;
        b[2]=b[0]+14;
        b[3]=b[0]+15;
    }
    if(b[4]==1)//棍
    {
        if(b[5]==0||b[5]==2)
        {
            b[0]=c;
            b[1]=b[0]-1;
            b[2]=b[0]+1;
            b[3]=b[0]+2;
        }
        if(b[5]==1||b[5]==3)
        {
            b[0]=c;
            b[1]=b[0]-14;
            b[2]=b[0]+14;
            b[3]=b[0]+28;
        }
    }
    if(b[4]==2)//锥子
    {
        if(b[5]==0)
        {
            b[0]=c;
            b[1]=b[0]+13;
            b[2]=b[0]+14;
            b[3]=b[0]+15;
        }
        if(b[5]==1)
        {
            b[0]=c;
            b[1]=b[0]-14;
            b[2]=b[0]+1;
            b[3]=b[0]+14;
        }
        if(b[5]==2)
        {
            b[0]=c;
            b[1]=b[0]-1;
            b[2]=b[0]+1;
            b[3]=b[0]+14;
        }
        if(b[5]==3)
        {
            b[0]=c;
            b[1]=b[0]-14;
            b[2]=b[0]-1;
            b[3]=b[0]+14;
        }
    }
    if(b[4]==3)//L
    {
        if(b[5]==0)
        {
            b[0]=c;
            b[1]=b[0]+14;
            b[2]=b[0]+1;
            b[3]=b[0]+2;
        }
        if(b[5]==1)
        {
            b[0]=c;
            b[1]=b[0]-1;
            b[2]=b[0]+14;
            b[3]=b[0]+28;
        }
        if(b[5]==2)
        {
            b[0]=c;
            b[1]=b[0]-14;
            b[2]=b[0]-1;
            b[3]=b[0]-2;
        }
        if(b[5]==3)
        {
            b[0]=c;
            b[1]=b[0]-14;
            b[2]=b[0]-28;
            b[3]=b[0]+1;
        }
    }
    if(b[4]==4)//!L
    {
        if(b[5]==0)
        {
            b[0]=c;
            b[1]=b[0]-1;
            b[2]=b[0]-2;
            b[3]=b[0]+14;
        }
        if(b[5]==1)
        {
            b[0]=c;
            b[1]=b[0]-1;
            b[2]=b[0]-14;
            b[3]=b[0]-28;
        }
        if(b[5]==3)
        {
            b[0]=c;
            b[1]=b[0]+1;
            b[2]=b[0]+14;
            b[3]=b[0]+28;
        }
        if(b[5]==2)
        {
            b[0]=c;
            b[1]=b[0]-14;
            b[2]=b[0]+1;
            b[3]=b[0]+2;
        }
    }
    return b;
}
int *stop(int *a)//-9
{
    int duge[4]={1,1,1,1};//左右下变
    int i,j,k=0,k1=0,k2=0;
    for(j=0;j<4;j++)
        if(b[j]%14>1)
            k++;
    if(k==4)
    {
        for(i=0;i<4;i++)//判断是否是最左
        {
            for(j=0;j<4;j++)
                if(j!=i)
                    if(b[i]-1==b[j])
                        k1++;
            if(k1==0)
                if(a[b[i]-1]==4)
                    duge[0]=0;//can not move to left
            k1=0;
        }
    }
    else
        duge[0]=0;
    k=0;
    for(j=0;j<4;j++)
        if(b[j]%14<12)
            k++;
    if(k==4)
    {
        for(i=0;i<4;i++)//判断是否是最right
        {
            for(j=0;j<4;j++)
                if(j!=i)
                    if(b[i]+1==b[j])
                        k2++;
            if(k2==0)
                if(a[b[i]+1]==4)
                    duge[1]=0;//can not move to r
            k2=0;
        }
    }
    else
        duge[1]=0;
    k=0;
    for(j=0;j<4;j++)
        if(b[j]/14<23)
            k++;
    if(k==4)
    {
        for(i=0;i<4;i++)//判断是否是最d
        {
            for(j=0;j<4;j++)
                if(j!=i)
                    if(b[i]+14==b[j])
                        k2++;
            if(k2==0)
                if(a[b[i]+14]==4 || b[i]+14>336)
                    duge[2]=0;//can not move to d
            k2=0;
        }
    }
    else
        duge[2]=0;
    return &duge[0];
}
int main()
{
    system("stty -icanon");
    int i;
    for(i=0;i<4;i++)
        printf("\n");
    printf("      ⊙☆★⊙☆★⊙☆★⊙      按下任意键开始      ⊙☆★⊙☆★⊙☆★⊙☆\n");
    for(i=0;i<4;i++)
        printf("\n");
    printf("              k:重新开始  p:结束，w:变形，a：向左，s:加速，d：向右\n");
    for(i=0;i<4;i++)
        printf("\n");
    printf("      ps:刷屏时屏幕很闪，不知道怎么办");
    getchar();
    move_();
    getchar();
    return 0;
}



