MAKEFLAGS += --no-builtin-rules

ifeq ($(origin CXX), default)
CXX=g++
endif
CXXFLAGS?=-g -Og

LINK_LIBRARIES=-pthread -lcmark -lhttp_parser -lfmt -lctemplate
CXXSETTINGS=-Wall -Wextra -Wconversion -Wextra-semi -Wold-style-cast -Wnon-virtual-dtor -pedantic -pedantic-errors -fvisibility=hidden -std=c++20 -fwrapv -fstrict-enums
LDSETTINGS=

STATIC_FILES=static/*

bin/site : src/main.o sgen/index.html.o sgen/static.hpp
	mkdir -p bin
	$(CXX) $(LDSETTINGS) $(LDFLAGS) src/main.o sgen/index.html.o $(LINK_LIBRARIES) -o $@

src/main.o : sgen/static.hpp

.PHONY: clean
clean:
	rm -rf bin/*
	rm -rf src/*.o
	rm -rf static/*.o
	rm -rf sgen/*

src/%.o : src/%.cpp
	$(CXX) $(CXXSETTINGS) $(CXXFLAGS) -c $< -o $@

sgen/static.hpp :
	mkdir -p sgen
	echo "#pragma once" >sgen/static.hpp
	echo "#include <string_view>" >sgen/static.hpp
	echo 'extern "C" {' >>sgen/static.hpp
	for f in ${STATIC_FILES}; do echo $$f | awk '{gsub(/\//, "_"); gsub(/\./, "_"); print "extern const char _binary_" $$0 "_start[];";}' >>sgen/static.hpp; done
	for f in ${STATIC_FILES}; do echo $$f | awk '{gsub(/\//, "_"); gsub(/\./, "_"); print "extern const char _binary_" $$0 "_end[];";}' >>sgen/static.hpp; done
	for f in ${STATIC_FILES}; do echo $$f | awk '{gsub(/\//, "_"); gsub(/\./, "_"); print "const size_t _binary_" $$0 "_size = _binary_" $$0 "_end - _binary_" $$0 "_start;";}' >>sgen/static.hpp; done
	echo '}' >>sgen/static.hpp
	echo 'namespace sfile {' >>sgen/static.hpp
	for f in ${STATIC_FILES}; do echo $$f | awk '{gsub(/\//, "_"); gsub(/\./, "_"); gsub(/^static_/, ""); print "const std::string_view " $$0 " = std::string_view(_binary_static_" $$0 "_start, _binary_static_" $$0 "_size);";}' >>sgen/static.hpp; done
	echo '}' >>sgen/static.hpp

sgen/%.o : static/%
	objcopy --input-target binary --rename-section .data=.rodata,alloc,load,readonly,data,contents --output-target elf64-x86-64 --binary-architecture i386:x86-64 $< $@
