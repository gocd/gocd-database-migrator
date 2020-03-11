ALTER TABLE materials ADD COLUMN additionalData TEXT;

--//@UNDO

ALTER TABLE materials DROP COLUMN additionalData;


