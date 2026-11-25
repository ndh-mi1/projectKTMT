# MI4344 — So sánh CPU, GPU và Systolic Array trên nhân ma trận

> **Mốc thời gian Tuần 13–18 (25/11/2026 – 30/12/2026):**
> - **Thuyết trình (Tuần 13–17):** Theo lịch trong `GroupProject_381.xlsx` (~45 phút/nhóm: 30p trình bày + 15p Q&A; **100% thành viên đều phải trình bày**).
> - **Hạn nộp bản mềm cuối kỳ qua MS Teams:** **Trước ngày 24/12/2026** (nộp đủ 4 hạng mục: **Slide, Báo cáo cuối kỳ, Mã nguồn và Các tài liệu liên quan**).

---

## 1. Tổng quan đề tài, Yêu cầu & Phạm vi nghiên cứu

**Tên dự án:** *Thiết kế, mô hình hóa và đánh giá hiệu năng ba kiến trúc tính toán (CPU, GPU và Systolic Array) trên bài toán nhân ma trận.*

Cùng một bài toán nhân ma trận vuông $C = A \times B$ ($N \times N$), nhóm tiến hành xây dựng thực nghiệm phần mềm trên **CPU** và **GPU**, kết hợp **thiết kế phần cứng, mô hình hóa và mô phỏng ở mức thanh ghi (RTL) bằng ngôn ngữ Verilog HDL** cho **Systolic Array** — đại diện cho ba triết lý kiến trúc máy tính khác nhau:

| Nền tảng | Cách triển khai & Công cụ | Chỉ số đo lường (Metrics) | Triết lý kiến trúc |
|---|---|---|---|
| **CPU (Laptop/PC)** | C11, `float32`: Naive, Cache Tiling, OpenMP (đa lõi), SIMD (AVX2/FMA); biên dịch `gcc -O3` | Thời gian thực (ms), GFLOPS, Speedup | Đa năng, độ trễ thấp, bộ nhớ cache phân cấp phức tạp |
| **GPU (Google Colab)** | CUDA C/C++, `float32`: Kernel tự viết (`cuda_naive`) và NVIDIA `cuBLAS` trên Tesla T4 | Kernel-only (ms), End-to-End (ms có chép dữ liệu PCIe), GFLOPS | Song song khối lượng lớn (SIMT), thông lượng cực cao, phụ thuộc băng thông PCIe |
| **Systolic Array (Chuyên dụng)** | **Verilog HDL**, mảng $8 \times 8$ PE, Weight-Stationary, `int16` MAC, tích lũy `int32`; mô phỏng **Icarus Verilog** & **GTKWave**, đối chiếu Python | Số chu kỳ xung clock ($C(N)$), PE Utilization ($U\%$) | Chuyên dụng (ASIC/TPU-like), luồng dữ liệu đều đặn, tái sử dụng dữ liệu nội bộ |

### Các yêu cầu của dự án (Requirements)
- **Yêu cầu chức năng (Functional):** Thực thi chính xác phép nhân ma trận vuông $C = A \times B$ trên cả 3 kiến trúc (`cpu/`, `gpu/`, `systolic/`), tự động ghi log số liệu theo schema chuẩn tại [METRICS.md](METRICS.md) và xuất biểu đồ so sánh (`scripts/`).
- **Yêu cầu phi chức năng & Độ chính xác:**
  - CPU/GPU (`float32`): Sai số tương đối cực đại so với bản chuẩn $\le 10^{-3}$ (`correct = 1`); lặp tối thiểu 5 lần lấy trung vị trên dải $N \in [64, 2048]$ (GPU mở rộng tới $4096$).
  - Systolic Array (`int16` $\to$ `int32`): Thiết kế RTL tổng hợp được theo chuẩn Verilog-2012, hoạt động không tràn số khi cộng dồn 8 tầng, kiểm chứng đúng đắn **bit-exact** với mô hình tham chiếu Python `int16`/`int32`.
