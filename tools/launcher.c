#include <mach-o/dyld.h>
#include <unistd.h>
#include <libgen.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
int main(int argc, char **argv) {
    char executable[PATH_MAX], runtime[PATH_MAX], pack[PATH_MAX];
    uint32_t size = sizeof(executable);
    if (_NSGetExecutablePath(executable, &size) != 0) return 1;
    char *folder = dirname(executable);
    snprintf(runtime, sizeof(runtime), "%s/PaopaoTangEngine", folder);
    snprintf(pack, sizeof(pack), "%s/../Resources/game.pck", folder);
    char **args = calloc(argc + 4, sizeof(char *));
    args[0] = runtime; args[1] = "--main-pack"; args[2] = pack;
    for (int i = 1; i < argc; i++) args[i + 2] = argv[i];
    execv(runtime, args);
    perror("Could not start PaopaoTang");
    return 1;
}
