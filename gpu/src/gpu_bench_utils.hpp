#ifndef GPU_BENCH_UTILS_HPP
#define GPU_BENCH_UTILS_HPP

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdlib>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

namespace gpu_bench {

static const int SWEEP_SIZES[] = {64, 128, 256, 512, 1024, 2048, 4096};
static const size_t NUM_SWEEP_SIZES = sizeof(SWEEP_SIZES) / sizeof(SWEEP_SIZES[0]);

static const char *GPU_CSV_HEADER =
    "platform,impl,N,kernel_ms,h2d_ms,d2h_ms,e2e_ms,gflops_kernel,gflops_e2e,gpu_name,correct";

struct BenchConfig {
    std::string impl = "all";
    int N = 1024;
    bool sweep = false;
    int repeats = 7;
    int warmup = 2;
    int block_size = 16;
    std::string out_path = "../results/gpu_bench.csv";
    unsigned int seed = 42u;
    int verify_samples = 512;
};

struct GpuBenchRow {
    std::string platform = "gpu";
    std::string impl;
    int N = 0;
    double kernel_ms = 0.0;
    double h2d_ms = 0.0;
    double d2h_ms = 0.0;
    double e2e_ms = 0.0;
    double gflops_kernel = 0.0;
    double gflops_e2e = 0.0;
    std::string gpu_name;
    int correct = 0;
};

inline void print_usage(const char *prog_name) {
    std::cout << "Usage: " << (prog_name ? prog_name : "bench_gpu") << " [options]\n"
              << "Options:\n"
              << "  --impl <cuda_naive|cublas|all>  Implementation to benchmark (default: all)\n"
              << "  --N <size>                      Square matrix dimension N (default: 1024)\n"
              << "  --sweep                         Sweep N in {64, 128, 256, 512, 1024, 2048, 4096}\n"
              << "  --repeats <R>                   Timed repetitions for median (default: 7)\n"
              << "  --warmup <W>                    Warmup iterations before timing (default: 2)\n"
              << "  --block <B>                     2D CUDA block dimension B x B (default: 16)\n"
              << "  --seed <S>                      RNG seed for A and B (default: 42)\n"
              << "  --out <path>                    Output CSV path (default: ../results/gpu_bench.csv)\n"
              << "  --help, -h                      Show this help message\n";
}

inline bool parse_positive_int(const char *str, int min_val, int &out) {
    if (!str || *str == '\0') {
        return false;
    }
    char *endptr = nullptr;
    long val = std::strtol(str, &endptr, 10);
    if (*endptr != '\0' || val < min_val || val > std::numeric_limits<int>::max()) {
        return false;
    }
    out = static_cast<int>(val);
    return true;
}

inline bool parse_uint(const char *str, unsigned int &out) {
    if (!str || *str == '\0' || str[0] == '-') {
        return false;
    }
    char *endptr = nullptr;
    unsigned long val = std::strtoul(str, &endptr, 10);
    if (*endptr != '\0' || val > std::numeric_limits<unsigned int>::max()) {
        return false;
    }
    out = static_cast<unsigned int>(val);
    return true;
}

inline bool parse_cli(int argc, char **argv, BenchConfig &cfg, bool &show_help) {
    show_help = false;
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--help" || arg == "-h") {
            show_help = true;
            return true;
        } else if (arg == "--sweep") {
            cfg.sweep = true;
        } else if (arg == "--impl") {
            if (i + 1 >= argc) {
                std::cerr << "Error: --impl requires an argument\n";
                return false;
            }
            cfg.impl = argv[++i];
            if (cfg.impl != "cuda_naive" && cfg.impl != "cublas" && cfg.impl != "all") {
                std::cerr << "Error: invalid --impl '" << cfg.impl
                          << "' (expected cuda_naive, cublas, or all)\n";
                return false;
            }
        } else if (arg == "--N") {
            if (i + 1 >= argc || !parse_positive_int(argv[++i], 1, cfg.N)) {
                std::cerr << "Error: --N requires a positive integer\n";
                return false;
            }
        } else if (arg == "--repeats") {
            if (i + 1 >= argc || !parse_positive_int(argv[++i], 1, cfg.repeats)) {
                std::cerr << "Error: --repeats requires an integer >= 1\n";
                return false;
            }
        } else if (arg == "--warmup") {
            if (i + 1 >= argc || !parse_positive_int(argv[++i], 0, cfg.warmup)) {
                std::cerr << "Error: --warmup requires an integer >= 0\n";
                return false;
            }
        } else if (arg == "--block") {
            if (i + 1 >= argc || !parse_positive_int(argv[++i], 1, cfg.block_size) ||
                cfg.block_size > 32) {
                std::cerr << "Error: --block requires an integer in [1, 32]\n";
                return false;
            }
        } else if (arg == "--seed") {
            if (i + 1 >= argc || !parse_uint(argv[++i], cfg.seed)) {
                std::cerr << "Error: --seed requires a non-negative integer\n";
                return false;
            }
        } else if (arg == "--out") {
            if (i + 1 >= argc) {
                std::cerr << "Error: --out requires a file path\n";
                return false;
            }
            cfg.out_path = argv[++i];
            if (cfg.out_path.empty()) {
                std::cerr << "Error: --out path cannot be empty\n";
                return false;
            }
        } else {
            std::cerr << "Error: unknown argument '" << arg << "'\n";
            return false;
        }
    }
    return true;
}