- **Yêu cầu chuẩn học thuật (Báo cáo & Thuyết trình):** Báo cáo cuối kỳ trình bày theo **chuẩn APA**, trích dẫn số kiểu **IEEE**, có **1–2 trang tóm tắt đóng góp thành viên từ cao đến thấp** và **Phụ lục kế hoạch làm việc nhóm**; bài thuyết trình đủ 4 nội dung bắt buộc và có phần demo/mô phỏng sản phẩm.

### Phạm vi & Lý do triển khai một phần sản phẩm (Scope Rationale)
- **Trong phạm vi (Lý do chọn cấu phần triển khai):**
  - CPU: Đo 4 mức tối ưu đại diện (naive, tiled, openmp, simd) để bóc tách rạch ròi tác động của Cache, Đa lõi và Vector hóa.
  - GPU: Chọn `cuda_naive` làm đối chứng cơ bản và `cuBLAS` làm cận trên thực tế trên Colab Tesla T4, tách riêng chi phí PCIe ($H2D, D2H$) và $T_{\text{kernel}}$.
  - Systolic Array: Triển khai phần nhân tính toán cốt lõi (Core Compute Grid) là mảng $8 \times 8$ PE (64 PEs) Weight-Stationary (mô phỏng TPU v1 rút gọn) nhằm cân bằng giữa việc nhìn rõ luồng 2D + Skewing trên sóng GTKWave, tốc độ mô phỏng Icarus Verilog nhanh (vài giây), chia hết kích thước Tiling ($N = 64 \dots 2048$) và vừa khít tài nguyên DSP của một FPGA phổ thông (Artix-7).
  - Báo cáo và thuyết trình: Trả lời dứt khoát 4 câu hỏi nghiên cứu và nêu rõ các hạn chế thực nghiệm.
- **Ngoài phạm vi:** Không xây dựng hệ thống chip hoàn chỉnh kèm DMA/HBM/Network-on-Chip phức tạp, không nạp lên board FPGA vật lý, không đo điện năng tiêu thụ vật lý (Joules/Watt), không khảo sát thêm các dataflow khác ngoài Weight-Stationary.

> [!IMPORTANT]
> **Quy tắc so sánh xuyên suốt:** Tuyệt đối không quy đổi chu kỳ mô phỏng sang mili-giây để đua tốc độ trực tiếp giữa Systolic Array với máy thật (CPU/GPU). Phần so sánh chéo được thực hiện khoa học qua **Bảng ma trận đánh đổi (Trade-off Matrix)** ở Chương 3 (Kết quả & Bàn luận).

---

## 2. Bốn câu hỏi nghiên cứu cốt lõi

1. **Câu hỏi 1 (CPU — Khương):** Tối ưu mã nguồn hiểu kiến trúc phần cứng (Cache locality, SIMD, đa nhân) giúp CPU tăng tốc bao nhiêu lần so với bản gốc? Đóng góp định lượng của từng kỹ thuật là bao nhiêu?
2. **Câu hỏi 2 (GPU — Long):** Khi nào GPU thực sự vượt trội hơn CPU? Điểm hòa vốn kích thước ma trận $N^*$ là bao nhiêu khi tính toán thuần và khi tính toàn trình cả thời gian truyền dữ liệu qua PCIe?
3. **Câu hỏi 3 (Systolic Array — Huy):** Tại sao cấu trúc phần cứng đơn giản của Systolic Array lại đạt được thông lượng tính toán cực cao? Số chu kỳ thực thi và hiệu suất PE thay đổi như thế nào theo kích thước $N$?
4. **Câu hỏi 4 (Đánh đổi — Cương):** Bài toán đánh đổi giữa Tính linh hoạt (Flexibility) và Hiệu suất tính toán (Efficiency) giữa 3 kiến trúc máy tính này diễn ra như thế nào?

---

## 3. Phân công thành viên

