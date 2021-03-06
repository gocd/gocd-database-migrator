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

DROP TABLE gadgetOauthAuthorizationCodes;
DROP TABLE gadgetOauthAccessTokens;
DROP TABLE gadgetOauthClients;

DROP SEQUENCE gadgetOauthClients_id_seq;
DROP SEQUENCE gadgetOauthAccessTokens_id_seq;
DROP SEQUENCE gadgetOauthAuthorizationCodes_id_seq;

--//@UNDO

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