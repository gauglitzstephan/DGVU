import { AuditActionType, type Asset } from "@prisma/client";

import type { Command } from "../command";
import { runInTransaction } from "../../../infra/db/transaction";
import { ensureOrg } from "../../../infra/db/scoping";

export type CreateAssetInput = {
  name: string;
  objectClassId: string;
  intervalOptionId: string;
  locationId?: string;
  responsibleRoleId?: string;
  inventoryNumber?: string;
  serialNumber?: string;
  description?: string;
};

export const createAssetCommand: Command<CreateAssetInput, Asset> = async (ctx, input) => {
  if (!input.name) {
    throw new Error("Missing required field: name");
  }

  if (!input.objectClassId) {
    throw new Error("Missing required field: objectClassId");
  }

  if (!input.intervalOptionId) {
    throw new Error("Missing required field: intervalOptionId");
  }

  const organisationId = ensureOrg(ctx);

  return runInTransaction(async (tx) => {
    if (input.locationId) {
      const location = await tx.location.findFirst({
        where: {
          id: input.locationId,
          organisationId,
        },
      });

      if (!location) {
        throw new Error("Invalid locationId for organisation");
      }
    }

    if (input.responsibleRoleId) {
      const responsibleRole = await tx.responsibleRole.findFirst({
        where: {
          id: input.responsibleRoleId,
          organisationId,
        },
      });

      if (!responsibleRole) {
        throw new Error("Invalid responsibleRoleId for organisation");
      }
    }

    const createdAsset = await tx.asset.create({
      data: {
        organisationId,
        name: input.name,
        objectClassId: input.objectClassId,
        intervalOptionId: input.intervalOptionId,
        locationId: input.locationId,
        responsibleRoleId: input.responsibleRoleId,
        inventoryNumber: input.inventoryNumber,
        serialNumber: input.serialNumber,
        description: input.description,
        is_active: true,
        last_inspection_date: null,
      },
    });

    const payloadSnapshot = JSON.parse(JSON.stringify(createdAsset));

    await tx.auditLog.create({
      data: {
        organisationId,
        actor_user_id: ctx.actorUserId ?? null,
        action_type: AuditActionType.CREATE_ASSET,
        target_entity_type: "Asset",
        target_entity_id: createdAsset.id,
        payload_json: payloadSnapshot,
      },
    });

    return { data: createdAsset };
  });
};
