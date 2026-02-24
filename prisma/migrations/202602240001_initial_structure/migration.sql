-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('ADMIN', 'OWNER', 'VIEWER');

-- CreateEnum
CREATE TYPE "AuditActionType" AS ENUM (
  'CREATE_ASSET',
  'TOGGLE_ASSET_ACTIVE',
  'CHANGE_ASSET_INTERVAL',
  'CREATE_INSPECTION_RECORD',
  'DELETE_INSPECTION_RECORD'
);

-- CreateTable
CREATE TABLE "ObjectClass" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "name" TEXT NOT NULL,
  "description" TEXT,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "ObjectClass_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "IntervalOption" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "months" INTEGER NOT NULL,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "IntervalOption_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Organisation" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "organisation_id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "name" TEXT NOT NULL,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "Organisation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Location" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "organisation_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "address" TEXT,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "Location_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ResponsibleRole" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "organisation_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "notification_email" TEXT NOT NULL,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "ResponsibleRole_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "User" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "organisation_id" UUID NOT NULL,
  "email" TEXT NOT NULL,
  "role" "UserRole" NOT NULL,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrganisationObjectClass" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "organisation_id" UUID NOT NULL,
  "object_class_id" UUID NOT NULL,
  "is_enabled" BOOLEAN NOT NULL DEFAULT false,
  "enabled_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "OrganisationObjectClass_pkey" PRIMARY KEY ("organisation_id", "object_class_id")
);

-- CreateTable
CREATE TABLE "Asset" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "organisation_id" UUID NOT NULL,
  "location_id" UUID NOT NULL,
  "object_class_id" UUID NOT NULL,
  "interval_option_id" UUID NOT NULL,
  "responsible_role_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "last_inspection_date" DATE,
  "inspector_name" TEXT NOT NULL,
  "serial_number" TEXT,
  "inventory_number" TEXT,
  "notes" TEXT,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "Asset_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InspectionRecord" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "organisation_id" UUID NOT NULL,
  "asset_id" UUID NOT NULL,
  "inspection_date" DATE NOT NULL,
  "inspector_name" TEXT NOT NULL,
  "interval_option_id_at_time" UUID NOT NULL,
  "recorded_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "comment" TEXT,
  "document_id" UUID,
  CONSTRAINT "InspectionRecord_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Document" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "organisation_id" UUID NOT NULL,
  "file_name" TEXT NOT NULL,
  "mime_type" TEXT NOT NULL,
  "storage_pointer" TEXT NOT NULL,
  "uploaded_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "uploaded_by_user_id" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "Document_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditLog" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "organisation_id" UUID NOT NULL,
  "occurred_at_utc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "actor_user_id" UUID,
  "action_type" "AuditActionType" NOT NULL,
  "target_entity_type" TEXT NOT NULL,
  "target_entity_id" TEXT NOT NULL,
  "payload_json" JSONB NOT NULL,
  CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ObjectClass_is_active_idx" ON "ObjectClass"("is_active");

-- CreateIndex
CREATE UNIQUE INDEX "IntervalOption_months_key" ON "IntervalOption"("months");

-- CreateIndex
CREATE INDEX "IntervalOption_is_active_idx" ON "IntervalOption"("is_active");

-- CreateIndex
CREATE UNIQUE INDEX "Organisation_organisation_id_key" ON "Organisation"("organisation_id");

-- CreateIndex
CREATE INDEX "Organisation_organisation_id_idx" ON "Organisation"("organisation_id");

-- CreateIndex
CREATE INDEX "Location_organisation_id_idx" ON "Location"("organisation_id");

-- CreateIndex
CREATE INDEX "ResponsibleRole_organisation_id_idx" ON "ResponsibleRole"("organisation_id");

-- CreateIndex
CREATE UNIQUE INDEX "User_organisation_id_email_key" ON "User"("organisation_id", "email");

-- CreateIndex
CREATE INDEX "User_organisation_id_idx" ON "User"("organisation_id");

-- CreateIndex
CREATE UNIQUE INDEX "OrganisationObjectClass_id_key" ON "OrganisationObjectClass"("id");

-- CreateIndex
CREATE INDEX "OrganisationObjectClass_organisation_id_idx" ON "OrganisationObjectClass"("organisation_id");

-- CreateIndex
CREATE INDEX "OrganisationObjectClass_object_class_id_idx" ON "OrganisationObjectClass"("object_class_id");

-- CreateIndex
CREATE INDEX "Asset_organisation_id_idx" ON "Asset"("organisation_id");

-- CreateIndex
CREATE INDEX "Asset_location_id_idx" ON "Asset"("location_id");

-- CreateIndex
CREATE INDEX "Asset_object_class_id_idx" ON "Asset"("object_class_id");

-- CreateIndex
CREATE INDEX "Asset_interval_option_id_idx" ON "Asset"("interval_option_id");

-- CreateIndex
CREATE INDEX "Asset_responsible_role_id_idx" ON "Asset"("responsible_role_id");

-- CreateIndex
CREATE INDEX "InspectionRecord_organisation_id_idx" ON "InspectionRecord"("organisation_id");

-- CreateIndex
CREATE INDEX "InspectionRecord_asset_id_idx" ON "InspectionRecord"("asset_id");

