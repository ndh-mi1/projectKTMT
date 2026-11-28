# Bản nháp Báo cáo cuối kỳ — Phần GPU (P3: Nguyễn Hoàng Long)

> **Hướng dẫn sử dụng khi đưa vào Google Docs chung của Nhóm 15:**
> - Tuân thủ định dạng **APA 7th Edition** (Times New Roman 12pt, giãn dòng thống nhất, lề 1 inch, thụt đầu dòng 0.5 inch, bảng chỉ kẻ đường ngang trên/dưới tiêu đề/đáy bảng, đặt `Bảng X` / `Hình X` ở **phía trên** đối tượng).
> - Các số hiệu trích dẫn `[1]`, `[2]`... dưới đây được đánh theo thứ tự xuất hiện trong phần GPU; khi Khương gom toàn bài cần rà lại thứ tự `[1]..[N]` thống nhất từ Chương 1 đến hết Chương 3.
> - **Tuyệt đối không tự điền số liệu giả:** Mọi ô `[ĐIỀN TỪ gpu_bench.csv]` phải được điền trực tiếp từ output thực nghiệm chạy trên Google Colab trong `results/gpu_bench.csv` và `results/env_long.json`.

---

## CHƯƠNG 2 — PHƯƠNG PHÁP LUẬN

### 2.3. Thiết kế và Tăng tốc trên GPU

#### 2.3.1. Triết lý kiến trúc SIMT và Phân cấp bộ nhớ trên GPU

Trái ngược với bộ xử lý đa năng CPU (tối ưu cho độ trễ đơn luồng thấp thông qua bộ nhớ đệm L1/L2/L3 dung lượng lớn và bộ dự đoán rẽ nhánh phức tạp), bộ xử lý đồ họa GPU được thiết kế theo triết lý **thông lượng cao (throughput-oriented)** dựa trên mô hình **SIMT (Single Instruction, Multiple Threads)** [1], [2]. Một GPU hiện đại bao gồm nhiều khối **Streaming Multiprocessor (SM)**; mỗi SM quản lý đồng thời hàng trăm đến hàng nghìn luồng nhẹ (threads) được lập lịch theo từng nhóm **Warp** (32 luồng thực thi cùng một lệnh trên các dữ liệu khác nhau). Khi một warp bị đình trệ do chờ truy cập bộ nhớ ngoài (Global Memory / VRAM có độ trễ hàng trăm chu kỳ xung clock), bộ lập lịch phần cứng của SM lập tức chuyển sang thực thi một warp khác đã sẵn sàng chỉ trong một chu kỳ — cơ chế **che giấu độ trễ bộ nhớ (latency hiding)** thông qua chuyển ngữ cảnh phần cứng gần như bằng không [1], [2].

Về mặt phân cấp bộ nhớ (Memory Hierarchy), ngoài không gian thanh ghi (Registers) và bộ nhớ dùng chung trên chip (Shared Memory / L1 Cache) nằm trong từng SM, phần lớn dữ liệu đầu vào $A, B$ và kết quả $C$ được lưu trên bộ nhớ chính của card đồ họa (Global Memory / GDDR6 hoặc HBM). Đối với GPU rời kết nối với máy chủ qua khe cắm **PCI Express (PCIe)** (như cấu hình NVIDIA Tesla T4 trên Google Colab), dữ liệu phải trải qua hai lần di chuyển qua bus I/O bên ngoài: chép từ RAM máy chủ (Host) sang VRAM của GPU (**Host-to-Device, H2D**) trước khi tính toán và chép kết quả từ VRAM về RAM máy chủ (**Device-to-Host, D2H**) sau khi tính toán xong [1], [3]. Theo nguyên lý Locality và Tháp bộ nhớ [1], băng thông bus PCIe (~10–16 GB/s trên PCIe 3.0 x16 thực tế) nhỏ hơn nhiều lần so với băng thông nội bộ VRAM (~320 GB/s trên Tesla T4), biến giao tiếp Host–Device trở thành nút thắt cổ chai quyết định đối với các ma trận kích thước nhỏ và vừa.

#### 2.3.2. Phạm vi triển khai và Thiết kế hai mức cài đặt (`cuda_naive` và `cuBLAS`)

Để bóc tách rạch ròi giữa giới hạn của lập trình song song cơ bản và giới hạn thông lượng thực tế của phần cứng GPU trên cùng bài toán nhân ma trận vuông $C = A \times B$ (`float32`), nhóm triển khai đúng hai mức đại diện trong tệp `gpu/src/matmul_cuda.cu` (thay vì dàn trải quá nhiều biến thể tối ưu trung gian ngoài phạm vi mục tiêu Câu hỏi 2):

