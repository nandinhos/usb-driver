export interface HealthCheckResult {
  ok: boolean;
  wsl: boolean;
  usbipd: {
    installed: boolean;
    version: string;
  };
  ntfs3g: boolean;
  mountPoint: string;
}

export interface WslDevice {
  device: string;
  fstype: string;
  label: string;
  size: string;
  mountPoint: string;
  status: 'mounted' | 'available' | 'in_use';
}

export interface WindowsDevice {
  busid: string;
  vidpid: string;
  description: string;
  state: 'Attached' | 'Shared' | 'NotShared' | string;
}

export interface DeviceListResult {
  wslDevices: WslDevice[];
  windowsDevices: WindowsDevice[];
}

export interface MountStatusItem {
  device: string;
  target: string;
  fstype: string;
}

export interface MountStatusResult {
  mountPoint: string;
  mounts: MountStatusItem[];
}

export interface ActionResult {
  ok: boolean;
  message?: string;
  simulated?: boolean;
  busid?: string;
  device?: string;
  mountPoint?: string;
  unmounted?: string | string[];
  needsBind?: boolean;
}

export interface UsbDriverApi {
  getAppInfo: () => Promise<{ version: string; platform: string; simulate: boolean }>;
  setSimulateMode: (enabled: boolean) => Promise<boolean>;
  checkHealth: () => Promise<HealthCheckResult>;
  listDevices: () => Promise<DeviceListResult>;
  getStatus: () => Promise<MountStatusResult>;
  mountDevice: (busid?: string) => Promise<ActionResult>;
  unmountDevice: (targetPath: string, options?: { force?: boolean; eject?: boolean }) => Promise<ActionResult>;
  bindDevice: (busid: string) => Promise<ActionResult>;
  openInExplorer: (wslMountPath: string) => Promise<ActionResult>;
}

declare global {
  interface Window {
    usbDriver: UsbDriverApi;
  }
}
