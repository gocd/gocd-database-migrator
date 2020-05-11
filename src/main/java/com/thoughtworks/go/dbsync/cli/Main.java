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

package com.thoughtworks.go.dbsync.cli;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.ParameterException;
import com.thoughtworks.go.dbsync.DbSync;

import static org.jooq.tools.StringUtils.isBlank;

public class Main {

    public static void main(String[] argv) {
        Args args = new Args();
        JCommander commander = JCommander.newBuilder()
                .addObject(args)
                .programName("gocd-h2-db-export")
                .build();
        try {
            commander.parse(argv);

            if (args.help) {
                printUsageAndExit(commander);
            } else {
                if (isBlank(args.outputFile) && !args.insert) {
                    commander.getConsole().println("ERROR: At least one of `--output` or `--insert` options must be specified.");
                    printUsageAndExit(commander);
                }

                validateDbDriverClass(args, commander);

                new DbSync(args).export();
            }
        } catch (ParameterException e) {
            commander.getConsole().println("ERROR: " + e.getMessage());
            printUsageAndExit(commander);
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static void validateDbDriverClass(Args args, JCommander commander) {
        String h2Driver = org.h2.Driver.class.getName();
        String postgresDriver = org.postgresql.Driver.class.getName();
        String mysqlDriver = com.mysql.cj.jdbc.Driver.class.getName();


        //validate source
        if (isH2Url(args.sourceDbUrl)) {
            validateOrDefaultSourceDBDriverClass(args, commander, h2Driver, "H2");
        }

        if (isPostgresqlUrl(args.sourceDbUrl)) {
            validateOrDefaultSourceDBDriverClass(args, commander, postgresDriver, "PostgreSQL");
        }

        if (isMysqlUrl(args.sourceDbUrl)) {
            validateOrDefaultSourceDBDriverClass(args, commander, mysqlDriver, "MySQL");
        }

        //validate target
        if (isH2Url(args.targetDbUrl)) {
            validateOrDefaultTargetDBDriverClass(args, commander, h2Driver, "H2");
        }

        if (isPostgresqlUrl(args.targetDbUrl)) {
            validateOrDefaultTargetDBDriverClass(args, commander, postgresDriver, "PostgreSQL");
        }

        if (isMysqlUrl(args.targetDbUrl)) {
            validateOrDefaultTargetDBDriverClass(args, commander, mysqlDriver, "MySQL");
        }
    }

    private static void validateOrDefaultSourceDBDriverClass(Args args, JCommander commander, String driver, String dbType) {
        if (isBlank(args.sourceDbDriverClass)) {
            commander.getConsole().println("INFO: No `--source-db-driver-class` is specified. Setting `--source-db-driver-class='" + driver + "'`.");
            args.sourceDbDriverClass = driver;
        } else if (!args.sourceDbDriverClass.equals(driver)) {
            commander.getConsole().println("ERROR: `--source-db-driver-class` is not compatible with specified type of database (" + dbType + ").");
            printUsageAndExit(commander);
        }
    }

    private static void validateOrDefaultTargetDBDriverClass(Args args, JCommander commander, String driver, String dbType) {
        if (isBlank(args.targetDbDriverClass)) {
            commander.getConsole().println("INFO: No `--target-db-driver-class` specified. Setting `--target-db-driver-class='" + driver + "'`.");
            args.targetDbDriverClass = driver;
        } else if (!args.targetDbDriverClass.equals(driver)) {
            commander.getConsole().println("ERROR: `--target-db-driver-class` is not compatible with specified type of database (" + dbType + ").");
            printUsageAndExit(commander);
        }
    }

    private static boolean isH2Url(String url) {
        return url.startsWith("jdbc:h2");
    }

    private static boolean isPostgresqlUrl(String url) {
        return url.startsWith("jdbc:postgresql");
    }

    private static boolean isMysqlUrl(String url) {
        return url.startsWith("jdbc:mysql");
    }

    private static void printUsageAndExit(JCommander commander) {
        commander.usage();
        System.exit(1);
    }
}
