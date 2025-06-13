1. build log-server image, switch to logServerDemo and run
    ``` 
    docker build -f {dockerfilename} -t {tagname} .
    # dockerfilename: 專案內的Build.dockerfile
    # tagname: 自定義image名稱，版號可不帶預設為latest，若想帶上板號格視為 {tagname}:{version}
    ```
2. switch to ElasticDemo and run `docker compose up -d` 