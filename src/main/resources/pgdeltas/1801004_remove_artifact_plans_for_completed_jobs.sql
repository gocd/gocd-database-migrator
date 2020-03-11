-- This query turned out to be time consuming on bigger db instances. Commenting it out as we plan to rethink about how we want to remove data from these tables.

-- DELETE FROM artifactPlans
-- WHERE artifactPlans.id IN (
--   SELECT artifactPlans.id
--   FROM artifactPlans
--   INNER JOIN builds
--     ON builds.id = artifactPlans.buildId
--   WHERE
--       artifactPlans.artifactType = 'file'
--     AND
--       builds.state = 'Completed'
-- );


--//@UNDO

