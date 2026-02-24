import { Prisma } from '@prisma/client';

import { prisma } from './prisma';

export async function runInTransaction<T>(
  fn: (tx: Prisma.TransactionClient) => Promise<T>
): Promise<T> {
  return prisma.$transaction(async (tx) => fn(tx));
}
