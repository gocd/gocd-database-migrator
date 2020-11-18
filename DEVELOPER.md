# Syncing the DB schema from GoCD's master.

1. Startup a fresh instance of GoCD server. Wait until the DB is migrated. Stop the GoCD server. 
2. Download and extract liquibase. Copy the `h2.jar` (same version as that used by GoCD) into the `lib` directory of liquibase.
3. Execute liquibase to generate a liquibase compatible changelog
    ```shell
   ./liquibase --username sa \
               --url jdbc:h2:/path/to/cruise \
               --changeLogFile changelog.xml \
               --changeSetAuthor 'gocd(generated)' \
               generateChangeLog
    ```
4. Modify the `ConverterTest` to point to the `changelog.xml` file. This will output some files in the `generated` directory.
5. Move the files from `create-{index,schema,view}.xml` from `generated` dir into the `resources` dir.
6. Ensure that the `left-over.xml` file contains no nodes.
7. Run a diff of the XML files to make sure changes look OK. Some changes to `create-view.xml` may need to be fixed by hand (remove quotes, fix some join queries, etc)
8. Package and bundle the distribution `./gradlew clean assembleDist`


# Building the distribution

```shell
./gradlew clean assembleDist
```
