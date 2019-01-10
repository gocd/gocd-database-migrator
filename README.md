# Migrating GoCD data between H2/PostgreSQL/MySQL 

This application helps convert/sync data stored in H2/PostgreSQL/MySQL.

# Usage

```shell
tar -zxf gocd-h2-db-export-VERSION.tgz
cd gocd-h2-db-export-VERSION
./bin/gocd-h2-db-export --help
```

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
- `jdbc:postgresql://localhost:5432/gocd`
- `jdbc:mysql://localhost:3306/gocd`

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