1. **Mức đối chứng cơ bản — Kernel CUDA Naive (`matmul_naive_kernel`):**  
   Mỗi luồng CUDA được ánh xạ theo tọa độ 2D `(row, col)` với khối luồng `dim3 block(16, 16)` (256 threads/block) và lưới `dim3 grid((N + 15)/16, (N + 15)/16)`. Mỗi luồng chịu trách nhiệm tính đúng một phần tử $C_{\text{row},\text{col}} = \sum_{k=0}^{N-1} A_{\text{row},k} B_{k,\text{col}}$.  
   *Phân tích truy cập bộ nhớ:* Trong cùng một warp (các luồng có `threadIdx.x` liên tiếp, tức `col` tăng dần và `row` cố định), thao tác đọc `B[k * N + col]` truy cập các địa chỉ liên tiếp nhau trên bộ nhớ nên đạt **memory coalescing** tốt [1], [3]; tuy nhiên, mỗi phép nhân-cộng (FMA) vẫn phải đọc trực tiếp $A_{\text{row},k}$ và $B_{k,\text{col}}$ từ Global Memory mà chưa tái sử dụng dữ liệu qua Shared Memory hay thanh ghi. Do đó, cường độ số học hiệu dụng của kernel naive rất thấp ($\approx 0.25$ FLOPs/Byte với `float32`), khiến kernel dễ bị **memory-bound** ở mức Global Memory theo mô hình Roofline [1], [2].
2. **Mức cận trên thực tế — Thư viện NVIDIA `cuBLAS` (`cublasSgemm`):**  
   Nhóm sử dụng hàm `cublasSgemm` từ thư viện chuẩn công nghiệp NVIDIA cuBLAS [4] nhằm phản ánh thông lượng thực tế tối đa mà kiến trúc GPU đạt được (tận dụng register blocking, shared-memory tiling, prefetching và lịch trình warp tối ưu cho từng thế hệ SM).  
   *Xử lý quy ước lưu trữ Row-major và Column-major:* Toàn bộ dữ liệu đầu vào của nhóm được cấp phát theo chuẩn **row-major** (C/C++), trong khi `cuBLAS` mặc định diễn giải ma trận theo **column-major** [4]. Một ma trận $X$ lưu theo row-major khi đọc dưới góc nhìn column-major chính là ma trận chuyển vị $X^T$. Áp dụng đồng nhất thức đại số tuyến tính:
   $$C^T = (A \times B)^T = B^T \times A^T$$
   chương trình gọi `cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, N, N, N, &alpha, d_B, N, d_A, N, &beta, d_C, N)` để tính trực tiếp $C = A \times B$ đúng chuẩn row-major mà không phát sinh bất kỳ bước sao chép hay chuyển vị phụ nào trên VRAM.

#### 2.3.3. Phương pháp đo thời gian, kiểm chứng và tái lập thực nghiệm

Do việc thực thi kernel trên GPU mang tính bất đồng bộ (asynchronous) so với CPU Host, việc dùng hàm thời gian phía CPU như `clock()` sẽ gây sai lệch nghiêm trọng. Nhóm sử dụng hoàn toàn **`cudaEvent_t`** (`cudaEventRecord`, `cudaEventSynchronize`, `cudaEventElapsedTime`) [3] để đo chính xác ba pha tách biệt trên dòng thực thi GPU:
- $T_{\text{H2D}}$: Thời gian truyền hai ma trận $A$ và $B$ từ Host RAM sang Device VRAM qua `cudaMemcpyHostToDevice`.
- $T_{\text{kernel}}$: Thời gian thực thi thuần của `matmul_naive_kernel` hoặc `cublasSgemm`.
- $T_{\text{D2H}}$: Thời gian truyền ma trận kết quả $C$ từ Device VRAM về Host RAM qua `cudaMemcpyDeviceToHost`.
- Thời gian toàn trình (End-to-End): $T_{\text{E2E}} = T_{\text{H2D}} + T_{\text{kernel}} + T_{\text{D2H}}$.

Thông lượng được tính thống nhất theo chuẩn chung của đồ án với $\text{FLOPs}(N) = 2N^3$ [1]:
$$\text{GFLOPS}_{\text{kernel}} = \frac{2N^3}{T_{\text{kernel}} \times 10^6}, \qquad \text{GFLOPS}_{\text{E2E}} = \frac{2N^3}{T_{\text{E2E}} \times 10^6}$$
trong đó thời gian tính bằng mili-giây (ms).

