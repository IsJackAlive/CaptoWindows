# Wpisz '.\clearCapto.ps1 -d' aby wyłączyć i usunąć wymienione usługi.
param (
    [switch]$d
)

$services = @("CantStop", "CertService", "RunService", "CaptoPs", "norebootsvc")

foreach ($serviceName in $services) {
    if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
        Stop-Service -Name $serviceName -Force
        Write-Host "Usluga $serviceName została wylaczona."
        if ($d) {
            sc.exe delete $serviceName
            Write-Host "Usluga $serviceName zostala usunieta."
        }
    } else {
        Write-Host "Usluga $serviceName nie istnieje."
    }
}
