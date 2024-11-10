#ifndef INPUT_H
#define INPUT_H
#include "../src/input.c"

// Function checks to see if the command is a path.
int cd(char *path);

// This function is used to receive user input
char **user_input(char *input);


#endif
