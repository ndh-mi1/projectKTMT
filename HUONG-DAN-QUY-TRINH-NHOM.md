# Hướng dẫn quy trình làm việc — Nhóm 15

Đề tài: **So sánh hiệu năng CPU, GPU và Systolic Array trên bài toán nhân ma trận (MI4344).**  

---

## Link làm việc chung

| Loại | Link | Quyền hạn yêu cầu |
|---|---|---|
| **Google Docs (Báo cáo)** | https://docs.google.com/document/d/1TXFgWydyJ7rMBT3fG0oTWzDbLhph4TGgAmQufeilvIE/edit?usp=sharing | **Anyone with the link, Editor** |
| **Canva (Slide)** | https://canva.link/r64u2jb5pdawwcw | **Can edit** |
| **GitHub repo (Public)** | https://github.com/ndh-mi1/projectKTMT | Public repo, thêm 4 bạn làm Collaborators |

---

## Phân vai thành viên

| Thành viên | MSSV | Module phụ trách | Trách nhiệm báo cáo | Phân công thuyết trình |
|---|---|---|---|---|
| **Trịnh Nhật Nam** | 202418949 | `cpu/` | Viết Phần I | Thuyết trình **Phần I** |
| **Lê Duy Khương** | 202418926 | `cpu/` | Viết Phần II; Gom và xuất bản nộp PDF | Thuyết trình **Phần II** |
| **Nguyễn Hoàng Long** | 202418938 | `gpu/` | Viết Phần III | Thuyết trình **Phần III** |
| **Nguyễn Đình Huy** | 202418918 | `systolic/` | Trưởng nhóm: Viết Phần IV, điều phối | Thuyết trình **Phần IV** |
| **Nguyễn Thanh Cương** | 202418857 | `scripts/` | Viết Phần V | Thuyết trình **Phần V** |


---

## Các tài liệu trong repo

| File | Mục đích sử dụng |
|---|---|
| **[README.md](README.md)** | Trang chủ: Tổng quan đề tài, 4 câu hỏi nghiên cứu, mục lục báo cáo chi tiết 5 phần, phân công thuyết trình, cấu trúc thư mục repo. |
| **[HUONG-DAN-QUY-TRINH-NHOM.md](HUONG-DAN-QUY-TRINH-NHOM.md)** | File này: Hướng dẫn Git thực chiến, phân quyền file, quy chuẩn báo cáo Docs và slide Canva. |
| **[METRICS.md](METRICS.md)** | Quy chuẩn tính toán FLOPs, GFLOPS, chu kỳ và schema các cột CSV (bắt buộc tuân thủ khi xuất kết quả). |
| **[Ly_thuyet_can_thiet_MI4344.pdf](Ly_thuyet_can_thiet_MI4344.pdf)** | Tài liệu lý thuyết kiến trúc máy tính 12 trang (đọc trước khi bắt tay vào code). |
| **README trong từng module** | `cpu/README.md`, `gpu/README.md`, `systolic/README.md`, `scripts/README.md` hướng dẫn cụ thể cách code, test và xuất số liệu. |

---

# 1. Hướng dẫn dùng GitHub

## 1.1. Cài đặt ban đầu 
1. Tải và cài đặt Git cho Windows: https://git-scm.com/download/win.
2. Đăng ký tài khoản GitHub và gửi **Username** cho Huy để được cấp quyền ghi (Collaborator).
3. Mở PowerShell, cấu hình danh tính và bật chế độ pull rebase an toàn:
   ```powershell
   git config --global user.name "Ten Cua Ban"
   git config --global user.email "email@cua.ban"
   git config --global pull.rebase true
   git config --global rebase.autoStash true
   ```
4. Kiểm tra: `git --version` in ra phiên bản là hoàn tất.

## 1.2. Các thành viên clone repo về máy 
Clone vào đường dẫn ngắn, không dấu, **tuyệt đối không nằm trong thư mục OneDrive**:
```powershell
mkdir C:\dev -Force
cd C:\dev
git clone https://github.com/ndh-mi1/projectKTMT.git
cd projectKTMT
```
Mở thư mục `projectKTMT` để bắt đầu làm việc.

## 1.3. Quy trình làm việc 5 bước hằng ngày
Làm đúng thứ tự này mỗi khi ngồi vào làm việc:
```powershell
# Bước 1: Lấy bản mới nhất của nhóm về TRƯỚC KHI sửa code
git pull

# Bước 2: Tự viết code, chạy thử trong module được phân công

# Bước 3: Kiểm tra xem mình đã sửa những file nào
git status
git diff

# Bước 4: Lưu mốc làm việc (CHỈ add file thuộc module của mình)
git add cpu/src/matmul_tiled.c results/cpu_bench.csv
git commit -m "[Nam] xong matmul tiled va do xong N=1024"

# Bước 5: Đẩy lên GitHub
git pull
git push
```

