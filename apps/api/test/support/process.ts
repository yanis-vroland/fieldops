import { spawn, type ChildProcess } from 'node:child_process';
import net from 'node:net';
import { fileURLToPath } from 'node:url';

/** Racine de apps/api : répertoire de travail des scripts lancés. */
export const apiRoot = fileURLToPath(new URL('../../', import.meta.url));

export interface RunResult {
  code: number | null;
  output: string;
  timedOut: boolean;
}

/** Lance un script Node compilé et attend sa fin (tué au-delà du délai). */
export function runNode(
  script: string,
  env: NodeJS.ProcessEnv,
  timeoutMs: number,
): Promise<RunResult> {
  return new Promise((resolve) => {
    const child = spawn(process.execPath, [script], {
      cwd: apiRoot,
      env,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let output = '';
    let timedOut = false;
    child.stdout.on('data', (chunk: Buffer) => (output += chunk.toString()));
    child.stderr.on('data', (chunk: Buffer) => (output += chunk.toString()));
    const timer = setTimeout(() => {
      timedOut = true;
      child.kill('SIGKILL');
    }, timeoutMs);
    child.on('close', (code) => {
      clearTimeout(timer);
      resolve({ code, output, timedOut });
    });
  });
}

/** Lance un processus longue durée (serveur) ; à arrêter avec stopProcess. */
export function startNode(
  script: string,
  env: NodeJS.ProcessEnv,
): ChildProcess {
  return spawn(process.execPath, [script], {
    cwd: apiRoot,
    env,
    stdio: 'ignore',
  });
}

export function stopProcess(child: ChildProcess): Promise<void> {
  if (child.exitCode !== null || child.signalCode !== null) {
    return Promise.resolve();
  }
  return new Promise((resolve) => {
    child.once('exit', () => resolve());
    child.kill('SIGKILL');
  });
}

/** Port TCP libre sur la machine. */
export async function freePort(): Promise<number> {
  const server = net.createServer();
  await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address() as net.AddressInfo;
  await new Promise<void>((resolve) => server.close(() => resolve()));
  return port;
}
