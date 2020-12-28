# kernel-style V=1 build verbosity
ifeq ('$(origin V)', 'command line')
	BUILD_VERBOSE = $(V)
endif
ifeq ($(BUILD_VERBOSE),1)
	Q =
else
	Q = @
endif

ifeq ($(OS),Windows_NT)
	SHELL := pwsh.exe
else
	SHELL := pwsh
endif

.SHELLFLAGS := -NoProfile -Command

namePrefix = vFlatcar
all: %

%:
	./GenerateFlatcarConfig.ps1 -namePrefix $(namePrefix) -numOfHosts $*

vagrant:
	vagrant up
clean:
	-Get-ChildItem | where {$$_.Name -like '$(namePrefix)*'} | remove-item -recurse -force -errorAction SilentlyContinue
	-vagrant down