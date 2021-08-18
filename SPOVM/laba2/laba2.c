#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <string.h>

ssize_t readlink(const char* restrict pathname, char *restrict buf,size_t bufsize);
void printLink(char*,char[]);
char* makePath(char*,char[]);
char* search(char*,int*);
void check(int,char**,int*);

int main(int argc,char *argv[])
{
    int flags[4]={0,0,0,1};
    char* path;
    if(argc==1)
    {
        path=(char*)malloc(sizeof(char)*2);
        path[0]='.';
        path[1]='\0';
        flags[0]=1;
        flags[1]=1;
        flags[2]=1;
    }
    else if(argc==2)
    {
        if(argv[1][0]!='-')
        {
            path=(char*)malloc(sizeof(char)*(1+strlen(argv[1])));
            strcpy(path,argv[1]);
            flags[0]=1;
            flags[1]=1;
            flags[2]=1;
        }
        else
        {
            path=(char*)malloc(sizeof(char)*2);
            path[0]='.';
            path[1]='\0';
            check(argc,argv,flags);
            if(flags[3]>=(flags[0]+flags[1]+flags[2]))
                flags[3]=0;
        }
    }
    else
    {
        if(argv[1][0]!='-')
        {
            path=(char*)malloc(sizeof(char)*(1+strlen(argv[1])));
            strcpy(path,argv[1]);
        }
        else
        {
            path=(char*)malloc(sizeof(char)*2);
            path[0]='.';
            path[1]='\0';
        }
        check(argc,argv,flags);
        if(flags[3]>=(flags[0]+flags[1]+flags[2]))
            flags[3]=0;
    }
    search(path,flags);
    return(0);
}

void check(int argc,char* argv[],int flags[]) //checking for options input
{
    for(int i=1;i<argc;i++)
    {
        if(argv[i][0]!='-') // if no - symbol then we'll show every file
            continue;
        int length=strlen(argv[i]);;
        for(int j=0;j<length;j++)
        {
            if(argv[i][j]=='f')
                flags[0]=1;
            if(argv[i][j]=='d')
                flags[1]=1;
            if(argv[i][j]=='l')
                flags[2]=1;
        }
    }
}

char* search(char* path,int flags[])
{
    DIR *dir;
    int cLength;
    cLength=strlen(path)+1;
    if((dir=opendir(path))!=NULL)
    {
        struct dirent *entry;
        while((entry = readdir(dir)) != NULL)
        {
            if(strcmp("..",entry->d_name)!=0 && strcmp(".",entry->d_name)!=0)
            {
                if(entry->d_type==4)
                {
                    path=makePath(path,entry->d_name);
                    if(flags[1])
                    {
                        if(flags[3])
                            printf("d ");
                        printf("%s\n",path);
                    }
                    path=search(path,flags);
                    path=(char*)realloc(path,sizeof(char )*cLength);
                    path[cLength-1]='\0';
                }
            }

            else
            {
                if(entry->d_type==10)
                {
                    if(flags[2])
                    {
                        if(flags[3])
                        {
                            printf("l ");
                        }
                        printf("%s/%s -> ",path,entry->d_name);
                        printLink(path,entry->d_name);
                    }
                }
                else
                {
                    if(flags[0])
                    {
                        printf("%s/",path);
                        printf("%s\n",entry->d_name);
                    }
                }
            }
        }
    }
    closedir(dir);
    return path;
}

char* makePath(char* path,char filename[])
{
    int mem = strlen(path);
    int size=2+strlen(filename)+strlen(path);
    path=(char*)realloc(path,sizeof(char)*size);
    path[mem]='/';
    for(int i=mem+1,j=0;i<size-1;i++,j++)
        path[i]=filename[j];
    path[size-1]='\0';
    return path;
}

void printLink(char* path,char linkName[])
{
    int len;
    struct stat mem;
    char* linkPath=(char*)malloc(sizeof(char)*2);
    linkPath[0]='.';
    linkPath[1]='\0';
    makePath(linkPath,path);
    makePath(linkPath,linkName);
    stat(linkPath,&mem);
    char* linkContent;
    linkContent=(char*)malloc(sizeof(char)*(1+mem.st_size));
    len=readlink(linkPath,linkContent,mem.st_size);
    linkContent[len]='\0';
    printf("%s\n",linkContent);
}
