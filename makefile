sha-3: sha-3.o
	ld -m elf_i386 -o sha-3 sha-3.o
sha-3.o: sha-3.asm
	nasm -f elf32 -o sha-3.o sha-3.asm
