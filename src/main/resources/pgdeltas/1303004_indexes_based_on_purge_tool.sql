CREATE INDEX idx_properties_buildId ON properties(buildId);
CREATE INDEX idx_materials_pipelinename ON materials(pipelinename);
CREATE INDEX idx_artifactpropertiesgenerator_jobid ON artifactpropertiesgenerator(jobid);
CREATE INDEX idx_environmentvariables_entitytype ON environmentvariables(entitytype);
CREATE INDEX idx_stageartifactcleanupprohibited_pipelinename ON stageartifactcleanupprohibited(pipelinename);
CREATE INDEX idx_pipelineLabelCounts_pipelinename ON pipelineLabelCounts(pipelinename);


--//@UNDO

DROP INDEX IF EXISTS idx_properties_buildId ;
DROP INDEX IF EXISTS idx_materials_pipelinename ;
DROP INDEX IF EXISTS idx_artifactpropertiesgenerator_jobid IF EXISTS;
DROP INDEX IF EXISTS idx_environmentvariables_entitytype ;
DROP INDEX IF EXISTS idx_stageartifactcleanupprohibited_pipelinename ;
DROP INDEX IF EXISTS idx_pipelineLabelCounts_pipelinename ;

