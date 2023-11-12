# Tworzenie certyfikatu "pscertservice"
$cert = New-SelfSignedCertificate -CertStoreLocation "Cert:\LocalMachine\My" -DnsName "pscertservice" -Type CodeSigning
$certThumbprint = $cert.Thumbprint

# Sprawdzenie czy certyfikat został utworzony
if (!$cert) {
    Write-Host "Certyfikat nie został utworzony"
    return
}

# Eksport certyfikatu do pliku PFX
$pwd = ConvertTo-SecureString -String 'Test123#' -AsPlainText -Force
$certPath = "Cert:\LocalMachine\My\" + $cert.Thumbprint
Export-PfxCertificate -Cert $certPath -FilePath "c:\temp\pscertservice.pfx" -Password $pwd

# Wyświetlanie informacji o certyfikacie
Write-Host "Certyfikat został utworzony. Thumbprint: $certThumbprint"

<#  (OPCJONALNIE)
    Przeniesienie certyfikatu do zaufanych certyfikatów administratora
    https://scottstoecker.wordpress.com/2020/04/17/powershell-creating-a-certificate-in-the-root/   #>
Move-Item (Join-Path Cert:\LocalMachine\My $certThumbprint) -Destination Cert:\LocalMachine\Root

# Tworzenie usługi
$serviceName = "CertService"
$serviceDisplayName = "Cert Service"

# Definiowanie kodu C#
$serviceCode = @"
using System;
using System.Diagnostics;
using System.ServiceProcess;
using System.Timers;
using System.Security.Cryptography.X509Certificates;

namespace powerShellService
{
    public class pShellService : ServiceBase
    {
        private System.Timers.Timer serviceTimer;
        private X509Certificate2 codeSigningCertificate;

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

            // Wczytaj certyfikat do podpisywania
            codeSigningCertificate = GetCertificateByThumbprint("$certThumbprint");
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

        private X509Certificate2 GetCertificateByThumbprint(string thumbprint)
        {
            X509Store store = new X509Store(StoreName.My, StoreLocation.LocalMachine);
            store.Open(OpenFlags.ReadOnly);
            X509Certificate2Collection certCollection = store.Certificates.Find(X509FindType.FindByThumbprint, thumbprint, false);
            store.Close();

            if (certCollection.Count > 0)
            {
                return certCollection[0];
            }
            else
            {
                return null;
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

# Sprawdź, czy plik .exe ma certyfikat
$cert = Get-AuthenticodeSignature -FilePath $assemblyPath

if ($cert) {
    Write-Host "Usługa '$serviceName.exe' jest podpisana certyfikatem. `n"
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