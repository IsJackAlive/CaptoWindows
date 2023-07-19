$serviceName = "cantStop"
$serviceDisplayName = "Can't Stop Service"
$serviceDescription = "This is a sample service created using PowerShell."

# Definiowanie kodu C#
$serviceCode = @"
using System;
using System.ServiceProcess;
using System.Threading;

namespace cantStop
{
    public class MyService : ServiceBase
    {
        public MyService()
        {
            ServiceName = "$serviceName";
            CanStop = false; // Odmawiamy zatrzymania serwisu
            CanPauseAndContinue = false;
        }
        protected override void OnStart(string[] args)
        {   // 
        }
        protected override void OnStop()
        {   // 
        }
        public static void Main()
        {
            ServiceBase.Run(new MyService());
        }
    }
}
"@

# Zapisywanie kodu C# do pliku
$serviceCodePath = Join-Path -Path $env:TEMP -ChildPath "cantStop.cs"
$serviceCode | Out-File -FilePath $serviceCodePath -Encoding UTF8

# Kompilowanie kodu C# do pliku wykonywalnego .exe
$assemblyPath = Join-Path -Path $env:TEMP -ChildPath "cantStop.exe"
$compilerParams = @{
    TypeDefinition = Get-Content -Path $serviceCodePath -Raw
    OutputAssembly = $assemblyPath
    ReferencedAssemblies = "System.ServiceProcess.dll"
}
Add-Type @compilerParams

# Dodawanie serwisu cantStop do Serwisów Windows
$binPath = "`"$(Convert-Path $assemblyPath)`""
Start-Process -FilePath "sc.exe" -ArgumentList "create $serviceName binpath= `"$binPath`" DisplayName= `"$serviceDisplayName`" start= auto" -NoNewWindow -Wait

# Ustawianie opisu serwisu
$service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
$service.Description = $serviceDescription
$service.Put()

# Sprawdzanie stanu serwisu
Get-Service -Name $serviceName
