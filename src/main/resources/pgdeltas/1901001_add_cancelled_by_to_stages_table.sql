ALTER TABLE stages ADD COLUMN cancelledBy VARCHAR(255);

--//@UNDO

ALTER TABLE stages DROP COLUMN cancelledBy;
