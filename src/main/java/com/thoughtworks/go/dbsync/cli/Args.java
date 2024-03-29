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

import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;

import java.util.concurrent.TimeUnit;

@Parameters(separators = "=")
public class Args {
    @Parameter(names = {"--help", "-h"}, description = "Prints help.", help = true, order = 100)
    public boolean help;

    @Parameter(names = "--source-db-url", description = "The source database url. Specify the existing GoCD database url. When none specified, it will default to looking up `cruise.h2.db` in the current directory.", order = 200)
    public String sourceDbUrl = "jdbc:h2:./cruise";

    @Parameter(names = "--source-db-driver-class", description = "The source database driver class. When none specified, based on the specified --source-db-url it will choose the appropriate driver class.", order = 300)
    public String sourceDbDriverClass;

    @Parameter(names = "--source-db-user", description = "The username of the source database.", order = 400)
    public String sourceDbUser = "sa";

    @Parameter(names = "--source-db-password", description = "The password of the source database.", password = true, order = 500)
    public String sourceDbPassword;

    @Parameter(names = "--target-db-url", description = "The target database url. Specify the newly created database url where the data will be copied.", required = true, order = 600)
    public String targetDbUrl;

    @Parameter(names = "--target-db-driver-class", description = "The target database driver class. When none specified, based on the specified --target-db-url it will choose the appropriate driver class.", required = false, order = 700)
    public String targetDbDriverClass;

    @Parameter(names = "--target-db-user", description = "The username of the target database.", order = 800)
    public String targetDbUser;

    @Parameter(names = "--target-db-password", description = "The password of the target database.", password = true, order = 900)
    public String targetDbPassword;

    @Parameter(names = "--batch-size", description = "The number of records to SELECT from source database and INSERT into target database in each batch.", order = 1000)
    public int batchSize = 100_000;

    @Parameter(names = {"-o", "--output"}, description = "The output SQL file. Specify `.gz` extension to enable gzip compression.", order = 1100)
    public String outputFile;

    @Parameter(names = {"--insert", "-i"}, description = "Perform INSERT into target database.", order = 1200)
    public boolean insert = false;

    @Parameter(names = {"--progress", "-p"}, description = "Show progress of the export operation", order = 1300)
    public boolean progress = false;

    @Parameter(names = {"--threads", "-t"}, description = "Number of import threads. Defaults to number of processors (max of 8).", order = 1400)
    public int threads = Math.min(8, Runtime.getRuntime().availableProcessors());

    @Parameter(names = {"--export-timeout"}, description = "Number of seconds to allow data to be exported from source to target database before timing out.", order = 1500)
    public long exportTimeoutSeconds = TimeUnit.MINUTES.toSeconds(30);
}
