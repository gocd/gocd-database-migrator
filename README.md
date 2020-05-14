# Tool for Migrating GoCD data between H2/PostgreSQL/MySQL 

GoCD has done several changes to its database implementation in order to build a more flexible model that allowed integrating GoCD with multiple databases.
This application helps to migrate the data from older GoCD database to the GoCD v20.5.0 compatible database.

Know more about GoCD support for multiple databases at [GoCD open sources Postgres Database addon]() blog post.

## Features:

* Migrates data from older GoCD database to the GoCD v20.5.0 compatible database. This tool helps to upgrade the data from existing GoCD database running on GoCD v20.4.0 (or below) to the GoCD v20.5.0 compatible database.  

* Convert/Sync data from one database to another. This allows GoCD users to switch from any of the existing database to `H2`, `PostgreSQL` and `MySQL` database.


## Usage

1. Download `gocd-db-migrator.tgz` tool from [Github releases]().

2. Extract the downloaded tar file.

    ```shell
    tar -zxf gocd-db-migrator-VERSION.tgz
    cd gocd-db-migrator
    ```

3. Create a new database of your choice. (where `gocd-db-migrator` will copy the existing data).
    
    **NOTE:** _If you wish you change your existing GoCD database from `H2`, `PostreSQL` to any of `H2`, `PosgreSQL`, `MySQL`, please choose to create the database of your choice.
    `gocd-db-migrator` tool has the capability to migrate the data from `H2`, `PostreSQL` to any of `H2`, `PosgreSQL`, `MySQL` database._

    3.1 Visit [www.h2database.com](http://www.h2database.com/html/quickstart.html) for creating a new H2 database.

    3.2 Visit [www.postgresql.org](https://www.postgresql.org/docs/9.6/sql-createdatabase.html) for creating a new PostgreSQL database.
    
    3.3 Visit [dev.mysql.com](https://dev.mysql.com/doc/refman/5.7/en/create-database.html) for creating a new MySQL database.
    
-- GANESHPL: do we need to create user and all?? any specific permissions?? --

4. Migrate the data from existing database to the newly created database using `gocd-db-migrator` command.

```shell
./bin/gocd-h2-db-export \
    --insert \
    --source-db-url='jdbc:h2:~/tmp/backup/cruise' \
    --target-db-url='jdbc:h2:~/projects/gocd/gocd/server/db/h2db/cruise'
```

# Command Arguments:

| Argument                   | Description                                                                                             |
|:-------------------------- |:------------------------------------------------------------------------------------------------------- |
| `--source-db-url`          | The source database url. Specify the existing GoCD database url. <br/> When none specified, it will default to looking up `cruise.h2.db` in the current directory. <br/> **Default:** `jdbc:h2:cruise` |
|   |   |
| `--source-db-driver-class` | The source database driver class. <br/> When none specified, based on the specified --source-db-url it will choose the appropriate driver class. |


# Some example usages:

- Migrate from an older version of GoCD (which uses an old H2 version) to a newer version that uses a new H2 version.

    ```shell
    ./bin/gocd-h2-db-export \
            --source-db-url='jdbc:h2:~/tmp/backup/cruise' \
            --target-db-url='jdbc:h2:~/projects/gocd/gocd/server/db/h2db/cruise'
    ``` 

- Sync data from H2 to PostgreSQL

    ```shell
    ./bin/gocd-h2-db-export \
            --source-db-url='jdbc:h2:~/tmp/backup/cruise' \
            --target-db-url='=jdbc:postgresql://localhost/gocd'
    ``` 

# Specifying database connection URLs

Some example database URLs that the program understands:

- `jdbc:h2:/path/to/cruise` (this is the path without the `.db` extension)
- `jdbc:postgresql://localhost:5432/cruise`
- `jdbc:mysql://localhost:3306/cruise`

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
