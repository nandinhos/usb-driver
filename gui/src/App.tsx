import { useCallback, useEffect, useState } from 'react';
import {
  CheckCircle2,
  FlaskConical,
  HardDrive,
  RefreshCw,
  Usb,
  XCircle,
} from 'lucide-react';
import { DeviceCardPlaceholder } from './components/EmptyState';
import { WindowsDeviceCard, WslDeviceCard } from './components/DeviceCard';
import { HealthBanner } from './components/HealthBanner';
import type { ActionResult, DeviceListResult, HealthCheckResult } from './types/usb';

interface ToastState {
  ok: boolean;
  text: string;
}

export default function App() {
  const [version, setVersion] = useState('0.9.0');
  const [simulate, setSimulate] = useState(false);
  const [health, setHealth] = useState<HealthCheckResult | null>(null);
  const [devices, setDevices] = useState<DeviceListResult>({
    wslDevices: [],
    windowsDevices: [],
  });
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [toast, setToast] = useState<ToastState | null>(null);

  const hasBridge = typeof window !== 'undefined' && Boolean(window.usbDriver);

  const notify = useCallback((res: ActionResult, fallbackSuccess: string) => {
    setToast({
      ok: res.ok,
      text: res.message || (res.ok ? fallbackSuccess : 'Operação não concluída.'),
    });
  }, []);

  const refreshAll = useCallback(async () => {
    if (!hasBridge) {
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      const [h, d] = await Promise.all([
        window.usbDriver.checkHealth().catch(() => null),
        window.usbDriver.listDevices().catch(() => ({ wslDevices: [], windowsDevices: [] })),
      ]);
      if (h) setHealth(h);
      setDevices(d);
    } finally {
      setLoading(false);
    }
  }, [hasBridge]);

  useEffect(() => {
    if (!hasBridge) {
      setLoading(false);
      return;
    }
    window.usbDriver
      .getAppInfo()
      .then((info) => {
        setVersion(info.version);
        setSimulate(info.simulate);
      })
      .finally(() => {
        refreshAll();
      });
  }, [hasBridge, refreshAll]);

  const handleToggleSimulate = async () => {
    if (!hasBridge || busy) return;
    const next = await window.usbDriver.setSimulateMode(!simulate);
    setSimulate(next);
    setToast({
      ok: true,
      text: next
        ? 'Modo Simulação ativado — exibindo dispositivos fictícios.'
        : 'Modo Simulação desativado — lendo hardware real.',
    });
    await refreshAll();
  };

  const handleMount = async (busid?: string) => {
    if (!hasBridge || busy) return;
    setBusy(true);
    try {
      const res = await window.usbDriver.mountDevice(busid);
      notify(res, 'Dispositivo montado no WSL2 com sucesso.');
      await refreshAll();
    } finally {
      setBusy(false);
    }
  };

  const handleUnmount = async (mountPoint: string, eject: boolean) => {
    if (!hasBridge || busy) return;
    setBusy(true);
    try {
      const res = await window.usbDriver.unmountDevice(mountPoint, { eject });
      notify(res, 'Dispositivo desmontado e ejetado com segurança.');
      await refreshAll();
    } finally {
      setBusy(false);
    }
  };

  const handleBind = async (busid: string) => {
    if (!hasBridge || busy) return;
    setBusy(true);
    try {
      const res = await window.usbDriver.bindDevice(busid);
      notify(res, `Dispositivo ${busid} compartilhado.`);
      await refreshAll();
    } finally {
      setBusy(false);
    }
  };

  const handleOpenExplorer = async (mountPoint: string) => {
    if (!hasBridge) return;
    const res = await window.usbDriver.openInExplorer(mountPoint);
    if (!res.ok) notify(res, '');
  };

  const mountedCount = devices.wslDevices.filter((d) => d.status === 'mounted').length;

  return (
    <div className="min-h-screen bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-slate-900 via-slate-950 to-slate-950 text-slate-100">
      <div className="mx-auto flex max-w-5xl flex-col gap-6 px-6 py-7">
        {/* Header */}
        <header className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-3.5">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl border border-cyan-500/30 bg-gradient-to-br from-cyan-500/20 to-indigo-500/20 shadow-lg shadow-cyan-500/10">
              <Usb className="h-5 w-5 text-cyan-300" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-lg font-bold tracking-tight text-white">USB Driver</h1>
                <span className="rounded-full border border-slate-800 bg-slate-900 px-2 py-0.5 text-[11px] font-medium text-slate-400">
                  v{version}
                </span>
              </div>
              <p className="text-xs text-slate-400">
                Gerenciador seguro de armazenamento USB (EXT4, NTFS, exFAT, FAT32) no WSL2
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <button
              type="button"
              onClick={handleToggleSimulate}
              disabled={!hasBridge || busy}
              className={`inline-flex items-center gap-1.5 rounded-xl border px-3 py-2 text-xs font-medium transition disabled:opacity-50 ${
                simulate
                  ? 'border-cyan-500/40 bg-cyan-500/15 text-cyan-200'
                  : 'border-slate-800 bg-slate-900/80 text-slate-300 hover:border-slate-700'
              }`}
            >
              <FlaskConical className="h-3.5 w-3.5" />
              {simulate ? 'Simulação: ON' : 'Simular'}
            </button>

            <button
              type="button"
              onClick={refreshAll}
              disabled={!hasBridge || loading || busy}
              className="inline-flex items-center gap-1.5 rounded-xl border border-slate-700 bg-slate-800/80 px-3.5 py-2 text-xs font-semibold text-slate-100 transition hover:border-cyan-500/40 hover:bg-slate-800 disabled:opacity-50"
            >
              <RefreshCw className={`h-3.5 w-3.5 ${loading ? 'animate-spin' : ''}`} />
              Atualizar
            </button>
          </div>
        </header>

        {/* Health Banner */}
        <HealthBanner health={health} simulate={simulate} />

        {/* Toast Feedback */}
        {toast && (
          <div
            className={`flex items-center justify-between gap-3 rounded-xl border px-4 py-2.5 text-xs font-medium ${
              toast.ok
                ? 'border-emerald-500/30 bg-emerald-500/10 text-emerald-200'
                : 'border-rose-500/30 bg-rose-500/10 text-rose-200'
            }`}
          >
            <div className="flex items-center gap-2">
              {toast.ok ? (
                <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-400" />
              ) : (
                <XCircle className="h-4 w-4 shrink-0 text-rose-400" />
              )}
              <span>{toast.text}</span>
            </div>
            <button
              type="button"
              onClick={() => setToast(null)}
              className="text-slate-400 hover:text-slate-200"
            >
              Fechar
            </button>
          </div>
        )}

        {/* KPI Cards */}
        <section className="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div className="rounded-2xl border border-slate-800/80 bg-slate-900/50 p-4">
            <p className="text-xs font-medium text-slate-400">Montados no WSL2</p>
            <p className="mt-1 text-2xl font-bold text-emerald-300">{mountedCount}</p>
          </div>
          <div className="rounded-2xl border border-slate-800/80 bg-slate-900/50 p-4">
            <p className="text-xs font-medium text-slate-400">Detectados no Windows</p>
            <p className="mt-1 text-2xl font-bold text-indigo-300">
              {devices.windowsDevices.length}
            </p>
          </div>
          <div className="rounded-2xl border border-slate-800/80 bg-slate-900/50 p-4">
            <p className="text-xs font-medium text-slate-400">Total no WSL2</p>
            <p className="mt-1 text-2xl font-bold text-cyan-300">
              {devices.wslDevices.length}
            </p>
          </div>
        </section>

        {/* WSL2 Devices */}
        <section className="space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="inline-flex items-center gap-2 text-sm font-semibold text-slate-200">
              <HardDrive className="h-4 w-4 text-emerald-400" />
              Dispositivos no WSL2
            </h2>
          </div>

          {devices.wslDevices.length === 0 ? (
            <DeviceCardPlaceholder
              title="Nenhum dispositivo montado no WSL2"
              description="Conecte um pendrive ou HD externo e clique em Montar no WSL na seção abaixo, ou ative o modo Simular para testar a interface."
            />
          ) : (
            <div className="grid gap-3">
              {devices.wslDevices.map((dev) => (
                <WslDeviceCard
                  key={dev.device}
                  device={dev}
                  busy={busy}
                  onUnmount={handleUnmount}
                  onOpenExplorer={handleOpenExplorer}
                />
              ))}
            </div>
          )}
        </section>

        {/* Windows Devices */}
        <section className="space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="inline-flex items-center gap-2 text-sm font-semibold text-slate-200">
              <Usb className="h-4 w-4 text-indigo-400" />
              Dispositivos USB no Windows (usbipd-win)
            </h2>
          </div>

          {devices.windowsDevices.length === 0 ? (
            <DeviceCardPlaceholder
              title="Nenhum armazenamento USB adicional no Windows"
              description="Pendrives e HDs externos conectados ao Windows aparecerão aqui automaticamente após clicar em Atualizar."
            />
          ) : (
            <div className="grid gap-3">
              {devices.windowsDevices.map((dev) => (
                <WindowsDeviceCard
                  key={dev.busid}
                  device={dev}
                  busy={busy}
                  onBind={handleBind}
                  onMount={handleMount}
                />
              ))}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
