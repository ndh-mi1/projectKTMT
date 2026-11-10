/*
 * matmul_openmp.c - Nhan ma tran float32: Cache Tiling + da luong OpenMP.
 * Nac thu 3 cua ablation: giu nguyen kernel cua ban tiled (i-j-k trong tung
 * khoi), chi them song song hoa de do rieng dong gop cua da luong.
 */
#include <omp.h>
#include <stdlib.h>
#include <string.h>

#include "matmul.h"

static inline size_t min_size(size_t a, size_t b)
{
    return a < b ? a : b;
}

/* Tinh mot khoi (ii, jj) cua C. */
static inline void multiply_tile(const float *A, const float *B, float *C,
                                 size_t N, size_t tile, size_t ii, size_t jj)
{
    size_t i_end = min_size(ii + tile, N);
    size_t j_end = min_size(jj + tile, N);

    for (size_t kk = 0; kk < N; kk += tile) {
        size_t k_end = min_size(kk + tile, N);

        for (size_t i = ii; i < i_end; i++) {
            for (size_t j = jj; j < j_end; j++) {
                float sum = C[i * N + j];
                for (size_t k = kk; k < k_end; k++) {
                    sum += A[i * N + k] * B[k * N + j];
                }
                C[i * N + j] = sum;
            }
        }
    }
}

void matmul_openmp(const float *A, const float *B, float *C, size_t N, size_t tile)
{
    if (tile == 0 || tile > N) {
        tile = N;
    }

    memset(C, 0, N * N * sizeof *C);

    /* Mot luong: khong mo vung parallel. Tren MinGW gcc 12.1, vung parallel
     * chi co 1 luong gay heap corruption trong libgomp (0xC0000374), du
     * kernel the nao. Duong chay nay cung kernel nen van so sanh duoc. */
    if (omp_get_max_threads() == 1) {
        for (size_t ii = 0; ii < N; ii += tile) {
            for (size_t jj = 0; jj < N; jj += tile) {
                multiply_tile(A, B, C, N, tile, ii, jj);
            }
        }
        return;
    }

    /* Mac dinh la static theo yeu cau nhom; dat OMP_SCHEDULE=dynamic de thu
     * lai tren CPU lai (P-core + E-core) ma khong can bien dich lai. */
    if (getenv("OMP_SCHEDULE") == NULL) {
        omp_set_schedule(omp_sched_static, 0);
    }

    /* Moi cap (ii, jj) ghi vao mot khoi rieng cua C nen cac luong khong
     * ghi chong len nhau. collapse(2) chia theo ca hang va cot cua khoi,
     * tao nhieu viec hon so voi chi chia theo hang khi N nho. */
#pragma omp parallel for collapse(2) schedule(runtime)
    for (size_t ii = 0; ii < N; ii += tile) {
        for (size_t jj = 0; jj < N; jj += tile) {
            multiply_tile(A, B, C, N, tile, ii, jj);
        }
    }
}
