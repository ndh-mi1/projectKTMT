# Hướng dẫn quy trình làm việc — Nhóm 15

Đề tài: **So sánh hiệu năng CPU, GPU và Systolic Array trên bài toán nhân ma trận (MI4344).**  

---

## Link làm việc chung

| Loại | Link / Địa chỉ | Quyền hạn & Ghi chú |
|---|---|---|
| **Google Docs (Báo cáo)** | https://docs.google.com/document/d/1TXFgWydyJ7rMBT3fG0oTWzDbLhph4TGgAmQufeilvIE/edit?usp=sharing | **Anyone with the link, Editor** |
| **Canva (Slide)** | https://canva.link/r64u2jb5pdawwcw | **Can edit** |
| **GitHub repo (Public)** | https://github.com/ndh-mi1/projectKTMT | Public repo, cả 5 thành viên có quyền Collaborators |
| **Nộp bài & Lịch thuyết trình (MS Teams)** | Kênh lớp MI4344 — xem `GroupProject_381.xlsx` | Nộp bản mềm qua Teams **trước 24/12/2026** |

---

## Phân vai thành viên

| Thành viên | MSSV | Module phụ trách | Trách nhiệm báo cáo (Chuẩn hóa theo đề cương) | Phân công thuyết trình (30p + 15p Q&A) |
|---|---|---|---|---|
| **Trịnh Nhật Nam** | 202418949 | `cpu/` | Chủ trì **Chương 1 (Giới thiệu)** + phần **CPU nền** (Chương 2–3) | Lượt 1: Giới thiệu, Yêu cầu & CPU nền |
| **Lê Duy Khương** | 202418926 | `cpu/` | Phần **CPU tối ưu** (Chương 2–3); **Gom bài, chuẩn hóa APA & IEEE `[1]`, xuất PDF nộp** | Lượt 2: Tối ưu CPU & Demo `bench_cpu` |
| **Nguyễn Hoàng Long** | 202418938 | `gpu/` | Phần **GPU CUDA & cuBLAS** (Chương 2–3) | Lượt 3: Tăng tốc GPU & Demo Colab |
| **Nguyễn Đình Huy** | 202418918 | `systolic/`, `docs/` | **Trưởng nhóm:** Phần **Systolic Array Verilog HDL** (Chương 2–3), **Trang đóng góp** & **Phụ lục Kế hoạch** | Lượt 4: Systolic Array HDL, Lý do 8×8 & Demo RTL/GTKWave |
| **Nguyễn Thanh Cương** | 202418857 | `scripts/` | Tổng hợp công cụ, **Ma trận đánh đổi 3 kiến trúc**, Hạn chế & Kết luận (Chương 2–3) | Lượt 5: So sánh chéo, Lý do phạm vi & Kết luận |

---

## Các tài liệu trong repo

