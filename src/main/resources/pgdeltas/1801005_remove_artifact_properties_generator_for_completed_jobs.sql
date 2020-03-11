-- This query turned out to be time consuming on bigger db instances. Commenting it out as we plan to rethink about how we want to remove data from these tables.

-- DELETE FROM artifactPropertiesGenerator
-- WHERE ID IN (
--   SELECT artifactPropertiesGenerator.id
--   FROM artifactPropertiesGenerator
--   INNER JOIN builds
--     ON builds.id = artifactPropertiesGenerator.jobId
--   WHERE
--     builds.state = 'Completed'
-- );

--//@UNDO

