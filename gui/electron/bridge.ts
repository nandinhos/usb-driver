import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import path from 'node:path';
import { shell } from 'electron';
import {
  buildWslUncPath,
  isValidBusid,
  isValidMountPath,
  parseJsonOutput,
} from './validators';

const execFileAsync = promisify(execFile);

const USBIPD_EXE = 'C:\\Program Files\\usbipd-win\\usbipd.exe';
const EXEC_TIMEOUT_MS = 30_000;

export interface BridgeConfig {
  simulate: boolean;
  wslDistro?: string;
}

export class UsbDriverBridge {
  private simulate: boolean;
  private wslDistro?: string;

  constructor(config: BridgeConfig = { simulate: false }) {
    this.simulate = config.simulate;
    this.wslDistro = config.wslDistro;
  }

  public isSimulate(): boolean {
    return this.simulate;
  }

  public setSimulate(enabled: boolean): boolean {
    this.simulate = Boolean(enabled);
    return this.simulate;
  }

  private getLocalCliPath(): string {
    // Em dev dentro do WSL/Linux, aponta para ../bin/usb-driver
    return path.resolve(__dirname, '..', '..', 'bin', 'usb-driver');
  }

  private async runCliJson<T>(args: string[]): Promise<T> {
    const cliArgs = [...(this.simulate ? ['--simulate'] : []), '--json', ...args];

    if (process.platform === 'win32') {
      const wslArgs: string[] = [];
      if (this.wslDistro) {
        wslArgs.push('-d', this.wslDistro);
      }
      wslArgs.push('--', 'usb-driver', ...cliArgs);

      const { stdout } = await execFileAsync('wsl.exe', wslArgs, {
        timeout: EXEC_TIMEOUT_MS,
        windowsHide: true,
      });
      return parseJsonOutput<T>(stdout);
    }

    // Execução local em ambiente Linux/WSL (útil para dev & --simulate)
    const { stdout } = await execFileAsync(this.getLocalCliPath(), cliArgs, {
      timeout: EXEC_TIMEOUT_MS,
    });
    return parseJsonOutput<T>(stdout);
  }

  public async checkHealth() {
    return this.runCliJson(['check']);
  }

  public async listDevices() {
    return this.runCliJson(['list']);
  }

  public async getStatus() {
    return this.runCliJson(['status']);
  }

  public async mountDevice(busid?: string) {
    if (busid !== undefined && busid !== '') {
      if (!isValidBusid(busid)) {
        return { ok: false, message: `BUSID inválido: ${busid}` };
      }
      if (process.platform === 'win32' && !this.simulate) {
        await execFileAsync(USBIPD_EXE, ['attach', '--wsl', '--busid', busid], {
          timeout: EXEC_TIMEOUT_MS,
          windowsHide: true,
        }).catch(() => undefined);
      }
      return this.runCliJson(['up', '--all']);
    }
    return this.runCliJson(['up', '--all']);
  }

  public async unmountDevice(
    targetPath: string,
    options: { force?: boolean; eject?: boolean } = {}
  ) {
    if (!isValidMountPath(targetPath)) {
      return { ok: false, message: `Caminho de montagem inválido: ${targetPath}` };
    }
    const args = ['down', targetPath];
    if (options.force) args.push('--force');
    if (options.eject) args.push('--eject');
    return this.runCliJson(args);
  }

  public async bindDevice(busid: string) {
    if (!isValidBusid(busid)) {
      return { ok: false, message: `BUSID inválido: ${busid}` };
    }
    if (this.simulate) {
      return { ok: true, simulated: true, busid, message: 'Bind simulado com sucesso' };
    }
    if (process.platform !== 'win32') {
      return { ok: false, message: 'Bind UAC disponível apenas no host Windows' };
    }

    // UAC pontual apenas para `usbipd bind --busid <id> --force` após validação estrita de BUSID
    await execFileAsync(
      'powershell.exe',
      [
        '-NoProfile',
        '-Command',
        `Start-Process -FilePath '${USBIPD_EXE}' -ArgumentList 'bind','--busid','${busid}','--force' -Verb RunAs -Wait`,
      ],
      { timeout: 60_000, windowsHide: true }
    );
    return { ok: true, busid, message: `Dispositivo ${busid} compartilhado com o WSL` };
  }

  public async openInExplorer(wslMountPath: string) {
    if (!isValidMountPath(wslMountPath)) {
      return { ok: false, message: `Caminho não permitido: ${wslMountPath}` };
    }
    if (process.platform === 'win32') {
      const distro = this.wslDistro || process.env.WSL_DISTRO_NAME || 'Ubuntu';
      const unc = buildWslUncPath(distro, wslMountPath);
      const err = await shell.openPath(unc);
      return err ? { ok: false, message: err } : { ok: true, mountPoint: unc };
    }
    const err = await shell.openPath(wslMountPath);
    return err ? { ok: false, message: err } : { ok: true, mountPoint: wslMountPath };
  }
}
