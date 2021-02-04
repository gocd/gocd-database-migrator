# Tool for Migrating a GoCD database on version 20.4.0 (or below) to a GoCD 20.5.0 complaint database.

GoCD has done several changes in version `v20.5.0` to its database implementation in order to build a more flexible model that allowed integrating GoCD with multiple databases.
This application helps to migrate the data from older GoCD database `v20.4.0` (or below) to the GoCD `v20.5.0` compatible database.

Know more about GoCD support for multiple databases [here](https://docs.gocd.org/20.5.0/installation/configuring_database.html).


## Features:

* Migrates data from older GoCD database `v20.4.0` (or below) to the GoCD `v20.5.0` compatible database. This tool helps to upgrade the data from existing GoCD database running on GoCD `v20.4.0` (or below) to the GoCD `v20.5.0` compatible database.

* As part of migrating data from a older GoCD `v20.4.0` (or below) to the GoCD `v20.5.0` database, users can convert/sync data from one database to another. This allows GoCD users to switch from any of the existing database to `H2`, `PostgreSQL` or `MySQL` database.

* For databases which are already migrated and are GoCD `v20.5.0` compliant, this tool can be used to sync data to a new database post the initial migration to GoCD `v20.5.0`.
E.g Sync data from a GoCD `v20.5.0` H2 database to a new PostgreSQL database. Verified to work till GoCD `v20.8.0`.

## Supported Databases

* H2 (`1.3.xxx` and above)
* PostgreSQL (`9.6` and above)
* MySQL (`8.0`)

## Installation

#### 1. From The Source:

The `GoCD Database Migrator v1.0.0` sources can be obtained from the [GitHub Releases](). You should get a file named `gocd-database-migrator-1.0.0.tgz`.
After you have downloaded the file, unpack it:

```bash
$ gunzip gocd-database-migrator-1.0.0.tgz
$ tar xf gocd-database-migrator-1.0.0.tar
```

This will create a directory `gocd-database-migrator-1.0.0` under the current directory with the GoCD Database Migrator sources.
Change into the directory and run `./bin/gocd-database-migrator --help` for usage instructions.

## Databases migration instructions

Follow detailed instructions in [Upgrading to GoCD 20.5.0](https://docs.gocd.org/20.5.0/installation/upgrade_to_gocd_20.5.0.html) document to migrate your database.


# Command Arguments:

| Argument &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; | Description                                                                                             |
|:---------------------------- |:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `source-db-url`              | The source database url. Specify the existing GoCD database url. <br/> If none specified, it will default to `cruise` (this is the H2 database file without the `.h2.db` extension) in the current directory. See [Example database connection URLs](#example-database-connection-urls). |
| `source-db-driver-class`     | The source database driver class. <br/> If none specified, it will choose the appropriate driver class based on the specified `--source-db-url`. See [Default database driver class](#default-database-driver-class). |
| `source-db-user`             | The username of the source database. |
| `source-db-password`         | The password of the source database. |
| `target-db-url`              | The target database url. Specify the newly created database url where the data will be copied. See [Example database connection URLs](#example-database-connection-urls). |
| `target-db-driver-class`     | The target database driver class. <br/> If none specified, it will choose the appropriate driver class based on the specified `--target-db-url`. See [Default database driver class](#default-database-driver-class). |
| `target-db-user`             | The username of the target database. |
| `target-db-password`         | The password of the target database. |
| `batch-size`                 | The number of records to `SELECT` from the source database to `INSERT` into the target database in each batch. <br/> **Default:** 100000 |
| `output`                     | The output SQL file. Specify `.gz` extension to enable gzip compression. |
| `insert`                     | Perform `INSERT` into target database. <br/> **Default:** false |
| `progress`                   | Show the progress of the export operation. <br/> **Default:** false |
| `threads`                    | Number of import threads. <br/> **Default:** the number of processor cores (up to 8) |


## Example database connection URLs:
Some example database URLs that the tool understands:

- H2 URL:         `jdbc:h2:/path/to/cruise` (this is the H2 database path without the `.db` extension)
- PostgreSQL URL: `jdbc:postgresql://localhost:5432/gocd`
- MySQL URL:      `jdbc:mysql://localhost:3306/gocd`


## Default database driver class:
When no database driver is specified for the source database (`--source-db-driver-class`) or the target database (`--target-db-driver-class`), based on the specified database url, the tool will choose the appropriate driver class.

- For H2 database urls (starting with `jdbc:h2:`), database driver is set to `org.h2.Driver`.
- For PostgreSQL database urls (starting with `jdbc:postgresql:`), database driver is set to `org.postgresql.Driver`.
- For MySQL database urls (starting with `jdbc:mysql:`), database driver is set to `com.mysql.cj.jdbc.Driver`.


# Example usages:

- Migrate from an older version of GoCD (which uses an old H2 version) to a newer version that uses a new H2 version.

    ```shell
    ./bin/gocd-database-migrator \
            --insert \
            --progress \
            --source-db-url='jdbc:h2:/godata/backup/db/h2db/cruise' \
            --source-db-user='sa' \
            --source-db-user='sa-password' \
            --target-db-url='jdbc:h2:/var/lib/gocd/new-database/db/h2db/cruise' \
            --target-db-user='target-sa' \
            --target-db-password='target-sa-password'
    ```

- Sync data from H2 to PostgreSQL

    ```shell
    ./bin/gocd-database-migrator \
            --insert \
            --progress \
            --source-db-url='jdbc:h2:/godata/backup/db/h2db/cruise' \
            --source-db-user='sa' \
            --source-db-user='sa-password' \
            --target-db-url='jdbc:postgresql://localhost:5432/cruise' \
            --target-db-user='postgres' \
            --target-db-password='postgres-password'
    ```

## License

```plain
Copyright 2020 ThoughtWorks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
