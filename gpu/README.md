# Hướng dẫn Module GPU (CUDA) — Nhóm 15 (MI4344)

> **Mục tiêu:** Đo đạc và đánh giá hiệu năng nhân ma trận $C = A \times B$ (`float32`) trên GPU qua hai cách tiếp cận: Kernel CUDA tự viết (`cuda_naive`) và Thư viện tối ưu cao (`cuBLAS`). Phân tích sự chênh lệch giữa thời gian tính toán thuần (`kernel_ms`) và thời gian toàn trình (`e2e_ms` bao gồm copy dữ liệu qua PCIe) để xác định điểm hòa vốn $N^*$ so với CPU.  
> **Người phụ trách:** **Nguyễn Hoàng Long (P3)**.  
> **File kết quả:** `../results/gpu_bench.csv`.

---

## 1. Yêu cầu tự xây dựng mã nguồn

Long cần tự phát triển mã nguồn trong thư mục `gpu/` gồm:
1. **Mã nguồn CUDA C/C++ (`src/`):**
   - Viết kernel naive: mỗi thread tính toán 1 phần tử của ma trận kết quả $C$ bằng tích vô hướng giữa hàng của $A$ và cột của $B$.
   - Cài đặt luồng gọi thư viện `cublasSgemm` từ NVIDIA cuBLAS SDK.
   - Quản lý bộ nhớ: `cudaMalloc`, `cudaMemcpy` (HostToDevice và DeviceToHost), `cudaFree`.
2. **Notebook chạy trên Google Colab (`notebooks/colab_matmul.ipynb`):**
   - Môi trường thực thi chính là Google Colab (GPU miễn phí như Tesla T4 hoặc A100).
   - Notebook có chức năng sweep tự động qua các giá trị $N$, tính toán median và xuất dữ liệu ra file `gpu_bench.csv`.

---

## 2. Quy chuẩn đo thời gian & Công thức tính toán

### 2.1. Đo thời gian bằng CUDA Events
Bắt buộc dùng `cudaEvent_t` để đo thời gian chính xác trên GPU (không dùng `clock()` của CPU):
- $T_{\text{H2D}}$: Thời gian chép 2 ma trận $A, B$ từ RAM máy chủ sang VRAM của GPU (`cudaMemcpyHostToDevice`).
- $T_{\text{kernel}}$: Thời gian thực thi kernel trên GPU (hoặc thời gian gọi `cublasSgemm`).
- $T_{\text{D2H}}$: Thời gian chép ma trận kết quả $C$ từ VRAM về RAM (`cudaMemcpyDeviceToHost`).
- $T_{\text{E2E}} = T_{\text{H2D}} + T_{\text{kernel}} + T_{\text{D2H}}$: Thời gian toàn trình (End-to-End).

```cpp
cudaEvent_t start, stop;
cudaEventCreate(&start);
cudaEventCreate(&stop);

// Đo kernel
cudaEventRecord(start);
matmul_kernel<<<grid, block>>>(d_A, d_B, d_C, N);
cudaEventRecord(stop);
cudaEventSynchronize(stop);
float kernel_ms = 0;
cudaEventElapsedTime(&kernel_ms, start, stop);
```

### 2.2. Kiểm tra tính đúng đắn & Tính toán Metric
- **Kiểm tra đúng:** So sánh kết quả của kernel với CPU hoặc cuBLAS với ngưỡng sai số tuyệt đối $\le 10^{-3} \implies \text{correct} = 1$.
- **Tính toán hiệu năng:**
  $$\text{GFLOPS}_{\text{kernel}} = \frac{2 \times N^3}{T_{\text{kernel\_s}} \times 10^9}$$
  $$\text{GFLOPS}_{\text{e2e}} = \frac{2 \times N^3}{T_{\text{e2e\_s}} \times 10^9}$$

---

## 3. Quy trình thực nghiệm & Xuất kết quả

1. **Dải kích thước $N$:** `64, 128, 256, 512, 1024, 2048, 4096`.
2. **Quy tắc lặp:** Warmup 1–2 lần trước khi đo; mỗi điểm $N$ chạy lặp tối thiểu 5 lần để lấy giá trị **trung vị** (median).
3. **Định dạng ghi CSV:** Ghi nối các dòng vào `results/gpu_bench.csv` theo đúng header:
   ```csv
   platform,impl,N,kernel_ms,h2d_ms,d2h_ms,e2e_ms,gflops_kernel,gflops_e2e,gpu_name,correct
   ```
4. **Lưu ý Colab:** Phiên làm việc trên Colab có thể bị ngắt kết nối bất ngờ. Long hãy **tải file `gpu_bench.csv` về máy và commit lên GitHub ngay sau khi chạy xong**.

---

## 4. Xác định điểm hòa vốn $N^*$ (Trả lời Câu hỏi 2)
Sau khi có số liệu của CPU (từ Nam và Khương), Long vẽ đường so sánh:
- Tìm $N^*_{\text{kernel}}$: Kích thước $N$ nhỏ nhất mà GPU tính toán thuần nhanh hơn CPU.
- Tìm $N^*_{\text{E2E}}$: Kích thước $N$ nhỏ nhất mà GPU thắng CPU khi tính cả thời gian copy dữ liệu qua PCIe.
- Giải thích nguyên nhân overhead copy dữ liệu ở ma trận nhỏ khiến GPU chậm hơn CPU.

## 5. File cấu hình môi trường
Chép file `results/env.template.json` thành `results/env_long.json`, ghi rõ model GPU (ví dụ: `Tesla T4 16GB`), phiên bản CUDA, Driver và compiler.
