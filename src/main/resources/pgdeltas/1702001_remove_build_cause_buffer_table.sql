DROP TABLE BuildCauseBuffer;
DROP SEQUENCE buildcausebuffer_id_seq;

--//@UNDO

CREATE SEQUENCE buildcausebuffer_id_seq START WITH 1;
CREATE TABLE BuildCauseBuffer (
    id                    BIGINT DEFAULT nextval('buildcausebuffer_id_seq') PRIMARY KEY,
    pipelineName          VARCHAR(255) ,
    buildCause            TEXT,
    timestamp             TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE BuildCauseBuffer ADD CONSTRAINT unique_build_buffer_pipeline_name UNIQUE (pipelineName);