inline void init_matrices(std::vector<float> &A, std::vector<float> &B, int N, unsigned int seed) {
    const size_t total = static_cast<size_t>(N) * static_cast<size_t>(N);
    A.resize(total);
    B.resize(total);
    std::srand(seed);
    const float inv_rand_max = 1.0f / static_cast<float>(RAND_MAX);
    for (size_t idx = 0; idx < total; ++idx) {
        A[idx] = static_cast<float>(std::rand()) * inv_rand_max - 0.5f;
    }
    for (size_t idx = 0; idx < total; ++idx) {
        B[idx] = static_cast<float>(std::rand()) * inv_rand_max - 0.5f;
    }
}

inline double compute_median(std::vector<double> vals) {
    if (vals.empty()) {
        return 0.0;
    }
    std::sort(vals.begin(), vals.end());
    const size_t n = vals.size();
    if (n % 2 == 1) {
        return vals[n / 2];
    }
    return 0.5 * (vals[n / 2 - 1] + vals[n / 2]);
}

inline double compute_gflops(int N, double time_ms) {
    if (N <= 0 || time_ms <= 0.0) {
        return 0.0;
    }
    const double dn = static_cast<double>(N);
    const double flops = 2.0 * dn * dn * dn;
    return flops / (time_ms * 1e6);
}

inline int verify_against_cpu_ref(const float *A,
                                  const float *B,
                                  const float *C_gpu,
                                  int N,
                                  int full_threshold = 512,
                                  int sample_count = 512,
                                  double *out_max_err = nullptr) {
    if (!A || !B || !C_gpu || N <= 0) {
        if (out_max_err) {
            *out_max_err = std::numeric_limits<double>::infinity();
        }
        return 0;
    }

    const size_t n_sz = static_cast<size_t>(N);
    const size_t total = n_sz * n_sz;
    for (size_t idx = 0; idx < total; ++idx) {
        if (!std::isfinite(C_gpu[idx])) {
            if (out_max_err) {
                *out_max_err = std::numeric_limits<double>::infinity();
            }
            return 0;
        }
    }

    double max_rel_err = 0.0;

    if (N <= full_threshold) {
        for (size_t i = 0; i < n_sz; ++i) {
            for (size_t j = 0; j < n_sz; ++j) {
                double sum = 0.0;
                for (size_t k = 0; k < n_sz; ++k) {
                    sum += static_cast<double>(A[i * n_sz + k]) *
                           static_cast<double>(B[k * n_sz + j]);
                }
                const double c_val = static_cast<double>(C_gpu[i * n_sz + j]);
                const double rel_err = std::fabs(c_val - sum) / (std::fabs(sum) + 1.0);
                if (rel_err > max_rel_err) {
                    max_rel_err = rel_err;
                }
            }
        }
    } else {
        std::vector<std::pair<int, int>> coords;
        coords.reserve(static_cast<size_t>(sample_count) + 16);

        // Include 4 corners
        coords.push_back(std::make_pair(0, 0));
        coords.push_back(std::make_pair(0, N - 1));
        coords.push_back(std::make_pair(N - 1, 0));
        coords.push_back(std::make_pair(N - 1, N - 1));

        // Include sampled diagonal positions
        const int diag_step = std::max(1, N / 32);
        for (int d = 0; d < N && static_cast<int>(coords.size()) < sample_count; d += diag_step) {
            coords.push_back(std::make_pair(d, d));
        }

        // Fill remaining budget with deterministic prime-strided positions across the matrix
        size_t pos = 0;
        const size_t stride = 2654435761ULL % (total > 1 ? total : 1);
        const size_t safe_stride = (stride == 0) ? 1 : stride;
        while (static_cast<int>(coords.size()) < sample_count) {
            pos = (pos + safe_stride) % total;
            const int r = static_cast<int>(pos / n_sz);
            const int c = static_cast<int>(pos % n_sz);
            coords.push_back(std::make_pair(r, c));
        }

        for (size_t idx = 0; idx < coords.size(); ++idx) {
            const size_t i = static_cast<size_t>(coords[idx].first);
            const size_t j = static_cast<size_t>(coords[idx].second);
            double sum = 0.0;
            for (size_t k = 0; k < n_sz; ++k) {
                sum += static_cast<double>(A[i * n_sz + k]) *
                       static_cast<double>(B[k * n_sz + j]);
            }
            const double c_val = static_cast<double>(C_gpu[i * n_sz + j]);
            const double rel_err = std::fabs(c_val - sum) / (std::fabs(sum) + 1.0);
            if (rel_err > max_rel_err) {
                max_rel_err = rel_err;
            }
        }
    }

    if (out_max_err) {
        *out_max_err = max_rel_err;
    }
    return (max_rel_err <= 1e-3) ? 1 : 0;
}

