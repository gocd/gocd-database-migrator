--BEGIN ==== 1_create_initial_tables.sql ====

CREATE SEQUENCE pipelines_id_seq START WITH 1;
CREATE TABLE pipelines (
    id              BIGINT DEFAULT nextval('pipelines_id_seq') PRIMARY KEY,
    name            VARCHAR(255),
    buildCauseType  VARCHAR(255),
    buildCauseBy    VARCHAR(255)
);

CREATE SEQUENCE stages_id_seq START WITH 1;
CREATE TABLE stages (
id BIGINT DEFAULT nextval('stages_id_seq') PRIMARY KEY,
name VARCHAR(255),
approvedBy VARCHAR(255),
pipelineId BIGINT
);

ALTER TABLE stages ADD CONSTRAINT fk_stages_pipelines FOREIGN KEY (pipelineId) REFERENCES pipelines(id) ON DELETE CASCADE DEFERRABLE;

CREATE SEQUENCE materials_id_seq START WITH 1;
CREATE TABLE materials (
id INTEGER DEFAULT nextval('materials_id_seq') PRIMARY KEY,
type VARCHAR(255),
pipelineId BIGINT,
url  VARCHAR(255),
username VARCHAR(255),
password VARCHAR(255)
);

ALTER TABLE materials ADD CONSTRAINT fk_materials_pipelines FOREIGN KEY (pipelineId) REFERENCES pipelines(id) ON DELETE CASCADE DEFERRABLE;

CREATE SEQUENCE builds_id_seq START WITH 1;
CREATE TABLE builds (
id BIGINT DEFAULT nextval('builds_id_seq') PRIMARY KEY,
name VARCHAR(255),
state VARCHAR(50),
result VARCHAR(50),
agentUuid VARCHAR(50),
scheduledDate TIMESTAMP,
stageId BIGINT,
matcher VARCHAR(4000),
buildEvent TEXT
);

ALTER TABLE builds ADD CONSTRAINT fk_builds_stages FOREIGN KEY (stageId) REFERENCES stages(id) ON DELETE CASCADE DEFERRABLE;

CREATE SEQUENCE properties_id_seq START WITH 1;
CREATE TABLE properties (
id BIGINT DEFAULT nextval('properties_id_seq') PRIMARY KEY,
buildId BIGINT,
key VARCHAR(255),
value VARCHAR(255),
UNIQUE (buildId, key)
);

ALTER TABLE properties ADD CONSTRAINT fk_properties_builds FOREIGN KEY (buildId) REFERENCES builds(id) ON DELETE CASCADE DEFERRABLE;

CREATE SEQUENCE artifactPlans_id_seq START WITH 1;
CREATE TABLE artifactPlans (
id BIGINT DEFAULT nextval('artifactPlans_id_seq') PRIMARY KEY,
buildId BIGINT,
src VARCHAR(255),
dest VARCHAR(255),
artifactType VARCHAR(255)
);

ALTER TABLE artifactplans ADD CONSTRAINT fk_artifactplans_builds FOREIGN KEY (buildId) REFERENCES builds(id) ON DELETE CASCADE DEFERRABLE;

CREATE SEQUENCE resources_id_seq START WITH 1;
CREATE TABLE resources (
id BIGINT DEFAULT nextval('resources_id_seq') PRIMARY KEY,
name VARCHAR(255),
buildId BIGINT Not NULL
);

ALTER TABLE resources ADD CONSTRAINT fk_resources_builds FOREIGN KEY (buildId) REFERENCES builds(id) ON DELETE CASCADE DEFERRABLE;

CREATE SEQUENCE modifications_id_seq START WITH 1;
CREATE TABLE modifications (
id BIGINT DEFAULT nextval('modifications_id_seq') PRIMARY KEY,
type VARCHAR(255),
username  VARCHAR(255),
comment TEXT,
emailaddress  VARCHAR(255),
revision VARCHAR(50),
modifiedTime TIMESTAMP,
pipelineId BIGINT Not NULL
);

ALTER TABLE modifications ADD CONSTRAINT fk_modifications_pipelineId_pipeline_id FOREIGN KEY (pipelineId) REFERENCES pipelines(id) ON DELETE CASCADE DEFERRABLE;

CREATE SEQUENCE modifiedFiles_id_seq START WITH 1;
CREATE TABLE modifiedFiles (
id BIGINT DEFAULT nextval('modifiedFiles_id_seq') PRIMARY KEY,
fileName VARCHAR(255),
revision VARCHAR(50),
folderName  VARCHAR(512),
action VARCHAR(50),
modificationId BIGINT Not NULL
);

ALTER TABLE modifiedFiles ADD CONSTRAINT fk_modifiedFiles_modifications FOREIGN KEY (modificationId) REFERENCES modifications(id) ON DELETE CASCADE DEFERRABLE;

CREATE SEQUENCE buildStateTransitions_id_seq START WITH 1;
CREATE TABLE buildStateTransitions (
id BIGINT DEFAULT nextval('buildStateTransitions_id_seq') PRIMARY KEY,
currentState VARCHAR(255) NOT NULL,
stateChangeTime TIMESTAMP NOT NULL,
buildId BIGINT Not NULL
);

ALTER TABLE buildstatetransitions ADD CONSTRAINT fk_buildstatetransitions_builds FOREIGN KEY (buildId) REFERENCES builds(id) ON DELETE CASCADE DEFERRABLE;



--END ==== 1_create_initial_tables.sql ====

--BEGIN ==== 2_create_indexes.sql ====

CREATE INDEX idx_pipeline_name ON pipelines (name);
CREATE INDEX idx_stage_name ON stages (name);
CREATE INDEX idx_properties_key ON properties (key);
CREATE INDEX idx_state_transition ON buildStateTransitions (currentState);
CREATE INDEX idx_build_state ON builds (state);
CREATE INDEX idx_build_name ON builds (name);
CREATE INDEX idx_build_result ON builds (result);
CREATE INDEX idx_build_agent ON builds (agentUuid);

--END ==== 2_create_indexes.sql ====

--BEGIN ==== 3_add_build_ignored_column.sql ====

ALTER TABLE builds ADD COLUMN ignored BOOLEAN DEFAULT false;
CREATE INDEX idx_build_ignored ON builds (ignored);

--END ==== 3_add_build_ignored_column.sql ====

--BEGIN ==== 4_add_check_externals_column.sql ====

ALTER TABLE materials ADD COLUMN checkExternals BOOLEAN DEFAULT false;

--END ==== 4_add_check_externals_column.sql ====

--BEGIN ==== 5_add_from_external_column.sql ====

ALTER TABLE modifications ADD COLUMN fromExternal BOOLEAN DEFAULT false;

--END ==== 5_add_from_external_column.sql ====

--BEGIN ==== 6_add_pipeline_label.sql ====

ALTER TABLE pipelines ADD COLUMN label VARCHAR(255);
CREATE INDEX idx_pipeline_label ON pipelines(label);

CREATE TABLE temp (label VARCHAR(255));
INSERT INTO temp (label) (SELECT id FROM pipelines);
UPDATE pipelines SET label = (SELECT label FROM temp WHERE CAST(temp.label AS BIGINT) = pipelines.id);
DROP TABLE temp;


--END ==== 6_add_pipeline_label.sql ====

--BEGIN ==== 7_add_pipeline_label_counters.sql ====

CREATE SEQUENCE pipelineLabelCounts_id_seq START WITH 1;
CREATE TABLE pipelineLabelCounts (
    id              BIGINT DEFAULT nextval('pipelineLabelCounts_id_seq') PRIMARY KEY,
    pipelineName    VARCHAR(255),
    labelCount      BIGINT
);

ALTER TABLE pipelineLabelCounts ADD CONSTRAINT unique_pipeline_name UNIQUE (pipelineName);

-- Migrate existing pipeline label data to the new counter table

INSERT INTO pipelineLabelCounts (pipelineName, labelCount)
	(SELECT name, MAX(CAST(label AS BIGINT)) FROM pipelines GROUP BY name);


--END ==== 7_add_pipeline_label_counters.sql ====

--BEGIN ==== 8_add_build_cause_buffer.sql ====

