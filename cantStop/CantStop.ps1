$serviceName = "cantStop"
$serviceDisplayName = "Can't Stop Service"

# Definiowanie kodu C#
$serviceCode = @"
using System;
using System.ServiceProcess;

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
$serviceCodePath = Join-Path -Path $env:TEMP -ChildPath "$serviceName.cs"
$serviceCode | Out-File -FilePath $serviceCodePath -Encoding UTF8

# Kompilowanie kodu C# do pliku wykonywalnego .exe
$assemblyPath = Join-Path -Path $env:TEMP -ChildPath "$serviceName.exe"
$compilerParams = @{
    TypeDefinition = Get-Content -Path $serviceCodePath -Raw
    OutputAssembly = $assemblyPath
    ReferencedAssemblies = "System.dll", "System.ServiceProcess.dll"
}
# Add-Type @compilerParams

try {
    Add-Type @compilerParams
} catch {
    Write-Error "Compilation failed: $_"
    exit 1
}

# Dodawanie serwisu cantStop do Serwisów Windows
$binPath = "`"$(Convert-Path $assemblyPath)`""
New-Service -Name $serviceName -BinaryPathName $binPath -DisplayName $serviceDisplayName -StartupType Automatic

# Zapisz informacje o utworzonym serwisie na pulpicie
$desktopPath = [Environment]::GetFolderPath("Desktop")
$servicesFilePath = Join-Path -Path $desktopPath -ChildPath "CaptoServices.txt"
$creationDate = Get-Date -Format "MM-dd HH:mm:ss"
Add-Content -Path $servicesFilePath -Value "Date: $creationDate Name: $serviceName Path: $assemblyPath"

Write-Host "Aby uruchomic wpisz: sc.exe start $serviceName `nJesli wystapily bledy usun za pomoca: sc.exe delete $serviceName `nPlik $serviceName.exe znajduje sie w $assemblyPath"