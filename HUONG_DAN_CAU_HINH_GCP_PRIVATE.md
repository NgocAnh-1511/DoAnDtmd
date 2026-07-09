# HƯỚNG DẪN THIẾT LẬP MẠNG NỘI BỘ (PRIVATE VPC) & BẢO MẬT TRÊN GCP

Tài liệu này hướng dẫn chi tiết từng bước thiết lập trên Google Cloud Platform Console để đồng bộ với cấu hình CI/CD mới của dự án.

---

## PHẦN 1: TẠO MẠNG NỘI BỘ (VPC NETWORK) & PEERING

1. **Truy cập:** Menu GCP -> **VPC network** -> **VPC networks**.
2. **Bấm "Create VPC Network":**
   * **Name:** `ev-sharing-vpc`
   * **Subnet creation mode:** Chọn `Custom`
   * **Subnet Name:** `ev-sharing-subnet`
   * **Region:** `asia-southeast1` (Singapore)
   * **IP address range:** `10.0.0.0/24`
   * Giữ nguyên các thông số khác -> Bấm **Create**.
3. **Cấu hình Kết nối dịch vụ Private (Private Service Connection):**
   * Trong VPC `ev-sharing-vpc`, chọn tab **Private service connection**.
   * Bấm **Allocate IP Range** (Cấp phát dải IP):
     * **Name:** `ev-sql-private-ip-range`
     * **Prefix length:** `/16` (hoặc chọn Custom và nhập `10.10.0.0/16`)
     * Bấm **Allocate**.
   * Bấm **Private connections to services** -> **Create Connection**:
     * **Assigned allocation:** Chọn `ev-sql-private-ip-range`
     * Bấm **Connect**. (Thao tác này tạo liên kết Peering giữa VPC của bạn và VPC của Google Cloud SQL).

---

## PHẦN 2: CHUYỂN DATABASE CLOUD SQL SANG PRIVATE IP

1. **Truy cập:** Menu GCP -> **SQL** -> Chọn instance của bạn: `ev-database`.
2. **Cấu hình kết nối (Connections):**
   * Bấm chọn **Connections** ở thanh bên trái -> tab **Networking**.
   * **Bật (Check):** **Private IP**.
     * **Network:** Chọn `ev-sharing-vpc`.
     * **Allocated IP range:** Chọn `ev-sql-private-ip-range`.
   * **Tắt (Uncheck):** **Public IP** (Ngắt hoàn toàn internet).
   * Bấm **Save** ở cuối trang.
3. **Lấy IP Private:**
   * Sau khi hoàn tất (mất 2-3 phút), quay lại màn hình **Overview** của `ev-database`.
   * Tìm mục **Private IP Address** (Ví dụ: `10.10.0.3`). Hãy copy địa chỉ IP này lại để dùng cho cấu hình GitHub.

---

## PHẦN 3: TẠO SERVERLESS VPC ACCESS CONNECTOR

1. **Truy cập:** Menu GCP -> **VPC network** -> **Serverless VPC access**.
2. **Bấm "Create Connector":**
   * **Name:** `ev-vpc-connector`
   * **Region:** `asia-southeast1`
   * **Network:** `ev-sharing-vpc`
   * **Subnet:** Chọn `Custom IP range`
   * **IP range:** Điền `10.8.0.0/28` (Dải IP này bắt buộc phải là `/28` và không trùng với dải IP của subnet khác).
   * **Scaling:** Minimum instances: `2`, Maximum instances: `10`, Machine type: `f1-micro`.
3. Bấm **Create** và đợi hệ thống tạo xong (khoảng 3 phút).

---

## PHẦN 4: THIẾT LẬP GOOGLE SECRET MANAGER

1. **Truy cập:** Menu GCP -> **Security** -> **Secret Manager**.
2. **Bấm "Create Secret":**
   * **Name:** `ev-db-password`
   * **Secret value:** Nhập mật khẩu database của bạn (`AnhNguyen1511@`).
   * Bấm **Create**.
3. **Cấp quyền truy cập cho Cloud Run:**
   * Lấy ID của Service Account mặc định chạy Cloud Run (thường là `[PROJECT_NUMBER]-compute@developer.gserviceaccount.com`). Bạn có thể tìm thấy trong trang **IAM**.
   * Quay lại trang Secret Manager -> Chọn secret `ev-db-password` -> chọn tab **Permissions** -> Bấm **Grant Access**:
     * **New principals:** Nhập địa chỉ email Service Account trên.
     * **Role:** Chọn **Secret Manager Secret Accessor**.
     * Bấm **Save**.

---

## PHẦN 5: TẠO KHO LƯU TRỮ GOOGLE ARTIFACT REGISTRY

1. **Truy cập:** Menu GCP -> **Artifact Registry** -> **Repositories**.
2. **Bấm "Create Repository":**
   * **Name:** `ev-sharing-repo`
   * **Format:** `Docker`
   * **Location type:** Chọn Region -> `asia-southeast1` (Singapore)
   * Bấm **Create**.

---

## PHẦN 6: TẠO SERVICE ACCOUNT CHO GITHUB ACTIONS CI/CD

1. **Truy cập:** Menu GCP -> **IAM & Admin** -> **Service Accounts**.
2. **Bấm "Create Service Account":**
   * **Service account name:** `github-cicd-sa`
   * Bấm **Create and Continue**.
3. **Gán vai trò (Roles) cho Service Account:**
   * Lần lượt gán 4 vai trò sau:
     1. **Artifact Registry Writer** (Để đẩy ảnh Docker)
     2. **Cloud Run Developer** (Để deploy Cloud Run)
     3. **Service Account User** (Để deploy dưới danh nghĩa SA chạy dịch vụ)
     4. **Secret Manager Secret Accessor** (Để liên kết secret từ GitHub)
   * Bấm **Continue** -> **Done**.
4. **Tạo JSON Key:**
   * Chọn Service Account `github-cicd-sa` vừa tạo -> Chọn tab **Keys** -> Bấm **Add Key** -> **Create new key**.
   * Chọn định dạng **JSON** -> Bấm **Create**.
   * File JSON chứa khóa bí mật sẽ tự động tải về máy bạn. Hãy mở nó ra và copy toàn bộ nội dung.

---

## PHẦN 7: CẤU HÌNH TRÊN GITHUB REPOSITORY

Mở repository mới của bạn trên GitHub (`NgocAnh-1511/DoAnDtmd`), vào mục **Settings** -> **Secrets and variables** -> **Actions** -> Bấm **New repository secret**:

1. **Secret 1:**
   * **Name:** `GCP_PROJECT_ID`
   * **Value:** `ev-cost-sharing-496416`
2. **Secret 2:**
   * **Name:** `GCP_SA_KEY`
   * **Value:** Dán toàn bộ nội dung file JSON Key vừa tải về ở Phần 6.
3. **Secret 3:**
   * **Name:** `GCP_DB_PRIVATE_IP`
   * **Value:** Dán địa chỉ IP Private của database lấy ở cuối Phần 2 (Ví dụ: `10.10.0.3`).

Sau khi cấu hình xong, mỗi lần bạn push code lên nhánh `main`, GitHub Actions sẽ tự động kích hoạt, phát hiện thay đổi và triển khai lên hệ thống mạng nội bộ bảo mật của bạn!
