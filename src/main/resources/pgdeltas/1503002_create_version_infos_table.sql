--*************************GO-LICENSE-START*********************************
-- Copyright 2015 ThoughtWorks, Inc.
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
--*************************GO-LICENSE-END***********************************

CREATE SEQUENCE versioninfos_id_seq START WITH 1;
CREATE TABLE versioninfos (
    id                      BIGINT DEFAULT nextval('versioninfos_id_seq') PRIMARY KEY,
    componentName           VARCHAR(255) Not NULL,
    installedVersion        VARCHAR(100) Not NULL,
    latestVersion           VARCHAR(50),
    latestVersionUpdatedAt  TIMESTAMP,
    UNIQUE (componentName)
);

--//@UNDO

DROP TABLE IF EXISTS versioninfos CASCADE;