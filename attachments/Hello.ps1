# Definiowanie kodu C#
$code = @"
using System;

namespace Hello
{
   class Program
    {
        static void Main()
        {
            Console.WriteLine("Witaj świecie!");
        }
    }
}
"@

# Zapisywanie kodu C# do pliku
$codePath = Join-Path -Path $env:TEMP -ChildPath "hello.cs"
$code | Out-File -FilePath $codePath -Encoding UTF8

# Kompilowanie kodu C# do pliku wykonywalnego .exe
$assemblyPath = Join-Path -Path $env:TEMP -ChildPath "hello.exe"

# Parametry kompilacji
$compilerParams = @{
    TypeDefinition = Get-Content -Path $codePath -Raw
    OutputAssembly = $assemblyPath
}

# Kompilacja kodu do pliku wykonywalnego (.exe)
Add-Type @compilerParams