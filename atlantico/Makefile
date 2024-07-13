all:
	ca65 atlantico.asm && ld65 -C ../nes.cfg atlantico.o -o atlantico.nes --dbgfile atlantico.dbg && fceux atlantico.nes
