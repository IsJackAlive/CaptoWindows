# psSession0 project documentation

## Introduction

Due to numerous issues with Visual Studio configuration, hindering the correct compilation of the DLL library, I am providing files that will allow opening a functional project for DLL compilation in C language for the Windows system.

## Description

The DLL library executes a PowerShell command in Session 0. It starts the PowerShell process with the command to start the 'CertService' Windows service.
<a href="https://github.com/IsJackAlive/CaptoWindows/tree/main/certService">Link to CertService</a>

This is a modified version of the svc.c program by Grzegorz Tworek. The svc.c code is available on <a href="https://github.com/gtworek/PSBits/blob/master/Services/sekurak/svc.c">GitHub</a>.

> <details open>
>  <summary>Screenshots</summary> </br>
>    <img alt="" src=".scs/0.png" height=600px>
>    <img alt="" src=".scs/1.png" height=600px>
>    Powershell with administrator privilages running in normal case:
>    <img alt="" src=".scs/2.png" height=600px>
> </details>

## Function Descriptions

### PowerShellService

Launches the PowerShell process with a specified command, waits for the process to finish, terminates it, and reads the status. The return value is an error code or 0 for success.

### ServiceMain

The main function handles events related to controlling the service, such as START, STOP, PAUSE, CONTINUE.