> [!WARNING]
> - **Tuyệt đối không dùng `git add .`** khi chưa xem `git status`, tránh add nhầm file rác hoặc file của bạn khác.
> - Tiền tố commit luôn bắt đầu bằng tên: `[Nam]`, `[Khuong]`, `[Long]`, `[Huy]`, `[Cuong]`.
> - Các lệnh **nghiêm cấm tự ý sử dụng**: `git push --force`, `git reset --hard`, `git clean -fd`.

## 1.4. Cấu trúc repo và Phân quyền chỉnh sửa file

```
projectKTMT/
├── README.md                          Huy       trang chủ (mục lục chi tiết, phân công)
├── HUONG-DAN-QUY-TRINH-NHOM.md        Huy       file này
├── METRICS.md                         Chỉ đọc   chuẩn cột CSV và công thức
├── Ly_thuyet_can_thiet_MI4344.pdf     Chỉ đọc   tài liệu lý thuyết nền tảng
│
├── cpu/                               MODULE CPU (Nam & Khương)
│   ├── README.md                      Nam/Khương hướng dẫn yêu cầu code, build và test
│   ├── include/                       Nam       chứa file interface (matmul.h)
│   └── src/                           Nam & Khương tự code theo phân công
│
├── gpu/                               MODULE GPU: Long (toàn bộ)
│   ├── README.md                      Long      hướng dẫn viết kernel CUDA, cuBLAS
│   ├── src/                           Long      mã nguồn CUDA
│   └── notebooks/                     Long      notebook Colab
│
├── systolic/                          MODULE SYSTOLIC: Huy (toàn bộ)
│   ├── README.md                      Huy       hướng dẫn thiết kế RTL, mô hình chu kỳ
│   ├── rtl/                           Huy       pe.v, systolic_array.v
│   ├── tb/                            Huy       testbench
│   ├── sim/                           Huy       script Icarus (run_sim.ps1, run_sim.sh)
│   └── ref/                           Huy       model tham chiếu int16
│
├── results/                           KẾT QUẢ ĐO: mỗi người một file
│   ├── cpu_bench.csv                  Nam       (naive, tiled)
│   ├── cpu_opt_bench.csv              Khương    (openmp, simd)
│   ├── gpu_bench.csv                  Long
│   ├── systolic_cycles.csv            Huy
│   ├── env.template.json              Chỉ đọc   mẫu thông tin máy
│   ├── env_<ten>.json                 Mỗi người tự tạo từ file mẫu (env_nam.json, ...)
│   └── plots/                         Cương     biểu đồ sinh ra phục vụ báo cáo/slide
│
└── scripts/                           Cương     (scripts vẽ so sánh, requirements.txt)
    ├── README.md                      Cương     hướng dẫn đọc CSV và vẽ biểu đồ
    └── requirements.txt               Chỉ đọc   thư viện Python
```

### Bảng phân quyền chỉnh sửa:
| Thành viên | ĐƯỢC PHÉP sửa | TUYỆT ĐỐI KHÔNG sửa |
|---|---|---|
| **Nam** | `cpu/include/`, `cpu/Makefile`, `cpu/README.md`, `cpu/src/matmul_naive.c`, `matmul_tiled.c`, `bench_main.c`; `results/cpu_bench.csv`, `results/env_nam.json` | `matmul_openmp.c`, `matmul_simd.c` (của Khương); `gpu/`; `systolic/` |
| **Khương** | `cpu/src/matmul_openmp.c`, `cpu/src/matmul_simd.c`; `results/cpu_opt_bench.csv`, `results/env_khuong.json` | các file CPU của Nam; `gpu/`; `systolic/`. Cần sửa file chung (`Makefile`, `bench_main.c`) thì nhắn Nam |
| **Long** | toàn bộ `gpu/`; `results/gpu_bench.csv`, `results/env_long.json` | `cpu/`; `systolic/` |
| **Huy** | toàn bộ `systolic/`; `results/systolic_cycles.csv`, `results/env_huy.json`; `README.md`, `HUONG-DAN-QUY-TRINH-NHOM.md`, `METRICS.md`, `.gitignore` | `cpu/`; `gpu/` |
| **Cương** | `scripts/`; `results/plots/`; `results/env_cuong.json` | `cpu/`; `gpu/`; `systolic/`; các file CSV của người khác (chỉ đọc) |

## 1.5. Tình huống thường gặp & Cách xử lý
| Hiện tượng | Nguyên nhân | Cách khắc phục |
|---|---|---|
| `git push` bị `rejected ... fetch first` | Có bạn khác vừa đẩy code lên GitHub trước. | Chạy `git pull` để nhận code về trước, sau đó chạy lại `git push`. |
| `git pull` báo `CONFLICT` | Hai người cùng sửa vào một dòng code trong cùng 1 file. | **Dừng lại, không xóa bừa.** Lệnh hủy an toàn: `git rebase --abort`. Chụp ảnh màn hình gửi nhóm hoặc nhắn Huy hỗ trợ gỡ. |
| Lỡ sửa nhầm file của người khác | Chưa commit | Chạy `git restore <đường-dẫn-file>` để hoàn tác. |
| Lỡ `git add` nhầm file | Chưa commit | Chạy `git restore --staged <đường-dẫn-file>` để bỏ khỏi danh sách chờ. |
| `Permission denied (403)` khi push | Chưa chấp nhận lời mời làm Collaborator | Mở email kiểm tra thư mời từ GitHub và bấm **Accept invitation**. |


