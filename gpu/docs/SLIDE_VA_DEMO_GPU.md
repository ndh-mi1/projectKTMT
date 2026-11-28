# Kịch bản Slide Canva & Demo Trực tiếp — Lượt 3: Module GPU (P3: Nguyễn Hoàng Long)

- **Thời lượng phân bổ:** ~6 phút trong tổng 30 phút trình bày của Nhóm 15 (+ tham gia 15 phút Q&A cuối buổi).
- **Quy tắc trình bày slide nhóm đã chốt:** Mỗi slide tối đa **3 ý chính** kèm 1 hình/bảng/đồ thị trực quan; đặt ghi chú người phụ trách `P3 — Nguyễn Hoàng Long` ở góc dưới mỗi slide.

---

## 1. Cấu trúc Slide Canva (7 Slides)

### Slide 1 — Tiêu đề Lượt 3 & Câu hỏi nghiên cứu 2
- **Tiêu đề:** Tăng tốc nhân ma trận trên GPU (CUDA & cuBLAS)
- **3 ý chính:**
  1. Câu hỏi 2: *Khi nào GPU thực sự vượt trội CPU? Điểm hòa vốn $N^*$ là bao nhiêu?*
  2. Triết lý GPU (SIMT): Hàng nghìn luồng nhẹ, che giấu độ trễ bộ nhớ (Latency Hiding) thay cho cache lớn.
  3. Hai mức đối chứng trên Tesla T4 (Colab): `cuda_naive` (tự viết) vs `cuBLAS` (cận trên thực tế).
- **Trực quan:** Sơ đồ so sánh CPU (ít lõi mạnh + cache lớn) vs GPU (nhiều SM + hàng nghìn luồng nhẹ) *(Patterson & Hennessy, Ch. 6)*.

### Slide 2 — Giải pháp phần cứng & Nút thắt PCIe
- **Tiêu đề:** Luồng dữ liệu Host–Device & Đo lường tách bạch `cudaEvent_t`
- **3 ý chính:**
  1. Dữ liệu di chuyển qua 3 pha: $T_{\text{E2E}} = T_{\text{H2D}} + T_{\text{kernel}} + T_{\text{D2H}}$.
  2. Cường độ số học qua PCIe: $I_{\text{PCIe}}(N) = \frac{2N^3}{12N^2} = \frac{N}{6}$ FLOPs/Byte.
  3. Đo bằng `cudaEvent_t` (7 lần lặp lấy trung vị, sai số $\le 10^{-3}$).
- **Trực quan:** Sơ đồ khối `Host RAM --(H2D PCIe)--> GPU VRAM --> Kernel/cuBLAS --> (D2H PCIe)--> Host RAM`.

### Slide 3 — Cài đặt `cuda_naive` & Thủ thuật `cuBLAS` Row-major
- **Tiêu đề:** Thiết kế Kernel CUDA & Tích hợp `cuBLAS`
- **3 ý chính:**
  1. `cuda_naive`: 1 thread = 1 phần tử $C_{ij}$ (block $16 \times 16$), bị *memory-bound* do đọc Global Memory lặp lại.
  2. `cuBLAS`: Khai thác Shared Memory & Register Tiling để tiệm cận trần tính toán FP32.
  3. Mẹo không cần chuyển vị: dùng $(AB)^T = B^T A^T$ để gọi `cublasSgemm` trực tiếp trên mảng row-major.
- **Trực quan:** Đoạn code ngắn gọn 6 dòng của `matmul_naive_kernel` và lời gọi `cublasSgemm(..., d_B, N, d_A, N, ...)`.

### Slide 4 — Kết quả thực nghiệm: Phân rã thời gian & PCIe Overhead
- **Tiêu đề:** Kết quả GPU trên Google Colab: `Kernel-only` vs `End-to-End`
- **3 ý chính:**
  1. Ở $N$ nhỏ ($64 \dots 256$): Chi phí copy PCIe & khởi động chiếm **[ĐIỀN]%** tổng $T_{\text{E2E}}$.
  2. Ở $N$ lớn ($2048 \dots 4096$): Độ phức tạp tính toán $O(N^3)$ áp đảo truyền dữ liệu $O(N^2)$.
  3. `cuBLAS` nhanh hơn `cuda_naive` **[ĐIỀN]x** ở $N = 4096$ nhưng bị PCIe kìm hãm rõ ở thông lượng E2E.
- **Trực quan:** Biểu đồ `gpu_time_breakdown.png` (Stacked bar chart tỷ trọng $T_{\text{H2D}}, T_{\text{kernel}}, T_{\text{D2H}}$).

