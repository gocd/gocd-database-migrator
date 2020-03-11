DROP SEQUENCE IF EXISTS materialProperties_id_seq;

--//@UNDO

-- The table using this sequence doesn't exist so undo doesn't really makes sense
CREATE SEQUENCE materialProperties_id_seq START WITH 1;
