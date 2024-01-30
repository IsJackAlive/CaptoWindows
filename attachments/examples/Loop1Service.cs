using System;
using System.IO;
using System.Diagnostics;
using System.ServiceProcess;

namespace powerShellService
{
    public class pShellService : ServiceBase
    {

        public pShellService()
        {
            ServiceName = "Loop1Service";
            CanHandleSessionChangeEvent = true;
            CanPauseAndContinue = true;
            CanShutdown = true;
            CanStop = true;
        }

        static void Main()
        {
            ServiceBase.Run(new pShellService());
        }

        protected override void OnStart(string[] args)
        {
            base.OnStart(args);
            driverScan();
        }

        private void driverScan()
        {
            const string command = "driverquery /nh /si > C:\\InstalledDrivers.txt";

            using (var process = new Process())
            {
                var startInfo = new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    RedirectStandardInput = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                process.StartInfo = startInfo;
                process.Start();

                using (StreamWriter sw = process.StandardInput)
                {
                    if (sw.BaseStream.CanWrite)
                    {
                        sw.WriteLine(command);
                    }
                }
                process.WaitForExit();
            }
        }
    }
}
