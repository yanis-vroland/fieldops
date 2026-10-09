import net from 'node:net';

/**
 * Proxy TCP de test entre l'API et PostgreSQL (CA5, CA6) : permet de rendre la
 * base injoignable puis de nouveau joignable sans arrêter PostgreSQL.
 */
export interface TcpProxy {
  readonly port: number;
  /** Ferme les connexions en cours et refuse les nouvelles. */
  cut(): void;
  /** Accepte de nouveau les connexions. */
  restore(): void;
  close(): Promise<void>;
}

export async function startTcpProxy(
  targetHost: string,
  targetPort: number,
): Promise<TcpProxy> {
  const sockets = new Set<net.Socket>();
  let isCut = false;

  const server = net.createServer((client) => {
    if (isCut) {
      client.destroy();
      return;
    }
    const upstream = net.connect(targetPort, targetHost);
    sockets.add(client);
    sockets.add(upstream);
    // Une extrémité qui tombe ferme l'autre.
    client.on('error', () => upstream.destroy());
    upstream.on('error', () => client.destroy());
    client.on('close', () => {
      sockets.delete(client);
      upstream.destroy();
    });
    upstream.on('close', () => {
      sockets.delete(upstream);
      client.destroy();
    });
    client.pipe(upstream);
    upstream.pipe(client);
  });

  await new Promise<void>((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => resolve());
  });
  const { port } = server.address() as net.AddressInfo;

  return {
    port,
    cut() {
      isCut = true;
      for (const socket of sockets) socket.destroy();
      sockets.clear();
    },
    restore() {
      isCut = false;
    },
    close() {
      isCut = true;
      for (const socket of sockets) socket.destroy();
      sockets.clear();
      return new Promise<void>((resolve) => server.close(() => resolve()));
    },
  };
}
