# MI4344 — So sánh CPU, GPU và Systolic Array trên nhân ma trận


## 1. Tổng quan đề tài & Phạm vi nghiên cứu

Cùng một bài toán nhân ma trận vuông $C = A \times B$, nhóm tiến hành khảo sát và đánh giá thực nghiệm trên ba nền tảng phần cứng đại diện cho ba triết lý kiến trúc máy tính khác nhau:

| Nền tảng | Cách triển khai | Chỉ số đo lường (Metrics) | Triết lý kiến trúc |
|---|---|---|---|
| **CPU (Laptop/PC)** | C, `float32`: Naive, Cache Tiling, OpenMP (đa lõi), SIMD (vector hóa) | Thời gian thực (ms), GFLOPS | Đa năng, độ trễ thấp, bộ nhớ cache phân cấp phức tạp |
| **GPU (Google Colab)** | CUDA `float32`: Kernel tự viết (`cuda_naive`) và thư viện NVIDIA `cuBLAS` | Kernel-only (ms), End-to-End (ms có chép dữ liệu PCIe), GFLOPS | Song song khối lượng lớn (SIMT), thông lượng cực cao, phụ thuộc băng thông PCIe |
| **Systolic Array** | Verilog HDL, mảng $8 \times 8$ PE, Weight-Stationary, `int16` MAC, tích lũy `int32`, mô phỏng Icarus | Số chu kỳ xung clock ($C(N)$), PE Utilization (%) | Chuyên dụng (ASIC/TPU-like), luồng dữ liệu đều đặn, tiết kiệm băng thông bộ nhớ |

### Phạm vi nghiên cứu (Scope)
- **Trong phạm vi:**
  - CPU: Đo đạc 4 mức tối ưu (naive, tiled, openmp, simd) trên dải $N \in [64, 2048]$, phân tích ablation study.
  - GPU: Kernel naive và cuBLAS trên Google Colab, bóc tách thời gian PCIe ($H2D, D2H$) và kernel thuần, xác định điểm hòa vốn $N^*$.
  - Systolic Array: Mảng $8 \times 8$ PE Weight-Stationary, kiểu số `int16` MAC cộng dồn `int32`, kiểm tra đúng đắn bit-exact với mô hình phần mềm, phân tích giản đồ sóng GTKWave và xây dựng mô hình chu kỳ $C(N)$.
  - Báo cáo và thuyết trình: Trả lời dứt khoát 4 câu hỏi nghiên cứu và nêu rõ các hạn chế thực nghiệm.
- **Ngoài phạm vi:** Không xây dựng full TPU/DMA/HBM phức tạp, không chạy trên board FPGA vật lý, không đo điện năng tiêu thụ (Joules/Watt), không khảo sát nhiều dataflow systolic khác nhau ngoài Weight-Stationary.

> [!IMPORTANT]
> **Quy tắc so sánh xuyên suốt:** Tuyệt đối không quy đổi chu kỳ mô phỏng sang mili-giây để đua tốc độ trực tiếp giữa Systolic Array với máy thật (CPU/GPU). Phần so sánh chéo được thực hiện khoa học qua **Bảng ma trận đánh đổi (Trade-off Matrix)** ở Phần V.

---

## 2. Bốn câu hỏi nghiên cứu cốt lõi

1. **Câu hỏi 1 (CPU — Khương):** Tối ưu mã nguồn hiểu kiến trúc phần cứng (Cache locality, SIMD, đa nhân) giúp CPU tăng tốc bao nhiêu lần so với bản gốc? Đóng góp định lượng của từng kỹ thuật là bao nhiêu?
2. **Câu hỏi 2 (GPU — Long):** Khi nào GPU thực sự vượt trội hơn CPU? Điểm hòa vốn kích thước ma trận $N^*$ là bao nhiêu khi tính toán thuần và khi tính toàn trình cả thời gian truyền dữ liệu qua PCIe?
3. **Câu hỏi 3 (Systolic Array — Huy):** Tại sao cấu trúc phần cứng đơn giản của Systolic Array lại đạt được thông lượng tính toán cực cao? Số chu kỳ thực thi và hiệu suất PE thay đổi như thế nào theo kích thước $N$?
4. **Câu hỏi 4 (Đánh đổi — Cương):** Bài toán đánh đổi giữa Tính linh hoạt (Flexibility) và Hiệu suất tính toán (Efficiency) giữa 3 kiến trúc máy tính này diễn ra như thế nào?

