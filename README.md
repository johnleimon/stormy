# stormy
Apple lightning protocol decoder

##Protocol Format

  * Byte framing is 12us.

  * Order is LSB first.

Bits interpreted as follows:
  
Host sends command (one hex byte, even), Device sends response which is the host command incremented by one. All other bytes are data and sometimes CRC.

![Bit Timing]
(https://github.com/evilspacepirate/stormy/raw/2a99bbb7a7155c6f9db24e1248031aea85692582/doc/bit_timing.jpg)

##Decoder Input Data Format

CSV File with first row being the time (in seconds) of the Apple Watch pin 4 transition. The second row is the state of the pin.

Example Capture:

    # Time[s], Apple Watch Pin 4
    1.648912625,0
    2.898912625,1
    2.90003775,0
    2.900051625,1
    2.900056,0
    2.900062875,1
    2.900066125,0
    2.900073,1
    2.900076125,0
    2.900077875,1
    2.90008625,0
    2.90009325,1
    2.900096375,0
    2.900098125,1
    2.9001065,0
    2.90010825,1
    2.900116625,0
    2.900118375,1
    2.90012675,0
    2.90013375,1
    2.900149375,0
    2.900156375,1
    2.9001595,0
    2.9001665,1
    2.900169625,0
    2.900176625,1
    2.90017975,0

./stormy -v capture.csv

    +delta:  1648912.624999866239 us 0
    +delta:  1250000.000000000000 us 1
    +delta:     1125.124999816762 us 0 [NewSequence]
    +delta:       13.875000149710 us 1
    +delta:        4.375000571599 us 0
    +delta:        6.874999598949 us 1 ... 0
    +delta:        3.250000190747 us 0
    +delta:        6.874999598949 us 1 ... 0
    +delta:        3.125000148430 us 0
    +delta:        1.749999682943 us 1 ... 1
    +delta:        8.375000106753 us 0
    +delta:        7.000000550761 us 1 ... 0
    +delta:        3.125000148430 us 0
    +delta:        1.749999682943 us 1 ... 1
    +delta:        8.375000106753 us 0
    +delta:        1.749999682943 us 1 ... 1
    +delta:        8.375000106753 us 0
    +delta:        1.749999682943 us 1 ... 1
    +delta:        8.375000106753 us 0
    +delta:        7.000000550761 us 1 ... 0 [Byte: 74]
    +delta:       15.624999832653 us 0
    +delta:        6.999999641266 us 1 ... 0
    +delta:        3.125000148430 us 0
    +delta:        6.999999641266 us 1 ... 0
    +delta:        3.125000148430 us 0
    +delta:        7.000000550761 us 1 ... 0
    +delta:        3.124999238935 us 0