| File | Mục đích sử dụng |
|---|---|
| **[README.md](README.md)** | Trang chủ: Tổng quan, Yêu cầu, Mục lục báo cáo chuẩn APA/IEEE, Phân công thuyết trình 45p, Cấu trúc repo. |
| **[HUONG-DAN-QUY-TRINH-NHOM.md](HUONG-DAN-QUY-TRINH-NHOM.md)** | File này: Hướng dẫn Git, Phân quyền, Chuẩn APA & IEEE, Slide Demo, Lịch trình Tuần 13–18 & Checklist nộp Teams. |
| **[METRICS.md](METRICS.md)** | Quy chuẩn tính toán FLOPs, GFLOPS, chu kỳ và schema các cột CSV (bắt buộc tuân thủ khi xuất kết quả). |
| **[Ly_thuyet_can_thiet_MI4344.pdf](Ly_thuyet_can_thiet_MI4344.pdf)** | Tài liệu lý thuyết kiến trúc máy tính 12 trang (đọc trước khi bắt tay vào code). |
| **[docs/KE-HOACH-LAM-VIEC-NHOM.md](docs/KE-HOACH-LAM-VIEC-NHOM.md)** | Bản Kế hoạch làm việc chi tiết Tuần 1–18 của Nhóm 15 (sẵn sàng chép vào **Phụ lục A** của báo cáo). |
| **[docs/MAU-BAO-CAO-APA-IEEE.md](docs/MAU-BAO-CAO-APA-IEEE.md)** | Khung mẫu **1–2 trang Tóm tắt đóng góp**, hướng dẫn định dạng **APA** & danh mục trích dẫn **IEEE `[1]`**. |
| **README trong từng module** | `cpu/README.md`, `gpu/README.md`, `systolic/README.md`, `scripts/README.md` hướng dẫn code, test và xuất số liệu. |

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
├── README.md                          Huy       trang chủ (mục lục APA/IEEE, phân công)
├── HUONG-DAN-QUY-TRINH-NHOM.md        Huy       file này
├── METRICS.md                         Chỉ đọc   chuẩn cột CSV và công thức
├── Ly_thuyet_can_thiet_MI4344.pdf     Chỉ đọc   tài liệu lý thuyết nền tảng
│
├── docs/                              Huy       tài liệu kế hoạch & mẫu chuẩn APA/IEEE
│   ├── KE-HOACH-LAM-VIEC-NHOM.md      Huy       kế hoạch Tuần 1-18 (cho Phụ lục A)
│   └── MAU-BAO-CAO-APA-IEEE.md        Huy       mẫu trang đóng góp & hướng dẫn APA/IEEE
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
| **Huy** | toàn bộ `systolic/`, `docs/`; `results/systolic_cycles.csv`, `results/env_huy.json`; `README.md`, `HUONG-DAN-QUY-TRINH-NHOM.md`, `METRICS.md`, `.gitignore` | `cpu/`; `gpu/` |
| **Cương** | `scripts/`; `results/plots/`; `results/env_cuong.json` | `cpu/`; `gpu/`; `systolic/`; các file CSV của người khác (chỉ đọc) |

## 1.5. Tình huống thường gặp & Cách xử lý
| Hiện tượng | Nguyên nhân | Cách khắc phục |
|---|---|---|
| `git push` bị `rejected ... fetch first` | Có bạn khác vừa đẩy code lên GitHub trước. | Chạy `git pull` để nhận code về trước, sau đó chạy lại `git push`. |
| `git pull` báo `CONFLICT` | Hai người cùng sửa vào một dòng code trong cùng 1 file. | **Dừng lại, không xóa bừa.** Lệnh hủy an toàn: `git rebase --abort`. Chụp ảnh màn hình gửi nhóm hoặc nhắn Huy hỗ trợ gỡ. |
| Lỡ sửa nhầm file của người khác | Chưa commit | Chạy `git restore <đường-dẫn-file>` để hoàn tác. |
| Lỡ `git add` nhầm file | Chưa commit | Chạy `git restore --staged <đường-dẫn-file>` để bỏ khỏi danh sách chờ. |
| `Permission denied (403)` khi push | Chưa chấp nhận lời mời làm Collaborator | Mở email kiểm tra thư mời từ GitHub và bấm **Accept invitation**. |


# 2. Hướng dẫn viết Báo cáo cuối kỳ chuẩn APA & IEEE (Google Docs)

Link làm việc: https://docs.google.com/document/d/1TXFgWydyJ7rMBT3fG0oTWzDbLhph4TGgAmQufeilvIE/edit?usp=sharing

