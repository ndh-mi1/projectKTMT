# Kế hoạch Làm việc của Nhóm 15 — Đồ án MI4344 (Kỳ 20261)

> **Tài liệu này phục vụ trực tiếp cho Mục "Phụ lục A: Kế hoạch làm việc của nhóm" trong Báo cáo cuối kỳ** (theo yêu cầu Giảng viên) và làm bảng theo dõi điều phối thực tế từ Tuần 1 đến Tuần 18 (hạn nộp MS Teams: **trước 24/12/2026**).

---

## 1. Thông tin chung & Mục tiêu dự án

- **Học phần:** Kiến trúc Máy tính (MI4344) — Viện/Khoa Toán-Tin (FaMI), Đại học Bách Khoa Hà Nội.
- **Tên dự án:** *Thiết kế, mô hình hóa và đánh giá hiệu năng ba kiến trúc tính toán (CPU, GPU và Systolic Array) trên bài toán nhân ma trận.*
- **Kho mã nguồn:** https://github.com/ndh-mi1/projectKTMT
- **Báo cáo (Google Docs):** https://docs.google.com/document/d/1TXFgWydyJ7rMBT3fG0oTWzDbLhph4TGgAmQufeilvIE/edit?usp=sharing
- **Slide (Canva):** https://canva.link/r64u2jb5pdawwcw

---

## 2. Phân rã công việc (WBS) & Phân công trách nhiệm

| Mã gói việc | Hạng mục công việc | Đầu ra (Deliverables) | Phụ trách chính | Phối hợp / Kiểm tra |
|---|---|---|---|---|
| **WBS-1** | **Khởi tạo khung dự án, lý thuyết & quy trình Git** | Repo GitHub, `README.md`, `METRICS.md`, `HUONG-DAN-QUY-TRINH-NHOM.md`, `Ly_thuyet_can_thiet_MI4344.pdf`, `docs/` | **Nguyễn Đình Huy** *(Leader)* | Cả nhóm |
| **WBS-2** | **Module CPU nền & Harness đo đạc** | `cpu/include/matmul.h`, `matmul_naive.c`, `matmul_tiled.c`, `bench_main.c`, `Makefile`, `results/cpu_bench.csv`, `env_nam.json` | **Trịnh Nhật Nam** | Lê Duy Khương |
| **WBS-3** | **Module CPU tối ưu & Ablation Study** | `cpu/src/matmul_openmp.c`, `matmul_simd.c`, `results/cpu_opt_bench.csv`, `env_khuong.json` | **Lê Duy Khương** | Trịnh Nhật Nam |
| **WBS-4** | **Module GPU (CUDA & cuBLAS trên Colab)** | `gpu/src/*.cu`, `gpu/notebooks/*.ipynb`, `results/gpu_bench.csv`, `env_long.json` | **Nguyễn Hoàng Long** | Nguyễn Thanh Cương |
| **WBS-5** | **Module Systolic Array (Verilog HDL & Mô phỏng)** | `systolic/rtl/{pe.v, systolic_array.v}`, `tb/tb_systolic.v`, `ref/matmul_ref.py`, sóng GTKWave, mô hình $C(N)$, `results/systolic_cycles.csv`, `env_huy.json` | **Nguyễn Đình Huy** | Cả nhóm |
| **WBS-6** | **Phân tích tổng hợp, Vẽ đồ thị & Trade-off** | `scripts/plot_compare.py`, ảnh đồ thị trong `results/plots/`, Bảng đánh đổi 3 kiến trúc, `env_cuong.json` | **Nguyễn Thanh Cương** | Nguyễn Đình Huy |
| **WBS-7** | **Báo cáo cuối kỳ chuẩn APA & IEEE** | File PDF/DOCX hoàn chỉnh trên Google Docs (kèm 1–2 trang Tóm tắt đóng góp, Chương 1–3, Tham khảo IEEE, Phụ lục A–C) | **Lê Duy Khương** *(biên tập & xuất PDF)* | 5/5 thành viên tự viết phần mình |
| **WBS-8** | **Slide Canva, Demo & Thuyết trình (45p)** | Slide Canva hoàn chỉnh, kịch bản Demo (CPU/GPU/GTKWave), 5/5 thành viên trình bày (30p + 15p Q&A) | **Cả nhóm (5/5)** | Nguyễn Đình Huy điều phối |

---

## 3. Lộ trình thực hiện theo giai đoạn (Timeline)