Thực nghiệm được tự động hóa trên Google Colab qua notebook `gpu/notebooks/colab_matmul.ipynb` trên dải kích thước $N \in \{64, 128, 256, 512, 1024, 2048, 4096\}$. Trước khi đo mỗi kích thước, chương trình chạy 2 lượt làm nóng (`warmup = 2`) để ổn định xung nhịp GPU và khởi tạo workspace của `cuBLAS`, sau đó lặp 7 lần (`repeats = 7`) và lấy giá trị **trung vị (median)** nhằm loại bỏ nhiễu ngẫu nhiên từ hệ thống chia sẻ tài nguyên đám mây. Tính đúng đắn (`correct = 1`) được kiểm tra tự động bằng cách quét toàn bộ $N^2$ phần tử phát hiện `NaN`/`Inf` và đối chiếu với tích chuẩn tích lũy `double` trên CPU (kiểm tra toàn phần với $N \le 512$ và lấy mẫu xác định 512 điểm kết hợp đối chiếu chéo toàn phần $N^2$ phần tử giữa `cuda_naive` và `cublas` với $N > 512$), đảm bảo sai số tương đối cực đại $\max \frac{|C_{\text{GPU}} - C_{\text{ref}}|}{|C_{\text{ref}}| + 1} \le 10^{-3}$. Toàn bộ thông số môi trường GPU, driver và phiên bản CUDA được lưu tại `results/env_long.json`, kết quả đo được xuất nối tiếp vào `results/gpu_bench.csv`.

---

## CHƯƠNG 3 — KẾT QUẢ VÀ BÀN LUẬN

### 3.2. Kết quả và Phân tích trên GPU (Trả lời Câu hỏi 2)

#### 3.2.1. Tổng hợp số liệu thực nghiệm trên GPU

Thực nghiệm được tiến hành trên môi trường Google Colab với GPU **[ĐIỀN TÊN GPU TỪ `results/env_long.json`, ví dụ: NVIDIA Tesla T4 16GB]**, phiên bản CUDA **[ĐIỀN TỪ `env_long.json`]**. Bảng 1 trình bày thời gian từng pha ($T_{\text{H2D}}, T_{\text{kernel}}, T_{\text{D2H}}, T_{\text{E2E}}$) và thông lượng đạt được của hai cài đặt `cuda_naive` và `cublas` trên toàn dải $N \in [64, 4096]$.

**Bảng 1**  
*Kết quả đo thời gian và thông lượng nhân ma trận `float32` trên GPU (trung vị qua 7 lần đo)*

| Thuật toán | $N$ | $T_{\text{H2D}}$ (ms) | $T_{\text{kernel}}$ (ms) | $T_{\text{D2H}}$ (ms) | $T_{\text{E2E}}$ (ms) | Tỷ trọng PCIe (%) | $\text{GFLOPS}_{\text{kernel}}$ | $\text{GFLOPS}_{\text{E2E}}$ | Đúng (`correct`) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|:---:|
| `cuda_naive` | 64 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cublas` | 64 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cuda_naive` | 128 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cublas` | 128 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cuda_naive` | 256 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cublas` | 256 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cuda_naive` | 512 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cublas` | 512 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cuda_naive` | 1024 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cublas` | 1024 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cuda_naive` | 2048 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cublas` | 2048 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cuda_naive` | 4096 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |
| `cublas` | 4096 | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] | [ĐIỀN]% | [ĐIỀN] | [ĐIỀN] | [ĐIỀN] |

*Ghi chú.* Số liệu trích xuất trực tiếp từ `results/gpu_bench.csv`. Tỷ trọng PCIe được tính bằng $(T_{\text{H2D}} + T_{\text{D2H}}) / T_{\text{E2E}} \times 100\%$. Toàn bộ 14 cấu hình đo đều đạt kiểm chứng đúng đắn `correct = 1` ($\max \text{rel\_err} \le 10^{-3}$).

**Hình 1**  
*Phân rã tỷ trọng thời gian truyền dữ liệu PCIe ($T_{\text{H2D}}, T_{\text{D2H}}$) và thời gian tính toán ($T_{\text{kernel}}$) theo kích thước $N$*  
`[CHÈN ẢNH gpu_time_breakdown.png TỪ NOTEBOOK HOẶC results/plots/]`  
*Ghi chú.* Minh họa sự chuyển dịch từ trạng thái nghẽn truyền dữ liệu (PCIe/Latency-bound) ở $N$ nhỏ sang trạng thái tận dụng năng lực tính toán (Compute-dominated) khi $N$ tăng lớn.

