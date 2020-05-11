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

@Parameters(separators = "=")
public class Args {
    @Parameter(names = {"--help", "-h"}, description = "Print this help.", help = true, order = 100)
    public boolean help;

    @Parameter(names = "--source-db-url", description = "The source DB url. Will default to looking up `cruise.h2.db` in the current directory.", order = 200)
    public String sourceDbUrl = "jdbc:h2:cruise";

    @Parameter(names = "--source-db-driver-class", description = "The source DB driver class.", order = 300)
    public String sourceDbDriverClass;

    @Parameter(names = "--source-db-user", description = "The username of the source database.", order = 400)
    public String sourceDbUser = "sa";

    @Parameter(names = "--source-db-password", description = "The password of the source database.", password = true, order = 500)
    public String sourceDbPassword;

    @Parameter(names = "--target-db-url", description = "The target-db DB url.", required = true, order = 600)
    public String targetDbUrl;

    @Parameter(names = "--target-db-driver-class", description = "The target DB driver class.", required = false, order = 700)
    public String targetDbDriverClass;

    @Parameter(names = "--target-db-user", description = "The username of the target database.", required = true, order = 800)
    public String targetDbUser;

    @Parameter(names = "--target-db-password", description = "The password of the target database.", password = true, order = 900)
    public String targetDbPassword;

    @Parameter(names = "--batch-size", description = "The number of records to SELECT from source and INSERT into target in each batch.", order = 1000)
    public int batchSize = 100_000;

    @Parameter(names = {"-o", "--output"}, description = "The output SQL file. Specify `.gz` extension to enable gzip compression.", order = 1100)
    public String outputFile;

    @Parameter(names = {"--insert", "-i"}, description = "Perform INSERT into target database.", order = 1200)
    public boolean insert;

    @Parameter(names = {"--progress", "-p"}, description = "Show progress", order = 1300)
    public boolean progress;

    @Parameter(names = {"--threads", "-t"}, description = "Number of import threads. Defaults to number of processors (max of 8).", order = 1400)
    public int threads = Math.max(8, Runtime.getRuntime().availableProcessors());
}