inline double compute_max_rel_error(const float *C_a, const float *C_b, size_t count) {
    if (!C_a || !C_b) {
        return std::numeric_limits<double>::infinity();
    }
    double max_rel_err = 0.0;
    for (size_t idx = 0; idx < count; ++idx) {
        if (!std::isfinite(C_a[idx]) || !std::isfinite(C_b[idx])) {
            return std::numeric_limits<double>::infinity();
        }
        const double va = static_cast<double>(C_a[idx]);
        const double vb = static_cast<double>(C_b[idx]);
        const double rel_err = std::fabs(va - vb) / (std::fabs(vb) + 1.0);
        if (rel_err > max_rel_err) {
            max_rel_err = rel_err;
        }
    }
    return max_rel_err;
}

inline std::string sanitize_csv_field(const std::string &s) {
    std::string cleaned = s;
    for (size_t i = 0; i < cleaned.size(); ++i) {
        if (cleaned[i] == ',' || cleaned[i] == '\r' || cleaned[i] == '\n') {
            cleaned[i] = ' ';
        }
    }
    const std::string ws = " \t\r\n";
    const size_t first = cleaned.find_first_not_of(ws);
    if (first == std::string::npos) {
        return "";
    }
    const size_t last = cleaned.find_last_not_of(ws);
    return cleaned.substr(first, last - first + 1);
}

inline bool append_gpu_csv_row(const std::string &out_path, const GpuBenchRow &row) {
    bool needs_header = true;
    {
        std::ifstream fin(out_path.c_str(), std::ios::binary | std::ios::ate);
        if (fin.is_open() && fin.tellg() > 0) {
            needs_header = false;
        }
    }

    std::ofstream fout(out_path.c_str(), std::ios::app);
    if (!fout.is_open()) {
        std::cerr << "Error: cannot open output CSV file '" << out_path << "'\n";
        return false;
    }

    if (needs_header) {
        fout << GPU_CSV_HEADER << "\n";
    }

    const std::string safe_platform = sanitize_csv_field(row.platform);
    const std::string safe_impl = sanitize_csv_field(row.impl);
    const std::string safe_gpu_name = sanitize_csv_field(row.gpu_name);

    std::ostringstream oss;
    oss << safe_platform << ","
        << safe_impl << ","
        << row.N << ","
        << std::fixed << std::setprecision(4) << row.kernel_ms << ","
        << std::fixed << std::setprecision(4) << row.h2d_ms << ","
        << std::fixed << std::setprecision(4) << row.d2h_ms << ","
        << std::fixed << std::setprecision(4) << row.e2e_ms << ","
        << std::fixed << std::setprecision(2) << row.gflops_kernel << ","
        << std::fixed << std::setprecision(2) << row.gflops_e2e << ","
        << safe_gpu_name << ","
        << row.correct << "\n";

    fout << oss.str();
    fout.flush();
    return static_cast<bool>(fout);
}

}  // namespace gpu_bench

#endif  // GPU_BENCH_UTILS_HPP
