CREATE INDEX idx_stages_pipelineId ON stages(pipelineid);
CREATE INDEX idx_resources_buildId ON resources(buildid);

--//@UNDO

DROP INDEX IF EXISTS idx_stages_pipelineId;
DROP INDEX IF EXISTS idx_resources_buildId;