## 2.1. Quy tắc viết bài, Định dạng APA & Trích dẫn IEEE
1. **Định dạng chuẩn APA ([APA Paper Format](https://apastyle.apa.org/style-grammar-guidelines/paper-format)):**
   - **Lề & Font chữ:** Căn lề **1 inch (2.54 cm)** cả 4 cạnh; sử dụng thống nhất font **Times New Roman 12pt** (code dùng font `Consolas` / `Courier New` 10pt); đánh số trang góc trên bên phải bắt đầu từ trang bìa.
   - **Giãn dòng & Đoạn văn:** Toàn văn bản dùng khoảng cách dòng nhất quán theo chuẩn APA (chi tiết định dạng Title Page, Heading Level 1–3, căn chỉnh Bảng & Hình xem tại [`docs/MAU-BAO-CAO-APA-IEEE.md`](docs/MAU-BAO-CAO-APA-IEEE.md)).
   - **Bảng và Hình theo APA:** Số thứ tự và tên Bảng (`Bảng 1`, *Tên bảng*) / Hình (`Hình 1`, *Tên hình*) đặt gọn phía trên trước Bảng/Hình, có nguồn/ghi chú (*Note.*) bên dưới nếu cần.
2. **Trích dẫn & Tài liệu tham khảo chuẩn IEEE ([IEEE Citation Guide](https://pitt.libguides.com/citationhelp/ieee)):**
   - Dùng kiểu **đánh số trong ngoặc vuông `[1]`, `[2]`** tăng dần theo **đúng thứ tự xuất hiện lần đầu** trong văn bản (ví dụ: *"Kiến trúc Systolic Array được Kung và Leiserson đề xuất năm 1982 [1]."*).
   - Mục **Tài liệu tham khảo** liệt kê theo thứ tự số `[1]`, `[2]`... Không dùng trích dẫn kiểu `(Author, Year)` của APA cho tài liệu tham khảo.
3. **BẮT BUỘC có 1–2 trang Tóm tắt đóng góp thành viên:** Đặt ngay đầu báo cáo (trước nội dung chính), mô tả đóng góp từng người **theo thứ tự từ cao đến thấp** (dùng mẫu trong `docs/MAU-BAO-CAO-APA-IEEE.md`).
4. **Độc lập, trung thực số liệu & Góp ý văn minh:** Mỗi bạn viết đúng phần mình trên Docs; mọi con số phải lấy trực tiếp từ `results/*.csv`; góp ý phần bạn khác dùng chế độ **Suggesting** hoặc **Comment**.
5. **Trách nhiệm của Khương (Gom bài):** Kiểm tra chuẩn hóa APA toàn bài, hợp nhất đánh số `[1], [2]` của Tài liệu tham khảo, đánh số Heading/Hình/Bảng thống nhất và xuất bản PDF + DOCX nộp cuối cùng.

## 2.2. Cấu trúc Mục lục Báo cáo cuối kỳ (Khớp 100% yêu cầu Giảng viên)
*(Được đồng bộ chuẩn xác 100% với Mục 4 trong README.md)*

| Mục | Tiêu đề chuẩn Báo cáo cuối kỳ | Người viết | Nội dung trọng tâm & Ánh xạ kỹ thuật |
|---|---|---|---|
| **Đầu bài** | **Trang bìa chuẩn APA, Mục lục, Danh mục Hình/Bảng** | **Khương** | Title page chuẩn APA + HUST; mục lục tự động sinh từ Heading. |
| **Bắt buộc (1–2 trang)** | **Tóm tắt đóng góp của từng thành viên (từ cao đến thấp)** | **Huy & Khương** *(cả nhóm chốt)* | **Đặt trước nội dung chính:** Xếp hạng đóng góp từ cao đến thấp; mô tả vai trò, code/RTL, đo đạc/mô phỏng, viết báo cáo & thuyết trình. |
| **Tóm tắt** | **Tóm tắt (Abstract)** | **Khương** | Tóm tắt 5–7 câu về mục tiêu, phương pháp, kết quả chính và kết luận. |
| **Chương 1** | **GIỚI THIỆU** *(Phần I cũ)* | **Nam** *(+ Huy rà soát Systolic)* | • **1.1 Tên & Mô tả dự án:** Tổng quan bài toán nhân ma trận trên 3 kiến trúc (CPU, GPU, và phần cứng Systolic Array thiết kế/mô hình hóa/mô phỏng).<br>• **1.2 Đề tài, Bối cảnh & 4 câu hỏi nghiên cứu:** Nút thắt Memory Wall ($2N^3$ FLOPs vs $2N^2$ phần tử) và 4 câu hỏi nghiên cứu.<br>• **1.3 Các yêu cầu của dự án:** Yêu cầu chức năng, độ chính xác (`float32` $\le 10^{-3}$, `int16` bit-exact), dải $N$ và lý do phạm vi triển khai.<br>• **1.4 Cơ sở lý thuyết đo đạc:** Công thức FLOPs, GFLOPS, Cycles, Utilization, quy tắc so sánh công bằng. |
| **Chương 2** | **PHƯƠNG PHÁP LUẬN** *(Kiến trúc, HDL & Công cụ triển khai)* | **Theo module** | • **2.1 Tổng quan cấu trúc & Công cụ lựa chọn (Cương + Huy):** Kiến trúc tổng thể sản phẩm, lựa chọn ngôn ngữ/công cụ (`C11/gcc/OpenMP/AVX2`, `CUDA/cuBLAS`, **Verilog HDL + `iverilog`/`GTKWave`**, `Python`) và lý do triển khai một phần/toàn bộ.<br>• **2.2 Thiết kế & Tối ưu trên CPU (Nam & Khương):** Cấu trúc Naive, Cache Tiling, OpenMP, SIMD AVX2/FMA ($i-k-j$) và harness `bench_main.c`.<br>• **2.3 Thiết kế & Tăng tốc trên GPU (Long):** Mô hình SIMT, Kernel CUDA naive, `cuBLAS`, đo `cudaEvent_t` ($T_{\text{H2D}}/T_{\text{kernel}}/T_{\text{D2H}}$).<br>• **2.4 Thiết kế phần cứng Systolic Array bằng Verilog HDL (Huy — *tương ứng Mục IV.1–IV.2*):** Luồng Weight-Stationary, lý do $8 \times 8$, vi kiến trúc PE (`pe.v`), ghép lưới 2D (`systolic_array.v`), Data Skewing & Wavefront.<br>• **2.5 Phương pháp tổng hợp & Đánh giá chéo (Cương):** Pipeline đọc CSV (`scripts/`) & khung Trade-off Matrix 5 tiêu chí. |
| **Chương 3** | **KẾT QUẢ VÀ BÀN LUẬN** *(Thực nghiệm, Mô phỏng & Đánh giá)* | **Theo module** | • **3.1 Kết quả & Phân tích CPU (Nam & Khương — *Câu 1*):** Bảng & đồ thị Naive vs Tiled ($N \in [64, 2048]$), bảng Ablation Study & Speedup.<br>• **3.2 Kết quả & Phân tích GPU (Long — *Câu 2*):** Bảng $T_{\text{kernel}}$ vs $T_{\text{E2E}}$ trên Colab Tesla T4, đồ thị log-log GPU vs CPU, điểm hòa vốn $N^*_{\text{kernel}}, N^*_{\text{E2E}}$.<br>• **3.3 Kết quả mô phỏng RTL & Chu kỳ Systolic (Huy — *tương ứng Mục IV.3–IV.6, Câu 3*):** Testbench `tb_systolic.v`, đối chiếu bit-exact `matmul_ref.py`, **ảnh sóng GTKWave**, mô hình $C(N)$ & Utilization, *(tùy chọn)* ước lượng Vivado.<br>• **3.4 So sánh chéo & Trade-off Matrix 3 kiến trúc (Cương — *Câu 4*):** Bảng tổng hợp, Ma trận đánh đổi 5 tiêu chí, phân tích Linh hoạt $\leftrightarrow$ Hiệu suất.<br>• **3.5 Đánh giá làm chủ công cụ, Hạn chế & Hướng mở rộng (Cương + nhóm):** Chứng minh làm chủ công nghệ/công cụ, các hạn chế thực nghiệm và hướng phát triển. |
| **Tham khảo** | **TÀI LIỆU THAM KHẢO** | **Khương** *(cả nhóm gửi)* | Danh mục đầy đủ trích dẫn theo **IEEE numerical citation style** (`[1]`, `[2]`...). |
| **Phụ lục** | **PHỤ LỤC** | **Huy & Khương** | • **Phụ lục A (Bắt buộc):** **Kế hoạch làm việc của nhóm** (chép từ `docs/KE-HOACH-LAM-VIEC-NHOM.md`).<br>• **Phụ lục B:** Cấu hình phần cứng các thành viên (`env_*.json`).<br>• **Phụ lục C:** Link GitHub, toàn văn CSV gốc & Hướng dẫn tái lập kết quả. |


# 3. Hướng dẫn làm Slide (Canva) & Thuyết trình (~45 phút)

Link làm việc: https://canva.link/r64u2jb5pdawwcw

## 3.1. Quy chuẩn thiết kế slide & 4 yêu cầu bắt buộc
- **Thời lượng & Hình thức:** **~45 phút** gồm **30 phút trình bày** + **15 phút trao đổi (Q&A)**; lịch trình bày xem trong `GroupProject_381.xlsx` trên Teams. **100% thành viên (5/5) đều phải trình bày.**
- **Bốn nội dung BẮT BUỘC phải xuất hiện trong Slide & Lời nói:**
  1. **Bối cảnh và chủ đề của dự án.**
  2. **Bài toán và các giải pháp.**
  3. **Lý do triển khai toàn bộ hoặc một phần sản phẩm** *(giải thích rõ tại sao chỉ triển khai RTL lõi $8 \times 8$ WS mô phỏng trên Icarus chứ không làm full chip TPU/DMA hay board FPGA; và phạm vi thực nghiệm CPU/GPU).*
  4. **Trình bày / mô phỏng sản phẩm (Demo):** Chạy/minh họa thực tế chương trình C CPU, Colab GPU và **chạy mô phỏng `iverilog` + xem sóng GTKWave / minh họa luồng Systolic Array**.
- **Trực quan & Đồng nhất:** Mỗi slide tối đa **3 ý chính** kèm 1 hình/bảng/đồ thị; thống nhất bảng màu và font chữ; đặt tên người phụ trách ở góc dưới slide.

## 3.2. Bảng phân công chi tiết giữa Làm Slide và Thuyết trình
*(Được đồng bộ chuẩn xác 100% với Mục 5 trong README.md)*

| Lượt | Nội dung trình bày | Người làm Slide & Thuyết trình | Trọng tâm & Demo sản phẩm |
|---|---|---|---|
| **1** | **Giới thiệu, Yêu cầu & CPU nền** | **Nam** | Bối cảnh, chủ đề, 3 kiến trúc thiết kế/mô hình/mô phỏng, yêu cầu, metrics, Naive vs Tiled. |
| **2** | **Tối ưu hóa CPU (Câu 1)** | **Khương** | OpenMP, SIMD AVX2/FMA ($i-k-j$), Ablation Study, **demo biên dịch/chạy `bench_cpu`**. |
| **3** | **Tăng tốc GPU (Câu 2)** | **Long** | SIMT CUDA naive vs `cuBLAS`, $T_{\text{H2D}}/T_{\text{kernel}}/T_{\text{D2H}}$, điểm hòa vốn $N^*$, **demo Notebook Colab**. |
| **4** | **Systolic Array Verilog HDL (Câu 3)** | **Huy** | Dataflow WS, lý do triển khai mảng $8 \times 8$, PE & lưới 2D, Skewing, **demo `iverilog` + GTKWave**, chu kỳ $C(N)$. |
| **5** | **So sánh chéo, Lý do phạm vi & Kết luận (Câu 4)** | **Cương** | Tổng hợp 3 nền tảng, Trade-off Matrix 5 tiêu chí, lý do phạm vi triển khai một phần, hạn chế & kết luận. |
| **6** | **Hỏi đáp (Q&A — 15 phút)** | **Cả nhóm** | Thành viên phụ trách phần nào chủ động trả lời phản biện câu hỏi của Giảng viên và lớp. |


# 4. Lịch trình Tuần 13–18, Definition of Done & Checklist Nộp MS Teams

## 4.1. Lịch trình thực hiện giai đoạn nước rút (25/11/2026 – 30/12/2026)

| Tuần | Mốc thời gian | Công việc trọng tâm | Người chịu trách nhiệm |
|---|---|---|---|
| **Tuần 13** | 25/11 – 01/12/2026 | • **Nam** hoàn thiện và push `matmul.h`, `matmul_naive.c`, `matmul_tiled.c`, `bench_main.c`, `Makefile`, chạy đo `cpu_bench.csv`.<br>• **Khương** chạy đo `cpu_opt_bench.csv`.<br>• **Huy** hoàn thành Mục IV.3–IV.4 (`matmul_ref.py`, `tb_systolic.v`, chạy `iverilog`/GTKWave, `systolic_cycles.csv`).<br>• Xem lịch thuyết trình chính thức của Nhóm 15 trong `GroupProject_381.xlsx`. | Nam, Khương, Huy |
| **Tuần 14** | 02/12 – 08/12/2026 | • **Long** hoàn thiện code CUDA/Colab notebook, chạy đo `gpu_bench.csv` và push repo.<br>• Cả 5 thành viên push file cấu hình `results/env_<ten>.json`.<br>• **Cương** viết script `scripts/plot_compare.py`, sinh đầy đủ biểu đồ vào `results/plots/`. | Long, Cương, Cả nhóm |
| **Tuần 15** | 09/12 – 15/12/2026 | • Hoàn thành viết đầy đủ nội dung các **Chương 1, 2, 3** và **Phụ lục A–C** trên Google Docs.<br>• Hoàn thiện Slide Canva kèm kịch bản Demo (CPU/GPU/GTKWave) và tổng duyệt thử 45 phút (30p + 15p). | Cả nhóm |
| **Tuần 16** | 16/12 – 20/12/2026 | • Chốt **1–2 trang Tóm tắt đóng góp thành viên (từ cao đến thấp)**.<br>• **Khương** rà soát chuẩn định dạng **APA**, hợp nhất **Tài liệu tham khảo kiểu số IEEE `[1]`**, kiểm tra mục lục và danh mục hình/bảng.<br>• Thuyết trình trước lớp (nếu lịch rơi vào Tuần 13–17 theo `GroupProject_381.xlsx`). | Huy, Khương, Cả nhóm |
| **Tuần 17** | 21/12 – **23/12/2026** | • Đóng gói và rà soát chéo bộ 4 sản phẩm nộp **MS Teams** (đảm bảo nộp **trước ngày 24/12/2026** — tránh sát giờ chót).<br>• Chốt tag hoàn thiện trên GitHub `ndh-mi1/projectKTMT`. | Huy & Khương |
| **Tuần 18** | 24/12 – 30/12/2026 | • **Hạn chót quy định của Khoa/Thầy: trước 24/12/2026.** Dự phòng bổ sung/phản hồi nếu Giảng viên yêu cầu sau khi nộp trên Teams. | Huy & Cả nhóm |

## 4.2. Checklist đóng gói nộp trực tuyến qua MS Teams (TRƯỚC 24/12/2026)

Khi nộp trên Assignment MS Teams, Nhóm trưởng (**Huy**) và **Khương** kiểm tra đủ **4 thành phần bắt buộc** sau:

1. **Báo cáo cuối kỳ (Bản mềm `.pdf` và `.docx`):**
   - [ ] Có **1–2 trang Tóm tắt đóng góp của từng thành viên theo thứ tự từ cao đến thấp** ở đầu báo cáo (trước nội dung chính).
   - [ ] Đủ 5 phần nội dung chuẩn: **Giới thiệu** (tên, mô tả, bài toán/phần cứng thiết kế-mô hình-mô phỏng, yêu cầu) $\to$ **Phương pháp luận** (cấu trúc, chức năng, ngôn ngữ HDL Verilog & công cụ chọn) $\to$ **Kết quả và Bàn luận** (số liệu, đồ thị, GTKWave, phân tích chứng minh làm chủ công nghệ/công cụ) $\to$ **Tài liệu tham khảo** $\to$ **Phụ lục** (có **Kế hoạch làm việc của nhóm**).
   - [ ] Định dạng chuẩn **APA** và trích dẫn/tài liệu tham khảo kiểu đánh số **IEEE `[1]`, `[2]`**.
2. **Slide thuyết trình (Bản mềm `.pdf` / `.pptx` xuất từ Canva):**
   - [ ] Thể hiện đủ 4 ý bắt buộc: Bối cảnh & chủ đề; Bài toán & giải pháp; Lý do triển khai toàn bộ/một phần sản phẩm; Minh họa/mô phỏng sản phẩm.
   - [ ] Đánh dấu tên người phụ trách tương ứng 5/5 thành viên cùng trình bày trong khung 45 phút (30p + 15p).
3. **Mã nguồn (Code):**
   - [ ] Đầy đủ, biên dịch & chạy không lỗi: `cpu/`, `gpu/`, `systolic/` (`pe.v`, `systolic_array.v`, `tb_systolic.v`, `matmul_ref.py`), `scripts/`.
   - [ ] Kèm hướng dẫn chạy & tái lập kết quả rõ ràng (`README.md`, `run_sim.ps1`/`sh`, `Makefile`).
4. **Các tài liệu liên quan:**
   - [ ] Dữ liệu thực nghiệm đầy đủ trong `results/*.csv`, `results/env_*.json`, ảnh biểu đồ `results/plots/*.png`, ảnh chụp sóng GTKWave (và video/HTML mô phỏng minh họa nếu đính kèm).
   - [ ] Link công khai Google Docs, Canva Slide và GitHub Repo `https://github.com/ndh-mi1/projectKTMT`.
