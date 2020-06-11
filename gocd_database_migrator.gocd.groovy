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

GoCD.script {
  pipelines {
    pipeline('gocd-database-migrator') {
      group = 'go-cd'
      materials {
        git('db-migrator') {
          branch = 'master'
          shallowClone = false
          url = 'https://git.gocd.io/git/gocd/gocd-database-migrator'
        }
      }
      stages {
        stage("test") {
          fetchMaterials = true
          jobs {
            job('test') {
              elasticProfileId = "ecs-gocd-dev-build-dind"
              tasks {
                exec {
                  commandLine = ['./gradlew', 'clean', 'check', 'assembleDist']
                  runIf = 'passed'
                }
              }
            }
          }
        }

        stage("github-preview-release") {
          fetchMaterials = true
          environmentVariables = [
            GITHUB_USER : 'gocd',
            GITHUB_TOKEN: "{{SECRET:[build-pipelines][GOCD_CI_USER_RELEASE_TOKEN]}}"
          ]
          jobs {
            job('create-preview-release') {
              elasticProfileId = "ecs-gocd-dev-build-dind"
              tasks {
                exec {
                  commandLine = ['./gradlew', 'githubRelease']
                  runIf = 'passed'
                }
              }
            }
          }
        }

        stage("github-release") {
          fetchMaterials = true
          environmentVariables = [
            GITHUB_USER : 'gocd',
            PRERELEASE  : "NO",
            GITHUB_TOKEN: "{{SECRET:[build-pipelines][GOCD_CI_USER_RELEASE_TOKEN]}}"
          ]
          approval { type = 'manual' }
          jobs {
            job('create-release') {
              elasticProfileId = "ecs-gocd-dev-build-dind"
              tasks {
                exec {
                  commandLine = ['./gradlew', 'githubRelease']
                  runIf = 'passed'
                }
              }
            }
          }
        }
      }
    }
  }
}

