#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    const char *emulator = getenv("TFT_EMULATOR");
    if (emulator == NULL || emulator[0] == '\0' || access(emulator, X_OK) != 0) {
        fputs("Mactician Game Host could not find its Android Emulator executable.\n", stderr);
        return EXIT_FAILURE;
    }

    argv[0] = (char *)emulator;
    execv(emulator, argv);

    fprintf(stderr, "Mactician Game Host could not start Android Emulator: %s\n", strerror(errno));
    return EXIT_FAILURE;
}
