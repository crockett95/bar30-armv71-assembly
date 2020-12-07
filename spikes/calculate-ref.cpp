//[16385, 29120, 27671, 16804, 17332, 24636, 25998]
#include <iostream>
using std::cout; 
using std::endl;

void calculate(unsigned long d1, unsigned long d2, unsigned short* c) {
    unsigned short t_ref = c[5];
    unsigned short tempsens = c[6];
    long dt = d2 - (t_ref << 8);
    cout << "dt: " << dt << endl;
    long temp = 2000 + (dt * tempsens >> 23);
    cout << "temp: " << temp << endl;

    long long off_t1 = c[2];
    long long tco = c[4];

    long long off = (off_t1 << 16) + (tco * dt >> 7);
    cout << "off: " << off << endl;

    long long sens_t1 = c[1];
    long long tcs = c[3];

    long long sens = (sens_t1 << 15) + (tcs * dt >> 8);
    cout << "sens: " << sens << endl;

    // long long ti, offi, sensi;
    // if (temp < 2000) {
    //     ti = 3 * ((long long) (dt * dt)) >> 33;
    //     long temp_adj = temp - 2000;
    //     offi = 3 * temp_adj * temp_adj >> 1;
    //     sensi = 5 * temp_adj * temp_adj >> 3;

    //     if (temp < -1500) {
    //         temp_adj = temp + 1500;
    //         offi = offi + 7 * temp_adj * temp_adj;
    //         sensi = sensi + 4 * temp_adj * temp_adj;
    //     }
    // } 
    // else {
    //     long temp_adj = temp - 2000;
    //     ti = 2 * dt * dt >> 27;
    //     offi = temp_adj * temp_adj >> 4;
    //     sensi = 0;
    // }

    // long long off2 = off - offi;
    // long long sens2 = sens - sensi;
    // long temp2 = temp - ti;
    long p2 = ((d1 * sens >> 21) - off) >> 13;
    cout << "p: " << p2 << endl;

    double temp_c = temp / 100.0;
    double p_mbar = p2 / 10.0;

    cout << "temperature (C): " << temp_c << endl;
    cout << "pressure (mbar): " << p_mbar << endl;
}

int main(int argc, char const *argv[])
{
    unsigned short c[8] = {16385, 29120, 27671, 16804, 17332, 24636, 25998};
    unsigned long d1 = 4164796;
    unsigned long d2 = 6353756;

    calculate(d1, d2, c);
    return 0;
}
