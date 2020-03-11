ALTER TABLE serverBackups ADD COLUMN status VARCHAR(255);
ALTER TABLE serverBackups ADD COLUMN message TEXT;
UPDATE serverBackups set status='COMPLETED' WHERE status IS NULL;
ALTER TABLE serverBackups ALTER COLUMN status SET NOT NULL;

--//@UNDO

ALTER TABLE serverBackups DROP COLUMN status;
ALTER TABLE serverBackups DROP COLUMN message;
