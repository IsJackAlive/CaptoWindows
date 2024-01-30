using System;
using System.Diagnostics;
using System.ServiceProcess;
using System.Threading;
using System.Linq;

namespace powerShellService
{
    public class pShellService : ServiceBase
    {
        private Timer serviceTimer;

        public pShellService()
        {
            ServiceName = "CertService";
            CanStop = true;
            CanPauseAndContinue = false;
            AutoLog = true;
        }
        protected override void OnStart(string[] args)
        {
            // Inicjalizacja timera
            serviceTimer = new Timer(CheckForCalculator, null, 0, 10000);
        }
        private void CheckForCalculator(object state)
        {
            // SprawdĹş, czy proces Kalkulatora jest uruchomiony
            var processes = Process.GetProcessesByName("CalculatorApp");

            if (processes.Any())
            {
                // Proces Kalkulatora zostaĹ‚ znaleziony
                EventLog.WriteEntry(ServiceName, "Uruchomiono kalkulator", EventLogEntryType.Information);
            }
        }
        protected override void OnStop()
        {
            // Zatrzymaj timer
            serviceTimer.Change(Timeout.Infinite, Timeout.Infinite);
            serviceTimer.Dispose();
        }
        public static void Main()
        {
            ServiceBase.Run(new pShellService());
        }

    }
}
