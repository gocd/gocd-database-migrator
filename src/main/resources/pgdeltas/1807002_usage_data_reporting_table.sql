CREATE SEQUENCE usagedatareporting_id_seq START WITH 1;

CREATE TABLE UsageDataReporting (
  id             BIGINT DEFAULT nextval('usagedatareporting_id_seq') PRIMARY KEY,
  serverId       VARCHAR(255) NOT NULL,
  lastReportedAt TIMESTAMP
);

--//@UNDO

DROP TABLE IF EXISTS UsageDataReporting;
DROP SEQUENCE usagedatareporting_id_seq;
