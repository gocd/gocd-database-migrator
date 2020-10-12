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

import ch.qos.logback.classic.LoggerContext;
import ch.qos.logback.classic.util.ContextInitializer;
import ch.qos.logback.core.joran.spi.JoranException;
import com.thoughtworks.go.dbsync.cli.Args;
import liquibase.exception.LiquibaseException;
import liquibase.integration.commandline.Main;
import me.tongfei.progressbar.ProgressBar;
import me.tongfei.progressbar.ProgressBarBuilder;
import me.tongfei.progressbar.ProgressBarStyle;
import org.apache.commons.dbcp2.BasicDataSource;
import org.apache.commons.io.FileUtils;
import org.jooq.*;
import org.jooq.conf.RenderNameStyle;
import org.jooq.conf.SettingsTools;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.sql.DataSource;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.zip.GZIPOutputStream;

import static com.thoughtworks.go.dbsync.Util.comment;
import static com.thoughtworks.go.dbsync.Util.*;
import static org.jooq.conf.RenderNameStyle.AS_IS;
import static org.jooq.conf.RenderNameStyle.QUOTED;
import static org.jooq.impl.DSL.*;
import static org.jooq.tools.StringUtils.isBlank;

public class DbSync {
    static {
        System.setProperty("org.jooq.no-logo", "true");
    }

    static final Logger LOG = LoggerFactory.getLogger(DbSync.class);
    private final Args args;

    public DbSync(Args args) {
        this.args = args;
        Executors.newFixedThreadPool(1);
    }

    public void export() throws Exception {
        File dumpsDir = new File("dumps");
        FileUtils.deleteDirectory(dumpsDir);
        FileUtils.forceMkdir(dumpsDir);

        BasicDataSource sourceDataSource = createDataSource(args.sourceDbDriverClass, args.sourceDbUrl, args.sourceDbUser, args.sourceDbPassword);
        BasicDataSource targetDataSource = createDataSource(args.targetDbDriverClass, args.targetDbUrl, args.targetDbUser, args.targetDbPassword);

        withDataSource(sourceDataSource, (connection) -> LOG.info("Using dialect {} for source database.", using(connection).dialect()));
        withDataSource(targetDataSource, (connection) -> LOG.info("Using dialect {} for target database.", using(connection).dialect()));

        withDataSource(sourceDataSource, (connection -> {
            LOG.debug("Checking if source DB contains the changelog table from dbdeploy.");
            if (new DbDeploySchemaVerifier().usesDbDeploy(connection) && isH2OrPostgres()) {
                LOG.debug("Found changelog table, performing DB migrations using dbdeploy.");
                String migrationSQL = new DbDeploySchemaMigrator(sourceDataSource, connection).migrationSQL();
                try (Statement statement = connection.createStatement()) {
                    statement.execute(migrationSQL);
                }
            }
        }));

        withDataSource(targetDataSource, (connection -> {
            LOG.debug("Checking if target DB is empty.");
            Map<String, Integer> tables = listTables(targetDataSource);

            if (!tables.isEmpty()) {
                LOG.error("Specified target DB is not empty. Contains '{}' tables in public schema.", String.join(", ", tables.keySet()));
                LOG.error("Skipping migration.", String.join(", ", tables.keySet()));
                System.exit(1);
            }
        }));

        withWriter((writer) -> {
            try {
                Map<String, Integer> tables = listTables(sourceDataSource);

                withDataSource(targetDataSource, (targetConnection) -> {
                    LOG.info("Initializing database skeleton on target database.");
                    executeLiquibaseWithContext(targetDataSource, writer, "createSchema");
                    LOG.info("Done initializing database skeleton on target database.");
                });

                withDataSource(targetDataSource, (targetConnection) -> {
                    LOG.info("Initializing database views.");
                    executeLiquibaseWithContext(targetDataSource, writer, "createView");
                    LOG.info("Done initializing database views.");
                });


                withDataSource(targetDataSource, (targetConnection) -> {
                    LOG.info("Copying database records.");
                    doExport(sourceDataSource, targetDataSource, writer);
                    LOG.info("Done copying database records.");
                });


                withDataSource(targetDataSource, (targetConnection) -> {
                    LOG.info("Setting sequences for all tables.");
                    resetSequences(targetDataSource, tables.keySet(), writer);
                    LOG.info("Done setting sequences for all tables.");
                });

                withDataSource(targetDataSource, (targetConnection) -> {
                    LOG.info("Initializing database indices and constraints on target database. This may take several minutes, depending on the size of the database.");
                    executeLiquibaseWithContext(targetDataSource, writer, "createIndex");
                    LOG.info("Done initializing database indices and constraints on target database.");
                });

                withDataSource(targetDataSource, (targetConection) -> {
                    if(!args.insert) {
                        LOG.info("No '--insert' option provided, causing no data insertion on the target database. Skipping data verification on target database.");
                        return;
                    }

                    LOG.info("Verifying if number of records are identical in source and target.");
                    List<String> errors = new ArrayList<>();

                    tables.keySet().forEach(tableName -> {
                        Integer actualCount = using(targetConection).fetchCount(table(tableName));
                        Integer expectedCount = tables.get(tableName);

                        if (!actualCount.equals(expectedCount)) {
                            errors.add("Expected table " + tableName + " to contain " + expectedCount + " records but contained " + actualCount + " records");
                        }
                    });

                    if (!errors.isEmpty()) {
                        LOG.error("It appears that there was a problem copying records:");
                        for (String error : errors) {
                            LOG.error("  {}", error);
                        }
                        System.exit(1);
                    } else {
                        LOG.info("All good!");
                    }
                });

            } catch (Exception e) {
                LOG.error(null, e);
                throw new RuntimeException(e);
            }
        });

        try {
            targetDataSource.close();
            sourceDataSource.close();
        } catch (SQLException e) {
            LOG.error(null, e);
            throw new RuntimeException(e);
        }

        LOG.info("Done copying tables!");
    }

