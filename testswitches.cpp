
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>

#include "SwitchRequestProxy.h"
#include "SwitchIndicationWrapper.h"
#include "LedControllerRequestProxy.h"
#include "GeneratedTypes.h"

int switchValues = 0;
class SwitchIndication : public SwitchIndicationWrapper
{
public:
  SwitchIndication(int id) : SwitchIndicationWrapper(id) { }
  virtual void switchPositions ( const uint32_t left, const uint32_t center, const uint32_t right ) {
    printf("switches left=%d center=%d right=%d\n", left, center, right);
    switchValues = left << 2 | center << 1 | right;
  }
  virtual void switchesChanged ( const uint32_t left, const uint32_t center, const uint32_t right ) {
    printf("switches changed left=%d center=%d right=%d\n", left, center, right);
    switchValues = left << 2 | center << 1 | right;
  }
};

int main(int argc, const char **argv)
{
  LedControllerRequestProxy *device = new LedControllerRequestProxy(IfcNames_LedControllerRequestPortal);
  SwitchRequestProxy *switches = new SwitchRequestProxy(IfcNames_SwitchRequestPortal);
  SwitchIndicationWrapper *ind = new SwitchIndication(IfcNames_SwitchIndicationPortal);

  printf("Starting Switch test\n");

  portalExec_start();

#ifdef BSIM
  // BSIM does not run very many cycles per second
  int blinkinterval = 10;
#else
  int blinkinterval = 100000000; // 100MHz cycles
#endif
  int sleepinterval = 1; // seconds
  for (int i = 0; i < 20; i++) {
    device->setLeds(switchValues, blinkinterval);
    switches->getSwitchPositions();
    sleep(sleepinterval);
  }
  printf("Done.\n");
}
