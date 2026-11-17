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

interface UsbipdStateDevice {
  BusId: string | null;
  ClientIPAddress: string | null;
  Description: string | null;
  InstanceId: string | null;
  IsForced: boolean;
  PersistedGuid: string | null;
  StubInstanceId: string | null;
}

interface UsbipdStateOutput {
  Devices?: UsbipdStateDevice[];
}

function cleanUsbipdVersion(raw: string): string {
  return raw ? raw.split('+')[0].trim() : '';
}

function extractVidPid(instanceId: string | null): string {
  if (!instanceId) return '0000:0000';
  const match = instanceId.match(/VID_([0-9A-Fa-f]{4})&PID_([0-9A-Fa-f]{4})/);
  return match ? `${match[1].toLowerCase()}:${match[2].toLowerCase()}` : '0000:0000';
}

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

    try {
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
    } catch (err: unknown) {
      const execErr = err as { stdout?: string; stderr?: string; message?: string };
      if (execErr.stdout) {
        try {
          return parseJsonOutput<T>(execErr.stdout);
        } catch {
          // Segue para erro legível abaixo
        }
      }
      const detail = (execErr.stderr || execErr.message || 'Erro desconhecido').trim();
      throw new Error(detail);
    }
  }

  public async checkHealth() {
    const res = await this.runCliJson<{
      ok: boolean;
      wsl: boolean;
      usbipd: { installed: boolean; version: string };
      ntfs3g: boolean;
      mountPoint: string;
    }>(['check']);

    if (res?.usbipd?.version) {
      res.usbipd.version = cleanUsbipdVersion(res.usbipd.version);
    }
    return res;
  }

  public async listDevices() {
    const base = await this.runCliJson<{
      wslDevices: Array<Record<string, unknown>>;
      windowsDevices: Array<{
        busid: string;
        vidpid: string;
        description: string;
        state: string;
      }>;
    }>(['list']);

    if (process.platform === 'win32' && !this.simulate) {
      try {
        const { stdout } = await execFileAsync(USBIPD_EXE, ['state'], {
          timeout: EXEC_TIMEOUT_MS,
          windowsHide: true,
        });
        const stateData = JSON.parse(stdout) as UsbipdStateOutput;
        const connected = (stateData.Devices || []).filter(
          (d): d is UsbipdStateDevice & { BusId: string } =>
            Boolean(d.BusId && isValidBusid(d.BusId))
        );

        // Prioriza dispositivos de armazenamento; se nenhum casar pelo nome, exibe todos conectados (exceto hubs)
        const storageRegex = /mass storage|armazenamento|uas|scsi|disk|flash|drive|sandisk|kingston|seagate|wd|samsung|crucial|toshiba|ssd|hdd/i;
        const nonHub = connected.filter((d) => !/root hub|generic usb hub/i.test(d.Description || ''));
        const storageOnly = nonHub.filter((d) => storageRegex.test(d.Description || ''));
        const chosen = storageOnly.length > 0 ? storageOnly : nonHub;

        if (chosen.length > 0) {
          base.windowsDevices = chosen.map((d) => ({
            busid: d.BusId,
            vidpid: extractVidPid(d.InstanceId),
            description: d.Description || 'Dispositivo USB',
            state: d.ClientIPAddress ? 'Attached' : d.PersistedGuid ? 'Shared' : 'NotShared',
          }));
        }
      } catch {
        // Mantém resultado vindo do CLI WSL se `usbipd state` falhar
      }
    }

    return base;
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
        // Aguarda kernel do WSL2 registrar o novo bloco /dev/sdX antes de montar
        await new Promise((r) => setTimeout(r, 800));
      }
      return this.runCliJson(['up', '--all']);
    }
    return this.runCliJson(['up', '--all']);
  }

  public async detachDevice(busid: string) {
    if (!isValidBusid(busid)) {
      return { ok: false, message: `BUSID inválido: ${busid}` };
    }
    if (this.simulate) {
      return { ok: true, simulated: true, busid, message: 'Dispositivo desanexado (simulado)' };
    }
    if (process.platform !== 'win32') {
      return { ok: false, message: 'Detach direto disponível apenas no Windows' };
    }
    await execFileAsync(USBIPD_EXE, ['detach', '--busid', busid], {
      timeout: EXEC_TIMEOUT_MS,
      windowsHide: true,
    });
    return { ok: true, busid, message: `Dispositivo ${busid} desanexado do WSL` };
  }

  public async unmountDevice(
    targetPath: string,
    options: { force?: boolean; eject?: boolean } = {}
  ) {
    if (targetPath === '__ALL__') {
      const args = ['down'];
      if (options.force) args.push('--force');
      if (options.eject) args.push('--eject');
      return this.runCliJson(args);
    }
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
