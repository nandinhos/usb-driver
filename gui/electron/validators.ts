const BUSID_REGEX = /^[0-9]+-[0-9]+(\.[0-9]+)*$/;
const SAFE_MOUNT_PATH_REGEX = /^\/mnt\/(usb-driver|bkp-pendrive)(\/[A-Za-z0-9._-]+)?$/;

export function isValidBusid(busid: string): boolean {
  return typeof busid === 'string' && BUSID_REGEX.test(busid.trim());
}

export function isValidMountPath(targetPath: string): boolean {
  if (typeof targetPath !== 'string') return false;
  const trimmed = targetPath.trim().replace(/\/+$/, '');
  if (trimmed.includes('..')) return false;
  return SAFE_MOUNT_PATH_REGEX.test(trimmed);
}

export function buildWslUncPath(distro: string, wslPath: string): string {
  const cleanDistro = distro.replace(/[^A-Za-z0-9._-]/g, '');
  const cleanPath = wslPath.replace(/^\/+/, '').replace(/\//g, '\\');
  if (!cleanDistro || !isValidMountPath(wslPath)) {
    throw new Error('Caminho WSL ou distro inválidos para abertura no Explorer.');
  }
  return `\\\\wsl.localhost\\${cleanDistro}\\${cleanPath}`;
}

export function parseJsonOutput<T>(raw: string): T {
  const trimmed = raw.trim();
  if (!trimmed) {
    throw new Error('Resposta vazia recebida do backend usb-driver.');
  }
  // Em caso de logs extras antes do JSON, captura a última linha JSON válida
  const lines = trimmed.split(/\r?\n/).filter((l) => l.trim().startsWith('{'));
  const candidate = lines.length > 0 ? lines[lines.length - 1] : trimmed;
  return JSON.parse(candidate) as T;
}
