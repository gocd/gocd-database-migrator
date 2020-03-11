
ALTER TABLE AccessToken ADD COLUMN deletedBecauseUserDeleted BOOLEAN DEFAULT false;

--//@UNDO

