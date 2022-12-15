# PDP2011 port to MiSTer FPGA
## PDP2011 Overview
 This is a MiSTer port of [PDP2011](https://pdp2011.sytse.net) – a re-creation of the well known series of PDP-11 computer systems in VHDL. Everything that is needed to run a PDP-11 system is included; you can run a complete Unibus PDP-11 system with console, disks and other peripherals on a simple low cost FPGA development board. The original V5-V7 versions of Unix, BSD 2.11, and the original DEC operating systems for the PDP-11 work.

## Highlights:

  *  You can configure PDP2011 to be 11/03, 11/20, 11/24, 11/34, 11/44, 11/45, 11/70 or 11/94. This also sets up 18- or 22-bit memory management, special instructions like MARK and MTPS/MFPS, EIS instructions, and FIS or FPU. The model specific instructions and the most important differences between the system models are implemented to the point that many of the original MAINDEC test programs run without error.
  
  *  There are disk controllers for RK, RL and RM/RP disks; these use SD cards to store the disk image on.
    The system can be hooked up to a network; it includes a DEUNA compatible Ethernet frontend that works with the ENC424J600 Ethernet chip (as on  Digilent’s PMODNIC100); you can run DECNET on RSTS and RSX, or TCP/IP on 2.11BSD.
    
  * The PDP2011 project includes a terminal core to interface to a VGA screen and PS2 keyboard.  You can configure the terminal to be a vt100 or a vt105.
  
  * Mister UART port can be used as console (swapping it on OSD), additional terminal, Modem, SLIP networking (**needs MisTER kernel change**),links to other systems etc.
    The most recent addition is the MINC laboratory system – several peripheral modules for A/D, D/A, timing, and digital input and output can be configured. And with the vt105 terminal you can display the MINC waveform graphics.

## Known problems and limitations.

 * The RH controller for the RP/RM disks only support 1 disk drive.
 * The original RL distribution disk for RT-11 V5 crashes on boot. Everything works if you copy the distribution to RK though, and earlier versions work fine as well.
 
## Future plans:
 *   Wireless network! an alternative for the current DEUNA+PMODNIC100 that works wirelessly.
 *   ESP32 software emulation running on ARM (if you dont want to hook an ethernet to SNAC port)
 *   Hardware to support the PiDP11 clonsole (Via SNAC port).
 
## License:

The copyrights to the VHDL described on this core are held by **Sytse Van Slooten**. In short, you are allowed to run the core for personal use, but you can not use it commercially.

## Disk images

  * You can download a disk image containing **BSD2.11** form the [original core download page](https://pdp2011.sytse.net/wordpress/download/).
  * Tested with a lot of images from the PiDP-11 project. For convenience, i have converted and renamed for easy use  the nankervis images and have uploaded them to mega. [You can get them here](https://mega.nz/folder/e0RTUbgJ#5YeohR7yLmCTc3MZBHJ8mg). All this images need a PDP11/70.
  
## Networking

  Networking at the moment is a bit tricky, and in all cases you have to do some hacking with hardware or firmware. You have two options here.
  
  * SLIP. You ned to change some files on the mister SD CARD. ([have a look here](https://misterfpga.org/viewtopic.php?p=59505#p59505)),  
  * Ethernet. I dont know if is possible to attach the network to the MiSTer ethernet. So at the moment, the only way to connect an ethernet to the core is via the SNAC connector (this "fake" USB blue connector on your IOBoard or DB9 connector on the [Antonio Villena](https://www.antoniovillena.es/store/) boards).
  * Two boards have been tested:
    * [Digilent PMOD nic](https://digilent.com/reference/pmod/pmodnic100/start). This board is not available from the vendor.... But may be you have one on the cupboard)
    * [Olimex MOD-ENC624J600](https://www.olimex.com/Products/Modules/Ethernet/MOD-ENC624J600)
    
The actual wiring is:
    
PIN             | Signal
----------------|--------
USER_IO[0]      | MOSI
USER_IO[1]      | MISO
USER_IO[6]      | SCLK
USER_IO[3]      | CS
5V              | 3v3 (I think the ethernet is 5V tolerant, but better to lower a bit
GND             | GND
   
      
