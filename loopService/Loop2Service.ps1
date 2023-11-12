<#
# Ustaw zależność serwisu Loop2 od serwisu Loop1
sc.exe config Loop2Service depend= Loop1Service

# Ustaw zależność serwisu Loop1 od serwisu Loop2
sc.exe config Loop1Service depend= Loop2Service
#>

# Tworzenie usługi
$serviceName = "Loop2Service"
$serviceDisplayName = "Loop2 Service"

# Definiowanie kodu C#
$serviceCode = @"
using System;
using System.IO;
using System.Diagnostics;
using System.ServiceProcess;
using System.Security.Principal;

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
            CollectSystemInfo();
        }

        protected override void OnStop()
        {
            base.OnStop();
        }

        private void CollectSystemInfo()
        {
            try
            {
                // Ścieżka do pliku, w którym będziemy zapisywać informacje
                string outputPath = "C:\\SystemInfo.txt";

                using (StreamWriter writer = new StreamWriter(outputPath))
                {
                    // Informacje o kontach użytkowników
                    writer.WriteLine("Konta użytkowników:");
                    foreach (var user in GetLocalUsers())
                    {
                        writer.WriteLine(user);
                    }

                    // Informacje o grupach
                    writer.WriteLine("\nGrupy:");
                    foreach (var group in GetLocalGroups())
                    {
                        writer.WriteLine(group);
                    }

                    // Informacje o uprawnieniach (lokalne grupy i ich uprawnienia)
                    writer.WriteLine("\nUprawnienia grup:");
                    foreach (var group in GetLocalGroupPermissions())
                    {
                        writer.WriteLine(group);
                    }

                    // Data ostatniej aktualizacji systemu
                    writer.WriteLine("\nData ostatniej aktualizacji systemu:");
                    string lastUpdate = GetLastSystemUpdate();
                    writer.WriteLine(lastUpdate);
                }

                // Poinformuj, że informacje zostały zapisane
                EventLog.WriteEntry("SystemInfoService", "Informacje zostały zapisane w pliku C:\\SystemInfo.txt", EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                // Obsługa ewentualnych błędów
                EventLog.WriteEntry("SystemInfoService", "Błąd podczas zbierania informacji: " + ex.Message, EventLogEntryType.Error);
            }
        }

        private string[] GetLocalUsers()
        {
            // Tutaj zbierz informacje o kontach użytkowników
            // Przykład: zastosowanie System.DirectoryServices.AccountManagement

            return new string[] { "User1", "User2", "User3" };
        }

        private string[] GetLocalGroups()
        {
            // Tutaj zbierz informacje o grupach
            // Przykład: zastosowanie System.DirectoryServices.AccountManagement

            return new string[] { "Group1", "Group2", "Group3" };
        }

        private string[] GetLocalGroupPermissions()
        {
            // Tutaj zbierz informacje o uprawnieniach grup
            // Przykład: zastosowanie System.DirectoryServices.AccountManagement

            return new string[] { "Permission1", "Permission2", "Permission3" };
        }

        private string GetLastSystemUpdate()
        {
            // Tutaj uzyskaj datę ostatniej aktualizacji systemu
            // Przykład: zastosowanie dostępu do informacji o aktualizacjach systemowych

            return DateTime.Now.ToString();
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