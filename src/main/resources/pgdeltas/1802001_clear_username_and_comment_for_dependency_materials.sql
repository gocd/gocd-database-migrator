UPDATE
  modifications
SET
  username = null, comment = null
WHERE
    pipelineid IS NOT NULL
  AND
    username = 'Unknown'
  AND
    comment = 'Unknown';

--//@UNDO

