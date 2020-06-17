/*
 * Copyright 2020 ThoughtWorks, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.thoughtworks.go.dbsync;

import net.sf.dbdeploy.InMemory;
import net.sf.dbdeploy.database.syntax.DbmsSyntax;
import net.sf.dbdeploy.database.syntax.HsqlDbmsSyntax;
import net.sf.dbdeploy.exceptions.DbDeployException;
import org.apache.commons.dbcp2.BasicDataSource;

import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.SQLException;

import static org.apache.commons.io.FilenameUtils.separatorsToUnix;

public class DbDeploySchemaMigrator {
    private final BasicDataSource sourceDataSource;
    private final Connection connection;

    public DbDeploySchemaMigrator(BasicDataSource sourceDataSource, Connection connection) {
        this.sourceDataSource = sourceDataSource;
        this.connection = connection;
    }

    public String migrationSQL() throws SQLException, DbDeployException, IOException, ClassNotFoundException, URISyntaxException {
        String deltasFolder = deltasFolder();

        InMemory inMemory = new InMemory(sourceDataSource, dbms(), new File(deltasFolder), "DDL");

        return inMemory.migrationSql();
    }

    private DbmsSyntax dbms() throws SQLException {
        if (isH2()) {
            return new HsqlDbmsSyntax();
        }
        if (isPG()) {
            return new PostgreSQLDbmsSyntax();
        }
        throw new RuntimeException("Unsupported DB " + connection.getMetaData().getDatabaseProductName());
    }

    private boolean isPG() throws SQLException {
        return connection.getMetaData().getDatabaseProductName().equalsIgnoreCase("PostgreSQL");
    }

    private boolean isH2() throws SQLException {
        return connection.getMetaData().getDatabaseProductName().equalsIgnoreCase("H2");
    }

    private String deltasFolder() throws SQLException, URISyntaxException {
        String folder = isH2() ? "h2deltas" : "pgdeltas";
        String jarPath = new File(getClass().getProtectionDomain().getCodeSource().getLocation().toURI().getPath()).getParentFile().getParent();

        return URI.create(separatorsToUnix(Paths.get(jarPath, folder).toString())).normalize().toString();
    }
    public static class PostgreSQLDbmsSyntax extends DbmsSyntax {
        public PostgreSQLDbmsSyntax() {
        }

        public String generateTimestamp() {
            return "CURRENT_TIMESTAMP";
        }

        public String generateUser() {
            return "CURRENT_USER";
        }
    }
}
