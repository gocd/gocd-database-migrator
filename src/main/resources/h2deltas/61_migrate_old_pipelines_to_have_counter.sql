--****
-- Copyright 2014 ThoughtWorks, Inc.
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
--*****

SELECT SET(@max_null, MAX(id)) FROM pipelines WHERE counter IS null;
UPDATE pipelines SET counter=(id - @max_null - 1) WHERE counter IS null;

--//@UNDO

UPDATE pipelines SET counter=null WHERE counter < 0;
