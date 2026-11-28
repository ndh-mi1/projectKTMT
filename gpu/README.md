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

---

## 6. Đóng góp vào Báo cáo cuối kỳ (APA/IEEE) & Thuyết trình
- **Báo cáo cuối kỳ (chuẩn APA & trích dẫn đánh số IEEE `[1]`):**
  - **Chương 2 (Phương pháp luận):** Mô tả kiến trúc SIMT GPU, thiết kế kernel `cuda_naive`, cách tích hợp `cuBLAS` và công cụ đo `cudaEvent_t` trên Google Colab; giải thích lý do chỉ khảo sát 2 mức (`naive` vs `cuBLAS`).
  - **Chương 3 (Kết quả & Bàn luận):** Phân tích bảng $T_{\text{kernel}}$ vs $T_{\text{E2E}}$, đồ thị hòa vốn $N^*$ và trả lời dứt khoát Câu hỏi 2; trích dẫn tài liệu NVIDIA CUDA theo chuẩn IEEE `[1]`.
- **Thuyết trình (Lượt 3):** Trình bày giải pháp GPU, phân tích nút thắt PCIe và **demo/minh họa Notebook Colab** (`gpu/notebooks/`).
- **Mốc hoàn thành:** Push mã nguồn `.cu`, notebook `.ipynb`, `results/gpu_bench.csv` và `results/env_long.json` lên GitHub đúng lộ trình Tuần 14 (kịp hạn nộp Teams trước `24/12/2026`).

---

## 7. Cấu trúc mã nguồn & Hướng dẫn chạy nhanh (Đã triển khai)

| Thành phần | Đường dẫn | Mô tả |
|---|---|---|
| **CUDA Benchmark & Kernel** | `src/matmul_cuda.cu` | Cài đặt `matmul_naive_kernel` và `cublasSgemm`, đo tách bạch `h2d_ms`, `kernel_ms`, `d2h_ms`, `e2e_ms` bằng `cudaEvent_t`, kiểm chứng sai số $\le 10^{-3}$. |
| **Tiện ích Host (C++14)** | `src/gpu_bench_utils.hpp` | Parse CLI, sinh ma trận `seed=42`, tính trung vị & GFLOPS, kiểm tra chéo CPU/GPU, xuất nối dòng vào CSV chuẩn `METRICS.md`. |
| **Build script** | `Makefile` | Hỗ trợ `make`, `make test`, `make bench`, `make clean` (trên Linux/Google Colab). |
| **Colab Notebook** | `notebooks/colab_matmul.ipynb` | Notebook chạy từ đầu tới cuối trên Google Colab (T4/L4/A100): kiểm tra môi trường, tạo `results/env_long.json`, biên dịch `nvcc`, sweep $N \in [64, 4096]$, xuất `results/gpu_bench.csv`, phân tích điểm hòa vốn $N^*$ và vẽ 3 biểu đồ minh họa. |
| **Tài liệu báo cáo & Slide** | `docs/BAO_CAO_PHAN_GPU.md`<br>`docs/SLIDE_VA_DEMO_GPU.md` | Bản nháp Mục 2.3 & Mục 3.2 chuẩn APA/IEEE bám sát Patterson & Hennessy (5th Ed.) cùng kịch bản Slide Canva & Demo Lượt 3. |

### Lưu ý kỹ thuật Row-major vs Column-major trong `cuBLAS`
Ma trận `float32` trong dự án được lưu theo hàng (**row-major**), trong khi `cublasSgemm` mặc định đọc dữ liệu theo cột (**column-major**). Khi đọc một ma trận row-major $X$ dưới góc nhìn column-major, bộ nhớ đó chính là $X^T$. Áp dụng đồng nhất thức:
$$C^T = (A \times B)^T = B^T \times A^T$$
chương trình truyền `(d_B, d_A)` vào `cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, N, N, N, &alpha, d_B, N, d_A, N, &beta, d_C, N)` để thu được trực tiếp $C = A \times B$ theo chuẩn row-major mà không cần tốn chi phí chuyển vị bộ nhớ phụ.

### Sử dụng CLI và Quy trình chạy trên Google Colab
```bash
# Biên dịch trong thư mục gpu/
make

# Chạy thử nhanh (demo / sanity test)
./bin/bench_gpu --impl all --N 256 --repeats 5 --warmup 1 --out /tmp/gpu_test.csv

# Chạy toàn bộ dải N = 64..4096 và ghi vào ../results/gpu_bench.csv
./bin/bench_gpu --sweep --impl all --repeats 7 --warmup 2 --out ../results/gpu_bench.csv
```
Trên Google Colab, mở trực tiếp `gpu/notebooks/colab_matmul.ipynb`, chọn **Runtime -> Change runtime type -> T4 GPU**, chạy tuần tự các cell, sau đó tải `results/gpu_bench.csv` và `results/env_long.json` về máy để commit với tiền tố `[Long]`.
