# Metric chung — khung so sánh

Mọi module xuất kết quả theo schema dưới đây. Nam, Khương, Long, Huy tự ghi CSV phần mình (mỗi người một file riêng); Cương dùng các CSV đó cho Phần V (Câu 4) và không sửa chúng.

## 1. Định nghĩa chung

- Phép nhân ma trận vuông `C = A × B`, kích thước `N×N`.
- Số phép tính số học (FMA đếm 2 ops):  
  `FLOPs = 2 × N³`
- Mỗi điểm đo lặp **≥ 5 lần**, báo cáo **trung vị** (và min/max nếu lệch lớn).
- Ghi môi trường: CPU model, số lõi, RAM; GPU model (Colab); phiên bản compiler/CUDA; OS.

## 2. CPU (`float32`)

| Cột CSV | Ý nghĩa |
|---|---|
| `platform` | `cpu` |
| `impl` | `naive` / `tiled` / `openmp` / `simd` / `blas` |
| `N` | kích thước ma trận |
| `time_ms` | thời gian tường (median) |
| `gflops` | `FLOPs / (time_s × 1e9)` |
| `threads` | số luồng OpenMP (nếu có) |
| `tile` | kích thước tile (nếu có) |
| `correct` | `1` nếu khớp naive (sai số tuyệt đối max ≤ 1e-3 tương đối hợp lý) |

**Ablation Câu 1:** cùng `N`, thêm từng kỹ thuật, tính `speedup = time_naive / time_impl`.

## 3. GPU (`float32`, CUDA)

| Cột CSV | Ý nghĩa |
|---|---|
| `platform` | `gpu` |
| `impl` | `cuda_naive` / `cublas` |
| `N` | kích thước |
| `kernel_ms` | chỉ kernel (CUDA event) |
| `h2d_ms` | Host→Device |
| `d2h_ms` | Device→Host |
| `e2e_ms` | `h2d + kernel + d2h` |
| `gflops_kernel` | theo `kernel_ms` |
| `gflops_e2e` | theo `e2e_ms` |
| `gpu_name` | ví dụ `Tesla T4` |
| `correct` | `1/0` |

**Câu 2:** vẽ hai đường `e2e_ms(N)` GPU vs `time_ms(N)` CPU tốt nhất; tìm `N*` nhỏ nhất mà GPU E2E thắng CPU. Báo thêm `N*_kernel` (chỉ kernel).

## 4. Systolic (RTL, int16, 8×8 weight-stationary)

| Cột / đại lượng | Ý nghĩa |
|---|---|
| `platform` | `systolic` |
| `array_r`, `array_c` | `8`, `8` |
| `N` | kích thước logic (hoặc kích thước tile đang mô phỏng) |
| `cycles` | số chu kỳ clock từ mô phỏng / công thức |
| `pe_count` | `64` |
| `macs_per_cycle_peak` | `64` (mỗi PE 1 MAC/cycle khi đầy) |
| `utilization` | MAC hữu ích / (PE × cycles) |
| `correct` | khớp kết quả tham chiếu int16 |

**Không** chuyển `cycles` sang ms để “đua” với CPU/GPU trừ khi giả định tần số `f` rõ ràng và chỉ dùng cho thảo luận lý thuyết.

**Công thức chu kỳ (weight-stationary, tile R×C = 8×8):**  
Với một tile: điền trọng số + stream đầu vào + drain kết quả — ghi rõ trong báo cáo sau khi chốt interface RTL.  
Với ma trận lớn: số tile × chu kỳ/tile (+ overhead), đối chiếu vài điểm mô phỏng.

Throughput lý thuyết: `2 × #PE × f` ops/s (nếu giả định `f`).

## 5. File kết quả chuẩn

Mỗi module ghi vào `results/`:

```
results/cpu_bench.csv        (Nam: naive, tiled)
results/cpu_opt_bench.csv    (Khương: openmp, simd; cùng cột với cpu_bench.csv)
results/gpu_bench.csv        (Long)
results/systolic_cycles.csv  (Huy)
results/env_<ten>.json       (mỗi người một file: env_nam.json, env_khuong.json, ...)
```

Mỗi người đo xong thì chép `results/env.template.json` thành `results/env_<ten>.json` và điền thông tin máy mình (CPU, số lõi, RAM, compiler; Long thêm GPU và CUDA; Huy thêm phiên bản Icarus). Không dùng chung một file env để tránh xung đột git.

Mỗi file CSV đã có sẵn dòng tiêu đề. Chương trình đo chỉ **thêm dòng** vào cuối, không xóa tiêu đề.

## 6. So sánh chéo (Câu 4) — bảng đánh đổi

Không gộp một cột ms cho cả ba. Dùng:

| Tiêu chí | CPU | GPU | Systolic |
|---|---|---|---|
| Thông lượng (GFLOPS hoặc MAC/cycle) | đo | đo | mô hình + sim |
| Độ linh hoạt | cao | trung bình | thấp |
| Chi phí chuyển dữ liệu | thấp (cache) | H2D/D2H | stream theo dataflow |
| Độ phức tạp thiết kế/lập trình | thấp–TB | TB | cao (RTL) |
| Phù hợp kích thước bài toán | nhỏ–vừa | lớn | cố định tile, lặp lại |

## 7. Kiểm tra đúng đắn

- CPU/GPU float32: so với naive hoặc BLAS, sai số tương đối phần tử max ≤ `1e-3` (hoặc theo chuẩn nhóm ghi trong báo cáo).
- Systolic int16: so bit-exact với model tham chiếu C/Python cùng quy tắc làm tròn/saturate.
