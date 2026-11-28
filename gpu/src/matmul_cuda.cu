/*
 * matmul_cuda.cu - Benchmark nhan ma tran vuong C = A * B (float32) tren GPU.
 *
 * Muc tieu (P3 - Nguyen Hoang Long, Nhom 15 - MI4344):
 *   1. Trien khai 2 muc: kernel CUDA co ban (cuda_naive) va thu vien cuBLAS (cublas).
 *   2. Do tach bach thoi gian bang cudaEvent_t:
 *      - T_h2d: Host -> Device (copy A va B)
 *      - T_kernel: chi thuc thi kernel / cublasSgemm
 *      - T_d2h: Device -> Host (copy C)
 *      - T_e2e = T_h2d + T_kernel + T_d2h
 *   3. Kiem tra tinh dung dan (sai so tuong doi max <= 1e-3) va ghi noi vao CSV
 *      theo dung schema cua METRICS.md.
 */

#include <cublas_v2.h>
#include <cuda_runtime.h>

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

#include "gpu_bench_utils.hpp"

#define CUDA_CHECK(call)                                                      \
    do {                                                                      \
        cudaError_t err__ = (call);                                           \
        if (err__ != cudaSuccess) {                                           \
            std::cerr << "CUDA error at " << __FILE__ << ":" << __LINE__      \
                      << " -> " << cudaGetErrorString(err__) << "\n";         \
            std::exit(EXIT_FAILURE);                                          \
        }                                                                     \
    } while (0)

#define CUBLAS_CHECK(call)                                                    \
    do {                                                                      \
        cublasStatus_t status__ = (call);                                     \
        if (status__ != CUBLAS_STATUS_SUCCESS) {                              \
            std::cerr << "cuBLAS error at " << __FILE__ << ":" << __LINE__    \
                      << " -> status code " << static_cast<int>(status__)     \
                      << "\n";                                                \
            std::exit(EXIT_FAILURE);                                          \
        }                                                                     \
    } while (0)

/*
 * Kernel CUDA naive: moi thread tinh dung 1 phan tu C[row, col].
 * Luu tru row-major:
 *   - C[row, col] = sum_{k=0}^{N-1} A[row * N + k] * B[k * N + col]
 * Dung size_t khi tinh chi so de tranh tran so nguyen 32-bit neu N lon.
 */
__global__ void matmul_naive_kernel(const float *__restrict__ A,
                                    const float *__restrict__ B,
                                    float *__restrict__ C,
                                    int N) {
    const int row = static_cast<int>(blockIdx.y) * blockDim.y + threadIdx.y;
    const int col = static_cast<int>(blockIdx.x) * blockDim.x + threadIdx.x;

    if (row < N && col < N) {
        const size_t n_sz = static_cast<size_t>(N);
        const size_t r_sz = static_cast<size_t>(row);
        const size_t c_sz = static_cast<size_t>(col);
        float sum = 0.0f;
        for (size_t k = 0; k < n_sz; ++k) {
            sum += A[r_sz * n_sz + k] * B[k * n_sz + c_sz];
        }
        C[r_sz * n_sz + c_sz] = sum;
    }
}

/*
 * Goi cublasSgemm cho ma tran row-major.
 *
 * Luu y quan trong ve thu tu luu tru (Row-major vs Column-major):
 *   cuBLAS mac dinh doc ma tran theo column-major. Mot ma tran X kich thuoc N x N
 *   duoc luu theo row-major trong bo nho se tuong duong voi ma tran chuyen vi X^T
 *   khi doc theo column-major.
 *   Do do, de thu duoc C = A * B theo row-major (tuc C^T = (A * B)^T trong
 *   bo nho column-major), ta ap dung dong nhat thuc:
 *       C^T = (A * B)^T = B^T * A^T
 *   Vi vay, truyen d_B truoc va d_A sau vao cublasSgemm(..., CUBLAS_OP_N, CUBLAS_OP_N,
 *   N, N, N, &alpha, d_B, N, d_A, N, &beta, d_C, N) se tinh dung C = A * B
 *   ma khong can copy hay chuyen vi bo nho phu.
 */
