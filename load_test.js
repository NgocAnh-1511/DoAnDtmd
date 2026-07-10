import http from 'k6/http';
import { sleep } from 'k6';

// ---------------------------------------------------------------------------------
// k6 Load Test Configuration for Auto-scaling Demo
// ---------------------------------------------------------------------------------
// Giả lập tải tăng dần từ 0 lên 150 người dùng đồng thời (VUs) trong vòng 30 giây,
// duy trì trong 1 phút, sau đó giảm về 0 trong 30 giây.
// ---------------------------------------------------------------------------------
export const options = {
  stages: [
    { duration: '30s', target: 150 }, // Tải tăng dần lên 150 users
    { duration: '1m', target: 150 },  // Duy trì tải 150 users
    { duration: '30s', target: 0 },   // Giảm tải về 0
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],   // Tỉ lệ lỗi HTTP < 1%
  },
};

export default function () {
  // Thay thế URL dưới đây bằng URL thật của ui-service hoặc api-gateway-cloud của bạn
  const url = 'https://ui-service-856180445698.asia-southeast1.run.app';
  
  // Gửi request GET tới trang chủ
  http.get(url);
  
  // Nghỉ 100ms giữa các request để tăng lượng request đồng thời
  sleep(0.1);
}
