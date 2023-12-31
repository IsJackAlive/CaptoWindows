for ($i = 4; $i -ge 1; $i--) {
    $serviceName = "Loop${i}Service"    
    if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
        Stop-Service -Name $serviceName -Force
        Write-Host "Usługa $serviceName została wyłączona."
    } else {
        Write-Host "Usługa $serviceName nie istnieje."
    }
}