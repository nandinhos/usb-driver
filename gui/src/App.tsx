import { useEffect, useState } from 'react';
import type { DeviceListResult, HealthCheckResult } from './types/usb';

export default function App() {
  const [health, setHealth] = useState<HealthCheckResult | null>(null);
  const [devices, setDevices] = useState<DeviceListResult | null>(null);

  useEffect(() => {
    if (!window.usbDriver) return;
    window.usbDriver.checkHealth().then(setHealth).catch(() => undefined);
    window.usbDriver.listDevices().then(setDevices).catch(() => undefined);
  }, []);

  return (
    <main className="min-h-screen bg-slate-950 p-6 text-slate-100">
      <h1 className="text-xl font-semibold">USB Driver — WSL2</h1>
      <p className="mt-2 text-sm text-slate-400">
        Health: {health ? (health.ok ? 'OK' : 'Pendente') : 'Carregando...'}
      </p>
      <p className="text-sm text-slate-400">
        Dispositivos WSL: {devices?.wslDevices.length ?? 0} | Windows: {devices?.windowsDevices.length ?? 0}
      </p>
    </main>
  );
}