static void run_cublas_sgemm(cublasHandle_t handle,
                             const float *d_A,
                             const float *d_B,
                             float *d_C,
                             int N) {
    const float alpha = 1.0f;
    const float beta = 0.0f;
    CUBLAS_CHECK(cublasSgemm(handle,
                             CUBLAS_OP_N,
                             CUBLAS_OP_N,
                             N,
                             N,
                             N,
                             &alpha,
                             d_B,
                             N,
                             d_A,
                             N,
                             &beta,
                             d_C,
                             N));
}

static void launch_impl(const std::string &impl,
                        cublasHandle_t cublas_handle,
                        const float *d_A,
                        const float *d_B,
                        float *d_C,
                        int N,
                        int block_size) {
    if (impl == "cuda_naive") {
        dim3 block(static_cast<unsigned int>(block_size),
                   static_cast<unsigned int>(block_size));
        dim3 grid(static_cast<unsigned int>((N + block_size - 1) / block_size),
                  static_cast<unsigned int>((N + block_size - 1) / block_size));
        matmul_naive_kernel<<<grid, block>>>(d_A, d_B, d_C, N);
        CUDA_CHECK(cudaGetLastError());
    } else {
        run_cublas_sgemm(cublas_handle, d_A, d_B, d_C, N);
    }
}