-- CreateIndex
CREATE INDEX "InspectionRecord_interval_option_id_at_time_idx" ON "InspectionRecord"("interval_option_id_at_time");

-- CreateIndex
CREATE INDEX "InspectionRecord_document_id_idx" ON "InspectionRecord"("document_id");

-- CreateIndex
CREATE INDEX "Document_organisation_id_idx" ON "Document"("organisation_id");

-- CreateIndex
CREATE INDEX "Document_uploaded_by_user_id_idx" ON "Document"("uploaded_by_user_id");

-- CreateIndex
CREATE INDEX "AuditLog_organisation_id_idx" ON "AuditLog"("organisation_id");

-- CreateIndex
CREATE INDEX "AuditLog_actor_user_id_idx" ON "AuditLog"("actor_user_id");

-- CreateIndex
CREATE INDEX "AuditLog_action_type_idx" ON "AuditLog"("action_type");

-- CreateIndex
CREATE INDEX "AuditLog_target_entity_type_target_entity_id_idx" ON "AuditLog"("target_entity_type", "target_entity_id");

-- AddForeignKey
ALTER TABLE "Location"
ADD CONSTRAINT "Location_organisation_id_fkey"
FOREIGN KEY ("organisation_id") REFERENCES "Organisation"("organisation_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "ResponsibleRole"
ADD CONSTRAINT "ResponsibleRole_organisation_id_fkey"
FOREIGN KEY ("organisation_id") REFERENCES "Organisation"("organisation_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "User"
ADD CONSTRAINT "User_organisation_id_fkey"
FOREIGN KEY ("organisation_id") REFERENCES "Organisation"("organisation_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "OrganisationObjectClass"
ADD CONSTRAINT "OrganisationObjectClass_organisation_id_fkey"
FOREIGN KEY ("organisation_id") REFERENCES "Organisation"("organisation_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "OrganisationObjectClass"
ADD CONSTRAINT "OrganisationObjectClass_object_class_id_fkey"
FOREIGN KEY ("object_class_id") REFERENCES "ObjectClass"("id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "Asset"
ADD CONSTRAINT "Asset_organisation_id_fkey"
FOREIGN KEY ("organisation_id") REFERENCES "Organisation"("organisation_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "Asset"
ADD CONSTRAINT "Asset_location_id_fkey"
FOREIGN KEY ("location_id") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "Asset"
ADD CONSTRAINT "Asset_object_class_id_fkey"
FOREIGN KEY ("object_class_id") REFERENCES "ObjectClass"("id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "Asset"
ADD CONSTRAINT "Asset_interval_option_id_fkey"
FOREIGN KEY ("interval_option_id") REFERENCES "IntervalOption"("id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "Asset"
ADD CONSTRAINT "Asset_responsible_role_id_fkey"
FOREIGN KEY ("responsible_role_id") REFERENCES "ResponsibleRole"("id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "InspectionRecord"
ADD CONSTRAINT "InspectionRecord_organisation_id_fkey"
FOREIGN KEY ("organisation_id") REFERENCES "Organisation"("organisation_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "InspectionRecord"
ADD CONSTRAINT "InspectionRecord_asset_id_fkey"
FOREIGN KEY ("asset_id") REFERENCES "Asset"("id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "InspectionRecord"
ADD CONSTRAINT "InspectionRecord_interval_option_id_at_time_fkey"
FOREIGN KEY ("interval_option_id_at_time") REFERENCES "IntervalOption"("id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "InspectionRecord"
ADD CONSTRAINT "InspectionRecord_document_id_fkey"
FOREIGN KEY ("document_id") REFERENCES "Document"("id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "Document"
ADD CONSTRAINT "Document_organisation_id_fkey"
FOREIGN KEY ("organisation_id") REFERENCES "Organisation"("organisation_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "Document"
ADD CONSTRAINT "Document_uploaded_by_user_id_fkey"
FOREIGN KEY ("uploaded_by_user_id") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "AuditLog"
ADD CONSTRAINT "AuditLog_organisation_id_fkey"
FOREIGN KEY ("organisation_id") REFERENCES "Organisation"("organisation_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "AuditLog"
ADD CONSTRAINT "AuditLog_actor_user_id_fkey"
FOREIGN KEY ("actor_user_id") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- IntervalOption allowed values constraint
ALTER TABLE "IntervalOption"
ADD CONSTRAINT "IntervalOption_months_allowed_check"
CHECK ("months" IN (3, 6, 12, 24));

-- Seed IntervalOption
INSERT INTO "IntervalOption" ("id", "months", "is_active", "updated_at") VALUES
('00000000-0000-0000-0000-000000000003', 3, true, CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000000006', 6, true, CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000000012', 12, true, CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000000024', 24, true, CURRENT_TIMESTAMP);

-- Seed ObjectClass (deterministic starter set)
INSERT INTO "ObjectClass" ("id", "name", "description", "is_active", "updated_at") VALUES
('10000000-0000-0000-0000-000000000001', 'CLASS_1', NULL, true, CURRENT_TIMESTAMP),
('10000000-0000-0000-0000-000000000002', 'CLASS_2', NULL, true, CURRENT_TIMESTAMP),
('10000000-0000-0000-0000-000000000003', 'CLASS_3', NULL, true, CURRENT_TIMESTAMP);
