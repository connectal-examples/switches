
INTERFACES = LedControllerRequest SwitchRequest SwitchIndication
BSVFILES = Controller.bsv Top.bsv SwitchPins.bsv
CPPFILES= testswitches.cpp
NUMBER_OF_MASTERS =0
PIN_TYPE = SwitchPins
CONNECTALFLAGS = -C $(BOARD)/sources/pinout-$(BOARD).xdc

gentarget:: $(BOARD)/sources/pinout-$(BOARD).xdc
$(BOARD)/sources/pinout-$(BOARD).xdc: pinout.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py $(CONNECTALDIR)/boardinfo/$(BOARD).json pinout.json > $(BOARD)/sources/pinout-$(BOARD).xdc

include $(CONNECTALDIR)/Makefile.connectal
