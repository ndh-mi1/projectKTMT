# Hướng dẫn Module CPU — Nhóm 15 (MI4344)

> **Mục tiêu:** Đánh giá hiệu năng nhân ma trận $C = A \times B$ (`float32`) trên CPU qua các mức độ tối ưu phần cứng tăng dần: Naive $\to$ Cache Tiling $\to$ Đa lõi (OpenMP) $\to$ Vector hóa (SIMD).  
> **Người phụ trách:** **Trịnh Nhật Nam (P1)** và **Lê Duy Khương (P2)**.

---

## 1. Phân chia nhiệm vụ

| Thành viên | File cần tự xây dựng | Trách nhiệm chính | File kết quả CSV |
|---|---|---|---|
| **Nam (P1)** | `include/matmul.h`<br>`src/matmul_naive.c`<br>`src/matmul_tiled.c`<br>`src/bench_main.c`<br>`Makefile` | Xây dựng khung interface chung, cài đặt bản Naive & Cache Tiling, viết harness đo thời gian chính xác (CLI, median $\ge 5$ lần, check sai số $\le 10^{-3}$, ghi nối CSV). | `../results/cpu_bench.csv` |
| **Khương (P2)** | `src/matmul_openmp.c`<br>`src/matmul_simd.c` | Tối ưu đa lõi (OpenMP) và tối ưu truy cập bộ nhớ / vector hóa (đổi thứ tự vòng lặp sang $i-k-j$, `#pragma omp simd` hoặc AVX2), thực hiện Ablation Study. | `../results/cpu_opt_bench.csv` |

---

## 2. Đặc tả kỹ thuật & Hướng dẫn cài đặt

### 2.1. Interface chung (`include/matmul.h`)
Nam tạo file `include/matmul.h` chứa khai báo nguyên mẫu hàm cho cả nhóm:
```c
#ifndef MATMUL_H
#define MATMUL_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Ma trận float32, lưu trữ theo hàng (row-major), kích thước N x N
void matmul_naive(const float *A, const float *B, float *C, size_t N);
void matmul_tiled(const float *A, const float *B, float *C, size_t N, size_t tile);
void matmul_openmp(const float *A, const float *B, float *C, size_t N, size_t tile);
void matmul_simd(const float *A, const float *B, float *C, size_t N, size_t tile);

#ifdef __cplusplus
}
#endif

#endif
```

### 2.2. Chi tiết yêu cầu từng hàm

1. **`matmul_naive.c` (Nam):**
   - 3 vòng lặp lồng nhau cổ điển ($i, j, k$).
   - Dùng làm mốc đối chứng (baseline) và hàm kiểm tra tính đúng đắn cho mọi cài đặt khác.
2. **`matmul_tiled.c` (Nam):**
   - Áp dụng kỹ thuật Cache Blocking (Tiling) với 6 vòng lặp ($ii, jj, kk, i, j, k$).
   - Kích thước khối `tile` truyền từ tham số dòng lệnh (gợi ý: 16, 32, 64) để khớp với dung lượng L1/L2 cache.
3. **`matmul_openmp.c` (Khương):**
   - Sử dụng thư viện OpenMP `#pragma omp parallel for schedule(static)` song song hóa theo các hàng ngoài cùng.
   - Thử nghiệm trên các số lượng luồng khác nhau ($1, 2, 4, 8, \dots$).
4. **`matmul_simd.c` (Khương):**
   - Đổi thứ tự vòng lặp sang $i-k-j$ để vòng trong $j$ quét liên tục trên bộ nhớ (stride-1 access cho ma trận $B$ và $C$).
   - Kết hợp chỉ thị `#pragma omp simd` hoặc intrinsic AVX2 (`_mm256_*`) để ép compiler sinh lệnh vector FMA.
5. **`bench_main.c` (Nam):**
   - Tiếp nhận tham số: `--impl <naive|tiled|openmp|simd>`, `--N <size>`, `--tile <size>`, `--repeats <so-lan>`, `--out <duong-dan-csv>`.
   - Sinh ma trận ngẫu nhiên với seed cố định `42` (`srand(42)`).
   - Đo thời gian thực (wall-clock time): dùng `QueryPerformanceCounter` (Windows) hoặc `clock_gettime(CLOCK_MONOTONIC)` (Linux).
   - Chạy lặp tối thiểu 5 lần (`--repeats 5`), tính toán thời gian **trung vị** (median).
   - Kiểm tra sai số tuyệt đối so với `matmul_naive`: $\max |C_{\text{impl}} - C_{\text{naive}}| / (|C_{\text{naive}}| + 1) \le 10^{-3} \implies \text{correct} = 1$.
   - Tính toán $\text{GFLOPS} = \frac{2 \times N^3}{\text{time\_s} \times 10^9}$.
   - Ghi nối (append) vào file CSV chỉ định theo đúng schema trong `METRICS.md`.

---

## 3. Hướng dẫn biên dịch và kiểm thử

### 3.1. Biên dịch trên Windows (gcc MSYS2 / MinGW)
```powershell
cd cpu
mkdir bin -Force
gcc -O3 -std=c11 -Wall -Wextra -Iinclude -fopenmp -o bin/bench_cpu.exe src/*.c -lm
```

### 3.2. Biên dịch bằng Makefile (Linux / MSYS2)
Nam viết `Makefile` hỗ trợ các mục tiêu:
```bash
make            # Biên dịch ra bin/bench_cpu
make bench      # Nam: Chạy quét naive + tiled -> results/cpu_bench.csv
make bench-opt  # Khương: Chạy quét openmp + simd -> results/cpu_opt_bench.csv
```

### 3.3. Dải thí nghiệm yêu cầu
- Dải kích thước ma trận $N$: `64, 128, 256, 512, 1024, 2048`.
- Lệnh chạy mẫu:
  ```powershell
  # Nam đo tiled N=1024
  ./bin/bench_cpu.exe --impl tiled --N 1024 --tile 32 --out ../results/cpu_bench.csv

  # Khương đo openmp N=1024 với 4 luồng
  $env:OMP_NUM_THREADS=4
  ./bin/bench_cpu.exe --impl openmp --N 1024 --out ../results/cpu_opt_bench.csv
  ```

---

## 4. Báo cáo cấu hình máy đo
Mỗi bạn sau khi hoàn thành đo đạc, chép file `results/env.template.json` thành file riêng của mình:
- Nam: `results/env_nam.json`
- Khương: `results/env_khuong.json`  
Điền đúng thông tin CPU, số nhân/luồng thực, RAM và phiên bản compiler để đảm bảo tính tái lập.