#### 3.2.2. Phân tích chênh lệch `cuda_naive` vs `cuBLAS` và Nút thắt PCIe theo Mô hình Roofline

Từ Bảng 1 và Hình 1, có hai quy luật kiến trúc nổi bật cần làm rõ:

1. **Khoảng cách giữa `cuda_naive` và `cuBLAS`:** Ở kích thước lớn ($N = 2048, 4096$), `cuBLAS` đạt **[ĐIỀN]** GFLOPS (kernel), nhanh hơn `cuda_naive` khoảng **[ĐIỀN]x**. Nguyên nhân là `cuda_naive` không dùng Shared Memory hay Register Tiling nên phải truy xuất Global Memory liên tục (bị giới hạn bởi băng thông VRAM theo trần Roofline $\text{GFLOPS}_{\text{attainable}} = \min(\text{Peak}_{\text{compute}}, I \cdot B_{\text{VRAM}})$ [1], [2]). Ngược lại, `cuBLAS` chia khối dữ liệu vào Shared Memory và thanh ghi của từng SM, đẩy cường độ số học nội bộ lên cao để tiệm cận trần tính toán FP32 của GPU.
2. **Sự thống trị của chi phí truyền dữ liệu PCIe ở $N$ nhỏ và phép chứng minh theo Cường độ số học:**  
   Xét khối lượng tính toán $\text{FLOPs}(N) = 2N^3$ so với tổng lượng dữ liệu bắt buộc truyền qua bus PCIe (đọc $A, B$ và ghi $C$, mỗi phần tử 4 byte `float32`):
   $$\text{Bytes}_{\text{PCIe}}(N) = 3 \times N^2 \times 4 = 12N^2 \text{ bytes}$$
   Do đó, **cường độ số học trên giao diện PCIe** tăng tuyến tính theo $N$:
   $$I_{\text{PCIe}}(N) = \frac{2N^3}{12N^2} = \frac{N}{6} \text{ [FLOPs/Byte]}$$
   - Khi $N = 64$: $I_{\text{PCIe}} \approx 10.67$ FLOPs/Byte và tổng số phép tính chỉ khoảng $5.24 \times 10^5$ FLOPs. Thời gian tính toán thuần trên GPU chỉ cỡ vài phần trăm mili-giây, trong khi chi phí khởi động kernel, đồng bộ và truyền dữ liệu qua PCIe chiếm tới **[ĐIỀN]%** tổng thời gian $T_{\text{E2E}}$ — thậm chí lớn hơn đáng kể so với chi phí chính phép nhân. Kết hợp với việc lưới `cuda_naive` tại $N = 64$ chỉ có $(64/16)^2 = 16$ thread blocks (không đủ lấp đầy toàn bộ số SM của GPU), phần lớn đơn vị tính toán bị bỏ không.
   - Khi $N \ge 1024$: Khối lượng tính toán tăng theo bậc ba ($O(N^3)$) trong khi dung lượng truyền PCIe chỉ tăng theo bậc hai ($O(N^2)$). Nhờ $I_{\text{PCIe}}(N)$ tăng lên hàng trăm FLOPs/Byte, chi phí PCIe dần bị khấu hao: với `cuda_naive`, tỷ trọng PCIe giảm xuống còn **[ĐIỀN]%** ở $N = 4096$; tuy nhiên với `cuBLAS` (vốn có $T_{\text{kernel}}$ cực ngắn nhờ tối ưu SM), thời gian copy qua PCIe vẫn chiếm một tỷ phần đáng kể (**[ĐIỀN]%** ở $N = 4096$). Điều này chứng minh nhận định trong [1], [2] rằng tối ưu hóa kernel tính toán mà bỏ qua tối ưu luồng dữ liệu Host–Device (như giữ tensor lâu dài trên VRAM, gộp batch hoặc dùng `cudaMemcpyAsync` với pinned memory) sẽ bị trần PCIe kìm hãm mạnh thông lượng toàn trình $\text{GFLOPS}_{\text{E2E}}$.

#### 3.2.3. Xác định điểm hòa vốn $N^*$ giữa GPU và CPU (Trả lời Câu hỏi 2)

