-- This query turned out to be time consuming on bigger db instances. Commenting it out as we plan to rethink about how we want to remove data from these tables.
-- DELETE FROM resources
-- WHERE resources.id IN (
--   SELECT resources.id
--   FROM resources
--   INNER JOIN builds
--     ON builds.id = resources.buildId
--   WHERE
--     builds.state = 'Completed'
-- );

--//@UNDO

