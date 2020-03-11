-- As part of 1704003_pipeline_state_table.sql, PipelineStates was incorrectly setup to use plugins_id_seq instead of pipelinestates_id_seq.
-- This migration resets the sequence pipelinestates_id_seq to be the max(id) of PipelineStates, and alters PipelineStates to use the correct sequence.
-- Since sequences are not explicitly defined for H2, a corresponding migration for H2 is not required.

-- This delta is being backported to all releases starting from 17.4 until 17.10 as part of the patch release.

do $$
declare maxid int;
begin
    select max(id) from pipelinestates into maxid;
    IF maxid IS NULL THEN
        maxid = 1;
    END IF;
    execute 'alter SEQUENCE pipelinestates_id_seq RESTART with '|| maxid;
end;
$$ language plpgsql;

ALTER table PipelineStates alter column ID set default nextval('pipelinestates_id_seq');

--//@UNDO