import {
  CheckCircle2,
  FolderOpen,
  HardDrive,
  Lock,
  Play,
  Power,
  ShieldAlert,
  Usb,
} from 'lucide-react';
import type { TranslationDict } from '../i18n/translations';
import type { WindowsDevice, WslDevice } from '../types/usb';

interface WslDeviceCardProps {
  device: WslDevice;
  busy: boolean;
  t: TranslationDict;
  onMount: () => void;
  onUnmount: (mountPoint: string, eject: boolean) => void;
  onOpenExplorer: (mountPoint: string) => void;
}

const FS_BADGE_COLORS: Record<string, string> = {
  ext4: 'border-violet-500/30 bg-violet-500/10 text-violet-300',
  ntfs: 'border-sky-500/30 bg-sky-500/10 text-sky-300',
  exfat: 'border-teal-500/30 bg-teal-500/10 text-teal-300',
  vfat: 'border-amber-500/30 bg-amber-500/10 text-amber-300',
};

export function WslDeviceCard({
  device,
  busy,
  t,
  onMount,
  onUnmount,
  onOpenExplorer,
}: WslDeviceCardProps) {
  const isMounted = device.status === 'mounted';
  const fsStyle =
    FS_BADGE_COLORS[device.fstype.toLowerCase()] ??
    'border-slate-700 bg-slate-800/80 text-slate-300';

  return (
    <article className="group rounded-xl border border-slate-800/90 bg-slate-900/70 p-3.5 transition-all hover:border-slate-700 hover:bg-slate-900/90">
      <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
        <div className="flex min-w-0 items-start gap-3">
          <div
            className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border ${
              isMounted
                ? 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400'
                : 'border-cyan-500/30 bg-cyan-500/10 text-cyan-400'
            }`}
          >
            <HardDrive className="h-4 w-4" />
          </div>

          <div className="min-w-0 space-y-1">
            <div className="flex flex-wrap items-center gap-1.5">
              <h3 className="truncate text-sm font-semibold text-slate-100">
                {device.label || device.device}
              </h3>
              <span className={`rounded border px-1.5 py-0.5 text-[10px] font-semibold uppercase ${fsStyle}`}>
                {device.fstype}
              </span>
              <span className="rounded border border-slate-800 bg-slate-950/70 px-1.5 py-0.5 text-[10px] font-medium text-slate-400">
                {device.size}
              </span>
            </div>

            <div className="flex flex-wrap items-center gap-1.5 text-xs text-slate-400">
              <code className="text-slate-300">{device.device}</code>
              {isMounted && device.mountPoint && (
                <>
                  <span>•</span>
                  <span className="inline-flex items-center gap-1 truncate text-emerald-300">
                    <CheckCircle2 className="h-3 w-3 shrink-0" />
                    <span className="truncate">{device.mountPoint}</span>
                  </span>
                </>
              )}
              {device.status === 'available' && (
                <span className="text-cyan-300">{t.readyToMount}</span>
              )}
              {device.status === 'in_use' && (
                <span className="inline-flex items-center gap-1 text-amber-300">
                  <ShieldAlert className="h-3 w-3 shrink-0" />
                  {t.inUseOther} ({device.mountPoint})
                </span>
              )}
            </div>
          </div>
        </div>

        <div className="flex shrink-0 flex-wrap items-center gap-2">
          {device.status === 'available' && (
            <button
              type="button"
              disabled={busy}
              onClick={onMount}
              className="inline-flex items-center gap-1.5 rounded-lg border border-cyan-500/30 bg-cyan-500/20 px-3 py-1.5 text-xs font-semibold text-cyan-100 transition hover:bg-cyan-500/30 disabled:opacity-50"
            >
              <Play className="h-3.5 w-3.5" />
              {t.mountLocal}
            </button>
          )}
          {isMounted && device.mountPoint && (
            <>
              <button
                type="button"
                disabled={busy}
                onClick={() => onOpenExplorer(device.mountPoint)}
                className="inline-flex items-center gap-1.5 rounded-lg border border-slate-700 bg-slate-800/80 px-2.5 py-1.5 text-xs font-medium text-slate-200 transition hover:border-cyan-500/40 hover:bg-slate-800 disabled:opacity-50"
              >
                <FolderOpen className="h-3.5 w-3.5 text-cyan-400" />
                {t.openFolder}
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={() => onUnmount(device.mountPoint, true)}
                className="inline-flex items-center gap-1.5 rounded-lg border border-rose-500/30 bg-rose-500/15 px-2.5 py-1.5 text-xs font-semibold text-rose-200 transition hover:bg-rose-500/25 disabled:opacity-50"
              >
                <Power className="h-3.5 w-3.5" />
                {t.ejectSafe}
              </button>
            </>
          )}
        </div>
      </div>
    </article>
  );
}

interface WindowsDeviceCardProps {
  device: WindowsDevice;
  busy: boolean;
  t: TranslationDict;
  onBind: (busid: string) => void;
  onMount: (busid: string) => void;
  onDetach: (busid: string) => void;
}

export function WindowsDeviceCard({
  device,
  busy,
  t,
  onBind,
  onMount,
  onDetach,
}: WindowsDeviceCardProps) {
  const needsBind = device.state === 'NotShared';
  const isAttached = device.state === 'Attached';

  return (
    <article className="rounded-xl border border-slate-800/90 bg-slate-900/70 p-3.5 transition-all hover:border-slate-700 hover:bg-slate-900/90">
      <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
        <div className="flex min-w-0 items-start gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-indigo-500/30 bg-indigo-500/10 text-indigo-300">
            <Usb className="h-4 w-4" />
          </div>

          <div className="min-w-0 space-y-1">
            <div className="flex flex-wrap items-center gap-1.5">
              <h3 className="truncate text-sm font-semibold text-slate-100">
                {device.description || 'USB Storage'}
              </h3>
              <span
                className={`rounded border px-1.5 py-0.5 text-[10px] font-semibold ${
                  isAttached
                    ? 'border-emerald-500/30 bg-emerald-500/10 text-emerald-300'
                    : needsBind
                      ? 'border-amber-500/30 bg-amber-500/10 text-amber-300'
                      : 'border-cyan-500/30 bg-cyan-500/10 text-cyan-300'
                }`}
              >
                {device.state}
              </span>
            </div>

            <div className="flex flex-wrap items-center gap-1.5 text-xs text-slate-400">
              <span>
                BUSID: <code className="text-slate-200">{device.busid}</code>
              </span>
              <span>•</span>
              <span>
                VID:PID: <code className="text-slate-300">{device.vidpid}</code>
              </span>
            </div>
          </div>
        </div>

        <div className="flex shrink-0 items-center gap-2">
          {needsBind ? (
            <button
              type="button"
              disabled={busy}
              onClick={() => onBind(device.busid)}
              className="inline-flex items-center gap-1.5 rounded-lg border border-amber-500/30 bg-amber-500/15 px-3 py-1.5 text-xs font-semibold text-amber-200 transition hover:bg-amber-500/25 disabled:opacity-50"
            >
              <Lock className="h-3.5 w-3.5" />
              {t.shareUac}
            </button>
          ) : (
            <>
              <button
                type="button"
                disabled={busy}
                onClick={() => onMount(device.busid)}
                className="inline-flex items-center gap-1.5 rounded-lg border border-cyan-500/30 bg-cyan-500/20 px-3 py-1.5 text-xs font-semibold text-cyan-100 transition hover:bg-cyan-500/30 disabled:opacity-50"
              >
                <Play className="h-3.5 w-3.5" />
                {t.mountWsl}
              </button>
              {isAttached && (
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => onDetach(device.busid)}
                  className="inline-flex items-center gap-1.5 rounded-lg border border-rose-500/30 bg-rose-500/15 px-2.5 py-1.5 text-xs font-semibold text-rose-200 transition hover:bg-rose-500/25 disabled:opacity-50"
                >
                  <Power className="h-3.5 w-3.5" />
                  {t.detachWsl}
                </button>
              )}
            </>
          )}
        </div>
      </div>
    </article>
  );
}