CREATE SEQUENCE buildcausebuffer_id_seq START WITH 1;
CREATE TABLE BuildCauseBuffer (
    id                    BIGINT DEFAULT nextval('buildcausebuffer_id_seq') PRIMARY KEY,
    pipelineName          VARCHAR(255) ,
    buildCause            TEXT,
    timestamp             TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE BuildCauseBuffer ADD CONSTRAINT unique_build_buffer_pipeline_name UNIQUE (pipelineName);
--END ==== 8_add_build_cause_buffer.sql ====

--BEGIN ==== 9_add_material_properties_table.sql ====

CREATE SEQUENCE materialProperties_id_seq START WITH 1;
CREATE TABLE materialProperties (
id BIGINT DEFAULT nextval('materialProperties_id_seq') PRIMARY KEY,
materialId INTEGER,
key VARCHAR(255),
value VARCHAR(255),
UNIQUE (materialId, key)
);

ALTER TABLE materialProperties ADD CONSTRAINT fk_materialProperties_materials FOREIGN KEY (materialId) REFERENCES materials(id) ON DELETE CASCADE DEFERRABLE;
--END ==== 9_add_material_properties_table.sql ====

--BEGIN ==== 10_add_stage_timestamp.sql ====

ALTER TABLE stages ADD COLUMN createdTime TIMESTAMP;

--END ==== 10_add_stage_timestamp.sql ====

--BEGIN ==== 11_add_stage_order.sql ====

ALTER TABLE stages ADD COLUMN orderId INTEGER;
CREATE INDEX idx_stages_orderId ON stages(orderId);
UPDATE stages SET orderId = CAST(id as INT);

--END ==== 11_add_stage_order.sql ====

--BEGIN ==== 12_add_stage_result.sql ====

ALTER TABLE Stages ADD result VARCHAR(50);

UPDATE stages
SET result='Cancelled'
WHERE exists
    (select *
    from builds
    where builds.stageId = stages.id
    and builds.result ='Cancelled')
AND stages.result is null;

UPDATE stages
SET result='Failed'
WHERE exists
    (select *
    from builds
    where builds.stageId = stages.id
    and builds.result ='Failed')
AND stages.result is null;

UPDATE stages
SET result='Unknown'
WHERE exists
    (select *
    from builds
    where builds.stageId = stages.id
    and builds.result ='Unknown')
AND stages.result is null;

UPDATE stages
SET result='Passed'
WHERE stages.result is null;

ALTER TABLE stages
ALTER COLUMN result
SET DEFAULT 'Unknown';

ALTER TABLE stages
ALTER COLUMN result
SET NOT NULL;

--END ==== 12_add_stage_result.sql ====

--BEGIN ==== 13_add_stage_approvalType.sql ====

ALTER TABLE stages ADD COLUMN approvalType VARCHAR(255);


UPDATE stages AS a SET approvalType = 'success' WHERE 'cruise' = (SELECT b.approvedBy FROM stages b WHERE b.name = a.name AND b.pipelineId = a.pipelineId ORDER BY b.id ASC LIMIT 1);

UPDATE stages SET approvalType = 'manual' WHERE approvalType != 'success';

--END ==== 13_add_stage_approvalType.sql ====

--BEGIN ==== 14_add_name_pipelineId_index_for_stages.sql ====

CREATE INDEX idx_stages_name_pipelineId ON stages(name, pipelineId);

--END ==== 14_add_name_pipelineId_index_for_stages.sql ====

--BEGIN ==== 15_add_name_agentId_buildid_index_for_builds.sql ====

-- this index is designed to improved the get duration sql, before it is 200ms, now it is 10ms.
CREATE INDEX idx_builds_agentId_stageid_name ON builds (NAME, AGENTUUID, STAGEID, STATE, RESULT);

--END ==== 15_add_name_agentId_buildid_index_for_builds.sql ====

--BEGIN ==== 16_add_folder_to_materials.sql ====

ALTER TABLE materials ADD COLUMN folder varchar(255);

--END ==== 16_add_folder_to_materials.sql ====

--BEGIN ==== 17_correct_integrity_issues_in_stages.sql ====

UPDATE stages SET orderId = CAST(id AS INT) WHERE ORDERID is NULL;

ALTER TABLE stages
ALTER COLUMN result
DROP NOT NULL;

UPDATE stages
SET result=NULL
WHERE result = 'Unknown';

UPDATE stages
SET result='Cancelled'
WHERE exists
    (select *
    from builds
    where builds.stageId = stages.id
    and builds.result ='Cancelled')
AND stages.result is null;

UPDATE stages
SET result='Failed'
WHERE exists
    (select *
    from builds
    where builds.stageId = stages.id
    and builds.result ='Failed')
AND stages.result is null;

UPDATE stages
SET result='Unknown'
WHERE exists
    (select *
    from builds
    where builds.stageId = stages.id
    and builds.result ='Unknown')
AND stages.result is null;

UPDATE stages
SET result='Passed'
WHERE stages.result is null;

ALTER TABLE stages
ALTER COLUMN result
SET NOT NULL;

ALTER TABLE STAGES ALTER COLUMN ORDERID SET NOT NULL;

--END ==== 17_correct_integrity_issues_in_stages.sql ====

--BEGIN ==== 18_change_material_properties_value_to_nvarchar.sql ====

ALTER TABLE materialProperties
ALTER COLUMN value TYPE TEXT;

--END ==== 18_change_material_properties_value_to_nvarchar.sql ====

--BEGIN ==== 19_change_material_url_to_nvarchar.sql ====

ALTER TABLE materials
ALTER COLUMN url TYPE TEXT;

--END ==== 19_change_material_url_to_nvarchar.sql ====

--BEGIN ==== 20_add_artifact_properties_generator_table.sql ====

CREATE SEQUENCE artifactPropertiesGenerator_id_seq START WITH 1;
CREATE TABLE artifactPropertiesGenerator (
id BIGINT DEFAULT nextval('artifactPropertiesGenerator_id_seq') PRIMARY KEY,
jobId BIGINT,
name VARCHAR(255),
src VARCHAR(512),
xpath VARCHAR(512),
regex VARCHAR(512),
generatorType VARCHAR(255),
UNIQUE (jobId, name)
);

ALTER TABLE artifactPropertiesGenerator ADD CONSTRAINT fk_artifactPropertiesGenerator_jobs FOREIGN KEY (jobId) REFERENCES builds(id) ON DELETE CASCADE DEFERRABLE;
--END ==== 20_add_artifact_properties_generator_table.sql ====

--BEGIN ==== 21_add_materialId_to_modifications.sql ====

ALTER TABLE modifications
ADD COLUMN materialId INTEGER;

-- associate modifications with materials

update modifications
SET materialId=
    (SELECT materials.id
    FROM materials
    JOIN pipelines
    ON materials.pipelineId=pipelines.id
    AND pipelines.id=modifications.pipelineId
    LIMIT 1);

CREATE INDEX idx_modifications_materialId ON modifications(materialId);
CREATE INDEX idx_modifications_modifiedtime ON modifications(modifiedtime);

-- copy modifications onto new materials for svn repos with multiple materials
-- this is for some number of historical pipelines that were created when
-- multiple materials support was not complete

INSERT INTO modifications(TYPE, USERNAME, COMMENT, EMAILADDRESS, REVISION, MODIFIEDTIME, PIPELINEID, FROMEXTERNAL, MATERIALID )
SELECT m1.TYPE, m1.USERNAME, m1.COMMENT, m1.EMAILADDRESS, m1.REVISION, m1.MODIFIEDTIME, m1.PIPELINEID, m1.FROMEXTERNAL, materials.ID
FROM modifications m1
JOIN materials on  m1.pipelineid = materials.pipelineid
WHERE not exists(select 1 from modifications where modifications.materialId = materials.id);

ALTER TABLE modifications
ALTER COLUMN materialId SET NOT NULL;

ALTER TABLE modifications
ADD CONSTRAINT fk_modifications_materials
FOREIGN KEY (materialId)
REFERENCES materials(id) ON DELETE CASCADE DEFERRABLE;

--END ==== 21_add_materialId_to_modifications.sql ====

--BEGIN ==== 22_remove_pipelineId_from_modifications.sql ====

ALTER TABLE modifications
DROP CONSTRAINT FK_MODIFICATIONS_PIPELINEID_PIPELINE_ID;

ALTER TABLE modifications
DROP COLUMN pipelineId;

--END ==== 22_remove_pipelineId_from_modifications.sql ====

--BEGIN ==== 23_add_index_for_stages.sql ====

ALTER TABLE stages ADD COLUMN counter INTEGER;
CREATE INDEX idx_stages_counter_index ON stages(counter);
update stages SET counter = (SELECT Count(*)  FROM stages s2 where s2.pipelineid = stages.pipelineid AND s2.name = stages.name AND s2.id<=stages.id);
ALTER TABLE stages ALTER COLUMN counter SET NOT NULL;


--END ==== 23_add_index_for_stages.sql ====

--BEGIN ==== 24_add_columns_for_dependency_materials.sql ====

ALTER TABLE Materials ADD pipelineName VARCHAR(255);
ALTER TABLE Materials ADD stageName VARCHAR(255);

--END ==== 24_add_columns_for_dependency_materials.sql ====

--BEGIN ==== 25_change_length_of_revision_to_1024_for_modifications.sql ====

ALTER TABLE modifications
ALTER COLUMN revision TYPE VARCHAR(1024);

--END ==== 25_change_length_of_revision_to_1024_for_modifications.sql ====

--BEGIN ==== 26_add_table_fetch_artifact_plans.sql ====

CREATE SEQUENCE fetchArtifactPlans_id_seq START WITH 1;
CREATE TABLE fetchArtifactPlans (
id BIGINT DEFAULT nextval('fetchArtifactPlans_id_seq') PRIMARY KEY,
jobId           BIGINT,
pipelineLabel   VARCHAR(255),
pipeline        VARCHAR(255),
stage           VARCHAR(255),
job             VARCHAR(255),
path            VARCHAR(255),
dest            VARCHAR(255)
);

--END ==== 26_add_table_fetch_artifact_plans.sql ====

--BEGIN ==== 27_set_not_null_on_fetch_artifact_plans.sql ====

ALTER TABLE fetchArtifactPlans ALTER COLUMN jobId SET NOT NULL;
ALTER TABLE fetchArtifactPlans ALTER COLUMN pipelineLabel SET NOT NULL;
ALTER TABLE fetchArtifactPlans ALTER COLUMN pipeline SET NOT NULL;
ALTER TABLE fetchArtifactPlans ALTER COLUMN stage SET NOT NULL;
ALTER TABLE fetchArtifactPlans ALTER COLUMN job SET NOT NULL;
ALTER TABLE fetchArtifactPlans ALTER COLUMN path SET NOT NULL;
ALTER TABLE fetchArtifactPlans ALTER COLUMN dest SET NOT NULL;

--END ==== 27_set_not_null_on_fetch_artifact_plans.sql ====

--BEGIN ==== 28_drop_table_fetch_artifacts.sql ====

DROP TABLE IF EXISTS fetchArtifactPlans CASCADE;

--END ==== 28_drop_table_fetch_artifacts.sql ====

--BEGIN ==== 29_fix_hsqldb_migration.sql ====

ALTER TABLE stages DROP CONSTRAINT IF EXISTS FK_STAGES_PIPELINES;
ALTER TABLE materials DROP CONSTRAINT IF EXISTS FK_MATERIALS_PIPELINES;
ALTER TABLE builds DROP CONSTRAINT IF EXISTS FK_BUILDS_STAGES;
ALTER TABLE properties DROP CONSTRAINT IF EXISTS FK_PROPERTIES_BUILDS;
ALTER TABLE artifactPlans DROP CONSTRAINT IF EXISTS FK_ARTIFACTPLANS_BUILDS;
ALTER TABLE resources DROP CONSTRAINT IF EXISTS FK_RESOURCES_BUILDS;
ALTER TABLE modifiedFiles DROP CONSTRAINT IF EXISTS FK_MODIFIEDFILES_MODIFICATIONS;
ALTER TABLE buildstatetransitions DROP CONSTRAINT IF EXISTS FK_BUILDSTATETRANSITIONS_BUILDS;

ALTER TABLE stages ADD CONSTRAINT fk_stages_pipelines FOREIGN KEY (pipelineId) REFERENCES pipelines(id) ON DELETE CASCADE DEFERRABLE;
ALTER TABLE materials ADD CONSTRAINT fk_materials_pipelines FOREIGN KEY (pipelineId) REFERENCES pipelines(id) ON DELETE CASCADE DEFERRABLE;
ALTER TABLE builds ADD CONSTRAINT fk_builds_stages FOREIGN KEY (stageId) REFERENCES stages(id) ON DELETE CASCADE DEFERRABLE;
ALTER TABLE properties ADD CONSTRAINT fk_properties_builds FOREIGN KEY (buildId) REFERENCES builds(id) ON DELETE CASCADE DEFERRABLE;
ALTER TABLE artifactPlans ADD CONSTRAINT fk_artifactplans_builds FOREIGN KEY (buildId) REFERENCES builds(id) ON DELETE CASCADE DEFERRABLE;
ALTER TABLE resources ADD CONSTRAINT fk_resources_builds FOREIGN KEY (buildId) REFERENCES builds(id) ON DELETE CASCADE DEFERRABLE;
ALTER TABLE modifiedFiles ADD CONSTRAINT fk_modifiedFiles_modifications FOREIGN KEY (modificationId) REFERENCES modifications(id) ON DELETE CASCADE DEFERRABLE;
ALTER TABLE buildstatetransitions ADD CONSTRAINT fk_buildstatetransitions_builds FOREIGN KEY (buildId) REFERENCES builds(id) ON DELETE CASCADE DEFERRABLE;

DELETE FROM pipelines WHERE buildCauseType='ErrorBuildCause';

--END ==== 29_fix_hsqldb_migration.sql ====

--BEGIN ==== 30_add_buildcause_message_to_pipeline.sql ====

ALTER TABLE Pipelines ADD buildCauseMessage TEXT;

--END ==== 30_add_buildcause_message_to_pipeline.sql ====

--BEGIN ==== 31_add_user_setting.sql ====

CREATE SEQUENCE usersettings_id_seq START WITH 1;
CREATE TABLE usersettings (
id          BIGINT DEFAULT nextval('usersettings_id_seq') PRIMARY KEY,
name        VARCHAR(255) Not NULL,
email       VARCHAR(255),
matcher     VARCHAR(255));
--END ==== 31_add_user_setting.sql ====

--BEGIN ==== 32_add_email_me_column.sql ====

ALTER TABLE usersettings ADD COLUMN emailme BOOLEAN DEFAULT false;

--END ==== 32_add_email_me_column.sql ====

--BEGIN ==== 33_add_unique_constraint_to_name_column_on_usersettings.sql ====

ALTER TABLE usersettings ADD CONSTRAINT unique_name UNIQUE(name);

--END ==== 33_add_unique_constraint_to_name_column_on_usersettings.sql ====

--BEGIN ==== 34_add_changed_column_to_modifications.sql ====

ALTER TABLE modifications ADD COLUMN changed BOOLEAN DEFAULT false;

--END ==== 34_add_changed_column_to_modifications.sql ====

--BEGIN ==== 35_rename_usersettings_table.sql ====

ALTER TABLE usersettings RENAME TO users;

--END ==== 35_rename_usersettings_table.sql ====

--BEGIN ==== 36_add_notificationfilters_table.sql ====

CREATE SEQUENCE notificationfilters_id_seq START WITH 1;
CREATE TABLE notificationfilters (
id          BIGINT DEFAULT nextval('notificationfilters_id_seq') PRIMARY KEY,
userId      BIGINT,
pipeline    VARCHAR(255),
stage       VARCHAR(255),
event           VARCHAR(50),
myCheckin       BOOLEAN
);

ALTER TABLE notificationfilters ADD CONSTRAINT fk_notificationfilters_users FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

--END ==== 36_add_notificationfilters_table.sql ====

--BEGIN ==== 37_make_the_pipeline_name_case_insensitive.sql ====

-- NOOP -- This has been rolled back

--END ==== 37_make_the_pipeline_name_case_insensitive.sql ====

--BEGIN ==== 38_make_the_stage_name_case_insensitive.sql ====

-- NOOP -- This has been rolled back

--END ==== 38_make_the_stage_name_case_insensitive.sql ====

--BEGIN ==== 39_make_the_job_name_case_insensitive.sql ====

-- NOOP -- This has been rolled back

--END ==== 39_make_the_job_name_case_insensitive.sql ====

--BEGIN ==== 40_undo_pipelines_case_insensitive_change.sql ====

-- NOOP -- This has been rolled back

--END ==== 40_undo_pipelines_case_insensitive_change.sql ====

--BEGIN ==== 41_add_builds_index_on_name_state_and_stageid.sql ====

create index idx_builds_name_state_stageid on builds( name, state, stageid );

--END ==== 41_add_builds_index_on_name_state_and_stageid.sql ====

--BEGIN ==== 42_add_counter_to_pipelines.sql ====

ALTER TABLE pipelines ADD COLUMN counter BIGINT;
CREATE INDEX idx_pipelines_name_counter ON pipelines( name, counter );

--END ==== 42_add_counter_to_pipelines.sql ====

--BEGIN ==== 43_alter_modifiedFiles_fileName.sql ====

ALTER TABLE modifiedFiles ALTER COLUMN fileName TYPE VARCHAR(1024);

--END ==== 43_alter_modifiedFiles_fileName.sql ====

--BEGIN ==== 44_added_name_column_into_material.sql ====

ALTER TABLE materials ADD COLUMN name varchar(255);

--END ==== 44_added_name_column_into_material.sql ====

--BEGIN ==== 45_remove_matcher_from_builds.sql ====

ALTER TABLE builds DROP COLUMN matcher;

--END ==== 45_remove_matcher_from_builds.sql ====

--BEGIN ==== 46_remove_material_properties.sql ====

ALTER TABLE materials ADD COLUMN branch TEXT;
UPDATE materials SET branch = (SELECT props.value FROM MaterialProperties props WHERE props.materialId = materials.id AND props.key = 'branch');

ALTER TABLE materials ADD COLUMN submoduleFolder TEXT;
UPDATE materials SET submoduleFolder = (SELECT props.value FROM MaterialProperties props WHERE props.materialId = materials.id AND props.key = 'submoduleFolder');

ALTER TABLE materials ADD COLUMN useTickets VARCHAR(10);
UPDATE materials SET useTickets = (SELECT props.value FROM MaterialProperties props WHERE props.materialId = materials.id AND props.key = 'useTickets');

ALTER TABLE materials ADD COLUMN view TEXT;
UPDATE materials SET view = (SELECT props.value FROM MaterialProperties props WHERE props.materialId = materials.id AND props.key = 'view');

DROP TABLE materialProperties;

--END ==== 46_remove_material_properties.sql ====

--BEGIN ==== 47_create_new_materials.sql ====

-- fixing bad data
--unsetting unnecessary fields based on material type
UPDATE materials SET url=null, username=null, password=null, checkexternals=null, view=null, branch=null, submodulefolder=null, usetickets=null WHERE type = 'DependencyMaterial';
UPDATE materials SET username=null, password=null, checkexternals=null, pipelineName=null, stageName=null, view=null, branch=null, submodulefolder=null, usetickets=null WHERE type='HgMaterial';
UPDATE materials SET username=null, password=null, checkexternals=null, pipelineName=null, stageName=null, view=null, usetickets=null WHERE type='GitMaterial';
UPDATE materials SET pipelineName=null, stageName=null, view=null, branch=null, submodulefolder=null, usetickets=null WHERE type='SvnMaterial';
UPDATE materials SET checkexternals=null, pipelineName=null, stageName=null, branch=null, submodulefolder=null WHERE type='P4Material';

--unsetting '' values
UPDATE materials SET url=null WHERE TRIM(url)='';
UPDATE materials SET username=null WHERE TRIM(username)='';
UPDATE materials SET password=null WHERE TRIM(password)='';
UPDATE materials SET folder=null WHERE TRIM(folder)='';
UPDATE materials SET pipelineName=null WHERE TRIM(pipelineName)='';
UPDATE materials SET stageName=null WHERE TRIM(stageName)='';
UPDATE materials SET name=null WHERE TRIM(name)='';
UPDATE materials SET view=null WHERE TRIM(view)='';
UPDATE materials SET branch=null WHERE TRIM(branch)='';
UPDATE materials SET submoduleFolder=null WHERE TRIM(submoduleFolder)='';
UPDATE materials SET useTickets=null WHERE TRIM(useTickets)='';

-- create table
CREATE SEQUENCE newMaterials_id_seq START WITH 1;
CREATE TABLE newMaterials (
    id BIGINT DEFAULT nextval('newMaterials_id_seq') PRIMARY KEY,
    type VARCHAR(255),
    url TEXT,
    username VARCHAR(255),
    password VARCHAR(255),
    checkexternals BOOLEAN DEFAULT FALSE,
    pipelinename VARCHAR(255),
    stagename VARCHAR(255),
    view TEXT,
    branch TEXT,
    submodulefolder TEXT,
    usetickets VARCHAR(10),
    fingerprint CHAR(64)
);

INSERT INTO newMaterials(type, url, username, password, checkexternals, pipelineName, stageName, view, branch, submoduleFolder, useTickets)
  SELECT DISTINCT type, url, username, '', checkexternals, pipelineName, stageName, view, branch, submoduleFolder, useTickets FROM materials;

-- choose the latest password for each material to avoid duplicating materials
UPDATE newmaterials A SET password =
  (SELECT password FROM materials WHERE id =
    ( SELECT max(B.id)
      FROM  materials B
      WHERE (A.type=B.type OR (A.type IS NULL AND B.type IS NULL)) AND
            (A.url=B.url OR (A.url IS NULL AND B.url IS NULL)) AND
            (A.username=B.username OR (A.username IS NULL AND B.username IS NULL)) AND
            (A.checkexternals=B.checkexternals  OR (A.checkexternals IS NULL AND B.checkexternals IS NULL)) AND
            (A.pipelineName=B.pipelineName  OR (A.pipelineName IS NULL AND B.pipelineName IS NULL)) AND
            (A.stageName=B.stageName  OR (A.stageName IS NULL AND B.stageName IS NULL)) AND
            (A.view=B.view  OR (A.view IS NULL AND B.view IS NULL)) AND
            (A.branch=B.branch  OR (A.branch IS NULL AND B.branch  IS NULL)) AND
            (A.submoduleFolder=B.submoduleFolder  OR (A.submoduleFolder IS NULL AND B.submoduleFolder IS NULL)) AND
            (A.useTickets=B.useTickets OR (A.useTickets IS NULL AND B.useTickets IS NULL))
      GROUP BY B.type, B.url, B.username, B.checkexternals, B.pipelineName, B.stageName, B.view, B.branch, B.submoduleFolder, B.useTickets
    )
  );

CREATE EXTENSION IF NOT EXISTS pgcrypto;
UPDATE newMaterials SET fingerprint =
  CASE type
      WHEN 'DependencyMaterial'
        THEN DIGEST(concat('type=', type, '<|>', 'pipelineName=', pipelineName, '<|>', 'stageName=', stageName), 'sha256')
      WHEN 'HgMaterial'
        THEN DIGEST(concat('type=', type, '<|>', 'url=', url), 'sha256')
      WHEN 'GitMaterial'
        THEN DIGEST(concat('type=', type, '<|>', 'url=', url, '<|>', 'branch=', branch), 'sha256')
      WHEN 'SvnMaterial'
        THEN DIGEST(concat('type=', type, '<|>', 'url=', url, '<|>', 'username=', username, '<|>', 'checkExternals=', checkExternals), 'sha256')
      WHEN 'P4Material'
        THEN DIGEST(concat('type=', type, '<|>', 'url=', url, '<|>', 'username=', username, '<|>', 'view=', view), 'sha256')
    END;

-- point material to newMaterial
ALTER TABLE materials ADD COLUMN newMaterialId BIGINT;

UPDATE materials m SET newMaterialId =
  (
    SELECT n.id
    FROM newMaterials n
    WHERE ((m.type IS NULL AND n.type IS NULL) OR (m.type = n.type))
      AND ((m.url IS NULL AND n.url IS NULL) OR (m.url = n.url))
      AND ((m.username IS NULL AND n.username IS NULL) OR (m.username = n.username))
      AND ((m.checkexternals IS NULL AND n.checkexternals IS NULL) OR (m.checkexternals = n.checkexternals))
      AND ((m.pipelineName IS NULL AND n.pipelineName IS NULL) OR (m.pipelineName = n.pipelineName))
      AND ((m.stageName IS NULL AND n.stageName IS NULL) OR (m.stageName = n.stageName))
      AND ((m.view IS NULL AND n.view IS NULL) OR (m.view = n.view))
      AND ((m.branch IS NULL AND n.branch IS NULL) OR (m.branch = n.branch))
      AND ((m.submoduleFolder IS NULL AND n.submoduleFolder IS NULL) OR (m.submoduleFolder = n.submoduleFolder))
      AND ((m.useTickets IS NULL AND n.useTickets IS NULL) OR (m.useTickets = n.useTickets))
  );

-- point modifications to newMaterials
ALTER TABLE modifications ADD COLUMN newMaterialId BIGINT;

UPDATE modifications set newMaterialId = (SELECT newMaterialId FROM materials WHERE materials.id = modifications.materialId);

CREATE SEQUENCE seq_ordered_modifications START WITH 1;

CREATE TABLE ordered_modifications AS
  SELECT nextval('seq_ordered_modifications') newModificationId, *
    FROM (
      SELECT mo.*
      FROM modifications mo
        INNER JOIN materials ma ON mo.materialid = ma.id
      ORDER BY ma.id ASC, mo.id DESC) AS temp_table;

CREATE INDEX idx_ordered_mods_id ON ordered_modifications(id);
CREATE INDEX idx_ordered_mods_newMaterialId ON ordered_modifications(newMaterialId);
CREATE INDEX idx_ordered_mods_materialId ON ordered_modifications(materialId);
CREATE INDEX idx_ordered_mods_newModificationId ON ordered_modifications(newModificationId);


-- Delete duplicate modifications
CREATE TABLE unique_modifications AS
  SELECT newMaterialId, revision, MIN(newModificationId) AS realModificationId
    FROM ordered_modifications
  GROUP BY newMaterialid, revision;


CREATE INDEX idx_unique_mods_newMaterialId_revisions ON unique_modifications(newMaterialId, revision);
CREATE INDEX idx_unique_mods_id ON unique_modifications(realModificationId);

CREATE TABLE unique_modifications_with_all_columns AS
  SELECT om.*
  FROM unique_modifications um
    INNER JOIN ordered_modifications om ON om.newModificationId = um.realModificationId;

-- sanity check to ensure we have unique newModificationIds
ALTER TABLE unique_modifications_with_all_columns ADD CONSTRAINT unq_newModiId UNIQUE (newModificationId);


-- add the new PipelineMaterialRevisions table
CREATE SEQUENCE PipelineMaterialRevisions_id_seq START WITH 1;
CREATE TABLE PipelineMaterialRevisions (
   id BIGINT DEFAULT nextval('PipelineMaterialRevisions_id_seq') PRIMARY KEY,
   folder VARCHAR(255),
   name VARCHAR(255),
   pipelineId BIGINT NOT NULL,
   toRevisionId BIGINT NOT NULL,
   fromRevisionId BIGINT NOT NULL,
   changed BOOLEAN DEFAULT FALSE
);

-- set newModificationId on ordered_modifications so we can use it to create PMRs
UPDATE ordered_modifications om SET newModificationId =
  (SELECT realModificationId
  FROM unique_modifications um
  WHERE um.newMaterialId = om.newMaterialId
    AND um.revision = om.revision);

--- helper indexes to speed up next insert
CREATE INDEX idx_new_material_id ON materials(newMaterialId);
CREATE INDEX idx_mod_new_material_id ON modifications(newMaterialId);

INSERT INTO PipelineMaterialRevisions(name, folder, pipelineId, fromRevisionId, toRevisionId, changed)
  SELECT name, folder, pipelineId,
          (SELECT newModificationId FROM ordered_modifications WHERE id = (SELECT MAX(id) FROM ordered_modifications om WHERE om.materialId = m.id)),
          (SELECT newModificationId FROM ordered_modifications WHERE id = (SELECT MIN(id) FROM ordered_modifications om WHERE om.materialId = m.id)),
          (SELECT changed FROM ordered_modifications om WHERE om.materialId = m.id LIMIT 1)
  FROM materials m;

CREATE INDEX idx_pmr_pipeline_id ON pipelineMaterialRevisions (pipelineId);

-- Fix modifications
ALTER TABLE modifiedFiles DROP CONSTRAINT FK_MODIFIEDFILES_MODIFICATIONS;
DELETE FROM modifications;

ALTER TABLE modifications ADD COLUMN newModificationId BIGINT;
ALTER TABLE modifications DROP COLUMN changed;

INSERT INTO modifications
  (id, type, username, comment, emailAddress, revision, modifiedTime, fromExternal, materialId, newMaterialId, newModificationId)
  SELECT id, type, username, comment, emailAddress, revision, modifiedTime, fromExternal, materialId, newMaterialId, newModificationId
    FROM unique_modifications_with_all_columns;

-- Fix modifiedFiles reference to modification.id
ALTER TABLE modifiedFiles ADD COLUMN newModificationId BIGINT;



UPDATE modifiedFiles mf SET newModificationId = (
  SELECT newModificationId
  FROM modifications mod
  WHERE mod.id = mf.modificationId);

DELETE FROM modifiedFiles WHERE newModificationId IS NULL;
UPDATE modifiedFiles SET modificationId = newModificationId;
ALTER TABLE modifiedFiles DROP COLUMN newModificationId;

-- Fix modification.id to be the new id
UPDATE modifications SET id = newModificationId;
ALTER TABLE modifications DROP COLUMN newModificationId;
ALTER TABLE modifiedFiles ADD CONSTRAINT FK_MODIFIEDFILES_MODIFICATIONS FOREIGN KEY (modificationId) REFERENCES modifications(id) ON DELETE CASCADE DEFERRABLE;

DROP TABLE unique_modifications_with_all_columns;
DROP TABLE unique_modifications;
DROP TABLE ordered_modifications;
DROP SEQUENCE seq_ordered_modifications;


-- Removing the following foreign-keys because hibernate AND ibatis use different connections AND therefore different transactions,
-- resulting in tests failing to see referenced objects, e.g. Pipeline is saved but not committed AND trying to save PMR bombs
--ALTER TABLE pipelineMaterialRevisions ADD CONSTRAINT fk_pmr_pipeline_id FOREIGN KEY (pipelineId) REFERENCES pipelines (id);
ALTER TABLE pipelineMaterialRevisions ADD CONSTRAINT fk_pmr_from_revision FOREIGN KEY (fromRevisionId) REFERENCES modifications (id) DEFERRABLE;
ALTER TABLE pipelineMaterialRevisions ADD CONSTRAINT fk_pmr_to_revision FOREIGN KEY (toRevisionId) REFERENCES modifications (id) DEFERRABLE;


-- Rename newMaterials to materials
ALTER TABLE modifications DROP CONSTRAINT fk_modifications_materials;
ALTER TABLE modifications DROP COLUMN materialId;
DROP TABLE materials;

ALTER TABLE newMaterials RENAME TO materials;

--ALTER TABLE modifications ADD CONSTRAINT fk_modifications_materials FOREIGN KEY (newMaterialId) REFERENCES materials(id);

-- Rename newMaterialId
ALTER TABLE modifications RENAME COLUMN newMaterialId TO materialId;

-- Make fingerprint unique AND not null
ALTER TABLE materials ALTER COLUMN fingerprint SET NOT NULL;
ALTER TABLE materials ADD CONSTRAINT unique_fingerprint UNIQUE (fingerprint);


--END ==== 47_create_new_materials.sql ====

--BEGIN ==== 48_add_name_to_material_instance.sql ====

ALTER TABLE materials ADD flyweightName VARCHAR(50);
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
UPDATE materials SET flyweightName = uuid_generate_v4() WHERE flyweightName IS NULL;

ALTER TABLE materials ADD CONSTRAINT materials_FlyweightName_unique UNIQUE(flyweightName);
ALTER TABLE materials ALTER COLUMN flyweightName SET NOT NULL;


--END ==== 48_add_name_to_material_instance.sql ====

--BEGIN ==== 49_add_unique_constraint_to_revisions.sql ====

ALTER TABLE modifications ADD CONSTRAINT unique_revision UNIQUE (materialId, revision);


--END ==== 49_add_unique_constraint_to_revisions.sql ====

--BEGIN ==== 50_add_run_on_all_agents_to_builds.sql ====

alter table builds add column runOnAllAgents boolean default false;

--END ==== 50_add_run_on_all_agents_to_builds.sql ====

--BEGIN ==== 51_add_environment_variable_properties.sql ====

CREATE SEQUENCE environmentVariables_id_seq START WITH 1;
CREATE TABLE environmentVariables (
id BIGINT DEFAULT nextval('environmentVariables_id_seq') PRIMARY KEY,
jobId           BIGINT,
variableName   VARCHAR(255),
variableValue        TEXT
);

--END ==== 51_add_environment_variable_properties.sql ====

--BEGIN ==== 52_add_pipeline_lock.sql ====

ALTER TABLE pipelines ADD locked BOOLEAN DEFAULT false NOT NULL;

--END ==== 52_add_pipeline_lock.sql ====

--BEGIN ==== 53_add_index_on_pipelines_locked.sql ====


-- this index makes the "lockedPipeline" query faster (was causing sluggishness on Mingle Cruise)
CREATE INDEX idx_pipelines_locked ON pipelines(locked);

--END ==== 53_add_index_on_pipelines_locked.sql ====

--BEGIN ==== 54_add_stage_id_to_build_transitions.sql ====

ALTER TABLE buildstatetransitions ADD COLUMN stageId BIGINT;

update buildstatetransitions set stageId=(select stageId from builds where id=buildstatetransitions.buildId);

ALTER TABLE buildstatetransitions ADD CONSTRAINT fk_buildtransitions_stages FOREIGN KEY (stageId) REFERENCES stages(id) DEFERRABLE;

--END ==== 54_add_stage_id_to_build_transitions.sql ====

--BEGIN ==== 55_add_completed_at_transition_id_to_stages.sql ====

ALTER TABLE stages ADD COLUMN completedByTransitionId BIGINT;

UPDATE stages SET completedByTransitionId = -1 WHERE id IN
    (SELECT DISTINCT b.stageid FROM builds b WHERE state <> 'Completed' and state <> 'Rescheduled');

CREATE INDEX idx_stages_completedByTransitionId ON stages (completedByTransitionId DESC);

UPDATE stages SET completedByTransitionId =
    (SELECT MAX(bst.id) FROM buildstatetransitions bst WHERE bst.stageid = stages.id) WHERE completedByTransitionId IS null;

UPDATE stages SET completedByTransitionId = null WHERE completedByTransitionId = -1;

--END ==== 55_add_completed_at_transition_id_to_stages.sql ====

--BEGIN ==== 56_create_index_on_environment_variables_job_id.sql ====


CREATE INDEX idx_env_job_id ON environmentVariables (jobId);

--END ==== 56_create_index_on_environment_variables_job_id.sql ====

--BEGIN ==== 57_add_state_to_stage.sql ====


ALTER TABLE stages ADD state VARCHAR(50) DEFAULT 'Unknown' NOT NULL;
UPDATE stages SET state = result;

--END ==== 57_add_state_to_stage.sql ====

--BEGIN ==== 58_add_natural_order_to_pipelines.sql ====


ALTER TABLE pipelines ADD naturalOrder FLOAT DEFAULT 0.0 NOT NULL;

--END ==== 58_add_natural_order_to_pipelines.sql ====

--BEGIN ==== 59_create_index_on_stages_state.sql ====

create index idx_stages_state on stages(state);

--END ==== 59_create_index_on_stages_state.sql ====

--BEGIN ==== 60_support_for_variables_at_different_levels.sql ====


ALTER TABLE environmentVariables ADD entityType VARCHAR(100);
UPDATE environmentVariables SET entityType='Job';
ALTER TABLE environmentVariables ALTER COLUMN entityType SET NOT NULL;
ALTER TABLE environmentVariables RENAME COLUMN jobId TO entityId;

--END ==== 60_support_for_variables_at_different_levels.sql ====

--BEGIN ==== 61_migrate_old_pipelines_to_have_counter.sql ====

UPDATE pipelines SET counter=(id - (SELECT MAX(id) FROM pipelines WHERE counter IS null) - 1) WHERE counter IS null;

--END ==== 61_migrate_old_pipelines_to_have_counter.sql ====

--BEGIN ==== 62_migrate_dependency_modifications_to_use_pipeline_counter_based_stage_locator.sql ====

ALTER TABLE modifications ADD counterBasedRevision VARCHAR(1024);
ALTER TABLE modifications ADD materialType VARCHAR(255);
UPDATE modifications m1 SET materialType = (SELECT materials.type FROM modifications m2 INNER JOIN materials on m2.materialid = materials.id WHERE m1.id = m2.id);
UPDATE modifications m1 SET counterBasedRevision = revision WHERE materialType = 'DependencyMaterial' AND revision ~ '.*\/\d+\[.*\]\/.*\/.*';
UPDATE modifications SET counterBasedRevision = REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(counterBasedRevision, '^.*?\/', ''), '\/.*', ''), '\[.*', '') WHERE counterBasedRevision IS NOT NULL;
UPDATE modifications SET counterBasedRevision = REGEXP_REPLACE(revision, '\d+\[.*?\]', counterBasedRevision) WHERE counterBasedRevision IS NOT NULL;

