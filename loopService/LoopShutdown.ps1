# Wpisz '.\LoopShutdown.ps1 -d' aby wyłączyć i usunąć usługi.
param (
    [switch]$d
)

for ($i = 4; $i -ge 1; $i--) {
    $serviceName = "Loop${i}Service"    
    if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
        Stop-Service -Name $serviceName -Force
        Write-Host "Usluga $serviceName zostala wylaczona."
        if ($d) {
            sc.exe delete $serviceName
            Write-Host "Usluga $serviceName zostala usunieta."
        }
    } else {
        Write-Host "Usluga $serviceName nie istnieje."
    }
}