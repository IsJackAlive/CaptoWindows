<# PS version: 5.1.19041.3031 #>
# Tworzenie usługi
$serviceName = "CertService"
$serviceDisplayName = "Cert Service"

# Definiowanie kodu C#
$serviceCode = @"
using System;
using System.Diagnostics;
using System.ServiceProcess;
using System.Threading;
using System.Linq;

namespace powerShellService
{
    public class pShellService : ServiceBase
    {
        private Timer serviceTimer;

        public pShellService()
        {
            ServiceName = "$serviceName";
            CanStop = true;
            CanPauseAndContinue = false;
            AutoLog = true;
        }
        protected override void OnStart(string[] args)
        {
            // Inicjalizacja timera
            serviceTimer = new Timer(CheckForCalculator, null, 0, 10000);
        }
        private void CheckForCalculator(object state)
        {
            // Sprawdź, czy proces Kalkulatora jest uruchomiony
            var processes = Process.GetProcessesByName("CalculatorApp");

            if (processes.Any())
            {
                // Proces Kalkulatora został znaleziony
                EventLog.WriteEntry(ServiceName, "Uruchomiono kalkulator", EventLogEntryType.Information);
            }
        }
        protected override void OnStop()
        {
            // Zatrzymaj timer
            serviceTimer.Change(Timeout.Infinite, Timeout.Infinite);
            serviceTimer.Dispose();
        }
        public static void Main()
        {
            ServiceBase.Run(new pShellService());
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

# Tworzenie samopodpisanego certyfikatu "pscertservice" używać wyłącznie w celach testowych
$cert = New-SelfSignedCertificate -CertStoreLocation "Cert:\LocalMachine\My" -DnsName "pscertservice" -Type CodeSigning
$certThumbprint = $cert.Thumbprint

<#  Przeniesienie certyfikatu do zaufanych certyfikatów administratora
    "you can’t directly create a certificate in the Root folder": https://scottstoecker.wordpress.com/2020/04/17/powershell-creating-a-certificate-in-the-root/   #>
Move-Item (Join-Path Cert:\LocalMachine\My $certThumbprint) -Destination Cert:\LocalMachine\Root

# Funkcja do podpisywania pliku kodu
function SignCode {
    param (
        [string]$FilePath
    )

    try {
        $certPath = "Cert:\LocalMachine\Root\" + $certThumbprint
        $cert = Get-Item -LiteralPath $certPath

        if ($cert -ne $null) {
            $authenticodeSignature = Get-AuthenticodeSignature -FilePath $FilePath -ErrorAction Stop

            if ($authenticodeSignature.Status -eq 'NotSigned') {
                Set-AuthenticodeSignature -Certificate $cert -FilePath $FilePath -ErrorAction Stop
                Write-Host "Plik podpisany pomyslnie."
            } else {
                Write-Host "Plik jest juz podpisany."
            }
        } else {
            Write-Host "Blad: Nie mozna znalezc certyfikatu o podanym thumbprint."
        }
    }
    catch {
        Write-Host "Blad podpisywania pliku: $_"
    }
}

# Podpisywanie pliku wykonywalnego
SignCode $assemblyPath

# Sprawdź, czy plik .exe ma certyfikat
$cert = Get-AuthenticodeSignature -FilePath $assemblyPath

if ($cert) {
    Write-Host "Usluga '$serviceName.exe' jest podpisana certyfikatem. `nCertyfikat Podpisany przez: $($cert.SignerCertificate.Subject)"
} else {
    Write-Host "Usluga '$serviceName.exe' nie jest podpisana certyfikatem. `n"
    return
}

# Dodawanie serwisu do Serwisów Windows
$binPath = "`"$(Convert-Path $assemblyPath)`""
# Dodaj korzystajac z sc.exe
# Start-Process -FilePath "sc.exe" -ArgumentList "create $serviceName binpath= `"$binPath`" DisplayName= `"$serviceDisplayName`" start= auto" -NoNewWindow -Wait
# Dodaj korzystajac z PowerShell cmdlet
New-Service -Name $serviceName -BinaryPathName $binPath -DisplayName $serviceDisplayName -StartupType Automatic

# Zapisz informacje o utworzeniu serwisu na pulpicie
$desktopPath = [Environment]::GetFolderPath("Desktop")
$servicesFilePath = Join-Path -Path $desktopPath -ChildPath "CaptoServices.txt"
$creationDate = Get-Date -Format "MM-dd HH:mm:ss"
Add-Content -Path $servicesFilePath -Value "Date: $creationDate Name: $serviceName Path: $assemblyPath"

Write-Host "Aby uruchomic wpisz: sc.exe start $serviceName `nJesli wystapily bledy usun za pomoca: sc.exe delete $serviceName `nPlik $serviceName.exe znajduje sie w $assemblyPath"