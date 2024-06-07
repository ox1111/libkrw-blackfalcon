#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include "libkrw.h"

int main(void) {
    // 파일 경로
    const char *filePath = "./test.txt";

    // 커널 기본 주소 가져오기
    uint64_t base = 0;
    int r = kbase(&base);
    printf("base: %d, 0x%llx\n", r, base);
    if (r != 0) return r;

    // 파일 접근 확인을 위해 커널 함수 호출
    uint32_t magic = 0;
    r = kread(base, &magic, sizeof(magic));
    printf("magic: %d, 0x%x\n", r, magic);
    if (r != 0) return r;

    // 파일 열기 시도
    int fd = open(filePath, O_RDONLY);
    
    if (fd == -1) {
        // 파일을 열지 못한 경우
        perror("Failed to open file");
        return 1;
    } else {
        // 파일을 성공적으로 연 경우
        printf("Successfully opened %s\n", filePath);

        // 파일 닫기
        close(fd);
    }

    return 0;
}

