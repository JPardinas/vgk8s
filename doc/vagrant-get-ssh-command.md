# show ssh command of vagrant in windows

(Get-CimInstance Win32_Process -Filter "Name = 'ssh.exe'" | Select-Object ProcessId, CommandLine).CommandLine
