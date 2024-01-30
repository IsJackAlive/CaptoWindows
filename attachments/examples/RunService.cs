using System;
using System.Diagnostics;
using System.ServiceProcess;
using System.Threading;

namespace RunService
{
    public class MyService : ServiceBase
    {
        private Timer timer;
        private const string ServiceLogMessage = "Run Service Run!";
        public MyService()
        {
            ServiceName = "RunService";
            CanStop = true;
            CanPauseAndContinue = false;
            AutoLog = true;
            timer = new Timer(DoWork, null, TimeSpan.Zero, TimeSpan.FromSeconds(30));
        }
        protected override void OnStart(string[] args)
        {
            // Kod wykonywany po rozpoczÄ™ciu pracy serwisu
            timer.Change(TimeSpan.Zero, TimeSpan.FromSeconds(30));
        }
        protected override void OnStop()
        {
            // Kod wykonywany po zatrzymaniu pracy serwisu
            if (timer != null)
            {
                timer.Dispose();
                timer = null;
            }
        }
        private void DoWork(object state)
        {
            try
            {
                EventLog.WriteEntry(ServiceName, ServiceLogMessage, EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry(ServiceName, String.Format("BĹ‚Ä…d podczas zapisywania do dziennika zdarzeĹ„: {0}", ex.Message), EventLogEntryType.Error);
            }
        }
        public static void Main()
        {
            ServiceBase.Run(new MyService());
        }
    }
}
