import { AlertTriangle, CheckCircle2, FolderRoot, ShieldCheck } from 'lucide-react';
import type { TranslationDict } from '../i18n/translations';
import type { HealthCheckResult } from '../types/usb';

interface HealthBannerProps {
  health: HealthCheckResult | null;
  simulate: boolean;
  t: TranslationDict;
}

export function HealthBanner({ health, simulate, t }: HealthBannerProps) {
  if (!health) {
    return (
      <div className="h-11 shrink-0 animate-pulse rounded-xl border border-slate-800/80 bg-slate-900/50" />
    );
  }

  const shortUsbipdVer = health.usbipd.version
    ? health.usbipd.version.split('+')[0]
    : '';

  const items = [
    { label: 'WSL2', ok: health.wsl, detail: health.wsl ? t.wslActive : t.wslUnavailable },
    {
      label: 'usbipd-win',
      ok: health.usbipd.installed,
      detail: health.usbipd.installed ? `v${shortUsbipdVer}` : t.usbipdMissing,
    },
    {
      label: 'ntfs-3g',
      ok: health.ntfs3g,
      detail: health.ntfs3g ? t.ntfsReady : t.ntfsOptional,
    },
  ];

  return (
    <section className="shrink-0 rounded-xl border border-slate-800/80 bg-slate-900/60 px-3.5 py-2.5 backdrop-blur-md">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex flex-wrap items-center gap-2">
          <span className="inline-flex items-center gap-1.5 text-[11px] font-semibold tracking-wider text-slate-400 uppercase">
            {health.ok ? (
              <ShieldCheck className="h-3.5 w-3.5 text-emerald-400" />
            ) : (
              <AlertTriangle className="h-3.5 w-3.5 text-amber-400" />
            )}
            {t.envLabel}
          </span>

          {items.map((item) => (
            <div
              key={item.label}
              className={`inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] font-medium ${
                item.ok
                  ? 'border-emerald-500/20 bg-emerald-500/10 text-emerald-300'
                  : 'border-amber-500/25 bg-amber-500/10 text-amber-300'
              }`}
            >
              <CheckCircle2 className="h-3 w-3 shrink-0" />
              <span>{item.label}:</span>
              <span className="max-w-[140px] truncate opacity-90">{item.detail}</span>
            </div>
          ))}

          {simulate && (
            <span className="rounded-full border border-cyan-500/30 bg-cyan-500/10 px-2 py-0.5 text-[11px] font-medium text-cyan-300">
              {t.simulateBadge}
            </span>
          )}
        </div>

        <div className="inline-flex items-center gap-1.5 text-[11px] text-slate-400">
          <FolderRoot className="h-3.5 w-3.5 text-slate-500" />
          <code className="rounded bg-slate-950/80 px-2 py-0.5 text-slate-300">
            {health.mountPoint}
          </code>
        </div>
      </div>

      {!health.usbipd.installed && !simulate && (
        <p className="mt-1.5 text-[11px] text-amber-300/90">
          {t.installUsbipdHint}{' '}
          <code className="rounded bg-slate-950 px-1.5 py-0.5 text-amber-200">
            winget install usbipd
          </code>
        </p>
      )}
    </section>
  );
}
