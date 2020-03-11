
ALTER TABLE AccessToken ADD COLUMN revokedBy VARCHAR(255);

--//@UNDO

ALTER TABLE AccessToken DROP COLUMN revokedBy;