ALTER TABLE modifications ADD pipelineName VARCHAR(255);
ALTER TABLE modifications ADD pipelineLabel VARCHAR(255);
ALTER TABLE modifications ADD stageName VARCHAR(255);
ALTER TABLE modifications ADD stageCounter VARCHAR(255);
ALTER TABLE modifications ADD pipelineCounter VARCHAR(255);

UPDATE modifications SET
    pipelineName = REGEXP_REPLACE(revision, '\/.*', ''),
    pipelineLabel = REGEXP_REPLACE(REGEXP_REPLACE(revision, '^.*?\/', ''), '\/.*', ''),
    stageName = REGEXP_REPLACE(REGEXP_REPLACE(revision, '^.*?\/.*?\/', ''), '\/.*', ''),
    stageCounter = REGEXP_REPLACE(revision, '^.*?\/.*?\/.*?\/', '')
        WHERE counterBasedRevision IS NULL AND materialType = 'DependencyMaterial';

CREATE TABLE pipelineStages AS (SELECT p.name AS pipelineName, p.counter AS pipelineCounter, p.label AS pipelineLabel, s.name AS stageName, s.counter AS stageCounter FROM stages s INNER JOIN pipelines p ON s.pipelineId = p.id);

CREATE INDEX TMP_IDX_PIPELINE_STAGES_LABEL ON pipelineStages(pipelineName, pipelineLabel, stageName, stageCounter);
CREATE INDEX TMP_IDX_PIPELINE_STAGES_COUNTER ON pipelineStages(pipelineName, pipelineCounter, stageName, stageCounter);

