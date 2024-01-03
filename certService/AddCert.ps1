$dllPath = "C:\Windows\system32\dll-ps0.dll"

$psCert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Subject -eq "CN=pscertservice" }

try {
    # Pobierz istniejący podpis cyfrowy
    $existingSignature = Get-AuthenticodeSignature -FilePath $dllPath -ErrorAction SilentlyContinue

    if ($existingSignature -eq $null -or $existingSignature.Status -eq 'NotSigned') {
        Set-AuthenticodeSignature -FilePath $dllPath -Certificate $psCert
        Write-Host "Dodano podpis cyfrowy do: $dllPath"
    } else {
        Write-Host "Plik $dllPath już ma podpis cyfrowy."
    }
} catch {
    Write-Host "Błąd podczas manipulacji podpisem cyfrowym pliku: $dllPath"
}

# Sprawdzenie certyfikatu
# Get-AuthenticodeSignature $dllPath