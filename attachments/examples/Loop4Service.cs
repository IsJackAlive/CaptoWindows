using System;
using System.ServiceProcess;

namespace powerShellService
{
    public class pShellService : ServiceBase
    {
        public pShellService()
        {
            ServiceName = "Loop4Service";
            CanStop = true;
            CanPauseAndContinue = true;
        }
        public static void Main()
        {
            ServiceBase.Run(new pShellService());
        }
    }
}