UPDATE modifications AS m SET pipelineCounter = (SELECT MIN(ps.pipelineCounter) FROM pipelineStages ps WHERE ps.pipelineName = m.pipelineName AND ps.pipelineLabel = m.pipelineLabel AND ps.stageName = m.stageName AND CAST(ps.stageCounter AS BIGINT) = CAST(m.stageCounter AS BIGINT)) where materialType = 'DependencyMaterial';

UPDATE modifications SET counterBasedRevision = CONCAT(pipelineName, '/', pipelineCounter, '/', stageName, '/', stageCounter) WHERE pipelineCounter IS NOT NULL;

UPDATE modifications SET counterBasedRevision = revision WHERE counterBasedRevision IS NULL AND materialType = 'DependencyMaterial';

ALTER TABLE modifications ADD uniqueModificationId bigint;
CREATE INDEX TMP_IDX_UNIQUE_MODIFICATION_ID ON modifications(counterBasedRevision);
UPDATE modifications m1 SET uniqueModificationId = (SELECT MIN(id) FROM modifications m2 WHERE m2.counterBasedRevision = m1.counterBasedRevision AND m2.materialType = 'DependencyMaterial');
UPDATE modifications SET uniqueModificationId = id WHERE uniqueModificationId IS NULL;
UPDATE pipelineMaterialRevisions pmr SET toRevisionId = (SELECT uniqueModificationId FROM modifications m WHERE pmr.toRevisionId = m.id);
UPDATE pipelineMaterialRevisions pmr SET fromRevisionId = (SELECT uniqueModificationId FROM modifications m WHERE pmr.fromRevisionId = m.id);

