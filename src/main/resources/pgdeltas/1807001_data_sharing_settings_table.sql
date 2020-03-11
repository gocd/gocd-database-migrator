CREATE SEQUENCE datasharingsettings_id_seq START WITH 1;

CREATE TABLE DataSharingSettings (
  id             BIGINT DEFAULT nextval('datasharingsettings_id_seq') PRIMARY KEY,
  allowSharing        BOOLEAN NOT NULL,
  updatedBy    VARCHAR(255),
  updatedOn    TIMESTAMP
);

--//@UNDO
DROP TABLE IF EXISTS DataSharingSettings;
DROP SEQUENCE datasharingsettings_id_seq;