| Vai | Họ và tên | MSSV | Module phụ trách | Trách nhiệm chính (Code & Báo cáo) | Thuyết trình |
|---|---|---|---|---|---|
| **P1** | Trịnh Nhật Nam | 202418949 | `cpu/` | Interface chung, CPU Naive, Cache Tiling, Harness đo thời gian, CSV `results/cpu_bench.csv`; viết **Chương 1 (Giới thiệu)** & phần **CPU nền** (Chương 2–3) | **Lượt 1:** Bối cảnh, Yêu cầu & CPU nền |
| **P2** | Lê Duy Khương | 202418926 | `cpu/` | CPU OpenMP, SIMD/AVX2, Ablation study, CSV `results/cpu_opt_bench.csv`; viết phần **CPU tối ưu** (Chương 2–3); **Gom bài, chuẩn hóa APA & IEEE, xuất PDF nộp** | **Lượt 2:** Tối ưu CPU & Câu hỏi 1 |
| **P3** | Nguyễn Hoàng Long | 202418938 | `gpu/` | Kernel CUDA naive, `cuBLAS`, đo $T_{\text{kernel}}$ vs $T_{\text{E2E}}$ trên Colab, xác định $N^*$, CSV `results/gpu_bench.csv`; viết phần **GPU** (Chương 2–3) | **Lượt 3:** Tăng tốc GPU & Câu hỏi 2 |
| **P4** | Nguyễn Đình Huy | 202418918 | `systolic/` | **Trưởng nhóm:** Thiết kế RTL mảng $8 \times 8$ WS, testbench, mô phỏng Icarus/GTKWave, chu kỳ $C(N)$, CSV `results/systolic_cycles.csv`; viết phần **Systolic Array HDL** (Chương 2–3) & **Phụ lục Kế hoạch** | **Lượt 4:** Systolic Array HDL, Demo RTL & Câu hỏi 3 |
| **P5** | Nguyễn Thanh Cương | 202418857 | `scripts/` | Script đọc CSV, vẽ biểu đồ vào `results/plots/`, xây dựng Trade-off Matrix, đánh giá giới hạn & làm chủ công cụ (Chương 2–3) | **Lượt 5:** So sánh chéo, Lý do phạm vi & Câu hỏi 4 |

---

## 4. Cấu trúc Báo cáo cuối kỳ chuẩn APA & Trích dẫn IEEE

