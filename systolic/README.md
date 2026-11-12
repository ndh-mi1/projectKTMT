# Hướng dẫn Module Systolic Array (Verilog) — Nhóm 15 (MI4344)

> **Mục tiêu:** Thiết kế phần cứng mảng systolic chuyên dụng (ASIC/TPU-like) cho bài toán nhân ma trận trên Verilog HDL, chạy mô phỏng chu kỳ chính xác bằng Icarus Verilog, phân tích giản đồ sóng GTKWave và xây dựng mô hình toán học số chu kỳ $C(N)$.  
> **Người phụ trách:** **Nguyễn Đình Huy (P4 - Trưởng nhóm)**.  
> **File kết quả:** `../results/systolic_cycles.csv`.

---

## 1. Thông số kiến trúc đã chốt

| Thông số | Quyết định | Giải thích kỹ thuật |
|---|---|---|
| **Kích thước mảng** | $8 \times 8$ PE (tổng cộng 64 PEs) | Cân bằng giữa thời gian mô phỏng Icarus và tính trực quan khi soi giản đồ sóng. |
| **Dataflow** | **Weight-Stationary (WS)** | Trọng số $B$ được nạp cố định vào PE; vector kích hoạt $A$ trôi ngang từ trái qua phải; tổng riêng phần (Partial Sum) tích lũy trôi dọc từ trên xuống dưới. |
| **Kiểu dữ liệu** | `int16` MAC, cộng dồn `int32` | Trọng số và kích hoạt là số nguyên có dấu 16-bit (`signed [15:0]`); bộ tích lũy là 32-bit (`signed [31:0]`) để chống tràn số. |
| **Công cụ mô phỏng** | Icarus Verilog (`iverilog`) & GTKWave | Mã nguồn mở, nhẹ, tương thích tốt trên cả Windows và Linux. |

---

## 2. Các thành phần cần tự phát triển

### 2.1. Module RTL (`rtl/`)
1. **`pe.v` (Processing Element):**
   - Chân tín hiệu: `clk`, `rst_n`, `load_w`, `w_in` (16-bit), `a_in` (16-bit), `psum_in` (32-bit), `a_out` (16-bit), `psum_out` (32-bit).
   - Thanh ghi nội bộ lưu trọng số `weight`. Khi `load_w = 1`, nạp giá trị từ `w_in`.
   - Mỗi chu kỳ xung clock: 
     $$a_{\text{out}} \Leftarrow a_{\text{in}}$$
     $$psum_{\text{out}} \Leftarrow psum_{\text{in}} + (a_{\text{in}} \times \text{weight})$$
2. **`systolic_array.v` (Mảng $8 \times 8$):**
   - Dùng vòng lặp `generate` lồng nhau (hàng `r`, cột `c`) để kết nối lưới $8 \times 8$ PEs.
   - Kết nối dây ngang: `a_out` của PE $(r, c)$ nối vào `a_in` của PE $(r, c+1)$.
   - Kết nối dây dọc: `psum_out` của PE $(r, c)$ nối vào `psum_in` của PE $(r+1, c)$. Hàng trên cùng ($r=0$) nhận `psum_in = 0`.
   - Đầu ra đáy mảng: Hàng cuối ($r=7$) xuất kết quả ra bus đầu ra `c_bus`.

### 2.2. Testbench & Kiểm tra tính đúng đắn (`tb/` và `ref/`)
1. **`ref/matmul_ref.py`:**
   - Dùng Python (`numpy`) sinh 2 ma trận ngẫu nhiên `int16`, tính tích bằng phép nhân ma trận chuẩn và xuất ra ma trận kết quả `int32` để làm ground-truth đối chiếu.
2. **`tb/tb_systolic.v`:**
   - Tạo xung nhịp `clk` và tín hiệu reset `rst_n`.
   - Nạp ma trận trọng số $B$ vào mảng thông qua tín hiệu `load_w`.
   - **Căn phase dữ liệu (Data Skewing):** Để mảng systolic hoạt động đúng, dữ liệu đầu vào ma trận $A$ phải được đưa vào lệch pha: hàng $r$ trễ $r$ chu kỳ xung clock so với hàng $0$.
   - Tự động ghi lại kết quả ra file sóng `$dumpfile("wave.vcd"); $dumpvars(0, tb_systolic);`.
   - Đếm số chu kỳ xung clock từ lúc bắt đầu nạp đến khi phần tử cuối cùng của kết quả $C$ ra khỏi đáy mảng.
   - So sánh bit-exact kết quả của mảng phần cứng với kết quả sinh từ `matmul_ref.py`.

---

## 3. Quy trình chạy mô phỏng
Trong thư mục `sim/`, sử dụng các script tiện ích sẵn có:
```powershell
# Trên Windows PowerShell
cd systolic\sim
.\run_sim.ps1
```
Mở file `wave.vcd` sinh ra bằng GTKWave để chụp ảnh dạng sóng phục vụ báo cáo và slide.

---

## 4. Xây dựng mô hình chu kỳ $C(N)$ & Điền CSV (Trả lời Câu hỏi 3)
1. **Mô hình chu kỳ cho ma trận kích thước $N \times N$:**
   - Đối với 1 tile kích thước $8 \times 8$:
     $$T_{\text{tile}} = T_{\text{load}} + T_{\text{stream}} + T_{\text{drain}}$$
   - Với ma trận lớn kích thước $N$, chia thành các tile $8 \times 8$ (số tile theo mỗi chiều là $K = \lceil N/8 \rceil$).
   - Công thức tổng số chu kỳ:
     $$C(N) \approx K^3 \times T_{\text{tile}} + \text{overhead}$$
2. **PE Utilization:**
   $$\text{Utilization} = \frac{\text{Số phép tính MAC hữu ích}}{64 \times C(N)}$$
3. **Ghi số liệu:** Điền kết quả vào file `results/systolic_cycles.csv` theo định dạng quy định tại `METRICS.md`.

---

## 5. Bộ 5 câu hỏi phản biện trọng tâm Phần IV (Huy tự tin bảo vệ trước Hội đồng)
Huy chuẩn bị sẵn sàng câu trả lời cho 5 câu hỏi phản biện cốt lõi của Phần IV để làm chủ phần bảo vệ của mình:
1. *Tại sao lại chọn kiến trúc Weight-Stationary mà không phải Output-Stationary?*
2. *Tại sao mảng lại chọn $8 \times 8$ mà không phải $16 \times 16$ hay lớn hơn?*
3. *Hiện tượng skewing (lệch pha) đường chéo là gì, tại sao bắt buộc phải có?*
4. *Hiệu suất sử dụng PE (utilization) đạt cao nhất và thấp nhất khi nào?*
5. *Tại sao không quy đổi chu kỳ sang mili-giây để so sánh trực tiếp với CPU/GPU?*
