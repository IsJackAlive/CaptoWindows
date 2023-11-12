# Zapisuje zainstalowane sterowniki na C:\InstalledDrivers.txt

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
            this.CanPauseAndContinue = true;
            this.CanShutdown = true;
            this.CanStop = true;
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

        protected override void OnStop()
        {
            base.OnStop();
        }

        private void driverScan()
        {
            try
            {
                // Komenda wiersza poleceń do pobrania listy sterowników
                string command = "driverquery /nh /si > C:\\InstalledDrivers.txt";

                // Utworzenie procesu do wykonania komendy wiersza poleceń
                Process process = new Process();
                ProcessStartInfo startInfo = new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    RedirectStandardInput = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                process.StartInfo = startInfo;
                process.Start();

                // Przekazanie komendy wiersza poleceń do procesu
                using (StreamWriter sw = process.StandardInput)
                {
                    if (sw.BaseStream.CanWrite)
                    {
                        sw.WriteLine(command);
                    }
                }

                // Oczekiwanie na zakończenie procesu
                process.WaitForExit();
                process.Close();

                Console.WriteLine("Lista sterowników została zapisana w pliku C:\\InstalledDrivers.txt.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Wystąpił błąd: " + ex.Message);
            }
        }
    }
}
"@

# Zapisywanie kodu C# do pliku
$serviceCodePath = Join-Path -Path $env:TEMP -ChildPath "$serviceName.cs"
$serviceCode | Out-File -FilePath $serviceCodePath -Encoding UTF8

# Kompilowanie kodu C# do pliku wykonywalnego .exe
$assemblyPath = Join-Path -Path $env:TEMP -ChildPath "$serviceName.exe"
$compilerParams = @{
    TypeDefinition = Get-Content -Path $serviceCodePath -Raw
    OutputAssembly = $assemblyPath
    ReferencedAssemblies = "System.ServiceProcess.dll", "System.dll", "System.Configuration.Install.dll"
}
Add-Type @compilerParams

$assemblyPath = Join-Path -Path $env:TEMP -ChildPath "$serviceName.exe"

# Dodawanie serwisu do Serwisów Windows
$binPath = "`"$(Convert-Path $assemblyPath)`""
Start-Process -FilePath "sc.exe" -ArgumentList "create $serviceName binpath= `"$binPath`" DisplayName= `"$serviceDisplayName`" start= auto" -NoNewWindow -Wait

# Sprawdzanie stanu serwisu
Get-Service -Name $serviceName | Select-Object Name, Status

Write-Host "Aby uruchomić wpisz: sc.exe start $serviceName `nJeśli wystąpiły błędy usuń za pomocą: sc.exe delete $serviceName"