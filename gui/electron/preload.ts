import { contextBridge, ipcRenderer } from 'electron';

const api = {
  getAppInfo: () => ipcRenderer.invoke('usb:app-info'),
  setSimulateMode: (enabled: boolean) => ipcRenderer.invoke('usb:set-simulate', enabled),
  checkHealth: () => ipcRenderer.invoke('usb:check'),
  listDevices: () => ipcRenderer.invoke('usb:list'),
  getStatus: () => ipcRenderer.invoke('usb:status'),
  mountDevice: (busid?: string) => ipcRenderer.invoke('usb:mount', busid),
  unmountDevice: (targetPath: string, options?: { force?: boolean; eject?: boolean }) =>
    ipcRenderer.invoke('usb:unmount', targetPath, options),
  bindDevice: (busid: string) => ipcRenderer.invoke('usb:bind', busid),
  detachDevice: (busid: string) => ipcRenderer.invoke('usb:detach', busid),
  openInExplorer: (wslMountPath: string) => ipcRenderer.invoke('usb:open-explorer', wslMountPath),
};

contextBridge.exposeInMainWorld('usbDriver', api);
