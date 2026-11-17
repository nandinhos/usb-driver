import { Usb } from 'lucide-react';

interface DeviceCardPlaceholderProps {
  title: string;
  description: string;
}

export function DeviceCardPlaceholder({ title, description }: DeviceCardPlaceholderProps) {
  return (
    <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-slate-800 bg-slate-900/30 px-6 py-8 text-center">
      <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-slate-800 bg-slate-900 text-slate-500">
        <Usb className="h-5 w-5" />
      </div>
      <p className="mt-3 text-sm font-medium text-slate-300">{title}</p>
      <p className="mt-1 max-w-md text-xs text-slate-500">{description}</p>
    </div>
  );
}