### Slide 5 — Xác định điểm hòa vốn $N^*$ (Trả lời Câu hỏi 2)
- **Tiêu đề:** Điểm hòa vốn CPU vs GPU: $N^*_{\text{kernel}}$ và $N^*_{\text{E2E}}$
- **3 ý chính:**
  1. $N < N^*$: CPU thắng nhờ ma trận nằm gọn trong L1/L2/L3 Cache và không tốn copy PCIe.
  2. Điểm hòa vốn thuần tính toán: $N^*_{\text{kernel}} =$ **[ĐIỀN]**; điểm hòa vốn toàn trình: $N^*_{\text{E2E}} =$ **[ĐIỀN]**.
  3. Kết luận Câu 2: Chỉ nên đẩy tác vụ lên GPU khi $N \ge N^*_{\text{E2E}}$ hoặc giữ dữ liệu lâu dài trên VRAM.
- **Trực quan:** Biểu đồ log-log `gpu_vs_cpu_breakeven.png` đánh dấu rõ mũi tên $N^*_{\text{kernel}}$ và $N^*_{\text{E2E}}$.

### Slide 6 — Lý do phạm vi & Demo sản phẩm trên Google Colab
- **Tiêu đề:** Phạm vi triển khai GPU & Minh họa thực tế
- **3 ý chính:**
  1. Lý do chỉ chọn 2 mức (`cuda_naive` & `cuBLAS`): đủ bóc tách *memory-bound* vs *compute peak* và đo trần PCIe mà không phân tán khỏi trọng tâm $N^*$.
  2. Demo trực tiếp Notebook `gpu/notebooks/colab_matmul.ipynb` trên GPU Tesla T4.
  3. Kiểm chứng `correct = 1` tự động và xuất chuẩn `results/gpu_bench.csv`.
- **Trực quan:** Ảnh chụp màn hình Colab chạy thành công + bảng tóm tắt `gpu_bench.csv` (sẵn sàng chuyển sang tab Colab demo).

---

## 2. Kịch bản Demo trực tiếp trên Google Colab (~2 phút)

1. **Chuẩn bị trước khi thuyết trình (15 phút trước giờ):**
   - Mở sẵn tab trình duyệt Google Colab chạy `gpu/notebooks/colab_matmul.ipynb` trên GPU Tesla T4.
   - Đã chạy trước Cell 1–4 (đã clone repo, kiểm tra `nvidia-smi` và biên dịch sẵn `gpu/bin/bench_gpu`) để không mất thời gian chờ tải hay compile khi đang thuyết trình.
2. **Thao tác khi đến lượt Demo:**
   - **Bước 1 (20 giây):** Chỉ vào output của `nvidia-smi` để giảng viên thấy GPU thực tế đang cấp (ví dụ `Tesla T4 15360 MiB`) và file `results/env_long.json`.
   - **Bước 2 (40 giây):** Bấm chạy trực tiếp **Cell 5 (Live Demo `N = 64, 128, 256`)** ngay trước lớp -> chỉ ra các cột `kernel_ms`, `h2d_ms`, `d2h_ms`, `e2e_ms` và kết quả `correct=1` đối chiếu chéo toàn phần.
   - **Bước 3 (40 giây):** Cuộn xuống **Cell 7 & Cell 9** (đã chạy sẵn sweep $N=64 \dots 4096$ trước đó) để chỉ vào bảng `results/gpu_bench.csv` và 3 biểu đồ phân rã PCIe + điểm hòa vốn $N^*$.
3. **Phương án dự phòng (Fallback) nếu mất mạng hoặc hết GPU Colab:**
   - Chụp sẵn ảnh output Cell 2, Cell 5, Cell 7 và lưu 3 ảnh `.png` từ `/content/gpu_plots/` chèn vào slide dự phòng cuối bộ slide.

---

## 3. Ngân hàng Câu hỏi Phản biện (Q&A Defense — 6 câu trọng tâm)

1. **Tại sao không dùng `clock()` hay `std::chrono` của CPU để đo thời gian kernel GPU?**  
   *Trả lời:* Lệnh gọi kernel CUDA (`<<<grid, block>>>`) và `cublasSgemm` mang tính **bất đồng bộ (asynchronous)** — hàm trả quyền điều khiển ngay về CPU trước khi GPU chạy xong. Nếu dùng `clock()` mà quên đồng bộ sẽ chỉ đo được thời gian launch vài micro-giây; còn nếu có đồng bộ CPU thì vẫn dính độ trễ giao tiếp hệ điều hành/driver. `cudaEvent_t` ghi dấu mốc trực tiếp trên hàng đợi lệnh (stream) của GPU nên đo chính xác từng pha H2D, Kernel, D2H đến mức micro-giây.