DELETE FROM modifications WHERE id <> uniqueModificationId;

UPDATE modifications SET revision = counterBasedRevision WHERE materialType = 'DependencyMaterial';

UPDATE modifications m SET pipelineLabel = (SELECT ps.pipelineLabel FROM pipelineStages ps WHERE ps.pipelineName = m.pipelineName AND CAST(ps.pipelineCounter AS BIGINT) = CAST(m.pipelineCounter AS BIGINT) AND ps.stageName = m.stageName AND CAST(ps.stageCounter AS BIGINT) = CAST(m.stageCounter AS BIGINT)) where materialType = 'DependencyMaterial';

DROP INDEX TMP_IDX_UNIQUE_MODIFICATION_ID;
DROP INDEX TMP_IDX_PIPELINE_STAGES_LABEL;
DROP INDEX TMP_IDX_PIPELINE_STAGES_COUNTER;
DROP TABLE pipelineStages;
ALTER TABLE modifications DROP COLUMN counterBasedRevision;
ALTER TABLE modifications DROP COLUMN uniqueModificationId;
ALTER TABLE modifications DROP COLUMN materialType;
ALTER TABLE modifications DROP COLUMN pipelineName;
ALTER TABLE modifications DROP COLUMN pipelineCounter;
ALTER TABLE modifications DROP COLUMN stageName;
ALTER TABLE modifications DROP COLUMN stageCounter;

--END ==== 62_migrate_dependency_modifications_to_use_pipeline_counter_based_stage_locator.sql ====

--BEGIN ==== 63_add_schedule_to_and_from_revisions.sql ====

ALTER TABLE pipelinematerialrevisions ADD scheduleTimeFromRevisionId BIGINT;
ALTER TABLE pipelinematerialrevisions ADD scheduleTimeToRevisionId BIGINT;

UPDATE pipelinematerialrevisions SET scheduleTimeFromRevisionId = fromRevisionId;
UPDATE pipelinematerialrevisions SET scheduleTimeToRevisionId = toRevisionId;

ALTER TABLE pipelineMaterialRevisions ADD CONSTRAINT fk_pmr_schedule_time_from_revision FOREIGN KEY (scheduleTimeFromRevisionId) REFERENCES modifications (id) DEFERRABLE;
ALTER TABLE pipelineMaterialRevisions ADD CONSTRAINT fk_pmr_schedule_time_to_revision FOREIGN KEY (scheduleTimeToRevisionId) REFERENCES modifications (id) DEFERRABLE;

ALTER TABLE pipelineMaterialRevisions ALTER COLUMN scheduleTimeFromRevisionId SET NOT NULL;
ALTER TABLE pipelineMaterialRevisions ALTER COLUMN scheduleTimeToRevisionId SET NOT NULL;


--END ==== 63_add_schedule_to_and_from_revisions.sql ====

--BEGIN ==== 64_populate_missing_pipeline_label_in_modifications.sql ====

ALTER TABLE modifications ADD materialType VARCHAR(255);
ALTER TABLE modifications ADD pipelineName VARCHAR(255);
ALTER TABLE modifications ADD pipelineCounter VARCHAR(255);

UPDATE modifications m1 SET materialType = (SELECT materials.type FROM modifications m2 INNER JOIN materials on m2.materialid = materials.id WHERE m1.id = m2.id);

UPDATE modifications SET
       pipelineName = REGEXP_REPLACE(revision, '\/.*', ''),
       pipelineCounter = REGEXP_REPLACE(REGEXP_REPLACE(revision, '^.*?\/', ''), '\/.*', '')
            WHERE materialType = 'DependencyMaterial' AND pipelineLabel IS NULL;

UPDATE modifications AS m SET pipelineLabel = (SELECT p.label FROM pipelines p WHERE p.name = m.pipelineName AND CAST(p.counter AS BIGINT) = CAST(m.pipelineCounter AS BIGINT)) WHERE pipelineCounter ~ ('\d+') AND pipelineLabel IS NULL;

ALTER TABLE modifications DROP COLUMN materialType;
ALTER TABLE modifications DROP COLUMN pipelineName;
ALTER TABLE modifications DROP COLUMN pipelineCounter;

--END ==== 64_populate_missing_pipeline_label_in_modifications.sql ====

--BEGIN ==== 65_repoint_FROM_to_TO_for_dependency_pmr.sql ====

ALTER TABLE pipelineMaterialRevisions ADD materialType VARCHAR(255);

UPDATE pipelineMaterialRevisions pmr SET materialType = (SELECT m.type FROM modifications mods INNER JOIN materials m on mods.materialId = m.id WHERE mods.id = pmr.toRevisionId);

UPDATE pipelineMaterialRevisions SET fromRevisionId = toRevisionId, scheduleTimeFromRevisionId = scheduleTimeToRevisionId WHERE materialType = 'DependencyMaterial';

ALTER TABLE pipelineMaterialRevisions DROP COLUMN materialType;

--END ==== 65_repoint_FROM_to_TO_for_dependency_pmr.sql ====

--BEGIN ==== 66_remove_schedule_to_and_from_revisions.sql ====

UPDATE pipelinematerialrevisions  SET fromRevisionId = scheduleTimeFromRevisionId;
UPDATE pipelinematerialrevisions SET toRevisionId = scheduleTimeToRevisionId;

ALTER TABLE pipelinematerialrevisions DROP CONSTRAINT fk_pmr_schedule_time_to_revision;
ALTER TABLE pipelinematerialrevisions DROP CONSTRAINT fk_pmr_schedule_time_from_revision;

ALTER TABLE pipelinematerialrevisions DROP COLUMN scheduleTimeToRevisionId;
ALTER TABLE pipelinematerialrevisions DROP COLUMN scheduleTimeFromRevisionId;

--END ==== 66_remove_schedule_to_and_from_revisions.sql ====

--BEGIN ==== 67_create_pipeline_selections_table.sql ====

CREATE SEQUENCE pipelineSelections_id_seq START WITH 1;
CREATE TABLE pipelineSelections (
  id BIGINT DEFAULT nextval('pipelineSelections_id_seq') PRIMARY KEY,
  unselectedPipelines TEXT,
  lastUpdate TIMESTAMP
);
--END ==== 67_create_pipeline_selections_table.sql ====

--BEGIN ==== 68_add_foreign_key_from_pmr_to_pipeline.sql ====

ALTER TABLE pipelineMaterialRevisions ADD CONSTRAINT fk_pmr_pipeline FOREIGN KEY (pipelineId) REFERENCES pipelines(id) DEFERRABLE;

--END ==== 68_add_foreign_key_from_pmr_to_pipeline.sql ====

--BEGIN ==== 69_create_index_on_builds_name_and_stage_id.sql ====

CREATE INDEX idx_builds_name_stage_id ON builds(name, stageid);

--END ==== 69_create_index_on_builds_name_and_stage_id.sql ====

--BEGIN ==== 70_change_pipeline_stage_and_job_name_to_varchar_ignorecase.sql ====

CREATE EXTENSION IF NOT EXISTS citext;
ALTER TABLE pipelines ALTER COLUMN name TYPE CITEXT;
ALTER TABLE stages    ALTER COLUMN name TYPE CITEXT;
ALTER TABLE builds    ALTER COLUMN name TYPE CITEXT;

--END ==== 70_change_pipeline_stage_and_job_name_to_varchar_ignorecase.sql ====

--BEGIN ==== 71_add_latest_run_flag_on_stage.sql ====

ALTER TABLE stages ADD latestRun boolean NOT NULL DEFAULT FALSE;
CREATE TABLE tmpStage AS (SELECT MAX(id) id FROM stages GROUP BY pipelineId, name);
UPDATE stages SET id = (SELECT id FROM tmpStage WHERE tmpStage.id = stages.id), latestRun = true;
DROP TABLE tmpStage;

CREATE INDEX idx_stages_name_latestRun_result ON stages(name, latestRun, result);

--END ==== 71_add_latest_run_flag_on_stage.sql ====

--BEGIN ==== 72_create_builds_view.sql ====

CREATE VIEW _builds AS
SELECT b.*,
  p.id pipelineId, p.name pipelineName, p.label pipelineLabel, p.counter pipelineCounter,
  s.name stageName, s.counter stageCounter
FROM builds b
  INNER JOIN stages s ON s.id = b.stageId
  INNER JOIN pipelines p ON p.id = s.pipelineId;

--END ==== 72_create_builds_view.sql ====

--BEGIN ==== 73_create_stages_view.sql ====

CREATE VIEW _stages AS
SELECT s.*,
  p.name pipelineName, p.buildCauseType, p.buildCauseBy, p.label pipelineLabel, p.buildCauseMessage, p.counter pipelineCounter, p.locked, p.naturalOrder
FROM stages s
  INNER JOIN pipelines p ON p.id = s.pipelineId;

--END ==== 73_create_stages_view.sql ====

--BEGIN ==== 74_add_unique_constraint_for_stages_on_pipelineId_name_counter.sql ====

ALTER TABLE stages ADD CONSTRAINT unique_pipeline_id_name_counter UNIQUE(pipelineId, name, counter);

--END ==== 74_add_unique_constraint_for_stages_on_pipelineId_name_counter.sql ====

--BEGIN ==== 75_create_agent_cookie_mapping_table.sql ====

CREATE SEQUENCE agents_id_seq START WITH 1;
CREATE TABLE agents (
  id BIGINT DEFAULT nextval('agents_id_seq') PRIMARY KEY,
  uuid VARCHAR(40) UNIQUE NOT NULL,
  cookie VARCHAR(40) UNIQUE NOT NULL
);

--END ==== 75_create_agent_cookie_mapping_table.sql ====

--BEGIN ==== 76_create_oauth_tables.sql ====

CREATE SEQUENCE oauthclients_id_seq START WITH 1;
CREATE TABLE oauthclients (
  id BIGINT DEFAULT nextval('oauthclients_id_seq') PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  clientId VARCHAR(255) UNIQUE NOT NULL,
  clientSecret VARCHAR(255) NOT NULL,
  redirectUri VARCHAR(255) NOT NULL);

