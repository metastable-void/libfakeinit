#include <stdio.h>

int main (int argc, char **argv)
{
	if (argc < 3) {
		return -1;
	}
	FILE *input = fopen ("/dev/urandom", "r");
	FILE *output1 = fopen (argv[1], "w");
	FILE *output2 = fopen (argv[2], "w");
	char buf[4096];
	char buf_random[4096];
	while (!feof (stdin)) {
		size_t read = fread (buf, 1, 4096, stdin);
		fread (buf_random, 1, read, input);
		int i;
		for (i = 0; i < read; i++) {
			buf[i] = buf[i] ^ buf_random[i];
		}
		fwrite (buf, 1, read, output1);
		fwrite (buf_random, 1, read, output2);
		fprintf (stderr, "written %d bytes\n", read);
	}
	fclose (input);
	fclose (output1);
	fclose (output2);
	return 0;
}

