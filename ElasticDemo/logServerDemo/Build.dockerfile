# 使用 Python 基礎映像
FROM python:3.9

# 設定工作目錄
WORKDIR /app

# 複製程式碼到容器
COPY app.py .

# 執行 Python 腳本
CMD ["python", "app.py"]