    private boolean isH2OrPostgres() {
        return args.sourceDbUrl.startsWith("jdbc:h2:") || args.sourceDbUrl.startsWith("jdbc:postgresql");
    }

    private void doExport(BasicDataSource sourceDataSource, DataSource targetDataSource, Writer writer) {
        Map<String, Integer> tables = listTables(sourceDataSource);
        LOG.info("Found tables:");

        tables.forEach((tableName, recordCount) -> {
            LOG.info("  {}: {} records", tableName, recordCount);
        });

        try (ProgressBar progressBar = progressBar(tables)) {
            ThreadPoolExecutor executor = new ThreadPoolExecutor(args.threads, args.threads, 1L, TimeUnit.SECONDS, new LinkedQueue<>(2));
            try {
                tables.forEach((String tableName, Integer rowCount) -> {
                    executor.execute(() -> {
                        try (Connection sourceConnection = sourceDataSource.getConnection()) {
                            dumpTableSQL(tableName, rowCount, sourceConnection, targetDataSource, writer, progressBar);
                        } catch (Exception e) {
                            LOG.error(null, e);
                            throw new RuntimeException(e);
                        }
                    });
                });
            } finally {
                LOG.debug("Shutting down thread pool executor");
                executor.shutdown();
                LOG.debug("Awaiting termination of executorService");
                try {
                    executor.awaitTermination(1000, TimeUnit.SECONDS);
                } catch (InterruptedException e) {
                    throw new RuntimeException(e);
                }
            }
        }

    }

    private ProgressBar progressBar(Map<String, Integer> tables) {
        if (args.progress) {
            return new ProgressBarBuilder()
                    .setInitialMax(tables.values().stream().mapToInt(Integer::intValue).sum())
                    .setTaskName("record copy progress")
                    .setUnit(" record", 1)
                    .setStyle(ProgressBarStyle.ASCII)
                    .setUpdateIntervalMillis(1000)
                    .showSpeed()
                    .build();
        } else {
            return null;
        }
    }

    private void executeLiquibaseWithContext(DataSource targetDataSource, Writer writer, String contexts) throws IOException, LiquibaseException, JoranException {

        if (!isBlank(args.outputFile)) {
            File tempFile = File.createTempFile("updateSQL", ".sql");
            Main.run(new String[]{
                    "--logLevel=off",
                    String.format("--url=%s", this.args.targetDbUrl),
                    "--changeLogFile=liquibase.xml",
                    String.format("--username=%s", this.args.targetDbUser),
                    String.format("--password=%s", this.args.targetDbPassword),
                    String.format("--outputFile=%s", tempFile.getAbsolutePath()),
                    String.format("--contexts=%s", contexts),
                    "update"
            });

            String sql = FileUtils.readFileToString(tempFile, StandardCharsets.UTF_8);
            executeAndLog(targetDataSource, writer, sql, false);
        }

        if (args.insert) {
            Main.run(new String[]{
                    "--logLevel=off",
                    String.format("--url=%s", this.args.targetDbUrl),
                    "--changeLogFile=liquibase.xml",
                    String.format("--username=%s", this.args.targetDbUser),
                    String.format("--password=%s", this.args.targetDbPassword),
                    String.format("--contexts=%s", contexts),
                    "update"
            });
        }

        // because liquibase will hijack logging
        LoggerContext lc = (LoggerContext) LoggerFactory.getILoggerFactory();
        lc.reset();

        new ContextInitializer(lc).autoConfig();

    }

    private Writer writer() throws IOException {
        if (isBlank(args.outputFile)) {
            return null;
        }

        BufferedOutputStream out = new BufferedOutputStream(new FileOutputStream(args.outputFile));

        if (args.outputFile.endsWith(".gz")) {
            return new OutputStreamWriter(new GZIPOutputStream(out));
        } else {
            return new OutputStreamWriter(out);
        }
    }

