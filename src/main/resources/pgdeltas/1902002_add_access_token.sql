CREATE SEQUENCE accesstoken_id_seq START WITH 1;

CREATE TABLE AccessToken (
id             BIGINT DEFAULT nextval('accesstoken_id_seq') PRIMARY KEY,
name           CITEXT NOT NULL,
value          VARCHAR(255) UNIQUE NOT NULL,
saltId         VARCHAR(8) UNIQUE NOT NULL,
saltValue      VARCHAR(255) UNIQUE NOT NULL,
description    VARCHAR(1024),
isRevoked      BOOLEAN,
revokedAt      TIMESTAMP,
createdAt      TIMESTAMP,
lastUsed       TIMESTAMP,
username       CITEXT NOT NULL,
authConfigId   CITEXT NOT NULL
);

--//@UNDO
DROP TABLE IF EXISTS AccessToken;
