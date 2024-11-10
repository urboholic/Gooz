#include <stdlib.h>
#include <stdio.h>
#include <readline/readline.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include "../include/input.h"

int main(void) {
    char **command;
    char *input;
    pid_t child;
    int stat_loc;

    while(1) {

        input = readline("gooz ~> ");
        command = user_input(input);

        // If input contains cd, a fork should not be created.
        // we want the path change to happen on the parent process.
        if(strcmp(command[0], "cd") == 0) {
            if(cd(command[1]) < 0) {
                perror(command[1]);
            }
            continue;
        }

        child = fork();

        if(child < 0) {
            // Write system error
            perror("fork failed");
            exit(1);
        } else if(child == 0){
            // If execvp is successfull, the child will never return
            if(execvp(command[0], command) < 0) {
                // Write system error
                free(input);
                free(command);
                perror(command[0]);
                exit(1);
            }
        } else {
            // Wait for child process to complete
            waitpid(child, &stat_loc, WUNTRACED);
        }

        // Free allocated memory
        free(input);
        free(command);
    }

    return 0;
}
