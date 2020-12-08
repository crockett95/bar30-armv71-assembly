#include <stdio.h>
#include <time.h>
int main() {
    //char buffer[10] = {0};
    double a = time(NULL) / 2.0;
    double b = time(NULL) / 3.0;

    printf("Pi: %f\n%f", a, b);

    return 0;
}