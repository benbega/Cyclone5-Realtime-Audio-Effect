# Realtime Audio Effect on an FPGA
This repository contains code, project files, and documentation for a realtime audio effect implemented on a [Terrasic DE10-Nano FPGA devkit](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=167&No=1046&PartNo=1#contents) using a [SensorLogic Audio Mini addon](https://www.sensorlogic.store/collections/audiologic-speech-and-audio-modules/products/fe-audio-edu-1). The project was done for the EELE 468 - *SoC FPGAs II: Application Specific Computing* class at Montana State University. The course was taken during the second (and final) semester of my senior year.

## Chosen Effect

The effect I implemented for this project was  a [feedforward comb filter](https://en.wikipedia.org/wiki/Comb_filter#Feedforward_form). 

# Hardware Implementation

To implement the feedforward comb filter, a Simulink model was used to generate VHDL code that was then compiled in Quartus. Using the VHDL code, a wrapper was written to convert the audio signals to the correct formats for the SensorLogic Audio Mini board. This wrapper was then used to make a Platform Designer hardware component. Platform Designer subsystems were made for the AD1939 and TPA3116 ICs to drive the input and output signals. These systems were all connected in Platform Designer, and compiled within a project that supported audio passthrough on the Audio Mini. New effects can be implemented with the current system by adding generated VHDL and building a Platform Designer component for the needed signals, the same process as was used for the comb filter. 

## FPGA Setup Basics

Using WSL, an Ubuntu image was compiled for ARM, then the zImage file was copied to the SD card for the FPGA. A U-Boot script was written to automatically load a device tree file, and an .rbf programming file on the SD card, to program the FPGA fabric immediately upon boot. In order to load driver module files into the FPGA's /lib/modules directory, the FPGA was connected to a PC via ethernet and scp was used from a Windows Powershell window. 

## Device Tree Setup

In order to implement character and device drivers for the newly created hardware component, a device tree node was added with the memory address of the comb filter component, 0xff200010 in the case of this project. The device tree node uses my last name, `bega` as the compatibility string for the drivers.

## Drivers

In order to control the filter using a command line argument, a driver was written to read and write values to the 4 registers in the comb filter hardware component. Currently, the driver supports turning the filter on and off, as well as adjusting the length of the delay within the filter. In order to use the driver module, it is inserted using `insmod`, and then values are written in the command line indicating which register should be written to or read from.

## Using The System

In order to use the system described above, the FGPA with attached Audio Mini board should be connected to a PC using two USB cables and an ethernet cable. An input audio signal and output audio device should be connected to the proper 3.5mm ports on the Audio Mini board. A PuTTY window can the be opened and set to communicate with the FPGA, which should be powered on after the PuTTY instance is running. After the FPGA boots, the user can navigate to /lib/modules, and then run the command `insmod comb-filter.ko`. This will start the comb filter. Running `rmmod` will remove the driver module.

# Overall

This project was a significant undertaking and is something I am very proud of. Although my initial plan was to implement a digital pop filter on the FPGA, I am still happy with the results that I got with the comb filter model. The driver code is less complete than I would like, due to time constraints with the class, but the basic functionality is still present and can be easily modified in the future. 

Looking forward, this project is something I would like to continue building, especially if I get the opportunity to implement a pop filter, as I think that is a project that has benefits which can be used in a wide variety of situations. With a now expiring Mathworks license, Im not sure when the next opportunity to continue this project will come. 