---

## 3. Phân công thành viên

| Vai | Họ và tên | MSSV | Module phụ trách | Trách nhiệm chính | Thuyết trình |
|---|---|---|---|---|---|
| **P1** | Trịnh Nhật Nam | 202418949 | `cpu/` | Interface chung, CPU Naive, Cache Tiling, Harness đo thời gian, CSV `results/cpu_bench.csv` | Phần I và IV.1–IV.2 |
| **P2** | Lê Duy Khương | 202418926 | `cpu/` | CPU OpenMP, SIMD/AVX2, Ablation study, CSV `results/cpu_opt_bench.csv`; **Gom và xuất bản báo cáo nộp** | Phần II |
| **P3** | Nguyễn Hoàng Long | 202418938 | `gpu/` | Kernel CUDA naive, cuBLAS, đo $T_{\text{kernel}}$ vs $T_{\text{E2E}}$ trên Colab, xác định $N^*$, CSV `results/gpu_bench.csv` | Phần III |
| **P4** | Nguyễn Đình Huy | 202418918 | `systolic/` | **Trưởng nhóm:** Thiết kế RTL mảng $8 \times 8$ WS, testbench, mô phỏng Icarus, mô hình chu kỳ $C(N)$, CSV `results/systolic_cycles.csv`, điều phối | *Không thuyết trình* |
| **P5** | Nguyễn Thanh Cương | 202418857 | `scripts/` | Script đọc CSV, vẽ biểu đồ so sánh vào `results/plots/`, xây dựng ma trận đánh đổi, phân tích giới hạn | Phần IV.3–IV.6 và Phần V |

---

## 4. Cấu trúc mục lục báo cáo chi tiết & Phân chia viết bài