static gpu_bench::GpuBenchRow benchmark_impl(const std::string &impl,
                                             int N,
                                             const gpu_bench::BenchConfig &cfg,
                                             const std::string &gpu_name,
                                             cublasHandle_t cublas_handle,
                                             const std::vector<float> &h_A,
                                             const std::vector<float> &h_B,
                                             std::vector<float> &h_C_out) {
    const size_t count = static_cast<size_t>(N) * static_cast<size_t>(N);
    const size_t bytes = count * sizeof(float);
    h_C_out.assign(count, 0.0f);

    float *d_A = nullptr;
    float *d_B = nullptr;
    float *d_C = nullptr;
    CUDA_CHECK(cudaMalloc(&d_A, bytes));
    CUDA_CHECK(cudaMalloc(&d_B, bytes));
    CUDA_CHECK(cudaMalloc(&d_C, bytes));

    cudaEvent_t ev_start = nullptr;
    cudaEvent_t ev_stop = nullptr;
    CUDA_CHECK(cudaEventCreate(&ev_start));
    CUDA_CHECK(cudaEventCreate(&ev_stop));

    // Warmup day du H2D -> compute -> D2H de on dinh xung GPU va cuBLAS workspace
    for (int w = 0; w < cfg.warmup; ++w) {
        CUDA_CHECK(cudaMemcpy(d_A, h_A.data(), bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(d_B, h_B.data(), bytes, cudaMemcpyHostToDevice));
        launch_impl(impl, cublas_handle, d_A, d_B, d_C, N, cfg.block_size);
        CUDA_CHECK(cudaMemcpy(h_C_out.data(), d_C, bytes, cudaMemcpyDeviceToHost));
        CUDA_CHECK(cudaDeviceSynchronize());
    }

    std::vector<double> h2d_samples;
    std::vector<double> kernel_samples;
    std::vector<double> d2h_samples;
    std::vector<double> e2e_samples;
    h2d_samples.reserve(static_cast<size_t>(cfg.repeats));
    kernel_samples.reserve(static_cast<size_t>(cfg.repeats));
    d2h_samples.reserve(static_cast<size_t>(cfg.repeats));
    e2e_samples.reserve(static_cast<size_t>(cfg.repeats));

    for (int r = 0; r < cfg.repeats; ++r) {
        float t_h2d = 0.0f;
        float t_kernel = 0.0f;
        float t_d2h = 0.0f;

        // 1. Do H2D (copy ca A va B)
        CUDA_CHECK(cudaEventRecord(ev_start, 0));
        CUDA_CHECK(cudaMemcpy(d_A, h_A.data(), bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(d_B, h_B.data(), bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaEventRecord(ev_stop, 0));
        CUDA_CHECK(cudaEventSynchronize(ev_stop));
        CUDA_CHECK(cudaEventElapsedTime(&t_h2d, ev_start, ev_stop));

        // 2. Do chi thoi gian kernel / cuBLAS
        CUDA_CHECK(cudaEventRecord(ev_start, 0));
        launch_impl(impl, cublas_handle, d_A, d_B, d_C, N, cfg.block_size);
        CUDA_CHECK(cudaEventRecord(ev_stop, 0));
        CUDA_CHECK(cudaEventSynchronize(ev_stop));
        CUDA_CHECK(cudaEventElapsedTime(&t_kernel, ev_start, ev_stop));

        // 3. Do D2H (copy C ve RAM Host)
        CUDA_CHECK(cudaEventRecord(ev_start, 0));
        CUDA_CHECK(cudaMemcpy(h_C_out.data(), d_C, bytes, cudaMemcpyDeviceToHost));
        CUDA_CHECK(cudaEventRecord(ev_stop, 0));
        CUDA_CHECK(cudaEventSynchronize(ev_stop));
        CUDA_CHECK(cudaEventElapsedTime(&t_d2h, ev_start, ev_stop));

        h2d_samples.push_back(static_cast<double>(t_h2d));
        kernel_samples.push_back(static_cast<double>(t_kernel));
        d2h_samples.push_back(static_cast<double>(t_d2h));
        e2e_samples.push_back(static_cast<double>(t_h2d) +
                              static_cast<double>(t_kernel) +
                              static_cast<double>(t_d2h));
    }

    CUDA_CHECK(cudaEventDestroy(ev_start));
    CUDA_CHECK(cudaEventDestroy(ev_stop));
    CUDA_CHECK(cudaFree(d_A));
    CUDA_CHECK(cudaFree(d_B));
    CUDA_CHECK(cudaFree(d_C));

    const double med_h2d = gpu_bench::compute_median(h2d_samples);
    const double med_kernel = gpu_bench::compute_median(kernel_samples);
    const double med_d2h = gpu_bench::compute_median(d2h_samples);
    const double med_e2e = med_h2d + med_kernel + med_d2h;

    const double min_kernel = *std::min_element(kernel_samples.begin(), kernel_samples.end());
    const double max_kernel = *std::max_element(kernel_samples.begin(), kernel_samples.end());
    const double min_e2e = *std::min_element(e2e_samples.begin(), e2e_samples.end());
    const double max_e2e = *std::max_element(e2e_samples.begin(), e2e_samples.end());

    double max_rel_err = 0.0;
    const int is_correct = gpu_bench::verify_against_cpu_ref(
        h_A.data(), h_B.data(), h_C_out.data(), N, 512, cfg.verify_samples, &max_rel_err);

    gpu_bench::GpuBenchRow row;
    row.platform = "gpu";
    row.impl = impl;
    row.N = N;
    row.kernel_ms = med_kernel;
    row.h2d_ms = med_h2d;
    row.d2h_ms = med_d2h;
    row.e2e_ms = med_e2e;
    row.gflops_kernel = gpu_bench::compute_gflops(N, med_kernel);
    row.gflops_e2e = gpu_bench::compute_gflops(N, med_e2e);
    row.gpu_name = gpu_name;
    row.correct = is_correct;

    std::cout << std::fixed << std::setprecision(4)
              << "[" << impl << "] N=" << N
              << " | kernel=" << med_kernel << " ms (min=" << min_kernel
              << ", max=" << max_kernel << ")"
              << " | h2d=" << med_h2d << " ms"
              << " | d2h=" << med_d2h << " ms"
              << " | e2e=" << med_e2e << " ms (min=" << min_e2e
              << ", max=" << max_e2e << ")"
              << std::setprecision(2)
              << " | GFLOPS_k=" << row.gflops_kernel
              << " | GFLOPS_e2e=" << row.gflops_e2e
              << " | rel_err=" << std::scientific << std::setprecision(2) << max_rel_err
              << " | correct=" << row.correct << "\n";

    return row;
}

int main(int argc, char **argv) {
    gpu_bench::BenchConfig cfg;
    bool show_help = false;
    if (!gpu_bench::parse_cli(argc, argv, cfg, show_help)) {
        gpu_bench::print_usage(argv[0]);
        return EXIT_FAILURE;
    }
    if (show_help) {
        gpu_bench::print_usage(argv[0]);
        return EXIT_SUCCESS;
    }

    int device_count = 0;
    CUDA_CHECK(cudaGetDeviceCount(&device_count));
    if (device_count <= 0) {
        std::cerr << "Error: no CUDA-capable GPU detected.\n";
        return EXIT_FAILURE;
    }

    int device_id = 0;
    CUDA_CHECK(cudaSetDevice(device_id));
    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, device_id));
    const std::string gpu_name = gpu_bench::sanitize_csv_field(prop.name);

    std::cout << "=== GPU Matrix Multiplication Benchmark (MI4344 - P3) ===\n"
              << "GPU: " << gpu_name
              << " | SMs: " << prop.multiProcessorCount
              << " | VRAM: " << (prop.totalGlobalMem / (1024ULL * 1024ULL)) << " MB"
              << " | CC: " << prop.major << "." << prop.minor << "\n"
              << "Config: impl=" << cfg.impl
              << ", repeats=" << cfg.repeats
              << ", warmup=" << cfg.warmup
              << ", block=" << cfg.block_size << "x" << cfg.block_size
              << ", out=" << cfg.out_path << "\n";

    cublasHandle_t cublas_handle = nullptr;
    CUBLAS_CHECK(cublasCreate(&cublas_handle));

    std::vector<int> sizes;
    if (cfg.sweep) {
        sizes.assign(gpu_bench::SWEEP_SIZES,
                     gpu_bench::SWEEP_SIZES + gpu_bench::NUM_SWEEP_SIZES);
    } else {
        sizes.push_back(cfg.N);
    }

    for (size_t s_idx = 0; s_idx < sizes.size(); ++s_idx) {
        const int N = sizes[s_idx];
        std::vector<float> h_A;
        std::vector<float> h_B;
        gpu_bench::init_matrices(h_A, h_B, N, cfg.seed);

        std::vector<float> h_C_naive;
        std::vector<float> h_C_cublas;

        if (cfg.impl == "cuda_naive" || cfg.impl == "all") {
            gpu_bench::GpuBenchRow row_naive = benchmark_impl(
                "cuda_naive", N, cfg, gpu_name, cublas_handle, h_A, h_B, h_C_naive);
            if (!gpu_bench::append_gpu_csv_row(cfg.out_path, row_naive)) {
                CUBLAS_CHECK(cublasDestroy(cublas_handle));
                return EXIT_FAILURE;
            }
        }

        if (cfg.impl == "cublas" || cfg.impl == "all") {
            gpu_bench::GpuBenchRow row_cublas = benchmark_impl(
                "cublas", N, cfg, gpu_name, cublas_handle, h_A, h_B, h_C_cublas);

            // Neu chay ca hai tren cung N, kiem tra cheo toan bo N*N phan tu
            if (cfg.impl == "all" && !h_C_naive.empty()) {
                const double cross_err = gpu_bench::compute_max_rel_error(
                    h_C_naive.data(), h_C_cublas.data(),
                    static_cast<size_t>(N) * static_cast<size_t>(N));
                std::cout << "  -> Full-matrix cross-check (cuda_naive vs cublas, N="
                          << N << "): max_rel_err=" << std::scientific
                          << std::setprecision(2) << cross_err
                          << (cross_err <= 1e-3 ? " [PASS]" : " [WARN]") << "\n";
            }

            if (!gpu_bench::append_gpu_csv_row(cfg.out_path, row_cublas)) {
                CUBLAS_CHECK(cublasDestroy(cublas_handle));
                return EXIT_FAILURE;
            }
        }
    }

    CUBLAS_CHECK(cublasDestroy(cublas_handle));
    std::cout << "Benchmark completed. Results appended to: " << cfg.out_path << "\n";
    return EXIT_SUCCESS;
}
