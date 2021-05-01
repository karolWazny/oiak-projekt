sha-3: sha-3.o
	gcc -o sha-3 sha-3.o
sha-3.o: sha-3.asm
	nasm -f elf -F dwarf -g -o sha-3.o sha-3.asm
