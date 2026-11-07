# Hướng dẫn Module Scripts & Vẽ biểu đồ — Nhóm 15 (MI4344)

> **Mục tiêu:** Thu thập dữ liệu từ các file CSV của các thành viên trong thư mục `results/`, xây dựng script xử lý số liệu và vẽ các đồ thị trực quan phục vụ báo cáo và slide thuyết trình. Đóng vai trò hạt nhân cho Phần V (So sánh chéo & Đánh đổi).  
> **Người phụ trách:** **Nguyễn Thanh Cương (P5)**.  
> **Thư mục xuất ảnh:** `../results/plots/`.

---

## 1. Yêu cầu cài đặt môi trường

Cài đặt các thư viện cần thiết qua `requirements.txt`:
```powershell
pip install -r scripts/requirements.txt
```
Thư viện sử dụng: `numpy`, `pandas`, `matplotlib`.

---

## 2. Dữ liệu đầu vào cần đọc

Cương viết script (ví dụ: `scripts/plot_compare.py`) tự động kiểm tra và đọc các file CSV trong `results/`:
- `results/cpu_bench.csv`: Số liệu CPU nền của Nam (naive, tiled).
- `results/cpu_opt_bench.csv`: Số liệu CPU tối ưu của Khương (openmp, simd).
- `results/gpu_bench.csv`: Số liệu GPU của Long (kernel_ms, e2e_ms, cublas).
- `results/systolic_cycles.csv`: Số liệu chu kỳ mảng systolic của Huy (cycles, utilization).

> [!WARNING]
> Cương **chỉ đọc** các file CSV của các bạn khác, **không được sửa hoặc ghi đè** vào các file CSV đó. Mọi biểu đồ sinh ra lưu vào thư mục `results/plots/`.

---

## 3. Các biểu đồ cần vẽ (Xuất vào `results/plots/`)

1. **Biểu đồ 1 — CPU Ablation Study (Hỗ trợ Phần II của Khương):**
   - Trục hoành: Kích thước ma trận $N$.
   - Trục tung: GFLOPS (hoặc Speedup so với Naive).
   - Các đường: `naive`, `tiled`, `openmp`, `simd`.
2. **Biểu đồ 2 — So sánh GPU vs CPU & Điểm hòa vốn $N^*$ (Hỗ trợ Phần III & V):**
   - Trục hoành: Kích thước ma trận $N$ (thang đo $\log_2$).
   - Trục tung: Thời gian chạy tính bằng mili-giây (ms, thang đo $\log_{10}$).
   - Các đường: CPU tối ưu nhất (OpenMP/SIMD), GPU Kernel thuần, GPU Toàn trình (End-to-End).
   - Đánh dấu rõ điểm cắt hòa vốn $N^*_{\text{kernel}}$ và $N^*_{\text{E2E}}$.
3. **Biểu đồ 3 — Xu hướng chu kỳ & Utilization của Systolic Array (Hỗ trợ Phần IV & V):**
   - Trục hoành: Kích thước $N$.
   - Trục tung trái: Số chu kỳ xung clock ($C(N)$).
   - Trục tung phải: Tỷ lệ sử dụng phần cứng PE Utilization (%).

---

## 4. Xây dựng Bảng đánh đổi 3 Kiến trúc (Câu hỏi 4)
Cương tổng hợp số liệu để hoàn thiện bảng đánh đổi trong Google Docs và slide:

| Tiêu chí | CPU đa năng (General Purpose) | GPU xử lý song song khối lượng lớn | Systolic Array (Chuyên dụng ASIC/TPU) |
|---|---|---|---|
| **Thông lượng đỉnh** | Trung bình ($\sim 10^1 - 10^2$ GFLOPS) | Rất cao ($\sim 10^3 - 10^4$ GFLOPS) | Rất cao trên phép tính cố định ($64 \times f$ MAC/s) |
| **Độ linh hoạt (Flexibility)** | **Rất cao** (chạy mọi loại thuật toán và phân nhánh) | **Trung bình** (phù hợp bài toán song song dữ liệu SIMT) | **Thấp** (cố định bài toán tích chập / nhân ma trận) |
| **Chi phí truyền dữ liệu** | Rất thấp (truy cập trực tiếp RAM và phân cấp Cache) | Cao (nghẽn cổ chai bus PCIe khi chép $H2D, D2H$) | Rất thấp nội bộ (dữ liệu trôi giữa các PE không qua bộ nhớ trung gian) |
| **Độ phức tạp phát triển** | Thấp $\to$ Trung bình (C/OpenMP quen thuộc) | Trung bình $\to$ Cao (CUDA, quản lý block/thread/shared memory) | **Rất cao** (thiết kế phần cứng RTL, timing, skewing) |
| **Kích thước bài toán tối ưu** | $N$ nhỏ đến vừa ($N < N^*$) | $N$ lớn ($N \ge 1024$) | Cố định theo kích thước Tile khối phần cứng |

---

## 5. Nhiệm vụ thuyết trình của Cương
Cương phụ trách thuyết trình 2 phần liên tiếp:
1. **Phần IV.3–IV.6:** Trình bày thay Huy về kết quả mô phỏng systolic array, phân tích giản đồ sóng GTKWave, xu hướng chu kỳ và trả lời Câu hỏi 3.
2. **Phần V:** Trình bày toàn bộ bảng đánh đổi 3 kiến trúc, phân tích các giới hạn thực nghiệm (đo thật vs mô phỏng, float32 vs int16) và kết luận chung của đồ án.
