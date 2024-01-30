# Zapisuje informacje o kontach użytkowników, grupach oraz datę ostatniej aktualizacji systemu w pliku C:\SystemInfo.txt

# Tworzenie usługi
$serviceName = "Loop2Service"
$serviceDisplayName = "Loop2 Service"

# Definiowanie kodu C#
$serviceCode = @"
using System;
using System.IO;
using System.Management;
using System.ServiceProcess;
using System.DirectoryServices.AccountManagement;
using System.Collections.Generic;

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
            CollectSystemInfo();
        }
        private void CollectSystemInfo()
        {
            // Ścieżka do pliku wyjściowego
            string outputPath = "C:\\SystemInfo.txt";

            using (StreamWriter writer = new StreamWriter(outputPath))
                {
                    // Informacje o kontach użytkowników
                    writer.WriteLine("Konta uzytkownikow:");
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

                    // Informacje o systemie
                    writer.WriteLine("\nInformacje o systemie:");
                    string info = GetSystemInfo();
                    writer.WriteLine(info);
                }
        }

        private string[] GetLocalUsers()
        {
            List<string> users = new List<string>();
            using (PrincipalContext context = new PrincipalContext(ContextType.Machine))
            {
                using (UserPrincipal userPrincipal = new UserPrincipal(context))
                {
                    using (PrincipalSearcher searcher = new PrincipalSearcher(userPrincipal))
                    {
                        foreach (var result in searcher.FindAll())
                        {
                            UserPrincipal user = result as UserPrincipal;

                            if (user != null)
                            {
                                users.Add(user.Name);
                            }
                        }
                    }
                }
            }

            return users.ToArray();
        }

        private string[] GetLocalGroups()
        {
            List<string> groups = new List<string>();
            using (PrincipalContext context = new PrincipalContext(ContextType.Machine))
            {
                using (GroupPrincipal groupPrincipal = new GroupPrincipal(context))
                {
                    using (PrincipalSearcher searcher = new PrincipalSearcher(groupPrincipal))
                    {
                        foreach (var result in searcher.FindAll())
                        {
                            GroupPrincipal group = result as GroupPrincipal;
                            if (group != null)
                            {
                                groups.Add(group.Name);
                            }
                        }
                    }
                }
            }
            return groups.ToArray();
        }

        private string GetSystemInfo()
        {   
            // https://learn.microsoft.com/pl-pl/dotnet/api/system.management.managementobjectsearcher.-ctor?view=dotnet-plat-ext-8.0#system-management-managementobjectsearcher-ctor(system-string)
            ManagementObjectSearcher searcher = new ManagementObjectSearcher("SELECT * FROM Win32_OperatingSystem");
            foreach (ManagementObject os in searcher.Get())
            {
                string caption = os["Caption"].ToString();
                string version = os["Version"].ToString();
                ulong totalMemory = Convert.ToUInt64(os["TotalVisibleMemorySize"]);
                
                string systemInfo = string.Format("Caption: {0}, Version: {1}, Total Memory: {2} KB", caption, version, totalMemory);
                return systemInfo;
            }
            return "No WMI info found";
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
    ReferencedAssemblies = "System.dll",  "System.ServiceProcess.dll", "System.DirectoryServices.dll", "System.DirectoryServices.AccountManagement.dll", "System.Management.dll"
}

# Kompilacja kodu do pliku wykonywalnego (.exe)
Add-Type @compilerParams

# Dodawanie serwisu do Serwisów Windows
$binPath = "`"$(Convert-Path $assemblyPath)`""
New-Service -Name $serviceName -BinaryPathName $binPath -DisplayName $serviceDisplayName -StartupType Automatic

# Dodanie zależności Loop2Service od Loop1Service
Start-Process -FilePath "sc.exe" -ArgumentList "config $serviceName depend= Loop1Service" -NoNewWindow -Wait

# Zapisz informacje o utworzonym serwisie na pulpicie
$desktopPath = [Environment]::GetFolderPath("Desktop")
$servicesFilePath = Join-Path -Path $desktopPath -ChildPath "CaptoServices.txt"
$creationDate = Get-Date -Format "MM-dd HH:mm:ss"
Add-Content -Path $servicesFilePath -Value "Date: $creationDate Name: $serviceName Path: $assemblyPath"

Write-Host "Aby uruchomic wpisz: sc.exe start $serviceName `nJesli wystapily bledy usun za pomoca: sc.exe delete $serviceName `nPlik $serviceName.exe znajduje sie w $assemblyPath"