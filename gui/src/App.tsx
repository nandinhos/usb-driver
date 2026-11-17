import { useCallback, useEffect, useState } from 'react';
import {
  CheckCircle2,
  FlaskConical,
  Globe,
  HardDrive,
  Play,
  Power,
  RefreshCw,
  Usb,
  XCircle,
} from 'lucide-react';
import { DeviceCardPlaceholder } from './components/EmptyState';
import { WindowsDeviceCard, WslDeviceCard } from './components/DeviceCard';
import { HealthBanner } from './components/HealthBanner';
import { TRANSLATIONS, type Locale } from './i18n/translations';
import type { ActionResult, DeviceListResult, HealthCheckResult } from './types/usb';

interface ToastState {
  ok: boolean;
  text: string;
}

export default function App() {
  const [locale, setLocale] = useState<Locale>(() => {
    const saved = typeof window !== 'undefined' ? localStorage.getItem('usb-driver-locale') : null;
    return saved === 'en-US' ? 'en-US' : 'pt-BR';
  });
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

  const t = TRANSLATIONS[locale];
  const hasBridge = typeof window !== 'undefined' && Boolean(window.usbDriver);

  const handleSetLocale = (next: Locale) => {
    setLocale(next);
    localStorage.setItem('usb-driver-locale', next);
  };

  const notify = useCallback(
    (res: ActionResult, fallbackSuccess: string) => {
      setToast({
        ok: res.ok,
        text: res.message || (res.ok ? fallbackSuccess : t.actionError),
      });
    },
    [t.actionError]
  );

  // Auto-dismiss discreto para todos os avisos após 4s
  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(null), 4000);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const refreshAll = useCallback(async () => {
    if (!hasBridge) {
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      const [hRes, dRes] = await Promise.allSettled([
        window.usbDriver.checkHealth(),
        window.usbDriver.listDevices(),
      ]);

      if (hRes.status === 'fulfilled') {
        setHealth(hRes.value);
      } else {
        setHealth({
          ok: false,
          wsl: false,
          usbipd: { installed: false, version: '' },
          ntfs3g: false,
          mountPoint: '/mnt/usb-driver',
        });
        setToast({
          ok: false,
          text: `${hRes.reason instanceof Error ? hRes.reason.message : String(hRes.reason)}`,
        });
      }

      if (dRes.status === 'fulfilled') {
        setDevices(dRes.value);
      } else {
        setDevices({ wslDevices: [], windowsDevices: [] });
      }
    } finally {
      setLoading(false);
    }
  }, [hasBridge]);

  const silentRefresh = useCallback(async () => {
    if (!hasBridge) return;
    try {
      const d = await window.usbDriver.listDevices();
      setDevices(d);
    } catch {
      // Ignora falhas transitórias durante polling silencioso
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

  // Atualização automática em tempo real a cada 3s quando a janela estiver visível
  useEffect(() => {
    if (!hasBridge) return;
    const id = window.setInterval(() => {
      if (!busy && !loading && document.visibilityState === 'visible') {
        silentRefresh();
      }
    }, 3000);
    return () => window.clearInterval(id);
  }, [hasBridge, busy, loading, silentRefresh]);

  const handleToggleSimulate = async () => {
    if (!hasBridge || busy) return;
    const next = await window.usbDriver.setSimulateMode(!simulate);
    setSimulate(next);
    setToast({ ok: true, text: next ? t.simOnMsg : t.simOffMsg });
    await refreshAll();
  };

  const syncAfterAction = useCallback(async () => {
    await refreshAll();
    window.setTimeout(() => {
      refreshAll().catch(() => undefined);
    }, 1200);
  }, [refreshAll]);

  const handleMount = async (busid?: string) => {
    if (!hasBridge || busy) return;
    setBusy(true);
    try {
      const res = await window.usbDriver.mountDevice(busid);
      notify(res, t.mountSuccess);
      await syncAfterAction();
    } finally {
      setBusy(false);
    }
  };

  const handleUnmount = async (mountPoint: string, eject: boolean) => {
    if (!hasBridge || busy) return;
    setBusy(true);
    try {
      const res = await window.usbDriver.unmountDevice(mountPoint, { eject });
      notify(res, t.unmountSuccess);
      await syncAfterAction();
    } finally {
      setBusy(false);
    }
  };

  const handleBind = async (busid: string) => {
    if (!hasBridge || busy) return;
    setBusy(true);
    try {
      const res = await window.usbDriver.bindDevice(busid);
      notify(res, t.bindSuccess);
      await syncAfterAction();
    } finally {
      setBusy(false);
    }
  };

  const handleDetach = async (busid: string) => {
    if (!hasBridge || busy) return;
    setBusy(true);
    try {
      const res = await window.usbDriver.detachDevice(busid);
      notify(res, t.unmountSuccess);
      await syncAfterAction();
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
    <div className="flex h-screen flex-col overflow-hidden bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-slate-900 via-slate-950 to-slate-950 text-slate-100">
      <div className="mx-auto flex h-full w-full max-w-6xl flex-col gap-3.5 px-5 py-4">
        {/* Header */}
        <header className="flex shrink-0 flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-cyan-500/30 bg-gradient-to-br from-cyan-500/20 to-indigo-500/20 shadow-lg shadow-cyan-500/10">
              <Usb className="h-5 w-5 text-cyan-300" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-base font-bold tracking-tight text-white">USB Driver</h1>
                <span className="rounded-full border border-slate-800 bg-slate-900 px-2 py-0.5 text-[10px] font-medium text-slate-400">
                  v{version}
                </span>
              </div>
              <p className="text-xs text-slate-400">{t.subtitle}</p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {/* Idioma PT-BR / EN-US */}
            <div className="inline-flex items-center rounded-lg border border-slate-800 bg-slate-900/90 p-0.5 text-[11px] font-semibold">
              <Globe className="mx-1.5 h-3.5 w-3.5 text-slate-400" />
              <button
                type="button"
                onClick={() => handleSetLocale('pt-BR')}
                className={`rounded-md px-2 py-1 transition ${
                  locale === 'pt-BR' ? 'bg-cyan-500/20 text-cyan-200' : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                PT-BR
              </button>
              <button
                type="button"
                onClick={() => handleSetLocale('en-US')}
                className={`rounded-md px-2 py-1 transition ${
                  locale === 'en-US' ? 'bg-cyan-500/20 text-cyan-200' : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                EN-US
              </button>
            </div>

            <button
              type="button"
              onClick={() => handleMount()}
              disabled={!hasBridge || busy}
              className="inline-flex items-center gap-1.5 rounded-lg border border-cyan-500/30 bg-cyan-500/20 px-3 py-1.5 text-xs font-semibold text-cyan-100 transition hover:bg-cyan-500/30 disabled:opacity-50"
            >
              <Play className="h-3.5 w-3.5" />
              {t.mountAll}
            </button>

            <button
              type="button"
              onClick={() => handleUnmount('__ALL__', true)}
              disabled={!hasBridge || busy || mountedCount === 0}
              className="inline-flex items-center gap-1.5 rounded-lg border border-rose-500/30 bg-rose-500/15 px-3 py-1.5 text-xs font-semibold text-rose-200 transition hover:bg-rose-500/25 disabled:opacity-40"
            >
              <Power className="h-3.5 w-3.5" />
              {t.ejectAll}
            </button>

            <button
              type="button"
              onClick={handleToggleSimulate}
              disabled={!hasBridge || busy}
              className={`inline-flex items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-xs font-medium transition disabled:opacity-50 ${
                simulate
                  ? 'border-cyan-500/40 bg-cyan-500/15 text-cyan-200'
                  : 'border-slate-800 bg-slate-900/80 text-slate-300 hover:border-slate-700'
              }`}
            >
              <FlaskConical className="h-3.5 w-3.5" />
              {simulate ? t.simulateOn : t.simulateOff}
            </button>

            <button
              type="button"
              onClick={refreshAll}
              disabled={!hasBridge || loading || busy}
              className="inline-flex items-center gap-1.5 rounded-lg border border-slate-700 bg-slate-800/80 px-3 py-1.5 text-xs font-semibold text-slate-100 transition hover:border-cyan-500/40 hover:bg-slate-800 disabled:opacity-50"
            >
              <RefreshCw className={`h-3.5 w-3.5 ${loading ? 'animate-spin' : ''}`} />
              {t.refresh}
            </button>
          </div>
        </header>

        {/* Health Banner */}
        <HealthBanner health={health} simulate={simulate} t={t} />

        {/* Toast Flutuante Discreto (Canto Superior Direito) */}
        {toast && (
          <div
            role="status"
            aria-live="polite"
            className={`fixed top-4 right-4 z-50 flex max-w-sm items-center gap-2.5 rounded-xl border px-3.5 py-2.5 text-xs font-medium shadow-2xl backdrop-blur-md transition-all ${
              toast.ok
                ? 'border-emerald-500/30 bg-slate-900/90 text-emerald-200 shadow-emerald-950/40'
                : 'border-rose-500/35 bg-slate-900/95 text-rose-200 shadow-rose-950/40'
            }`}
          >
            {toast.ok ? (
              <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-400" />
            ) : (
              <XCircle className="h-4 w-4 shrink-0 text-rose-400" />
            )}
            <span className="leading-snug">{toast.text}</span>
            <button
              type="button"
              onClick={() => setToast(null)}
              aria-label={t.close}
              className="ml-1 shrink-0 rounded p-0.5 text-slate-400 transition hover:bg-slate-800 hover:text-slate-100"
            >
              ✕
            </button>
          </div>
        )}

        {/* KPI Strip */}
        <section className="grid shrink-0 grid-cols-3 gap-3">
          <div className="flex items-center justify-between rounded-xl border border-slate-800/80 bg-slate-900/50 px-4 py-2.5">
            <span className="text-xs font-medium text-slate-400">{t.kpiMounted}</span>
            <span className="text-xl font-bold text-emerald-300">{mountedCount}</span>
          </div>
          <div className="flex items-center justify-between rounded-xl border border-slate-800/80 bg-slate-900/50 px-4 py-2.5">
            <span className="text-xs font-medium text-slate-400">{t.kpiWindows}</span>
            <span className="text-xl font-bold text-indigo-300">
              {devices.windowsDevices.length}
            </span>
          </div>
          <div className="flex items-center justify-between rounded-xl border border-slate-800/80 bg-slate-900/50 px-4 py-2.5">
            <span className="text-xs font-medium text-slate-400">{t.kpiTotalWsl}</span>
            <span className="text-xl font-bold text-cyan-300">
              {devices.wslDevices.length}
            </span>
          </div>
        </section>

        {/* Main 2-Column Responsive Grid (no page overflow) */}
        <div className="grid min-h-0 flex-1 grid-cols-1 gap-4 lg:grid-cols-2">
          {/* WSL2 Column */}
          <section className="flex min-h-0 flex-col rounded-2xl border border-slate-800/70 bg-slate-900/30 p-3.5">
            <h2 className="mb-2.5 inline-flex shrink-0 items-center gap-2 text-xs font-semibold tracking-wide text-slate-300 uppercase">
              <HardDrive className="h-4 w-4 text-emerald-400" />
              {t.sectionWsl}
            </h2>

            <div className="min-h-0 flex-1 space-y-2.5 overflow-y-auto pr-1">
              {devices.wslDevices.length === 0 ? (
                <DeviceCardPlaceholder title={t.emptyWslTitle} description={t.emptyWslDesc} />
              ) : (
                devices.wslDevices.map((dev) => (
                  <WslDeviceCard
                    key={dev.device}
                    device={dev}
                    busy={busy}
                    t={t}
                    onMount={() => handleMount(dev.device)}
                    onUnmount={handleUnmount}
                    onOpenExplorer={handleOpenExplorer}
                  />
                ))
              )}
            </div>
          </section>

          {/* Windows Column */}
          <section className="flex min-h-0 flex-col rounded-2xl border border-slate-800/70 bg-slate-900/30 p-3.5">
            <h2 className="mb-2.5 inline-flex shrink-0 items-center gap-2 text-xs font-semibold tracking-wide text-slate-300 uppercase">
              <Usb className="h-4 w-4 text-indigo-400" />
              {t.sectionWindows}
            </h2>

            <div className="min-h-0 flex-1 space-y-2.5 overflow-y-auto pr-1">
              {devices.windowsDevices.length === 0 ? (
                <DeviceCardPlaceholder title={t.emptyWinTitle} description={t.emptyWinDesc} />
              ) : (
                devices.windowsDevices.map((dev) => (
                  <WindowsDeviceCard
                    key={dev.busid}
                    device={dev}
                    busy={busy}
                    isMountedInWsl={mountedCount > 0}
                    t={t}
                    onBind={handleBind}
                    onMount={handleMount}
                    onDetach={handleDetach}
                    onUnmountWsl={() => handleUnmount('__ALL__', true)}
                  />
                ))
              )}
            </div>
          </section>
        </div>
      </div>
    </div>
  );
}
