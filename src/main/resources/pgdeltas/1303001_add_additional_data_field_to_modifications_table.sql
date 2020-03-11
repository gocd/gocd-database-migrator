ALTER TABLE modifications ADD COLUMN additionalData TEXT;

--//@UNDO

ALTER TABLE modifications DROP COLUMN additionalData;


