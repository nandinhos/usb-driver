import { app, BrowserWindow, ipcMain, Menu, nativeImage, Tray } from 'electron';
import path from 'node:path';
import { UsbDriverBridge } from './bridge';

let mainWindow: BrowserWindow | null = null;
let tray: Tray | null = null;

const isDev = !app.isPackaged;
const bridge = new UsbDriverBridge({
  simulate: process.env.USB_DRIVER_SIMULATE === '1',
  wslDistro: process.env.USB_DRIVER_DISTRO,
});

function createWindow(): BrowserWindow {
  const win = new BrowserWindow({
    width: 1080,
    height: 720,
    minWidth: 860,
    minHeight: 600,
    backgroundColor: '#020617',
    title: 'USB Driver — WSL2 Storage Manager',
    show: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      webSecurity: true,
    },
  });

  // Bloqueia navegação externa e abertura de novas janelas
  win.webContents.setWindowOpenHandler(() => ({ action: 'deny' }));
  win.webContents.on('will-navigate', (event, url) => {
    const allowedOrigin = isDev ? 'http://localhost:5173' : 'file://';
    if (!url.startsWith(allowedOrigin)) {
      event.preventDefault();
    }
  });

  win.once('ready-to-show', () => win.show());

  if (isDev && process.env.VITE_DEV_SERVER_URL) {
    win.loadURL(process.env.VITE_DEV_SERVER_URL);
  } else {
    win.loadFile(path.join(__dirname, '..', 'dist', 'index.html'));
  }

  win.on('closed', () => {
    mainWindow = null;
  });

  return win;
}

function createTray(): void {
  const emptyIcon = nativeImage.createEmpty();
  tray = new Tray(emptyIcon);
  tray.setToolTip('USB Driver — WSL2');

  const menu = Menu.buildFromTemplate([
    {
      label: 'Abrir Painel USB Driver',
      click: () => {
        if (!mainWindow) {
          mainWindow = createWindow();
        } else {
          mainWindow.show();
          mainWindow.focus();
        }
      },
    },
    { type: 'separator' },
    {
      label: 'Sair',
      click: () => app.quit(),
    },
  ]);

  tray.setContextMenu(menu);
  tray.on('double-click', () => {
    if (mainWindow) {
      mainWindow.show();
      mainWindow.focus();
    }
  });
}

function registerIpcHandlers(): void {
  ipcMain.handle('usb:app-info', () => ({
    version: app.getVersion(),
    platform: process.platform,
    simulate: bridge.isSimulate(),
  }));

  ipcMain.handle('usb:set-simulate', (_event, enabled: boolean) => {
    return bridge.setSimulate(enabled);
  });

  ipcMain.handle('usb:check', () => bridge.checkHealth());
  ipcMain.handle('usb:list', () => bridge.listDevices());
  ipcMain.handle('usb:status', () => bridge.getStatus());
  ipcMain.handle('usb:mount', (_event, busid?: string) => bridge.mountDevice(busid));
  ipcMain.handle(
    'usb:unmount',
    (_event, targetPath: string, options?: { force?: boolean; eject?: boolean }) =>
      bridge.unmountDevice(targetPath, options)
  );
  ipcMain.handle('usb:bind', (_event, busid: string) => bridge.bindDevice(busid));
  ipcMain.handle('usb:open-explorer', (_event, wslMountPath: string) =>
    bridge.openInExplorer(wslMountPath)
  );
}

app.whenReady().then(() => {
  registerIpcHandlers();
  mainWindow = createWindow();
  createTray();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      mainWindow = createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
