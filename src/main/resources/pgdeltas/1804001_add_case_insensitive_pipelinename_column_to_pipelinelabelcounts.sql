ALTER TABLE PIPELINELABELCOUNTS ADD COLUMN caseInsensitivePipelineName CITEXT;
UPDATE PIPELINELABELCOUNTS set caseInsensitivePipelineName = pipelinename;
CREATE INDEX idx_pipelinelabelcounts_caseinsensitivepipelinename ON PIPELINELABELCOUNTS(caseInsensitivePipelineName);

--//@UNDO

DROP INDEX idx_pipelinelabelcounts_caseinsensitivepipelinename;
ALTER TABLE PIPELINELABELCOUNTS DROP COLUMN caseInsensitivePipelineName;
