#include <stdio.h> 

int main(int argc, char** argv)
{
    long long ll = (long long)argc;
    //_ftol2(1.0);
    printf("%lld\n", ll >> 1);
}