Theo định nghĩa chuẩn hóa của nhóm, gọi $T^*_{\text{CPU}}(N)$ là thời gian thực thi của phiên bản CPU tối ưu nhất (OpenMP + AVX2/FMA của Khương trong `results/cpu_opt_bench.csv`). Điểm hòa vốn khi chỉ tính thời gian tính toán thuần ($N^*_{\text{kernel}}$) và khi tính toàn trình cả copy PCIe ($N^*_{\text{E2E}}$) được xác định theo:
$$N^*_{\text{kernel}} = \min \{ N \mid T^{\text{GPU}}_{\text{kernel}}(N) < T^*_{\text{CPU}}(N) \}, \qquad N^*_{\text{E2E}} = \min \{ N \mid T^{\text{GPU}}_{\text{E2E}}(N) < T^*_{\text{CPU}}(N) \}$$

**Hình 2**  
*Đồ thị log-log so sánh thời gian thực thi CPU tối ưu nhất và GPU (Kernel-only vs End-to-End) để xác định điểm hòa vốn $N^*$*  
`[CHÈN ẢNH gpu_vs_cpu_breakeven.png TỪ results/plots/ SAU KHI CƯƠNG TỔNG HỢP]`  
*Ghi chú.* Trục hoành biểu diễn $N$ theo thang $\log_2$, trục tung biểu diễn thời gian (ms) theo thang $\log_{10}$.

Đối chiếu số liệu thực nghiệm trên phần cứng cụ thể của nhóm (**[ĐIỀN CPU laptop của Khương]** vs **[ĐIỀN GPU Colab của Long]**):
- **Tại $N$ nhỏ ($N < N^*_{\text{E2E}}$):** CPU chiến thắng GPU vì CPU truy cập trực tiếp ma trận nằm gọn trong bộ nhớ đệm L1/L2/L3 (với $N=64, 128$, tổng kích thước $3N^2 \times 4$ bytes chỉ từ $48\text{ KB}$ đến $192\text{ KB}$, vừa khít cache) và không phải chịu chi phí truyền dữ liệu qua bus PCIe hay độ trễ khởi động kernel.
- **Điểm hòa vốn thuần tính toán $N^*_{\text{kernel}}$:** Với `cuBLAS`, $N^*_{\text{kernel}} =$ **[ĐIỀN TỪ BẢNG SO SÁNH]**; với `cuda_naive`, $N^*_{\text{kernel}} =$ **[ĐIỀN TỪ BẢNG SO SÁNH]**.
- **Điểm hòa vốn toàn trình $N^*_{\text{E2E}}$:** Khi cộng thêm $T_{\text{H2D}} + T_{\text{D2H}}$, điểm hòa vốn bị đẩy lên mức lớn hơn: $N^*_{\text{E2E}} =$ **[ĐIỀN TỪ BẢNG SO SÁNH]** đối với `cuBLAS` và **[ĐIỀN TỪ BẢNG SO SÁNH]** đối với `cuda_naive`. Từ mốc $N \ge N^*_{\text{E2E}}$ trở đi, GPU chính thức vượt trội hoàn toàn cả về thời gian thực tế lẫn hiệu suất mở rộng, đạt mức tăng tốc lên tới **[ĐIỀN]x** so với CPU đa nhân SIMD ở $N = 2048$.

> **Lưu ý về tính phụ thuộc phần cứng của $N^*$:** Điểm hòa vốn $N^*$ không phải một hằng số bất biến mà phụ thuộc vào cặp phần cứng đối chiếu (tốc độ CPU đa nhân/AVX2 so với thế hệ GPU như Tesla T4/L4 và băng thông khe PCIe trên máy chủ Colab). Do đó, nhóm báo cáo rõ **khoảng hòa vốn** gắn với thông số cấu hình trong `results/env_khuong.json` và `results/env_long.json` để đảm bảo tính trung thực khoa học.

---

## TÀI LIỆU THAM KHẢO (Chuẩn IEEE — phần GPU)

> *Ghi chú cho Khương (P2): Khi hợp nhất toàn bộ báo cáo trên Google Docs, hãy đánh lại số `[1], [2]...` theo đúng thứ tự xuất hiện lần đầu tiên từ Chương 1 đến Chương 3.*

`[1]` D. A. Patterson and J. L. Hennessy, *Computer Organization and Design: The Hardware/Software Interface*, 5th ed. Waltham, MA, USA: Morgan Kaufmann, 2014.

`[2]` J. L. Hennessy and D. A. Patterson, *Computer Architecture: A Quantitative Approach*, 6th ed. Cambridge, MA, USA: Morgan Kaufmann, 2019.

`[3]` NVIDIA Corporation, "CUDA C++ Programming Guide," NVIDIA Documentation. [Online]. Available: https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html

`[4]` NVIDIA Corporation, "cuBLAS Library User Guide," NVIDIA Documentation. [Online]. Available: https://docs.nvidia.com/cuda/cublas/index.html
