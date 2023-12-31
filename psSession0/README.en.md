# psSession0 project documentation

## Introduction

Due to numerous issues with Visual Studio configuration, hindering the correct compilation of the DLL library, I am providing files that will allow opening a functional project for DLL compilation in C language for the Windows system.

## Description

The DLL library executes a PowerShell command in Session 0. It starts the PowerShell process with the command to start the 'CertService' Windows service.
<a href="https://github.com/IsJackAlive/CaptoWindows/tree/main/certService">Link to CertService</a>

This is a modified version of the svc.c program by Grzegorz Tworek. The svc.c code is available on <a href="https://github.com/gtworek/PSBits/blob/master/Services/sekurak/svc.c">GitHub</a>.

> <details open>
>  <summary>Screenshots</summary> </br>
>    <img alt="" src=".scs/0.png">
>    <img alt="" src=".scs/1.png">
>    Powershell with administrator privilages running in normal case:
>    <img alt="" src=".scs/2.png">
> </details>

## Function Descriptions

### PowerShellService

Launches the PowerShell process with a specified command, waits for the process to finish, terminates it, and reads the status. The return value is an error code or 0 for success.

### ServiceMain

The main function handles events related to controlling the service, such as START, STOP, PAUSE, CONTINUE.

# How to run

Create a service based on the svchost process.
<img alt="create own service 'CaptoPs' based on svchost" src=".scs/5.png"> </br>

The compiled DLL file size is  132 KB / 135 680 B.
<img alt="correct size is about 132KB / 135 680B" src=".scs/7.png"> </br>

Open the Registry Editor (regedit) and create a new key for your service. This key should be placed in the appropriate location.
<img alt="create new key in own service (regedit)" src=".scs/6.png"> </br>

Configure the path to the compiled DLL library of your service.
<img alt="path to compiled dll" src=".scs/8.png"> </br>

Add a group name for svchost, where your service belongs.
<img alt="add group name for svchost" src=".scs/9.png"> </br>

Add the name of your service to the previously created svchost group.
<img alt="add service name in added group" src=".scs/10.png"> </br>

Open DebugView as an administrator to trace information related to the DLL's operation.
<img alt="view debug info in DebugView(admin)" src=".scs/11.png"> </br>

Start the service.
<img alt="start service 'CaptoPs'" src=".scs/12.png"> </br>