# RunService2 25-05
# Add-Type w PowerShell korzysta z kompilatora C# 5.0

$serviceName = "RunService"
$serviceDisplayName = "Run Service"

# Definiowanie kodu C#
$serviceCode = @"
using System;
using System.Diagnostics;
using System.ServiceProcess;
using System.Threading;

namespace RunService
{
    public class MyService : ServiceBase
    {
        private Timer timer;
        private const string ServiceLogMessage = "Run Service Run!";
        public MyService()
        {
            ServiceName = "$serviceName";
            CanStop = true;
            CanPauseAndContinue = false;
            AutoLog = true;
            timer = new Timer(DoWork, null, TimeSpan.Zero, TimeSpan.FromSeconds(30));
        }
        protected override void OnStart(string[] args)
        {
            // Kod wykonywany po rozpoczęciu pracy serwisu
            timer.Change(TimeSpan.Zero, TimeSpan.FromSeconds(30));
        }
        protected override void OnStop()
        {
            // Kod wykonywany po zatrzymaniu pracy serwisu
            if (timer != null)
            {
                timer.Dispose();
                timer = null;
            }
        }
        private void DoWork(object state)
        {
            try
            {
                EventLog.WriteEntry(ServiceName, ServiceLogMessage, EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry(ServiceName, String.Format("Błąd podczas zapisywania do dziennika zdarzeń: {0}", ex.Message), EventLogEntryType.Error);
            }
        }
        public static void Main()
        {
            ServiceBase.Run(new MyService());
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
    ReferencedAssemblies = "System.dll", "System.ServiceProcess.dll"
}
Add-Type @compilerParams # Operator splatting (@) pozwala na przekazanie tablicy lub słownika argumentów do cmdletu.

# Dodawanie serwisu RunService do Serwisów Windows
$binPath = "`"$(Convert-Path $assemblyPath)`""
# Dodaj korzystajac z sc.exe
# Start-Process -FilePath "sc.exe" -ArgumentList "create $serviceName binpath= `"$binPath`" DisplayName= `"$serviceDisplayName`" start= auto" -NoNewWindow -Wait
# Lub dodaj korzystajac z PowerShell cmdlet
New-Service -Name $serviceName -BinaryPathName $binPath -DisplayName $serviceDisplayName -StartupType Automatic

# Zapisz informacje o utworzonym serwisie na pulpicie
$desktopPath = [Environment]::GetFolderPath("Desktop")
$servicesFilePath = Join-Path -Path $desktopPath -ChildPath "CaptoServices.txt"
$creationDate = Get-Date -Format "MM-dd HH:mm:ss"
Add-Content -Path $servicesFilePath -Value "Date: $creationDate Name: $serviceName Path: $assemblyPath"

Write-Host "Aby uruchomic wpisz: sc.exe start $serviceName `nJesli wystapily bledy usun za pomoca: sc.exe delete $serviceName `nPlik $serviceName.exe znajduje sie w $assemblyPath"