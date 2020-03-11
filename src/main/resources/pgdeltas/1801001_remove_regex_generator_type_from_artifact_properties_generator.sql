ALTER TABLE artifactpropertiesgenerator DROP COLUMN regex;
ALTER TABLE artifactpropertiesgenerator DROP COLUMN generatorType;

--//@UNDO

ALTER TABLE artifactpropertiesgenerator ADD COLUMN IF NOT EXISTS regex VARCHAR(512) DEFAULT NULL;
ALTER TABLE artifactpropertiesgenerator ADD COLUMN IF NOT EXISTS generatorType VARCHAR(255) DEFAULT NULL;