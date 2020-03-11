CREATE SEQUENCE pipelinestates_id_seq START WITH 1;
CREATE TABLE PipelineStates (
    id                      BIGINT DEFAULT nextval('plugins_id_seq') PRIMARY KEY,
    pipelineName            CITEXT NOT NULL,
    locked                  BOOLEAN,
    lockedByPipelineId              BIGINT
);

ALTER TABLE PipelineStates ADD CONSTRAINT unique_pipeline_state UNIQUE (pipelineName);

INSERT INTO PipelineStates (pipelineName, locked, lockedByPipelineId) (select name, locked, id from pipelines where id in (select max(id) from pipelines where locked = true group by name));

DROP VIEW _stages;

CREATE VIEW _stages AS
    SELECT s.*,
      p.name pipelineName, p.buildCauseType, p.buildCauseBy, p.label pipelineLabel, p.buildCauseMessage, p.counter pipelineCounter, ps.locked, p.naturalOrder
    FROM stages s
    INNER JOIN pipelines p ON p.id = s.pipelineId
    LEFT OUTER JOIN PipelineStates ps on ps.lockedByPipelineId = s.pipelineId;


ALTER TABLE pipelines drop column locked;

--//@UNDO

