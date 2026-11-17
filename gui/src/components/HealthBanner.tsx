import { AlertTriangle, CheckCircle2, FolderRoot, ShieldCheck } from 'lucide-react';
import type { HealthCheckResult } from '../types/usb';

interface HealthBannerProps {
  health: HealthCheckResult | null;
  simulate: boolean;
}

export function HealthBanner({ health, simulate }: HealthBannerProps) {
  if (!health) {
    return (
      <div className="h-14 animate-pulse rounded-2xl border border-slate-800/80 bg-slate-900/50" />
    );
  }

  const items = [
    { label: 'WSL2', ok: health.wsl, detail: health.wsl ? 'Ativo' : 'Indisponível' },
    {
      label: 'usbipd-win',
      ok: health.usbipd.installed,
      detail: health.usbipd.installed ? `v${health.usbipd.version}` : 'Não instalado',
    },
    { label: 'ntfs-3g', ok: health.ntfs3g, detail: health.ntfs3g ? 'Pronto' : 'Opcional (NTFS)' },
  ];

  return (
    <section className="rounded-2xl border border-slate-800/80 bg-slate-900/60 px-4 py-3 backdrop-blur-md">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap items-center gap-3">
          <span className="inline-flex items-center gap-1.5 text-xs font-medium tracking-wide text-slate-400 uppercase">
            {health.ok ? (
              <ShieldCheck className="h-4 w-4 text-emerald-400" />
            ) : (
              <AlertTriangle className="h-4 w-4 text-amber-400" />
            )}
            Ambiente
          </span>

          {items.map((item) => (
            <div
              key={item.label}
              className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-medium ${
                item.ok
                  ? 'border-emerald-500/20 bg-emerald-500/10 text-emerald-300'
                  : 'border-amber-500/25 bg-amber-500/10 text-amber-300'
              }`}
            >
              <CheckCircle2 className="h-3.5 w-3.5" />
              <span>{item.label}:</span>
              <span className="opacity-85">{item.detail}</span>
            </div>
          ))}

          {simulate && (
            <span className="rounded-full border border-cyan-500/30 bg-cyan-500/10 px-2.5 py-1 text-xs font-medium text-cyan-300">
              Modo Simulação
            </span>
          )}
        </div>

        <div className="inline-flex items-center gap-1.5 text-xs text-slate-400">
          <FolderRoot className="h-3.5 w-3.5 text-slate-500" />
          <code className="rounded bg-slate-950/80 px-2 py-0.5 text-slate-300">
            {health.mountPoint}
          </code>
        </div>
      </div>

      {!health.usbipd.installed && !simulate && (
        <p className="mt-2 text-xs text-amber-300/90">
          Para detectar discos do Windows, instale o usbipd-win no PowerShell (Admin):{' '}
          <code className="rounded bg-slate-950 px-1.5 py-0.5 text-amber-200">
            winget install usbipd
          </code>
        </p>
      )}
    </section>
  );
}
