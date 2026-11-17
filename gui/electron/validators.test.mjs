import test from 'node:test';
import assert from 'node:assert/strict';
import {
  buildWslUncPath,
  isValidBusid,
  isValidDeviceNode,
  isValidMountPath,
  parseJsonOutput,
} from '../dist-electron/validators.js';

test('isValidBusid aceita BUSIDs válidos e bloqueia injeções', () => {
  assert.equal(isValidBusid('2-16'), true);
  assert.equal(isValidBusid('1-2.3'), true);
  assert.equal(isValidBusid('1-1; calc.exe'), false);
  assert.equal(isValidBusid('$(whoami)'), false);
  assert.equal(isValidBusid(''), false);
});

test('isValidDeviceNode aceita apenas /dev/sd* válidos', () => {
  assert.equal(isValidDeviceNode('/dev/sdg1'), true);
  assert.equal(isValidDeviceNode('/dev/sda'), true);
  assert.equal(isValidDeviceNode('/dev/sdg1; rm -rf /'), false);
  assert.equal(isValidDeviceNode('/etc/passwd'), false);
});

test('isValidMountPath aceita apenas diretórios gerenciados sem traversal', () => {
  assert.equal(isValidMountPath('/mnt/usb-driver/BACKUP_LINUX'), true);
  assert.equal(isValidMountPath('/mnt/usb-driver'), true);
  assert.equal(isValidMountPath('/mnt/usb-driver/../etc'), false);
  assert.equal(isValidMountPath('/etc/passwd'), false);
});

test('buildWslUncPath gera caminho UNC seguro para Windows Explorer', () => {
  assert.equal(
    buildWslUncPath('Ubuntu-24.04', '/mnt/usb-driver/BACKUP_LINUX'),
    '\\\\wsl.localhost\\Ubuntu-24.04\\mnt\\usb-driver\\BACKUP_LINUX'
  );
  assert.throws(() => buildWslUncPath('Ubuntu', '/etc/shadow'));
});

test('parseJsonOutput extrai JSON válido mesmo com logs precedentes', () => {
  const parsed = parseJsonOutput('[INFO] carregando\n{"ok":true,"count":2}\n');
  assert.deepEqual(parsed, { ok: true, count: 2 });
});