CREATE SEQUENCE oauthauthorizations_id_seq START WITH 1;
CREATE TABLE oauthauthorizations (
  id BIGINT DEFAULT nextval('oauthauthorizations_id_seq') PRIMARY KEY,
  userId VARCHAR(255) NOT NULL,
  oauthClientId BIGINT,
  code VARCHAR(255) UNIQUE NOT NULL,
  expiresAt BIGINT
);

ALTER TABLE oauthauthorizations ADD CONSTRAINT fk_oauth_authorization_oauth_client FOREIGN KEY (oauthClientId) REFERENCES oauthclients(id) DEFERRABLE;

CREATE SEQUENCE oauthtokens_id_seq START WITH 1;
CREATE TABLE oauthtokens (
  id BIGINT DEFAULT nextval('oauthtokens_id_seq') PRIMARY KEY,
  userId VARCHAR(255) NOT NULL,
  oauthClientId BIGINT,
  accessToken VARCHAR(255) UNIQUE NOT NULL,
  refreshToken VARCHAR(255) UNIQUE NOT NULL,
  expiresAt BIGINT
);

ALTER TABLE oauthtokens ADD CONSTRAINT fk_oauth_token_oauth_client FOREIGN KEY (oauthClientId) REFERENCES oauthclients(id) DEFERRABLE;

--END ==== 76_create_oauth_tables.sql ====

--BEGIN ==== 77_add_enabled_to_users.sql ====

ALTER TABLE users ADD enabled boolean NOT NULL DEFAULT TRUE;

--END ==== 77_add_enabled_to_users.sql ====

--BEGIN ==== 78_add_fetchMaterials_to_stages.sql ====

ALTER TABLE stages ADD fetchMaterials boolean DEFAULT true NOT NULL;

--END ==== 78_add_fetchMaterials_to_stages.sql ====

--BEGIN ==== 79_recreate_build_and_stages_views.sql ====


-- recreate the view from 72_create_builds_view.sql and 73_create_stages_view.sql since H2 does not automatically include new columns into views

DROP VIEW _builds;

CREATE VIEW _builds AS
SELECT b.*,
  p.id pipelineId, p.name pipelineName, p.label pipelineLabel, p.counter pipelineCounter,
  s.name stageName, s.counter stageCounter, s.fetchMaterials
FROM builds b
  INNER JOIN stages s ON s.id = b.stageId
  INNER JOIN pipelines p ON p.id = s.pipelineId;


DROP VIEW _stages;

CREATE VIEW _stages AS
SELECT s.*,
  p.name pipelineName, p.buildCauseType, p.buildCauseBy, p.label pipelineLabel, p.buildCauseMessage, p.counter pipelineCounter, p.locked, p.naturalOrder
FROM stages s
  INNER JOIN pipelines p ON p.id = s.pipelineId;

--END ==== 79_recreate_build_and_stages_views.sql ====

--BEGIN ==== 80_add_cleanWorkingDir_to_stages.sql ====

ALTER TABLE stages ADD cleanWorkingDir boolean DEFAULT false NOT NULL;

--END ==== 80_add_cleanWorkingDir_to_stages.sql ====

--BEGIN ==== 81_recreate_build_and_stages_views.sql ====


-- recreate the view from 72_create_builds_view.sql and 73_create_stages_view.sql since H2 does not automatically include new columns into views

DROP VIEW _builds;

CREATE VIEW _builds AS
SELECT b.*,
  p.id pipelineId, p.name pipelineName, p.label pipelineLabel, p.counter pipelineCounter,
  s.name stageName, s.counter stageCounter, s.fetchMaterials, s.cleanWorkingDir
FROM builds b
  INNER JOIN stages s ON s.id = b.stageId
  INNER JOIN pipelines p ON p.id = s.pipelineId;


DROP VIEW _stages;

CREATE VIEW _stages AS
SELECT s.*,
  p.name pipelineName, p.buildCauseType, p.buildCauseBy, p.label pipelineLabel, p.buildCauseMessage, p.counter pipelineCounter, p.locked, p.naturalOrder
FROM stages s
  INNER JOIN pipelines p ON p.id = s.pipelineId;

--END ==== 81_recreate_build_and_stages_views.sql ====

--BEGIN ==== 82_make_oauth_client_names_unique.sql ====

ALTER TABLE oauthclients ADD CONSTRAINT unique_oauth_client_name UNIQUE(name);

--END ==== 82_make_oauth_client_names_unique.sql ====

--BEGIN ==== 83_create_gadget_oauth_tables.sql ====

CREATE SEQUENCE gadgetOauthClients_id_seq START WITH 1;
CREATE TABLE gadgetOauthClients (
  id BIGINT DEFAULT nextval('gadgetOauthClients_id_seq') PRIMARY KEY,
  oauthAuthorizeUrl VARCHAR(255) UNIQUE NOT NULL,
  clientId VARCHAR(255) NOT NULL,
  clientSecret VARCHAR(255) NOT NULL,
  serviceName VARCHAR(255) UNIQUE NOT NULL
);

CREATE SEQUENCE gadgetOauthAccessTokens_id_seq START WITH 1;
CREATE TABLE gadgetOauthAccessTokens (
  id BIGINT DEFAULT nextval('gadgetOauthAccessTokens_id_seq') PRIMARY KEY,
  userId VARCHAR(255) NOT NULL,
  accessToken VARCHAR(255) NOT NULL,
  refreshToken VARCHAR(255) NOT NULL,
  gadgetsOauthClientId BIGINT NOT NULL,
  expiresIn BIGINT
);

CREATE SEQUENCE gadgetOauthAuthorizationCodes_id_seq START WITH 1;
CREATE TABLE gadgetOauthAuthorizationCodes (
  id BIGINT DEFAULT nextval('gadgetOauthAuthorizationCodes_id_seq') PRIMARY KEY,
  userId VARCHAR(255) NOT NULL,
  code VARCHAR(255) NOT NULL,
  gadgetsOauthClientId BIGINT NOT NULL,
  expiresIn BIGINT
);

ALTER TABLE gadgetOauthAccessTokens ADD CONSTRAINT fk_gadget_oauth_access_token_gadget_oauth_client FOREIGN KEY (gadgetsOauthClientId) REFERENCES gadgetOauthClients(id) DEFERRABLE;
ALTER TABLE gadgetOauthAuthorizationCodes ADD CONSTRAINT fk_gadget_oauth_authorization_code_gadget_oauth_client FOREIGN KEY (gadgetsOauthClientId) REFERENCES gadgetOauthClients(id) DEFERRABLE;
ALTER TABLE gadgetOauthAccessTokens ADD CONSTRAINT unique_user_id_client_id_token UNIQUE(gadgetsOauthClientId, userId);
ALTER TABLE gadgetOauthAuthorizationCodes ADD CONSTRAINT unique_user_id_client_id_code UNIQUE(gadgetsOauthClientId, userId);

--END ==== 83_create_gadget_oauth_tables.sql ====

--BEGIN ==== 84_add_pipelineId_to_modifications.sql ====

ALTER TABLE modifications ADD pipelineId BIGINT;
ALTER TABLE modifications ADD CONSTRAINT fk_modifications_pipelineId FOREIGN KEY (pipelineId) REFERENCES pipelines DEFERRABLE;

--// Creating temp columns for migration
ALTER TABLE pipelines ADD COLUMN TEMP_CASE_SENSITIVE_NAME CITEXT;
UPDATE pipelines SET TEMP_CASE_SENSITIVE_NAME = name;
CREATE INDEX idx_pipelines_temp_case_sensitive_name ON pipelines(TEMP_CASE_SENSITIVE_NAME);

ALTER TABLE modifications ADD COLUMN TEMP_REVISION_FOR_MIGRATION CITEXT;
ALTER TABLE modifications ADD COLUMN TEMP_COUNTER_FOR_MIGRATION CITEXT;
UPDATE modifications SET TEMP_REVISION_FOR_MIGRATION = REGEXP_REPLACE(revision, '\/.*', ''), TEMP_COUNTER_FOR_MIGRATION = REGEXP_REPLACE(REGEXP_REPLACE(revision, '^.*?\/', ''), '\/.*', '');
CREATE INDEX idx_modifications_temp_revision_for_migration ON modifications(TEMP_REVISION_FOR_MIGRATION, TEMP_COUNTER_FOR_MIGRATION);

--// Actual Migration
UPDATE modifications
  SET pipelineId = (SELECT id
                    FROM pipelines
                    WHERE TEMP_CASE_SENSITIVE_NAME = TEMP_REVISION_FOR_MIGRATION
                      AND CAST(counter AS BIGINT) = CAST(TEMP_COUNTER_FOR_MIGRATION AS BIGINT))
  WHERE revision LIKE '%/%/%/%' AND revision ~ ('.+?/-?\d+/.+');

--// Deleting temp columns for migration
DROP INDEX IF EXISTS idx_modifications_temp_revision_for_migration;
ALTER TABLE modifications DROP COLUMN TEMP_COUNTER_FOR_MIGRATION;
ALTER TABLE modifications DROP COLUMN TEMP_REVISION_FOR_MIGRATION;
DROP INDEX IF EXISTS idx_pipelines_temp_case_sensitive_name;
ALTER TABLE pipelines DROP COLUMN TEMP_CASE_SENSITIVE_NAME;


--END ==== 84_add_pipelineId_to_modifications.sql ====

--BEGIN ==== 85_add_materialId_to_pipelineMaterialRevisions.sql ====

ALTER TABLE pipelineMaterialRevisions ADD materialId BIGINT;
ALTER TABLE pipelineMaterialRevisions ADD CONSTRAINT fk_pmr_materialId FOREIGN KEY (materialId) REFERENCES materials DEFERRABLE;

UPDATE pipelineMaterialRevisions
  SET materialId = (SELECT mod.materialId FROM modifications mod WHERE toRevisionId = mod.id);

--END ==== 85_add_materialId_to_pipelineMaterialRevisions.sql ====

--BEGIN ==== 86_add_actual_from_revision_to_pmr.sql ====

-- This index helps speed up the pipeline graph compare queries, and is needed for quickly finding the nextModificationId in the Java migration below
CREATE INDEX idx_modifications_materialid_id ON modifications(materialId,id);


ALTER TABLE pipelineMaterialRevisions ADD COLUMN actualFromRevisionId BIGINT;
ALTER TABLE pipelineMaterialRevisions ADD CONSTRAINT fk_pmr_actualFromRevisionId FOREIGN KEY (actualFromRevisionId) REFERENCES modifications DEFERRABLE;

CREATE TABLE DUMMY_TABLE_FOR_MIGRATION_86 (id int);

-- TRIGGER BEGIN - SACHIN
--CREATE TRIGGER TRIGGER_86_FOR_STORY_4643 BEFORE SELECT ON DUMMY_TABLE_FOR_MIGRATION_86 CALL "com.thoughtworks.go.server.sqlmigration.Migration_86";
--SELECT * FROM DUMMY_TABLE_FOR_MIGRATION_86;
--DROP TRIGGER TRIGGER_86_FOR_STORY_4643;
-- TRIGGER END - SACHIN
DROP TABLE DUMMY_TABLE_FOR_MIGRATION_86;

ALTER TABLE pipelineMaterialRevisions ALTER COLUMN actualFromRevisionId TYPE BIGINT;
ALTER TABLE pipelineMaterialRevisions ALTER COLUMN actualFromRevisionId SET NOT NULL;

--END ==== 86_add_actual_from_revision_to_pmr.sql ====

--BEGIN ==== 87_create_index_modifications_materialId.sql ====

-- This migration was folded into migration 86 because of bad data on go02.

--CREATE INDEX idx_modifications_materialid_id ON modifications(materialId,id);

--END ==== 87_create_index_modifications_materialId.sql ====

--BEGIN ==== 88_rerun_to_actual_job_mapping.sql ====

