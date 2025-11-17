1. build log-server image, switch to logServerDemo and run
    ``` 
    docker build -f {dockerfilename} -t {tagname} .
    # dockerfilename: 專案內的Build.dockerfile
    # tagname: 自定義image名稱，版號可不帶預設為latest，若想帶上板號格視為 {tagname}:{version}
    ```
2. switch to ElasticDemo and run `docker compose up -d` 
3. https://api.slack.com/apps 
    1. → Create New App → From scratch → 選你的 Workspace
    2. Feature -> Incoming Webhooks -> Activate Incoming Webhooks -> 打開開關 -> Add New Webhook -> 選擇WorkSapce、Channel -> Install test