2. **Tại sao ở kích thước nhỏ ($N = 64, 128$), GPU Tesla T4 có hàng nghìn nhân mà lại chạy chậm hơn CPU?**  
   *Trả lời:* Theo mô hình phân cấp bộ nhớ và Roofline trong Patterson & Hennessy (Ch. 5–6), có 3 nguyên nhân: (i) Dữ liệu $A, B, C$ ở $N=64$ chỉ chiếm $48\text{ KB}$, nằm gọn trong L1/L2 Cache của CPU nên CPU đọc cực nhanh; (ii) GPU phải chịu chi phí truyền dữ liệu qua bus PCIe có băng thông thấp và độ trễ khởi động kernel; (iii) Cường độ số học qua PCIe là $I_{\text{PCIe}} = N/6$, khi $N$ nhỏ lượng tính toán quá ít để bù đắp chi phí copy, đồng thời 16 block ở $N=64$ không đủ lấp đầy toàn bộ SM trên GPU.

3. **Tại sao `cublasSgemm` trong code lại truyền `d_B` trước `d_A` mà không gọi hàm chuyển vị?**  
   *Trả lời:* Do dữ liệu C/C++ lưu theo **row-major**, còn thư viện `cuBLAS` mặc định đọc theo **column-major**. Một ma trận row-major $X$ khi được hiểu theo column-major chính là $X^T$. Vì $(AB)^T = B^T A^T$, truyền `d_B` vào vị trí tham số thứ nhất và `d_A` vào vị trí thứ hai giúp `cuBLAS` tính ra trực tiếp $C^T$ theo column-major — tức chính là ma trận $C = AB$ lưu theo row-major mà không tốn thêm bộ nhớ hay thời gian chuyển vị.

4. **Tại sao `cuBLAS` nhanh hơn `cuda_naive` rất nhiều dù cả hai cùng thực hiện đúng $2N^3$ phép toán?**  
   *Trả lời:* Theo chương 6 sách Patterson & Hennessy, đây là sự khác biệt giữa **memory-bound** và tối ưu khai thác **data locality**. Trong `cuda_naive`, mỗi thread đọc lại toàn bộ hàng của $A$ và cột của $B$ từ Global Memory (VRAM), khiến đơn vị tính liên tục phải chờ bộ nhớ. Ngược lại, `cuBLAS` chia ma trận thành các tile nhỏ đưa vào Shared Memory và thanh ghi (Registers) trên chip SM, tái sử dụng dữ liệu nhiều lần trước khi ghi ra ngoài và tối ưu hóa lệnh FMA/Tensor pipeline.

5. **Nếu cùng chạy phép nhân ma trận trong mạng nơ-ron sâu (nhiều lớp nối tiếp), bài toán PCIe có còn nghiêm trọng như đo đơn lẻ không?**  
   *Trả lời:* Không nghiêm trọng bằng, vì trong thực tế các framework như PyTorch/TensorFlow chỉ chép dữ liệu input lên VRAM một lần ở đầu chuỗi (batch), thực hiện liên tiếp nhiều phép GEMM ngay trên GPU mà không chép qua PCIe ở giữa các lớp. Đó chính là lý do đồ án tách bạch cả hai chỉ số $T_{\text{kernel}}$ (đại diện cho chuỗi tính toán giữ dữ liệu trên VRAM) và $T_{\text{E2E}}$ (đại diện cho tác vụ rời rạc phải chuyển dữ liệu qua PCIe).

6. **Vì sao điểm hòa vốn $N^*$ của nhóm có thể khác nếu chạy trên máy khác (ví dụ RTX 4090 hoặc Colab L4)?**  
   *Trả lời:* Bởi vì $N^*$ phụ thuộc đồng thời vào hiệu năng đỉnh CPU đối chứng ($T^*_{\text{CPU}}$), năng lực tính toán của GPU, và băng thông/độ trễ kết nối PCIe (PCIe 3.0 vs 4.0/5.0). Theo đúng khuyến cáo trong tài liệu lý thuyết của nhóm, chúng tôi báo cáo $N^*$ gắn kèm cấu hình cụ thể trong `results/env_khuong.json` và `results/env_long.json`, thay vì coi một con số $N^*$ duy nhất là đúng cho mọi phần cứng.
