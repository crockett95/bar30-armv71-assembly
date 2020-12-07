#include <iostream>
#include "wiringPi.h"
#include "wiringPiI2C.h"
#include "../reference/wiring-i2c.h"

#define BAR30 0x76
#define PROM_READ 0xA0

unsigned long read_sensor_value(int fd, int signal_base, int osr) {
    int delay = 640 << osr;
    wiringPiI2CWrite(fd, signal_base + osr * 2);

    delayMicroseconds(delay);

    unsigned int value = myWiringPiI2CReadReg16(fd, 0x00);
    unsigned long reordered = ((value & 0xFF) << 16) | ((value & 0xFF00)) | 0;
    

    return reordered;
}

unsigned long read_pressure(int fd, int osr = 0) {
    return read_sensor_value(fd, 0x40, osr);
}

unsigned long read_temp(int fd, int osr = 0) {
    return read_sensor_value(fd, 0x50, osr);
}


void calculate(unsigned long d1, unsigned long d2, unsigned short* c) {
    unsigned short t_ref = c[5];
    unsigned short tempsens = c[6];
    long dt = d2 - (t_ref << 8);
    long temp = 2000 + (dt * tempsens >> 23);

    long long off_t1 = c[2];
    long long tco = c[4];

    long long off = (off_t1 << 16) + (tco * dt >> 7);

    long long sens_t1 = c[1];
    long long tcs = c[3];

    long long sens = (sens_t1 << 15) + (tcs * dt >> 8);

    long long ti, offi, sensi;
    if (temp < 2000) {
        ti = 3 * ((long long) (dt * dt)) >> 33;
        long temp_adj = temp - 2000;
        offi = 3 * temp_adj * temp_adj >> 1;
        sensi = 5 * temp_adj * temp_adj >> 3;

        if (temp < -1500) {
            temp_adj = temp + 1500;
            offi = offi + 7 * temp_adj * temp_adj;
            sensi = sensi + 4 * temp_adj * temp_adj;
        }
    } else {
        long temp_adj = temp - 2000;
        ti = 2 * dt * dt >> 27;
        offi = temp_adj * temp_adj >> 4;
        sensi = 0;
    }

    long long off2 = off - offi;
    long long sens2 = sens - sensi;
    long temp2 = temp - ti;
    long p2 = ((d1 * sens2 >> 21) - off2) >> 13;

    double temp_c = temp2 / 100.0;
    double p_mbar = p2 / 10.0;

    printf("Temperature (C): %0.1f \tPressure (mbar): %0.1f\n", temp_c, p_mbar);
}

int main(int argc, char const *argv[])
{
    int fp = wiringPiI2CSetup(BAR30);
    wiringPiI2CWrite(fp, 0x1e);

    delayMicroseconds(10000);

    unsigned short c[8];

    for (int i = 0; i < 7; i++) {
        unsigned short result = myWiringPiI2CReadReg16(fp, PROM_READ + 2 * i);
        c[i] = ((result & 0xFF) << 8) | (result >> 8);
    }

    delayMicroseconds(5e6);

    int start = time(NULL);

    while (time(NULL) - start < 20) {
        delayMicroseconds(1e5);
        std::cout << "Time: " << time(NULL) << std::endl;
        unsigned long d1 = read_pressure(fp);
        unsigned long d2 = read_temp(fp);
        calculate(d1, d2, c);
    }

    return 0;
}
