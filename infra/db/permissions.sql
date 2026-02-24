-- Database permissions hardening for trust model.
-- Execute this script as migration_user during deploy, after Prisma migrations.

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'migration_user') THEN
    CREATE ROLE migration_user LOGIN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_user') THEN
    CREATE ROLE app_user LOGIN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_readonly_user') THEN
    CREATE ROLE admin_readonly_user LOGIN;
  END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO app_user;
GRANT USAGE ON SCHEMA public TO admin_readonly_user;

REVOKE CREATE ON SCHEMA public FROM app_user;
REVOKE CREATE ON SCHEMA public FROM admin_readonly_user;

REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM app_user;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM admin_readonly_user;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO admin_readonly_user;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public FROM admin_readonly_user;

ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA public
  REVOKE ALL ON TABLES FROM admin_readonly_user;
ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA public
  GRANT SELECT ON TABLES TO admin_readonly_user;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
REVOKE TRUNCATE ON ALL TABLES IN SCHEMA public FROM app_user;
REVOKE REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public FROM app_user;

ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA public
  REVOKE ALL ON TABLES FROM app_user;
ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA public
  REVOKE TRUNCATE ON TABLES FROM app_user;
ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA public
  REVOKE REFERENCES, TRIGGER ON TABLES FROM app_user;

REVOKE UPDATE, DELETE ON TABLE public."AuditLog" FROM app_user;
REVOKE INSERT, UPDATE, DELETE ON TABLE public."ObjectClass" FROM app_user;
REVOKE INSERT, UPDATE, DELETE ON TABLE public."IntervalOption" FROM app_user;
REVOKE DELETE ON TABLE public."Asset" FROM app_user;
REVOKE UPDATE ON TABLE public."InspectionRecord" FROM app_user;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE public."AuditLog" FROM admin_readonly_user;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE public."ObjectClass" FROM admin_readonly_user;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE public."IntervalOption" FROM admin_readonly_user;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE public."Asset" FROM admin_readonly_user;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE public."InspectionRecord" FROM admin_readonly_user;

DO $$
DECLARE
  required_table text;
BEGIN
  FOREACH required_table IN ARRAY ARRAY[
    'public."AuditLog"',
    'public."ObjectClass"',
    'public."IntervalOption"',
    'public."Asset"',
    'public."InspectionRecord"'
  ]
  LOOP
    IF to_regclass(required_table) IS NULL THEN
      RAISE EXCEPTION 'Required table % does not exist; failing closed.', required_table;
    END IF;
  END LOOP;

  IF NOT has_table_privilege('app_user', 'public."AuditLog"', 'SELECT') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must have SELECT on public."AuditLog"';
  END IF;
  IF NOT has_table_privilege('app_user', 'public."AuditLog"', 'INSERT') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must have INSERT on public."AuditLog"';
  END IF;
  IF has_table_privilege('app_user', 'public."AuditLog"', 'UPDATE') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have UPDATE on public."AuditLog"';
  END IF;
  IF has_table_privilege('app_user', 'public."AuditLog"', 'DELETE') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have DELETE on public."AuditLog"';
  END IF;

  IF has_table_privilege('app_user', 'public."IntervalOption"', 'INSERT') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have INSERT on public."IntervalOption"';
  END IF;
  IF has_table_privilege('app_user', 'public."IntervalOption"', 'UPDATE') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have UPDATE on public."IntervalOption"';
  END IF;
  IF has_table_privilege('app_user', 'public."IntervalOption"', 'DELETE') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have DELETE on public."IntervalOption"';
  END IF;

  IF has_table_privilege('app_user', 'public."ObjectClass"', 'INSERT') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have INSERT on public."ObjectClass"';
  END IF;
  IF has_table_privilege('app_user', 'public."ObjectClass"', 'UPDATE') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have UPDATE on public."ObjectClass"';
  END IF;
  IF has_table_privilege('app_user', 'public."ObjectClass"', 'DELETE') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have DELETE on public."ObjectClass"';
  END IF;

  IF has_table_privilege('app_user', 'public."Asset"', 'DELETE') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have DELETE on public."Asset"';
  END IF;
  IF has_table_privilege('app_user', 'public."Asset"', 'TRUNCATE') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have TRUNCATE on public."Asset"';
  END IF;
  IF has_table_privilege('app_user', 'public."Asset"', 'REFERENCES') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have REFERENCES on public."Asset"';
  END IF;
  IF has_table_privilege('app_user', 'public."Asset"', 'TRIGGER') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have TRIGGER on public."Asset"';
  END IF;

  IF has_table_privilege('app_user', 'public."InspectionRecord"', 'UPDATE') THEN
    RAISE EXCEPTION 'Invariant failed: app_user must NOT have UPDATE on public."InspectionRecord"';
  END IF;

  IF NOT has_table_privilege('admin_readonly_user', 'public."AuditLog"', 'SELECT') THEN
    RAISE EXCEPTION 'Invariant failed: admin_readonly_user must have SELECT on public."AuditLog"';
  END IF;
  IF NOT has_table_privilege('admin_readonly_user', 'public."Asset"', 'SELECT') THEN
    RAISE EXCEPTION 'Invariant failed: admin_readonly_user must have SELECT on public."Asset"';
  END IF;
  IF NOT has_table_privilege('admin_readonly_user', 'public."InspectionRecord"', 'SELECT') THEN
    RAISE EXCEPTION 'Invariant failed: admin_readonly_user must have SELECT on public."InspectionRecord"';
  END IF;
  IF NOT has_table_privilege('admin_readonly_user', 'public."ObjectClass"', 'SELECT') THEN
    RAISE EXCEPTION 'Invariant failed: admin_readonly_user must have SELECT on public."ObjectClass"';
  END IF;
  IF NOT has_table_privilege('admin_readonly_user', 'public."IntervalOption"', 'SELECT') THEN
    RAISE EXCEPTION 'Invariant failed: admin_readonly_user must have SELECT on public."IntervalOption"';
  END IF;

  IF has_table_privilege('admin_readonly_user', 'public."AuditLog"', 'INSERT') THEN
    RAISE EXCEPTION 'Invariant failed: admin_readonly_user must NOT have INSERT on public."AuditLog"';
  END IF;
  IF has_table_privilege('admin_readonly_user', 'public."Asset"', 'INSERT') THEN
    RAISE EXCEPTION 'Invariant failed: admin_readonly_user must NOT have INSERT on public."Asset"';
  END IF;
  IF has_table_privilege('admin_readonly_user', 'public."InspectionRecord"', 'INSERT') THEN
    RAISE EXCEPTION 'Invariant failed: admin_readonly_user must NOT have INSERT on public."InspectionRecord"';
  END IF;
  IF has_table_privilege('admin_readonly_user', 'public."ObjectClass"', 'INSERT') THEN
    RAISE EXCEPTION 'Invariant failed: admin_readonly_user must NOT have INSERT on public."ObjectClass"';
  END IF;
  IF has_table_privilege('admin_readonly_user', 'public."IntervalOption"', 'INSERT') THEN
    RAISE EXCEPTION 'Invariant failed: admin_readonly_user must NOT have INSERT on public."IntervalOption"';
  END IF;
END
$$;

COMMIT;