    private void withWriter(ThrowingConsumer<Writer> consumer) throws Exception {
        try (Writer writer = writer()) {
            consumer.accept(writer);
        }
    }

    private void resetSequences(DataSource targetDataSource, Set<String> tableNames, Writer writer) throws IOException, SQLException {
        SQLDialect dialect = getDialect(targetDataSource);
        comment(writer, "Setting sequences");

        switch (dialect.family()) {
            case MYSQL:
                break; // do nothing, mysql automatically sets sequence
            case H2:
                break; // do nothing, h2 automatically sets sequence
            case POSTGRES:
                for (String tableName : tableNames) {
                    String sequenceName = tableName.toLowerCase() + "_id_seq";
                    String sql = String.format("select setval('%s', (select max(id) from %s))", sequenceName, tableName);

                    executeAndLog(targetDataSource, writer, sql, args.insert);
                }
                break;
            default:
                throw new UnsupportedOperationException("Database " + dialect.family() + " is not supported");

        }
    }

    private SQLDialect getDialect(DataSource targetDataSource) throws SQLException {
        SQLDialect dialect;
        try (Connection connection = targetDataSource.getConnection()) {
            dialect = using(connection).configuration().dialect();
        }
        return dialect;
    }

    private void dumpTableSQL(String table, Integer rowCount, Connection sourceConnection, DataSource targetDataSource, Writer writer, ProgressBar progressBar) throws IOException, SQLException {
        LOG.debug("Copying {} records in table {}", rowCount, table);
        Field<Long> idField = field("id", Long.class);
        int maxIdInTable = using(sourceConnection).select(max(idField)).from(table).execute();

        comment(writer, "dumping records for table " + table);
        long lastIdSeen = 0L;
        while (lastIdSeen != maxIdInTable) {
            Result<Record> records = using(sourceConnection)
                    .select(asterisk())
                    .from(table)
                    .orderBy(idField)
                    .seek(lastIdSeen)
                    .limit(args.batchSize)
                    .fetch();

            if (records.isEmpty()) {
                break;
            }

            Field<?>[] fields = records.fields();

            Field<Long> idFieldInCurrentSourceTable = (Field<Long>) Arrays.stream(fields)
                    .filter(field -> field.getName().equalsIgnoreCase("id"))
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException("Unable to determine "));

            lastIdSeen = records.get(records.size() - 1).getValue(idFieldInCurrentSourceTable);

            executAndLogInsertStatement(table, targetDataSource, writer, records);
            if (progressBar != null) {
                progressBar.stepBy(records.size());
            }
        }
    }

    private void executAndLogInsertStatement(String table, DataSource targetDataSource, Writer writer, Result<Record> records) throws SQLException {
        Field<?>[] fields = records.fields();
        InsertValuesStepN<Record> insertQuery = insertInto(table(table), fields);

        for (Record record : records) {
            insertQuery.values(record.intoArray());
        }

        try (Connection connection = targetDataSource.getConnection()) {
            String bulkInsertSql = renderer(connection).renderInlined(insertQuery);
            executeAndLog(targetDataSource, writer, bulkInsertSql, args.insert);
        }
    }

    private static DSLContext renderer(Connection targetConnection) {
        Configuration targetConfiguration = using(targetConnection).configuration();
        RenderNameStyle renderNameStyle = targetConfiguration.dialect().family() == SQLDialect.POSTGRES ? AS_IS : QUOTED;
        return using(targetConfiguration.derive(SettingsTools.clone(targetConfiguration.settings())
                .withRenderFormatted(false)
                .withRenderNameStyle(renderNameStyle)));
    }

    private static Map<String, Integer> listTables(BasicDataSource sourceDataSource) {
        Map<String, Integer> tables = new LinkedHashMap<>();

        withDataSource(sourceDataSource, (connection) -> {
            Field<String> field = field("TABLE_NAME", String.class);
            Result<Record1<String>> result = using(connection)
                    .select(field)
                    .from("INFORMATION_SCHEMA.tables")
                    .where("table_schema in ('PUBLIC', 'public') and table_type in ('TABLE', 'BASE TABLE')")
                    .fetch();

            for (Record1<String> record : result) {
                String tableName = record.getValue(field);

                if (!isChangeLogTable(tableName)) {
                    tables.put(tableName, using(connection).fetchCount(table(tableName)));
                }
            }
        });

        return tables;
    }

    private static boolean isChangeLogTable(String tableName) {
        return tableName.equalsIgnoreCase("CHANGELOG") ||
                tableName.equalsIgnoreCase("DATABASECHANGELOG") ||
                tableName.equalsIgnoreCase("DATABASECHANGELOGLOCK");
    }
}
