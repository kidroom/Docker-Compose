import time
import logging

# 設定 logging
logging.basicConfig(
    filename="logs/log.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(filename)s:%(lineno)d - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

a = 1
while True:
    logging.info(f"自動記錄 Log, 第{a}筆記錄")
    if a % 3 == 0:
        logging.error(f"自動記錄 Error Log, 第{a}筆記錄")
    a += 1
    time.sleep(60)
