https://forums.virtualbox.org/viewtopic.php?t=108745


VirtualBox slow on Alder Lake CPU and Win 11
Post by kabu » 1. Mar 2023, 02:04

Intel 12th gen Alder Lake CPU comes with new big.LITTLE architecture with performance P-cores and efficient E-cores. And Windows 11 Thread Director now decides on which of these cpus should process/thread be scheduled. Foreground processes are schedulled on P-cores, background processes and minimized windows on E-cores. And this causes problems with VirtualBox performance.

When I start machine normally, VM performance is good. But when VM window is minimized, windows no longer schedules VM on P-cores, but on E-cores. The same happens when you start VM headless, it is background task for windows and schedules it on E-cores.
Performance on E-cores is very bad, much times slower than on P-cores. Test machines with RAC were unusable in my case.

You can check to which cores is VM scheduled in windows task manager, show logical cpus insted of summary and run some cpu intensive task in VM for test, like:
openssl speed -evp aes-128-xts
First listed cores are P-cores, last are E-cores.

Searching similar problems I found that this is generic problem with Windows 11 on Alder Lake CPU, this is how it was designed.
It seems that there could be few workarounds:
- run VirtualBox with Admin rights - I have not tested it, I do now want to run VBox with higher privileges
- set Windows 11 power mode to "Best Performance" from "Balanced" - but that would affect all applications and laptop power consumption
- disable E-cores in bios, if such setting is available - also not adviced
- disable power throttling just for Virtualbox processes

I choosed last workaround, disabled power throttling.
From Terminal (Admin) shell (opened with Win+X):

powercfg /powerthrottling disable /path "C:\Program Files\Oracle\VirtualBox\VBoxHeadless.exe"
powercfg /powerthrottling disable /path "C:\Program Files\Oracle\VirtualBox\VirtualBoxVM.exe"
powercfg /powerthrottling list

Battery Usage Settings By App
=============================

Application: C:\Program Files\Oracle\VirtualBox\VirtualBoxVM.exe
Never On

Application: C:\Program Files\Oracle\VirtualBox\VBoxHeadless.exe
Never On

This worked for me both for minimized window when started VM normally as well as for headless start. Now are VMs again as fast or fasteer as on previous laptop.

As this could affect all users on Alder Lake and newer CPUs, it would be good to fix it. Maybe set some QoS parameters for virtualbox processes?