Toàn bộ báo cáo được soạn thảo trực tiếp trên **[Google Docs Báo cáo Nhóm 15](https://docs.google.com/document/d/1TXFgWydyJ7rMBT3fG0oTWzDbLhph4TGgAmQufeilvIE/edit?usp=sharing)**. Khương kiểm tra định dạng và xuất bản PDF nộp cuối cùng. Mỗi thành viên chịu trách nhiệm viết đúng mục của mình theo cấu trúc chi tiết sau:

```
Báo cáo Đồ án Kiến trúc Máy tính (MI4344) — Dự kiến: 16–22 trang
```

| Mục | Tiêu đề chi tiết | Người viết | Nội dung trọng tâm & Hình/Bảng bắt buộc | Số trang |
|---|---|---|---|---|
| | **Trang bìa, Mục lục, Danh mục hình/bảng** | **Khương** | Bìa chuẩn quy cách HUST, mục lục tự động sinh từ Heading. | 2 trang |
| | **Tóm tắt (Abstract)** | **Khương** | Tóm tắt toàn bộ nghiên cứu trong 5–7 câu: mục tiêu, phương pháp, kết quả nổi bật và kết luận chính (viết sau cùng). | 0.5 trang |
| **I** | **GIỚI THIỆU VÀ NỀN TẢNG ĐO ĐẠC** | **Nam** | Đặt nền tảng cho toàn bộ báo cáo: | **3–4 trang** |
| I.1 | Bối cảnh & Lý do chọn bài toán nhân ma trận | Nam | Ứng dụng trong AI/Graphics/Khoa học dữ liệu; đặc trưng truy cập bộ nhớ. | |
| I.2 | Mục tiêu nghiên cứu & 4 câu hỏi nghiên cứu | Nam | Nêu rõ 4 câu hỏi nghiên cứu của đề tài. | |
| I.3 | Cơ sở lý thuyết đo: Công thức FLOPs & GFLOPS | Nam | Công thức $2N^3$, định nghĩa GFLOPS; nguyên tắc không so sánh trực tiếp ms thật với chu kỳ mô phỏng. | |
| I.4 | Môi trường thực nghiệm CPU | Nam | Bảng cấu hình phần cứng (CPU, cache L1/L2/L3, RAM), OS, compiler flags (`-O3 -fopenmp`). | |
| I.5 | Thực nghiệm CPU nền: Naive vs Cache Tiling | Nam | Trình bày thuật toán naive $i-j-k$ và tiled $ii-jj-kk$; phân tích hiện tượng Cache Miss; **Bảng số liệu thời gian & GFLOPS ($N \in [64, 2048]$)**. | |
| I.6 | Tóm tắt nền tảng & Điểm nghẽn bộ nhớ | Nam | Đồ thị thời gian Naive vs Tiled; nhận xét nút thắt Memory-bound. | |
| **II** | **TỐI ƯU HÓA TRÊN CPU (Trả lời Câu hỏi 1)** | **Khương** | Khảo sát các kỹ thuật khai thác triệt để vi kiến trúc CPU: | **3–4 trang** |
| II.1 | Các kỹ thuật tối ưu phần cứng trên CPU | Khương | Nguyên lý song song hóa đa lõi (OpenMP) và song song mức lệnh/dữ liệu (SIMD, vector registers). | |
| II.2 | Thiết lập thí nghiệm bóc tách (Ablation Study) | Khương | Giữ cố định kích thước $N$, đo qua từng nấc: Naive $\to$ Tiled $\to$ OpenMP $\to$ SIMD. | |
| II.3 | Kết quả thực nghiệm và phân tích định lượng | Khương | **Bảng Ablation Study** (thời gian, GFLOPS, Speedup so với Naive); **Biểu đồ GFLOPS theo $N$**. | |
| II.4 | Phân tích đóng góp của từng kỹ thuật | Khương | Tác động của Cache Tiling (giảm miss), OpenMP (tận dụng đa nhân), SIMD (tăng thông lượng FMA). | |
| II.5 | Kết luận & Trả lời dứt khoát Câu hỏi 1 | Khương | Trả lời: Tăng tốc được tối đa bao nhiêu lần; kỹ thuật nào đóng góp lớn nhất. | |
| **III** | **TĂNG TỐC TRÊN GPU (Trả lời Câu hỏi 2)** | **Long** | Đánh giá kiến trúc xử lý song song khối lượng lớn: | **3–4 trang** |
| III.1 | Kiến trúc GPU & Môi trường đo Colab | Long | Cấu hình GPU (Tesla T4), SMs, CUDA cores, phương pháp đo bằng `cudaEvent_t`. | |
| III.2 | Cài đặt Kernel Naive và cuBLAS | Long | Mô hình luồng SIMT, cấu hình Grid/Block, cách gọi thư viện chuẩn `cublasSgemm`. | |
| III.3 | Đo lường chi tiết: $T_{\text{kernel}}$ vs $T_{\text{E2E}}$ | Long | Phân tích sơ đồ thời gian: $T_{\text{H2D}}$ (copy sang GPU), $T_{\text{kernel}}$, $T_{\text{D2H}}$ (copy về CPU), $T_{\text{E2E}}$; **Bảng số liệu GPU**. | |
| III.4 | Phân tích điểm hòa vốn $N^*$ so với CPU | Long | So sánh GPU với bản CPU tốt nhất; xác định $N^*_{\text{kernel}}$ và $N^*_{\text{E2E}}$; **Biểu đồ thời gian log-log**. | |
| III.5 | Kết luận & Trả lời dứt khoát Câu hỏi 2 | Long | Trả lời: Khi nào GPU thắng CPU; chi phí truyền dữ liệu PCIe ảnh hưởng thế nào đến bài toán nhỏ. | |
| **IV** | **SYSTOLIC ARRAY CHUYÊN DỤNG (Trả lời Câu hỏi 3)** | **Huy** | Thiết kế phần cứng ASIC/TPU-like trên Verilog: | **3–4 trang** |
| IV.1 | Ý tưởng kiến trúc & Luồng dữ liệu Weight-Stationary | Huy | Nguyên lý mảng dòng tâm thất; so sánh Weight-Stationary vs Output-Stationary; sơ đồ luồng dữ liệu 2D. | |
| IV.2 | Thiết kế vi kiến trúc PE và Mảng $8 \times 8$ | Huy | Cấu trúc PE (`int16` MAC, `int32` accumulator); sơ đồ kết nối lưới $8 \times 8$; cơ chế nạp trọng số `load_w`. | |
| IV.3 | Mô phỏng RTL & Phân tích Waveform | Huy | Quy trình mô phỏng Icarus Verilog; kỹ thuật skewing đầu vào; **Ảnh chụp giản đồ sóng GTKWave minh họa quá trình tính**. | |
| IV.4 | Số chu kỳ thực thi & Hiệu suất sử dụng PE | Huy | Xây dựng công thức chu kỳ $C(N)$ cho tile và ma trận $N \times N$; **Bảng số chu kỳ và PE Utilization theo $N$**; đồ thị chu kỳ. | |
| IV.5 | (Tùy chọn) Đánh giá tổng hợp phần cứng | Huy | Ước lượng diện tích và tài nguyên FPGA (LUT, DSP, BRAM) nếu tổng hợp qua Vivado. | |
| IV.6 | Kết luận & Trả lời dứt khoát Câu hỏi 3 | Huy | Trả lời: Vì sao mảng đạt thông lượng cao dù cấu trúc đơn giản; bộ 5 câu hỏi Q&A phục vụ phản biện. | |
| **V** | **SO SÁNH CHÉO, ĐÁNH ĐỔI & KẾT LUẬN (Trả lời Câu hỏi 4)** | **Cương** | Bức tranh toàn cảnh về 3 triết lý kiến trúc máy tính: | **2–3 trang** |
| V.1 | Tổng hợp kết quả đo đạc từ 3 nền tảng | Cương | Bảng tổng hợp các metric chính của CPU, GPU và Systolic Array. | |
| V.2 | Bảng ma trận đánh đổi (Trade-off Matrix) | Cương | **Bảng đánh đổi toàn diện 5 tiêu chí**: Thông lượng đỉnh, Độ linh hoạt, Chi phí truyền dữ liệu, Độ phức tạp phát triển, Kích thước bài toán tối ưu. | |
| V.3 | Trả lời dứt khoát Câu hỏi 4 | Cương | Phân tích sâu sắc bài toán đánh đổi giữa Tính linh hoạt (CPU) và Hiệu suất cao (Systolic/GPU). | |
| V.4 | Phân tích các hạn chế của đồ án | Cương | Sự khác biệt giữa đo thực tế (ms) và mô phỏng chu kỳ; sự khác biệt kiểu số `float32` vs `int16`; biến động GPU trên Colab. | |
| V.5 | Kết luận chung & Bài học kinh nghiệm | Cương | Tóm tắt 3 kết luận then chốt của toàn bộ đồ án. | |
| V.6 | Hướng phát triển mở rộng | Cương | Mở rộng kiểu dữ liệu (FP8/BF16), tích hợp DMA/double buffering, triển khai board FPGA thực tế. | |
| | **Tài liệu tham khảo** | **Khương** | Định dạng chuẩn IEEE/ACM, trích dẫn tài liệu kiến trúc máy tính, bài báo Google TPU, tài liệu CUDA. | 1 trang |
| | **Phụ lục** | **Khương** | Link repo GitHub, cấu hình máy các thành viên (`env_*.json`), toàn văn bảng số liệu CSV gốc, hướng dẫn tái lập kết quả. | 2 trang |

---

## 5. Phân công Slide (Canva) & Thuyết trình

- **Nền tảng làm slide:** Soạn thảo chung trên **[Canva Slide Nhóm 15](https://canva.link/r64u2jb5pdawwcw)**.
- **Quy tắc phân công slide vs thuyết trình:**
  - Mỗi thành viên tự thiết kế cụm slide tương ứng với phần báo cáo của mình.
  - **Lưu ý đặc biệt ở Phần IV (Systolic Array):** **Huy làm slide** (vì Huy nắm rõ cấu trúc phần cứng và waveform), **Nam và Cương trình bày thay Huy** trước hội đồng.

| Lượt | Nội dung trình bày | Người làm Slide (Canva) | Người thuyết trình | Khối lượng tương ứng |
|---|---|---|---|---|
| **1** | **Phần I:** Bối cảnh, mục tiêu, metrics, CPU nền (naive & tiled) | **Nam** | **Nam** | 3–4 trang báo cáo |
| **2** | **Phần II:** CPU tối ưu OpenMP, SIMD, Ablation study (Câu 1) | **Khương** | **Khương** | 3–4 trang báo cáo |
| **3** | **Phần III:** GPU CUDA, cuBLAS, chi phí copy PCIe, điểm hòa vốn $N^*$ (Câu 2) | **Long** | **Long** | 3–4 trang báo cáo |
| **4** | **Phần IV.1–IV.2:** Ý tưởng Systolic, luồng dữ liệu Weight-Stationary, thiết kế PE & mảng 8×8 | **Huy** | **Nam**  | ~1.5–2 trang báo cáo |
| **5** | **Phần IV.3–IV.6:** Testbench, waveform GTKWave, chu kỳ $C(N)$, utilization (Câu 3) | **Huy** | **Cương** | ~1.5–2 trang báo cáo |
| **6** | **Phần V:** Bảng ma trận đánh đổi 3 kiến trúc, hạn chế, kết luận chung (Câu 4) | **Cương** | **Cương** | 2–3 trang báo cáo |
| **7** | **Hỏi đáp (Q&A):** Trả lời câu hỏi của giảng viên và hội đồng phản biện | Cả nhóm | Người phụ trách phần được hỏi | Toàn bộ đồ án |

---

## 6. Cấu trúc thư mục mã nguồn Repo

```
projectKTMT/
├── README.md                          # Trang chủ: Tổng quan, mục lục chi tiết, phân công
├── HUONG-DAN-QUY-TRINH-NHOM.md        # Hướng dẫn Git, quy trình nhóm, lịch trình & DoD
├── METRICS.md                         # Chuẩn hóa công thức và schema các file CSV kết quả
├── Ly_thuyet_can_thiet_MI4344.pdf     # Tài liệu lý thuyết kiến trúc máy tính nền tảng (12 trang)
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

## 7. Bắt đầu làm việc

- **GitHub Repository:** https://github.com/ndh-mi1/projectKTMT
- **Báo cáo chung (Google Docs):** https://docs.google.com/document/d/1TXFgWydyJ7rMBT3fG0oTWzDbLhph4TGgAmQufeilvIE/edit?usp=sharing
- **Slide thuyết trình (Canva):** https://canva.link/r64u2jb5pdawwcw

1. Đọc kỹ tài liệu lý thuyết [Ly_thuyet_can_thiet_MI4344.pdf](Ly_thuyet_can_thiet_MI4344.pdf).
2. Đọc [HUONG-DAN-QUY-TRINH-NHOM.md](HUONG-DAN-QUY-TRINH-NHOM.md) để nắm quy trình pull/commit/push an toàn và phân quyền module.
3. Đọc file `README.md` trong thư mục module của mình (`cpu/`, `gpu/`, `systolic/`, `scripts/`) để bắt đầu xây dựng mã nguồn và kiểm thử.
4. Ghi kết quả đo đạc vào file CSV riêng theo chuẩn quy định tại [METRICS.md](METRICS.md).
