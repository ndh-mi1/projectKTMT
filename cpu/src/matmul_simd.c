/*
 * matmul_simd.c - Nhan ma tran float32: Cache Tiling + OpenMP + SIMD (AVX2/FMA).
 * Nac thu 4 cua ablation: giu cach chia khoi va chia luong cua matmul_openmp,
 * doi kernel trong khoi sang thu tu i-k-j va tinh 8 phan tu float moi lenh FMA.
 *
 * Vi sao i-k-j: voi i, k co dinh, vong j quet lien tiep tren hang cua B va C
 * (truy cap stride-1), nen nap/ghi duoc 8 so float lien nhau bang mot lenh.
 */
#include <immintrin.h>
#include <omp.h>
#include <stdlib.h>
#include <string.h>

#include "matmul.h"

static inline size_t min_size(size_t a, size_t b)
{
    return a < b ? a : b;
}

/* Kernel AVX2 + FMA cho mot khoi (ii, jj) cua C.
 * target("avx2,fma") cho phep dung lenh AVX2 ma khong can them -mavx2 vao
 * Makefile chung. Chi dung loadu/storeu (khong yeu cau can le 32 byte) va it
 * bien __m256 de tranh loi can le stack cua gcc MinGW tren Windows. */
__attribute__((target("avx2,fma")))
static void tile_avx2(const float *A, const float *B, float *C,
                      size_t N, size_t tile, size_t ii, size_t jj)
{
    size_t i_end = min_size(ii + tile, N);
    size_t j_end = min_size(jj + tile, N);
    size_t j_vec_end = jj + ((j_end - jj) / 8) * 8;

    for (size_t kk = 0; kk < N; kk += tile) {
        size_t k_end = min_size(kk + tile, N);

        for (size_t i = ii; i < i_end; i++) {
            float *c_row = C + i * N;
            for (size_t k = kk; k < k_end; k++) {
                const float a_ik = A[i * N + k];
                const float *b_row = B + k * N;
                const __m256 a_vec = _mm256_set1_ps(a_ik);

                size_t j = jj;
                for (; j < j_vec_end; j += 8) {
                    __m256 c_vec = _mm256_loadu_ps(c_row + j);
                    c_vec = _mm256_fmadd_ps(a_vec, _mm256_loadu_ps(b_row + j), c_vec);
                    _mm256_storeu_ps(c_row + j, c_vec);
                }
                for (; j < j_end; j++) { /* phan du khi do rong khoi khong chia het cho 8 */
                    c_row[j] += a_ik * b_row[j];
                }
            }
        }
    }
}

/* Du phong cho may khong co AVX2/FMA: cung thu tu i-k-j, khong dung intrinsic. */
static void tile_scalar(const float *A, const float *B, float *C,
                        size_t N, size_t tile, size_t ii, size_t jj)
{
    size_t i_end = min_size(ii + tile, N);
    size_t j_end = min_size(jj + tile, N);

    for (size_t kk = 0; kk < N; kk += tile) {
        size_t k_end = min_size(kk + tile, N);
        for (size_t i = ii; i < i_end; i++) {
            for (size_t k = kk; k < k_end; k++) {
                const float a_ik = A[i * N + k];
                for (size_t j = jj; j < j_end; j++) {
                    C[i * N + j] += a_ik * B[k * N + j];
                }
            }
        }
    }
}

typedef void (*tile_fn)(const float *, const float *, float *, size_t, size_t, size_t, size_t);

void matmul_simd(const float *A, const float *B, float *C, size_t N, size_t tile)
{
    if (tile == 0 || tile > N) {
        tile = N;
    }

    __builtin_cpu_init();
    tile_fn kernel = (__builtin_cpu_supports("avx2") && __builtin_cpu_supports("fma"))
                         ? tile_avx2
                         : tile_scalar;

    memset(C, 0, N * N * sizeof *C);

    /* Mot luong: khong mo vung parallel (tranh loi libgomp cua MinGW gcc 12.1,
     * xem matmul_openmp.c). */
    if (omp_get_max_threads() == 1) {
        for (size_t ii = 0; ii < N; ii += tile) {
            for (size_t jj = 0; jj < N; jj += tile) {
                kernel(A, B, C, N, tile, ii, jj);
            }
        }
        return;
    }

    if (getenv("OMP_SCHEDULE") == NULL) {
        omp_set_schedule(omp_sched_static, 0);
    }

#pragma omp parallel for collapse(2) schedule(runtime)
    for (size_t ii = 0; ii < N; ii += tile) {
        for (size_t jj = 0; jj < N; jj += tile) {
            kernel(A, B, C, N, tile, ii, jj);
        }
    }
}
