# ═══════════════════════════════════════════════════════════════════
# CP2 — Containerization
#
# Dưới đây là Dockerfile "chạy được nhưng chưa production": một stage,
# chạy bằng user root, không có health check, base image nặng.
#
# NHIỆM VỤ: sửa file này thành bản production-ready. Yêu cầu:
#   [ ] Multi-stage build: stage `builder` cài dependency, stage runtime
#       chỉ copy kết quả sang → image nhỏ hơn, không mang theo compiler.
#       Cú pháp: `FROM python:3.11-slim AS builder`
#   [ ] Base image slim (hoặc alpine), không dùng `python:3.11` bản đầy đủ
#   [ ] COPY requirements.txt và pip install TRƯỚC khi COPY source code
#       (Docker cache theo layer: sửa 1 dòng code không phải cài lại thư viện)
#   [ ] Tạo user thường và chuyển sang bằng lệnh `USER` — container chạy
#       root nghĩa là ai thoát được khỏi app cũng thành root trên host
#   [ ] Có `HEALTHCHECK` gọi vào endpoint /health
#   [ ] Đọc cổng từ biến môi trường PORT (cloud tự gán cổng, không cố định 8000)
#
# Kiểm tra:  pytest tests/test_cp2.py -v
# Build thử: docker build -t day12-agent:prod .
#            docker images day12-agent:prod     # xem dung lượng
# ═══════════════════════════════════════════════════════════════════

# ============================================================
# Stage 1: Builder
# Cài dependency riêng để tận dụng Docker layer cache
# ============================================================
FROM python:3.11-slim AS builder

WORKDIR /app

# Copy dependency manifest trước source code.
# Khi chỉ sửa code Python, layer pip install vẫn được cache.
COPY requirements.txt .

# Cài dependency vào một thư mục riêng để stage runtime copy sang.
RUN pip install \
    --no-cache-dir \
    --prefix=/install \
    -r requirements.txt


# ============================================================
# Stage 2: Runtime
# Chỉ chứa những gì cần để chạy application
# ============================================================
FROM python:3.11-slim AS runtime

WORKDIR /app

# Copy Python packages đã cài từ builder.
COPY --from=builder /install /usr/local

# Copy source sau dependency để tận dụng Docker cache.
COPY app ./app
COPY utils ./utils

# Tạo user thường.
# Không chạy application bằng root.
RUN useradd \
    --create-home \
    --uid 10001 \
    appuser \
    && chown -R appuser:appuser /app

USER appuser

# Port mặc định khi chạy local.
ENV PORT=8000

EXPOSE 8000

# Kiểm tra liveness của container.
# Dùng Python stdlib nên không phải cài curl.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:' + __import__('os').environ.get('PORT', '8000') + '/health')" || exit 1

# Cloud như Railway có thể inject PORT khác 8000.
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
