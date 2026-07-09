main: main.o
	ld -o main main.o

main.o: main.asm
	nasm -f elf64 main.asm -o main.o

clean:
	rm -f main main.o