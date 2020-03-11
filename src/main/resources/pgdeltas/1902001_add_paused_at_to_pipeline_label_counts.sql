ALTER TABLE pipelinelabelcounts ADD COLUMN paused_at TIMESTAMP;

--//@UNDO

ALTER TABLE pipelinelabelcounts DROP COLUMN paused_at;
