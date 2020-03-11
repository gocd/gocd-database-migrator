-- This query turned out to be time consuming on bigger db instances. Commenting it out as we plan to rethink about how we want to remove data from these tables.

-- DELETE FROM jobAgentMetadata
-- WHERE jobAgentMetadata.id IN (
--   SELECT jobAgentMetadata.id
--   FROM jobAgentMetadata
--   INNER JOIN builds
--     ON
--       builds.id = jobAgentMetadata.jobId
--   WHERE
--     builds.state = 'Completed'
-- );

--//@UNDO

