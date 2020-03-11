ALTER TABLE artifactplans ADD COLUMN pluggableArtifactConfigJson TEXT DEFAULT NULL;

--//@UNDO

ALTER TABLE artifactplans DROP COLUMN pluggableArtifactConfigJson;

