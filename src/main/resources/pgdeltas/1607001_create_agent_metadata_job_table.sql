--
-- Copyright 2016 ThoughtWorks, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

CREATE SEQUENCE jobagentmetadata_id_seq START WITH 1;
CREATE TABLE jobagentmetadata (
  id              BIGINT DEFAULT nextval('jobagentmetadata_id_seq') PRIMARY KEY,
  jobId           BIGINT UNIQUE NOT NULL,
  metadata        TEXT NOT NULL,
  metadataVersion VARCHAR(50),
  UNIQUE (jobId)
);

ALTER TABLE jobagentmetadata ADD CONSTRAINT fk_jobagentmetadata_jobs FOREIGN KEY (jobId) REFERENCES builds (id)
  ON DELETE CASCADE;

--//@UNDO
DROP TABLE IF EXISTS jobagentmetadata CASCADE;