# 2. Hướng dẫn viết báo cáo (Google Docs)

Link làm việc: https://docs.google.com/document/d/1TXFgWydyJ7rMBT3fG0oTWzDbLhph4TGgAmQufeilvIE/edit?usp=sharing

## 2.1. Quy tắc viết bài
1. **Độc lập và tự chủ:** Mỗi thành viên chỉ soạn thảo trong phần được phân công. Sử dụng đúng định dạng Heading 1 (tên phần lớn) và Heading 2 (các tiểu mục con) để Google Docs tự động sinh mục lục chuẩn.
2. **Góp ý văn minh:** Muốn sửa hoặc góp ý phần của bạn khác, bắt buộc dùng chế độ **Suggesting** hoặc đặt **Comment**, không xóa/sửa trực tiếp.
3. **Số liệu thực tế:** Mọi con số đưa vào báo cáo phải trích xuất chính xác từ các file CSV trong `results/`, tuyệt đối không ước lượng cảm tính.
4. **Chèn hình ảnh:** Ảnh giản đồ sóng GTKWave và biểu đồ phân tích lấy từ `results/plots/` chèn trực tiếp vào Docs kèm chú thích (Hình X.Y).
5. **Trách nhiệm của Khương (Gom bài):** Khương phụ trách trang bìa, mục lục, tóm tắt, chuẩn hóa font chữ/căn lề toàn bài, đánh số thứ tự hình/bảng nhất quán và xuất file PDF nộp. Khương không viết hộ nội dung kỹ thuật của người khác.

## 2.2. Cấu trúc mục lục báo cáo chi tiết & Phân chia viết bài
*(Được đồng bộ chuẩn xác 100% với Mục 4 trong README.md)*

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

# 3. Hướng dẫn làm Slide (Canva) & Phân công thuyết trình

Link làm việc: https://canva.link/r64u2jb5pdawwcw

## 3.1. Quy chuẩn thiết kế slide
- **Thời lượng bảo vệ quy định:** **30 phút trình bày** + **15 phút trao đổi (Q&A)**.
- **Nội dung súc tích:** Slide là bản tóm lược trực quan của báo cáo, không copy nguyên cả đoạn văn dài. Mỗi slide tối đa **3 ý chính** kết hợp cùng 1 biểu đồ hoặc bảng số liệu.
- **Tính đồng nhất:** Cả nhóm dùng chung font chữ, cỡ chữ tiêu đề/nội dung và bảng màu (palette). Khương hoặc Cương thiết kế mẫu slide mở đầu, các bạn khác follow theo.
- **Ghi danh:** Đặt tên người phụ trách ở góc dưới slide để thuận tiện theo dõi khi bảo vệ.
- **Tự chủ:** Của ai người đó tự làm slide và tự thuyết trình bảo vệ phần mình phụ trách trước hội đồng.

## 3.2. Bảng phân công chi tiết giữa Làm Slide và Thuyết trình
*(Được đồng bộ chuẩn xác 100% với Mục 5 trong README.md)*

| Lượt | Nội dung trình bày | Người làm Slide (Canva) | Người thuyết trình | Trọng tâm nội dung |
|---|---|---|---|---|
| **1** | **Phần I:** Bối cảnh, mục tiêu, metrics, CPU nền (naive & tiled) | **Nam** | **Nam** | Memory Wall, công thức metrics, đo đạc baseline CPU |
| **2** | **Phần II:** CPU tối ưu OpenMP, SIMD, Ablation study (Câu 1) | **Khương** | **Khương** | Khai thác đa lõi, vector hóa AVX2, trả lời Câu hỏi 1 |
| **3** | **Phần III:** GPU CUDA, cuBLAS, chi phí copy PCIe, điểm hòa vốn $N^*$ (Câu 2) | **Long** | **Long** | Xử lý song song SIMT, bóc tách thời gian PCIe vs Kernel, trả lời Câu hỏi 2 |
| **4** | **Phần IV:** Systolic Array chuyên dụng mảng 8×8 WS (Câu 3) | **Huy** | **Huy** | Vi kiến trúc PE, mảng 8×8, skewing, waveform GTKWave, chu kỳ $C(N)$, trả lời Câu hỏi 3 |
| **5** | **Phần V:** Bảng ma trận đánh đổi 3 kiến trúc, hạn chế, kết luận chung (Câu 4) | **Cương** | **Cương** | Trade-off Matrix toàn diện 5 tiêu chí, hạn chế thực nghiệm, trả lời Câu hỏi 4 |
| **6** | **Hỏi đáp (Q&A - 15 phút):** Trao đổi & phản biện với Hội đồng | Cả nhóm | Người phụ trách phần được hỏi | Toàn bộ đồ án |

