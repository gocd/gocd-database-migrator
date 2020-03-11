-- This query turned out to be time consuming on bigger db instances. Commenting it out as we plan to rethink about how we want to remove data from these tables.

-- DELETE FROM environmentVariables
-- WHERE environmentVariables.id IN (
--   SELECT environmentVariables.id
--   FROM environmentVariables
--   INNER JOIN builds
--   ON
--     builds.id = environmentVariables.entityId
--   WHERE
--       environmentVariables.entityType = 'Job'
--     AND
--       builds.state = 'Completed'
-- );

--//@UNDO

