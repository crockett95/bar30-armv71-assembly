Bar30 Implementation in ARMv71
===

This repository is an implementation to read from the [Bar30][1] underwater 
pressure and depth sensor in ARMv71 assembly language on the Raspberry Pi using
Raspberry Pi OS. The sensor communicates across I2C in 24-bit signals, which
can be problematic to use. Notably, the `ioctl` interface on the Raspberry Pi
apparently does not support I2C block reads, which limits the use of libraries
such as WiringPi.

The linux `read` and `write` utilities can be used to interact with the
`/dev/i2c-{n}` driver files. More information for using this interface is 
provided by the [Embedded Linux wiki][2]. It's important to note that for the
Bar30, a control signal must be passed via a "write" operation before attempting
to read any data from the sensor. The `read_bar30` subroutine in _sensor.s_
demonstrates this behavior.

## Sources

* [Bar30 product page][1]
* [Bar30 Python library](https://github.com/bluerobotics/ms5837-python)
* [Interfacing with I2C Devices][2]
* [MS5837-30BA Spec](https://www.te.com/commerce/DocumentDelivery/DDEController?Action=showdoc&DocId=Data+Sheet%7FMS5837-30BA%7FB1%7Fpdf%7FEnglish%7FENG_DS_MS5837-30BA_B1.pdf%7FCAT-BLPS0017)

[1]: https://bluerobotics.com/store/sensors-sonars-cameras/sensors/bar30-sensor-r1/
[2]: https://elinux.org/Interfacing_with_I2C_Devices#Reading_from_the_ADC