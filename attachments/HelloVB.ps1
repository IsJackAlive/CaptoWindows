# Definiowanie kodu VB.NET
$vbCode = @"
Imports System

Namespace HelloVB
    Class Program
        Shared Sub Main()
            Console.WriteLine("Witaj świecie!")
        End Sub
    End Class
End Namespace
"@

# Zapisywanie kodu VB.NET do pliku
$vbCodePath = Join-Path -Path $env:TEMP -ChildPath "hellovb.vb"
$vbCode | Out-File -FilePath $vbCodePath -Encoding UTF8

# Kompilowanie kodu VB.NET do pliku wykonywalnego .exe
$assemblyPath = Join-Path -Path $env:TEMP -ChildPath "hellovb.exe"

# Parametry kompilacji
$compilerParams = @{
    TypeDefinition = Get-Content -Path $vbCodePath -Raw
    OutputAssembly = $assemblyPath
    Language = "VisualBasic"
}

# Kompilacja kodu do pliku wykonywalnego (.exe)
Add-Type @compilerParams