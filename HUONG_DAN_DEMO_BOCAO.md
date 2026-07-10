# KỊCH BẢN THUYẾT TRÌNH VÀ DEMO ĐỒ ÁN CUỐI KỲ (ĐIỆN TOÁN ĐÁM MÂY)

Tài liệu này hướng dẫn chi tiết các bước thực hiện Demo trước hội đồng/giảng viên để chứng minh 3 tính năng cốt lõi: **CI/CD tự động**, **Bảo mật mạng nội bộ** và **Tự động co giãn (Auto-scaling) bằng k6**.

---

## 🚀 DEMO PHẦN 1: TÍNH NĂNG CI/CD (TỰ ĐỘNG HÓA TRIỂN KHAI)

### Mục tiêu:
Chứng minh khi có thay đổi mã nguồn, hệ thống tự động nhận diện, chỉ build những phần thay đổi và deploy lên Google Cloud mà không cần can thiệp thủ công.

### Các bước thực hiện:
1. **Chuẩn bị thay đổi nhỏ:**
   * Mở file [index.html](file:///D:/NguyenNgocAnh/KCPM/EV-Co-ownership-Cost-sharing-System-anh/ui-service/src/main/resources/templates/index.html) hoặc bất kỳ file giao diện nào của `ui-service`.
   * Sửa một dòng tiêu đề hoặc đoạn text nhỏ (Ví dụ: Thêm chữ *" - Phiên bản cuối kỳ Cloud"*).
2. **Commit và Push:**
   * Chạy lệnh git để push lên nhánh `main`:
     ```bash
     git add .
     git commit -m "demo: update UI header for final exam presentation"
     git push origin main
     ```
3. **Thuyết trình trực quan:**
   * Mở trình duyệt tại mục **Actions** trên GitHub Repo của bạn ([https://github.com/NgocAnh-1511/DoAnDtmd/actions](https://github.com/NgocAnh-1511/DoAnDtmd/actions)).
   * Chỉ cho thầy thấy: **GitHub Actions đã tự động bắt được sự kiện push và đang chạy Pipeline**.
   * Chỉ vào log phần **Detect Changes**: Chỉ cho thầy thấy hệ thống chỉ kích hoạt build duy nhất `ui-service` và bỏ qua (skip) các service khác nhờ cấu hình thông minh.
4. **Kết quả:**
   * Sau khi pipeline chạy xong (hiện màu xanh lá), F5 lại trang web `ui-service` trên Cloud Run để thầy thấy sự thay đổi đã xuất hiện ngay lập tức.

---

## 🔒 DEMO PHẦN 2: TÍNH BẢO MẬT HẠ TẦNG (CLUOD SECURITY)

### Mục tiêu:
Chứng minh dữ liệu được bảo vệ an toàn trong mạng nội bộ VPC, mật khẩu được mã hóa và quy trình CI/CD hoàn toàn bảo mật không dùng khóa cứng.

### Các bước thực hiện:
1. **Chứng minh Database bị cô lập (Private IP):**
   * Mở phần mềm kết nối database (MySQL Workbench, DBeaver, Navicat...).
   * Tạo kết nối thử vào IP Private của database (`10.252.0.3`) bằng cổng `3306`.
   * Kết nối sẽ xoay vòng và báo lỗi **Connection Timeout**.
   * *Giải thích với thầy:* Database đã được chuyển hoàn toàn về mạng VPC nội bộ, ngăn chặn 100% các cuộc tấn công quét cổng/hack từ internet.
2. **Chứng minh Quản lý Mật khẩu tập trung (Secret Manager):**
   * Mở **GCP Console** -> Truy cập **Cloud Run** -> Chọn `user-account-service` -> Tab **Variables & Secrets**.
   * Chỉ cho thầy thấy biến môi trường `SPRING_DATASOURCE_PASSWORD` đang trỏ tới Secret: `ev-db-password` (không hiển thị mật khẩu bằng chữ rõ).
   * Mở tiếp trang **Secret Manager** trên GCP Console để thầy thấy mật khẩu của bạn được Google mã hóa và quản lý tập trung.
3. **Chứng minh Xác thực không dùng khóa (Workload Identity Federation):**
   * Mở file cấu hình CI/CD trên GitHub hoặc VS Code.
   * Chỉ cho thầy thấy bước Authenticate hoàn toàn không sử dụng các file khóa JSON chứa private key nhạy cảm (GCP SA Key). Việc xác thực diễn ra thông qua giao thức OIDC tin cậy trực tiếp giữa GitHub và GCP.

---

## 📊 DEMO PHẦN 3: TỰ ĐỘNG CO GIÃN (AUTO-SCALING) BẰNG K6

### Mục tiêu:
Chứng minh khả năng tự động tăng/giảm số lượng instance của Cloud Run khi có tải đột biến (Scale up và Scale to Zero) sử dụng công cụ k6.

### Chuẩn bị file test `load_test.js`:
Tôi đã tạo sẵn file cấu hình tải [load_test.js](file:///D:/NguyenNgocAnh/KCPM/EV-Co-ownership-Cost-sharing-System-anh/load_test.js) trong thư mục gốc của bạn. File này sẽ giả lập tải tăng dần từ 0 lên 150 người dùng truy cập đồng thời trong vòng 2 phút.

### Các bước thực hiện:
1. **Cài đặt k6 trên máy của bạn (nếu chưa có):**
   * Cài đặt qua PowerShell (Run as Administrator):
     ```powershell
     winget install k6
     ```
2. **Chuẩn bị màn hình Thuyết trình:**
   * Mở **GCP Console** -> **Cloud Run** -> Chọn dịch vụ `ui-service` -> Chọn tab **Metrics**.
   * Kéo xuống biểu đồ **Active Instances** (Số lượng instance đang hoạt động). Ban đầu biểu đồ này sẽ hiển thị **0** hoặc **1** instance.
3. **Chạy Test bằng k6:**
   * Mở terminal trên máy, di chuyển đến thư mục dự án và chạy:
     ```bash
     k6 run load_test.js
     ```
4. **Thuyết trình trực quan:**
   * Khi k6 đang chạy và gửi hàng nghìn request, hãy chỉ cho thầy thấy biểu đồ **Active Instances** trên GCP Console bắt đầu **đi lên** (tăng từ 1 -> 2 -> 3 -> 4 instances) để xử lý lượng tải lớn. Điều này chứng minh **Auto-scaling (Scale Up)** hoạt động thành công.
   * Sau khi k6 chạy xong, lượng tải về 0. Đợi khoảng 2-3 phút, chỉ cho thầy thấy biểu đồ **Active Instances** tự động **giảm dần về 0**. Điều này chứng minh tính năng **Scale to Zero** của Serverless hoạt động hoàn hảo giúp tiết kiệm chi phí!
