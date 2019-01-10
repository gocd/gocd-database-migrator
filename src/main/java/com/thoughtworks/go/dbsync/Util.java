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

import org.apache.commons.dbcp2.BasicDataSource;
import org.postgresql.Driver;

import javax.sql.DataSource;
import java.io.IOException;
import java.io.Writer;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

import static com.thoughtworks.go.dbsync.DbSync.LOG;

class Util {
    private static final String SQL_STMT_TERMINATE = ";\n";

    static BasicDataSource createDataSource(String sourceDriverClass, String sourceUrl, String sourceUser, String sourcePassword, boolean readOnly) {
        BasicDataSource dataSource = new BasicDataSource();
        dataSource.setDriverClassName(sourceDriverClass);
        if (sourceDriverClass.equals(Driver.class.getName()) || sourceUrl.startsWith("jdbc:postgresql")) {
            dataSource.setConnectionProperties("preferQueryMode=extendedCacheEverything");
        }
        dataSource.setUrl(sourceUrl);
        dataSource.setUsername(sourceUser);
        dataSource.setDefaultReadOnly(readOnly);
        dataSource.setPassword(sourcePassword);
        dataSource.setMaxTotal(32);
        return dataSource;
    }

    static void comment(Writer writer, String string) throws IOException {
        if (writer != null) {
            writer.append("--\n");
            writer.append("-- ").append(string).append("\n");
            writer.append("--\n");
        }
    }

    static void executeAndLog(DataSource targetDataSource, Writer writer, String sql, boolean execute) {
        if (writer != null) {
            write(writer, sql);
        }
        if (execute) {
            execute(targetDataSource, sql);
        }
    }

    private static void write(Writer writer, String sql) {
        long currentTime = System.currentTimeMillis();
        try {
            writer.append(sql).append(SQL_STMT_TERMINATE);
            writer.flush();
        } catch (Exception e) {
            LOG.error(null, e);
            throw new RuntimeException(e);
        } finally {
            long endTime = System.currentTimeMillis();
            LOG.debug("Took {}ms to write SQL", endTime - currentTime);
        }
    }

    private static void execute(DataSource targetDataSource, String sql) {
        long currentTime = System.currentTimeMillis();
        LOG.debug("Executing SQL: {}", sql.substring(0, Math.min(sql.length(), 100)));
        try {
            try (Connection connection = targetDataSource.getConnection()) {
                connection.createStatement().execute(sql);
            }
        } catch (SQLException e) {
            LOG.error(null, e);
            throw new RuntimeException(e);
        }
        long endTime = System.currentTimeMillis();
        LOG.debug("Took {}ms to execute SQL: {}", endTime - currentTime, sql.substring(0, Math.min(sql.length(), 100)));
    }

    static void withDataSource(BasicDataSource dataSource, ThrowingConsumer<Connection> consumer) {
        try (Connection connection = dataSource.getConnection()) {
            try {
                consumer.accept(connection);
            } catch (Exception e) {
                LOG.error(null, e);
                throw new RuntimeException(e);
            }
        } catch (SQLException e) {
            LOG.error(null, e);
            throw new RuntimeException(e);
        }
    }

    static class LinkedQueue<T> extends LinkedBlockingQueue<T> {
        LinkedQueue(int capacity) {
            super(capacity);
        }

        @Override
        public boolean offer(T o) {
            try {
                put(o);
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
            return true;
        }

        @Override
        public boolean add(T o) {
            try {
                put(o);
                return true;
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
        }

        @Override
        public boolean offer(T o, long timeout, TimeUnit unit) throws InterruptedException {
            put(o);
            return true;
        }
    }
}
