COMPILER      = ca65
COMPILERFLAGS = -g

LINKER	    = ld65
LINKERFLAGS = -t nes

SRCS = $(wildcard *.asm)
OBJS = $(subst .asm,.o,$(SRCS))
ROMS = $(subst .asm,.nes,$(SRCS))

%.o: %.asm
	$(COMPILER) $(COMPILERFLAGS) $<

%.nes: %.o
	$(LINKER) $(LINKERFLAGS) --dbgfile $(subst .o,.dbg,$<) $< -o $@

compile_roms: $(ROMS)

clean: $(OBJS)
	rm $(OBJS)

distclean: clean
	rm $(ROMS) *.dbg

all: compile_roms
	