#!/bin/bash
as -g calculate.s -o calculate.o
as -g sensor.s -o sensor.o
as -g main.s -o main.o
gcc main.o calculate.o sensor.o -o bar30 -lwiringPi