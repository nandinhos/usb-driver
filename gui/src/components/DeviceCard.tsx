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
import type { WindowsDevice, WslDevice } from '../types/usb';

interface WslDeviceCardProps {
  device: WslDevice;
  busy: boolean;
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
  onUnmount,
  onOpenExplorer,
}: WslDeviceCardProps) {
  const isMounted = device.status === 'mounted';
  const fsStyle =
    FS_BADGE_COLORS[device.fstype.toLowerCase()] ??
    'border-slate-700 bg-slate-800/80 text-slate-300';

  return (
    <article className="group rounded-2xl border border-slate-800/90 bg-slate-900/70 p-4 transition-all hover:border-slate-700 hover:bg-slate-900/90">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div className="flex items-start gap-3.5">
          <div
            className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border ${
              isMounted
                ? 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400'
                : 'border-cyan-500/30 bg-cyan-500/10 text-cyan-400'
            }`}
          >
            <HardDrive className="h-5 w-5" />
          </div>

          <div className="space-y-1">
            <div className="flex flex-wrap items-center gap-2">
              <h3 className="text-sm font-semibold text-slate-100">
                {device.label || device.device}
              </h3>
              <span className={`rounded-md border px-2 py-0.5 text-[11px] font-semibold uppercase ${fsStyle}`}>
                {device.fstype}
              </span>
              <span className="rounded-md border border-slate-800 bg-slate-950/70 px-2 py-0.5 text-[11px] font-medium text-slate-400">
                {device.size}
              </span>
            </div>

            <div className="flex flex-wrap items-center gap-2 text-xs text-slate-400">
              <code className="text-slate-300">{device.device}</code>
              {isMounted && device.mountPoint && (
                <>
                  <span>•</span>
                  <span className="inline-flex items-center gap-1 text-emerald-300">
                    <CheckCircle2 className="h-3.5 w-3.5" />
                    {device.mountPoint}
                  </span>
                </>
              )}
              {device.status === 'available' && (
                <span className="text-cyan-300">Pronto para montar</span>
              )}
              {device.status === 'in_use' && (
                <span className="inline-flex items-center gap-1 text-amber-300">
                  <ShieldAlert className="h-3.5 w-3.5" />
                  Em uso por outro ponto ({device.mountPoint})
                </span>
              )}
            </div>
          </div>
        </div>

        {isMounted && device.mountPoint && (
          <div className="flex flex-wrap items-center gap-2">
            <button
              type="button"
              disabled={busy}
              onClick={() => onOpenExplorer(device.mountPoint)}
              className="inline-flex items-center gap-1.5 rounded-xl border border-slate-700 bg-slate-800/80 px-3 py-2 text-xs font-medium text-slate-200 transition hover:border-cyan-500/40 hover:bg-slate-800 disabled:opacity-50"
            >
              <FolderOpen className="h-3.5 w-3.5 text-cyan-400" />
              Abrir Pasta
            </button>
            <button
              type="button"
              disabled={busy}
              onClick={() => onUnmount(device.mountPoint, true)}
              className="inline-flex items-center gap-1.5 rounded-xl border border-rose-500/30 bg-rose-500/15 px-3 py-2 text-xs font-semibold text-rose-200 transition hover:bg-rose-500/25 disabled:opacity-50"
            >
              <Power className="h-3.5 w-3.5" />
              Ejetar com Segurança
            </button>
          </div>
        )}
      </div>
    </article>
  );
}

interface WindowsDeviceCardProps {
  device: WindowsDevice;
  busy: boolean;
  onBind: (busid: string) => void;
  onMount: (busid: string) => void;
}

export function WindowsDeviceCard({
  device,
  busy,
  onBind,
  onMount,
}: WindowsDeviceCardProps) {
  const needsBind = device.state === 'NotShared';
  const isAttached = device.state === 'Attached';

  return (
    <article className="rounded-2xl border border-slate-800/90 bg-slate-900/70 p-4 transition-all hover:border-slate-700 hover:bg-slate-900/90">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div className="flex items-start gap-3.5">
          <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-indigo-500/30 bg-indigo-500/10 text-indigo-300">
            <Usb className="h-5 w-5" />
          </div>

          <div className="space-y-1">
            <div className="flex flex-wrap items-center gap-2">
              <h3 className="text-sm font-semibold text-slate-100">
                {device.description || 'Dispositivo USB de Armazenamento'}
              </h3>
              <span
                className={`rounded-md border px-2 py-0.5 text-[11px] font-semibold ${
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

            <div className="flex flex-wrap items-center gap-2 text-xs text-slate-400">
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

        <div className="flex items-center gap-2">
          {needsBind ? (
            <button
              type="button"
              disabled={busy}
              onClick={() => onBind(device.busid)}
              className="inline-flex items-center gap-1.5 rounded-xl border border-amber-500/30 bg-amber-500/15 px-3.5 py-2 text-xs font-semibold text-amber-200 transition hover:bg-amber-500/25 disabled:opacity-50"
            >
              <Lock className="h-3.5 w-3.5" />
              Compartilhar (UAC)
            </button>
          ) : (
            <button
              type="button"
              disabled={busy}
              onClick={() => onMount(device.busid)}
              className="inline-flex items-center gap-1.5 rounded-xl border border-cyan-500/30 bg-cyan-500/20 px-3.5 py-2 text-xs font-semibold text-cyan-100 transition hover:bg-cyan-500/30 disabled:opacity-50"
            >
              <Play className="h-3.5 w-3.5" />
              Montar no WSL
            </button>
          )}
        </div>
      </div>
    </article>
  );
}
