NVCC ?= nvcc
ARCH ?= native
CXXFLAGS := -O3 -std=c++14
INCLUDES := -Isrc
LDFLAGS := -lcublas

BIN_DIR := bin
TARGET := $(BIN_DIR)/bench_gpu
SRC := src/matmul_cuda.cu
DEPS := src/gpu_bench_utils.hpp

.PHONY: all test bench clean

all: $(TARGET)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(TARGET): $(SRC) $(DEPS) | $(BIN_DIR)
	$(NVCC) $(CXXFLAGS) -arch=$(ARCH) $(INCLUDES) $(SRC) -o $(TARGET) $(LDFLAGS)

test: $(TARGET)
	rm -f /tmp/gpu_test.csv
	./$(TARGET) --impl all --N 64 --repeats 5 --warmup 1 --out /tmp/gpu_test.csv
	./$(TARGET) --impl all --N 256 --repeats 5 --warmup 1 --out /tmp/gpu_test.csv
	cat /tmp/gpu_test.csv

bench: $(TARGET)
	./$(TARGET) --sweep --impl all --repeats 7 --warmup 2 --out ../results/gpu_bench.csv

clean:
	rm -rf $(BIN_DIR)
