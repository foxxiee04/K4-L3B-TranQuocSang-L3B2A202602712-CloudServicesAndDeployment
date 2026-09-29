# Phiếu Phản Ánh — K4 Level 3B, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: viết nội dung ngay dưới mỗi câu hỏi.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Trần Quốc Sáng Mã học viên: L3B2A202602712

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Nếu deploy lên Railway nhưng quên đặt `AGENT_API_KEY`, `Settings()` báo lỗi cấu
> hình ngay khi service khởi động. Tôi sẽ thấy lỗi trong runtime log và sửa biến
> môi trường trước khi cho người khác gọi `/ask`. Nếu code dùng mặc định
> `"changeme"`, service vẫn lên xanh với một khóa dễ đoán; người lạ có thể gọi
> API và tiêu ngân sách của tôi trước khi tôi phát hiện.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Tôi gọi `/ask` bằng `TestClient` với Redis giả và nhận HTTP 200. Một dòng log
> thực tế từ lần chạy đó là:
>
> `{"event": "ask_completed", "level": "info", "timestamp": "2026-09-29T04:39:01.327798+00:00", "user_id": "exercise-check", "tokens_in": 1, "tokens_out": 35, "cost_usd": 2.115e-05}`
>
> Tôi có thể lọc các bản ghi `ask_completed` theo `user_id` để tìm request của
> một người dùng, rồi cộng `cost_usd` theo khoảng thời gian để theo dõi chi phí.
> `print("đã trả lời xong")` thiếu các trường có cấu trúc để làm hai việc đó.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản               | Dung lượng   |
| ----------------- | ------------ |
| 1 stage (bản đầu) | Chưa đo được |
| Multi-stage       | Chưa đo được |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Tôi build hai image bằng Docker và đo bằng `docker images agent`. Bản single-stage
> có dung lượng 1.17 GB, trong khi bản production multi-stage là 184 MB, tức giảm
> khoảng 986 MB (xấp xỉ 84%).
>
> Sự chênh lệch không chỉ đến từ multi-stage build mà còn do bản single-stage dùng
> base image `python:3.11` đầy đủ, còn bản production dùng `python:3.11-slim`.
> Ở bản multi-stage, dependency được cài vào `/install` trong stage `builder`, sau
> đó runtime chỉ copy các package cần thiết sang image cuối. Vì vậy runtime không
> mang toàn bộ môi trường của builder và sử dụng base image nhẹ hơn.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Trong Dockerfile hiện tại, `COPY requirements.txt` và `RUN pip install` nằm
> trước `COPY app`/`COPY utils`. Nếu chỉ sửa `app/main.py`, các layer base image,
> requirements và cài dependency có thể dùng cache; layer copy source và các
> layer phía sau phải chạy lại. Nếu đặt `COPY . .` trước `RUN pip install`, thay
> một ký tự trong source cũng làm mất cache của bước cài package, khiến build
> lại chậm hơn. Tôi chưa đo thời gian build lại trong môi trường này.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Ví dụ một lỗi cho phép thực thi lệnh trong process Python: kẻ tấn công lấy
> được quyền của user đang chạy ứng dụng trong container. Nếu user đó là root,
> họ có thể sửa nhiều file trong container và, khi có mount hoặc cấu hình
> container nguy hiểm, tác động tới tài nguyên trên host. Dockerfile dùng
> `USER appuser` (UID 10001), nên mã bị chiếm quyền trước tiên chỉ chạy với
> quyền của user thường. Đây là một lớp giảm thiệt hại, không bảo đảm chặn mọi
> đường thoát container.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Tối đa 20 request: gửi 10 request ở giây 59 của phút trước, rồi gửi tiếp 10
> request ở giây 00 của phút sau. Bộ đếm theo phút vừa reset nên cho qua cả
> hai nhóm trong khoảng hai giây. Sliding window tính 60 giây gần nhất nên khi
> nhóm thứ hai đến, 10 request đầu vẫn còn trong cửa sổ và sẽ bị trả 429.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> Rate limiter đếm số request trong 60 giây; cost guard theo dõi tổng USD của
> từng user trong tháng. Nếu user mới gọi một request trong phút này nhưng đã
> hết ngân sách tháng, rate limiter cho qua còn cost guard trả 402. Ngược lại,
> user còn nhiều ngân sách nhưng đã gửi đủ 10 request trong 60 giây sẽ nhận 429. Bằng chứng deploy trong `DEPLOYMENT.md` ghi 10 lần 200 rồi 5 lần 429
> khi thử 15 request liên tiếp.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Khi Redis mất kết nối, cả ba instance vẫn chạy nhưng endpoint gộp trả lỗi.
> Nếu orchestrator dùng endpoint đó làm liveness probe, nó đánh dấu cả ba
> container không khỏe rồi khởi động lại chúng. Redis vẫn chưa trở lại nên
> container mới tiếp tục lỗi, gây thêm gián đoạn và mất khả năng phục vụ ngay
> cả các đường không cần Redis. Với code hiện tại, `/health` chỉ kiểm tra
> process và trạng thái shutdown, còn `/ready` kiểm tra `store.ping()` để tạm
> ngừng đưa request vào instance chưa sẵn sàng.

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Tôi chạy 3 replica của `agent` và Docker cấp ba host port khác nhau:
> agent-1 ở 62846, agent-2 ở 62844 và agent-3 ở 62845. Tôi gọi trực tiếp từng
> replica với cùng `X-User-Id: exercise-scale-test`. Kết quả `history_length`
> lần lượt là 0, 2 và 4.
>
> Điều này cho thấy các replica dùng chung conversation history trong Redis:
> request thứ hai vào agent-2 vẫn đọc được hai message do request trước ở
> agent-1 tạo ra, và request thứ ba vào agent-3 đọc được bốn message trước đó.
> Mỗi lượt `/ask` thêm hai message nên `history_length` tăng 2.
>
> Nếu thay Redis bằng một dict Python trong từng process thì mỗi replica có
> vùng nhớ riêng. Khi lần lượt gọi ba replica khác nhau, mỗi replica chưa từng
> thấy user đó nên `history_length` có thể đều bắt đầu từ 0. Khi container
> restart, dữ liệu trong dict cũng bị mất.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Khi thiết lập GitHub Actions để tự động deploy lên Railway, bước
> `railway up --service day12-agent --detach` bị thất bại với thông báo
> `Invalid RAILWAY_TOKEN. Please check that it is valid and has access to
the resource you're trying to use.`
>
> Tôi kiểm tra secret `RAILWAY_TOKEN` trên GitHub và loại token đã tạo trên
> Railway. Token ban đầu là API Token có scope Account, không phải token phù
> hợp với project/environment mà workflow đang deploy.
>
> Tôi tạo Project Token cho đúng Railway project và environment, sau đó cập
> nhật repository secret `RAILWAY_TOKEN` trong GitHub Actions. Tôi không đưa
> token trực tiếp vào file workflow. Sau khi chạy lại failed jobs, bước deploy
> thành công và workflow CI/CD chuyển sang trạng thái xanh.