ALTER TABLE builds ADD COLUMN originalJobId BIGINT;
ALTER TABLE builds ADD COLUMN rerun BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE stages ADD COLUMN rerunJobs BOOLEAN DEFAULT false NOT NULL;

-- recreate the view since H2 does not automatically include new columns into views

DROP VIEW _builds;

CREATE VIEW _builds AS
SELECT b.*,
  p.id pipelineId, p.name pipelineName, p.label pipelineLabel, p.counter pipelineCounter,
  s.name stageName, s.counter stageCounter, s.fetchMaterials, s.cleanWorkingDir
FROM builds b
  INNER JOIN stages s ON s.id = b.stageId
  INNER JOIN pipelines p ON p.id = s.pipelineId;

DROP VIEW _stages;

CREATE VIEW _stages AS
SELECT s.*,
  p.name pipelineName, p.buildCauseType, p.buildCauseBy, p.label pipelineLabel, p.buildCauseMessage, p.counter pipelineCounter, p.locked, p.naturalOrder
FROM stages s
  INNER JOIN pipelines p ON p.id = s.pipelineId;


--END ==== 88_rerun_to_actual_job_mapping.sql ====

--BEGIN ==== 89_adding_rerun_of_counter_for_rerun_job_stages.sql ====

DROP VIEW _stages;
DROP VIEW _builds;

ALTER TABLE stages ADD COLUMN rerunOfCounter INT;

UPDATE stages SET rerunOfCounter = (SELECT counter FROM stages AS self WHERE self.name = stages.name and self.counter < stages.counter and self.pipelineid = stages.pipelineid and self.rerunjobs = false order by self.counter desc limit 1) where stages.rerunjobs = true;

ALTER TABLE stages DROP COLUMN rerunJobs;

CREATE VIEW _builds AS
SELECT b.*,
  p.id pipelineId, p.name pipelineName, p.label pipelineLabel, p.counter pipelineCounter,
  s.name stageName, s.counter stageCounter, s.fetchMaterials, s.cleanWorkingDir, s.rerunOfCounter
FROM builds b
  INNER JOIN stages s ON s.id = b.stageId
  INNER JOIN pipelines p ON p.id = s.pipelineId;

CREATE VIEW _stages AS
SELECT s.*,
  p.name pipelineName, p.buildCauseType, p.buildCauseBy, p.label pipelineLabel, p.buildCauseMessage, p.counter pipelineCounter, p.locked, p.naturalOrder
FROM stages s
  INNER JOIN pipelines p ON p.id = s.pipelineId;

--END ==== 89_adding_rerun_of_counter_for_rerun_job_stages.sql ====

--BEGIN ==== 90_populate_missing_completed_at_transition_id.sql ====

-- populate missing buildStateTransitions (for instance, where build is completed but 'completed' transition does not exist)

CREATE TABLE latest_bst AS (SELECT MAX(bst.id) id, bst.buildId, bst.stageId, b.state AS build_state FROM buildStateTransitions AS bst INNER JOIN builds AS b on (b.id = bst.buildid) GROUP BY build_state, bst.stageId, bst.buildId);

ALTER TABLE latest_bst ADD COLUMN state VARCHAR(255);
ALTER TABLE latest_bst ADD COLUMN transition_time TIMESTAMP;

UPDATE latest_bst SET state = (SELECT currentState FROM buildStateTransitions bst WHERE bst.id = latest_bst.id),
                      transition_time = (select statechangetime from buildstatetransitions bst where bst.id = latest_bst.id);

INSERT INTO buildStateTransitions (buildId, currentState, stageId, stateChangeTime)
    SELECT buildId, build_state, stageId, transition_time FROM latest_bst
        WHERE build_state != state AND
              build_state IN ('Completed', 'Discontinued', 'Rescheduled');

DROP TABLE latest_bst;

--- populate completedByTransitionId for stages that are unpopulated because migration#55 was incomplete

CREATE TABLE latest_bst AS (SELECT MAX(bst.id) id, bst.buildId, bst.stageId FROM buildStateTransitions bst GROUP BY bst.stageId, bst.buildId);

ALTER TABLE latest_bst ADD COLUMN state VARCHAR(255);
ALTER TABLE latest_bst ADD COLUMN non_complete_state INT DEFAULT 0;

UPDATE latest_bst SET state = (SELECT currentState FROM buildStateTransitions bst WHERE bst.id = latest_bst.id);

UPDATE latest_bst SET non_complete_state = 1 WHERE state <> 'Completed' AND state <> 'Rescheduled' AND state <> 'Discontinued';

CREATE TABLE latest_stage_bst AS (SELECT MAX(id) id, SUM(non_complete_state) total_incomplete, stageId FROM latest_bst GROUP BY stageId);

DELETE FROM latest_stage_bst WHERE total_incomplete > 0;

UPDATE stages SET id = (SELECT stageId FROM latest_stage_bst WHERE stages.id = latest_stage_bst.id), completedByTransitionId = (SELECT id FROM latest_stage_bst WHERE stages.id = latest_stage_bst.id);

DROP TABLE latest_bst;

DROP TABLE latest_stage_bst;

-- populate completedByTransitionId = -1 for stages that have no builds

CREATE TABLE stages_without_builds AS (SELECT stages.id FROM stages LEFT OUTER JOIN builds ON builds.stageid = stages.id WHERE builds.id IS NULL);

UPDATE stages SET completedByTransitionId = -1 WHERE id IN (SELECT swb.id FROM stages_without_builds swb);

DROP TABLE stages_without_builds;

--END ==== 90_populate_missing_completed_at_transition_id.sql ====

--BEGIN ==== 221001_fix_incomplete_stages_and_jobs.sql ====

-- subset of 90
CREATE TABLE latest_bst AS (SELECT MAX(bst.id) id, bst.buildId, bst.stageId FROM buildStateTransitions bst GROUP BY bst.stageId, bst.buildId);

ALTER TABLE latest_bst ADD COLUMN state VARCHAR(255);
ALTER TABLE latest_bst ADD COLUMN non_complete_state INT DEFAULT 0;

UPDATE latest_bst SET state = (SELECT currentState FROM buildStateTransitions bst WHERE bst.id = latest_bst.id);

UPDATE latest_bst SET non_complete_state = 1 WHERE state <> 'Completed' AND state <> 'Rescheduled' AND state <> 'Discontinued';

CREATE TABLE latest_stage_bst AS (SELECT MAX(id) id, SUM(non_complete_state) total_incomplete, stageId FROM latest_bst GROUP BY stageId);

DELETE FROM latest_stage_bst WHERE total_incomplete > 0;

UPDATE stages SET id = (SELECT stageId FROM latest_stage_bst WHERE stages.id = latest_stage_bst.id), completedByTransitionId = (SELECT id FROM latest_stage_bst WHERE stages.id = latest_stage_bst.id);

DROP TABLE latest_bst;

DROP TABLE latest_stage_bst;

-- fix stages
UPDATE stages SET result = 'Failed', state = 'Failed' WHERE completedByTransitionId IS NOT NULL AND result = 'Unknown';

-- fix jobs
UPDATE builds SET result = 'Failed' WHERE state = 'Completed' AND result = 'Unknown';

--END ==== 221001_fix_incomplete_stages_and_jobs.sql ====

--BEGIN ==== 230001_add_column_artifacts_deleted_to_stage.sql ====

DO $$
    BEGIN
        BEGIN
		ALTER TABLE STAGES ADD COLUMN ARTIFACTSDELETED Boolean DEFAULT FALSE NOT NULL;
        EXCEPTION
		WHEN duplicate_column THEN RAISE NOTICE 'column <column_name> already exists in <table_name>.';
        END;
    END;
$$ LANGUAGE plpgsql;

DROP VIEW _builds;

DROP VIEW _stages;

CREATE VIEW _builds AS
SELECT b.*,
  p.id pipelineId, p.name pipelineName, p.label pipelineLabel, p.counter pipelineCounter,
  s.name stageName, s.counter stageCounter, s.fetchMaterials, s.cleanWorkingDir, s.rerunOfCounter, s.artifactsDeleted
FROM builds b
  INNER JOIN stages s ON s.id = b.stageId
  INNER JOIN pipelines p ON p.id = s.pipelineId;

CREATE VIEW _stages AS
SELECT s.*,
  p.name pipelineName, p.buildCauseType, p.buildCauseBy, p.label pipelineLabel, p.buildCauseMessage, p.counter pipelineCounter, p.locked, p.naturalOrder
FROM stages s
  INNER JOIN pipelines p ON p.id = s.pipelineId;

CREATE SEQUENCE stageArtifactCleanupProhibited_id_seq START WITH 1;
CREATE TABLE IF NOT EXISTS stageArtifactCleanupProhibited (
             id BIGINT DEFAULT nextval('stageArtifactCleanupProhibited_id_seq') PRIMARY KEY,
             stageName CITEXT NOT NULL,
             pipelineName CITEXT NOT NULL,
             prohibited Boolean DEFAULT FALSE NOT NULL);

--END ==== 230001_add_column_artifacts_deleted_to_stage.sql ====

--BEGIN ==== 230002_populate_missing_completed_by_transition_id.sql ====

--- populate completedByTransitionId for stages that are unpopulated because migration#55 was incomplete. This is a subset of migration 90 for the bug introduced on go02 and go03

CREATE TABLE latest_bst AS (SELECT MAX(bst.id) id, bst.buildId, bst.stageId FROM buildStateTransitions bst GROUP BY bst.stageId, bst.buildId);

ALTER TABLE latest_bst ADD COLUMN state VARCHAR(255);
ALTER TABLE latest_bst ADD COLUMN non_complete_state INT DEFAULT 0;

UPDATE latest_bst SET state = (SELECT currentState FROM buildStateTransitions bst WHERE bst.id = latest_bst.id);

UPDATE latest_bst SET non_complete_state = 1 WHERE state <> 'Completed' AND state <> 'Rescheduled' AND state <> 'Discontinued';

CREATE TABLE latest_stage_bst AS (SELECT MAX(id) id, SUM(non_complete_state) total_incomplete, stageId FROM latest_bst GROUP BY stageId);

DELETE FROM latest_stage_bst WHERE total_incomplete > 0;

UPDATE stages SET id = (SELECT stageId FROM latest_stage_bst WHERE stages.id = latest_stage_bst.id), completedByTransitionId = (SELECT id FROM latest_stage_bst WHERE stages.id = latest_stage_bst.id);

DROP TABLE latest_bst;

DROP TABLE latest_stage_bst;

--END ==== 230002_populate_missing_completed_by_transition_id.sql ====

--BEGIN ==== 230003_stop_persisting_material_password.sql ====

ALTER TABLE materials DROP COLUMN password;

--END ==== 230003_stop_persisting_material_password.sql ====

--BEGIN ==== 230004_add_config_version_to_stage.sql ====

ALTER TABLE stages ADD COLUMN configversion VARCHAR(255);

DROP VIEW _builds;

DROP VIEW _stages;

CREATE VIEW _builds AS
SELECT b.*,
  p.id pipelineId, p.name pipelineName, p.label pipelineLabel, p.counter pipelineCounter,
  s.name stageName, s.counter stageCounter, s.fetchMaterials, s.cleanWorkingDir, s.rerunOfCounter, s.artifactsDeleted
FROM builds b
  INNER JOIN stages s ON s.id = b.stageId
  INNER JOIN pipelines p ON p.id = s.pipelineId;

CREATE VIEW _stages AS
SELECT s.*,
  p.name pipelineName, p.buildCauseType, p.buildCauseBy, p.label pipelineLabel, p.buildCauseMessage, p.counter pipelineCounter, p.locked, p.naturalOrder
FROM stages s
  INNER JOIN pipelines p ON p.id = s.pipelineId;

--END ==== 230004_add_config_version_to_stage.sql ====

--BEGIN ==== 230005_add_index_bst_buildid_currentstate.sql ====

