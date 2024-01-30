using System;
using System.ServiceProcess;
using System.Threading;

namespace powerShellService
{
    public class pShellService : ServiceBase
    {
        public pShellService()
        {
            ServiceName = "Loop3Service";
            CanStop = true;
            CanPauseAndContinue = true;
        }
        public static void Main()
        {
            ServiceBase.Run(new pShellService());
        }
    }
}