| Giai đoạn | Mốc thời gian | Hoạt động chính | Tiêu chí hoàn thành (DoD) |
|---|---|---|---|
| **GĐ 1: Khởi tạo & Thiết kế khung** | Tuần 10–11 *(08/11 – 12/11/2026)* | - Dựng khung repo GitHub, chuẩn hóa công thức & CSV schema (`METRICS.md`).<br>- Thống nhất 4 câu hỏi nghiên cứu và kiến trúc $8 \times 8$ Weight-Stationary.<br>- Huy hoàn thành RTL [`pe.v`](../systolic/rtl/pe.v) và [`systolic_array.v`](../systolic/rtl/systolic_array.v); Khương hoàn thành [`matmul_openmp.c`](../cpu/src/matmul_openmp.c) và [`matmul_simd.c`](../cpu/src/matmul_simd.c).<br>- Chuẩn hóa phân công thuyết trình 100% thành viên (30p + 15p). | Repo vận hành ổn định, RTL biên dịch 0 lỗi trên `iverilog -g2012`. |
| **GĐ 2: Hoàn thiện Code, Testbench & Thu thập số liệu** | **Tuần 13–14** *(25/11 – 08/12/2026)* | - Rà soát 100% cấu trúc báo cáo & slide theo hướng dẫn Tuần 13–18 của Giảng viên.<br>- Nam đẩy code CPU nền + harness; Nam & Khương xuất `cpu_bench.csv`, `cpu_opt_bench.csv`.<br>- Huy hoàn thành `matmul_ref.py`, `tb_systolic.v`, mô phỏng `iverilog`/GTKWave, xuất `systolic_cycles.csv`.<br>- Long hoàn thành CUDA/Colab, xuất `gpu_bench.csv`.<br>- Đẩy đủ 5 file `results/env_*.json`. | Đủ 100% mã nguồn chạy ổn định và 4 file CSV kết quả hợp lệ. |
| **GĐ 3: Vẽ biểu đồ & Hoàn thiện Báo cáo APA/IEEE** | **Tuần 15–16** *(09/12 – 20/12/2026)* | - Cương hoàn thành script phân tích và xuất toàn bộ đồ thị vào `results/plots/`.<br>- 5 thành viên viết xong các mục thuộc Chương 1, 2, 3 và Phụ lục trên Google Docs.<br>- Thống nhất bảng xếp hạng **1–2 trang Tóm tắt đóng góp thành viên (từ cao đến thấp)**.<br>- Khương kiểm tra chuẩn **APA**, thống nhất trích dẫn số **IEEE `[1]`**, kiểm tra mục lục và danh mục hình/bảng.<br>- Hoàn thiện Slide Canva + tổng duyệt thuyết trình 45 phút + Demo. | Bản thảo báo cáo đạt 100% tiêu chí định dạng APA/IEEE; slide sẵn sàng bảo vệ. |
| **GĐ 4: Thuyết trình & Nộp hồ sơ MS Teams** | **Tuần 13–18** *(Theo lịch Excel & **trước 24/12/2026**)* | - Bảo vệ trực tiếp trước lớp & Giảng viên theo lịch trong `GroupProject_381.xlsx` (30p trình bày + 15p Q&A).<br>- Kiểm tra đủ 4 thành phần bản mềm (Slide, Báo cáo cuối kỳ, Mã nguồn, Tài liệu liên quan) và nộp qua **MS Teams trước ngày 24/12/2026**. | Nộp bài đúng hạn trên Teams, bảo vệ hoàn tất. |

---

## 4. Quy chế phối hợp & Kiểm soát chất lượng

1. **Quản lý mã nguồn (GitHub):** Phân quyền tách biệt theo từng module (`cpu/`, `gpu/`, `systolic/`, `scripts/`), mọi file CSV đo đạc tách riêng theo từng người, bắt buộc `git pull --rebase` trước khi `git push` để tránh xung đột.
2. **Đảm bảo tính tái lập (Reproducibility):** Mọi kết quả thực nghiệm phải đi kèm file thông số phần cứng `results/env_<ten>.json`, thực hiện lặp $\ge 5$ lần lấy trung vị (`float32`), và kiểm chứng bit-exact với Python đối với Systolic Array (`int16`/`int32`).
3. **Kiểm soát tiến độ hằng tuần:** Nhóm trưởng (Huy) kiểm tra trạng thái commit và tiến độ Google Docs vào cuối mỗi tuần trong giai đoạn Tuần 13–17 để đảm bảo không trễ hạn nộp `24/12/2026`.
