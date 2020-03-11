
ALTER TABLE AccessToken ADD COLUMN revokeCause TEXT;

--//@UNDO

ALTER TABLE AccessToken DROP COLUMN revokeCause;