> [!IMPORTANT]
> **Quy chuẩn trình bày & trích dẫn bắt buộc (theo hướng dẫn Giảng viên):**
> - **Định dạng văn bản:** Soạn thảo trên **[Google Docs Báo cáo Nhóm 15](https://docs.google.com/document/d/1TXFgWydyJ7rMBT3fG0oTWzDbLhph4TGgAmQufeilvIE/edit?usp=sharing)** theo chuẩn **APA** ([APA Paper Format](https://apastyle.apa.org/style-grammar-guidelines/paper-format)): lề `1 inch` (2.54 cm), font chữ thống nhất (Times New Roman 12pt), đánh số trang góc trên phải, phân cấp Heading và đánh số Hình/Bảng theo chuẩn. Xem chi tiết tại [`docs/MAU-BAO-CAO-APA-IEEE.md`](docs/MAU-BAO-CAO-APA-IEEE.md).
> - **Trích dẫn & Tài liệu tham khảo:** Bắt buộc dùng kiểu đánh số **IEEE numerical citation style** (`[1]`, `[2]` theo thứ tự xuất hiện — xem [IEEE Citation Guide](https://pitt.libguides.com/citationhelp/ieee)).
> - **Trang đóng góp thành viên:** Đầu báo cáo **PHẢI có 1–2 trang tóm tắt mô tả đóng góp của từng thành viên theo thứ tự từ cao đến thấp** (đặt trước nội dung chính). Khương kiểm tra định dạng toàn bài và xuất PDF nộp cuối cùng.

| Mục | Tiêu đề chuẩn Báo cáo cuối kỳ | Người viết | Nội dung bắt buộc & Ánh xạ kỹ thuật |
|---|---|---|---|
| **Đầu bài** | **Trang bìa chuẩn APA, Mục lục, Danh mục Hình/Bảng** | **Khương** | Title page chuẩn APA + HUST; mục lục và danh mục tự động sinh từ Heading. |
| **Bắt buộc (1–2 trang)** | **Tóm tắt đóng góp của từng thành viên (từ cao đến thấp)** | **Huy & Khương** *(cả nhóm duyệt)* | **Đứng ngay trước nội dung chính:** Xếp hạng đóng góp từ cao đến thấp; nêu rõ vai trò, hạng mục code/RTL, đo đạc/mô phỏng, viết báo cáo & làm slide của từng người. |
| **Tóm tắt** | **Tóm tắt (Abstract)** | **Khương** | Tóm tắt 5–7 câu về mục tiêu, phương pháp, kết quả nổi bật và kết luận chính (viết sau cùng). |
| **Chương 1** | **GIỚI THIỆU** *(Phần I cũ)* | **Nam** *(+ Huy rà soát Systolic)* | **Đầy đủ 3 ý bắt buộc:**<br>• **1.1 Tên & Mô tả dự án:** Tổng quan bài toán nhân ma trận trên 3 kiến trúc (CPU, GPU, và phần cứng Systolic Array thiết kế/mô hình/mô phỏng).<br>• **1.2 Đề tài, Bối cảnh & 4 câu hỏi nghiên cứu:** Memory Wall ($2N^3$ FLOPs vs $2N^2$ dữ liệu) và 4 câu hỏi nghiên cứu.<br>• **1.3 Các yêu cầu của bài toán (Requirements):** Yêu cầu chức năng, độ chính xác (`float32` $\le 10^{-3}$, `int16` bit-exact), dải $N$ và lý do phạm vi triển khai.<br>• **1.4 Cơ sở lý thuyết đo đạc:** Công thức FLOPs, GFLOPS, Cycles, Utilization, quy tắc không đổi chu kỳ sang ms đua trực tiếp. |
| **Chương 2** | **PHƯƠNG PHÁP LUẬN** *(Kiến trúc, HDL & Công cụ triển khai)* | **Theo module** | **Mô tả cấu trúc, chức năng sản phẩm, việc sử dụng HDL và công cụ lựa chọn:**<br>• **2.1 Kiến trúc tổng thể & Lựa chọn công cụ (Cương + Huy):** Tổng hợp công cụ (`gcc -O3`, OpenMP/AVX2, CUDA/`cuBLAS`, **Verilog HDL**, `iverilog`/`GTKWave`, Python) & lý do triển khai từng phần.<br>• **2.2 Thiết kế & Tối ưu trên CPU (Nam & Khương):** Cấu trúc Naive ($i-j-k$), Cache Tiling ($ii-jj-kk$), đa lõi OpenMP, vector hóa AVX2/FMA ($i-k-j$) và harness đo `bench_main.c`.<br>• **2.3 Thiết kế & Tăng tốc trên GPU (Long):** Mô hình SIMT, Kernel CUDA naive, `cuBLAS`, đo bóc tách $T_{\text{H2D}}/T_{\text{kernel}}/T_{\text{D2H}}$ bằng `cudaEvent_t`.<br>• **2.4 Thiết kế Systolic Array bằng Verilog HDL (Huy — *tương ứng Mục IV.1–IV.2*):** Dataflow Weight-Stationary, lý do chọn lưới $8 \times 8$, vi kiến trúc PE (`pe.v`: `int16` MAC, `int32` accumulator), ghép lưới 2D (`systolic_array.v`), Data Skewing & Wavefront.<br>• **2.5 Phương pháp tổng hợp CSV & Ma trận đánh đổi (Cương):** Thiết kế pipeline đọc CSV (`scripts/`), khung Trade-off Matrix 5 tiêu chí. |
| **Chương 3** | **KẾT QUẢ VÀ BÀN LUẬN** *(Thực nghiệm, Mô phỏng & Đánh giá)* | **Theo module** | **Trình bày kết quả, phân tích chứng minh làm chủ phương pháp, công nghệ và công cụ:**<br>• **3.1 Kết quả & Phân tích trên CPU (Nam & Khương — *Câu hỏi 1*):** Bảng & đồ thị Naive vs Tiled ($N \in [64, 2048]$), bảng Ablation Study (Naive $\to$ Tiled $\to$ OpenMP $\to$ SIMD), Speedup và đóng góp từng kỹ thuật.<br>• **3.2 Kết quả & Phân tích trên GPU (Long — *Câu hỏi 2*):** Bảng số liệu $T_{\text{kernel}}$ vs $T_{\text{E2E}}$ trên Tesla T4, đồ thị log-log GPU vs CPU, điểm hòa vốn $N^*_{\text{kernel}}, N^*_{\text{E2E}}$.<br>• **3.3 Kết quả mô phỏng RTL Systolic Array & Chu kỳ (Huy — *tương ứng Mục IV.3–IV.6, Câu hỏi 3*):** Testbench `tb_systolic.v`, đối chiếu bit-exact với `matmul_ref.py`, **ảnh chụp waveform GTKWave**, mô hình chu kỳ $C(N)$ và PE Utilization, *(tùy chọn)* ước lượng tài nguyên FPGA.<br>• **3.4 So sánh chéo & Ma trận đánh đổi 3 kiến trúc (Cương — *Câu hỏi 4*):** Bảng tổng hợp 3 nền tảng, **Trade-off Matrix 5 tiêu chí**, phân tích đánh đổi Linh hoạt $\leftrightarrow$ Hiệu suất.<br>• **3.5 Đánh giá làm chủ công cụ, Hạn chế & Hướng phát triển (Cương + nhóm):** Chứng minh làm chủ công cụ (`gcc`, CUDA, Verilog/GTKWave), hạn chế (`float32` vs `int16`, chu kỳ mô phỏng vs ms thật, Colab) và hướng mở rộng. |
| **Tham khảo** | **TÀI LIỆU THAM KHẢO** | **Khương** *(cả nhóm gửi nguồn)* | Liệt kê toàn bộ tài liệu đã tham khảo theo chuẩn đánh số **IEEE numerical citation style** (`[1]`, `[2]`...). Xem danh mục khởi tạo tại [`docs/MAU-BAO-CAO-APA-IEEE.md`](docs/MAU-BAO-CAO-APA-IEEE.md). |
| **Phụ lục** | **PHỤ LỤC** | **Huy & Khương** | • **Phụ lục A (Bắt buộc):** **Kế hoạch làm việc của nhóm** (Tiến độ Tuần 1–18, WBS, quản lý GitHub/Docs/Canva — xem [`docs/KE-HOACH-LAM-VIEC-NHOM.md`](docs/KE-HOACH-LAM-VIEC-NHOM.md)).<br>• **Phụ lục B:** Cấu hình phần cứng/môi trường các thành viên (`results/env_*.json`).<br>• **Phụ lục C:** Link GitHub, toàn văn CSV gốc & Hướng dẫn tái lập kết quả. |

---

## 5. Phân công Slide (Canva) & Thuyết trình (~45 phút)

- **Nền tảng làm slide:** Soạn thảo chung trên **[Canva Slide Nhóm 15](https://canva.link/r64u2jb5pdawwcw)**.
- **Lịch & Thời lượng báo cáo:** Lịch thuyết trình Tuần 13–17 theo file `GroupProject_381.xlsx` trên Teams lớp MI4344. Tổng thời lượng **~45 phút** gồm **30 phút trình bày + 15 phút trao đổi (Q&A)**; **100% thành viên đều phải trình bày**.
- **Bốn nội dung BẮT BUỘC phải có trong bài thuyết trình:**
  1. **Bối cảnh và chủ đề của dự án.**
  2. **Bài toán và các giải pháp** (CPU, GPU, Systolic Array Verilog HDL).
  3. **Lý do triển khai toàn bộ hoặc một phần sản phẩm** (làm rõ vì sao chạy benchmark phần mềm trên CPU/GPU và triển khai thiết kế RTL lõi tính toán $8 \times 8$ WS thay vì xây dựng cả con chip TPU có DMA/HBM hay tổng hợp lên board FPGA).
  4. **Trình bày / mô phỏng sản phẩm (Demo):** Chạy/minh họa thực tế chương trình C (`bench_cpu`), notebook GPU Colab và **chạy mô phỏng RTL Icarus Verilog + soi giản đồ sóng GTKWave / mô phỏng trực quan luồng Systolic Array**.

| Lượt | Nội dung trình bày & Nội dung bắt buộc đáp ứng | Người làm Slide & Thuyết trình | Trọng tâm & Sản phẩm minh họa (Demo) |
|---|---|---|---|
| **1** | **Giới thiệu, Yêu cầu & CPU nền**<br>*(Bối cảnh, chủ đề dự án, bài toán & yêu cầu)* | **Nam** | Memory Wall, mô tả 3 kiến trúc & thành phần thiết kế/mô phỏng, công thức metrics, kết quả CPU Naive vs Tiled. |
| **2** | **Tối ưu hóa trên CPU (Câu hỏi 1)**<br>*(Giải pháp tối ưu CPU & chứng minh làm chủ công cụ)* | **Khương** | Nguyên lý & cài đặt OpenMP, SIMD AVX2/FMA ($i-k-j$), Ablation Study, **demo biên dịch/chạy `bench_cpu`**. |
| **3** | **Tăng tốc trên GPU (Câu hỏi 2)**<br>*(Giải pháp song song GPU & phân tích hiệu năng)* | **Long** | SIMT CUDA naive vs `cuBLAS`, bóc tách $T_{\text{H2D}}/T_{\text{kernel}}/T_{\text{D2H}}$, điểm hòa vốn $N^*$, **minh họa Notebook Colab**. |
| **4** | **Systolic Array bằng Verilog HDL (Câu hỏi 3)**<br>*(Thiết kế phần cứng, lý do triển khai $8 \times 8$ & mô phỏng sản phẩm)* | **Huy** | Dataflow WS, lý do chỉ triển khai lõi $8 \times 8$ WS, vi kiến trúc PE & mảng lưới, Skewing, **demo chạy `iverilog` + sóng GTKWave**, mô hình $C(N)$ & Utilization. |
| **5** | **So sánh chéo, Lý do phạm vi & Kết luận (Câu hỏi 4)**<br>*(Tổng kết lý do triển khai từng phần & đánh đổi 3 kiến trúc)* | **Cương** | Bảng tổng hợp, Trade-off Matrix 5 tiêu chí, tổng kết lý do phạm vi toàn/bán phần từng kiến trúc, hạn chế & hướng phát triển. |
| **6** | **Trao đổi & Phản biện (Q&A — 15 phút)** | **Cả nhóm** | Giảng viên và lớp đặt câu hỏi; thành viên phụ trách phần nào chủ động trả lời bảo vệ. |

---

## 6. Cấu trúc thư mục mã nguồn Repo & Hồ sơ nộp Teams

```
projectKTMT/
├── README.md                          # Trang chủ: Tổng quan, Yêu cầu, Mục lục chuẩn APA/IEEE, Thuyết trình
├── HUONG-DAN-QUY-TRINH-NHOM.md        # Hướng dẫn Git, phân quyền, Lịch trình Tuần 13-18, APA/IEEE & Checklist Teams
├── METRICS.md                         # Chuẩn hóa công thức và schema các file CSV kết quả
├── Ly_thuyet_can_thiet_MI4344.pdf     # Tài liệu lý thuyết kiến trúc máy tính nền tảng (12 trang)
│
├── docs/                              # TÀI LIỆU CHUẨN HÓA BÁO CÁO & KẾ HOẠCH (Huy)
│   ├── KE-HOACH-LAM-VIEC-NHOM.md      # Kế hoạch làm việc Tuần 1-18 chi tiết (dùng cho Phụ lục A)
│   └── MAU-BAO-CAO-APA-IEEE.md        # Mẫu 1-2 trang Đóng góp thành viên, chuẩn APA & trích dẫn IEEE
│
├── cpu/                               # MODULE CPU (Nam & Khương)
│   ├── README.md                      # Hướng dẫn chi tiết yêu cầu code, build và test CPU
│   ├── include/                       # Khung interface (matmul.h)
│   └── src/                           # Mã nguồn do Nam & Khương tự viết
│
├── gpu/                               # MODULE GPU (Long)
│   ├── README.md                      # Hướng dẫn viết kernel CUDA, đo H2D/D2H, cuBLAS
│   ├── src/                           # Mã nguồn CUDA (.cu)
│   └── notebooks/                     # Jupyter Notebook chạy trên Google Colab
│
├── systolic/                          # MODULE SYSTOLIC ARRAY (Huy)
│   ├── README.md                      # Hướng dẫn thiết kế RTL, dataflow WS, mô hình chu kỳ
│   ├── rtl/                           # Mã nguồn Verilog (pe.v, systolic_array.v)
│   ├── tb/                            # Testbench mô phỏng (tb_systolic.v)
│   ├── sim/                           # Script chạy mô phỏng Icarus (run_sim.ps1, run_sim.sh)
│   └── ref/                           # Model tham chiếu kiểm tra đúng đắn (matmul_ref.py)
│
├── results/                           # KẾT QUẢ THỰC NGHIỆM ĐO ĐẠC
│   ├── cpu_bench.csv                  # Kết quả đo CPU nền (Nam)
│   ├── cpu_opt_bench.csv              # Kết quả đo CPU tối ưu (Khương)
│   ├── gpu_bench.csv                  # Kết quả đo GPU (Long)
│   ├── systolic_cycles.csv            # Kết quả đo chu kỳ Systolic (Huy)
│   ├── env.template.json              # Mẫu khai báo thông số máy đo
│   ├── env_<ten>.json                 # File cấu hình máy riêng của từng thành viên
│   └── plots/                         # Biểu đồ xuất ra phục vụ báo cáo/slide (Cương)
│
└── scripts/                           # SCRIPTS PHÂN TÍCH & VẼ BIỂU ĐỒ (Cương)
    ├── README.md                      # Hướng dẫn đọc CSV và vẽ các biểu đồ đánh đổi
    └── requirements.txt               # Thư viện phụ thuộc (numpy, pandas, matplotlib)
```

---

## 7. Bắt đầu làm việc & Nộp bài cuối kỳ

- **GitHub Repository:** https://github.com/ndh-mi1/projectKTMT
- **Báo cáo chung (Google Docs):** https://docs.google.com/document/d/1TXFgWydyJ7rMBT3fG0oTWzDbLhph4TGgAmQufeilvIE/edit?usp=sharing
- **Slide thuyết trình (Canva):** https://canva.link/r64u2jb5pdawwcw
- **Lịch thuyết trình lớp (Excel trên Teams):** `GroupProject_381.xlsx`

1. Đọc kỹ tài liệu lý thuyết [Ly_thuyet_can_thiet_MI4344.pdf](Ly_thuyet_can_thiet_MI4344.pdf).
2. Đọc [HUONG-DAN-QUY-TRINH-NHOM.md](HUONG-DAN-QUY-TRINH-NHOM.md) để nắm quy trình Git, **Lịch trình Tuần 13–18**, **chuẩn APA + IEEE** và **Checklist nộp MS Teams trước ngày 24/12/2026**.
3. Đọc file `README.md` trong module của mình (`cpu/`, `gpu/`, `systolic/`, `scripts/`) và tham khảo [`docs/MAU-BAO-CAO-APA-IEEE.md`](docs/MAU-BAO-CAO-APA-IEEE.md) khi soạn báo cáo.
4. Ghi kết quả đo đạc vào file CSV riêng theo chuẩn quy định tại [METRICS.md](METRICS.md).
