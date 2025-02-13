import time
import logging

# 設定 logging
logging.basicConfig(filename="logs/log.log", level=logging.INFO, format="%(asctime)s - %(message)s")

a = 1
while True:
    logging.info(f"自動記錄 Log, 第{a}筆記錄")
    a += 1
    time.sleep(60)
