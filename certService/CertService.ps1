<# PS version: 5.1.19041.3031 #>
# Tworzenie usługi
$serviceName = "CertService"
$serviceDisplayName = "Cert Service"

# Definiowanie kodu C#
$serviceCode = @"
using System;
using System.Diagnostics;
using System.ServiceProcess;
using System.Timers;

namespace powerShellService
{
    public class pShellService : ServiceBase
    {
        private System.Timers.Timer serviceTimer;

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
            serviceTimer = new System.Timers.Timer(10000);
            serviceTimer.Elapsed += CheckForCalculator;
            serviceTimer.AutoReset = true;
            serviceTimer.Enabled = true;
        }

        private void CheckForCalculator(object sender, ElapsedEventArgs e)
        {
            // Sprawdź, czy proces Kalkulatora jest uruchomiony
            Process[] processes = Process.GetProcessesByName("CalculatorApp");

            if (processes.Length > 0)
            {
                // Proces Kalkulatora został znaleziony
                EventLog.WriteEntry(ServiceName, "Uruchomiono kalkulator", EventLogEntryType.Information);
            }
        }

        protected override void OnStop()
        {
            // Zatrzymaj timer
            serviceTimer.Stop();
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
    ReferencedAssemblies = "System.ServiceProcess.dll", "System.dll", "System.Configuration.Install.dll"
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
                Write-Host "Plik podpisany pomyślnie."
            } else {
                Write-Host "Plik jest już podpisany."
            }
        } else {
            Write-Host "Błąd: Nie można znaleźć certyfikatu o podanym thumbprint."
        }
    }
    catch {
        Write-Host "Błąd podpisywania pliku: $_"
    }
}

# Podpisywanie pliku wykonywalnego
SignCode $assemblyPath

# Sprawdź, czy plik .exe ma certyfikat
$cert = Get-AuthenticodeSignature -FilePath $assemblyPath

if ($cert) {
    Write-Host "Usługa '$serviceName.exe' jest podpisana certyfikatem. `nCertyfikat Podpisany przez: $($cert.SignerCertificate.Subject)"
} else {
    Write-Host "Usługa '$serviceName.exe' nie jest podpisana certyfikatem. `n"
    return
}

# Dodawanie serwisu do Serwisów Windows
$binPath = "`"$(Convert-Path $assemblyPath)`""
Start-Process -FilePath "sc.exe" -ArgumentList "create $serviceName binpath= `"$binPath`" DisplayName= `"$serviceDisplayName`" start= auto" -NoNewWindow -Wait

# Sprawdzanie stanu serwisu
Get-Service -Name $serviceName | Select-Object Name, Status

Write-Host "Aby uruchomić wpisz: sc.exe start $serviceName `nJeśli wystąpiły błędy usuń za pomocą: sc.exe delete $serviceName"