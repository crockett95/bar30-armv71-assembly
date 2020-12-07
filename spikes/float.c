#include <stdio.h>
#include <time.h>
int main() {
    //char buffer[10] = {0};
    double a = time(NULL) / 2.0;
    // float b = time(NULL) / 2.0;

    printf("Pi: %f\n", a);

    return 0;
}