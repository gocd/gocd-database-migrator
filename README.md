# Tool for Migrating GoCD data between H2/PostgreSQL/MySQL

GoCD has done several changes to its database implementation in order to build a more flexible model that allowed integrating GoCD with multiple databases.
This application helps to migrate the data from older GoCD database to the GoCD `v20.5.0` compatible database.

Know more about GoCD support for multiple databases [here]().


## Features:

* Migrates data from older GoCD database to the GoCD `v20.5.0` compatible database. This tool helps to upgrade the data from existing GoCD database running on GoCD `v20.4.0` (or below) to the GoCD `v20.5.0` compatible database.

* Convert/Sync data from one database to another. This allows GoCD users to switch from any of the existing database to `H2`, `PostgreSQL` or `MySQL` database.


## Supported Databases

* H2 (`1.3.xxx` and above)
* PostgreSQL (`9.6` and above)
* MySQL (`8.0`)


## Installation

#### 1. From The Source:

The `GoCD Database Migrator v1.0.0` sources can be obtained from the [Github Releases](). You should get a file named `gocd-database-migrator-1.0.0.tgz`.
After you have downloaded the file, unpack it:

```bash
$ gunzip gocd-database-migrator-1.0.0.tgz
$ tar xf gocd-database-migrator-1.0.0.tar
```

This will create a directory `gocd-database-migrator-1.0.0` under the current directory with the GoCD Database Migrator sources.
Change into the directory and run `./bin/gocd-database-migrator --help` for usage instructions.


~~ TODO: @ganeshpl says DOCKER IS NOT A PRIORITY can be removed ~~
#### 2. Using Docker Image:

Pull the `GoCD Database Migrator v1.0.0` docker image from [Dockerhub](https://hub.docker.com/) at [gocd/gocd-database-migrator](https://hub.docker.com/r/gocd/gocd-database-migrator).

```bash
$ docker pull gocd/gocd-database-migrator:v1.0.0
```

Run the container from the pulled `gocd/gocd-database-migrator:v1.0.0` docker image. Specify the GoCD Database Migrator command arguments using docker run command.

Example:
```bash
$ docker container run gocd/gocd-database-migrator:v1.0.0 --help
```


## Usage

1. [_Optional_] Upgrade the GoCD Server to `GoCD v20.4.0`.

    The `GoCD Database Migrator` tool has the ability to migrate the database from any version of GoCD (prior to `v20.4.0`) to `v20.5.0`. As GoCD has undergone serveral breaking changes every release, it is recommended to upgrade your existing GoCD instance to `v20.4.0` before performing the data migration.


2. Backup GoCD database and configurations using [One Click Backup](https://docs.gocd.org/current/advanced_usage/one_click_backup.html) feature of GoCD.


3. Stop the running server.


4. Create a new database of your choice. (i.e., the destination database where `gocd-database-migrator` will copy the existing database's data).

    **NOTE:** _`gocd-database-migrator` tool has the capability to migrate the data from `H2`or `PostreSQL` to any of `H2`, `PosgreSQL`, or `MySQL`. If you wish you change your existing GoCD database from `H2` or `PostreSQL` to any of `H2`, `PosgreSQL`, or `MySQL`, please create a new destination database._

    3.1 Visit [www.h2database.com](http://www.h2database.com/html/quickstart.html) for creating a new H2 database.

    3.2 Visit [www.postgresql.org](https://www.postgresql.org/docs/9.6/sql-createdatabase.html) for creating a new PostgreSQL database.

    3.3 Visit [dev.mysql.com](https://dev.mysql.com/doc/refman/5.7/en/create-database.html) for creating a new MySQL database.


5. Migrate the data from the existing database to the newly created database using the `gocd-database-migrator` command.
    Refer to [Command Arguments](#command-arguments) for specifying options for the `gocd-database-migrator` tool.
    Refer to [examples](#some-example-usages) for data migration.


6. Define new database configurations in the `config/db.properties` file. Refer to [Location of GoCD server files](https://docs.gocd.org/current/installation/installing_go_server.html) for the location of the GoCD Server `config` directory.

    ```properties
    db.driver=org.postgresql.Driver
    db.url=jdbc:postgresql://localhost:5432/cruise
    db.user=postgres
    ```

    Refer to [GoCD database property configurations](provide-link-to-docs) to know the full list of configuration properties that can be specified under `config/db.properties`.


7. [_Only for existing PostgreSQL users_] Remove the `config/postgresqldb.properties` properties file and PostgreSQL addon from the `addons` directory.


8. Start GoCD Server.



# Command Arguments:

| Argument &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; | Description                                                                                             |
|:---------------------------- |:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `source-db-url`              | The source database url. Specify the existing GoCD database url. <br/> If none specified, it will default to `cruise.h2.db` in the current directory. See [Example database connection URLs](#example-database-connection-urls). |
| `source-db-driver-class`     | The source database driver class. <br/> If none specified, it will choose the appropriate driver class based on the specified `--source-db-url`. See [Default database driver class](#default-database-driver-class). |
| `source-db-user`             | The username of the source database. |
| `source-db-password`         | The password of the source database. |
| `target-db-url`              | The target database url. Specify the newly created database url where the data will be copied. See [Example database connection URLs](#example-database-connection-urls). |
| `taregt-db-driver-class`     | The target database driver class. <br/> If none specified, it will choose the appropriate driver class based on the specified `--target-db-url`. See [Default database driver class](#default-database-driver-class). |
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
When no database driver is specified for the soruce database (`--source-db-driver-class`) or the taregt database (`--target-db-driver-class`), based on the specified database url, the tool will choose the appropriate driver class.

- For H2 database urls (starting with `jdbc:h2:`), database driver is set to `org.h2.Driver`.
- For PostgreSQL database urls (starting with `jdbc:postgresql:`), database driver is set to `org.postgresql.Driver`.
- For MySQL database urls (starting with `jdbc:mysql:`), database driver is set to `com.mysql.cj.jdbc.Driver`.


# Some example usages:

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
            --target-db-user='target-sa-password'
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
            --target-db-user='postgres-password'
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
