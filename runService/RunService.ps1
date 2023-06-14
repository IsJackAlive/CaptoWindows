# RunService2 25-05

$serviceName = "RunService"
$serviceDisplayName = "Run Service"
$serviceDescription = "This is a sample service created using C#."

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

        public MyService()
        {
            ServiceName = "$serviceName";
            CanStop = true;
            CanPauseAndContinue = false;
            AutoLog = true;
        }

        protected override void OnStart(string[] args)
        {
            // Kod wykonywany po rozpoczęciu pracy serwisu
            timer = new Timer(DoWork, null, TimeSpan.Zero, TimeSpan.FromSeconds(30));
        }

        protected override void OnStop()
        {
            // Kod wykonywany po zatrzymaniu pracy serwisu
            timer.Dispose();
        }

        private void DoWork(object state)
        {
            EventLog.WriteEntry("$serviceName", "Run Service Run!", EventLogEntryType.Information);
        }
        
        public static void Main()
        {
            ServiceBase.Run(new MyService());
        }
    }
}
"@

# Zapisywanie kodu C# do pliku
$serviceCodePath = Join-Path -Path $env:TEMP -ChildPath "RunService.cs"
$serviceCode | Out-File -FilePath $serviceCodePath -Encoding UTF8

# Kompilowanie kodu C# do pliku wykonywalnego .exe
$assemblyPath = Join-Path -Path $env:TEMP -ChildPath "RunService.exe"
$compilerParams = @{
    TypeDefinition = Get-Content -Path $serviceCodePath -Raw
    OutputAssembly = $assemblyPath
    ReferencedAssemblies = "System.ServiceProcess.dll"
}
Add-Type @compilerParams

# Dodawanie serwisu RunService do Serwisów Windows
$binPath = "`"$(Convert-Path $assemblyPath)`""
Start-Process -FilePath "sc.exe" -ArgumentList "create $serviceName binpath= `"$binPath`" DisplayName= `"$serviceDisplayName`" start= auto" -NoNewWindow -Wait

# Ustawianie opisu serwisu
$service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
$service.Description = $serviceDescription
$service.Put()

# Sprawdzanie stanu serwisu
Get-Service -Name $serviceName