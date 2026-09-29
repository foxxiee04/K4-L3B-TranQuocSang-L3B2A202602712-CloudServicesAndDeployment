# Thông Tin Deploy — Checkpoint 5

> `pytest tests/test_cp5.py` đọc Public URL bên dưới để kiểm tra service.
>
> **Chỉ ghi TÊN biến môi trường, tuyệt đối không dán giá trị API key vào đây.**
> Repo này công khai — dán khóa vào là mất khóa.

## Thông Tin Học Viên

| Mục | Nội dung |
|-----|----------|
| Họ và tên | Trần Quốc Sáng |
| Mã học viên | L3B2A202602712 |
| Repo | https://github.com/foxxiee04/K4-L3B-TranQuocSang-L3B2A202602712Cloud-Service-And-Deployment |

## Service

| Mục | Nội dung |
|-----|----------|
| Public URL | https://day12-agent-production-6c59.up.railway.app |
| Platform | Railway |
| Ngày deploy | 29/09/2026 |

## Biến Môi Trường Đã Set Trên Cloud

Ghi tên biến và **nguồn giá trị**, không ghi giá trị:

| Biến | Đã set | Ghi chú |
|------|--------|---------|
| `PORT` | ✅ | platform tự gán |
| `AGENT_API_KEY` | ✅ | đặt trong dashboard, không nằm trong repo |
| `REDIS_URL` | ✅ | Railway Redis service `day12-redis` |
| `RATE_LIMIT_PER_MINUTE` | ✅ | 10 |
| `MONTHLY_BUDGET_USD` | ✅ | 10.0 |
| `LOG_LEVEL` | ✅ | INFO |

## Lệnh Kiểm Tra

Các lệnh dưới đây dùng PowerShell. `DEPLOY_API_KEY` cần được đặt trong biến môi
trường của phiên làm việc và không ghi giá trị vào repository.

```powershell
# 1. Liveness — mong đợi 200 {"status":"ok"}
curl.exe -i https://day12-agent-production-6c59.up.railway.app/health

# 2. Readiness — mong đợi 200 {"status":"ready"} (đã nối được Redis)
curl.exe -i https://day12-agent-production-6c59.up.railway.app/ready

# 3. Không có API key — mong đợi 401
try {
  Invoke-WebRequest -Uri https://day12-agent-production-6c59.up.railway.app/ask `
    -Method Post -ContentType application/json -Body '{"question":"Hello"}'
} catch { $_.Exception.Response.StatusCode.value__ }

# 4. Có API key — mong đợi 200 kèm câu trả lời
Invoke-WebRequest -Uri https://day12-agent-production-6c59.up.railway.app/ask `
  -Method Post -ContentType application/json `
  -Headers @{"X-API-Key"=$env:DEPLOY_API_KEY; "X-User-Id"="sv-test"} `
  -Body (@{question="Deploy là gì?"} | ConvertTo-Json)

# 5. Rate limit — gọi 15 lần, những lần cuối phải trả 429
1..15 | ForEach-Object {
  try {
    (Invoke-WebRequest -Uri https://day12-agent-production-6c59.up.railway.app/ask `
      -Method Post -ContentType application/json `
      -Headers @{"X-API-Key"=$env:DEPLOY_API_KEY; "X-User-Id"="rate-limit-check"} `
      -Body (@{question="test"} | ConvertTo-Json)).StatusCode
  } catch { $_.Exception.Response.StatusCode.value__ }
}
```

## Kết Quả Chạy Thật

Output đã ghi trong phiên deploy ngày 29/09/2026:

```
1. (.venv) C:\AI_VINUNI\K4-L3B-TranQuocSang-L3B2A202602712Cloud-Service-And-Deployment>curl -i https://day12-agent-production-6c59.up.railway.app/health
HTTP/1.1 200 OK
Content-Type: application/json
Date: Tue, 29 Sep 2026 04:05:20 GMT
Server: railway-hikari
x-railway-request-id: FBwI9WpJSduCwAf5YqVb7A
Content-Length: 57
x-hikari-trace: sin1.tr00
x-railway-edge: sin1
Connection: keep-alive

{"status":"ok","service":"day12-agent","version":"1.0.0"}

2. (.venv) C:\AI_VINUNI\K4-L3B-TranQuocSang-L3B2A202602712Cloud-Service-And-Deployment>curl -i https://day12-agent-production-6c59.up.railway.app/ready
HTTP/1.1 200 OK
Content-Type: application/json
Date: Tue, 29 Sep 2026 04:07:27 GMT
Server: railway-hikari
x-railway-request-id: dV5IcOFARPKvZIDvwUFZXw
Content-Length: 31
x-hikari-trace: sin1.98a6
x-railway-edge: sin1
Connection: keep-alive

{"status":"ready","redis":true}

3. (.venv) PS C:\AI_VINUNI\K4-L3B-TranQuocSang-L3B2A202602712Cloud-Service-And-Deployment> curl.exe -i -X POST "https://day12-agent-production-6c59.up.railway.app/ask" -H "Content-Type: application/json" -d '{\"question\":\"Hello\"}'
HTTP/1.1 401 Unauthorized
Content-Type: application/json
Date: Tue, 29 Sep 2026 04:09:16 GMT
Server: railway-hikari
x-railway-request-id: 8LYS3nqjR2aMoZkYY53eZw
Content-Length: 39
x-hikari-trace: sin1.nzn2
x-railway-edge: sin1
Connection: keep-alive

{"detail":"invalid or missing API key"}

4.(.venv) PS C:\AI_VINUNI\K4-L3B-TranQuocSang-L3B2A202602712Cloud-Service-And-Deployment> curl.exe -i "https://day12-agent-production-6c59.up.railway.app/ask" -H "Content-Type: application/json" -H "X-API-Key: $env:DEPLOY_API_KEY" -H "X-User-Id: sv-test" --data-binary "@body.json"
HTTP/1.1 200 OK
Content-Type: application/json
Date: Tue, 29 Sep 2026 04:14:01 GMT
Server: railway-hikari
x-railway-request-id: HJGP2-AtTretAbjQLPU1MQ
Content-Length: 287
x-hikari-trace: sin1.d1nj
x-railway-edge: sin1
vary: accept-encoding
Connection: keep-alive

{"answer":"Ngắn gọn: Deploy la gi phụ thuộc vào ba yếu tố — cấu hình qua biến môi trường, health check để orchestrator biết trạng thái, và giới hạn tài nguyên.","user_id":"sv-test","history_length":0,"cost_usd":2.265e-05,"tokens":{"in":3,"out":37}}

5.
(.venv) PS C:\AI_VINUNI\K4-L3B-TranQuocSang-L3B2A202602712Cloud-Service-And-Deployment> 1..15 | ForEach-Object { try { Invoke-WebRequest -Uri "https://day12-agent-production-6c59.up.railway.app/ask" -Method Post -Headers @{"X-API-Key"=$env:DEPLOY_API_KEY;"X-User-Id"="rate-limit-test-2"} -ContentType "application/json" -Body (@{question="test"} | ConvertTo-Json) -UseBasicParsing | ForEach-Object { $_.StatusCode } } catch { $_.Exception.Response.StatusCode.value__ } }
200
200
200
200
200
200
200
200
200
200
429
429
429
429
429
```

## Ảnh Chụp Màn Hình

Ảnh chụp kết quả gọi API trong `screenshots/`:

- `health.png`: `/health` trả 200.
- `ready.png`: `/ready` trả 200, Redis sẵn sàng.
- `ask-unauthorized.png`: `/ask` không có khóa trả 401.
- `ask-authorized.png`: `/ask` có khóa trả 200.
