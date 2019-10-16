# Move Maven Artifacts

Tool that gets all artifacts in a `Public Maven Repo` and move all to another `Maven Repo` that has access by username and password. 

## Prerequisites

Install the `Maven Client` and make it available at system path.

[http://maven.apache.org/download.cgi](http://maven.apache.org/download.cgi)

## Build

```shell script
$ git clone https://github.com/rzcastilho/move_maven_artifacts
$ cd move_maven_artifacts
$ mix deps.get
$ mix escript.build
```

## Run

```shell script
$ ./move_maven_artifacts -s <maven_repo_source> -t <maven_repo_target> -p <initial_path>
```

**Important:** Inform `username` and `password` in the target URL like below.

```
https://<username>:<password>@<hostname>:<port>
```
