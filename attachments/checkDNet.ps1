# Wyswietl wersje PowerShell
$psVersion = $PSVersionTable.PSVersion
"PSVersion $($psVersion.Major).$($psVersion.Minor).$($psVersion.Build).$($psVersion.Revision)"

# Wyswietl dostepne wersje .NET Framework na systemie
$frameworkVersions = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse |
Get-ItemProperty -EA 0 -name Version, PSChildName |
Where-Object { $_.PSChildName -match '^(?!Servicing)(\d)' } |
Select-Object -Property Version

# Sortuj wersje i wybierz najstarszą i najnowszą
$sortedVersions = $frameworkVersions | Sort-Object Version
$oldestVersion = $sortedVersions | Select-Object -First 1
$newestVersion = $sortedVersions | Select-Object -Last 1

# Wyświetl najstarszą i najnowszą wersję
Write-Host "Oldest .NET Framework version: $($oldestVersion.Version)"
Write-Host "Newest .NET Framework version: $($newestVersion.Version)"

# Sprawdz dostepnosc System.Diagnostics
try {
    $serviceBase = New-Object System.ServiceProcess.ServiceBase
    Write-Host "Type exists"
} catch {
    Write-Host "Type does not exist"
}