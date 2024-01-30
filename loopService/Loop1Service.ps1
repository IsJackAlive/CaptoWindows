<#
:: Ustaw zależność serwisu X2 od serwisu X1
sc.exe config X2 depend= X1

:: Usun zaleznosc serwisu X
sc.exe config X depend= ""

:: Usun zaleznosc uslugi X (gdy usługa X jest zalezna, oraz inne uslugi sa zalezne od X)
sc.exe config X depend= "/<ServiceName>"
#>

# Loop1Service zapisuje nazwy zainstalowanych sterowników w pliku C:\InstalledDrivers.txt

# Tworzenie usługi
$serviceName = "Loop1Service"
$serviceDisplayName = "Loop1 Service"

# Definiowanie kodu C#
$serviceCode = @"
using System;
using System.IO;
using System.Diagnostics;
using System.ServiceProcess;

namespace powerShellService
{
    public class pShellService : ServiceBase
    {

        public pShellService()
        {
            ServiceName = "$serviceName";
            CanHandleSessionChangeEvent = true;
            CanPauseAndContinue = true;
            CanShutdown = true;
            CanStop = true;
        }

        static void Main()
        {
            ServiceBase.Run(new pShellService());
        }

        protected override void OnStart(string[] args)
        {
            base.OnStart(args);
            driverScan();
        }

        private void driverScan()
        {
            const string command = "driverquery /nh /si > C:\\InstalledDrivers.txt";

            using (var process = new Process())
            {
                var startInfo = new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    RedirectStandardInput = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                process.StartInfo = startInfo;
                process.Start();

                using (StreamWriter sw = process.StandardInput)
                {
                    if (sw.BaseStream.CanWrite)
                    {
                        sw.WriteLine(command);
                    }
                }
                process.WaitForExit();
            }
        }
    }
}
"@

# Zapisywanie kodu C# do pliku
$serviceCodePath = Join-Path -Path $env:TEMP -ChildPath "$serviceName.cs"
$serviceCode | Out-File -FilePath $serviceCodePath -Encoding UTF8

# Tworzenie ścieżki do pliku wykonywalnego (.exe)
$assemblyPath = Join-Path -Path $env:TEMP -ChildPath "$serviceName.exe"

# Parametry kompilacji
$compilerParams = @{
    TypeDefinition = Get-Content -Path $serviceCodePath -Raw
    OutputAssembly = $assemblyPath
    ReferencedAssemblies = "System.dll",  "System.ServiceProcess.dll"
}

# Kompilacja kodu do pliku wykonywalnego (.exe)
Add-Type @compilerParams

# Dodawanie serwisu do Serwisów Windows
$binPath = "`"$(Convert-Path $assemblyPath)`""
New-Service -Name $serviceName -BinaryPathName $binPath -DisplayName $serviceDisplayName -StartupType Automatic

# Dodanie zależności Loop1Service od CertService (Opcjonalnie)
# Start-Process -FilePath "sc.exe" -ArgumentList "config $serviceName depend= CertService" -NoNewWindow -Wait

# Zapisz informacje o utworzonym serwisie na pulpicie
$desktopPath = [Environment]::GetFolderPath("Desktop")
$servicesFilePath = Join-Path -Path $desktopPath -ChildPath "CaptoServices.txt"
$creationDate = Get-Date -Format "MM-dd HH:mm:ss"
Add-Content -Path $servicesFilePath -Value "Date: $creationDate Name: $serviceName Path: $assemblyPath"

Write-Host "Aby uruchomic wpisz: sc.exe start $serviceName `nJesli wystapily bledy usun za pomoca: sc.exe delete $serviceName `nPlik $serviceName.exe znajduje sie w $assemblyPath"