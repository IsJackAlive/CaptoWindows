using System;
using System.ServiceProcess;

namespace cantStop
{
    public class MyService : ServiceBase
    {
        public MyService()
        {
            ServiceName = "cantStop";
            CanStop = false; // Odmawiamy zatrzymania serwisu
            CanPauseAndContinue = false;
        }
        protected override void OnStart(string[] args)
        {   // 
        }
        protected override void OnStop()
        {   // 
        }
        public static void Main()
        {
            ServiceBase.Run(new MyService());
        }
    }
}
