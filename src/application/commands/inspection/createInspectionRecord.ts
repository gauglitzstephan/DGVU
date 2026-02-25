import { AuditActionType, Prisma, type InspectionRecord } from "@prisma/client";

import type { Command } from "../command";
import { runInTransaction } from "../../../infra/db/transaction";
import { ensureOrg } from "../../../infra/db/scoping";

type CreateInspectionRecordInput = {
  assetId: string;
  inspection_date: string;
  inspector_name: string;
  comment?: string;
  documentId?: string;
};

export const createInspectionRecordCommand: Command<
  CreateInspectionRecordInput,
  InspectionRecord
> = async (ctx, input) => {
  if (!input.assetId) {
    throw new Error("Missing required field: assetId");
  }

  if (!input.inspection_date) {
    throw new Error("Missing required field: inspection_date");
  }

  if (!input.inspector_name) {
    throw new Error("Missing required field: inspector_name");
  }

  if (!ctx.actorUserId) {
    throw new Error("Missing actorUserId");
  }

  const organisationId = ensureOrg(ctx);

  return runInTransaction(async (tx) => {
    const asset = await tx.asset.findFirst({
      where: {
        id: input.assetId,
        organisationId,
      },
    });

    if (!asset) {
      throw new Error("Asset not found for organisation");
    }

    const intervalOptionIdAtTime = asset.intervalOptionId;

    if (input.documentId) {
      const doc = await tx.document.findFirst({
        where: {
          id: input.documentId,
          organisationId,
        },
      });

      if (!doc) {
        throw new Error("Invalid documentId for organisation");
      }
    }

    const createdInspectionRecord = await tx.inspectionRecord.create({
      data: {
        organisationId,
        assetId: input.assetId,
        inspection_date: input.inspection_date,
        inspector_name: input.inspector_name,
        intervalOptionId_at_time: intervalOptionIdAtTime,
        comment: input.comment,
        documentId: input.documentId,
      },
    });

    const agg = await tx.inspectionRecord.aggregate({
      where: {
        assetId: input.assetId,
        organisationId,
      },
      _max: {
        inspection_date: true,
      },
    });

    await tx.asset.update({
      where: {
        id: input.assetId,
        organisationId,
      },
      data: {
        last_inspection_date: agg._max.inspection_date,
      },
    });

    const payload: Prisma.JsonObject = {
      inspection_record_id: createdInspectionRecord.id,
      organisation_id: organisationId,
      asset_id: createdInspectionRecord.assetId,
      inspection_date: input.inspection_date,
      inspector_name: input.inspector_name,
      interval_option_id_at_time: intervalOptionIdAtTime,
    };

    if (input.comment) {
      payload.comment = input.comment;
    }

    if (input.documentId) {
      payload.document_id = input.documentId;
    }

    await tx.auditLog.create({
      data: {
        organisationId,
        actor_user_id: ctx.actorUserId,
        action_type: AuditActionType.CREATE_INSPECTION_RECORD,
        target_entity_type: "INSPECTION_RECORD",
        target_entity_id: createdInspectionRecord.id,
        payload_json: payload,
      },
    });

    return { data: createdInspectionRecord };
  });
};
