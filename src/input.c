#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int cd(char *path) {
    printf("%s", path);
    return chdir(path);
}

char **user_input(char *input) {

    char **command = malloc(8 * sizeof(char *));
    if(command == NULL) {
        perror("Could not allocate memory for malloc");
    }
    char *separator = " ";
    char *parsed;
    int index = 0;

    parsed = strtok(input, separator);

    while(parsed != NULL){
        command[index++] = parsed;

        parsed = strtok(NULL, separator);
    }

    command[index] = NULL;

    return command;
}
