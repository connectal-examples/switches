
// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import FIFO::*;
import GetPut::*;
import Leds::*;
import SwitchPins::*;

typedef enum {LedControllerRequestPortal, SwitchRequestPortal, SwitchIndicationPortal} IfcNames deriving (Eq,Bits);

typedef struct {
   Bit#(8) leds;
   Bit#(32) duration;
   } LedControllerCmd deriving (Bits);

interface SwitchRequest;
   method Action getSwitchPositions();
endinterface

interface SwitchIndication;
   method Action switchPositions(Bit#(1) left, Bit#(1) center, Bit#(1) right);
   method Action switchesChanged(Bit#(1) left, Bit#(1) center, Bit#(1) right);
endinterface

interface LedControllerRequest;
   method Action setLeds(Bit#(8) v, Bit#(32) duration);
endinterface

interface Controller;
   interface LedControllerRequest ledRequest;
   interface SwitchRequest switchRequest;
   interface LEDS leds;
   interface SwitchPins switchPins;
endinterface

module mkControllerRequest#(SwitchIndication switchIndication)(Controller);

   Reg#(Bit#(8)) ledsValue <- mkReg(0);
   Reg#(Bit#(32)) remainingDuration <- mkReg(0);

   Reg#(Bool)   changedReg <- mkReg(False);
   Reg#(Bit#(3)) switchReg <- mkReg(0);

   FIFO#(LedControllerCmd) ledsCmdFifo <- mkSizedFIFO(32);

   rule switchChanged if (changedReg);
      switchIndication.switchesChanged(switchReg[2], switchReg[1], switchReg[0]);
   endrule

   rule updateLeds;
      let duration = remainingDuration;
      if (duration == 0) begin
	 let cmd <- toGet(ledsCmdFifo).get();
	 $display("ledsValue <= %b", cmd.leds);
	 ledsValue <= cmd.leds;
	 duration = cmd.duration;
      end
      else begin
	 duration = duration - 1;
      end
      remainingDuration <= duration;
   endrule

   interface LedControllerRequest ledRequest;
       method Action setLeds(Bit#(8) v, Bit#(32) duration);
	  $display("Enqueing v=%d duration=%d", v, duration);
	  ledsCmdFifo.enq(LedControllerCmd { leds: truncate(v), duration: duration });
       endmethod
   endinterface
   interface SwitchRequest switchRequest;
      method Action getSwitchPositions();
	 switchIndication.switchPositions(switchReg[2], switchReg[1], switchReg[0]);
      endmethod
   endinterface
   interface LEDS leds;
      method Bit#(LedsWidth) leds(); return truncate(ledsValue._read); endmethod
   endinterface
   interface SwitchPins switchPins;
      method Action gpio_sw(Bit#(1) left, Bit#(1) center, Bit#(1) right);
	 let switchValue = {left, center, right};
	 changedReg <= (switchValue != switchReg);
	 switchReg <= switchValue;
      endmethod
   endinterface
endmodule