CREATE INDEX idx_bst_buildid_currentstate ON buildstatetransitions(buildid, currentstate);

--END ==== 230005_add_index_bst_buildid_currentstate.sql ====

--BEGIN ==== 230006_make_user_name_case_insensitive.sql ====


ALTER TABLE users ADD COLUMN preffered_id BIGINT;
ALTER TABLE users ADD COLUMN in_name CITEXT;
UPDATE users SET in_name = name;

CREATE TABLE preffered AS SELECT MIN(id) id, in_name FROM users WHERE enabled = true GROUP BY in_name;
UPDATE users SET preffered_id = (SELECT preffered.id FROM preffered WHERE users.in_name = preffered.in_name);
DELETE FROM users WHERE preffered_id IS NOT NULL AND id != preffered_id;

DROP TABLE preffered;
CREATE TABLE preffered AS SELECT MIN(id) id, in_name FROM users WHERE preffered_id IS NULL GROUP BY in_name;
UPDATE users SET preffered_id = (SELECT preffered.id FROM preffered WHERE users.in_name = preffered.in_name) WHERE preffered_id IS NULL;
DELETE FROM users WHERE id != preffered_id;

ALTER TABLE users DROP COLUMN preffered_id;
ALTER TABLE users DROP COLUMN in_name;

ALTER TABLE users ALTER COLUMN name TYPE CITEXT;
ALTER TABLE users ALTER COLUMN name SET NOT NULL;

--END ==== 230006_make_user_name_case_insensitive.sql ====

--BEGIN ==== 230007_add_completed_time_on_job_and_stage.sql ====

ALTER TABLE stages ADD COLUMN lastTransitionedTime TIMESTAMP;

DROP VIEW _builds;

DROP VIEW _stages;

CREATE VIEW _builds AS
SELECT b.*,
  p.id pipelineId, p.name pipelineName, p.label pipelineLabel, p.counter pipelineCounter,
  s.name stageName, s.counter stageCounter, s.fetchMaterials, s.cleanWorkingDir, s.rerunOfCounter, s.artifactsDeleted
FROM builds b
  INNER JOIN stages s ON s.id = b.stageId
  INNER JOIN pipelines p ON p.id = s.pipelineId;

CREATE VIEW _stages AS
SELECT s.*,
  p.name pipelineName, p.buildCauseType, p.buildCauseBy, p.label pipelineLabel, p.buildCauseMessage, p.counter pipelineCounter, p.locked, p.naturalOrder
FROM stages s
  INNER JOIN pipelines p ON p.id = s.pipelineId;

UPDATE stages SET
id = (SELECT s.id FROM stages s INNER JOIN buildStateTransitions bst on s.completedByTransitionId = bst.id),
lastTransitionedTime = (SELECT bst.stateChangeTime FROM stages s INNER JOIN buildStateTransitions bst on s.completedByTransitionId = bst.id);

CREATE FUNCTION update_stages_lastTransitionedTime() RETURNS TRIGGER AS $$
  BEGIN
    UPDATE stages SET lastTransitionedTime = NEW.statechangetime WHERE stages.id = NEW.stageid;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER lastTransitionedTimeUpdate
  AFTER INSERT ON buildStateTransitions
  FOR EACH ROW
  EXECUTE PROCEDURE update_stages_lastTransitionedTime();

--END ==== 230007_add_completed_time_on_job_and_stage.sql ====

--BEGIN ==== 230008_drop_unique_revisions_for_material_constraint.sql ====

ALTER TABLE modifications DROP CONSTRAINT UNIQUE_REVISION;

--END ==== 230008_drop_unique_revisions_for_material_constraint.sql ====

--BEGIN ==== 230009_update_git_material_with_null_branch_to_use_branch_master.sql ====

UPDATE materials
    SET branch = 'master',
        fingerprint = DIGEST(concat('type=', type, '<|>', 'url=', url, '<|>', 'branch=', branch), 'sha256')
    WHERE
        type = 'GitMaterial' AND
        branch IS null;

--END ==== 230009_update_git_material_with_null_branch_to_use_branch_master.sql ====

--BEGIN ==== 240001_add_userid_column_to_pipelineselections.sql ====

ALTER TABLE pipelineselections ADD COLUMN userId BIGINT;
ALTER TABLE  pipelineselections ADD CONSTRAINT fk_pipelineselections_userid FOREIGN KEY(userid) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

--END ==== 240001_add_userid_column_to_pipelineselections.sql ====

--BEGIN ==== 240002_add_disableLicenseExpiryWarning_to_users.sql ====

ALTER TABLE users ADD disableLicenseExpiryWarning boolean NOT NULL DEFAULT FALSE;

--END ==== 240002_add_disableLicenseExpiryWarning_to_users.sql ====

--BEGIN ==== 300001_add_serverBackup_table.sql ====

CREATE SEQUENCE serverBackups_id_seq START WITH 1;
CREATE TABLE serverBackups (
id BIGINT DEFAULT nextval('serverBackups_id_seq') PRIMARY KEY,
path  VARCHAR(2048),
time  TIMESTAMP);

--END ==== 300001_add_serverBackup_table.sql ====

--BEGIN ==== 300002_add_pause_info_column.sql ====

ALTER TABLE pipelineLabelCounts ADD COLUMN pause_cause VARCHAR(255);
ALTER TABLE pipelineLabelCounts ADD COLUMN pause_by VARCHAR(255);
ALTER TABLE pipelineLabelCounts ADD COLUMN paused BOOLEAN DEFAULT false;

--END ==== 300002_add_pause_info_column.sql ====

--BEGIN ==== 300003_add_serveralias_column_to_material_instance.sql ====

ALTER TABLE materials ADD COLUMN serveralias VARCHAR(255);

--END ==== 300003_add_serveralias_column_to_material_instance.sql ====

--BEGIN ==== 300004_create_luau_state_table.sql ====

CREATE SEQUENCE luauState_id_seq START WITH 1;
CREATE TABLE luauState (
id BIGINT DEFAULT nextval('luauState_id_seq') PRIMARY KEY,
clientKey  VARCHAR(255),
authState  VARCHAR(255),
authStateExplanation  VARCHAR(255),
lastClientDigest VARCHAR(255),
lastSyncStatus VARCHAR(255),
submittedAt  TIMESTAMP,
lastSyncAt  TIMESTAMP,
markForDeletion BOOLEAN DEFAULT FALSE);

--END ==== 300004_create_luau_state_table.sql ====

--BEGIN ==== 300005_drop_auth_state_column_from_luau_state.sql ====

ALTER TABLE luauState DROP COLUMN authState;

--END ==== 300005_drop_auth_state_column_from_luau_state.sql ====

--BEGIN ==== 300006_add_tfs_material_attributes.sql ====

ALTER TABLE materials ADD COLUMN workspace VARCHAR(255);
ALTER TABLE materials ADD COLUMN workspaceOwner VARCHAR(255);
ALTER TABLE materials ADD COLUMN projectPath VARCHAR(255);

--END ==== 300006_add_tfs_material_attributes.sql ====

--BEGIN ==== 300007_add_display_name_column_to_users.sql ====

ALTER TABLE users ADD COLUMN displayName VARCHAR(255);
UPDATE users SET displayName=name;

--END ==== 300007_add_display_name_column_to_users.sql ====

--BEGIN ==== 300008_create_luau_groups.sql ====

CREATE SEQUENCE luau_groups_id_seq START WITH 1;
CREATE TABLE luau_groups (
    id BIGINT DEFAULT nextval('luau_groups_id_seq') PRIMARY KEY,
    name VARCHAR,
    fullName VARCHAR,
    uri VARCHAR
);

CREATE TABLE luau_groups_users (
    luau_group_id BIGINT,
    user_id BIGINT
);

ALTER TABLE luau_groups_users ADD CONSTRAINT fk_luau_group_id FOREIGN KEY(luau_group_id) REFERENCES luau_groups(id) DEFERRABLE;
ALTER TABLE luau_groups_users ADD CONSTRAINT fk_user_id FOREIGN KEY(user_id) REFERENCES users(id) DEFERRABLE;
ALTER TABLE luau_groups ADD CONSTRAINT unique_uri UNIQUE (uri);

--END ==== 300008_create_luau_groups.sql ====

--BEGIN ==== 300009_add_secure_column_to_environment_variables.sql ====

ALTER TABLE environmentVariables ADD COLUMN isSecure BOOLEAN DEFAULT false;

--END ==== 300009_add_secure_column_to_environment_variables.sql ====

--BEGIN ==== 300010_add_column_to_store_last_successful_sync_time.sql ====

ALTER TABLE luauState ADD COLUMN lastSuccessfulSyncAt TIMESTAMP;

--END ==== 300010_add_column_to_store_last_successful_sync_time.sql ====

--BEGIN ==== 300011_remove_column_workspace_owner.sql ====

ALTER TABLE materials DROP COLUMN workspaceOwner;

--END ==== 300011_remove_column_workspace_owner.sql ====

--BEGIN ==== 1202001_fix_dependency_material_fingerprint_to_adjust_serveralias.sql ====

UPDATE materials SET
    fingerprint = digest(concat('type=', type, '<|>', 'pipelineName=', pipelineName, '<|>', 'stageName=', stageName, '<|>', 'serverAlias=null'), 'SHA256')
    WHERE type = 'DependencyMaterial' AND serverAlias IS null;

--END ==== 1202001_fix_dependency_material_fingerprint_to_adjust_serveralias.sql ====

--BEGIN ==== 1202002_add_domain_column_to_material_instance.sql ====

ALTER TABLE materials ADD COLUMN domain CITEXT;

--END ==== 1202002_add_domain_column_to_material_instance.sql ====

--BEGIN ==== 1202003_remove_ignore_case_from_domain_column_to_material_instance.sql ====

ALTER TABLE materials ALTER COLUMN domain TYPE VARCHAR(255);
--END ==== 1202003_remove_ignore_case_from_domain_column_to_material_instance.sql ====

--BEGIN ==== 1203002_add_user_column_to_server_backup_table.sql ====

ALTER TABLE serverBackups ADD COLUMN username CITEXT;
--END ==== 1203002_add_user_column_to_server_backup_table.sql ====

--BEGIN ==== 1203003_zap_natural_order_values.sql ====

UPDATE pipelines SET naturalOrder = 0.0;

--END ==== 1203003_zap_natural_order_values.sql ====

--BEGIN ==== 1203004_kill_remote_dependency_material.sql ====

ALTER TABLE materials DROP COLUMN serveralias;

UPDATE materials SET
    fingerprint = DIGEST(concat('type=', type, '<|>', 'pipelineName=', pipelineName, '<|>', 'stageName=', stageName), 'sha256')
    WHERE type = 'DependencyMaterial';

--END ==== 1203004_kill_remote_dependency_material.sql ====

--BEGIN ==== 1203005_add_index_on_modifications_revision.sql ====

CREATE INDEX idx_modifications_revision ON modifications(revision);
--END ==== 1203005_add_index_on_modifications_revision.sql ====

--BEGIN ==== 1301001_drop_build_event_column_from_builds.sql ====

DROP VIEW _builds;

ALTER TABLE builds DROP COLUMN buildEvent;

CREATE VIEW _builds AS
SELECT b.*,
  p.id pipelineId, p.name pipelineName, p.label pipelineLabel, p.counter pipelineCounter,
  s.name stageName, s.counter stageCounter, s.fetchMaterials, s.cleanWorkingDir, s.rerunOfCounter, s.artifactsDeleted
FROM builds b
  INNER JOIN stages s ON s.id = b.stageId
  INNER JOIN pipelines p ON p.id = s.pipelineId;

--END ==== 1301001_drop_build_event_column_from_builds.sql ====

--BEGIN ==== 1302001_add_configuration_field_to_materials_table.sql ====

ALTER TABLE Materials ADD COLUMN configuration text;
--END ==== 1302001_add_configuration_field_to_materials_table.sql ====
