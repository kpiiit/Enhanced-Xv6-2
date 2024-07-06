
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a5010113          	add	sp,sp,-1456 # 80008a50 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	add	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	add	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	add	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	sllw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	sll	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	sll	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8c070713          	add	a4,a4,-1856 # 80008910 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	1fe78793          	add	a5,a5,510 # 80006260 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	add	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	add	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffbc067>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	02c78793          	add	a5,a5,44 # 800010d8 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srl	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	add	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	add	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	add	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	add	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	716080e7          	jalr	1814(ra) # 80002840 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addw	s2,s2,1
    80000144:	0485                	add	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	add	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	add	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	add	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000180:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	8cc50513          	add	a0,a0,-1844 # 80010a50 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	cac080e7          	jalr	-852(ra) # 80000e38 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	8bc48493          	add	s1,s1,-1860 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	94c90913          	add	s2,s2,-1716 # 80010ae8 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	a50080e7          	jalr	-1456(ra) # 80001c04 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	4ce080e7          	jalr	1230(ra) # 8000268a <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	20c080e7          	jalr	524(ra) # 800023d6 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	87270713          	add	a4,a4,-1934 # 80010a50 <cons>
    800001e6:	0017869b          	addw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	and	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	add	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	5da080e7          	jalr	1498(ra) # 800027ea <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
      break;

    dst++;
    8000021e:	0a05                	add	s4,s4,1
    --n;
    80000220:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	82850513          	add	a0,a0,-2008 # 80010a50 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	cbc080e7          	jalr	-836(ra) # 80000eec <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	81250513          	add	a0,a0,-2030 # 80010a50 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	ca6080e7          	jalr	-858(ra) # 80000eec <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	add	sp,sp,96
    80000264:	8082                	ret
      if(n < target){
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
        cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	86f72d23          	sw	a5,-1926(a4) # 80010ae8 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	add	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
    uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	add	sp,sp,16
    80000296:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ba:	1101                	add	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	add	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c8:	00010517          	auipc	a0,0x10
    800002cc:	78850513          	add	a0,a0,1928 # 80010a50 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	b68080e7          	jalr	-1176(ra) # 80000e38 <acquire>

  switch(c){
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	5a8080e7          	jalr	1448(ra) # 80002896 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	75a50513          	add	a0,a0,1882 # 80010a50 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	bee080e7          	jalr	-1042(ra) # 80000eec <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	add	sp,sp,32
    80000310:	8082                	ret
  switch(c){
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031a:	00010717          	auipc	a4,0x10
    8000031e:	73670713          	add	a4,a4,1846 # 80010a50 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
      consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00010797          	auipc	a5,0x10
    80000348:	70c78793          	add	a5,a5,1804 # 80010a50 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	and	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00010797          	auipc	a5,0x10
    80000376:	7767a783          	lw	a5,1910(a5) # 80010ae8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6ca70713          	add	a4,a4,1738 # 80010a50 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	6ba48493          	add	s1,s1,1722 # 80010a50 <cons>
    while(cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a4:	37fd                	addw	a5,a5,-1
    800003a6:	07f7f713          	and	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
    while(cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	67e70713          	add	a4,a4,1662 # 80010a50 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	70f72423          	sw	a5,1800(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
      consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	64278793          	add	a5,a5,1602 # 80010a50 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	and	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	6ac7ad23          	sw	a2,1722(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	6ae50513          	add	a0,a0,1710 # 80010ae8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	ff8080e7          	jalr	-8(ra) # 8000243a <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void
consoleinit(void)
{
    8000044c:	1141                	add	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	add	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	5f450513          	add	a0,a0,1524 # 80010a50 <cons>
    80000464:	00001097          	auipc	ra,0x1
    80000468:	944080e7          	jalr	-1724(ra) # 80000da8 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00041797          	auipc	a5,0x41
    80000478:	18c78793          	add	a5,a5,396 # 80041600 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	add	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	add	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	add	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	add	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	add	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	add	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	sll	a5,a5,0x20
    800004c8:	9381                	srl	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	add	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	add	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	add	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	add	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addw	a4,a4,-1
    8000050e:	1702                	sll	a4,a4,0x20
    80000510:	9301                	srl	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	add	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	add	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	add	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	add	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00010797          	auipc	a5,0x10
    8000054c:	5c07a423          	sw	zero,1480(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	add	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b7e50513          	add	a0,a0,-1154 # 800080e8 <digits+0xa8>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	34f72a23          	sw	a5,852(a4) # 800088d0 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	add	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	add	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00010d97          	auipc	s11,0x10
    800005bc:	558dad83          	lw	s11,1368(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	add	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	add	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	50250513          	add	a0,a0,1282 # 80010af8 <pr>
    800005fe:	00001097          	auipc	ra,0x1
    80000602:	83a080e7          	jalr	-1990(ra) # 80000e38 <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	add	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	add	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	add	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	add	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srl	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	sll	s2,s2,0x4
    800006d4:	34fd                	addw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	add	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	add	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	add	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	add	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00010517          	auipc	a0,0x10
    80000758:	3a450513          	add	a0,a0,932 # 80010af8 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	790080e7          	jalr	1936(ra) # 80000eec <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	add	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00010497          	auipc	s1,0x10
    80000774:	38848493          	add	s1,s1,904 # 80010af8 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	add	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	626080e7          	jalr	1574(ra) # 80000da8 <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	add	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	add	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	add	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	34850513          	add	a0,a0,840 # 80010b18 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	5d0080e7          	jalr	1488(ra) # 80000da8 <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	add	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	add	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	add	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	5f8080e7          	jalr	1528(ra) # 80000dec <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	0d47a783          	lw	a5,212(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	and	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	66a080e7          	jalr	1642(ra) # 80000e8c <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	add	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	0a47b783          	ld	a5,164(a5) # 800088d8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	0a473703          	ld	a4,164(a4) # 800088e0 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	add	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00010a17          	auipc	s4,0x10
    80000862:	2baa0a13          	add	s4,s4,698 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	07248493          	add	s1,s1,114 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	07298993          	add	s3,s3,114 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	and	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	and	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	add	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	baa080e7          	jalr	-1110(ra) # 8000243a <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	add	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	add	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	add	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00010517          	auipc	a0,0x10
    800008d0:	24c50513          	add	a0,a0,588 # 80010b18 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	564080e7          	jalr	1380(ra) # 80000e38 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	ff47a783          	lw	a5,-12(a5) # 800088d0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	ffa73703          	ld	a4,-6(a4) # 800088e0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	fea7b783          	ld	a5,-22(a5) # 800088d8 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	21e98993          	add	s3,s3,542 # 80010b18 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	fd648493          	add	s1,s1,-42 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	fd690913          	add	s2,s2,-42 # 800088e0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	abc080e7          	jalr	-1348(ra) # 800023d6 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	1e848493          	add	s1,s1,488 # 80010b18 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	f8e7be23          	sd	a4,-100(a5) # 800088e0 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	596080e7          	jalr	1430(ra) # 80000eec <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	add	sp,sp,48
    8000096c:	8082                	ret
    for(;;)
    8000096e:	a001                	j	8000096e <uartputc+0xb4>

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	add	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	and	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	add	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000994:	1101                	add	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	add	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	16248493          	add	s1,s1,354 # 80010b18 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	478080e7          	jalr	1144(ra) # 80000e38 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	51a080e7          	jalr	1306(ra) # 80000eec <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	add	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	add	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	add	s0,sp,32
  struct run *r;

  int ref = PA2REF(pa);
    800009f0:	800007b7          	lui	a5,0x80000
    800009f4:	97aa                	add	a5,a5,a0
    800009f6:	83b1                	srl	a5,a5,0xc
    800009f8:	0007849b          	sext.w	s1,a5
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009fc:	03451793          	sll	a5,a0,0x34
    80000a00:	ebd9                	bnez	a5,80000a96 <kfree+0xb2>
    80000a02:	892a                	mv	s2,a0
    80000a04:	00042797          	auipc	a5,0x42
    80000a08:	d9478793          	add	a5,a5,-620 # 80042798 <end>
    80000a0c:	08f56563          	bltu	a0,a5,80000a96 <kfree+0xb2>
    80000a10:	47c5                	li	a5,17
    80000a12:	07ee                	sll	a5,a5,0x1b
    80000a14:	08f57163          	bgeu	a0,a5,80000a96 <kfree+0xb2>
    panic("kfree");

  acquire(&Ref.lock);
    80000a18:	00010517          	auipc	a0,0x10
    80000a1c:	15850513          	add	a0,a0,344 # 80010b70 <Ref>
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	418080e7          	jalr	1048(ra) # 80000e38 <acquire>
  if(--Ref.references[ref] > 0){
    80000a28:	00448793          	add	a5,s1,4
    80000a2c:	078a                	sll	a5,a5,0x2
    80000a2e:	00010717          	auipc	a4,0x10
    80000a32:	14270713          	add	a4,a4,322 # 80010b70 <Ref>
    80000a36:	97ba                	add	a5,a5,a4
    80000a38:	4798                	lw	a4,8(a5)
    80000a3a:	377d                	addw	a4,a4,-1
    80000a3c:	0007069b          	sext.w	a3,a4
    80000a40:	c798                	sw	a4,8(a5)
    80000a42:	06d04263          	bgtz	a3,80000aa6 <kfree+0xc2>
    release(&Ref.lock);
    return;
  }
  release(&Ref.lock);
    80000a46:	00010517          	auipc	a0,0x10
    80000a4a:	12a50513          	add	a0,a0,298 # 80010b70 <Ref>
    80000a4e:	00000097          	auipc	ra,0x0
    80000a52:	49e080e7          	jalr	1182(ra) # 80000eec <release>

  memset(pa, 1, PGSIZE);   // Fill with junk to catch dangling refs.
    80000a56:	6605                	lui	a2,0x1
    80000a58:	4585                	li	a1,1
    80000a5a:	854a                	mv	a0,s2
    80000a5c:	00000097          	auipc	ra,0x0
    80000a60:	4d8080e7          	jalr	1240(ra) # 80000f34 <memset>
  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a64:	00010497          	auipc	s1,0x10
    80000a68:	0ec48493          	add	s1,s1,236 # 80010b50 <kmem>
    80000a6c:	8526                	mv	a0,s1
    80000a6e:	00000097          	auipc	ra,0x0
    80000a72:	3ca080e7          	jalr	970(ra) # 80000e38 <acquire>

  r->next = kmem.freelist;
    80000a76:	6c9c                	ld	a5,24(s1)
    80000a78:	00f93023          	sd	a5,0(s2)
  kmem.freelist = r;
    80000a7c:	0124bc23          	sd	s2,24(s1)

  release(&kmem.lock);
    80000a80:	8526                	mv	a0,s1
    80000a82:	00000097          	auipc	ra,0x0
    80000a86:	46a080e7          	jalr	1130(ra) # 80000eec <release>
}
    80000a8a:	60e2                	ld	ra,24(sp)
    80000a8c:	6442                	ld	s0,16(sp)
    80000a8e:	64a2                	ld	s1,8(sp)
    80000a90:	6902                	ld	s2,0(sp)
    80000a92:	6105                	add	sp,sp,32
    80000a94:	8082                	ret
    panic("kfree");
    80000a96:	00007517          	auipc	a0,0x7
    80000a9a:	5ca50513          	add	a0,a0,1482 # 80008060 <digits+0x20>
    80000a9e:	00000097          	auipc	ra,0x0
    80000aa2:	a9e080e7          	jalr	-1378(ra) # 8000053c <panic>
    release(&Ref.lock);
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	0ca50513          	add	a0,a0,202 # 80010b70 <Ref>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	43e080e7          	jalr	1086(ra) # 80000eec <release>
    return;
    80000ab6:	bfd1                	j	80000a8a <kfree+0xa6>

0000000080000ab8 <freerange>:
{
    80000ab8:	7179                	add	sp,sp,-48
    80000aba:	f406                	sd	ra,40(sp)
    80000abc:	f022                	sd	s0,32(sp)
    80000abe:	ec26                	sd	s1,24(sp)
    80000ac0:	e84a                	sd	s2,16(sp)
    80000ac2:	e44e                	sd	s3,8(sp)
    80000ac4:	e052                	sd	s4,0(sp)
    80000ac6:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ac8:	6785                	lui	a5,0x1
    80000aca:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ace:	00e504b3          	add	s1,a0,a4
    80000ad2:	777d                	lui	a4,0xfffff
    80000ad4:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000ad6:	94be                	add	s1,s1,a5
    80000ad8:	0095ee63          	bltu	a1,s1,80000af4 <freerange+0x3c>
    80000adc:	892e                	mv	s2,a1
    kfree(p);
    80000ade:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000ae0:	6985                	lui	s3,0x1
    kfree(p);
    80000ae2:	01448533          	add	a0,s1,s4
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	efe080e7          	jalr	-258(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000aee:	94ce                	add	s1,s1,s3
    80000af0:	fe9979e3          	bgeu	s2,s1,80000ae2 <freerange+0x2a>
}
    80000af4:	70a2                	ld	ra,40(sp)
    80000af6:	7402                	ld	s0,32(sp)
    80000af8:	64e2                	ld	s1,24(sp)
    80000afa:	6942                	ld	s2,16(sp)
    80000afc:	69a2                	ld	s3,8(sp)
    80000afe:	6a02                	ld	s4,0(sp)
    80000b00:	6145                	add	sp,sp,48
    80000b02:	8082                	ret

0000000080000b04 <kinit>:
{
    80000b04:	1141                	add	sp,sp,-16
    80000b06:	e406                	sd	ra,8(sp)
    80000b08:	e022                	sd	s0,0(sp)
    80000b0a:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b0c:	00007597          	auipc	a1,0x7
    80000b10:	55c58593          	add	a1,a1,1372 # 80008068 <digits+0x28>
    80000b14:	00010517          	auipc	a0,0x10
    80000b18:	03c50513          	add	a0,a0,60 # 80010b50 <kmem>
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	28c080e7          	jalr	652(ra) # 80000da8 <initlock>
  initlock(&Ref.lock, "Ref");
    80000b24:	00007597          	auipc	a1,0x7
    80000b28:	54c58593          	add	a1,a1,1356 # 80008070 <digits+0x30>
    80000b2c:	00010517          	auipc	a0,0x10
    80000b30:	04450513          	add	a0,a0,68 # 80010b70 <Ref>
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	274080e7          	jalr	628(ra) # 80000da8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b3c:	45c5                	li	a1,17
    80000b3e:	05ee                	sll	a1,a1,0x1b
    80000b40:	00042517          	auipc	a0,0x42
    80000b44:	c5850513          	add	a0,a0,-936 # 80042798 <end>
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	f70080e7          	jalr	-144(ra) # 80000ab8 <freerange>
}
    80000b50:	60a2                	ld	ra,8(sp)
    80000b52:	6402                	ld	s0,0(sp)
    80000b54:	0141                	add	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b58:	1101                	add	sp,sp,-32
    80000b5a:	ec06                	sd	ra,24(sp)
    80000b5c:	e822                	sd	s0,16(sp)
    80000b5e:	e426                	sd	s1,8(sp)
    80000b60:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b62:	00010497          	auipc	s1,0x10
    80000b66:	fee48493          	add	s1,s1,-18 # 80010b50 <kmem>
    80000b6a:	8526                	mv	a0,s1
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	2cc080e7          	jalr	716(ra) # 80000e38 <acquire>
  r = kmem.freelist;
    80000b74:	6c84                	ld	s1,24(s1)
  if(r)
    80000b76:	c4b1                	beqz	s1,80000bc2 <kalloc+0x6a>
    kmem.freelist = r->next;
    80000b78:	609c                	ld	a5,0(s1)
    80000b7a:	00010517          	auipc	a0,0x10
    80000b7e:	fd650513          	add	a0,a0,-42 # 80010b50 <kmem>
    80000b82:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	368080e7          	jalr	872(ra) # 80000eec <release>

  if(r){
    memset((char*)r, 69, PGSIZE); // fill with junk
    80000b8c:	6605                	lui	a2,0x1
    80000b8e:	04500593          	li	a1,69
    80000b92:	8526                	mv	a0,s1
    80000b94:	00000097          	auipc	ra,0x0
    80000b98:	3a0080e7          	jalr	928(ra) # 80000f34 <memset>
    Ref.references[PA2REF((uint64)r)] = 1;
    80000b9c:	800007b7          	lui	a5,0x80000
    80000ba0:	97a6                	add	a5,a5,s1
    80000ba2:	83b1                	srl	a5,a5,0xc
    80000ba4:	0791                	add	a5,a5,4 # ffffffff80000004 <end+0xfffffffefffbd86c>
    80000ba6:	078a                	sll	a5,a5,0x2
    80000ba8:	00010717          	auipc	a4,0x10
    80000bac:	fc870713          	add	a4,a4,-56 # 80010b70 <Ref>
    80000bb0:	97ba                	add	a5,a5,a4
    80000bb2:	4705                	li	a4,1
    80000bb4:	c798                	sw	a4,8(a5)
  }
  return (void*)r;
}
    80000bb6:	8526                	mv	a0,s1
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	add	sp,sp,32
    80000bc0:	8082                	ret
  release(&kmem.lock);
    80000bc2:	00010517          	auipc	a0,0x10
    80000bc6:	f8e50513          	add	a0,a0,-114 # 80010b50 <kmem>
    80000bca:	00000097          	auipc	ra,0x0
    80000bce:	322080e7          	jalr	802(ra) # 80000eec <release>
  if(r){
    80000bd2:	b7d5                	j	80000bb6 <kalloc+0x5e>

0000000080000bd4 <addReference>:

void addReference(void* pa){
  int ref = PA2REF(pa);
    80000bd4:	800007b7          	lui	a5,0x80000
    80000bd8:	953e                	add	a0,a0,a5
    80000bda:	8131                	srl	a0,a0,0xc
  if(ref < 0 || ref >= MAXREF)
    80000bdc:	0005071b          	sext.w	a4,a0
    80000be0:	67a1                	lui	a5,0x8
    80000be2:	00f76363          	bltu	a4,a5,80000be8 <addReference+0x14>
    80000be6:	8082                	ret
void addReference(void* pa){
    80000be8:	1101                	add	sp,sp,-32
    80000bea:	ec06                	sd	ra,24(sp)
    80000bec:	e822                	sd	s0,16(sp)
    80000bee:	e426                	sd	s1,8(sp)
    80000bf0:	1000                	add	s0,sp,32
  int ref = PA2REF(pa);
    80000bf2:	84ba                	mv	s1,a4
    return;
  acquire(&Ref.lock);
    80000bf4:	00010517          	auipc	a0,0x10
    80000bf8:	f7c50513          	add	a0,a0,-132 # 80010b70 <Ref>
    80000bfc:	00000097          	auipc	ra,0x0
    80000c00:	23c080e7          	jalr	572(ra) # 80000e38 <acquire>
  Ref.references[ref]++;
    80000c04:	00010517          	auipc	a0,0x10
    80000c08:	f6c50513          	add	a0,a0,-148 # 80010b70 <Ref>
    80000c0c:	00448793          	add	a5,s1,4
    80000c10:	078a                	sll	a5,a5,0x2
    80000c12:	97aa                	add	a5,a5,a0
    80000c14:	4798                	lw	a4,8(a5)
    80000c16:	2705                	addw	a4,a4,1
    80000c18:	c798                	sw	a4,8(a5)
  release(&Ref.lock);
    80000c1a:	00000097          	auipc	ra,0x0
    80000c1e:	2d2080e7          	jalr	722(ra) # 80000eec <release>
}
    80000c22:	60e2                	ld	ra,24(sp)
    80000c24:	6442                	ld	s0,16(sp)
    80000c26:	64a2                	ld	s1,8(sp)
    80000c28:	6105                	add	sp,sp,32
    80000c2a:	8082                	ret

0000000080000c2c <copyndecref>:

// Copy the page to another memory address and decrease reference count
void* copyndecref(void* pa){
    80000c2c:	1101                	add	sp,sp,-32
    80000c2e:	ec06                	sd	ra,24(sp)
    80000c30:	e822                	sd	s0,16(sp)
    80000c32:	e426                	sd	s1,8(sp)
    80000c34:	e04a                	sd	s2,0(sp)
    80000c36:	1000                	add	s0,sp,32
  int ref = PA2REF(pa);
    80000c38:	800007b7          	lui	a5,0x80000
    80000c3c:	97aa                	add	a5,a5,a0
    80000c3e:	83b1                	srl	a5,a5,0xc
  if(ref < 0 || ref >= MAXREF)
    80000c40:	0007869b          	sext.w	a3,a5
    80000c44:	6721                	lui	a4,0x8
    return 0;
    80000c46:	4481                	li	s1,0
  if(ref < 0 || ref >= MAXREF)
    80000c48:	06e6f663          	bgeu	a3,a4,80000cb4 <copyndecref+0x88>
    80000c4c:	892a                	mv	s2,a0
  int ref = PA2REF(pa);
    80000c4e:	84b6                	mv	s1,a3

  acquire(&Ref.lock);
    80000c50:	00010517          	auipc	a0,0x10
    80000c54:	f2050513          	add	a0,a0,-224 # 80010b70 <Ref>
    80000c58:	00000097          	auipc	ra,0x0
    80000c5c:	1e0080e7          	jalr	480(ra) # 80000e38 <acquire>
  if(Ref.references[ref] <= 1){
    80000c60:	00448713          	add	a4,s1,4
    80000c64:	070a                	sll	a4,a4,0x2
    80000c66:	00010797          	auipc	a5,0x10
    80000c6a:	f0a78793          	add	a5,a5,-246 # 80010b70 <Ref>
    80000c6e:	97ba                	add	a5,a5,a4
    80000c70:	4798                	lw	a4,8(a5)
    80000c72:	4785                	li	a5,1
    80000c74:	04e7d763          	bge	a5,a4,80000cc2 <copyndecref+0x96>
    release(&Ref.lock);
    return pa;
  }
  
  Ref.references[ref]--;
    80000c78:	00448793          	add	a5,s1,4
    80000c7c:	078a                	sll	a5,a5,0x2
    80000c7e:	00010697          	auipc	a3,0x10
    80000c82:	ef268693          	add	a3,a3,-270 # 80010b70 <Ref>
    80000c86:	97b6                	add	a5,a5,a3
    80000c88:	377d                	addw	a4,a4,-1 # 7fff <_entry-0x7fff8001>
    80000c8a:	c798                	sw	a4,8(a5)
  
  uint64 mem = (uint64)kalloc();
    80000c8c:	00000097          	auipc	ra,0x0
    80000c90:	ecc080e7          	jalr	-308(ra) # 80000b58 <kalloc>
    80000c94:	84aa                	mv	s1,a0
  if(mem == 0){
    80000c96:	c121                	beqz	a0,80000cd6 <copyndecref+0xaa>
    release(&Ref.lock);
    return 0;
  }
  memmove((void*)mem,(void*)pa, PGSIZE);
    80000c98:	6605                	lui	a2,0x1
    80000c9a:	85ca                	mv	a1,s2
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	2f4080e7          	jalr	756(ra) # 80000f90 <memmove>
  release(&Ref.lock);
    80000ca4:	00010517          	auipc	a0,0x10
    80000ca8:	ecc50513          	add	a0,a0,-308 # 80010b70 <Ref>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	240080e7          	jalr	576(ra) # 80000eec <release>
  return (void*)mem;
}
    80000cb4:	8526                	mv	a0,s1
    80000cb6:	60e2                	ld	ra,24(sp)
    80000cb8:	6442                	ld	s0,16(sp)
    80000cba:	64a2                	ld	s1,8(sp)
    80000cbc:	6902                	ld	s2,0(sp)
    80000cbe:	6105                	add	sp,sp,32
    80000cc0:	8082                	ret
    release(&Ref.lock);
    80000cc2:	00010517          	auipc	a0,0x10
    80000cc6:	eae50513          	add	a0,a0,-338 # 80010b70 <Ref>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	222080e7          	jalr	546(ra) # 80000eec <release>
    return pa;
    80000cd2:	84ca                	mv	s1,s2
    80000cd4:	b7c5                	j	80000cb4 <copyndecref+0x88>
    release(&Ref.lock);
    80000cd6:	00010517          	auipc	a0,0x10
    80000cda:	e9a50513          	add	a0,a0,-358 # 80010b70 <Ref>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	20e080e7          	jalr	526(ra) # 80000eec <release>
    return 0;
    80000ce6:	b7f9                	j	80000cb4 <copyndecref+0x88>

0000000080000ce8 <pagefhandler>:

int pagefhandler(pagetable_t pagetable,uint64 va){
  if(va >= MAXVA || va <= 0)
    80000ce8:	fff58713          	add	a4,a1,-1
    80000cec:	f80007b7          	lui	a5,0xf8000
    80000cf0:	83e9                	srl	a5,a5,0x1a
    80000cf2:	0ae7e163          	bltu	a5,a4,80000d94 <pagefhandler+0xac>
int pagefhandler(pagetable_t pagetable,uint64 va){
    80000cf6:	7179                	add	sp,sp,-48
    80000cf8:	f406                	sd	ra,40(sp)
    80000cfa:	f022                	sd	s0,32(sp)
    80000cfc:	ec26                	sd	s1,24(sp)
    80000cfe:	e84a                	sd	s2,16(sp)
    80000d00:	e44e                	sd	s3,8(sp)
    80000d02:	e052                	sd	s4,0(sp)
    80000d04:	1800                	add	s0,sp,48
    80000d06:	892a                	mv	s2,a0
    80000d08:	84ae                	mv	s1,a1
    return -1;

  pte_t *pte = walk(pagetable,va,0);
    80000d0a:	4601                	li	a2,0
    80000d0c:	00000097          	auipc	ra,0x0
    80000d10:	50a080e7          	jalr	1290(ra) # 80001216 <walk>
    80000d14:	89aa                	mv	s3,a0
  if(pte == 0){
    80000d16:	c149                	beqz	a0,80000d98 <pagefhandler+0xb0>
    return -1;
  }
  if(!(*pte & PTE_V)){
    80000d18:	6108                	ld	a0,0(a0)
    return -1;
  }
  if(!(*pte & PTE_U)){
    80000d1a:	01157713          	and	a4,a0,17
    80000d1e:	47c5                	li	a5,17
    80000d20:	06f71e63          	bne	a4,a5,80000d9c <pagefhandler+0xb4>
    return -1;
  }
  if(!(*pte & PTE_COW)){
    80000d24:	02057793          	and	a5,a0,32
    80000d28:	cfa5                	beqz	a5,80000da0 <pagefhandler+0xb8>
    return -1;
  }
  uint64 pa = PTE2PA(*pte);
    80000d2a:	8129                	srl	a0,a0,0xa
  void* mem = copyndecref((void*)pa);
    80000d2c:	0532                	sll	a0,a0,0xc
    80000d2e:	00000097          	auipc	ra,0x0
    80000d32:	efe080e7          	jalr	-258(ra) # 80000c2c <copyndecref>
    80000d36:	8a2a                	mv	s4,a0

  if(mem == 0)
    80000d38:	c535                	beqz	a0,80000da4 <pagefhandler+0xbc>
    return -1;

  uint64 flags = (PTE_FLAGS(*pte) | PTE_W) & ~PTE_COW;
    80000d3a:	0009b983          	ld	s3,0(s3) # 1000 <_entry-0x7ffff000>
    80000d3e:	3db9f993          	and	s3,s3,987
    80000d42:	0049e993          	or	s3,s3,4
  uvmunmap(pagetable,PGROUNDDOWN(va),1,0);
    80000d46:	4681                	li	a3,0
    80000d48:	4605                	li	a2,1
    80000d4a:	75fd                	lui	a1,0xfffff
    80000d4c:	8de5                	and	a1,a1,s1
    80000d4e:	854a                	mv	a0,s2
    80000d50:	00000097          	auipc	ra,0x0
    80000d54:	774080e7          	jalr	1908(ra) # 800014c4 <uvmunmap>
  if(mappages(pagetable,va,1,(uint64)mem,flags) == -1){
    80000d58:	874e                	mv	a4,s3
    80000d5a:	86d2                	mv	a3,s4
    80000d5c:	4605                	li	a2,1
    80000d5e:	85a6                	mv	a1,s1
    80000d60:	854a                	mv	a0,s2
    80000d62:	00000097          	auipc	ra,0x0
    80000d66:	59c080e7          	jalr	1436(ra) # 800012fe <mappages>
    80000d6a:	872a                	mv	a4,a0
    80000d6c:	57fd                	li	a5,-1
    panic("Pagefhandler mappages");
  }

  return 0;
    80000d6e:	4501                	li	a0,0
  if(mappages(pagetable,va,1,(uint64)mem,flags) == -1){
    80000d70:	00f70a63          	beq	a4,a5,80000d84 <pagefhandler+0x9c>
    80000d74:	70a2                	ld	ra,40(sp)
    80000d76:	7402                	ld	s0,32(sp)
    80000d78:	64e2                	ld	s1,24(sp)
    80000d7a:	6942                	ld	s2,16(sp)
    80000d7c:	69a2                	ld	s3,8(sp)
    80000d7e:	6a02                	ld	s4,0(sp)
    80000d80:	6145                	add	sp,sp,48
    80000d82:	8082                	ret
    panic("Pagefhandler mappages");
    80000d84:	00007517          	auipc	a0,0x7
    80000d88:	2f450513          	add	a0,a0,756 # 80008078 <digits+0x38>
    80000d8c:	fffff097          	auipc	ra,0xfffff
    80000d90:	7b0080e7          	jalr	1968(ra) # 8000053c <panic>
    return -1;
    80000d94:	557d                	li	a0,-1
    80000d96:	8082                	ret
    return -1;
    80000d98:	557d                	li	a0,-1
    80000d9a:	bfe9                	j	80000d74 <pagefhandler+0x8c>
    return -1;
    80000d9c:	557d                	li	a0,-1
    80000d9e:	bfd9                	j	80000d74 <pagefhandler+0x8c>
    return -1;
    80000da0:	557d                	li	a0,-1
    80000da2:	bfc9                	j	80000d74 <pagefhandler+0x8c>
    return -1;
    80000da4:	557d                	li	a0,-1
    80000da6:	b7f9                	j	80000d74 <pagefhandler+0x8c>

0000000080000da8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000da8:	1141                	add	sp,sp,-16
    80000daa:	e422                	sd	s0,8(sp)
    80000dac:	0800                	add	s0,sp,16
  lk->name = name;
    80000dae:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000db0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000db4:	00053823          	sd	zero,16(a0)
}
    80000db8:	6422                	ld	s0,8(sp)
    80000dba:	0141                	add	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000dbe:	411c                	lw	a5,0(a0)
    80000dc0:	e399                	bnez	a5,80000dc6 <holding+0x8>
    80000dc2:	4501                	li	a0,0
  return r;
}
    80000dc4:	8082                	ret
{
    80000dc6:	1101                	add	sp,sp,-32
    80000dc8:	ec06                	sd	ra,24(sp)
    80000dca:	e822                	sd	s0,16(sp)
    80000dcc:	e426                	sd	s1,8(sp)
    80000dce:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000dd0:	6904                	ld	s1,16(a0)
    80000dd2:	00001097          	auipc	ra,0x1
    80000dd6:	e16080e7          	jalr	-490(ra) # 80001be8 <mycpu>
    80000dda:	40a48533          	sub	a0,s1,a0
    80000dde:	00153513          	seqz	a0,a0
}
    80000de2:	60e2                	ld	ra,24(sp)
    80000de4:	6442                	ld	s0,16(sp)
    80000de6:	64a2                	ld	s1,8(sp)
    80000de8:	6105                	add	sp,sp,32
    80000dea:	8082                	ret

0000000080000dec <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000dec:	1101                	add	sp,sp,-32
    80000dee:	ec06                	sd	ra,24(sp)
    80000df0:	e822                	sd	s0,16(sp)
    80000df2:	e426                	sd	s1,8(sp)
    80000df4:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000df6:	100024f3          	csrr	s1,sstatus
    80000dfa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000dfe:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e00:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000e04:	00001097          	auipc	ra,0x1
    80000e08:	de4080e7          	jalr	-540(ra) # 80001be8 <mycpu>
    80000e0c:	5d3c                	lw	a5,120(a0)
    80000e0e:	cf89                	beqz	a5,80000e28 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000e10:	00001097          	auipc	ra,0x1
    80000e14:	dd8080e7          	jalr	-552(ra) # 80001be8 <mycpu>
    80000e18:	5d3c                	lw	a5,120(a0)
    80000e1a:	2785                	addw	a5,a5,1 # fffffffff8000001 <end+0xffffffff77fbd869>
    80000e1c:	dd3c                	sw	a5,120(a0)
}
    80000e1e:	60e2                	ld	ra,24(sp)
    80000e20:	6442                	ld	s0,16(sp)
    80000e22:	64a2                	ld	s1,8(sp)
    80000e24:	6105                	add	sp,sp,32
    80000e26:	8082                	ret
    mycpu()->intena = old;
    80000e28:	00001097          	auipc	ra,0x1
    80000e2c:	dc0080e7          	jalr	-576(ra) # 80001be8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000e30:	8085                	srl	s1,s1,0x1
    80000e32:	8885                	and	s1,s1,1
    80000e34:	dd64                	sw	s1,124(a0)
    80000e36:	bfe9                	j	80000e10 <push_off+0x24>

0000000080000e38 <acquire>:
{
    80000e38:	1101                	add	sp,sp,-32
    80000e3a:	ec06                	sd	ra,24(sp)
    80000e3c:	e822                	sd	s0,16(sp)
    80000e3e:	e426                	sd	s1,8(sp)
    80000e40:	1000                	add	s0,sp,32
    80000e42:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000e44:	00000097          	auipc	ra,0x0
    80000e48:	fa8080e7          	jalr	-88(ra) # 80000dec <push_off>
  if(holding(lk))
    80000e4c:	8526                	mv	a0,s1
    80000e4e:	00000097          	auipc	ra,0x0
    80000e52:	f70080e7          	jalr	-144(ra) # 80000dbe <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000e56:	4705                	li	a4,1
  if(holding(lk))
    80000e58:	e115                	bnez	a0,80000e7c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000e5a:	87ba                	mv	a5,a4
    80000e5c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000e60:	2781                	sext.w	a5,a5
    80000e62:	ffe5                	bnez	a5,80000e5a <acquire+0x22>
  __sync_synchronize();
    80000e64:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000e68:	00001097          	auipc	ra,0x1
    80000e6c:	d80080e7          	jalr	-640(ra) # 80001be8 <mycpu>
    80000e70:	e888                	sd	a0,16(s1)
}
    80000e72:	60e2                	ld	ra,24(sp)
    80000e74:	6442                	ld	s0,16(sp)
    80000e76:	64a2                	ld	s1,8(sp)
    80000e78:	6105                	add	sp,sp,32
    80000e7a:	8082                	ret
    panic("acquire");
    80000e7c:	00007517          	auipc	a0,0x7
    80000e80:	21450513          	add	a0,a0,532 # 80008090 <digits+0x50>
    80000e84:	fffff097          	auipc	ra,0xfffff
    80000e88:	6b8080e7          	jalr	1720(ra) # 8000053c <panic>

0000000080000e8c <pop_off>:

void
pop_off(void)
{
    80000e8c:	1141                	add	sp,sp,-16
    80000e8e:	e406                	sd	ra,8(sp)
    80000e90:	e022                	sd	s0,0(sp)
    80000e92:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000e94:	00001097          	auipc	ra,0x1
    80000e98:	d54080e7          	jalr	-684(ra) # 80001be8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e9c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000ea0:	8b89                	and	a5,a5,2
  if(intr_get())
    80000ea2:	e78d                	bnez	a5,80000ecc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ea4:	5d3c                	lw	a5,120(a0)
    80000ea6:	02f05b63          	blez	a5,80000edc <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000eaa:	37fd                	addw	a5,a5,-1
    80000eac:	0007871b          	sext.w	a4,a5
    80000eb0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000eb2:	eb09                	bnez	a4,80000ec4 <pop_off+0x38>
    80000eb4:	5d7c                	lw	a5,124(a0)
    80000eb6:	c799                	beqz	a5,80000ec4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000eb8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ebc:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ec0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ec4:	60a2                	ld	ra,8(sp)
    80000ec6:	6402                	ld	s0,0(sp)
    80000ec8:	0141                	add	sp,sp,16
    80000eca:	8082                	ret
    panic("pop_off - interruptible");
    80000ecc:	00007517          	auipc	a0,0x7
    80000ed0:	1cc50513          	add	a0,a0,460 # 80008098 <digits+0x58>
    80000ed4:	fffff097          	auipc	ra,0xfffff
    80000ed8:	668080e7          	jalr	1640(ra) # 8000053c <panic>
    panic("pop_off");
    80000edc:	00007517          	auipc	a0,0x7
    80000ee0:	1d450513          	add	a0,a0,468 # 800080b0 <digits+0x70>
    80000ee4:	fffff097          	auipc	ra,0xfffff
    80000ee8:	658080e7          	jalr	1624(ra) # 8000053c <panic>

0000000080000eec <release>:
{
    80000eec:	1101                	add	sp,sp,-32
    80000eee:	ec06                	sd	ra,24(sp)
    80000ef0:	e822                	sd	s0,16(sp)
    80000ef2:	e426                	sd	s1,8(sp)
    80000ef4:	1000                	add	s0,sp,32
    80000ef6:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ef8:	00000097          	auipc	ra,0x0
    80000efc:	ec6080e7          	jalr	-314(ra) # 80000dbe <holding>
    80000f00:	c115                	beqz	a0,80000f24 <release+0x38>
  lk->cpu = 0;
    80000f02:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000f06:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000f0a:	0f50000f          	fence	iorw,ow
    80000f0e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	f7a080e7          	jalr	-134(ra) # 80000e8c <pop_off>
}
    80000f1a:	60e2                	ld	ra,24(sp)
    80000f1c:	6442                	ld	s0,16(sp)
    80000f1e:	64a2                	ld	s1,8(sp)
    80000f20:	6105                	add	sp,sp,32
    80000f22:	8082                	ret
    panic("release");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	19450513          	add	a0,a0,404 # 800080b8 <digits+0x78>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	610080e7          	jalr	1552(ra) # 8000053c <panic>

0000000080000f34 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000f34:	1141                	add	sp,sp,-16
    80000f36:	e422                	sd	s0,8(sp)
    80000f38:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000f3a:	ca19                	beqz	a2,80000f50 <memset+0x1c>
    80000f3c:	87aa                	mv	a5,a0
    80000f3e:	1602                	sll	a2,a2,0x20
    80000f40:	9201                	srl	a2,a2,0x20
    80000f42:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000f46:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000f4a:	0785                	add	a5,a5,1
    80000f4c:	fee79de3          	bne	a5,a4,80000f46 <memset+0x12>
  }
  return dst;
}
    80000f50:	6422                	ld	s0,8(sp)
    80000f52:	0141                	add	sp,sp,16
    80000f54:	8082                	ret

0000000080000f56 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000f56:	1141                	add	sp,sp,-16
    80000f58:	e422                	sd	s0,8(sp)
    80000f5a:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000f5c:	ca05                	beqz	a2,80000f8c <memcmp+0x36>
    80000f5e:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000f62:	1682                	sll	a3,a3,0x20
    80000f64:	9281                	srl	a3,a3,0x20
    80000f66:	0685                	add	a3,a3,1
    80000f68:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000f6a:	00054783          	lbu	a5,0(a0)
    80000f6e:	0005c703          	lbu	a4,0(a1) # fffffffffffff000 <end+0xffffffff7ffbc868>
    80000f72:	00e79863          	bne	a5,a4,80000f82 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000f76:	0505                	add	a0,a0,1
    80000f78:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000f7a:	fed518e3          	bne	a0,a3,80000f6a <memcmp+0x14>
  }

  return 0;
    80000f7e:	4501                	li	a0,0
    80000f80:	a019                	j	80000f86 <memcmp+0x30>
      return *s1 - *s2;
    80000f82:	40e7853b          	subw	a0,a5,a4
}
    80000f86:	6422                	ld	s0,8(sp)
    80000f88:	0141                	add	sp,sp,16
    80000f8a:	8082                	ret
  return 0;
    80000f8c:	4501                	li	a0,0
    80000f8e:	bfe5                	j	80000f86 <memcmp+0x30>

0000000080000f90 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000f90:	1141                	add	sp,sp,-16
    80000f92:	e422                	sd	s0,8(sp)
    80000f94:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000f96:	c205                	beqz	a2,80000fb6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000f98:	02a5e263          	bltu	a1,a0,80000fbc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000f9c:	1602                	sll	a2,a2,0x20
    80000f9e:	9201                	srl	a2,a2,0x20
    80000fa0:	00c587b3          	add	a5,a1,a2
{
    80000fa4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000fa6:	0585                	add	a1,a1,1
    80000fa8:	0705                	add	a4,a4,1
    80000faa:	fff5c683          	lbu	a3,-1(a1)
    80000fae:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000fb2:	fef59ae3          	bne	a1,a5,80000fa6 <memmove+0x16>

  return dst;
}
    80000fb6:	6422                	ld	s0,8(sp)
    80000fb8:	0141                	add	sp,sp,16
    80000fba:	8082                	ret
  if(s < d && s + n > d){
    80000fbc:	02061693          	sll	a3,a2,0x20
    80000fc0:	9281                	srl	a3,a3,0x20
    80000fc2:	00d58733          	add	a4,a1,a3
    80000fc6:	fce57be3          	bgeu	a0,a4,80000f9c <memmove+0xc>
    d += n;
    80000fca:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000fcc:	fff6079b          	addw	a5,a2,-1
    80000fd0:	1782                	sll	a5,a5,0x20
    80000fd2:	9381                	srl	a5,a5,0x20
    80000fd4:	fff7c793          	not	a5,a5
    80000fd8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000fda:	177d                	add	a4,a4,-1
    80000fdc:	16fd                	add	a3,a3,-1
    80000fde:	00074603          	lbu	a2,0(a4)
    80000fe2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000fe6:	fee79ae3          	bne	a5,a4,80000fda <memmove+0x4a>
    80000fea:	b7f1                	j	80000fb6 <memmove+0x26>

0000000080000fec <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000fec:	1141                	add	sp,sp,-16
    80000fee:	e406                	sd	ra,8(sp)
    80000ff0:	e022                	sd	s0,0(sp)
    80000ff2:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000ff4:	00000097          	auipc	ra,0x0
    80000ff8:	f9c080e7          	jalr	-100(ra) # 80000f90 <memmove>
}
    80000ffc:	60a2                	ld	ra,8(sp)
    80000ffe:	6402                	ld	s0,0(sp)
    80001000:	0141                	add	sp,sp,16
    80001002:	8082                	ret

0000000080001004 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80001004:	1141                	add	sp,sp,-16
    80001006:	e422                	sd	s0,8(sp)
    80001008:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    8000100a:	ce11                	beqz	a2,80001026 <strncmp+0x22>
    8000100c:	00054783          	lbu	a5,0(a0)
    80001010:	cf89                	beqz	a5,8000102a <strncmp+0x26>
    80001012:	0005c703          	lbu	a4,0(a1)
    80001016:	00f71a63          	bne	a4,a5,8000102a <strncmp+0x26>
    n--, p++, q++;
    8000101a:	367d                	addw	a2,a2,-1
    8000101c:	0505                	add	a0,a0,1
    8000101e:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80001020:	f675                	bnez	a2,8000100c <strncmp+0x8>
  if(n == 0)
    return 0;
    80001022:	4501                	li	a0,0
    80001024:	a809                	j	80001036 <strncmp+0x32>
    80001026:	4501                	li	a0,0
    80001028:	a039                	j	80001036 <strncmp+0x32>
  if(n == 0)
    8000102a:	ca09                	beqz	a2,8000103c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    8000102c:	00054503          	lbu	a0,0(a0)
    80001030:	0005c783          	lbu	a5,0(a1)
    80001034:	9d1d                	subw	a0,a0,a5
}
    80001036:	6422                	ld	s0,8(sp)
    80001038:	0141                	add	sp,sp,16
    8000103a:	8082                	ret
    return 0;
    8000103c:	4501                	li	a0,0
    8000103e:	bfe5                	j	80001036 <strncmp+0x32>

0000000080001040 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80001040:	1141                	add	sp,sp,-16
    80001042:	e422                	sd	s0,8(sp)
    80001044:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80001046:	87aa                	mv	a5,a0
    80001048:	86b2                	mv	a3,a2
    8000104a:	367d                	addw	a2,a2,-1
    8000104c:	00d05963          	blez	a3,8000105e <strncpy+0x1e>
    80001050:	0785                	add	a5,a5,1
    80001052:	0005c703          	lbu	a4,0(a1)
    80001056:	fee78fa3          	sb	a4,-1(a5)
    8000105a:	0585                	add	a1,a1,1
    8000105c:	f775                	bnez	a4,80001048 <strncpy+0x8>
    ;
  while(n-- > 0)
    8000105e:	873e                	mv	a4,a5
    80001060:	9fb5                	addw	a5,a5,a3
    80001062:	37fd                	addw	a5,a5,-1
    80001064:	00c05963          	blez	a2,80001076 <strncpy+0x36>
    *s++ = 0;
    80001068:	0705                	add	a4,a4,1
    8000106a:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    8000106e:	40e786bb          	subw	a3,a5,a4
    80001072:	fed04be3          	bgtz	a3,80001068 <strncpy+0x28>
  return os;
}
    80001076:	6422                	ld	s0,8(sp)
    80001078:	0141                	add	sp,sp,16
    8000107a:	8082                	ret

000000008000107c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    8000107c:	1141                	add	sp,sp,-16
    8000107e:	e422                	sd	s0,8(sp)
    80001080:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001082:	02c05363          	blez	a2,800010a8 <safestrcpy+0x2c>
    80001086:	fff6069b          	addw	a3,a2,-1
    8000108a:	1682                	sll	a3,a3,0x20
    8000108c:	9281                	srl	a3,a3,0x20
    8000108e:	96ae                	add	a3,a3,a1
    80001090:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001092:	00d58963          	beq	a1,a3,800010a4 <safestrcpy+0x28>
    80001096:	0585                	add	a1,a1,1
    80001098:	0785                	add	a5,a5,1
    8000109a:	fff5c703          	lbu	a4,-1(a1)
    8000109e:	fee78fa3          	sb	a4,-1(a5)
    800010a2:	fb65                	bnez	a4,80001092 <safestrcpy+0x16>
    ;
  *s = 0;
    800010a4:	00078023          	sb	zero,0(a5)
  return os;
}
    800010a8:	6422                	ld	s0,8(sp)
    800010aa:	0141                	add	sp,sp,16
    800010ac:	8082                	ret

00000000800010ae <strlen>:

int
strlen(const char *s)
{
    800010ae:	1141                	add	sp,sp,-16
    800010b0:	e422                	sd	s0,8(sp)
    800010b2:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800010b4:	00054783          	lbu	a5,0(a0)
    800010b8:	cf91                	beqz	a5,800010d4 <strlen+0x26>
    800010ba:	0505                	add	a0,a0,1
    800010bc:	87aa                	mv	a5,a0
    800010be:	86be                	mv	a3,a5
    800010c0:	0785                	add	a5,a5,1
    800010c2:	fff7c703          	lbu	a4,-1(a5)
    800010c6:	ff65                	bnez	a4,800010be <strlen+0x10>
    800010c8:	40a6853b          	subw	a0,a3,a0
    800010cc:	2505                	addw	a0,a0,1
    ;
  return n;
}
    800010ce:	6422                	ld	s0,8(sp)
    800010d0:	0141                	add	sp,sp,16
    800010d2:	8082                	ret
  for(n = 0; s[n]; n++)
    800010d4:	4501                	li	a0,0
    800010d6:	bfe5                	j	800010ce <strlen+0x20>

00000000800010d8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    800010d8:	1141                	add	sp,sp,-16
    800010da:	e406                	sd	ra,8(sp)
    800010dc:	e022                	sd	s0,0(sp)
    800010de:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    800010e0:	00001097          	auipc	ra,0x1
    800010e4:	af8080e7          	jalr	-1288(ra) # 80001bd8 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    800010e8:	00008717          	auipc	a4,0x8
    800010ec:	80070713          	add	a4,a4,-2048 # 800088e8 <started>
  if(cpuid() == 0){
    800010f0:	c139                	beqz	a0,80001136 <main+0x5e>
    while(started == 0)
    800010f2:	431c                	lw	a5,0(a4)
    800010f4:	2781                	sext.w	a5,a5
    800010f6:	dff5                	beqz	a5,800010f2 <main+0x1a>
      ;
    __sync_synchronize();
    800010f8:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    800010fc:	00001097          	auipc	ra,0x1
    80001100:	adc080e7          	jalr	-1316(ra) # 80001bd8 <cpuid>
    80001104:	85aa                	mv	a1,a0
    80001106:	00007517          	auipc	a0,0x7
    8000110a:	fd250513          	add	a0,a0,-46 # 800080d8 <digits+0x98>
    8000110e:	fffff097          	auipc	ra,0xfffff
    80001112:	478080e7          	jalr	1144(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80001116:	00000097          	auipc	ra,0x0
    8000111a:	0d8080e7          	jalr	216(ra) # 800011ee <kvminithart>
    trapinithart();   // install kernel trap vector
    8000111e:	00002097          	auipc	ra,0x2
    80001122:	a98080e7          	jalr	-1384(ra) # 80002bb6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001126:	00005097          	auipc	ra,0x5
    8000112a:	17a080e7          	jalr	378(ra) # 800062a0 <plicinithart>
  }

  scheduler();        
    8000112e:	00001097          	auipc	ra,0x1
    80001132:	000080e7          	jalr	ra # 8000212e <scheduler>
    consoleinit();
    80001136:	fffff097          	auipc	ra,0xfffff
    8000113a:	316080e7          	jalr	790(ra) # 8000044c <consoleinit>
    printfinit();
    8000113e:	fffff097          	auipc	ra,0xfffff
    80001142:	628080e7          	jalr	1576(ra) # 80000766 <printfinit>
    printf("\n");
    80001146:	00007517          	auipc	a0,0x7
    8000114a:	fa250513          	add	a0,a0,-94 # 800080e8 <digits+0xa8>
    8000114e:	fffff097          	auipc	ra,0xfffff
    80001152:	438080e7          	jalr	1080(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80001156:	00007517          	auipc	a0,0x7
    8000115a:	f6a50513          	add	a0,a0,-150 # 800080c0 <digits+0x80>
    8000115e:	fffff097          	auipc	ra,0xfffff
    80001162:	428080e7          	jalr	1064(ra) # 80000586 <printf>
    printf("\n");
    80001166:	00007517          	auipc	a0,0x7
    8000116a:	f8250513          	add	a0,a0,-126 # 800080e8 <digits+0xa8>
    8000116e:	fffff097          	auipc	ra,0xfffff
    80001172:	418080e7          	jalr	1048(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80001176:	00000097          	auipc	ra,0x0
    8000117a:	98e080e7          	jalr	-1650(ra) # 80000b04 <kinit>
    kvminit();       // create kernel page table
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	326080e7          	jalr	806(ra) # 800014a4 <kvminit>
    kvminithart();   // turn on paging
    80001186:	00000097          	auipc	ra,0x0
    8000118a:	068080e7          	jalr	104(ra) # 800011ee <kvminithart>
    procinit();      // process table
    8000118e:	00001097          	auipc	ra,0x1
    80001192:	996080e7          	jalr	-1642(ra) # 80001b24 <procinit>
    trapinit();      // trap vectors
    80001196:	00002097          	auipc	ra,0x2
    8000119a:	9f8080e7          	jalr	-1544(ra) # 80002b8e <trapinit>
    trapinithart();  // install kernel trap vector
    8000119e:	00002097          	auipc	ra,0x2
    800011a2:	a18080e7          	jalr	-1512(ra) # 80002bb6 <trapinithart>
    plicinit();      // set up interrupt controller
    800011a6:	00005097          	auipc	ra,0x5
    800011aa:	0e4080e7          	jalr	228(ra) # 8000628a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800011ae:	00005097          	auipc	ra,0x5
    800011b2:	0f2080e7          	jalr	242(ra) # 800062a0 <plicinithart>
    binit();         // buffer cache
    800011b6:	00002097          	auipc	ra,0x2
    800011ba:	2cc080e7          	jalr	716(ra) # 80003482 <binit>
    iinit();         // inode table
    800011be:	00003097          	auipc	ra,0x3
    800011c2:	96a080e7          	jalr	-1686(ra) # 80003b28 <iinit>
    fileinit();      // file table
    800011c6:	00004097          	auipc	ra,0x4
    800011ca:	8e0080e7          	jalr	-1824(ra) # 80004aa6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800011ce:	00005097          	auipc	ra,0x5
    800011d2:	1da080e7          	jalr	474(ra) # 800063a8 <virtio_disk_init>
    userinit();      // first user process
    800011d6:	00001097          	auipc	ra,0x1
    800011da:	d3a080e7          	jalr	-710(ra) # 80001f10 <userinit>
    __sync_synchronize();
    800011de:	0ff0000f          	fence
    started = 1;
    800011e2:	4785                	li	a5,1
    800011e4:	00007717          	auipc	a4,0x7
    800011e8:	70f72223          	sw	a5,1796(a4) # 800088e8 <started>
    800011ec:	b789                	j	8000112e <main+0x56>

00000000800011ee <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800011ee:	1141                	add	sp,sp,-16
    800011f0:	e422                	sd	s0,8(sp)
    800011f2:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800011f4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800011f8:	00007797          	auipc	a5,0x7
    800011fc:	6f87b783          	ld	a5,1784(a5) # 800088f0 <kernel_pagetable>
    80001200:	83b1                	srl	a5,a5,0xc
    80001202:	577d                	li	a4,-1
    80001204:	177e                	sll	a4,a4,0x3f
    80001206:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001208:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000120c:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001210:	6422                	ld	s0,8(sp)
    80001212:	0141                	add	sp,sp,16
    80001214:	8082                	ret

0000000080001216 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001216:	7139                	add	sp,sp,-64
    80001218:	fc06                	sd	ra,56(sp)
    8000121a:	f822                	sd	s0,48(sp)
    8000121c:	f426                	sd	s1,40(sp)
    8000121e:	f04a                	sd	s2,32(sp)
    80001220:	ec4e                	sd	s3,24(sp)
    80001222:	e852                	sd	s4,16(sp)
    80001224:	e456                	sd	s5,8(sp)
    80001226:	e05a                	sd	s6,0(sp)
    80001228:	0080                	add	s0,sp,64
    8000122a:	84aa                	mv	s1,a0
    8000122c:	89ae                	mv	s3,a1
    8000122e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001230:	57fd                	li	a5,-1
    80001232:	83e9                	srl	a5,a5,0x1a
    80001234:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001236:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001238:	04b7f263          	bgeu	a5,a1,8000127c <walk+0x66>
    panic("walk");
    8000123c:	00007517          	auipc	a0,0x7
    80001240:	eb450513          	add	a0,a0,-332 # 800080f0 <digits+0xb0>
    80001244:	fffff097          	auipc	ra,0xfffff
    80001248:	2f8080e7          	jalr	760(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000124c:	060a8663          	beqz	s5,800012b8 <walk+0xa2>
    80001250:	00000097          	auipc	ra,0x0
    80001254:	908080e7          	jalr	-1784(ra) # 80000b58 <kalloc>
    80001258:	84aa                	mv	s1,a0
    8000125a:	c529                	beqz	a0,800012a4 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000125c:	6605                	lui	a2,0x1
    8000125e:	4581                	li	a1,0
    80001260:	00000097          	auipc	ra,0x0
    80001264:	cd4080e7          	jalr	-812(ra) # 80000f34 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001268:	00c4d793          	srl	a5,s1,0xc
    8000126c:	07aa                	sll	a5,a5,0xa
    8000126e:	0017e793          	or	a5,a5,1
    80001272:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001276:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffbc85f>
    80001278:	036a0063          	beq	s4,s6,80001298 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000127c:	0149d933          	srl	s2,s3,s4
    80001280:	1ff97913          	and	s2,s2,511
    80001284:	090e                	sll	s2,s2,0x3
    80001286:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001288:	00093483          	ld	s1,0(s2)
    8000128c:	0014f793          	and	a5,s1,1
    80001290:	dfd5                	beqz	a5,8000124c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001292:	80a9                	srl	s1,s1,0xa
    80001294:	04b2                	sll	s1,s1,0xc
    80001296:	b7c5                	j	80001276 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001298:	00c9d513          	srl	a0,s3,0xc
    8000129c:	1ff57513          	and	a0,a0,511
    800012a0:	050e                	sll	a0,a0,0x3
    800012a2:	9526                	add	a0,a0,s1
}
    800012a4:	70e2                	ld	ra,56(sp)
    800012a6:	7442                	ld	s0,48(sp)
    800012a8:	74a2                	ld	s1,40(sp)
    800012aa:	7902                	ld	s2,32(sp)
    800012ac:	69e2                	ld	s3,24(sp)
    800012ae:	6a42                	ld	s4,16(sp)
    800012b0:	6aa2                	ld	s5,8(sp)
    800012b2:	6b02                	ld	s6,0(sp)
    800012b4:	6121                	add	sp,sp,64
    800012b6:	8082                	ret
        return 0;
    800012b8:	4501                	li	a0,0
    800012ba:	b7ed                	j	800012a4 <walk+0x8e>

00000000800012bc <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800012bc:	57fd                	li	a5,-1
    800012be:	83e9                	srl	a5,a5,0x1a
    800012c0:	00b7f463          	bgeu	a5,a1,800012c8 <walkaddr+0xc>
    return 0;
    800012c4:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800012c6:	8082                	ret
{
    800012c8:	1141                	add	sp,sp,-16
    800012ca:	e406                	sd	ra,8(sp)
    800012cc:	e022                	sd	s0,0(sp)
    800012ce:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    800012d0:	4601                	li	a2,0
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	f44080e7          	jalr	-188(ra) # 80001216 <walk>
  if(pte == 0)
    800012da:	c105                	beqz	a0,800012fa <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800012dc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800012de:	0117f693          	and	a3,a5,17
    800012e2:	4745                	li	a4,17
    return 0;
    800012e4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800012e6:	00e68663          	beq	a3,a4,800012f2 <walkaddr+0x36>
}
    800012ea:	60a2                	ld	ra,8(sp)
    800012ec:	6402                	ld	s0,0(sp)
    800012ee:	0141                	add	sp,sp,16
    800012f0:	8082                	ret
  pa = PTE2PA(*pte);
    800012f2:	83a9                	srl	a5,a5,0xa
    800012f4:	00c79513          	sll	a0,a5,0xc
  return pa;
    800012f8:	bfcd                	j	800012ea <walkaddr+0x2e>
    return 0;
    800012fa:	4501                	li	a0,0
    800012fc:	b7fd                	j	800012ea <walkaddr+0x2e>

00000000800012fe <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800012fe:	715d                	add	sp,sp,-80
    80001300:	e486                	sd	ra,72(sp)
    80001302:	e0a2                	sd	s0,64(sp)
    80001304:	fc26                	sd	s1,56(sp)
    80001306:	f84a                	sd	s2,48(sp)
    80001308:	f44e                	sd	s3,40(sp)
    8000130a:	f052                	sd	s4,32(sp)
    8000130c:	ec56                	sd	s5,24(sp)
    8000130e:	e85a                	sd	s6,16(sp)
    80001310:	e45e                	sd	s7,8(sp)
    80001312:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001314:	c639                	beqz	a2,80001362 <mappages+0x64>
    80001316:	8aaa                	mv	s5,a0
    80001318:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000131a:	777d                	lui	a4,0xfffff
    8000131c:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001320:	fff58993          	add	s3,a1,-1
    80001324:	99b2                	add	s3,s3,a2
    80001326:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000132a:	893e                	mv	s2,a5
    8000132c:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001330:	6b85                	lui	s7,0x1
    80001332:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001336:	4605                	li	a2,1
    80001338:	85ca                	mv	a1,s2
    8000133a:	8556                	mv	a0,s5
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	eda080e7          	jalr	-294(ra) # 80001216 <walk>
    80001344:	cd1d                	beqz	a0,80001382 <mappages+0x84>
    if(*pte & PTE_V)
    80001346:	611c                	ld	a5,0(a0)
    80001348:	8b85                	and	a5,a5,1
    8000134a:	e785                	bnez	a5,80001372 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000134c:	80b1                	srl	s1,s1,0xc
    8000134e:	04aa                	sll	s1,s1,0xa
    80001350:	0164e4b3          	or	s1,s1,s6
    80001354:	0014e493          	or	s1,s1,1
    80001358:	e104                	sd	s1,0(a0)
    if(a == last)
    8000135a:	05390063          	beq	s2,s3,8000139a <mappages+0x9c>
    a += PGSIZE;
    8000135e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001360:	bfc9                	j	80001332 <mappages+0x34>
    panic("mappages: size");
    80001362:	00007517          	auipc	a0,0x7
    80001366:	d9650513          	add	a0,a0,-618 # 800080f8 <digits+0xb8>
    8000136a:	fffff097          	auipc	ra,0xfffff
    8000136e:	1d2080e7          	jalr	466(ra) # 8000053c <panic>
      panic("mappages: remap");
    80001372:	00007517          	auipc	a0,0x7
    80001376:	d9650513          	add	a0,a0,-618 # 80008108 <digits+0xc8>
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	1c2080e7          	jalr	450(ra) # 8000053c <panic>
      return -1;
    80001382:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001384:	60a6                	ld	ra,72(sp)
    80001386:	6406                	ld	s0,64(sp)
    80001388:	74e2                	ld	s1,56(sp)
    8000138a:	7942                	ld	s2,48(sp)
    8000138c:	79a2                	ld	s3,40(sp)
    8000138e:	7a02                	ld	s4,32(sp)
    80001390:	6ae2                	ld	s5,24(sp)
    80001392:	6b42                	ld	s6,16(sp)
    80001394:	6ba2                	ld	s7,8(sp)
    80001396:	6161                	add	sp,sp,80
    80001398:	8082                	ret
  return 0;
    8000139a:	4501                	li	a0,0
    8000139c:	b7e5                	j	80001384 <mappages+0x86>

000000008000139e <kvmmap>:
{
    8000139e:	1141                	add	sp,sp,-16
    800013a0:	e406                	sd	ra,8(sp)
    800013a2:	e022                	sd	s0,0(sp)
    800013a4:	0800                	add	s0,sp,16
    800013a6:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800013a8:	86b2                	mv	a3,a2
    800013aa:	863e                	mv	a2,a5
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	f52080e7          	jalr	-174(ra) # 800012fe <mappages>
    800013b4:	e509                	bnez	a0,800013be <kvmmap+0x20>
}
    800013b6:	60a2                	ld	ra,8(sp)
    800013b8:	6402                	ld	s0,0(sp)
    800013ba:	0141                	add	sp,sp,16
    800013bc:	8082                	ret
    panic("kvmmap");
    800013be:	00007517          	auipc	a0,0x7
    800013c2:	d5a50513          	add	a0,a0,-678 # 80008118 <digits+0xd8>
    800013c6:	fffff097          	auipc	ra,0xfffff
    800013ca:	176080e7          	jalr	374(ra) # 8000053c <panic>

00000000800013ce <kvmmake>:
{
    800013ce:	1101                	add	sp,sp,-32
    800013d0:	ec06                	sd	ra,24(sp)
    800013d2:	e822                	sd	s0,16(sp)
    800013d4:	e426                	sd	s1,8(sp)
    800013d6:	e04a                	sd	s2,0(sp)
    800013d8:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	77e080e7          	jalr	1918(ra) # 80000b58 <kalloc>
    800013e2:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800013e4:	6605                	lui	a2,0x1
    800013e6:	4581                	li	a1,0
    800013e8:	00000097          	auipc	ra,0x0
    800013ec:	b4c080e7          	jalr	-1204(ra) # 80000f34 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800013f0:	4719                	li	a4,6
    800013f2:	6685                	lui	a3,0x1
    800013f4:	10000637          	lui	a2,0x10000
    800013f8:	100005b7          	lui	a1,0x10000
    800013fc:	8526                	mv	a0,s1
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	fa0080e7          	jalr	-96(ra) # 8000139e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001406:	4719                	li	a4,6
    80001408:	6685                	lui	a3,0x1
    8000140a:	10001637          	lui	a2,0x10001
    8000140e:	100015b7          	lui	a1,0x10001
    80001412:	8526                	mv	a0,s1
    80001414:	00000097          	auipc	ra,0x0
    80001418:	f8a080e7          	jalr	-118(ra) # 8000139e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000141c:	4719                	li	a4,6
    8000141e:	004006b7          	lui	a3,0x400
    80001422:	0c000637          	lui	a2,0xc000
    80001426:	0c0005b7          	lui	a1,0xc000
    8000142a:	8526                	mv	a0,s1
    8000142c:	00000097          	auipc	ra,0x0
    80001430:	f72080e7          	jalr	-142(ra) # 8000139e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001434:	00007917          	auipc	s2,0x7
    80001438:	bcc90913          	add	s2,s2,-1076 # 80008000 <etext>
    8000143c:	4729                	li	a4,10
    8000143e:	80007697          	auipc	a3,0x80007
    80001442:	bc268693          	add	a3,a3,-1086 # 8000 <_entry-0x7fff8000>
    80001446:	4605                	li	a2,1
    80001448:	067e                	sll	a2,a2,0x1f
    8000144a:	85b2                	mv	a1,a2
    8000144c:	8526                	mv	a0,s1
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	f50080e7          	jalr	-176(ra) # 8000139e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001456:	4719                	li	a4,6
    80001458:	46c5                	li	a3,17
    8000145a:	06ee                	sll	a3,a3,0x1b
    8000145c:	412686b3          	sub	a3,a3,s2
    80001460:	864a                	mv	a2,s2
    80001462:	85ca                	mv	a1,s2
    80001464:	8526                	mv	a0,s1
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	f38080e7          	jalr	-200(ra) # 8000139e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000146e:	4729                	li	a4,10
    80001470:	6685                	lui	a3,0x1
    80001472:	00006617          	auipc	a2,0x6
    80001476:	b8e60613          	add	a2,a2,-1138 # 80007000 <_trampoline>
    8000147a:	040005b7          	lui	a1,0x4000
    8000147e:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001480:	05b2                	sll	a1,a1,0xc
    80001482:	8526                	mv	a0,s1
    80001484:	00000097          	auipc	ra,0x0
    80001488:	f1a080e7          	jalr	-230(ra) # 8000139e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000148c:	8526                	mv	a0,s1
    8000148e:	00000097          	auipc	ra,0x0
    80001492:	600080e7          	jalr	1536(ra) # 80001a8e <proc_mapstacks>
}
    80001496:	8526                	mv	a0,s1
    80001498:	60e2                	ld	ra,24(sp)
    8000149a:	6442                	ld	s0,16(sp)
    8000149c:	64a2                	ld	s1,8(sp)
    8000149e:	6902                	ld	s2,0(sp)
    800014a0:	6105                	add	sp,sp,32
    800014a2:	8082                	ret

00000000800014a4 <kvminit>:
{
    800014a4:	1141                	add	sp,sp,-16
    800014a6:	e406                	sd	ra,8(sp)
    800014a8:	e022                	sd	s0,0(sp)
    800014aa:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    800014ac:	00000097          	auipc	ra,0x0
    800014b0:	f22080e7          	jalr	-222(ra) # 800013ce <kvmmake>
    800014b4:	00007797          	auipc	a5,0x7
    800014b8:	42a7be23          	sd	a0,1084(a5) # 800088f0 <kernel_pagetable>
}
    800014bc:	60a2                	ld	ra,8(sp)
    800014be:	6402                	ld	s0,0(sp)
    800014c0:	0141                	add	sp,sp,16
    800014c2:	8082                	ret

00000000800014c4 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800014c4:	715d                	add	sp,sp,-80
    800014c6:	e486                	sd	ra,72(sp)
    800014c8:	e0a2                	sd	s0,64(sp)
    800014ca:	fc26                	sd	s1,56(sp)
    800014cc:	f84a                	sd	s2,48(sp)
    800014ce:	f44e                	sd	s3,40(sp)
    800014d0:	f052                	sd	s4,32(sp)
    800014d2:	ec56                	sd	s5,24(sp)
    800014d4:	e85a                	sd	s6,16(sp)
    800014d6:	e45e                	sd	s7,8(sp)
    800014d8:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800014da:	03459793          	sll	a5,a1,0x34
    800014de:	e795                	bnez	a5,8000150a <uvmunmap+0x46>
    800014e0:	8a2a                	mv	s4,a0
    800014e2:	892e                	mv	s2,a1
    800014e4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014e6:	0632                	sll	a2,a2,0xc
    800014e8:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800014ec:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014ee:	6b05                	lui	s6,0x1
    800014f0:	0735e263          	bltu	a1,s3,80001554 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800014f4:	60a6                	ld	ra,72(sp)
    800014f6:	6406                	ld	s0,64(sp)
    800014f8:	74e2                	ld	s1,56(sp)
    800014fa:	7942                	ld	s2,48(sp)
    800014fc:	79a2                	ld	s3,40(sp)
    800014fe:	7a02                	ld	s4,32(sp)
    80001500:	6ae2                	ld	s5,24(sp)
    80001502:	6b42                	ld	s6,16(sp)
    80001504:	6ba2                	ld	s7,8(sp)
    80001506:	6161                	add	sp,sp,80
    80001508:	8082                	ret
    panic("uvmunmap: not aligned");
    8000150a:	00007517          	auipc	a0,0x7
    8000150e:	c1650513          	add	a0,a0,-1002 # 80008120 <digits+0xe0>
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	02a080e7          	jalr	42(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    8000151a:	00007517          	auipc	a0,0x7
    8000151e:	c1e50513          	add	a0,a0,-994 # 80008138 <digits+0xf8>
    80001522:	fffff097          	auipc	ra,0xfffff
    80001526:	01a080e7          	jalr	26(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    8000152a:	00007517          	auipc	a0,0x7
    8000152e:	c1e50513          	add	a0,a0,-994 # 80008148 <digits+0x108>
    80001532:	fffff097          	auipc	ra,0xfffff
    80001536:	00a080e7          	jalr	10(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    8000153a:	00007517          	auipc	a0,0x7
    8000153e:	c2650513          	add	a0,a0,-986 # 80008160 <digits+0x120>
    80001542:	fffff097          	auipc	ra,0xfffff
    80001546:	ffa080e7          	jalr	-6(ra) # 8000053c <panic>
    *pte = 0;
    8000154a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000154e:	995a                	add	s2,s2,s6
    80001550:	fb3972e3          	bgeu	s2,s3,800014f4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001554:	4601                	li	a2,0
    80001556:	85ca                	mv	a1,s2
    80001558:	8552                	mv	a0,s4
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	cbc080e7          	jalr	-836(ra) # 80001216 <walk>
    80001562:	84aa                	mv	s1,a0
    80001564:	d95d                	beqz	a0,8000151a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001566:	6108                	ld	a0,0(a0)
    80001568:	00157793          	and	a5,a0,1
    8000156c:	dfdd                	beqz	a5,8000152a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000156e:	3ff57793          	and	a5,a0,1023
    80001572:	fd7784e3          	beq	a5,s7,8000153a <uvmunmap+0x76>
    if(do_free){
    80001576:	fc0a8ae3          	beqz	s5,8000154a <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000157a:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    8000157c:	0532                	sll	a0,a0,0xc
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	466080e7          	jalr	1126(ra) # 800009e4 <kfree>
    80001586:	b7d1                	j	8000154a <uvmunmap+0x86>

0000000080001588 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001588:	1101                	add	sp,sp,-32
    8000158a:	ec06                	sd	ra,24(sp)
    8000158c:	e822                	sd	s0,16(sp)
    8000158e:	e426                	sd	s1,8(sp)
    80001590:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001592:	fffff097          	auipc	ra,0xfffff
    80001596:	5c6080e7          	jalr	1478(ra) # 80000b58 <kalloc>
    8000159a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000159c:	c519                	beqz	a0,800015aa <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000159e:	6605                	lui	a2,0x1
    800015a0:	4581                	li	a1,0
    800015a2:	00000097          	auipc	ra,0x0
    800015a6:	992080e7          	jalr	-1646(ra) # 80000f34 <memset>
  return pagetable;
}
    800015aa:	8526                	mv	a0,s1
    800015ac:	60e2                	ld	ra,24(sp)
    800015ae:	6442                	ld	s0,16(sp)
    800015b0:	64a2                	ld	s1,8(sp)
    800015b2:	6105                	add	sp,sp,32
    800015b4:	8082                	ret

00000000800015b6 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800015b6:	7179                	add	sp,sp,-48
    800015b8:	f406                	sd	ra,40(sp)
    800015ba:	f022                	sd	s0,32(sp)
    800015bc:	ec26                	sd	s1,24(sp)
    800015be:	e84a                	sd	s2,16(sp)
    800015c0:	e44e                	sd	s3,8(sp)
    800015c2:	e052                	sd	s4,0(sp)
    800015c4:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800015c6:	6785                	lui	a5,0x1
    800015c8:	04f67863          	bgeu	a2,a5,80001618 <uvmfirst+0x62>
    800015cc:	8a2a                	mv	s4,a0
    800015ce:	89ae                	mv	s3,a1
    800015d0:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800015d2:	fffff097          	auipc	ra,0xfffff
    800015d6:	586080e7          	jalr	1414(ra) # 80000b58 <kalloc>
    800015da:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800015dc:	6605                	lui	a2,0x1
    800015de:	4581                	li	a1,0
    800015e0:	00000097          	auipc	ra,0x0
    800015e4:	954080e7          	jalr	-1708(ra) # 80000f34 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800015e8:	4779                	li	a4,30
    800015ea:	86ca                	mv	a3,s2
    800015ec:	6605                	lui	a2,0x1
    800015ee:	4581                	li	a1,0
    800015f0:	8552                	mv	a0,s4
    800015f2:	00000097          	auipc	ra,0x0
    800015f6:	d0c080e7          	jalr	-756(ra) # 800012fe <mappages>
  memmove(mem, src, sz);
    800015fa:	8626                	mv	a2,s1
    800015fc:	85ce                	mv	a1,s3
    800015fe:	854a                	mv	a0,s2
    80001600:	00000097          	auipc	ra,0x0
    80001604:	990080e7          	jalr	-1648(ra) # 80000f90 <memmove>
}
    80001608:	70a2                	ld	ra,40(sp)
    8000160a:	7402                	ld	s0,32(sp)
    8000160c:	64e2                	ld	s1,24(sp)
    8000160e:	6942                	ld	s2,16(sp)
    80001610:	69a2                	ld	s3,8(sp)
    80001612:	6a02                	ld	s4,0(sp)
    80001614:	6145                	add	sp,sp,48
    80001616:	8082                	ret
    panic("uvmfirst: more than a page");
    80001618:	00007517          	auipc	a0,0x7
    8000161c:	b6050513          	add	a0,a0,-1184 # 80008178 <digits+0x138>
    80001620:	fffff097          	auipc	ra,0xfffff
    80001624:	f1c080e7          	jalr	-228(ra) # 8000053c <panic>

0000000080001628 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001628:	1101                	add	sp,sp,-32
    8000162a:	ec06                	sd	ra,24(sp)
    8000162c:	e822                	sd	s0,16(sp)
    8000162e:	e426                	sd	s1,8(sp)
    80001630:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001632:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001634:	00b67d63          	bgeu	a2,a1,8000164e <uvmdealloc+0x26>
    80001638:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000163a:	6785                	lui	a5,0x1
    8000163c:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000163e:	00f60733          	add	a4,a2,a5
    80001642:	76fd                	lui	a3,0xfffff
    80001644:	8f75                	and	a4,a4,a3
    80001646:	97ae                	add	a5,a5,a1
    80001648:	8ff5                	and	a5,a5,a3
    8000164a:	00f76863          	bltu	a4,a5,8000165a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000164e:	8526                	mv	a0,s1
    80001650:	60e2                	ld	ra,24(sp)
    80001652:	6442                	ld	s0,16(sp)
    80001654:	64a2                	ld	s1,8(sp)
    80001656:	6105                	add	sp,sp,32
    80001658:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000165a:	8f99                	sub	a5,a5,a4
    8000165c:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000165e:	4685                	li	a3,1
    80001660:	0007861b          	sext.w	a2,a5
    80001664:	85ba                	mv	a1,a4
    80001666:	00000097          	auipc	ra,0x0
    8000166a:	e5e080e7          	jalr	-418(ra) # 800014c4 <uvmunmap>
    8000166e:	b7c5                	j	8000164e <uvmdealloc+0x26>

0000000080001670 <uvmalloc>:
  if(newsz < oldsz)
    80001670:	0ab66563          	bltu	a2,a1,8000171a <uvmalloc+0xaa>
{
    80001674:	7139                	add	sp,sp,-64
    80001676:	fc06                	sd	ra,56(sp)
    80001678:	f822                	sd	s0,48(sp)
    8000167a:	f426                	sd	s1,40(sp)
    8000167c:	f04a                	sd	s2,32(sp)
    8000167e:	ec4e                	sd	s3,24(sp)
    80001680:	e852                	sd	s4,16(sp)
    80001682:	e456                	sd	s5,8(sp)
    80001684:	e05a                	sd	s6,0(sp)
    80001686:	0080                	add	s0,sp,64
    80001688:	8aaa                	mv	s5,a0
    8000168a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000168c:	6785                	lui	a5,0x1
    8000168e:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001690:	95be                	add	a1,a1,a5
    80001692:	77fd                	lui	a5,0xfffff
    80001694:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001698:	08c9f363          	bgeu	s3,a2,8000171e <uvmalloc+0xae>
    8000169c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000169e:	0126eb13          	or	s6,a3,18
    mem = kalloc();
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	4b6080e7          	jalr	1206(ra) # 80000b58 <kalloc>
    800016aa:	84aa                	mv	s1,a0
    if(mem == 0){
    800016ac:	c51d                	beqz	a0,800016da <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800016ae:	6605                	lui	a2,0x1
    800016b0:	4581                	li	a1,0
    800016b2:	00000097          	auipc	ra,0x0
    800016b6:	882080e7          	jalr	-1918(ra) # 80000f34 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800016ba:	875a                	mv	a4,s6
    800016bc:	86a6                	mv	a3,s1
    800016be:	6605                	lui	a2,0x1
    800016c0:	85ca                	mv	a1,s2
    800016c2:	8556                	mv	a0,s5
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	c3a080e7          	jalr	-966(ra) # 800012fe <mappages>
    800016cc:	e90d                	bnez	a0,800016fe <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800016ce:	6785                	lui	a5,0x1
    800016d0:	993e                	add	s2,s2,a5
    800016d2:	fd4968e3          	bltu	s2,s4,800016a2 <uvmalloc+0x32>
  return newsz;
    800016d6:	8552                	mv	a0,s4
    800016d8:	a809                	j	800016ea <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800016da:	864e                	mv	a2,s3
    800016dc:	85ca                	mv	a1,s2
    800016de:	8556                	mv	a0,s5
    800016e0:	00000097          	auipc	ra,0x0
    800016e4:	f48080e7          	jalr	-184(ra) # 80001628 <uvmdealloc>
      return 0;
    800016e8:	4501                	li	a0,0
}
    800016ea:	70e2                	ld	ra,56(sp)
    800016ec:	7442                	ld	s0,48(sp)
    800016ee:	74a2                	ld	s1,40(sp)
    800016f0:	7902                	ld	s2,32(sp)
    800016f2:	69e2                	ld	s3,24(sp)
    800016f4:	6a42                	ld	s4,16(sp)
    800016f6:	6aa2                	ld	s5,8(sp)
    800016f8:	6b02                	ld	s6,0(sp)
    800016fa:	6121                	add	sp,sp,64
    800016fc:	8082                	ret
      kfree(mem);
    800016fe:	8526                	mv	a0,s1
    80001700:	fffff097          	auipc	ra,0xfffff
    80001704:	2e4080e7          	jalr	740(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001708:	864e                	mv	a2,s3
    8000170a:	85ca                	mv	a1,s2
    8000170c:	8556                	mv	a0,s5
    8000170e:	00000097          	auipc	ra,0x0
    80001712:	f1a080e7          	jalr	-230(ra) # 80001628 <uvmdealloc>
      return 0;
    80001716:	4501                	li	a0,0
    80001718:	bfc9                	j	800016ea <uvmalloc+0x7a>
    return oldsz;
    8000171a:	852e                	mv	a0,a1
}
    8000171c:	8082                	ret
  return newsz;
    8000171e:	8532                	mv	a0,a2
    80001720:	b7e9                	j	800016ea <uvmalloc+0x7a>

0000000080001722 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001722:	7179                	add	sp,sp,-48
    80001724:	f406                	sd	ra,40(sp)
    80001726:	f022                	sd	s0,32(sp)
    80001728:	ec26                	sd	s1,24(sp)
    8000172a:	e84a                	sd	s2,16(sp)
    8000172c:	e44e                	sd	s3,8(sp)
    8000172e:	e052                	sd	s4,0(sp)
    80001730:	1800                	add	s0,sp,48
    80001732:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001734:	84aa                	mv	s1,a0
    80001736:	6905                	lui	s2,0x1
    80001738:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000173a:	4985                	li	s3,1
    8000173c:	a829                	j	80001756 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000173e:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001740:	00c79513          	sll	a0,a5,0xc
    80001744:	00000097          	auipc	ra,0x0
    80001748:	fde080e7          	jalr	-34(ra) # 80001722 <freewalk>
      pagetable[i] = 0;
    8000174c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001750:	04a1                	add	s1,s1,8
    80001752:	03248163          	beq	s1,s2,80001774 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001756:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001758:	00f7f713          	and	a4,a5,15
    8000175c:	ff3701e3          	beq	a4,s3,8000173e <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001760:	8b85                	and	a5,a5,1
    80001762:	d7fd                	beqz	a5,80001750 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001764:	00007517          	auipc	a0,0x7
    80001768:	a3450513          	add	a0,a0,-1484 # 80008198 <digits+0x158>
    8000176c:	fffff097          	auipc	ra,0xfffff
    80001770:	dd0080e7          	jalr	-560(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    80001774:	8552                	mv	a0,s4
    80001776:	fffff097          	auipc	ra,0xfffff
    8000177a:	26e080e7          	jalr	622(ra) # 800009e4 <kfree>
}
    8000177e:	70a2                	ld	ra,40(sp)
    80001780:	7402                	ld	s0,32(sp)
    80001782:	64e2                	ld	s1,24(sp)
    80001784:	6942                	ld	s2,16(sp)
    80001786:	69a2                	ld	s3,8(sp)
    80001788:	6a02                	ld	s4,0(sp)
    8000178a:	6145                	add	sp,sp,48
    8000178c:	8082                	ret

000000008000178e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000178e:	1101                	add	sp,sp,-32
    80001790:	ec06                	sd	ra,24(sp)
    80001792:	e822                	sd	s0,16(sp)
    80001794:	e426                	sd	s1,8(sp)
    80001796:	1000                	add	s0,sp,32
    80001798:	84aa                	mv	s1,a0
  if(sz > 0)
    8000179a:	e999                	bnez	a1,800017b0 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000179c:	8526                	mv	a0,s1
    8000179e:	00000097          	auipc	ra,0x0
    800017a2:	f84080e7          	jalr	-124(ra) # 80001722 <freewalk>
}
    800017a6:	60e2                	ld	ra,24(sp)
    800017a8:	6442                	ld	s0,16(sp)
    800017aa:	64a2                	ld	s1,8(sp)
    800017ac:	6105                	add	sp,sp,32
    800017ae:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800017b0:	6785                	lui	a5,0x1
    800017b2:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800017b4:	95be                	add	a1,a1,a5
    800017b6:	4685                	li	a3,1
    800017b8:	00c5d613          	srl	a2,a1,0xc
    800017bc:	4581                	li	a1,0
    800017be:	00000097          	auipc	ra,0x0
    800017c2:	d06080e7          	jalr	-762(ra) # 800014c4 <uvmunmap>
    800017c6:	bfd9                	j	8000179c <uvmfree+0xe>

00000000800017c8 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    800017c8:	7139                	add	sp,sp,-64
    800017ca:	fc06                	sd	ra,56(sp)
    800017cc:	f822                	sd	s0,48(sp)
    800017ce:	f426                	sd	s1,40(sp)
    800017d0:	f04a                	sd	s2,32(sp)
    800017d2:	ec4e                	sd	s3,24(sp)
    800017d4:	e852                	sd	s4,16(sp)
    800017d6:	e456                	sd	s5,8(sp)
    800017d8:	e05a                	sd	s6,0(sp)
    800017da:	0080                	add	s0,sp,64
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    800017dc:	c645                	beqz	a2,80001884 <uvmcopy+0xbc>
    800017de:	8aaa                	mv	s5,a0
    800017e0:	8a2e                	mv	s4,a1
    800017e2:	89b2                	mv	s3,a2
    800017e4:	4481                	li	s1,0
    if((pte = walk(old, i, 0)) == 0)
    800017e6:	4601                	li	a2,0
    800017e8:	85a6                	mv	a1,s1
    800017ea:	8556                	mv	a0,s5
    800017ec:	00000097          	auipc	ra,0x0
    800017f0:	a2a080e7          	jalr	-1494(ra) # 80001216 <walk>
    800017f4:	c139                	beqz	a0,8000183a <uvmcopy+0x72>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800017f6:	6118                	ld	a4,0(a0)
    800017f8:	00177793          	and	a5,a4,1
    800017fc:	c7b9                	beqz	a5,8000184a <uvmcopy+0x82>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800017fe:	00a75913          	srl	s2,a4,0xa
    80001802:	0932                	sll	s2,s2,0xc

    *pte = (*pte & ~PTE_W) | PTE_COW;
    80001804:	fdb77713          	and	a4,a4,-37
    80001808:	02076713          	or	a4,a4,32
    8000180c:	e118                	sd	a4,0(a0)
    flags = PTE_FLAGS(*pte);
    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    8000180e:	3fb77713          	and	a4,a4,1019
    80001812:	86ca                	mv	a3,s2
    80001814:	6605                	lui	a2,0x1
    80001816:	85a6                	mv	a1,s1
    80001818:	8552                	mv	a0,s4
    8000181a:	00000097          	auipc	ra,0x0
    8000181e:	ae4080e7          	jalr	-1308(ra) # 800012fe <mappages>
    80001822:	8b2a                	mv	s6,a0
    80001824:	e91d                	bnez	a0,8000185a <uvmcopy+0x92>
      goto err;
    }
    addReference((void*)pa);
    80001826:	854a                	mv	a0,s2
    80001828:	fffff097          	auipc	ra,0xfffff
    8000182c:	3ac080e7          	jalr	940(ra) # 80000bd4 <addReference>
  for(i = 0; i < sz; i += PGSIZE){
    80001830:	6785                	lui	a5,0x1
    80001832:	94be                	add	s1,s1,a5
    80001834:	fb34e9e3          	bltu	s1,s3,800017e6 <uvmcopy+0x1e>
    80001838:	a81d                	j	8000186e <uvmcopy+0xa6>
      panic("uvmcopy: pte should exist");
    8000183a:	00007517          	auipc	a0,0x7
    8000183e:	96e50513          	add	a0,a0,-1682 # 800081a8 <digits+0x168>
    80001842:	fffff097          	auipc	ra,0xfffff
    80001846:	cfa080e7          	jalr	-774(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    8000184a:	00007517          	auipc	a0,0x7
    8000184e:	97e50513          	add	a0,a0,-1666 # 800081c8 <digits+0x188>
    80001852:	fffff097          	auipc	ra,0xfffff
    80001856:	cea080e7          	jalr	-790(ra) # 8000053c <panic>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000185a:	4685                	li	a3,1
    8000185c:	00c4d613          	srl	a2,s1,0xc
    80001860:	4581                	li	a1,0
    80001862:	8552                	mv	a0,s4
    80001864:	00000097          	auipc	ra,0x0
    80001868:	c60080e7          	jalr	-928(ra) # 800014c4 <uvmunmap>
  return -1;
    8000186c:	5b7d                	li	s6,-1
}
    8000186e:	855a                	mv	a0,s6
    80001870:	70e2                	ld	ra,56(sp)
    80001872:	7442                	ld	s0,48(sp)
    80001874:	74a2                	ld	s1,40(sp)
    80001876:	7902                	ld	s2,32(sp)
    80001878:	69e2                	ld	s3,24(sp)
    8000187a:	6a42                	ld	s4,16(sp)
    8000187c:	6aa2                	ld	s5,8(sp)
    8000187e:	6b02                	ld	s6,0(sp)
    80001880:	6121                	add	sp,sp,64
    80001882:	8082                	ret
  return 0;
    80001884:	4b01                	li	s6,0
    80001886:	b7e5                	j	8000186e <uvmcopy+0xa6>

0000000080001888 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001888:	1141                	add	sp,sp,-16
    8000188a:	e406                	sd	ra,8(sp)
    8000188c:	e022                	sd	s0,0(sp)
    8000188e:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001890:	4601                	li	a2,0
    80001892:	00000097          	auipc	ra,0x0
    80001896:	984080e7          	jalr	-1660(ra) # 80001216 <walk>
  if(pte == 0)
    8000189a:	c901                	beqz	a0,800018aa <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000189c:	611c                	ld	a5,0(a0)
    8000189e:	9bbd                	and	a5,a5,-17
    800018a0:	e11c                	sd	a5,0(a0)
}
    800018a2:	60a2                	ld	ra,8(sp)
    800018a4:	6402                	ld	s0,0(sp)
    800018a6:	0141                	add	sp,sp,16
    800018a8:	8082                	ret
    panic("uvmclear");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	93e50513          	add	a0,a0,-1730 # 800081e8 <digits+0x1a8>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c8a080e7          	jalr	-886(ra) # 8000053c <panic>

00000000800018ba <copyout>:
// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
    800018ba:	715d                	add	sp,sp,-80
    800018bc:	e486                	sd	ra,72(sp)
    800018be:	e0a2                	sd	s0,64(sp)
    800018c0:	fc26                	sd	s1,56(sp)
    800018c2:	f84a                	sd	s2,48(sp)
    800018c4:	f44e                	sd	s3,40(sp)
    800018c6:	f052                	sd	s4,32(sp)
    800018c8:	ec56                	sd	s5,24(sp)
    800018ca:	e85a                	sd	s6,16(sp)
    800018cc:	e45e                	sd	s7,8(sp)
    800018ce:	e062                	sd	s8,0(sp)
    800018d0:	0880                	add	s0,sp,80
    800018d2:	8b2a                	mv	s6,a0
    800018d4:	8c2e                	mv	s8,a1
    800018d6:	8a32                	mv	s4,a2
    800018d8:	89b6                	mv	s3,a3
  uint64 n, va0, pa0;

  pagefhandler(pagetable,dstva); // Makes page fault exception if it is a cow page
    800018da:	fffff097          	auipc	ra,0xfffff
    800018de:	40e080e7          	jalr	1038(ra) # 80000ce8 <pagefhandler>

  while(len > 0){
    800018e2:	04098863          	beqz	s3,80001932 <copyout+0x78>
    va0 = PGROUNDDOWN(dstva);
    800018e6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800018e8:	6a85                	lui	s5,0x1
    800018ea:	a015                	j	8000190e <copyout+0x54>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800018ec:	9562                	add	a0,a0,s8
    800018ee:	0004861b          	sext.w	a2,s1
    800018f2:	85d2                	mv	a1,s4
    800018f4:	41250533          	sub	a0,a0,s2
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	698080e7          	jalr	1688(ra) # 80000f90 <memmove>

    len -= n;
    80001900:	409989b3          	sub	s3,s3,s1
    src += n;
    80001904:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001906:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000190a:	02098263          	beqz	s3,8000192e <copyout+0x74>
    va0 = PGROUNDDOWN(dstva);
    8000190e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001912:	85ca                	mv	a1,s2
    80001914:	855a                	mv	a0,s6
    80001916:	00000097          	auipc	ra,0x0
    8000191a:	9a6080e7          	jalr	-1626(ra) # 800012bc <walkaddr>
    if(pa0 == 0)
    8000191e:	cd01                	beqz	a0,80001936 <copyout+0x7c>
    n = PGSIZE - (dstva - va0);
    80001920:	418904b3          	sub	s1,s2,s8
    80001924:	94d6                	add	s1,s1,s5
    80001926:	fc99f3e3          	bgeu	s3,s1,800018ec <copyout+0x32>
    8000192a:	84ce                	mv	s1,s3
    8000192c:	b7c1                	j	800018ec <copyout+0x32>
  }
  return 0;
    8000192e:	4501                	li	a0,0
    80001930:	a021                	j	80001938 <copyout+0x7e>
    80001932:	4501                	li	a0,0
    80001934:	a011                	j	80001938 <copyout+0x7e>
      return -1;
    80001936:	557d                	li	a0,-1
}
    80001938:	60a6                	ld	ra,72(sp)
    8000193a:	6406                	ld	s0,64(sp)
    8000193c:	74e2                	ld	s1,56(sp)
    8000193e:	7942                	ld	s2,48(sp)
    80001940:	79a2                	ld	s3,40(sp)
    80001942:	7a02                	ld	s4,32(sp)
    80001944:	6ae2                	ld	s5,24(sp)
    80001946:	6b42                	ld	s6,16(sp)
    80001948:	6ba2                	ld	s7,8(sp)
    8000194a:	6c02                	ld	s8,0(sp)
    8000194c:	6161                	add	sp,sp,80
    8000194e:	8082                	ret

0000000080001950 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001950:	caa5                	beqz	a3,800019c0 <copyin+0x70>
{
    80001952:	715d                	add	sp,sp,-80
    80001954:	e486                	sd	ra,72(sp)
    80001956:	e0a2                	sd	s0,64(sp)
    80001958:	fc26                	sd	s1,56(sp)
    8000195a:	f84a                	sd	s2,48(sp)
    8000195c:	f44e                	sd	s3,40(sp)
    8000195e:	f052                	sd	s4,32(sp)
    80001960:	ec56                	sd	s5,24(sp)
    80001962:	e85a                	sd	s6,16(sp)
    80001964:	e45e                	sd	s7,8(sp)
    80001966:	e062                	sd	s8,0(sp)
    80001968:	0880                	add	s0,sp,80
    8000196a:	8b2a                	mv	s6,a0
    8000196c:	8a2e                	mv	s4,a1
    8000196e:	8c32                	mv	s8,a2
    80001970:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001972:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001974:	6a85                	lui	s5,0x1
    80001976:	a01d                	j	8000199c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001978:	018505b3          	add	a1,a0,s8
    8000197c:	0004861b          	sext.w	a2,s1
    80001980:	412585b3          	sub	a1,a1,s2
    80001984:	8552                	mv	a0,s4
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	60a080e7          	jalr	1546(ra) # 80000f90 <memmove>

    len -= n;
    8000198e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001992:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001994:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001998:	02098263          	beqz	s3,800019bc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000199c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800019a0:	85ca                	mv	a1,s2
    800019a2:	855a                	mv	a0,s6
    800019a4:	00000097          	auipc	ra,0x0
    800019a8:	918080e7          	jalr	-1768(ra) # 800012bc <walkaddr>
    if(pa0 == 0)
    800019ac:	cd01                	beqz	a0,800019c4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800019ae:	418904b3          	sub	s1,s2,s8
    800019b2:	94d6                	add	s1,s1,s5
    800019b4:	fc99f2e3          	bgeu	s3,s1,80001978 <copyin+0x28>
    800019b8:	84ce                	mv	s1,s3
    800019ba:	bf7d                	j	80001978 <copyin+0x28>
  }
  return 0;
    800019bc:	4501                	li	a0,0
    800019be:	a021                	j	800019c6 <copyin+0x76>
    800019c0:	4501                	li	a0,0
}
    800019c2:	8082                	ret
      return -1;
    800019c4:	557d                	li	a0,-1
}
    800019c6:	60a6                	ld	ra,72(sp)
    800019c8:	6406                	ld	s0,64(sp)
    800019ca:	74e2                	ld	s1,56(sp)
    800019cc:	7942                	ld	s2,48(sp)
    800019ce:	79a2                	ld	s3,40(sp)
    800019d0:	7a02                	ld	s4,32(sp)
    800019d2:	6ae2                	ld	s5,24(sp)
    800019d4:	6b42                	ld	s6,16(sp)
    800019d6:	6ba2                	ld	s7,8(sp)
    800019d8:	6c02                	ld	s8,0(sp)
    800019da:	6161                	add	sp,sp,80
    800019dc:	8082                	ret

00000000800019de <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800019de:	c2dd                	beqz	a3,80001a84 <copyinstr+0xa6>
{
    800019e0:	715d                	add	sp,sp,-80
    800019e2:	e486                	sd	ra,72(sp)
    800019e4:	e0a2                	sd	s0,64(sp)
    800019e6:	fc26                	sd	s1,56(sp)
    800019e8:	f84a                	sd	s2,48(sp)
    800019ea:	f44e                	sd	s3,40(sp)
    800019ec:	f052                	sd	s4,32(sp)
    800019ee:	ec56                	sd	s5,24(sp)
    800019f0:	e85a                	sd	s6,16(sp)
    800019f2:	e45e                	sd	s7,8(sp)
    800019f4:	0880                	add	s0,sp,80
    800019f6:	8a2a                	mv	s4,a0
    800019f8:	8b2e                	mv	s6,a1
    800019fa:	8bb2                	mv	s7,a2
    800019fc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800019fe:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001a00:	6985                	lui	s3,0x1
    80001a02:	a02d                	j	80001a2c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001a04:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001a08:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001a0a:	37fd                	addw	a5,a5,-1
    80001a0c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
    80001a10:	60a6                	ld	ra,72(sp)
    80001a12:	6406                	ld	s0,64(sp)
    80001a14:	74e2                	ld	s1,56(sp)
    80001a16:	7942                	ld	s2,48(sp)
    80001a18:	79a2                	ld	s3,40(sp)
    80001a1a:	7a02                	ld	s4,32(sp)
    80001a1c:	6ae2                	ld	s5,24(sp)
    80001a1e:	6b42                	ld	s6,16(sp)
    80001a20:	6ba2                	ld	s7,8(sp)
    80001a22:	6161                	add	sp,sp,80
    80001a24:	8082                	ret
    srcva = va0 + PGSIZE;
    80001a26:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001a2a:	c8a9                	beqz	s1,80001a7c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001a2c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001a30:	85ca                	mv	a1,s2
    80001a32:	8552                	mv	a0,s4
    80001a34:	00000097          	auipc	ra,0x0
    80001a38:	888080e7          	jalr	-1912(ra) # 800012bc <walkaddr>
    if(pa0 == 0)
    80001a3c:	c131                	beqz	a0,80001a80 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001a3e:	417906b3          	sub	a3,s2,s7
    80001a42:	96ce                	add	a3,a3,s3
    80001a44:	00d4f363          	bgeu	s1,a3,80001a4a <copyinstr+0x6c>
    80001a48:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001a4a:	955e                	add	a0,a0,s7
    80001a4c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001a50:	daf9                	beqz	a3,80001a26 <copyinstr+0x48>
    80001a52:	87da                	mv	a5,s6
    80001a54:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001a56:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001a5a:	96da                	add	a3,a3,s6
    80001a5c:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001a5e:	00f60733          	add	a4,a2,a5
    80001a62:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffbc868>
    80001a66:	df59                	beqz	a4,80001a04 <copyinstr+0x26>
        *dst = *p;
    80001a68:	00e78023          	sb	a4,0(a5)
      dst++;
    80001a6c:	0785                	add	a5,a5,1
    while(n > 0){
    80001a6e:	fed797e3          	bne	a5,a3,80001a5c <copyinstr+0x7e>
    80001a72:	14fd                	add	s1,s1,-1
    80001a74:	94c2                	add	s1,s1,a6
      --max;
    80001a76:	8c8d                	sub	s1,s1,a1
      dst++;
    80001a78:	8b3e                	mv	s6,a5
    80001a7a:	b775                	j	80001a26 <copyinstr+0x48>
    80001a7c:	4781                	li	a5,0
    80001a7e:	b771                	j	80001a0a <copyinstr+0x2c>
      return -1;
    80001a80:	557d                	li	a0,-1
    80001a82:	b779                	j	80001a10 <copyinstr+0x32>
  int got_null = 0;
    80001a84:	4781                	li	a5,0
  if(got_null){
    80001a86:	37fd                	addw	a5,a5,-1
    80001a88:	0007851b          	sext.w	a0,a5
    80001a8c:	8082                	ret

0000000080001a8e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a8e:	7139                	add	sp,sp,-64
    80001a90:	fc06                	sd	ra,56(sp)
    80001a92:	f822                	sd	s0,48(sp)
    80001a94:	f426                	sd	s1,40(sp)
    80001a96:	f04a                	sd	s2,32(sp)
    80001a98:	ec4e                	sd	s3,24(sp)
    80001a9a:	e852                	sd	s4,16(sp)
    80001a9c:	e456                	sd	s5,8(sp)
    80001a9e:	e05a                	sd	s6,0(sp)
    80001aa0:	0080                	add	s0,sp,64
    80001aa2:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001aa4:	0002f497          	auipc	s1,0x2f
    80001aa8:	51448493          	add	s1,s1,1300 # 80030fb8 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001aac:	8b26                	mv	s6,s1
    80001aae:	00006a97          	auipc	s5,0x6
    80001ab2:	552a8a93          	add	s5,s5,1362 # 80008000 <etext>
    80001ab6:	04000937          	lui	s2,0x4000
    80001aba:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001abc:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001abe:	00036a17          	auipc	s4,0x36
    80001ac2:	8faa0a13          	add	s4,s4,-1798 # 800373b8 <tickslock>
    char *pa = kalloc();
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	092080e7          	jalr	146(ra) # 80000b58 <kalloc>
    80001ace:	862a                	mv	a2,a0
    if (pa == 0)
    80001ad0:	c131                	beqz	a0,80001b14 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001ad2:	416485b3          	sub	a1,s1,s6
    80001ad6:	8591                	sra	a1,a1,0x4
    80001ad8:	000ab783          	ld	a5,0(s5)
    80001adc:	02f585b3          	mul	a1,a1,a5
    80001ae0:	2585                	addw	a1,a1,1
    80001ae2:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ae6:	4719                	li	a4,6
    80001ae8:	6685                	lui	a3,0x1
    80001aea:	40b905b3          	sub	a1,s2,a1
    80001aee:	854e                	mv	a0,s3
    80001af0:	00000097          	auipc	ra,0x0
    80001af4:	8ae080e7          	jalr	-1874(ra) # 8000139e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001af8:	19048493          	add	s1,s1,400
    80001afc:	fd4495e3          	bne	s1,s4,80001ac6 <proc_mapstacks+0x38>
  }
}
    80001b00:	70e2                	ld	ra,56(sp)
    80001b02:	7442                	ld	s0,48(sp)
    80001b04:	74a2                	ld	s1,40(sp)
    80001b06:	7902                	ld	s2,32(sp)
    80001b08:	69e2                	ld	s3,24(sp)
    80001b0a:	6a42                	ld	s4,16(sp)
    80001b0c:	6aa2                	ld	s5,8(sp)
    80001b0e:	6b02                	ld	s6,0(sp)
    80001b10:	6121                	add	sp,sp,64
    80001b12:	8082                	ret
      panic("kalloc");
    80001b14:	00006517          	auipc	a0,0x6
    80001b18:	6e450513          	add	a0,a0,1764 # 800081f8 <digits+0x1b8>
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	a20080e7          	jalr	-1504(ra) # 8000053c <panic>

0000000080001b24 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001b24:	7139                	add	sp,sp,-64
    80001b26:	fc06                	sd	ra,56(sp)
    80001b28:	f822                	sd	s0,48(sp)
    80001b2a:	f426                	sd	s1,40(sp)
    80001b2c:	f04a                	sd	s2,32(sp)
    80001b2e:	ec4e                	sd	s3,24(sp)
    80001b30:	e852                	sd	s4,16(sp)
    80001b32:	e456                	sd	s5,8(sp)
    80001b34:	e05a                	sd	s6,0(sp)
    80001b36:	0080                	add	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001b38:	00006597          	auipc	a1,0x6
    80001b3c:	6c858593          	add	a1,a1,1736 # 80008200 <digits+0x1c0>
    80001b40:	0002f517          	auipc	a0,0x2f
    80001b44:	04850513          	add	a0,a0,72 # 80030b88 <pid_lock>
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	260080e7          	jalr	608(ra) # 80000da8 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b50:	00006597          	auipc	a1,0x6
    80001b54:	6b858593          	add	a1,a1,1720 # 80008208 <digits+0x1c8>
    80001b58:	0002f517          	auipc	a0,0x2f
    80001b5c:	04850513          	add	a0,a0,72 # 80030ba0 <wait_lock>
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	248080e7          	jalr	584(ra) # 80000da8 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001b68:	0002f497          	auipc	s1,0x2f
    80001b6c:	45048493          	add	s1,s1,1104 # 80030fb8 <proc>
  {
    initlock(&p->lock, "proc");
    80001b70:	00006b17          	auipc	s6,0x6
    80001b74:	6a8b0b13          	add	s6,s6,1704 # 80008218 <digits+0x1d8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001b78:	8aa6                	mv	s5,s1
    80001b7a:	00006a17          	auipc	s4,0x6
    80001b7e:	486a0a13          	add	s4,s4,1158 # 80008000 <etext>
    80001b82:	04000937          	lui	s2,0x4000
    80001b86:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b88:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b8a:	00036997          	auipc	s3,0x36
    80001b8e:	82e98993          	add	s3,s3,-2002 # 800373b8 <tickslock>
    initlock(&p->lock, "proc");
    80001b92:	85da                	mv	a1,s6
    80001b94:	8526                	mv	a0,s1
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	212080e7          	jalr	530(ra) # 80000da8 <initlock>
    p->state = UNUSED;
    80001b9e:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001ba2:	415487b3          	sub	a5,s1,s5
    80001ba6:	8791                	sra	a5,a5,0x4
    80001ba8:	000a3703          	ld	a4,0(s4)
    80001bac:	02e787b3          	mul	a5,a5,a4
    80001bb0:	2785                	addw	a5,a5,1
    80001bb2:	00d7979b          	sllw	a5,a5,0xd
    80001bb6:	40f907b3          	sub	a5,s2,a5
    80001bba:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001bbc:	19048493          	add	s1,s1,400
    80001bc0:	fd3499e3          	bne	s1,s3,80001b92 <procinit+0x6e>
  }
}
    80001bc4:	70e2                	ld	ra,56(sp)
    80001bc6:	7442                	ld	s0,48(sp)
    80001bc8:	74a2                	ld	s1,40(sp)
    80001bca:	7902                	ld	s2,32(sp)
    80001bcc:	69e2                	ld	s3,24(sp)
    80001bce:	6a42                	ld	s4,16(sp)
    80001bd0:	6aa2                	ld	s5,8(sp)
    80001bd2:	6b02                	ld	s6,0(sp)
    80001bd4:	6121                	add	sp,sp,64
    80001bd6:	8082                	ret

0000000080001bd8 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001bd8:	1141                	add	sp,sp,-16
    80001bda:	e422                	sd	s0,8(sp)
    80001bdc:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bde:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001be0:	2501                	sext.w	a0,a0
    80001be2:	6422                	ld	s0,8(sp)
    80001be4:	0141                	add	sp,sp,16
    80001be6:	8082                	ret

0000000080001be8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001be8:	1141                	add	sp,sp,-16
    80001bea:	e422                	sd	s0,8(sp)
    80001bec:	0800                	add	s0,sp,16
    80001bee:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001bf0:	2781                	sext.w	a5,a5
    80001bf2:	079e                	sll	a5,a5,0x7
  return c;
}
    80001bf4:	0002f517          	auipc	a0,0x2f
    80001bf8:	fc450513          	add	a0,a0,-60 # 80030bb8 <cpus>
    80001bfc:	953e                	add	a0,a0,a5
    80001bfe:	6422                	ld	s0,8(sp)
    80001c00:	0141                	add	sp,sp,16
    80001c02:	8082                	ret

0000000080001c04 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001c04:	1101                	add	sp,sp,-32
    80001c06:	ec06                	sd	ra,24(sp)
    80001c08:	e822                	sd	s0,16(sp)
    80001c0a:	e426                	sd	s1,8(sp)
    80001c0c:	1000                	add	s0,sp,32
  push_off();
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	1de080e7          	jalr	478(ra) # 80000dec <push_off>
    80001c16:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c18:	2781                	sext.w	a5,a5
    80001c1a:	079e                	sll	a5,a5,0x7
    80001c1c:	0002f717          	auipc	a4,0x2f
    80001c20:	f6c70713          	add	a4,a4,-148 # 80030b88 <pid_lock>
    80001c24:	97ba                	add	a5,a5,a4
    80001c26:	7b84                	ld	s1,48(a5)
  pop_off();
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	264080e7          	jalr	612(ra) # 80000e8c <pop_off>
  return p;
}
    80001c30:	8526                	mv	a0,s1
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6105                	add	sp,sp,32
    80001c3a:	8082                	ret

0000000080001c3c <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001c3c:	1141                	add	sp,sp,-16
    80001c3e:	e406                	sd	ra,8(sp)
    80001c40:	e022                	sd	s0,0(sp)
    80001c42:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	fc0080e7          	jalr	-64(ra) # 80001c04 <myproc>
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	2a0080e7          	jalr	672(ra) # 80000eec <release>

  if (first)
    80001c54:	00007797          	auipc	a5,0x7
    80001c58:	c2c7a783          	lw	a5,-980(a5) # 80008880 <first.1>
    80001c5c:	eb89                	bnez	a5,80001c6e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c5e:	00001097          	auipc	ra,0x1
    80001c62:	f70080e7          	jalr	-144(ra) # 80002bce <usertrapret>
}
    80001c66:	60a2                	ld	ra,8(sp)
    80001c68:	6402                	ld	s0,0(sp)
    80001c6a:	0141                	add	sp,sp,16
    80001c6c:	8082                	ret
    first = 0;
    80001c6e:	00007797          	auipc	a5,0x7
    80001c72:	c007a923          	sw	zero,-1006(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001c76:	4505                	li	a0,1
    80001c78:	00002097          	auipc	ra,0x2
    80001c7c:	e30080e7          	jalr	-464(ra) # 80003aa8 <fsinit>
    80001c80:	bff9                	j	80001c5e <forkret+0x22>

0000000080001c82 <allocpid>:
{
    80001c82:	1101                	add	sp,sp,-32
    80001c84:	ec06                	sd	ra,24(sp)
    80001c86:	e822                	sd	s0,16(sp)
    80001c88:	e426                	sd	s1,8(sp)
    80001c8a:	e04a                	sd	s2,0(sp)
    80001c8c:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001c8e:	0002f917          	auipc	s2,0x2f
    80001c92:	efa90913          	add	s2,s2,-262 # 80030b88 <pid_lock>
    80001c96:	854a                	mv	a0,s2
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	1a0080e7          	jalr	416(ra) # 80000e38 <acquire>
  pid = nextpid;
    80001ca0:	00007797          	auipc	a5,0x7
    80001ca4:	be478793          	add	a5,a5,-1052 # 80008884 <nextpid>
    80001ca8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001caa:	0014871b          	addw	a4,s1,1
    80001cae:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001cb0:	854a                	mv	a0,s2
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	23a080e7          	jalr	570(ra) # 80000eec <release>
}
    80001cba:	8526                	mv	a0,s1
    80001cbc:	60e2                	ld	ra,24(sp)
    80001cbe:	6442                	ld	s0,16(sp)
    80001cc0:	64a2                	ld	s1,8(sp)
    80001cc2:	6902                	ld	s2,0(sp)
    80001cc4:	6105                	add	sp,sp,32
    80001cc6:	8082                	ret

0000000080001cc8 <proc_pagetable>:
{
    80001cc8:	1101                	add	sp,sp,-32
    80001cca:	ec06                	sd	ra,24(sp)
    80001ccc:	e822                	sd	s0,16(sp)
    80001cce:	e426                	sd	s1,8(sp)
    80001cd0:	e04a                	sd	s2,0(sp)
    80001cd2:	1000                	add	s0,sp,32
    80001cd4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	8b2080e7          	jalr	-1870(ra) # 80001588 <uvmcreate>
    80001cde:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001ce0:	c121                	beqz	a0,80001d20 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ce2:	4729                	li	a4,10
    80001ce4:	00005697          	auipc	a3,0x5
    80001ce8:	31c68693          	add	a3,a3,796 # 80007000 <_trampoline>
    80001cec:	6605                	lui	a2,0x1
    80001cee:	040005b7          	lui	a1,0x4000
    80001cf2:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cf4:	05b2                	sll	a1,a1,0xc
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	608080e7          	jalr	1544(ra) # 800012fe <mappages>
    80001cfe:	02054863          	bltz	a0,80001d2e <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d02:	4719                	li	a4,6
    80001d04:	05893683          	ld	a3,88(s2)
    80001d08:	6605                	lui	a2,0x1
    80001d0a:	020005b7          	lui	a1,0x2000
    80001d0e:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d10:	05b6                	sll	a1,a1,0xd
    80001d12:	8526                	mv	a0,s1
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	5ea080e7          	jalr	1514(ra) # 800012fe <mappages>
    80001d1c:	02054163          	bltz	a0,80001d3e <proc_pagetable+0x76>
}
    80001d20:	8526                	mv	a0,s1
    80001d22:	60e2                	ld	ra,24(sp)
    80001d24:	6442                	ld	s0,16(sp)
    80001d26:	64a2                	ld	s1,8(sp)
    80001d28:	6902                	ld	s2,0(sp)
    80001d2a:	6105                	add	sp,sp,32
    80001d2c:	8082                	ret
    uvmfree(pagetable, 0);
    80001d2e:	4581                	li	a1,0
    80001d30:	8526                	mv	a0,s1
    80001d32:	00000097          	auipc	ra,0x0
    80001d36:	a5c080e7          	jalr	-1444(ra) # 8000178e <uvmfree>
    return 0;
    80001d3a:	4481                	li	s1,0
    80001d3c:	b7d5                	j	80001d20 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d3e:	4681                	li	a3,0
    80001d40:	4605                	li	a2,1
    80001d42:	040005b7          	lui	a1,0x4000
    80001d46:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d48:	05b2                	sll	a1,a1,0xc
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	778080e7          	jalr	1912(ra) # 800014c4 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d54:	4581                	li	a1,0
    80001d56:	8526                	mv	a0,s1
    80001d58:	00000097          	auipc	ra,0x0
    80001d5c:	a36080e7          	jalr	-1482(ra) # 8000178e <uvmfree>
    return 0;
    80001d60:	4481                	li	s1,0
    80001d62:	bf7d                	j	80001d20 <proc_pagetable+0x58>

0000000080001d64 <proc_freepagetable>:
{
    80001d64:	1101                	add	sp,sp,-32
    80001d66:	ec06                	sd	ra,24(sp)
    80001d68:	e822                	sd	s0,16(sp)
    80001d6a:	e426                	sd	s1,8(sp)
    80001d6c:	e04a                	sd	s2,0(sp)
    80001d6e:	1000                	add	s0,sp,32
    80001d70:	84aa                	mv	s1,a0
    80001d72:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d74:	4681                	li	a3,0
    80001d76:	4605                	li	a2,1
    80001d78:	040005b7          	lui	a1,0x4000
    80001d7c:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d7e:	05b2                	sll	a1,a1,0xc
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	744080e7          	jalr	1860(ra) # 800014c4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d88:	4681                	li	a3,0
    80001d8a:	4605                	li	a2,1
    80001d8c:	020005b7          	lui	a1,0x2000
    80001d90:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d92:	05b6                	sll	a1,a1,0xd
    80001d94:	8526                	mv	a0,s1
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	72e080e7          	jalr	1838(ra) # 800014c4 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d9e:	85ca                	mv	a1,s2
    80001da0:	8526                	mv	a0,s1
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	9ec080e7          	jalr	-1556(ra) # 8000178e <uvmfree>
}
    80001daa:	60e2                	ld	ra,24(sp)
    80001dac:	6442                	ld	s0,16(sp)
    80001dae:	64a2                	ld	s1,8(sp)
    80001db0:	6902                	ld	s2,0(sp)
    80001db2:	6105                	add	sp,sp,32
    80001db4:	8082                	ret

0000000080001db6 <freeproc>:
{
    80001db6:	1101                	add	sp,sp,-32
    80001db8:	ec06                	sd	ra,24(sp)
    80001dba:	e822                	sd	s0,16(sp)
    80001dbc:	e426                	sd	s1,8(sp)
    80001dbe:	1000                	add	s0,sp,32
    80001dc0:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001dc2:	6d28                	ld	a0,88(a0)
    80001dc4:	c509                	beqz	a0,80001dce <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	c1e080e7          	jalr	-994(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001dce:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001dd2:	68a8                	ld	a0,80(s1)
    80001dd4:	c511                	beqz	a0,80001de0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001dd6:	64ac                	ld	a1,72(s1)
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	f8c080e7          	jalr	-116(ra) # 80001d64 <proc_freepagetable>
  p->pagetable = 0;
    80001de0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001de4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001de8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001dec:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001df0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001df4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001df8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001dfc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e00:	0004ac23          	sw	zero,24(s1)
}
    80001e04:	60e2                	ld	ra,24(sp)
    80001e06:	6442                	ld	s0,16(sp)
    80001e08:	64a2                	ld	s1,8(sp)
    80001e0a:	6105                	add	sp,sp,32
    80001e0c:	8082                	ret

0000000080001e0e <allocproc>:
{
    80001e0e:	1101                	add	sp,sp,-32
    80001e10:	ec06                	sd	ra,24(sp)
    80001e12:	e822                	sd	s0,16(sp)
    80001e14:	e426                	sd	s1,8(sp)
    80001e16:	e04a                	sd	s2,0(sp)
    80001e18:	1000                	add	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001e1a:	0002f497          	auipc	s1,0x2f
    80001e1e:	19e48493          	add	s1,s1,414 # 80030fb8 <proc>
    80001e22:	00035917          	auipc	s2,0x35
    80001e26:	59690913          	add	s2,s2,1430 # 800373b8 <tickslock>
    acquire(&p->lock);
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	00c080e7          	jalr	12(ra) # 80000e38 <acquire>
    if (p->state == UNUSED)
    80001e34:	4c9c                	lw	a5,24(s1)
    80001e36:	cf81                	beqz	a5,80001e4e <allocproc+0x40>
      release(&p->lock);
    80001e38:	8526                	mv	a0,s1
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	0b2080e7          	jalr	178(ra) # 80000eec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001e42:	19048493          	add	s1,s1,400
    80001e46:	ff2492e3          	bne	s1,s2,80001e2a <allocproc+0x1c>
  return 0;
    80001e4a:	4481                	li	s1,0
    80001e4c:	a059                	j	80001ed2 <allocproc+0xc4>
  p->pid = allocpid();
    80001e4e:	00000097          	auipc	ra,0x0
    80001e52:	e34080e7          	jalr	-460(ra) # 80001c82 <allocpid>
    80001e56:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e58:	4785                	li	a5,1
    80001e5a:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	cfc080e7          	jalr	-772(ra) # 80000b58 <kalloc>
    80001e64:	892a                	mv	s2,a0
    80001e66:	eca8                	sd	a0,88(s1)
    80001e68:	cd25                	beqz	a0,80001ee0 <allocproc+0xd2>
  p->pagetable = proc_pagetable(p);
    80001e6a:	8526                	mv	a0,s1
    80001e6c:	00000097          	auipc	ra,0x0
    80001e70:	e5c080e7          	jalr	-420(ra) # 80001cc8 <proc_pagetable>
    80001e74:	892a                	mv	s2,a0
    80001e76:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001e78:	c141                	beqz	a0,80001ef8 <allocproc+0xea>
  memset(&p->context, 0, sizeof(p->context));
    80001e7a:	07000613          	li	a2,112
    80001e7e:	4581                	li	a1,0
    80001e80:	06048513          	add	a0,s1,96
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	0b0080e7          	jalr	176(ra) # 80000f34 <memset>
  p->context.ra = (uint64)forkret;
    80001e8c:	00000797          	auipc	a5,0x0
    80001e90:	db078793          	add	a5,a5,-592 # 80001c3c <forkret>
    80001e94:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e96:	60bc                	ld	a5,64(s1)
    80001e98:	6705                	lui	a4,0x1
    80001e9a:	97ba                	add	a5,a5,a4
    80001e9c:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e9e:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001ea2:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001ea6:	00007797          	auipc	a5,0x7
    80001eaa:	a5a7a783          	lw	a5,-1446(a5) # 80008900 <ticks>
    80001eae:	16f4a623          	sw	a5,364(s1)
  p->sched = 0 ;
    80001eb2:	1604aa23          	sw	zero,372(s1)
  p->time_sleep = 0 ;
    80001eb6:	1604ac23          	sw	zero,376(s1)
  p->time_run = 0;
    80001eba:	1604ae23          	sw	zero,380(s1)
  p->D = 0;
    80001ebe:	1804a023          	sw	zero,384(s1)
  p->S = 60;
    80001ec2:	03c00793          	li	a5,60
    80001ec6:	18f4a223          	sw	a5,388(s1)
  p->time_start=0;
    80001eca:	1804a423          	sw	zero,392(s1)
  p->time_wait=0;
    80001ece:	1804a623          	sw	zero,396(s1)
}
    80001ed2:	8526                	mv	a0,s1
    80001ed4:	60e2                	ld	ra,24(sp)
    80001ed6:	6442                	ld	s0,16(sp)
    80001ed8:	64a2                	ld	s1,8(sp)
    80001eda:	6902                	ld	s2,0(sp)
    80001edc:	6105                	add	sp,sp,32
    80001ede:	8082                	ret
    freeproc(p);
    80001ee0:	8526                	mv	a0,s1
    80001ee2:	00000097          	auipc	ra,0x0
    80001ee6:	ed4080e7          	jalr	-300(ra) # 80001db6 <freeproc>
    release(&p->lock);
    80001eea:	8526                	mv	a0,s1
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	000080e7          	jalr	ra # 80000eec <release>
    return 0;
    80001ef4:	84ca                	mv	s1,s2
    80001ef6:	bff1                	j	80001ed2 <allocproc+0xc4>
    freeproc(p);
    80001ef8:	8526                	mv	a0,s1
    80001efa:	00000097          	auipc	ra,0x0
    80001efe:	ebc080e7          	jalr	-324(ra) # 80001db6 <freeproc>
    release(&p->lock);
    80001f02:	8526                	mv	a0,s1
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	fe8080e7          	jalr	-24(ra) # 80000eec <release>
    return 0;
    80001f0c:	84ca                	mv	s1,s2
    80001f0e:	b7d1                	j	80001ed2 <allocproc+0xc4>

0000000080001f10 <userinit>:
{
    80001f10:	1101                	add	sp,sp,-32
    80001f12:	ec06                	sd	ra,24(sp)
    80001f14:	e822                	sd	s0,16(sp)
    80001f16:	e426                	sd	s1,8(sp)
    80001f18:	1000                	add	s0,sp,32
  p = allocproc();
    80001f1a:	00000097          	auipc	ra,0x0
    80001f1e:	ef4080e7          	jalr	-268(ra) # 80001e0e <allocproc>
    80001f22:	84aa                	mv	s1,a0
  initproc = p;
    80001f24:	00007797          	auipc	a5,0x7
    80001f28:	9ca7ba23          	sd	a0,-1580(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f2c:	03400613          	li	a2,52
    80001f30:	00007597          	auipc	a1,0x7
    80001f34:	96058593          	add	a1,a1,-1696 # 80008890 <initcode>
    80001f38:	6928                	ld	a0,80(a0)
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	67c080e7          	jalr	1660(ra) # 800015b6 <uvmfirst>
  p->sz = PGSIZE;
    80001f42:	6785                	lui	a5,0x1
    80001f44:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001f46:	6cb8                	ld	a4,88(s1)
    80001f48:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001f4c:	6cb8                	ld	a4,88(s1)
    80001f4e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f50:	4641                	li	a2,16
    80001f52:	00006597          	auipc	a1,0x6
    80001f56:	2ce58593          	add	a1,a1,718 # 80008220 <digits+0x1e0>
    80001f5a:	15848513          	add	a0,s1,344
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	11e080e7          	jalr	286(ra) # 8000107c <safestrcpy>
  p->cwd = namei("/");
    80001f66:	00006517          	auipc	a0,0x6
    80001f6a:	2ca50513          	add	a0,a0,714 # 80008230 <digits+0x1f0>
    80001f6e:	00002097          	auipc	ra,0x2
    80001f72:	558080e7          	jalr	1368(ra) # 800044c6 <namei>
    80001f76:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f7a:	478d                	li	a5,3
    80001f7c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f7e:	8526                	mv	a0,s1
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	f6c080e7          	jalr	-148(ra) # 80000eec <release>
}
    80001f88:	60e2                	ld	ra,24(sp)
    80001f8a:	6442                	ld	s0,16(sp)
    80001f8c:	64a2                	ld	s1,8(sp)
    80001f8e:	6105                	add	sp,sp,32
    80001f90:	8082                	ret

0000000080001f92 <growproc>:
{
    80001f92:	1101                	add	sp,sp,-32
    80001f94:	ec06                	sd	ra,24(sp)
    80001f96:	e822                	sd	s0,16(sp)
    80001f98:	e426                	sd	s1,8(sp)
    80001f9a:	e04a                	sd	s2,0(sp)
    80001f9c:	1000                	add	s0,sp,32
    80001f9e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	c64080e7          	jalr	-924(ra) # 80001c04 <myproc>
    80001fa8:	84aa                	mv	s1,a0
  sz = p->sz;
    80001faa:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001fac:	01204c63          	bgtz	s2,80001fc4 <growproc+0x32>
  else if (n < 0)
    80001fb0:	02094663          	bltz	s2,80001fdc <growproc+0x4a>
  p->sz = sz;
    80001fb4:	e4ac                	sd	a1,72(s1)
  return 0;
    80001fb6:	4501                	li	a0,0
}
    80001fb8:	60e2                	ld	ra,24(sp)
    80001fba:	6442                	ld	s0,16(sp)
    80001fbc:	64a2                	ld	s1,8(sp)
    80001fbe:	6902                	ld	s2,0(sp)
    80001fc0:	6105                	add	sp,sp,32
    80001fc2:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001fc4:	4691                	li	a3,4
    80001fc6:	00b90633          	add	a2,s2,a1
    80001fca:	6928                	ld	a0,80(a0)
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	6a4080e7          	jalr	1700(ra) # 80001670 <uvmalloc>
    80001fd4:	85aa                	mv	a1,a0
    80001fd6:	fd79                	bnez	a0,80001fb4 <growproc+0x22>
      return -1;
    80001fd8:	557d                	li	a0,-1
    80001fda:	bff9                	j	80001fb8 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fdc:	00b90633          	add	a2,s2,a1
    80001fe0:	6928                	ld	a0,80(a0)
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	646080e7          	jalr	1606(ra) # 80001628 <uvmdealloc>
    80001fea:	85aa                	mv	a1,a0
    80001fec:	b7e1                	j	80001fb4 <growproc+0x22>

0000000080001fee <fork>:
{
    80001fee:	7139                	add	sp,sp,-64
    80001ff0:	fc06                	sd	ra,56(sp)
    80001ff2:	f822                	sd	s0,48(sp)
    80001ff4:	f426                	sd	s1,40(sp)
    80001ff6:	f04a                	sd	s2,32(sp)
    80001ff8:	ec4e                	sd	s3,24(sp)
    80001ffa:	e852                	sd	s4,16(sp)
    80001ffc:	e456                	sd	s5,8(sp)
    80001ffe:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80002000:	00000097          	auipc	ra,0x0
    80002004:	c04080e7          	jalr	-1020(ra) # 80001c04 <myproc>
    80002008:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    8000200a:	00000097          	auipc	ra,0x0
    8000200e:	e04080e7          	jalr	-508(ra) # 80001e0e <allocproc>
    80002012:	10050c63          	beqz	a0,8000212a <fork+0x13c>
    80002016:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002018:	048ab603          	ld	a2,72(s5)
    8000201c:	692c                	ld	a1,80(a0)
    8000201e:	050ab503          	ld	a0,80(s5)
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	7a6080e7          	jalr	1958(ra) # 800017c8 <uvmcopy>
    8000202a:	04054863          	bltz	a0,8000207a <fork+0x8c>
  np->sz = p->sz;
    8000202e:	048ab783          	ld	a5,72(s5)
    80002032:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80002036:	058ab683          	ld	a3,88(s5)
    8000203a:	87b6                	mv	a5,a3
    8000203c:	058a3703          	ld	a4,88(s4)
    80002040:	12068693          	add	a3,a3,288
    80002044:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002048:	6788                	ld	a0,8(a5)
    8000204a:	6b8c                	ld	a1,16(a5)
    8000204c:	6f90                	ld	a2,24(a5)
    8000204e:	01073023          	sd	a6,0(a4)
    80002052:	e708                	sd	a0,8(a4)
    80002054:	eb0c                	sd	a1,16(a4)
    80002056:	ef10                	sd	a2,24(a4)
    80002058:	02078793          	add	a5,a5,32
    8000205c:	02070713          	add	a4,a4,32
    80002060:	fed792e3          	bne	a5,a3,80002044 <fork+0x56>
  np->trapframe->a0 = 0;
    80002064:	058a3783          	ld	a5,88(s4)
    80002068:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    8000206c:	0d0a8493          	add	s1,s5,208
    80002070:	0d0a0913          	add	s2,s4,208
    80002074:	150a8993          	add	s3,s5,336
    80002078:	a00d                	j	8000209a <fork+0xac>
    freeproc(np);
    8000207a:	8552                	mv	a0,s4
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	d3a080e7          	jalr	-710(ra) # 80001db6 <freeproc>
    release(&np->lock);
    80002084:	8552                	mv	a0,s4
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	e66080e7          	jalr	-410(ra) # 80000eec <release>
    return -1;
    8000208e:	597d                	li	s2,-1
    80002090:	a059                	j	80002116 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80002092:	04a1                	add	s1,s1,8
    80002094:	0921                	add	s2,s2,8
    80002096:	01348b63          	beq	s1,s3,800020ac <fork+0xbe>
    if (p->ofile[i])
    8000209a:	6088                	ld	a0,0(s1)
    8000209c:	d97d                	beqz	a0,80002092 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    8000209e:	00003097          	auipc	ra,0x3
    800020a2:	a9a080e7          	jalr	-1382(ra) # 80004b38 <filedup>
    800020a6:	00a93023          	sd	a0,0(s2)
    800020aa:	b7e5                	j	80002092 <fork+0xa4>
  np->cwd = idup(p->cwd);
    800020ac:	150ab503          	ld	a0,336(s5)
    800020b0:	00002097          	auipc	ra,0x2
    800020b4:	c32080e7          	jalr	-974(ra) # 80003ce2 <idup>
    800020b8:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020bc:	4641                	li	a2,16
    800020be:	158a8593          	add	a1,s5,344
    800020c2:	158a0513          	add	a0,s4,344
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	fb6080e7          	jalr	-74(ra) # 8000107c <safestrcpy>
  pid = np->pid;
    800020ce:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    800020d2:	8552                	mv	a0,s4
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	e18080e7          	jalr	-488(ra) # 80000eec <release>
  acquire(&wait_lock);
    800020dc:	0002f497          	auipc	s1,0x2f
    800020e0:	ac448493          	add	s1,s1,-1340 # 80030ba0 <wait_lock>
    800020e4:	8526                	mv	a0,s1
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	d52080e7          	jalr	-686(ra) # 80000e38 <acquire>
  np->parent = p;
    800020ee:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    800020f2:	8526                	mv	a0,s1
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	df8080e7          	jalr	-520(ra) # 80000eec <release>
  acquire(&np->lock);
    800020fc:	8552                	mv	a0,s4
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	d3a080e7          	jalr	-710(ra) # 80000e38 <acquire>
  np->state = RUNNABLE;
    80002106:	478d                	li	a5,3
    80002108:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    8000210c:	8552                	mv	a0,s4
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	dde080e7          	jalr	-546(ra) # 80000eec <release>
}
    80002116:	854a                	mv	a0,s2
    80002118:	70e2                	ld	ra,56(sp)
    8000211a:	7442                	ld	s0,48(sp)
    8000211c:	74a2                	ld	s1,40(sp)
    8000211e:	7902                	ld	s2,32(sp)
    80002120:	69e2                	ld	s3,24(sp)
    80002122:	6a42                	ld	s4,16(sp)
    80002124:	6aa2                	ld	s5,8(sp)
    80002126:	6121                	add	sp,sp,64
    80002128:	8082                	ret
    return -1;
    8000212a:	597d                	li	s2,-1
    8000212c:	b7ed                	j	80002116 <fork+0x128>

000000008000212e <scheduler>:
{
    8000212e:	711d                	add	sp,sp,-96
    80002130:	ec86                	sd	ra,88(sp)
    80002132:	e8a2                	sd	s0,80(sp)
    80002134:	e4a6                	sd	s1,72(sp)
    80002136:	e0ca                	sd	s2,64(sp)
    80002138:	fc4e                	sd	s3,56(sp)
    8000213a:	f852                	sd	s4,48(sp)
    8000213c:	f456                	sd	s5,40(sp)
    8000213e:	f05a                	sd	s6,32(sp)
    80002140:	ec5e                	sd	s7,24(sp)
    80002142:	e862                	sd	s8,16(sp)
    80002144:	e466                	sd	s9,8(sp)
    80002146:	1080                	add	s0,sp,96
    80002148:	8792                	mv	a5,tp
  int id = r_tp();
    8000214a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000214c:	00779693          	sll	a3,a5,0x7
    80002150:	0002f717          	auipc	a4,0x2f
    80002154:	a3870713          	add	a4,a4,-1480 # 80030b88 <pid_lock>
    80002158:	9736                	add	a4,a4,a3
    8000215a:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &highpriority->context);
    8000215e:	0002f717          	auipc	a4,0x2f
    80002162:	a6270713          	add	a4,a4,-1438 # 80030bc0 <cpus+0x8>
    80002166:	00e68cb3          	add	s9,a3,a4
    struct proc* highpriority = 0;
    8000216a:	4b81                	li	s7,0
    p->D = (p->S + niceness) > 100 ? 100 : (p->S + niceness);
    8000216c:	06400a93          	li	s5,100
    80002170:	06400b13          	li	s6,100
  for(p = proc; p < &proc[NPROC]; p++) {
    80002174:	00035997          	auipc	s3,0x35
    80002178:	24498993          	add	s3,s3,580 # 800373b8 <tickslock>
          c->proc = highpriority;
    8000217c:	0002fc17          	auipc	s8,0x2f
    80002180:	a0cc0c13          	add	s8,s8,-1524 # 80030b88 <pid_lock>
    80002184:	9c36                	add	s8,s8,a3
    80002186:	aa2d                	j	800022c0 <scheduler+0x192>
      release(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	d62080e7          	jalr	-670(ra) # 80000eec <release>
      continue;
    80002192:	a809                	j	800021a4 <scheduler+0x76>
    80002194:	8926                	mv	s2,s1
    80002196:	a011                	j	8000219a <scheduler+0x6c>
    80002198:	8926                	mv	s2,s1
release(&p->lock);
    8000219a:	8526                	mv	a0,s1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	d50080e7          	jalr	-688(ra) # 80000eec <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021a4:	19048493          	add	s1,s1,400
    800021a8:	09348c63          	beq	s1,s3,80002240 <scheduler+0x112>
        acquire(&p->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	c8a080e7          	jalr	-886(ra) # 80000e38 <acquire>
    niceness = (3 * p->time_run - p->time_sleep - p->time_wait) / ( p->time_run+ p->time_wait +p->time_sleep ) + 50;
    800021b6:	17c4a703          	lw	a4,380(s1)
    800021ba:	1784a683          	lw	a3,376(s1)
    800021be:	18c4a603          	lw	a2,396(s1)
    if(p->state!=RUNNABLE)
    800021c2:	4c9c                	lw	a5,24(s1)
    800021c4:	fd4792e3          	bne	a5,s4,80002188 <scheduler+0x5a>
    niceness = (3 * p->time_run - p->time_sleep - p->time_wait) / ( p->time_run+ p->time_wait +p->time_sleep ) + 50;
    800021c8:	0017179b          	sllw	a5,a4,0x1
    800021cc:	9fb9                	addw	a5,a5,a4
    800021ce:	9f95                	subw	a5,a5,a3
    800021d0:	9f91                	subw	a5,a5,a2
    800021d2:	9f31                	addw	a4,a4,a2
    800021d4:	9f35                	addw	a4,a4,a3
    800021d6:	02e7c7bb          	divw	a5,a5,a4
    800021da:	0327879b          	addw	a5,a5,50
    niceness = (niceness < 0) ? 0 : niceness;
    800021de:	0007871b          	sext.w	a4,a5
    800021e2:	fff74713          	not	a4,a4
    800021e6:	977d                	sra	a4,a4,0x3f
    800021e8:	8ff9                	and	a5,a5,a4
    p->D = (p->S + niceness) > 100 ? 100 : (p->S + niceness);
    800021ea:	1844a703          	lw	a4,388(s1)
    800021ee:	9fb9                	addw	a5,a5,a4
    800021f0:	0007871b          	sext.w	a4,a5
    800021f4:	00ead363          	bge	s5,a4,800021fa <scheduler+0xcc>
    800021f8:	87da                	mv	a5,s6
    800021fa:	0007871b          	sext.w	a4,a5
    800021fe:	18f4a023          	sw	a5,384(s1)
    p->time_start++;
    80002202:	1884a783          	lw	a5,392(s1)
    80002206:	2789                	addw	a5,a5,2
    80002208:	18f4a423          	sw	a5,392(s1)
    if (highpriority == 0) {
    8000220c:	f80904e3          	beqz	s2,80002194 <scheduler+0x66>
    else if(p->D < highpriority->D){
    80002210:	18092783          	lw	a5,384(s2)
    80002214:	f8f742e3          	blt	a4,a5,80002198 <scheduler+0x6a>
      else if (p->D == highpriority->D) {
    80002218:	f8f711e3          	bne	a4,a5,8000219a <scheduler+0x6c>
        if (p->sched < highpriority->sched) {
    8000221c:	1744a703          	lw	a4,372(s1)
    80002220:	17492783          	lw	a5,372(s2)
    80002224:	00f74c63          	blt	a4,a5,8000223c <scheduler+0x10e>
        } else if (p->sched == highpriority->sched) {
    80002228:	f6f719e3          	bne	a4,a5,8000219a <scheduler+0x6c>
            if (p->ctime > highpriority->ctime) {
    8000222c:	16c4a703          	lw	a4,364(s1)
    80002230:	16c92783          	lw	a5,364(s2)
    80002234:	f6e7f3e3          	bgeu	a5,a4,8000219a <scheduler+0x6c>
    80002238:	8926                	mv	s2,s1
    8000223a:	b785                	j	8000219a <scheduler+0x6c>
    8000223c:	8926                	mv	s2,s1
    8000223e:	bfb1                	j	8000219a <scheduler+0x6c>
      if(highpriority!=0){
    80002240:	00091e63          	bnez	s2,8000225c <scheduler+0x12e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002244:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002248:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000224c:	10079073          	csrw	sstatus,a5
    struct proc* highpriority = 0;
    80002250:	895e                	mv	s2,s7
  for(p = proc; p < &proc[NPROC]; p++) {
    80002252:	0002f497          	auipc	s1,0x2f
    80002256:	d6648493          	add	s1,s1,-666 # 80030fb8 <proc>
    8000225a:	bf89                	j	800021ac <scheduler+0x7e>
        acquire(&highpriority->lock);
    8000225c:	84ca                	mv	s1,s2
    8000225e:	854a                	mv	a0,s2
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	bd8080e7          	jalr	-1064(ra) # 80000e38 <acquire>
        if(highpriority->state == RUNNABLE){
    80002268:	01892703          	lw	a4,24(s2)
    8000226c:	478d                	li	a5,3
    8000226e:	04f71463          	bne	a4,a5,800022b6 <scheduler+0x188>
          highpriority->state = RUNNING;
    80002272:	4791                	li	a5,4
    80002274:	00f92c23          	sw	a5,24(s2)
          highpriority->time_run=0;
    80002278:	16092e23          	sw	zero,380(s2)
          highpriority->time_sleep=0;
    8000227c:	16092c23          	sw	zero,376(s2)
          c->proc = highpriority;
    80002280:	032c3823          	sd	s2,48(s8)
          if (p->time_start == 0)
    80002284:	00035797          	auipc	a5,0x35
    80002288:	2bc7a783          	lw	a5,700(a5) # 80037540 <bcache+0x170>
    8000228c:	e799                	bnez	a5,8000229a <scheduler+0x16c>
          highpriority->time_start = ticks;
    8000228e:	00006797          	auipc	a5,0x6
    80002292:	6727a783          	lw	a5,1650(a5) # 80008900 <ticks>
    80002296:	18f92423          	sw	a5,392(s2)
          highpriority->sched++;
    8000229a:	17492783          	lw	a5,372(s2)
    8000229e:	2785                	addw	a5,a5,1
    800022a0:	16f92a23          	sw	a5,372(s2)
          swtch(&c->context, &highpriority->context);
    800022a4:	06090593          	add	a1,s2,96
    800022a8:	8566                	mv	a0,s9
    800022aa:	00001097          	auipc	ra,0x1
    800022ae:	87a080e7          	jalr	-1926(ra) # 80002b24 <swtch>
          c->proc = 0;
    800022b2:	020c3823          	sd	zero,48(s8)
        release(&highpriority->lock);
    800022b6:	8526                	mv	a0,s1
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	c34080e7          	jalr	-972(ra) # 80000eec <release>
    if(p->state!=RUNNABLE)
    800022c0:	4a0d                	li	s4,3
    800022c2:	b749                	j	80002244 <scheduler+0x116>

00000000800022c4 <sched>:
{
    800022c4:	7179                	add	sp,sp,-48
    800022c6:	f406                	sd	ra,40(sp)
    800022c8:	f022                	sd	s0,32(sp)
    800022ca:	ec26                	sd	s1,24(sp)
    800022cc:	e84a                	sd	s2,16(sp)
    800022ce:	e44e                	sd	s3,8(sp)
    800022d0:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    800022d2:	00000097          	auipc	ra,0x0
    800022d6:	932080e7          	jalr	-1742(ra) # 80001c04 <myproc>
    800022da:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	ae2080e7          	jalr	-1310(ra) # 80000dbe <holding>
    800022e4:	c93d                	beqz	a0,8000235a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022e6:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800022e8:	2781                	sext.w	a5,a5
    800022ea:	079e                	sll	a5,a5,0x7
    800022ec:	0002f717          	auipc	a4,0x2f
    800022f0:	89c70713          	add	a4,a4,-1892 # 80030b88 <pid_lock>
    800022f4:	97ba                	add	a5,a5,a4
    800022f6:	0a87a703          	lw	a4,168(a5)
    800022fa:	4785                	li	a5,1
    800022fc:	06f71763          	bne	a4,a5,8000236a <sched+0xa6>
  if (p->state == RUNNING)
    80002300:	4c98                	lw	a4,24(s1)
    80002302:	4791                	li	a5,4
    80002304:	06f70b63          	beq	a4,a5,8000237a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002308:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000230c:	8b89                	and	a5,a5,2
  if (intr_get())
    8000230e:	efb5                	bnez	a5,8000238a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002310:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002312:	0002f917          	auipc	s2,0x2f
    80002316:	87690913          	add	s2,s2,-1930 # 80030b88 <pid_lock>
    8000231a:	2781                	sext.w	a5,a5
    8000231c:	079e                	sll	a5,a5,0x7
    8000231e:	97ca                	add	a5,a5,s2
    80002320:	0ac7a983          	lw	s3,172(a5)
    80002324:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002326:	2781                	sext.w	a5,a5
    80002328:	079e                	sll	a5,a5,0x7
    8000232a:	0002f597          	auipc	a1,0x2f
    8000232e:	89658593          	add	a1,a1,-1898 # 80030bc0 <cpus+0x8>
    80002332:	95be                	add	a1,a1,a5
    80002334:	06048513          	add	a0,s1,96
    80002338:	00000097          	auipc	ra,0x0
    8000233c:	7ec080e7          	jalr	2028(ra) # 80002b24 <swtch>
    80002340:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002342:	2781                	sext.w	a5,a5
    80002344:	079e                	sll	a5,a5,0x7
    80002346:	993e                	add	s2,s2,a5
    80002348:	0b392623          	sw	s3,172(s2)
}
    8000234c:	70a2                	ld	ra,40(sp)
    8000234e:	7402                	ld	s0,32(sp)
    80002350:	64e2                	ld	s1,24(sp)
    80002352:	6942                	ld	s2,16(sp)
    80002354:	69a2                	ld	s3,8(sp)
    80002356:	6145                	add	sp,sp,48
    80002358:	8082                	ret
    panic("sched p->lock");
    8000235a:	00006517          	auipc	a0,0x6
    8000235e:	ede50513          	add	a0,a0,-290 # 80008238 <digits+0x1f8>
    80002362:	ffffe097          	auipc	ra,0xffffe
    80002366:	1da080e7          	jalr	474(ra) # 8000053c <panic>
    panic("sched locks");
    8000236a:	00006517          	auipc	a0,0x6
    8000236e:	ede50513          	add	a0,a0,-290 # 80008248 <digits+0x208>
    80002372:	ffffe097          	auipc	ra,0xffffe
    80002376:	1ca080e7          	jalr	458(ra) # 8000053c <panic>
    panic("sched running");
    8000237a:	00006517          	auipc	a0,0x6
    8000237e:	ede50513          	add	a0,a0,-290 # 80008258 <digits+0x218>
    80002382:	ffffe097          	auipc	ra,0xffffe
    80002386:	1ba080e7          	jalr	442(ra) # 8000053c <panic>
    panic("sched interruptible");
    8000238a:	00006517          	auipc	a0,0x6
    8000238e:	ede50513          	add	a0,a0,-290 # 80008268 <digits+0x228>
    80002392:	ffffe097          	auipc	ra,0xffffe
    80002396:	1aa080e7          	jalr	426(ra) # 8000053c <panic>

000000008000239a <yield>:
{
    8000239a:	1101                	add	sp,sp,-32
    8000239c:	ec06                	sd	ra,24(sp)
    8000239e:	e822                	sd	s0,16(sp)
    800023a0:	e426                	sd	s1,8(sp)
    800023a2:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800023a4:	00000097          	auipc	ra,0x0
    800023a8:	860080e7          	jalr	-1952(ra) # 80001c04 <myproc>
    800023ac:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	a8a080e7          	jalr	-1398(ra) # 80000e38 <acquire>
  p->state = RUNNABLE;
    800023b6:	478d                	li	a5,3
    800023b8:	cc9c                	sw	a5,24(s1)
  sched();
    800023ba:	00000097          	auipc	ra,0x0
    800023be:	f0a080e7          	jalr	-246(ra) # 800022c4 <sched>
  release(&p->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	b28080e7          	jalr	-1240(ra) # 80000eec <release>
}
    800023cc:	60e2                	ld	ra,24(sp)
    800023ce:	6442                	ld	s0,16(sp)
    800023d0:	64a2                	ld	s1,8(sp)
    800023d2:	6105                	add	sp,sp,32
    800023d4:	8082                	ret

00000000800023d6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023d6:	7179                	add	sp,sp,-48
    800023d8:	f406                	sd	ra,40(sp)
    800023da:	f022                	sd	s0,32(sp)
    800023dc:	ec26                	sd	s1,24(sp)
    800023de:	e84a                	sd	s2,16(sp)
    800023e0:	e44e                	sd	s3,8(sp)
    800023e2:	1800                	add	s0,sp,48
    800023e4:	89aa                	mv	s3,a0
    800023e6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023e8:	00000097          	auipc	ra,0x0
    800023ec:	81c080e7          	jalr	-2020(ra) # 80001c04 <myproc>
    800023f0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	a46080e7          	jalr	-1466(ra) # 80000e38 <acquire>
  release(lk);
    800023fa:	854a                	mv	a0,s2
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	af0080e7          	jalr	-1296(ra) # 80000eec <release>

  // Go to sleep.
  p->chan = chan;
    80002404:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002408:	4789                	li	a5,2
    8000240a:	cc9c                	sw	a5,24(s1)

  sched();
    8000240c:	00000097          	auipc	ra,0x0
    80002410:	eb8080e7          	jalr	-328(ra) # 800022c4 <sched>

  // Tidy up.
  p->chan = 0;
    80002414:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	ad2080e7          	jalr	-1326(ra) # 80000eec <release>
  acquire(lk);
    80002422:	854a                	mv	a0,s2
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	a14080e7          	jalr	-1516(ra) # 80000e38 <acquire>
}
    8000242c:	70a2                	ld	ra,40(sp)
    8000242e:	7402                	ld	s0,32(sp)
    80002430:	64e2                	ld	s1,24(sp)
    80002432:	6942                	ld	s2,16(sp)
    80002434:	69a2                	ld	s3,8(sp)
    80002436:	6145                	add	sp,sp,48
    80002438:	8082                	ret

000000008000243a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000243a:	7139                	add	sp,sp,-64
    8000243c:	fc06                	sd	ra,56(sp)
    8000243e:	f822                	sd	s0,48(sp)
    80002440:	f426                	sd	s1,40(sp)
    80002442:	f04a                	sd	s2,32(sp)
    80002444:	ec4e                	sd	s3,24(sp)
    80002446:	e852                	sd	s4,16(sp)
    80002448:	e456                	sd	s5,8(sp)
    8000244a:	0080                	add	s0,sp,64
    8000244c:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000244e:	0002f497          	auipc	s1,0x2f
    80002452:	b6a48493          	add	s1,s1,-1174 # 80030fb8 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002456:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002458:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000245a:	00035917          	auipc	s2,0x35
    8000245e:	f5e90913          	add	s2,s2,-162 # 800373b8 <tickslock>
    80002462:	a811                	j	80002476 <wakeup+0x3c>
      }
      release(&p->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	a86080e7          	jalr	-1402(ra) # 80000eec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000246e:	19048493          	add	s1,s1,400
    80002472:	03248663          	beq	s1,s2,8000249e <wakeup+0x64>
    if (p != myproc())
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	78e080e7          	jalr	1934(ra) # 80001c04 <myproc>
    8000247e:	fea488e3          	beq	s1,a0,8000246e <wakeup+0x34>
      acquire(&p->lock);
    80002482:	8526                	mv	a0,s1
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	9b4080e7          	jalr	-1612(ra) # 80000e38 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000248c:	4c9c                	lw	a5,24(s1)
    8000248e:	fd379be3          	bne	a5,s3,80002464 <wakeup+0x2a>
    80002492:	709c                	ld	a5,32(s1)
    80002494:	fd4798e3          	bne	a5,s4,80002464 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002498:	0154ac23          	sw	s5,24(s1)
    8000249c:	b7e1                	j	80002464 <wakeup+0x2a>
    }
  }
}
    8000249e:	70e2                	ld	ra,56(sp)
    800024a0:	7442                	ld	s0,48(sp)
    800024a2:	74a2                	ld	s1,40(sp)
    800024a4:	7902                	ld	s2,32(sp)
    800024a6:	69e2                	ld	s3,24(sp)
    800024a8:	6a42                	ld	s4,16(sp)
    800024aa:	6aa2                	ld	s5,8(sp)
    800024ac:	6121                	add	sp,sp,64
    800024ae:	8082                	ret

00000000800024b0 <reparent>:
{
    800024b0:	7179                	add	sp,sp,-48
    800024b2:	f406                	sd	ra,40(sp)
    800024b4:	f022                	sd	s0,32(sp)
    800024b6:	ec26                	sd	s1,24(sp)
    800024b8:	e84a                	sd	s2,16(sp)
    800024ba:	e44e                	sd	s3,8(sp)
    800024bc:	e052                	sd	s4,0(sp)
    800024be:	1800                	add	s0,sp,48
    800024c0:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024c2:	0002f497          	auipc	s1,0x2f
    800024c6:	af648493          	add	s1,s1,-1290 # 80030fb8 <proc>
      pp->parent = initproc;
    800024ca:	00006a17          	auipc	s4,0x6
    800024ce:	42ea0a13          	add	s4,s4,1070 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024d2:	00035997          	auipc	s3,0x35
    800024d6:	ee698993          	add	s3,s3,-282 # 800373b8 <tickslock>
    800024da:	a029                	j	800024e4 <reparent+0x34>
    800024dc:	19048493          	add	s1,s1,400
    800024e0:	01348d63          	beq	s1,s3,800024fa <reparent+0x4a>
    if (pp->parent == p)
    800024e4:	7c9c                	ld	a5,56(s1)
    800024e6:	ff279be3          	bne	a5,s2,800024dc <reparent+0x2c>
      pp->parent = initproc;
    800024ea:	000a3503          	ld	a0,0(s4)
    800024ee:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024f0:	00000097          	auipc	ra,0x0
    800024f4:	f4a080e7          	jalr	-182(ra) # 8000243a <wakeup>
    800024f8:	b7d5                	j	800024dc <reparent+0x2c>
}
    800024fa:	70a2                	ld	ra,40(sp)
    800024fc:	7402                	ld	s0,32(sp)
    800024fe:	64e2                	ld	s1,24(sp)
    80002500:	6942                	ld	s2,16(sp)
    80002502:	69a2                	ld	s3,8(sp)
    80002504:	6a02                	ld	s4,0(sp)
    80002506:	6145                	add	sp,sp,48
    80002508:	8082                	ret

000000008000250a <exit>:
{
    8000250a:	7179                	add	sp,sp,-48
    8000250c:	f406                	sd	ra,40(sp)
    8000250e:	f022                	sd	s0,32(sp)
    80002510:	ec26                	sd	s1,24(sp)
    80002512:	e84a                	sd	s2,16(sp)
    80002514:	e44e                	sd	s3,8(sp)
    80002516:	e052                	sd	s4,0(sp)
    80002518:	1800                	add	s0,sp,48
    8000251a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	6e8080e7          	jalr	1768(ra) # 80001c04 <myproc>
    80002524:	89aa                	mv	s3,a0
  if (p == initproc)
    80002526:	00006797          	auipc	a5,0x6
    8000252a:	3d27b783          	ld	a5,978(a5) # 800088f8 <initproc>
    8000252e:	0d050493          	add	s1,a0,208
    80002532:	15050913          	add	s2,a0,336
    80002536:	02a79363          	bne	a5,a0,8000255c <exit+0x52>
    panic("init exiting");
    8000253a:	00006517          	auipc	a0,0x6
    8000253e:	d4650513          	add	a0,a0,-698 # 80008280 <digits+0x240>
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	ffa080e7          	jalr	-6(ra) # 8000053c <panic>
      fileclose(f);
    8000254a:	00002097          	auipc	ra,0x2
    8000254e:	640080e7          	jalr	1600(ra) # 80004b8a <fileclose>
      p->ofile[fd] = 0;
    80002552:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002556:	04a1                	add	s1,s1,8
    80002558:	01248563          	beq	s1,s2,80002562 <exit+0x58>
    if (p->ofile[fd])
    8000255c:	6088                	ld	a0,0(s1)
    8000255e:	f575                	bnez	a0,8000254a <exit+0x40>
    80002560:	bfdd                	j	80002556 <exit+0x4c>
  begin_op();
    80002562:	00002097          	auipc	ra,0x2
    80002566:	164080e7          	jalr	356(ra) # 800046c6 <begin_op>
  iput(p->cwd);
    8000256a:	1509b503          	ld	a0,336(s3)
    8000256e:	00002097          	auipc	ra,0x2
    80002572:	96c080e7          	jalr	-1684(ra) # 80003eda <iput>
  end_op();
    80002576:	00002097          	auipc	ra,0x2
    8000257a:	1ca080e7          	jalr	458(ra) # 80004740 <end_op>
  p->cwd = 0;
    8000257e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002582:	0002e497          	auipc	s1,0x2e
    80002586:	61e48493          	add	s1,s1,1566 # 80030ba0 <wait_lock>
    8000258a:	8526                	mv	a0,s1
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	8ac080e7          	jalr	-1876(ra) # 80000e38 <acquire>
  reparent(p);
    80002594:	854e                	mv	a0,s3
    80002596:	00000097          	auipc	ra,0x0
    8000259a:	f1a080e7          	jalr	-230(ra) # 800024b0 <reparent>
  wakeup(p->parent);
    8000259e:	0389b503          	ld	a0,56(s3)
    800025a2:	00000097          	auipc	ra,0x0
    800025a6:	e98080e7          	jalr	-360(ra) # 8000243a <wakeup>
  acquire(&p->lock);
    800025aa:	854e                	mv	a0,s3
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	88c080e7          	jalr	-1908(ra) # 80000e38 <acquire>
  p->xstate = status;
    800025b4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800025b8:	4795                	li	a5,5
    800025ba:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800025be:	00006797          	auipc	a5,0x6
    800025c2:	3427a783          	lw	a5,834(a5) # 80008900 <ticks>
    800025c6:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800025ca:	8526                	mv	a0,s1
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	920080e7          	jalr	-1760(ra) # 80000eec <release>
  sched();
    800025d4:	00000097          	auipc	ra,0x0
    800025d8:	cf0080e7          	jalr	-784(ra) # 800022c4 <sched>
  panic("zombie exit");
    800025dc:	00006517          	auipc	a0,0x6
    800025e0:	cb450513          	add	a0,a0,-844 # 80008290 <digits+0x250>
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	f58080e7          	jalr	-168(ra) # 8000053c <panic>

00000000800025ec <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025ec:	7179                	add	sp,sp,-48
    800025ee:	f406                	sd	ra,40(sp)
    800025f0:	f022                	sd	s0,32(sp)
    800025f2:	ec26                	sd	s1,24(sp)
    800025f4:	e84a                	sd	s2,16(sp)
    800025f6:	e44e                	sd	s3,8(sp)
    800025f8:	1800                	add	s0,sp,48
    800025fa:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025fc:	0002f497          	auipc	s1,0x2f
    80002600:	9bc48493          	add	s1,s1,-1604 # 80030fb8 <proc>
    80002604:	00035997          	auipc	s3,0x35
    80002608:	db498993          	add	s3,s3,-588 # 800373b8 <tickslock>
  {
    acquire(&p->lock);
    8000260c:	8526                	mv	a0,s1
    8000260e:	fffff097          	auipc	ra,0xfffff
    80002612:	82a080e7          	jalr	-2006(ra) # 80000e38 <acquire>
    if (p->pid == pid)
    80002616:	589c                	lw	a5,48(s1)
    80002618:	01278d63          	beq	a5,s2,80002632 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000261c:	8526                	mv	a0,s1
    8000261e:	fffff097          	auipc	ra,0xfffff
    80002622:	8ce080e7          	jalr	-1842(ra) # 80000eec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002626:	19048493          	add	s1,s1,400
    8000262a:	ff3491e3          	bne	s1,s3,8000260c <kill+0x20>
  }
  return -1;
    8000262e:	557d                	li	a0,-1
    80002630:	a829                	j	8000264a <kill+0x5e>
      p->killed = 1;
    80002632:	4785                	li	a5,1
    80002634:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002636:	4c98                	lw	a4,24(s1)
    80002638:	4789                	li	a5,2
    8000263a:	00f70f63          	beq	a4,a5,80002658 <kill+0x6c>
      release(&p->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	fffff097          	auipc	ra,0xfffff
    80002644:	8ac080e7          	jalr	-1876(ra) # 80000eec <release>
      return 0;
    80002648:	4501                	li	a0,0
}
    8000264a:	70a2                	ld	ra,40(sp)
    8000264c:	7402                	ld	s0,32(sp)
    8000264e:	64e2                	ld	s1,24(sp)
    80002650:	6942                	ld	s2,16(sp)
    80002652:	69a2                	ld	s3,8(sp)
    80002654:	6145                	add	sp,sp,48
    80002656:	8082                	ret
        p->state = RUNNABLE;
    80002658:	478d                	li	a5,3
    8000265a:	cc9c                	sw	a5,24(s1)
    8000265c:	b7cd                	j	8000263e <kill+0x52>

000000008000265e <setkilled>:

void setkilled(struct proc *p)
{
    8000265e:	1101                	add	sp,sp,-32
    80002660:	ec06                	sd	ra,24(sp)
    80002662:	e822                	sd	s0,16(sp)
    80002664:	e426                	sd	s1,8(sp)
    80002666:	1000                	add	s0,sp,32
    80002668:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	7ce080e7          	jalr	1998(ra) # 80000e38 <acquire>
  p->killed = 1;
    80002672:	4785                	li	a5,1
    80002674:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002676:	8526                	mv	a0,s1
    80002678:	fffff097          	auipc	ra,0xfffff
    8000267c:	874080e7          	jalr	-1932(ra) # 80000eec <release>
}
    80002680:	60e2                	ld	ra,24(sp)
    80002682:	6442                	ld	s0,16(sp)
    80002684:	64a2                	ld	s1,8(sp)
    80002686:	6105                	add	sp,sp,32
    80002688:	8082                	ret

000000008000268a <killed>:

int killed(struct proc *p)
{
    8000268a:	1101                	add	sp,sp,-32
    8000268c:	ec06                	sd	ra,24(sp)
    8000268e:	e822                	sd	s0,16(sp)
    80002690:	e426                	sd	s1,8(sp)
    80002692:	e04a                	sd	s2,0(sp)
    80002694:	1000                	add	s0,sp,32
    80002696:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	7a0080e7          	jalr	1952(ra) # 80000e38 <acquire>
  k = p->killed;
    800026a0:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800026a4:	8526                	mv	a0,s1
    800026a6:	fffff097          	auipc	ra,0xfffff
    800026aa:	846080e7          	jalr	-1978(ra) # 80000eec <release>
  return k;
}
    800026ae:	854a                	mv	a0,s2
    800026b0:	60e2                	ld	ra,24(sp)
    800026b2:	6442                	ld	s0,16(sp)
    800026b4:	64a2                	ld	s1,8(sp)
    800026b6:	6902                	ld	s2,0(sp)
    800026b8:	6105                	add	sp,sp,32
    800026ba:	8082                	ret

00000000800026bc <wait>:
{
    800026bc:	715d                	add	sp,sp,-80
    800026be:	e486                	sd	ra,72(sp)
    800026c0:	e0a2                	sd	s0,64(sp)
    800026c2:	fc26                	sd	s1,56(sp)
    800026c4:	f84a                	sd	s2,48(sp)
    800026c6:	f44e                	sd	s3,40(sp)
    800026c8:	f052                	sd	s4,32(sp)
    800026ca:	ec56                	sd	s5,24(sp)
    800026cc:	e85a                	sd	s6,16(sp)
    800026ce:	e45e                	sd	s7,8(sp)
    800026d0:	e062                	sd	s8,0(sp)
    800026d2:	0880                	add	s0,sp,80
    800026d4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800026d6:	fffff097          	auipc	ra,0xfffff
    800026da:	52e080e7          	jalr	1326(ra) # 80001c04 <myproc>
    800026de:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026e0:	0002e517          	auipc	a0,0x2e
    800026e4:	4c050513          	add	a0,a0,1216 # 80030ba0 <wait_lock>
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	750080e7          	jalr	1872(ra) # 80000e38 <acquire>
    havekids = 0;
    800026f0:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800026f2:	4a15                	li	s4,5
        havekids = 1;
    800026f4:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026f6:	00035997          	auipc	s3,0x35
    800026fa:	cc298993          	add	s3,s3,-830 # 800373b8 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026fe:	0002ec17          	auipc	s8,0x2e
    80002702:	4a2c0c13          	add	s8,s8,1186 # 80030ba0 <wait_lock>
    80002706:	a0d1                	j	800027ca <wait+0x10e>
          pid = pp->pid;
    80002708:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000270c:	000b0e63          	beqz	s6,80002728 <wait+0x6c>
    80002710:	4691                	li	a3,4
    80002712:	02c48613          	add	a2,s1,44
    80002716:	85da                	mv	a1,s6
    80002718:	05093503          	ld	a0,80(s2)
    8000271c:	fffff097          	auipc	ra,0xfffff
    80002720:	19e080e7          	jalr	414(ra) # 800018ba <copyout>
    80002724:	04054163          	bltz	a0,80002766 <wait+0xaa>
          freeproc(pp);
    80002728:	8526                	mv	a0,s1
    8000272a:	fffff097          	auipc	ra,0xfffff
    8000272e:	68c080e7          	jalr	1676(ra) # 80001db6 <freeproc>
          release(&pp->lock);
    80002732:	8526                	mv	a0,s1
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	7b8080e7          	jalr	1976(ra) # 80000eec <release>
          release(&wait_lock);
    8000273c:	0002e517          	auipc	a0,0x2e
    80002740:	46450513          	add	a0,a0,1124 # 80030ba0 <wait_lock>
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	7a8080e7          	jalr	1960(ra) # 80000eec <release>
}
    8000274c:	854e                	mv	a0,s3
    8000274e:	60a6                	ld	ra,72(sp)
    80002750:	6406                	ld	s0,64(sp)
    80002752:	74e2                	ld	s1,56(sp)
    80002754:	7942                	ld	s2,48(sp)
    80002756:	79a2                	ld	s3,40(sp)
    80002758:	7a02                	ld	s4,32(sp)
    8000275a:	6ae2                	ld	s5,24(sp)
    8000275c:	6b42                	ld	s6,16(sp)
    8000275e:	6ba2                	ld	s7,8(sp)
    80002760:	6c02                	ld	s8,0(sp)
    80002762:	6161                	add	sp,sp,80
    80002764:	8082                	ret
            release(&pp->lock);
    80002766:	8526                	mv	a0,s1
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	784080e7          	jalr	1924(ra) # 80000eec <release>
            release(&wait_lock);
    80002770:	0002e517          	auipc	a0,0x2e
    80002774:	43050513          	add	a0,a0,1072 # 80030ba0 <wait_lock>
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	774080e7          	jalr	1908(ra) # 80000eec <release>
            return -1;
    80002780:	59fd                	li	s3,-1
    80002782:	b7e9                	j	8000274c <wait+0x90>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002784:	19048493          	add	s1,s1,400
    80002788:	03348463          	beq	s1,s3,800027b0 <wait+0xf4>
      if (pp->parent == p)
    8000278c:	7c9c                	ld	a5,56(s1)
    8000278e:	ff279be3          	bne	a5,s2,80002784 <wait+0xc8>
        acquire(&pp->lock);
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	6a4080e7          	jalr	1700(ra) # 80000e38 <acquire>
        if (pp->state == ZOMBIE)
    8000279c:	4c9c                	lw	a5,24(s1)
    8000279e:	f74785e3          	beq	a5,s4,80002708 <wait+0x4c>
        release(&pp->lock);
    800027a2:	8526                	mv	a0,s1
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	748080e7          	jalr	1864(ra) # 80000eec <release>
        havekids = 1;
    800027ac:	8756                	mv	a4,s5
    800027ae:	bfd9                	j	80002784 <wait+0xc8>
    if (!havekids || killed(p))
    800027b0:	c31d                	beqz	a4,800027d6 <wait+0x11a>
    800027b2:	854a                	mv	a0,s2
    800027b4:	00000097          	auipc	ra,0x0
    800027b8:	ed6080e7          	jalr	-298(ra) # 8000268a <killed>
    800027bc:	ed09                	bnez	a0,800027d6 <wait+0x11a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027be:	85e2                	mv	a1,s8
    800027c0:	854a                	mv	a0,s2
    800027c2:	00000097          	auipc	ra,0x0
    800027c6:	c14080e7          	jalr	-1004(ra) # 800023d6 <sleep>
    havekids = 0;
    800027ca:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800027cc:	0002e497          	auipc	s1,0x2e
    800027d0:	7ec48493          	add	s1,s1,2028 # 80030fb8 <proc>
    800027d4:	bf65                	j	8000278c <wait+0xd0>
      release(&wait_lock);
    800027d6:	0002e517          	auipc	a0,0x2e
    800027da:	3ca50513          	add	a0,a0,970 # 80030ba0 <wait_lock>
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	70e080e7          	jalr	1806(ra) # 80000eec <release>
      return -1;
    800027e6:	59fd                	li	s3,-1
    800027e8:	b795                	j	8000274c <wait+0x90>

00000000800027ea <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027ea:	7179                	add	sp,sp,-48
    800027ec:	f406                	sd	ra,40(sp)
    800027ee:	f022                	sd	s0,32(sp)
    800027f0:	ec26                	sd	s1,24(sp)
    800027f2:	e84a                	sd	s2,16(sp)
    800027f4:	e44e                	sd	s3,8(sp)
    800027f6:	e052                	sd	s4,0(sp)
    800027f8:	1800                	add	s0,sp,48
    800027fa:	84aa                	mv	s1,a0
    800027fc:	892e                	mv	s2,a1
    800027fe:	89b2                	mv	s3,a2
    80002800:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002802:	fffff097          	auipc	ra,0xfffff
    80002806:	402080e7          	jalr	1026(ra) # 80001c04 <myproc>
  if (user_dst)
    8000280a:	c08d                	beqz	s1,8000282c <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000280c:	86d2                	mv	a3,s4
    8000280e:	864e                	mv	a2,s3
    80002810:	85ca                	mv	a1,s2
    80002812:	6928                	ld	a0,80(a0)
    80002814:	fffff097          	auipc	ra,0xfffff
    80002818:	0a6080e7          	jalr	166(ra) # 800018ba <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000281c:	70a2                	ld	ra,40(sp)
    8000281e:	7402                	ld	s0,32(sp)
    80002820:	64e2                	ld	s1,24(sp)
    80002822:	6942                	ld	s2,16(sp)
    80002824:	69a2                	ld	s3,8(sp)
    80002826:	6a02                	ld	s4,0(sp)
    80002828:	6145                	add	sp,sp,48
    8000282a:	8082                	ret
    memmove((char *)dst, src, len);
    8000282c:	000a061b          	sext.w	a2,s4
    80002830:	85ce                	mv	a1,s3
    80002832:	854a                	mv	a0,s2
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	75c080e7          	jalr	1884(ra) # 80000f90 <memmove>
    return 0;
    8000283c:	8526                	mv	a0,s1
    8000283e:	bff9                	j	8000281c <either_copyout+0x32>

0000000080002840 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002840:	7179                	add	sp,sp,-48
    80002842:	f406                	sd	ra,40(sp)
    80002844:	f022                	sd	s0,32(sp)
    80002846:	ec26                	sd	s1,24(sp)
    80002848:	e84a                	sd	s2,16(sp)
    8000284a:	e44e                	sd	s3,8(sp)
    8000284c:	e052                	sd	s4,0(sp)
    8000284e:	1800                	add	s0,sp,48
    80002850:	892a                	mv	s2,a0
    80002852:	84ae                	mv	s1,a1
    80002854:	89b2                	mv	s3,a2
    80002856:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002858:	fffff097          	auipc	ra,0xfffff
    8000285c:	3ac080e7          	jalr	940(ra) # 80001c04 <myproc>
  if (user_src)
    80002860:	c08d                	beqz	s1,80002882 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002862:	86d2                	mv	a3,s4
    80002864:	864e                	mv	a2,s3
    80002866:	85ca                	mv	a1,s2
    80002868:	6928                	ld	a0,80(a0)
    8000286a:	fffff097          	auipc	ra,0xfffff
    8000286e:	0e6080e7          	jalr	230(ra) # 80001950 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002872:	70a2                	ld	ra,40(sp)
    80002874:	7402                	ld	s0,32(sp)
    80002876:	64e2                	ld	s1,24(sp)
    80002878:	6942                	ld	s2,16(sp)
    8000287a:	69a2                	ld	s3,8(sp)
    8000287c:	6a02                	ld	s4,0(sp)
    8000287e:	6145                	add	sp,sp,48
    80002880:	8082                	ret
    memmove(dst, (char *)src, len);
    80002882:	000a061b          	sext.w	a2,s4
    80002886:	85ce                	mv	a1,s3
    80002888:	854a                	mv	a0,s2
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	706080e7          	jalr	1798(ra) # 80000f90 <memmove>
    return 0;
    80002892:	8526                	mv	a0,s1
    80002894:	bff9                	j	80002872 <either_copyin+0x32>

0000000080002896 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002896:	715d                	add	sp,sp,-80
    80002898:	e486                	sd	ra,72(sp)
    8000289a:	e0a2                	sd	s0,64(sp)
    8000289c:	fc26                	sd	s1,56(sp)
    8000289e:	f84a                	sd	s2,48(sp)
    800028a0:	f44e                	sd	s3,40(sp)
    800028a2:	f052                	sd	s4,32(sp)
    800028a4:	ec56                	sd	s5,24(sp)
    800028a6:	e85a                	sd	s6,16(sp)
    800028a8:	e45e                	sd	s7,8(sp)
    800028aa:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800028ac:	00006517          	auipc	a0,0x6
    800028b0:	83c50513          	add	a0,a0,-1988 # 800080e8 <digits+0xa8>
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	cd2080e7          	jalr	-814(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028bc:	0002f497          	auipc	s1,0x2f
    800028c0:	85448493          	add	s1,s1,-1964 # 80031110 <proc+0x158>
    800028c4:	00035917          	auipc	s2,0x35
    800028c8:	c4c90913          	add	s2,s2,-948 # 80037510 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028cc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028ce:	00006997          	auipc	s3,0x6
    800028d2:	9d298993          	add	s3,s3,-1582 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    800028d6:	00006a97          	auipc	s5,0x6
    800028da:	9d2a8a93          	add	s5,s5,-1582 # 800082a8 <digits+0x268>
    printf("\n");
    800028de:	00006a17          	auipc	s4,0x6
    800028e2:	80aa0a13          	add	s4,s4,-2038 # 800080e8 <digits+0xa8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028e6:	00006b97          	auipc	s7,0x6
    800028ea:	a02b8b93          	add	s7,s7,-1534 # 800082e8 <states.0>
    800028ee:	a00d                	j	80002910 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028f0:	ed86a583          	lw	a1,-296(a3)
    800028f4:	8556                	mv	a0,s5
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	c90080e7          	jalr	-880(ra) # 80000586 <printf>
    printf("\n");
    800028fe:	8552                	mv	a0,s4
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c86080e7          	jalr	-890(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002908:	19048493          	add	s1,s1,400
    8000290c:	03248263          	beq	s1,s2,80002930 <procdump+0x9a>
    if (p->state == UNUSED)
    80002910:	86a6                	mv	a3,s1
    80002912:	ec04a783          	lw	a5,-320(s1)
    80002916:	dbed                	beqz	a5,80002908 <procdump+0x72>
      state = "???";
    80002918:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000291a:	fcfb6be3          	bltu	s6,a5,800028f0 <procdump+0x5a>
    8000291e:	02079713          	sll	a4,a5,0x20
    80002922:	01d75793          	srl	a5,a4,0x1d
    80002926:	97de                	add	a5,a5,s7
    80002928:	6390                	ld	a2,0(a5)
    8000292a:	f279                	bnez	a2,800028f0 <procdump+0x5a>
      state = "???";
    8000292c:	864e                	mv	a2,s3
    8000292e:	b7c9                	j	800028f0 <procdump+0x5a>
  }
}
    80002930:	60a6                	ld	ra,72(sp)
    80002932:	6406                	ld	s0,64(sp)
    80002934:	74e2                	ld	s1,56(sp)
    80002936:	7942                	ld	s2,48(sp)
    80002938:	79a2                	ld	s3,40(sp)
    8000293a:	7a02                	ld	s4,32(sp)
    8000293c:	6ae2                	ld	s5,24(sp)
    8000293e:	6b42                	ld	s6,16(sp)
    80002940:	6ba2                	ld	s7,8(sp)
    80002942:	6161                	add	sp,sp,80
    80002944:	8082                	ret

0000000080002946 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002946:	711d                	add	sp,sp,-96
    80002948:	ec86                	sd	ra,88(sp)
    8000294a:	e8a2                	sd	s0,80(sp)
    8000294c:	e4a6                	sd	s1,72(sp)
    8000294e:	e0ca                	sd	s2,64(sp)
    80002950:	fc4e                	sd	s3,56(sp)
    80002952:	f852                	sd	s4,48(sp)
    80002954:	f456                	sd	s5,40(sp)
    80002956:	f05a                	sd	s6,32(sp)
    80002958:	ec5e                	sd	s7,24(sp)
    8000295a:	e862                	sd	s8,16(sp)
    8000295c:	e466                	sd	s9,8(sp)
    8000295e:	e06a                	sd	s10,0(sp)
    80002960:	1080                	add	s0,sp,96
    80002962:	8b2a                	mv	s6,a0
    80002964:	8bae                	mv	s7,a1
    80002966:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002968:	fffff097          	auipc	ra,0xfffff
    8000296c:	29c080e7          	jalr	668(ra) # 80001c04 <myproc>
    80002970:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002972:	0002e517          	auipc	a0,0x2e
    80002976:	22e50513          	add	a0,a0,558 # 80030ba0 <wait_lock>
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	4be080e7          	jalr	1214(ra) # 80000e38 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002982:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002984:	4a15                	li	s4,5
        havekids = 1;
    80002986:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002988:	00035997          	auipc	s3,0x35
    8000298c:	a3098993          	add	s3,s3,-1488 # 800373b8 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002990:	0002ed17          	auipc	s10,0x2e
    80002994:	210d0d13          	add	s10,s10,528 # 80030ba0 <wait_lock>
    80002998:	a8e9                	j	80002a72 <waitx+0x12c>
          pid = np->pid;
    8000299a:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000299e:	1684a783          	lw	a5,360(s1)
    800029a2:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800029a6:	16c4a703          	lw	a4,364(s1)
    800029aa:	9f3d                	addw	a4,a4,a5
    800029ac:	1704a783          	lw	a5,368(s1)
    800029b0:	9f99                	subw	a5,a5,a4
    800029b2:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800029b6:	000b0e63          	beqz	s6,800029d2 <waitx+0x8c>
    800029ba:	4691                	li	a3,4
    800029bc:	02c48613          	add	a2,s1,44
    800029c0:	85da                	mv	a1,s6
    800029c2:	05093503          	ld	a0,80(s2)
    800029c6:	fffff097          	auipc	ra,0xfffff
    800029ca:	ef4080e7          	jalr	-268(ra) # 800018ba <copyout>
    800029ce:	04054363          	bltz	a0,80002a14 <waitx+0xce>
          freeproc(np);
    800029d2:	8526                	mv	a0,s1
    800029d4:	fffff097          	auipc	ra,0xfffff
    800029d8:	3e2080e7          	jalr	994(ra) # 80001db6 <freeproc>
          release(&np->lock);
    800029dc:	8526                	mv	a0,s1
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	50e080e7          	jalr	1294(ra) # 80000eec <release>
          release(&wait_lock);
    800029e6:	0002e517          	auipc	a0,0x2e
    800029ea:	1ba50513          	add	a0,a0,442 # 80030ba0 <wait_lock>
    800029ee:	ffffe097          	auipc	ra,0xffffe
    800029f2:	4fe080e7          	jalr	1278(ra) # 80000eec <release>
  }
}
    800029f6:	854e                	mv	a0,s3
    800029f8:	60e6                	ld	ra,88(sp)
    800029fa:	6446                	ld	s0,80(sp)
    800029fc:	64a6                	ld	s1,72(sp)
    800029fe:	6906                	ld	s2,64(sp)
    80002a00:	79e2                	ld	s3,56(sp)
    80002a02:	7a42                	ld	s4,48(sp)
    80002a04:	7aa2                	ld	s5,40(sp)
    80002a06:	7b02                	ld	s6,32(sp)
    80002a08:	6be2                	ld	s7,24(sp)
    80002a0a:	6c42                	ld	s8,16(sp)
    80002a0c:	6ca2                	ld	s9,8(sp)
    80002a0e:	6d02                	ld	s10,0(sp)
    80002a10:	6125                	add	sp,sp,96
    80002a12:	8082                	ret
            release(&np->lock);
    80002a14:	8526                	mv	a0,s1
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	4d6080e7          	jalr	1238(ra) # 80000eec <release>
            release(&wait_lock);
    80002a1e:	0002e517          	auipc	a0,0x2e
    80002a22:	18250513          	add	a0,a0,386 # 80030ba0 <wait_lock>
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	4c6080e7          	jalr	1222(ra) # 80000eec <release>
            return -1;
    80002a2e:	59fd                	li	s3,-1
    80002a30:	b7d9                	j	800029f6 <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    80002a32:	19048493          	add	s1,s1,400
    80002a36:	03348463          	beq	s1,s3,80002a5e <waitx+0x118>
      if (np->parent == p)
    80002a3a:	7c9c                	ld	a5,56(s1)
    80002a3c:	ff279be3          	bne	a5,s2,80002a32 <waitx+0xec>
        acquire(&np->lock);
    80002a40:	8526                	mv	a0,s1
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	3f6080e7          	jalr	1014(ra) # 80000e38 <acquire>
        if (np->state == ZOMBIE)
    80002a4a:	4c9c                	lw	a5,24(s1)
    80002a4c:	f54787e3          	beq	a5,s4,8000299a <waitx+0x54>
        release(&np->lock);
    80002a50:	8526                	mv	a0,s1
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	49a080e7          	jalr	1178(ra) # 80000eec <release>
        havekids = 1;
    80002a5a:	8756                	mv	a4,s5
    80002a5c:	bfd9                	j	80002a32 <waitx+0xec>
    if (!havekids || p->killed)
    80002a5e:	c305                	beqz	a4,80002a7e <waitx+0x138>
    80002a60:	02892783          	lw	a5,40(s2)
    80002a64:	ef89                	bnez	a5,80002a7e <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a66:	85ea                	mv	a1,s10
    80002a68:	854a                	mv	a0,s2
    80002a6a:	00000097          	auipc	ra,0x0
    80002a6e:	96c080e7          	jalr	-1684(ra) # 800023d6 <sleep>
    havekids = 0;
    80002a72:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002a74:	0002e497          	auipc	s1,0x2e
    80002a78:	54448493          	add	s1,s1,1348 # 80030fb8 <proc>
    80002a7c:	bf7d                	j	80002a3a <waitx+0xf4>
      release(&wait_lock);
    80002a7e:	0002e517          	auipc	a0,0x2e
    80002a82:	12250513          	add	a0,a0,290 # 80030ba0 <wait_lock>
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	466080e7          	jalr	1126(ra) # 80000eec <release>
      return -1;
    80002a8e:	59fd                	li	s3,-1
    80002a90:	b79d                	j	800029f6 <waitx+0xb0>

0000000080002a92 <update_time>:

void update_time()
{
    80002a92:	7139                	add	sp,sp,-64
    80002a94:	fc06                	sd	ra,56(sp)
    80002a96:	f822                	sd	s0,48(sp)
    80002a98:	f426                	sd	s1,40(sp)
    80002a9a:	f04a                	sd	s2,32(sp)
    80002a9c:	ec4e                	sd	s3,24(sp)
    80002a9e:	e852                	sd	s4,16(sp)
    80002aa0:	e456                	sd	s5,8(sp)
    80002aa2:	0080                	add	s0,sp,64
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002aa4:	0002e497          	auipc	s1,0x2e
    80002aa8:	51448493          	add	s1,s1,1300 # 80030fb8 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002aac:	4991                	li	s3,4
    {
      p->rtime++;
      p->time_run++;
    }
    else if (p->state == RUNNABLE)
    80002aae:	4a0d                	li	s4,3
    {
      p->time_wait++;
    }
    else if(p->state == SLEEPING){
    80002ab0:	4a89                	li	s5,2
  for (p = proc; p < &proc[NPROC]; p++)
    80002ab2:	00035917          	auipc	s2,0x35
    80002ab6:	90690913          	add	s2,s2,-1786 # 800373b8 <tickslock>
    80002aba:	a025                	j	80002ae2 <update_time+0x50>
      p->rtime++;
    80002abc:	1684a783          	lw	a5,360(s1)
    80002ac0:	2785                	addw	a5,a5,1
    80002ac2:	16f4a423          	sw	a5,360(s1)
      p->time_run++;
    80002ac6:	17c4a783          	lw	a5,380(s1)
    80002aca:	2785                	addw	a5,a5,1
    80002acc:	16f4ae23          	sw	a5,380(s1)
      p->time_sleep++;
    }
    release(&p->lock);
    80002ad0:	8526                	mv	a0,s1
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	41a080e7          	jalr	1050(ra) # 80000eec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ada:	19048493          	add	s1,s1,400
    80002ade:	03248a63          	beq	s1,s2,80002b12 <update_time+0x80>
    acquire(&p->lock);
    80002ae2:	8526                	mv	a0,s1
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	354080e7          	jalr	852(ra) # 80000e38 <acquire>
    if (p->state == RUNNING)
    80002aec:	4c9c                	lw	a5,24(s1)
    80002aee:	fd3787e3          	beq	a5,s3,80002abc <update_time+0x2a>
    else if (p->state == RUNNABLE)
    80002af2:	01478a63          	beq	a5,s4,80002b06 <update_time+0x74>
    else if(p->state == SLEEPING){
    80002af6:	fd579de3          	bne	a5,s5,80002ad0 <update_time+0x3e>
      p->time_sleep++;
    80002afa:	1784a783          	lw	a5,376(s1)
    80002afe:	2785                	addw	a5,a5,1
    80002b00:	16f4ac23          	sw	a5,376(s1)
    80002b04:	b7f1                	j	80002ad0 <update_time+0x3e>
      p->time_wait++;
    80002b06:	18c4a783          	lw	a5,396(s1)
    80002b0a:	2785                	addw	a5,a5,1
    80002b0c:	18f4a623          	sw	a5,396(s1)
    80002b10:	b7c1                	j	80002ad0 <update_time+0x3e>
  }
    80002b12:	70e2                	ld	ra,56(sp)
    80002b14:	7442                	ld	s0,48(sp)
    80002b16:	74a2                	ld	s1,40(sp)
    80002b18:	7902                	ld	s2,32(sp)
    80002b1a:	69e2                	ld	s3,24(sp)
    80002b1c:	6a42                	ld	s4,16(sp)
    80002b1e:	6aa2                	ld	s5,8(sp)
    80002b20:	6121                	add	sp,sp,64
    80002b22:	8082                	ret

0000000080002b24 <swtch>:
    80002b24:	00153023          	sd	ra,0(a0)
    80002b28:	00253423          	sd	sp,8(a0)
    80002b2c:	e900                	sd	s0,16(a0)
    80002b2e:	ed04                	sd	s1,24(a0)
    80002b30:	03253023          	sd	s2,32(a0)
    80002b34:	03353423          	sd	s3,40(a0)
    80002b38:	03453823          	sd	s4,48(a0)
    80002b3c:	03553c23          	sd	s5,56(a0)
    80002b40:	05653023          	sd	s6,64(a0)
    80002b44:	05753423          	sd	s7,72(a0)
    80002b48:	05853823          	sd	s8,80(a0)
    80002b4c:	05953c23          	sd	s9,88(a0)
    80002b50:	07a53023          	sd	s10,96(a0)
    80002b54:	07b53423          	sd	s11,104(a0)
    80002b58:	0005b083          	ld	ra,0(a1)
    80002b5c:	0085b103          	ld	sp,8(a1)
    80002b60:	6980                	ld	s0,16(a1)
    80002b62:	6d84                	ld	s1,24(a1)
    80002b64:	0205b903          	ld	s2,32(a1)
    80002b68:	0285b983          	ld	s3,40(a1)
    80002b6c:	0305ba03          	ld	s4,48(a1)
    80002b70:	0385ba83          	ld	s5,56(a1)
    80002b74:	0405bb03          	ld	s6,64(a1)
    80002b78:	0485bb83          	ld	s7,72(a1)
    80002b7c:	0505bc03          	ld	s8,80(a1)
    80002b80:	0585bc83          	ld	s9,88(a1)
    80002b84:	0605bd03          	ld	s10,96(a1)
    80002b88:	0685bd83          	ld	s11,104(a1)
    80002b8c:	8082                	ret

0000000080002b8e <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b8e:	1141                	add	sp,sp,-16
    80002b90:	e406                	sd	ra,8(sp)
    80002b92:	e022                	sd	s0,0(sp)
    80002b94:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002b96:	00005597          	auipc	a1,0x5
    80002b9a:	78258593          	add	a1,a1,1922 # 80008318 <states.0+0x30>
    80002b9e:	00035517          	auipc	a0,0x35
    80002ba2:	81a50513          	add	a0,a0,-2022 # 800373b8 <tickslock>
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	202080e7          	jalr	514(ra) # 80000da8 <initlock>
}
    80002bae:	60a2                	ld	ra,8(sp)
    80002bb0:	6402                	ld	s0,0(sp)
    80002bb2:	0141                	add	sp,sp,16
    80002bb4:	8082                	ret

0000000080002bb6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002bb6:	1141                	add	sp,sp,-16
    80002bb8:	e422                	sd	s0,8(sp)
    80002bba:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bbc:	00003797          	auipc	a5,0x3
    80002bc0:	61478793          	add	a5,a5,1556 # 800061d0 <kernelvec>
    80002bc4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bc8:	6422                	ld	s0,8(sp)
    80002bca:	0141                	add	sp,sp,16
    80002bcc:	8082                	ret

0000000080002bce <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002bce:	1141                	add	sp,sp,-16
    80002bd0:	e406                	sd	ra,8(sp)
    80002bd2:	e022                	sd	s0,0(sp)
    80002bd4:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	02e080e7          	jalr	46(ra) # 80001c04 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bde:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002be2:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002be4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002be8:	00004697          	auipc	a3,0x4
    80002bec:	41868693          	add	a3,a3,1048 # 80007000 <_trampoline>
    80002bf0:	00004717          	auipc	a4,0x4
    80002bf4:	41070713          	add	a4,a4,1040 # 80007000 <_trampoline>
    80002bf8:	8f15                	sub	a4,a4,a3
    80002bfa:	040007b7          	lui	a5,0x4000
    80002bfe:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002c00:	07b2                	sll	a5,a5,0xc
    80002c02:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c04:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c08:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c0a:	18002673          	csrr	a2,satp
    80002c0e:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c10:	6d30                	ld	a2,88(a0)
    80002c12:	6138                	ld	a4,64(a0)
    80002c14:	6585                	lui	a1,0x1
    80002c16:	972e                	add	a4,a4,a1
    80002c18:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c1a:	6d38                	ld	a4,88(a0)
    80002c1c:	00000617          	auipc	a2,0x0
    80002c20:	14260613          	add	a2,a2,322 # 80002d5e <usertrap>
    80002c24:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002c26:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c28:	8612                	mv	a2,tp
    80002c2a:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c2c:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c30:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c34:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c38:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c3c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c3e:	6f18                	ld	a4,24(a4)
    80002c40:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c44:	6928                	ld	a0,80(a0)
    80002c46:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c48:	00004717          	auipc	a4,0x4
    80002c4c:	45470713          	add	a4,a4,1108 # 8000709c <userret>
    80002c50:	8f15                	sub	a4,a4,a3
    80002c52:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c54:	577d                	li	a4,-1
    80002c56:	177e                	sll	a4,a4,0x3f
    80002c58:	8d59                	or	a0,a0,a4
    80002c5a:	9782                	jalr	a5
}
    80002c5c:	60a2                	ld	ra,8(sp)
    80002c5e:	6402                	ld	s0,0(sp)
    80002c60:	0141                	add	sp,sp,16
    80002c62:	8082                	ret

0000000080002c64 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002c64:	1101                	add	sp,sp,-32
    80002c66:	ec06                	sd	ra,24(sp)
    80002c68:	e822                	sd	s0,16(sp)
    80002c6a:	e426                	sd	s1,8(sp)
    80002c6c:	e04a                	sd	s2,0(sp)
    80002c6e:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002c70:	00034917          	auipc	s2,0x34
    80002c74:	74890913          	add	s2,s2,1864 # 800373b8 <tickslock>
    80002c78:	854a                	mv	a0,s2
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	1be080e7          	jalr	446(ra) # 80000e38 <acquire>
  ticks++;
    80002c82:	00006497          	auipc	s1,0x6
    80002c86:	c7e48493          	add	s1,s1,-898 # 80008900 <ticks>
    80002c8a:	409c                	lw	a5,0(s1)
    80002c8c:	2785                	addw	a5,a5,1
    80002c8e:	c09c                	sw	a5,0(s1)
  update_time();
    80002c90:	00000097          	auipc	ra,0x0
    80002c94:	e02080e7          	jalr	-510(ra) # 80002a92 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002c98:	8526                	mv	a0,s1
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	7a0080e7          	jalr	1952(ra) # 8000243a <wakeup>
  release(&tickslock);
    80002ca2:	854a                	mv	a0,s2
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	248080e7          	jalr	584(ra) # 80000eec <release>
}
    80002cac:	60e2                	ld	ra,24(sp)
    80002cae:	6442                	ld	s0,16(sp)
    80002cb0:	64a2                	ld	s1,8(sp)
    80002cb2:	6902                	ld	s2,0(sp)
    80002cb4:	6105                	add	sp,sp,32
    80002cb6:	8082                	ret

0000000080002cb8 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cb8:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80002cbc:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002cbe:	0807df63          	bgez	a5,80002d5c <devintr+0xa4>
{
    80002cc2:	1101                	add	sp,sp,-32
    80002cc4:	ec06                	sd	ra,24(sp)
    80002cc6:	e822                	sd	s0,16(sp)
    80002cc8:	e426                	sd	s1,8(sp)
    80002cca:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    80002ccc:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002cd0:	46a5                	li	a3,9
    80002cd2:	00d70d63          	beq	a4,a3,80002cec <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    80002cd6:	577d                	li	a4,-1
    80002cd8:	177e                	sll	a4,a4,0x3f
    80002cda:	0705                	add	a4,a4,1
    return 0;
    80002cdc:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002cde:	04e78e63          	beq	a5,a4,80002d3a <devintr+0x82>
  }
}
    80002ce2:	60e2                	ld	ra,24(sp)
    80002ce4:	6442                	ld	s0,16(sp)
    80002ce6:	64a2                	ld	s1,8(sp)
    80002ce8:	6105                	add	sp,sp,32
    80002cea:	8082                	ret
    int irq = plic_claim();
    80002cec:	00003097          	auipc	ra,0x3
    80002cf0:	5ec080e7          	jalr	1516(ra) # 800062d8 <plic_claim>
    80002cf4:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002cf6:	47a9                	li	a5,10
    80002cf8:	02f50763          	beq	a0,a5,80002d26 <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    80002cfc:	4785                	li	a5,1
    80002cfe:	02f50963          	beq	a0,a5,80002d30 <devintr+0x78>
    return 1;
    80002d02:	4505                	li	a0,1
    else if (irq)
    80002d04:	dcf9                	beqz	s1,80002ce2 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d06:	85a6                	mv	a1,s1
    80002d08:	00005517          	auipc	a0,0x5
    80002d0c:	61850513          	add	a0,a0,1560 # 80008320 <states.0+0x38>
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	876080e7          	jalr	-1930(ra) # 80000586 <printf>
      plic_complete(irq);
    80002d18:	8526                	mv	a0,s1
    80002d1a:	00003097          	auipc	ra,0x3
    80002d1e:	5e2080e7          	jalr	1506(ra) # 800062fc <plic_complete>
    return 1;
    80002d22:	4505                	li	a0,1
    80002d24:	bf7d                	j	80002ce2 <devintr+0x2a>
      uartintr();
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	c6e080e7          	jalr	-914(ra) # 80000994 <uartintr>
    if (irq)
    80002d2e:	b7ed                	j	80002d18 <devintr+0x60>
      virtio_disk_intr();
    80002d30:	00004097          	auipc	ra,0x4
    80002d34:	a92080e7          	jalr	-1390(ra) # 800067c2 <virtio_disk_intr>
    if (irq)
    80002d38:	b7c5                	j	80002d18 <devintr+0x60>
    if (cpuid() == 0)
    80002d3a:	fffff097          	auipc	ra,0xfffff
    80002d3e:	e9e080e7          	jalr	-354(ra) # 80001bd8 <cpuid>
    80002d42:	c901                	beqz	a0,80002d52 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d44:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d48:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d4a:	14479073          	csrw	sip,a5
    return 2;
    80002d4e:	4509                	li	a0,2
    80002d50:	bf49                	j	80002ce2 <devintr+0x2a>
      clockintr();
    80002d52:	00000097          	auipc	ra,0x0
    80002d56:	f12080e7          	jalr	-238(ra) # 80002c64 <clockintr>
    80002d5a:	b7ed                	j	80002d44 <devintr+0x8c>
}
    80002d5c:	8082                	ret

0000000080002d5e <usertrap>:
{
    80002d5e:	1101                	add	sp,sp,-32
    80002d60:	ec06                	sd	ra,24(sp)
    80002d62:	e822                	sd	s0,16(sp)
    80002d64:	e426                	sd	s1,8(sp)
    80002d66:	e04a                	sd	s2,0(sp)
    80002d68:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d6a:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d6e:	1007f793          	and	a5,a5,256
    80002d72:	e7b9                	bnez	a5,80002dc0 <usertrap+0x62>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d74:	00003797          	auipc	a5,0x3
    80002d78:	45c78793          	add	a5,a5,1116 # 800061d0 <kernelvec>
    80002d7c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d80:	fffff097          	auipc	ra,0xfffff
    80002d84:	e84080e7          	jalr	-380(ra) # 80001c04 <myproc>
    80002d88:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d8a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d8c:	14102773          	csrr	a4,sepc
    80002d90:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d92:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002d96:	47a1                	li	a5,8
    80002d98:	02f70c63          	beq	a4,a5,80002dd0 <usertrap+0x72>
    80002d9c:	14202773          	csrr	a4,scause
  else if(r_scause() == 15){
    80002da0:	47bd                	li	a5,15
    80002da2:	08f70063          	beq	a4,a5,80002e22 <usertrap+0xc4>
  else if ((which_dev = devintr()) != 0)
    80002da6:	00000097          	auipc	ra,0x0
    80002daa:	f12080e7          	jalr	-238(ra) # 80002cb8 <devintr>
    80002dae:	892a                	mv	s2,a0
    80002db0:	c155                	beqz	a0,80002e54 <usertrap+0xf6>
  if (killed(p))
    80002db2:	8526                	mv	a0,s1
    80002db4:	00000097          	auipc	ra,0x0
    80002db8:	8d6080e7          	jalr	-1834(ra) # 8000268a <killed>
    80002dbc:	cd79                	beqz	a0,80002e9a <usertrap+0x13c>
    80002dbe:	a8c9                	j	80002e90 <usertrap+0x132>
    panic("usertrap: not from user mode");
    80002dc0:	00005517          	auipc	a0,0x5
    80002dc4:	58050513          	add	a0,a0,1408 # 80008340 <states.0+0x58>
    80002dc8:	ffffd097          	auipc	ra,0xffffd
    80002dcc:	774080e7          	jalr	1908(ra) # 8000053c <panic>
    if (killed(p))
    80002dd0:	00000097          	auipc	ra,0x0
    80002dd4:	8ba080e7          	jalr	-1862(ra) # 8000268a <killed>
    80002dd8:	ed1d                	bnez	a0,80002e16 <usertrap+0xb8>
    p->trapframe->epc += 4;
    80002dda:	6cb8                	ld	a4,88(s1)
    80002ddc:	6f1c                	ld	a5,24(a4)
    80002dde:	0791                	add	a5,a5,4
    80002de0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002de2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002de6:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dea:	10079073          	csrw	sstatus,a5
    syscall();
    80002dee:	00000097          	auipc	ra,0x0
    80002df2:	306080e7          	jalr	774(ra) # 800030f4 <syscall>
  if (killed(p))
    80002df6:	8526                	mv	a0,s1
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	892080e7          	jalr	-1902(ra) # 8000268a <killed>
    80002e00:	e559                	bnez	a0,80002e8e <usertrap+0x130>
  usertrapret();
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	dcc080e7          	jalr	-564(ra) # 80002bce <usertrapret>
}
    80002e0a:	60e2                	ld	ra,24(sp)
    80002e0c:	6442                	ld	s0,16(sp)
    80002e0e:	64a2                	ld	s1,8(sp)
    80002e10:	6902                	ld	s2,0(sp)
    80002e12:	6105                	add	sp,sp,32
    80002e14:	8082                	ret
      exit(-1);
    80002e16:	557d                	li	a0,-1
    80002e18:	fffff097          	auipc	ra,0xfffff
    80002e1c:	6f2080e7          	jalr	1778(ra) # 8000250a <exit>
    80002e20:	bf6d                	j	80002dda <usertrap+0x7c>
    if(killed(p))
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	868080e7          	jalr	-1944(ra) # 8000268a <killed>
    80002e2a:	ed19                	bnez	a0,80002e48 <usertrap+0xea>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e2c:	143025f3          	csrr	a1,stval
    if(pagefhandler(p->pagetable,va) < 0){
    80002e30:	77fd                	lui	a5,0xfffff
    80002e32:	8dfd                	and	a1,a1,a5
    80002e34:	68a8                	ld	a0,80(s1)
    80002e36:	ffffe097          	auipc	ra,0xffffe
    80002e3a:	eb2080e7          	jalr	-334(ra) # 80000ce8 <pagefhandler>
    80002e3e:	fa055ce3          	bgez	a0,80002df6 <usertrap+0x98>
      p->killed = 1;
    80002e42:	4785                	li	a5,1
    80002e44:	d49c                	sw	a5,40(s1)
    80002e46:	bf45                	j	80002df6 <usertrap+0x98>
      exit(-1);
    80002e48:	557d                	li	a0,-1
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	6c0080e7          	jalr	1728(ra) # 8000250a <exit>
    80002e52:	bfe9                	j	80002e2c <usertrap+0xce>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e54:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e58:	5890                	lw	a2,48(s1)
    80002e5a:	00005517          	auipc	a0,0x5
    80002e5e:	50650513          	add	a0,a0,1286 # 80008360 <states.0+0x78>
    80002e62:	ffffd097          	auipc	ra,0xffffd
    80002e66:	724080e7          	jalr	1828(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e6a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e6e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e72:	00005517          	auipc	a0,0x5
    80002e76:	51e50513          	add	a0,a0,1310 # 80008390 <states.0+0xa8>
    80002e7a:	ffffd097          	auipc	ra,0xffffd
    80002e7e:	70c080e7          	jalr	1804(ra) # 80000586 <printf>
    setkilled(p);
    80002e82:	8526                	mv	a0,s1
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	7da080e7          	jalr	2010(ra) # 8000265e <setkilled>
    80002e8c:	b7ad                	j	80002df6 <usertrap+0x98>
  if (killed(p))
    80002e8e:	4901                	li	s2,0
    exit(-1);
    80002e90:	557d                	li	a0,-1
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	678080e7          	jalr	1656(ra) # 8000250a <exit>
  if (which_dev == 2)
    80002e9a:	4789                	li	a5,2
    80002e9c:	f6f913e3          	bne	s2,a5,80002e02 <usertrap+0xa4>
    yield();
    80002ea0:	fffff097          	auipc	ra,0xfffff
    80002ea4:	4fa080e7          	jalr	1274(ra) # 8000239a <yield>
    80002ea8:	bfa9                	j	80002e02 <usertrap+0xa4>

0000000080002eaa <kerneltrap>:
{
    80002eaa:	7179                	add	sp,sp,-48
    80002eac:	f406                	sd	ra,40(sp)
    80002eae:	f022                	sd	s0,32(sp)
    80002eb0:	ec26                	sd	s1,24(sp)
    80002eb2:	e84a                	sd	s2,16(sp)
    80002eb4:	e44e                	sd	s3,8(sp)
    80002eb6:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eb8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ebc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ec0:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002ec4:	1004f793          	and	a5,s1,256
    80002ec8:	cb85                	beqz	a5,80002ef8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eca:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ece:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    80002ed0:	ef85                	bnez	a5,80002f08 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	de6080e7          	jalr	-538(ra) # 80002cb8 <devintr>
    80002eda:	cd1d                	beqz	a0,80002f18 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002edc:	4789                	li	a5,2
    80002ede:	06f50a63          	beq	a0,a5,80002f52 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ee2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ee6:	10049073          	csrw	sstatus,s1
}
    80002eea:	70a2                	ld	ra,40(sp)
    80002eec:	7402                	ld	s0,32(sp)
    80002eee:	64e2                	ld	s1,24(sp)
    80002ef0:	6942                	ld	s2,16(sp)
    80002ef2:	69a2                	ld	s3,8(sp)
    80002ef4:	6145                	add	sp,sp,48
    80002ef6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ef8:	00005517          	auipc	a0,0x5
    80002efc:	4b850513          	add	a0,a0,1208 # 800083b0 <states.0+0xc8>
    80002f00:	ffffd097          	auipc	ra,0xffffd
    80002f04:	63c080e7          	jalr	1596(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002f08:	00005517          	auipc	a0,0x5
    80002f0c:	4d050513          	add	a0,a0,1232 # 800083d8 <states.0+0xf0>
    80002f10:	ffffd097          	auipc	ra,0xffffd
    80002f14:	62c080e7          	jalr	1580(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002f18:	85ce                	mv	a1,s3
    80002f1a:	00005517          	auipc	a0,0x5
    80002f1e:	4de50513          	add	a0,a0,1246 # 800083f8 <states.0+0x110>
    80002f22:	ffffd097          	auipc	ra,0xffffd
    80002f26:	664080e7          	jalr	1636(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f2a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f2e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f32:	00005517          	auipc	a0,0x5
    80002f36:	4d650513          	add	a0,a0,1238 # 80008408 <states.0+0x120>
    80002f3a:	ffffd097          	auipc	ra,0xffffd
    80002f3e:	64c080e7          	jalr	1612(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002f42:	00005517          	auipc	a0,0x5
    80002f46:	4de50513          	add	a0,a0,1246 # 80008420 <states.0+0x138>
    80002f4a:	ffffd097          	auipc	ra,0xffffd
    80002f4e:	5f2080e7          	jalr	1522(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	cb2080e7          	jalr	-846(ra) # 80001c04 <myproc>
    80002f5a:	d541                	beqz	a0,80002ee2 <kerneltrap+0x38>
    80002f5c:	fffff097          	auipc	ra,0xfffff
    80002f60:	ca8080e7          	jalr	-856(ra) # 80001c04 <myproc>
    80002f64:	4d18                	lw	a4,24(a0)
    80002f66:	4791                	li	a5,4
    80002f68:	f6f71de3          	bne	a4,a5,80002ee2 <kerneltrap+0x38>
    yield();
    80002f6c:	fffff097          	auipc	ra,0xfffff
    80002f70:	42e080e7          	jalr	1070(ra) # 8000239a <yield>
    80002f74:	b7bd                	j	80002ee2 <kerneltrap+0x38>

0000000080002f76 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f76:	1101                	add	sp,sp,-32
    80002f78:	ec06                	sd	ra,24(sp)
    80002f7a:	e822                	sd	s0,16(sp)
    80002f7c:	e426                	sd	s1,8(sp)
    80002f7e:	1000                	add	s0,sp,32
    80002f80:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	c82080e7          	jalr	-894(ra) # 80001c04 <myproc>
  switch (n) {
    80002f8a:	4795                	li	a5,5
    80002f8c:	0497e163          	bltu	a5,s1,80002fce <argraw+0x58>
    80002f90:	048a                	sll	s1,s1,0x2
    80002f92:	00005717          	auipc	a4,0x5
    80002f96:	4c670713          	add	a4,a4,1222 # 80008458 <states.0+0x170>
    80002f9a:	94ba                	add	s1,s1,a4
    80002f9c:	409c                	lw	a5,0(s1)
    80002f9e:	97ba                	add	a5,a5,a4
    80002fa0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fa2:	6d3c                	ld	a5,88(a0)
    80002fa4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002fa6:	60e2                	ld	ra,24(sp)
    80002fa8:	6442                	ld	s0,16(sp)
    80002faa:	64a2                	ld	s1,8(sp)
    80002fac:	6105                	add	sp,sp,32
    80002fae:	8082                	ret
    return p->trapframe->a1;
    80002fb0:	6d3c                	ld	a5,88(a0)
    80002fb2:	7fa8                	ld	a0,120(a5)
    80002fb4:	bfcd                	j	80002fa6 <argraw+0x30>
    return p->trapframe->a2;
    80002fb6:	6d3c                	ld	a5,88(a0)
    80002fb8:	63c8                	ld	a0,128(a5)
    80002fba:	b7f5                	j	80002fa6 <argraw+0x30>
    return p->trapframe->a3;
    80002fbc:	6d3c                	ld	a5,88(a0)
    80002fbe:	67c8                	ld	a0,136(a5)
    80002fc0:	b7dd                	j	80002fa6 <argraw+0x30>
    return p->trapframe->a4;
    80002fc2:	6d3c                	ld	a5,88(a0)
    80002fc4:	6bc8                	ld	a0,144(a5)
    80002fc6:	b7c5                	j	80002fa6 <argraw+0x30>
    return p->trapframe->a5;
    80002fc8:	6d3c                	ld	a5,88(a0)
    80002fca:	6fc8                	ld	a0,152(a5)
    80002fcc:	bfe9                	j	80002fa6 <argraw+0x30>
  panic("argraw");
    80002fce:	00005517          	auipc	a0,0x5
    80002fd2:	46250513          	add	a0,a0,1122 # 80008430 <states.0+0x148>
    80002fd6:	ffffd097          	auipc	ra,0xffffd
    80002fda:	566080e7          	jalr	1382(ra) # 8000053c <panic>

0000000080002fde <fetchaddr>:
{
    80002fde:	1101                	add	sp,sp,-32
    80002fe0:	ec06                	sd	ra,24(sp)
    80002fe2:	e822                	sd	s0,16(sp)
    80002fe4:	e426                	sd	s1,8(sp)
    80002fe6:	e04a                	sd	s2,0(sp)
    80002fe8:	1000                	add	s0,sp,32
    80002fea:	84aa                	mv	s1,a0
    80002fec:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002fee:	fffff097          	auipc	ra,0xfffff
    80002ff2:	c16080e7          	jalr	-1002(ra) # 80001c04 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ff6:	653c                	ld	a5,72(a0)
    80002ff8:	02f4f863          	bgeu	s1,a5,80003028 <fetchaddr+0x4a>
    80002ffc:	00848713          	add	a4,s1,8
    80003000:	02e7e663          	bltu	a5,a4,8000302c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003004:	46a1                	li	a3,8
    80003006:	8626                	mv	a2,s1
    80003008:	85ca                	mv	a1,s2
    8000300a:	6928                	ld	a0,80(a0)
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	944080e7          	jalr	-1724(ra) # 80001950 <copyin>
    80003014:	00a03533          	snez	a0,a0
    80003018:	40a00533          	neg	a0,a0
}
    8000301c:	60e2                	ld	ra,24(sp)
    8000301e:	6442                	ld	s0,16(sp)
    80003020:	64a2                	ld	s1,8(sp)
    80003022:	6902                	ld	s2,0(sp)
    80003024:	6105                	add	sp,sp,32
    80003026:	8082                	ret
    return -1;
    80003028:	557d                	li	a0,-1
    8000302a:	bfcd                	j	8000301c <fetchaddr+0x3e>
    8000302c:	557d                	li	a0,-1
    8000302e:	b7fd                	j	8000301c <fetchaddr+0x3e>

0000000080003030 <fetchstr>:
{
    80003030:	7179                	add	sp,sp,-48
    80003032:	f406                	sd	ra,40(sp)
    80003034:	f022                	sd	s0,32(sp)
    80003036:	ec26                	sd	s1,24(sp)
    80003038:	e84a                	sd	s2,16(sp)
    8000303a:	e44e                	sd	s3,8(sp)
    8000303c:	1800                	add	s0,sp,48
    8000303e:	892a                	mv	s2,a0
    80003040:	84ae                	mv	s1,a1
    80003042:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003044:	fffff097          	auipc	ra,0xfffff
    80003048:	bc0080e7          	jalr	-1088(ra) # 80001c04 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    8000304c:	86ce                	mv	a3,s3
    8000304e:	864a                	mv	a2,s2
    80003050:	85a6                	mv	a1,s1
    80003052:	6928                	ld	a0,80(a0)
    80003054:	fffff097          	auipc	ra,0xfffff
    80003058:	98a080e7          	jalr	-1654(ra) # 800019de <copyinstr>
    8000305c:	00054e63          	bltz	a0,80003078 <fetchstr+0x48>
  return strlen(buf);
    80003060:	8526                	mv	a0,s1
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	04c080e7          	jalr	76(ra) # 800010ae <strlen>
}
    8000306a:	70a2                	ld	ra,40(sp)
    8000306c:	7402                	ld	s0,32(sp)
    8000306e:	64e2                	ld	s1,24(sp)
    80003070:	6942                	ld	s2,16(sp)
    80003072:	69a2                	ld	s3,8(sp)
    80003074:	6145                	add	sp,sp,48
    80003076:	8082                	ret
    return -1;
    80003078:	557d                	li	a0,-1
    8000307a:	bfc5                	j	8000306a <fetchstr+0x3a>

000000008000307c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    8000307c:	1101                	add	sp,sp,-32
    8000307e:	ec06                	sd	ra,24(sp)
    80003080:	e822                	sd	s0,16(sp)
    80003082:	e426                	sd	s1,8(sp)
    80003084:	1000                	add	s0,sp,32
    80003086:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	eee080e7          	jalr	-274(ra) # 80002f76 <argraw>
    80003090:	c088                	sw	a0,0(s1)
}
    80003092:	60e2                	ld	ra,24(sp)
    80003094:	6442                	ld	s0,16(sp)
    80003096:	64a2                	ld	s1,8(sp)
    80003098:	6105                	add	sp,sp,32
    8000309a:	8082                	ret

000000008000309c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    8000309c:	1101                	add	sp,sp,-32
    8000309e:	ec06                	sd	ra,24(sp)
    800030a0:	e822                	sd	s0,16(sp)
    800030a2:	e426                	sd	s1,8(sp)
    800030a4:	1000                	add	s0,sp,32
    800030a6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030a8:	00000097          	auipc	ra,0x0
    800030ac:	ece080e7          	jalr	-306(ra) # 80002f76 <argraw>
    800030b0:	e088                	sd	a0,0(s1)
}
    800030b2:	60e2                	ld	ra,24(sp)
    800030b4:	6442                	ld	s0,16(sp)
    800030b6:	64a2                	ld	s1,8(sp)
    800030b8:	6105                	add	sp,sp,32
    800030ba:	8082                	ret

00000000800030bc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030bc:	7179                	add	sp,sp,-48
    800030be:	f406                	sd	ra,40(sp)
    800030c0:	f022                	sd	s0,32(sp)
    800030c2:	ec26                	sd	s1,24(sp)
    800030c4:	e84a                	sd	s2,16(sp)
    800030c6:	1800                	add	s0,sp,48
    800030c8:	84ae                	mv	s1,a1
    800030ca:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800030cc:	fd840593          	add	a1,s0,-40
    800030d0:	00000097          	auipc	ra,0x0
    800030d4:	fcc080e7          	jalr	-52(ra) # 8000309c <argaddr>
  return fetchstr(addr, buf, max);
    800030d8:	864a                	mv	a2,s2
    800030da:	85a6                	mv	a1,s1
    800030dc:	fd843503          	ld	a0,-40(s0)
    800030e0:	00000097          	auipc	ra,0x0
    800030e4:	f50080e7          	jalr	-176(ra) # 80003030 <fetchstr>
}
    800030e8:	70a2                	ld	ra,40(sp)
    800030ea:	7402                	ld	s0,32(sp)
    800030ec:	64e2                	ld	s1,24(sp)
    800030ee:	6942                	ld	s2,16(sp)
    800030f0:	6145                	add	sp,sp,48
    800030f2:	8082                	ret

00000000800030f4 <syscall>:
[SYS_set_priority] sys_set_priority,
};

void
syscall(void)
{
    800030f4:	1101                	add	sp,sp,-32
    800030f6:	ec06                	sd	ra,24(sp)
    800030f8:	e822                	sd	s0,16(sp)
    800030fa:	e426                	sd	s1,8(sp)
    800030fc:	e04a                	sd	s2,0(sp)
    800030fe:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003100:	fffff097          	auipc	ra,0xfffff
    80003104:	b04080e7          	jalr	-1276(ra) # 80001c04 <myproc>
    80003108:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000310a:	05853903          	ld	s2,88(a0)
    8000310e:	0a893783          	ld	a5,168(s2)
    80003112:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003116:	37fd                	addw	a5,a5,-1 # ffffffffffffefff <end+0xffffffff7ffbc867>
    80003118:	475d                	li	a4,23
    8000311a:	00f76f63          	bltu	a4,a5,80003138 <syscall+0x44>
    8000311e:	00369713          	sll	a4,a3,0x3
    80003122:	00005797          	auipc	a5,0x5
    80003126:	34e78793          	add	a5,a5,846 # 80008470 <syscalls>
    8000312a:	97ba                	add	a5,a5,a4
    8000312c:	639c                	ld	a5,0(a5)
    8000312e:	c789                	beqz	a5,80003138 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003130:	9782                	jalr	a5
    80003132:	06a93823          	sd	a0,112(s2)
    80003136:	a839                	j	80003154 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003138:	15848613          	add	a2,s1,344
    8000313c:	588c                	lw	a1,48(s1)
    8000313e:	00005517          	auipc	a0,0x5
    80003142:	2fa50513          	add	a0,a0,762 # 80008438 <states.0+0x150>
    80003146:	ffffd097          	auipc	ra,0xffffd
    8000314a:	440080e7          	jalr	1088(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000314e:	6cbc                	ld	a5,88(s1)
    80003150:	577d                	li	a4,-1
    80003152:	fbb8                	sd	a4,112(a5)
  }
}
    80003154:	60e2                	ld	ra,24(sp)
    80003156:	6442                	ld	s0,16(sp)
    80003158:	64a2                	ld	s1,8(sp)
    8000315a:	6902                	ld	s2,0(sp)
    8000315c:	6105                	add	sp,sp,32
    8000315e:	8082                	ret

0000000080003160 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003160:	1101                	add	sp,sp,-32
    80003162:	ec06                	sd	ra,24(sp)
    80003164:	e822                	sd	s0,16(sp)
    80003166:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80003168:	fec40593          	add	a1,s0,-20
    8000316c:	4501                	li	a0,0
    8000316e:	00000097          	auipc	ra,0x0
    80003172:	f0e080e7          	jalr	-242(ra) # 8000307c <argint>
  exit(n);
    80003176:	fec42503          	lw	a0,-20(s0)
    8000317a:	fffff097          	auipc	ra,0xfffff
    8000317e:	390080e7          	jalr	912(ra) # 8000250a <exit>
  return 0; // not reached
}
    80003182:	4501                	li	a0,0
    80003184:	60e2                	ld	ra,24(sp)
    80003186:	6442                	ld	s0,16(sp)
    80003188:	6105                	add	sp,sp,32
    8000318a:	8082                	ret

000000008000318c <sys_set_priority>:
int
sys_set_priority(void)
{
    8000318c:	7139                	add	sp,sp,-64
    8000318e:	fc06                	sd	ra,56(sp)
    80003190:	f822                	sd	s0,48(sp)
    80003192:	f426                	sd	s1,40(sp)
    80003194:	f04a                	sd	s2,32(sp)
    80003196:	ec4e                	sd	s3,24(sp)
    80003198:	0080                	add	s0,sp,64
  int priority;
  int pid;
  int LS= -1,LD=-1;
  int flag = 0;
  argint(0,&priority);
    8000319a:	fcc40593          	add	a1,s0,-52
    8000319e:	4501                	li	a0,0
    800031a0:	00000097          	auipc	ra,0x0
    800031a4:	edc080e7          	jalr	-292(ra) # 8000307c <argint>
  argint(1,&pid);
    800031a8:	fc840593          	add	a1,s0,-56
    800031ac:	4505                	li	a0,1
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	ece080e7          	jalr	-306(ra) # 8000307c <argint>
  struct proc* p;
  for(p = proc; p < &proc[NPROC]; p++) {
    800031b6:	0002e497          	auipc	s1,0x2e
    800031ba:	e0248493          	add	s1,s1,-510 # 80030fb8 <proc>
  int LS= -1,LD=-1;
    800031be:	59fd                	li	s3,-1
  for(p = proc; p < &proc[NPROC]; p++) {
    800031c0:	00034917          	auipc	s2,0x34
    800031c4:	1f890913          	add	s2,s2,504 # 800373b8 <tickslock>
    800031c8:	a811                	j	800031dc <sys_set_priority+0x50>
      p->D = p->S;
      if(p->D< LD){
         flag = 1;
         break;}
    }
    release(&p->lock);
    800031ca:	8526                	mv	a0,s1
    800031cc:	ffffe097          	auipc	ra,0xffffe
    800031d0:	d20080e7          	jalr	-736(ra) # 80000eec <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800031d4:	19048493          	add	s1,s1,400
    800031d8:	05248563          	beq	s1,s2,80003222 <sys_set_priority+0x96>
    acquire(&p->lock);
    800031dc:	8526                	mv	a0,s1
    800031de:	ffffe097          	auipc	ra,0xffffe
    800031e2:	c5a080e7          	jalr	-934(ra) # 80000e38 <acquire>
    if(p->pid == pid){
    800031e6:	5898                	lw	a4,48(s1)
    800031e8:	fc842783          	lw	a5,-56(s0)
    800031ec:	fcf71fe3          	bne	a4,a5,800031ca <sys_set_priority+0x3e>
      p->time_sleep= 0;
    800031f0:	1604ac23          	sw	zero,376(s1)
      p->time_run = 0;
    800031f4:	1604ae23          	sw	zero,380(s1)
      LS = p->S;
    800031f8:	1844a983          	lw	s3,388(s1)
      LD = p->D;
    800031fc:	1804a703          	lw	a4,384(s1)
      p->S = priority;
    80003200:	fcc42783          	lw	a5,-52(s0)
    80003204:	18f4a223          	sw	a5,388(s1)
      p->D = p->S;
    80003208:	18f4a023          	sw	a5,384(s1)
      if(p->D< LD){
    8000320c:	fae7dfe3          	bge	a5,a4,800031ca <sys_set_priority+0x3e>
  }
 if(flag){
    release(&p->lock);
    80003210:	8526                	mv	a0,s1
    80003212:	ffffe097          	auipc	ra,0xffffe
    80003216:	cda080e7          	jalr	-806(ra) # 80000eec <release>
    yield();}
    8000321a:	fffff097          	auipc	ra,0xfffff
    8000321e:	180080e7          	jalr	384(ra) # 8000239a <yield>
  return LS;
}
    80003222:	854e                	mv	a0,s3
    80003224:	70e2                	ld	ra,56(sp)
    80003226:	7442                	ld	s0,48(sp)
    80003228:	74a2                	ld	s1,40(sp)
    8000322a:	7902                	ld	s2,32(sp)
    8000322c:	69e2                	ld	s3,24(sp)
    8000322e:	6121                	add	sp,sp,64
    80003230:	8082                	ret

0000000080003232 <sys_getpid>:
uint64
sys_getpid(void)
{
    80003232:	1141                	add	sp,sp,-16
    80003234:	e406                	sd	ra,8(sp)
    80003236:	e022                	sd	s0,0(sp)
    80003238:	0800                	add	s0,sp,16
  return myproc()->pid;
    8000323a:	fffff097          	auipc	ra,0xfffff
    8000323e:	9ca080e7          	jalr	-1590(ra) # 80001c04 <myproc>
}
    80003242:	5908                	lw	a0,48(a0)
    80003244:	60a2                	ld	ra,8(sp)
    80003246:	6402                	ld	s0,0(sp)
    80003248:	0141                	add	sp,sp,16
    8000324a:	8082                	ret

000000008000324c <sys_fork>:

uint64
sys_fork(void)
{
    8000324c:	1141                	add	sp,sp,-16
    8000324e:	e406                	sd	ra,8(sp)
    80003250:	e022                	sd	s0,0(sp)
    80003252:	0800                	add	s0,sp,16
  return fork();
    80003254:	fffff097          	auipc	ra,0xfffff
    80003258:	d9a080e7          	jalr	-614(ra) # 80001fee <fork>
}
    8000325c:	60a2                	ld	ra,8(sp)
    8000325e:	6402                	ld	s0,0(sp)
    80003260:	0141                	add	sp,sp,16
    80003262:	8082                	ret

0000000080003264 <sys_wait>:

uint64
sys_wait(void)
{
    80003264:	1101                	add	sp,sp,-32
    80003266:	ec06                	sd	ra,24(sp)
    80003268:	e822                	sd	s0,16(sp)
    8000326a:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000326c:	fe840593          	add	a1,s0,-24
    80003270:	4501                	li	a0,0
    80003272:	00000097          	auipc	ra,0x0
    80003276:	e2a080e7          	jalr	-470(ra) # 8000309c <argaddr>
  return wait(p);
    8000327a:	fe843503          	ld	a0,-24(s0)
    8000327e:	fffff097          	auipc	ra,0xfffff
    80003282:	43e080e7          	jalr	1086(ra) # 800026bc <wait>
}
    80003286:	60e2                	ld	ra,24(sp)
    80003288:	6442                	ld	s0,16(sp)
    8000328a:	6105                	add	sp,sp,32
    8000328c:	8082                	ret

000000008000328e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000328e:	7179                	add	sp,sp,-48
    80003290:	f406                	sd	ra,40(sp)
    80003292:	f022                	sd	s0,32(sp)
    80003294:	ec26                	sd	s1,24(sp)
    80003296:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003298:	fdc40593          	add	a1,s0,-36
    8000329c:	4501                	li	a0,0
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	dde080e7          	jalr	-546(ra) # 8000307c <argint>
  addr = myproc()->sz;
    800032a6:	fffff097          	auipc	ra,0xfffff
    800032aa:	95e080e7          	jalr	-1698(ra) # 80001c04 <myproc>
    800032ae:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800032b0:	fdc42503          	lw	a0,-36(s0)
    800032b4:	fffff097          	auipc	ra,0xfffff
    800032b8:	cde080e7          	jalr	-802(ra) # 80001f92 <growproc>
    800032bc:	00054863          	bltz	a0,800032cc <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800032c0:	8526                	mv	a0,s1
    800032c2:	70a2                	ld	ra,40(sp)
    800032c4:	7402                	ld	s0,32(sp)
    800032c6:	64e2                	ld	s1,24(sp)
    800032c8:	6145                	add	sp,sp,48
    800032ca:	8082                	ret
    return -1;
    800032cc:	54fd                	li	s1,-1
    800032ce:	bfcd                	j	800032c0 <sys_sbrk+0x32>

00000000800032d0 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032d0:	7139                	add	sp,sp,-64
    800032d2:	fc06                	sd	ra,56(sp)
    800032d4:	f822                	sd	s0,48(sp)
    800032d6:	f426                	sd	s1,40(sp)
    800032d8:	f04a                	sd	s2,32(sp)
    800032da:	ec4e                	sd	s3,24(sp)
    800032dc:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800032de:	fcc40593          	add	a1,s0,-52
    800032e2:	4501                	li	a0,0
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	d98080e7          	jalr	-616(ra) # 8000307c <argint>
  acquire(&tickslock);
    800032ec:	00034517          	auipc	a0,0x34
    800032f0:	0cc50513          	add	a0,a0,204 # 800373b8 <tickslock>
    800032f4:	ffffe097          	auipc	ra,0xffffe
    800032f8:	b44080e7          	jalr	-1212(ra) # 80000e38 <acquire>
  ticks0 = ticks;
    800032fc:	00005917          	auipc	s2,0x5
    80003300:	60492903          	lw	s2,1540(s2) # 80008900 <ticks>
  while (ticks - ticks0 < n)
    80003304:	fcc42783          	lw	a5,-52(s0)
    80003308:	cf9d                	beqz	a5,80003346 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000330a:	00034997          	auipc	s3,0x34
    8000330e:	0ae98993          	add	s3,s3,174 # 800373b8 <tickslock>
    80003312:	00005497          	auipc	s1,0x5
    80003316:	5ee48493          	add	s1,s1,1518 # 80008900 <ticks>
    if (killed(myproc()))
    8000331a:	fffff097          	auipc	ra,0xfffff
    8000331e:	8ea080e7          	jalr	-1814(ra) # 80001c04 <myproc>
    80003322:	fffff097          	auipc	ra,0xfffff
    80003326:	368080e7          	jalr	872(ra) # 8000268a <killed>
    8000332a:	ed15                	bnez	a0,80003366 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000332c:	85ce                	mv	a1,s3
    8000332e:	8526                	mv	a0,s1
    80003330:	fffff097          	auipc	ra,0xfffff
    80003334:	0a6080e7          	jalr	166(ra) # 800023d6 <sleep>
  while (ticks - ticks0 < n)
    80003338:	409c                	lw	a5,0(s1)
    8000333a:	412787bb          	subw	a5,a5,s2
    8000333e:	fcc42703          	lw	a4,-52(s0)
    80003342:	fce7ece3          	bltu	a5,a4,8000331a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003346:	00034517          	auipc	a0,0x34
    8000334a:	07250513          	add	a0,a0,114 # 800373b8 <tickslock>
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	b9e080e7          	jalr	-1122(ra) # 80000eec <release>
  return 0;
    80003356:	4501                	li	a0,0
}
    80003358:	70e2                	ld	ra,56(sp)
    8000335a:	7442                	ld	s0,48(sp)
    8000335c:	74a2                	ld	s1,40(sp)
    8000335e:	7902                	ld	s2,32(sp)
    80003360:	69e2                	ld	s3,24(sp)
    80003362:	6121                	add	sp,sp,64
    80003364:	8082                	ret
      release(&tickslock);
    80003366:	00034517          	auipc	a0,0x34
    8000336a:	05250513          	add	a0,a0,82 # 800373b8 <tickslock>
    8000336e:	ffffe097          	auipc	ra,0xffffe
    80003372:	b7e080e7          	jalr	-1154(ra) # 80000eec <release>
      return -1;
    80003376:	557d                	li	a0,-1
    80003378:	b7c5                	j	80003358 <sys_sleep+0x88>

000000008000337a <sys_kill>:

uint64
sys_kill(void)
{
    8000337a:	1101                	add	sp,sp,-32
    8000337c:	ec06                	sd	ra,24(sp)
    8000337e:	e822                	sd	s0,16(sp)
    80003380:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    80003382:	fec40593          	add	a1,s0,-20
    80003386:	4501                	li	a0,0
    80003388:	00000097          	auipc	ra,0x0
    8000338c:	cf4080e7          	jalr	-780(ra) # 8000307c <argint>
  return kill(pid);
    80003390:	fec42503          	lw	a0,-20(s0)
    80003394:	fffff097          	auipc	ra,0xfffff
    80003398:	258080e7          	jalr	600(ra) # 800025ec <kill>
}
    8000339c:	60e2                	ld	ra,24(sp)
    8000339e:	6442                	ld	s0,16(sp)
    800033a0:	6105                	add	sp,sp,32
    800033a2:	8082                	ret

00000000800033a4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033a4:	1101                	add	sp,sp,-32
    800033a6:	ec06                	sd	ra,24(sp)
    800033a8:	e822                	sd	s0,16(sp)
    800033aa:	e426                	sd	s1,8(sp)
    800033ac:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033ae:	00034517          	auipc	a0,0x34
    800033b2:	00a50513          	add	a0,a0,10 # 800373b8 <tickslock>
    800033b6:	ffffe097          	auipc	ra,0xffffe
    800033ba:	a82080e7          	jalr	-1406(ra) # 80000e38 <acquire>
  xticks = ticks;
    800033be:	00005497          	auipc	s1,0x5
    800033c2:	5424a483          	lw	s1,1346(s1) # 80008900 <ticks>
  release(&tickslock);
    800033c6:	00034517          	auipc	a0,0x34
    800033ca:	ff250513          	add	a0,a0,-14 # 800373b8 <tickslock>
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	b1e080e7          	jalr	-1250(ra) # 80000eec <release>
  return xticks;
}
    800033d6:	02049513          	sll	a0,s1,0x20
    800033da:	9101                	srl	a0,a0,0x20
    800033dc:	60e2                	ld	ra,24(sp)
    800033de:	6442                	ld	s0,16(sp)
    800033e0:	64a2                	ld	s1,8(sp)
    800033e2:	6105                	add	sp,sp,32
    800033e4:	8082                	ret

00000000800033e6 <sys_waitx>:

uint64
sys_waitx(void)
{
    800033e6:	7139                	add	sp,sp,-64
    800033e8:	fc06                	sd	ra,56(sp)
    800033ea:	f822                	sd	s0,48(sp)
    800033ec:	f426                	sd	s1,40(sp)
    800033ee:	f04a                	sd	s2,32(sp)
    800033f0:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800033f2:	fd840593          	add	a1,s0,-40
    800033f6:	4501                	li	a0,0
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	ca4080e7          	jalr	-860(ra) # 8000309c <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003400:	fd040593          	add	a1,s0,-48
    80003404:	4505                	li	a0,1
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	c96080e7          	jalr	-874(ra) # 8000309c <argaddr>
  argaddr(2, &addr2);
    8000340e:	fc840593          	add	a1,s0,-56
    80003412:	4509                	li	a0,2
    80003414:	00000097          	auipc	ra,0x0
    80003418:	c88080e7          	jalr	-888(ra) # 8000309c <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000341c:	fc040613          	add	a2,s0,-64
    80003420:	fc440593          	add	a1,s0,-60
    80003424:	fd843503          	ld	a0,-40(s0)
    80003428:	fffff097          	auipc	ra,0xfffff
    8000342c:	51e080e7          	jalr	1310(ra) # 80002946 <waitx>
    80003430:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003432:	ffffe097          	auipc	ra,0xffffe
    80003436:	7d2080e7          	jalr	2002(ra) # 80001c04 <myproc>
    8000343a:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000343c:	4691                	li	a3,4
    8000343e:	fc440613          	add	a2,s0,-60
    80003442:	fd043583          	ld	a1,-48(s0)
    80003446:	6928                	ld	a0,80(a0)
    80003448:	ffffe097          	auipc	ra,0xffffe
    8000344c:	472080e7          	jalr	1138(ra) # 800018ba <copyout>
    return -1;
    80003450:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003452:	00054f63          	bltz	a0,80003470 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003456:	4691                	li	a3,4
    80003458:	fc040613          	add	a2,s0,-64
    8000345c:	fc843583          	ld	a1,-56(s0)
    80003460:	68a8                	ld	a0,80(s1)
    80003462:	ffffe097          	auipc	ra,0xffffe
    80003466:	458080e7          	jalr	1112(ra) # 800018ba <copyout>
    8000346a:	00054a63          	bltz	a0,8000347e <sys_waitx+0x98>
    return -1;
  return ret;
    8000346e:	87ca                	mv	a5,s2
    80003470:	853e                	mv	a0,a5
    80003472:	70e2                	ld	ra,56(sp)
    80003474:	7442                	ld	s0,48(sp)
    80003476:	74a2                	ld	s1,40(sp)
    80003478:	7902                	ld	s2,32(sp)
    8000347a:	6121                	add	sp,sp,64
    8000347c:	8082                	ret
    return -1;
    8000347e:	57fd                	li	a5,-1
    80003480:	bfc5                	j	80003470 <sys_waitx+0x8a>

0000000080003482 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003482:	7179                	add	sp,sp,-48
    80003484:	f406                	sd	ra,40(sp)
    80003486:	f022                	sd	s0,32(sp)
    80003488:	ec26                	sd	s1,24(sp)
    8000348a:	e84a                	sd	s2,16(sp)
    8000348c:	e44e                	sd	s3,8(sp)
    8000348e:	e052                	sd	s4,0(sp)
    80003490:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003492:	00005597          	auipc	a1,0x5
    80003496:	0a658593          	add	a1,a1,166 # 80008538 <syscalls+0xc8>
    8000349a:	00034517          	auipc	a0,0x34
    8000349e:	f3650513          	add	a0,a0,-202 # 800373d0 <bcache>
    800034a2:	ffffe097          	auipc	ra,0xffffe
    800034a6:	906080e7          	jalr	-1786(ra) # 80000da8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034aa:	0003c797          	auipc	a5,0x3c
    800034ae:	f2678793          	add	a5,a5,-218 # 8003f3d0 <bcache+0x8000>
    800034b2:	0003c717          	auipc	a4,0x3c
    800034b6:	18670713          	add	a4,a4,390 # 8003f638 <bcache+0x8268>
    800034ba:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034be:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034c2:	00034497          	auipc	s1,0x34
    800034c6:	f2648493          	add	s1,s1,-218 # 800373e8 <bcache+0x18>
    b->next = bcache.head.next;
    800034ca:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034cc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034ce:	00005a17          	auipc	s4,0x5
    800034d2:	072a0a13          	add	s4,s4,114 # 80008540 <syscalls+0xd0>
    b->next = bcache.head.next;
    800034d6:	2b893783          	ld	a5,696(s2)
    800034da:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034dc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034e0:	85d2                	mv	a1,s4
    800034e2:	01048513          	add	a0,s1,16
    800034e6:	00001097          	auipc	ra,0x1
    800034ea:	496080e7          	jalr	1174(ra) # 8000497c <initsleeplock>
    bcache.head.next->prev = b;
    800034ee:	2b893783          	ld	a5,696(s2)
    800034f2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034f4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034f8:	45848493          	add	s1,s1,1112
    800034fc:	fd349de3          	bne	s1,s3,800034d6 <binit+0x54>
  }
}
    80003500:	70a2                	ld	ra,40(sp)
    80003502:	7402                	ld	s0,32(sp)
    80003504:	64e2                	ld	s1,24(sp)
    80003506:	6942                	ld	s2,16(sp)
    80003508:	69a2                	ld	s3,8(sp)
    8000350a:	6a02                	ld	s4,0(sp)
    8000350c:	6145                	add	sp,sp,48
    8000350e:	8082                	ret

0000000080003510 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003510:	7179                	add	sp,sp,-48
    80003512:	f406                	sd	ra,40(sp)
    80003514:	f022                	sd	s0,32(sp)
    80003516:	ec26                	sd	s1,24(sp)
    80003518:	e84a                	sd	s2,16(sp)
    8000351a:	e44e                	sd	s3,8(sp)
    8000351c:	1800                	add	s0,sp,48
    8000351e:	892a                	mv	s2,a0
    80003520:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003522:	00034517          	auipc	a0,0x34
    80003526:	eae50513          	add	a0,a0,-338 # 800373d0 <bcache>
    8000352a:	ffffe097          	auipc	ra,0xffffe
    8000352e:	90e080e7          	jalr	-1778(ra) # 80000e38 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003532:	0003c497          	auipc	s1,0x3c
    80003536:	1564b483          	ld	s1,342(s1) # 8003f688 <bcache+0x82b8>
    8000353a:	0003c797          	auipc	a5,0x3c
    8000353e:	0fe78793          	add	a5,a5,254 # 8003f638 <bcache+0x8268>
    80003542:	02f48f63          	beq	s1,a5,80003580 <bread+0x70>
    80003546:	873e                	mv	a4,a5
    80003548:	a021                	j	80003550 <bread+0x40>
    8000354a:	68a4                	ld	s1,80(s1)
    8000354c:	02e48a63          	beq	s1,a4,80003580 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003550:	449c                	lw	a5,8(s1)
    80003552:	ff279ce3          	bne	a5,s2,8000354a <bread+0x3a>
    80003556:	44dc                	lw	a5,12(s1)
    80003558:	ff3799e3          	bne	a5,s3,8000354a <bread+0x3a>
      b->refcnt++;
    8000355c:	40bc                	lw	a5,64(s1)
    8000355e:	2785                	addw	a5,a5,1
    80003560:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003562:	00034517          	auipc	a0,0x34
    80003566:	e6e50513          	add	a0,a0,-402 # 800373d0 <bcache>
    8000356a:	ffffe097          	auipc	ra,0xffffe
    8000356e:	982080e7          	jalr	-1662(ra) # 80000eec <release>
      acquiresleep(&b->lock);
    80003572:	01048513          	add	a0,s1,16
    80003576:	00001097          	auipc	ra,0x1
    8000357a:	440080e7          	jalr	1088(ra) # 800049b6 <acquiresleep>
      return b;
    8000357e:	a8b9                	j	800035dc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003580:	0003c497          	auipc	s1,0x3c
    80003584:	1004b483          	ld	s1,256(s1) # 8003f680 <bcache+0x82b0>
    80003588:	0003c797          	auipc	a5,0x3c
    8000358c:	0b078793          	add	a5,a5,176 # 8003f638 <bcache+0x8268>
    80003590:	00f48863          	beq	s1,a5,800035a0 <bread+0x90>
    80003594:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003596:	40bc                	lw	a5,64(s1)
    80003598:	cf81                	beqz	a5,800035b0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000359a:	64a4                	ld	s1,72(s1)
    8000359c:	fee49de3          	bne	s1,a4,80003596 <bread+0x86>
  panic("bget: no buffers");
    800035a0:	00005517          	auipc	a0,0x5
    800035a4:	fa850513          	add	a0,a0,-88 # 80008548 <syscalls+0xd8>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	f94080e7          	jalr	-108(ra) # 8000053c <panic>
      b->dev = dev;
    800035b0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800035b4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800035b8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035bc:	4785                	li	a5,1
    800035be:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035c0:	00034517          	auipc	a0,0x34
    800035c4:	e1050513          	add	a0,a0,-496 # 800373d0 <bcache>
    800035c8:	ffffe097          	auipc	ra,0xffffe
    800035cc:	924080e7          	jalr	-1756(ra) # 80000eec <release>
      acquiresleep(&b->lock);
    800035d0:	01048513          	add	a0,s1,16
    800035d4:	00001097          	auipc	ra,0x1
    800035d8:	3e2080e7          	jalr	994(ra) # 800049b6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035dc:	409c                	lw	a5,0(s1)
    800035de:	cb89                	beqz	a5,800035f0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035e0:	8526                	mv	a0,s1
    800035e2:	70a2                	ld	ra,40(sp)
    800035e4:	7402                	ld	s0,32(sp)
    800035e6:	64e2                	ld	s1,24(sp)
    800035e8:	6942                	ld	s2,16(sp)
    800035ea:	69a2                	ld	s3,8(sp)
    800035ec:	6145                	add	sp,sp,48
    800035ee:	8082                	ret
    virtio_disk_rw(b, 0);
    800035f0:	4581                	li	a1,0
    800035f2:	8526                	mv	a0,s1
    800035f4:	00003097          	auipc	ra,0x3
    800035f8:	f9e080e7          	jalr	-98(ra) # 80006592 <virtio_disk_rw>
    b->valid = 1;
    800035fc:	4785                	li	a5,1
    800035fe:	c09c                	sw	a5,0(s1)
  return b;
    80003600:	b7c5                	j	800035e0 <bread+0xd0>

0000000080003602 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003602:	1101                	add	sp,sp,-32
    80003604:	ec06                	sd	ra,24(sp)
    80003606:	e822                	sd	s0,16(sp)
    80003608:	e426                	sd	s1,8(sp)
    8000360a:	1000                	add	s0,sp,32
    8000360c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000360e:	0541                	add	a0,a0,16
    80003610:	00001097          	auipc	ra,0x1
    80003614:	440080e7          	jalr	1088(ra) # 80004a50 <holdingsleep>
    80003618:	cd01                	beqz	a0,80003630 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000361a:	4585                	li	a1,1
    8000361c:	8526                	mv	a0,s1
    8000361e:	00003097          	auipc	ra,0x3
    80003622:	f74080e7          	jalr	-140(ra) # 80006592 <virtio_disk_rw>
}
    80003626:	60e2                	ld	ra,24(sp)
    80003628:	6442                	ld	s0,16(sp)
    8000362a:	64a2                	ld	s1,8(sp)
    8000362c:	6105                	add	sp,sp,32
    8000362e:	8082                	ret
    panic("bwrite");
    80003630:	00005517          	auipc	a0,0x5
    80003634:	f3050513          	add	a0,a0,-208 # 80008560 <syscalls+0xf0>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	f04080e7          	jalr	-252(ra) # 8000053c <panic>

0000000080003640 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003640:	1101                	add	sp,sp,-32
    80003642:	ec06                	sd	ra,24(sp)
    80003644:	e822                	sd	s0,16(sp)
    80003646:	e426                	sd	s1,8(sp)
    80003648:	e04a                	sd	s2,0(sp)
    8000364a:	1000                	add	s0,sp,32
    8000364c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000364e:	01050913          	add	s2,a0,16
    80003652:	854a                	mv	a0,s2
    80003654:	00001097          	auipc	ra,0x1
    80003658:	3fc080e7          	jalr	1020(ra) # 80004a50 <holdingsleep>
    8000365c:	c925                	beqz	a0,800036cc <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000365e:	854a                	mv	a0,s2
    80003660:	00001097          	auipc	ra,0x1
    80003664:	3ac080e7          	jalr	940(ra) # 80004a0c <releasesleep>

  acquire(&bcache.lock);
    80003668:	00034517          	auipc	a0,0x34
    8000366c:	d6850513          	add	a0,a0,-664 # 800373d0 <bcache>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	7c8080e7          	jalr	1992(ra) # 80000e38 <acquire>
  b->refcnt--;
    80003678:	40bc                	lw	a5,64(s1)
    8000367a:	37fd                	addw	a5,a5,-1
    8000367c:	0007871b          	sext.w	a4,a5
    80003680:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003682:	e71d                	bnez	a4,800036b0 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003684:	68b8                	ld	a4,80(s1)
    80003686:	64bc                	ld	a5,72(s1)
    80003688:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    8000368a:	68b8                	ld	a4,80(s1)
    8000368c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000368e:	0003c797          	auipc	a5,0x3c
    80003692:	d4278793          	add	a5,a5,-702 # 8003f3d0 <bcache+0x8000>
    80003696:	2b87b703          	ld	a4,696(a5)
    8000369a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000369c:	0003c717          	auipc	a4,0x3c
    800036a0:	f9c70713          	add	a4,a4,-100 # 8003f638 <bcache+0x8268>
    800036a4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036a6:	2b87b703          	ld	a4,696(a5)
    800036aa:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036ac:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036b0:	00034517          	auipc	a0,0x34
    800036b4:	d2050513          	add	a0,a0,-736 # 800373d0 <bcache>
    800036b8:	ffffe097          	auipc	ra,0xffffe
    800036bc:	834080e7          	jalr	-1996(ra) # 80000eec <release>
}
    800036c0:	60e2                	ld	ra,24(sp)
    800036c2:	6442                	ld	s0,16(sp)
    800036c4:	64a2                	ld	s1,8(sp)
    800036c6:	6902                	ld	s2,0(sp)
    800036c8:	6105                	add	sp,sp,32
    800036ca:	8082                	ret
    panic("brelse");
    800036cc:	00005517          	auipc	a0,0x5
    800036d0:	e9c50513          	add	a0,a0,-356 # 80008568 <syscalls+0xf8>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	e68080e7          	jalr	-408(ra) # 8000053c <panic>

00000000800036dc <bpin>:

void
bpin(struct buf *b) {
    800036dc:	1101                	add	sp,sp,-32
    800036de:	ec06                	sd	ra,24(sp)
    800036e0:	e822                	sd	s0,16(sp)
    800036e2:	e426                	sd	s1,8(sp)
    800036e4:	1000                	add	s0,sp,32
    800036e6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036e8:	00034517          	auipc	a0,0x34
    800036ec:	ce850513          	add	a0,a0,-792 # 800373d0 <bcache>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	748080e7          	jalr	1864(ra) # 80000e38 <acquire>
  b->refcnt++;
    800036f8:	40bc                	lw	a5,64(s1)
    800036fa:	2785                	addw	a5,a5,1
    800036fc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036fe:	00034517          	auipc	a0,0x34
    80003702:	cd250513          	add	a0,a0,-814 # 800373d0 <bcache>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	7e6080e7          	jalr	2022(ra) # 80000eec <release>
}
    8000370e:	60e2                	ld	ra,24(sp)
    80003710:	6442                	ld	s0,16(sp)
    80003712:	64a2                	ld	s1,8(sp)
    80003714:	6105                	add	sp,sp,32
    80003716:	8082                	ret

0000000080003718 <bunpin>:

void
bunpin(struct buf *b) {
    80003718:	1101                	add	sp,sp,-32
    8000371a:	ec06                	sd	ra,24(sp)
    8000371c:	e822                	sd	s0,16(sp)
    8000371e:	e426                	sd	s1,8(sp)
    80003720:	1000                	add	s0,sp,32
    80003722:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003724:	00034517          	auipc	a0,0x34
    80003728:	cac50513          	add	a0,a0,-852 # 800373d0 <bcache>
    8000372c:	ffffd097          	auipc	ra,0xffffd
    80003730:	70c080e7          	jalr	1804(ra) # 80000e38 <acquire>
  b->refcnt--;
    80003734:	40bc                	lw	a5,64(s1)
    80003736:	37fd                	addw	a5,a5,-1
    80003738:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000373a:	00034517          	auipc	a0,0x34
    8000373e:	c9650513          	add	a0,a0,-874 # 800373d0 <bcache>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	7aa080e7          	jalr	1962(ra) # 80000eec <release>
}
    8000374a:	60e2                	ld	ra,24(sp)
    8000374c:	6442                	ld	s0,16(sp)
    8000374e:	64a2                	ld	s1,8(sp)
    80003750:	6105                	add	sp,sp,32
    80003752:	8082                	ret

0000000080003754 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003754:	1101                	add	sp,sp,-32
    80003756:	ec06                	sd	ra,24(sp)
    80003758:	e822                	sd	s0,16(sp)
    8000375a:	e426                	sd	s1,8(sp)
    8000375c:	e04a                	sd	s2,0(sp)
    8000375e:	1000                	add	s0,sp,32
    80003760:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003762:	00d5d59b          	srlw	a1,a1,0xd
    80003766:	0003c797          	auipc	a5,0x3c
    8000376a:	3467a783          	lw	a5,838(a5) # 8003faac <sb+0x1c>
    8000376e:	9dbd                	addw	a1,a1,a5
    80003770:	00000097          	auipc	ra,0x0
    80003774:	da0080e7          	jalr	-608(ra) # 80003510 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003778:	0074f713          	and	a4,s1,7
    8000377c:	4785                	li	a5,1
    8000377e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003782:	14ce                	sll	s1,s1,0x33
    80003784:	90d9                	srl	s1,s1,0x36
    80003786:	00950733          	add	a4,a0,s1
    8000378a:	05874703          	lbu	a4,88(a4)
    8000378e:	00e7f6b3          	and	a3,a5,a4
    80003792:	c69d                	beqz	a3,800037c0 <bfree+0x6c>
    80003794:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003796:	94aa                	add	s1,s1,a0
    80003798:	fff7c793          	not	a5,a5
    8000379c:	8f7d                	and	a4,a4,a5
    8000379e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800037a2:	00001097          	auipc	ra,0x1
    800037a6:	0f6080e7          	jalr	246(ra) # 80004898 <log_write>
  brelse(bp);
    800037aa:	854a                	mv	a0,s2
    800037ac:	00000097          	auipc	ra,0x0
    800037b0:	e94080e7          	jalr	-364(ra) # 80003640 <brelse>
}
    800037b4:	60e2                	ld	ra,24(sp)
    800037b6:	6442                	ld	s0,16(sp)
    800037b8:	64a2                	ld	s1,8(sp)
    800037ba:	6902                	ld	s2,0(sp)
    800037bc:	6105                	add	sp,sp,32
    800037be:	8082                	ret
    panic("freeing free block");
    800037c0:	00005517          	auipc	a0,0x5
    800037c4:	db050513          	add	a0,a0,-592 # 80008570 <syscalls+0x100>
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	d74080e7          	jalr	-652(ra) # 8000053c <panic>

00000000800037d0 <balloc>:
{
    800037d0:	711d                	add	sp,sp,-96
    800037d2:	ec86                	sd	ra,88(sp)
    800037d4:	e8a2                	sd	s0,80(sp)
    800037d6:	e4a6                	sd	s1,72(sp)
    800037d8:	e0ca                	sd	s2,64(sp)
    800037da:	fc4e                	sd	s3,56(sp)
    800037dc:	f852                	sd	s4,48(sp)
    800037de:	f456                	sd	s5,40(sp)
    800037e0:	f05a                	sd	s6,32(sp)
    800037e2:	ec5e                	sd	s7,24(sp)
    800037e4:	e862                	sd	s8,16(sp)
    800037e6:	e466                	sd	s9,8(sp)
    800037e8:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037ea:	0003c797          	auipc	a5,0x3c
    800037ee:	2aa7a783          	lw	a5,682(a5) # 8003fa94 <sb+0x4>
    800037f2:	cff5                	beqz	a5,800038ee <balloc+0x11e>
    800037f4:	8baa                	mv	s7,a0
    800037f6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037f8:	0003cb17          	auipc	s6,0x3c
    800037fc:	298b0b13          	add	s6,s6,664 # 8003fa90 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003800:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003802:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003804:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003806:	6c89                	lui	s9,0x2
    80003808:	a061                	j	80003890 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000380a:	97ca                	add	a5,a5,s2
    8000380c:	8e55                	or	a2,a2,a3
    8000380e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003812:	854a                	mv	a0,s2
    80003814:	00001097          	auipc	ra,0x1
    80003818:	084080e7          	jalr	132(ra) # 80004898 <log_write>
        brelse(bp);
    8000381c:	854a                	mv	a0,s2
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	e22080e7          	jalr	-478(ra) # 80003640 <brelse>
  bp = bread(dev, bno);
    80003826:	85a6                	mv	a1,s1
    80003828:	855e                	mv	a0,s7
    8000382a:	00000097          	auipc	ra,0x0
    8000382e:	ce6080e7          	jalr	-794(ra) # 80003510 <bread>
    80003832:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003834:	40000613          	li	a2,1024
    80003838:	4581                	li	a1,0
    8000383a:	05850513          	add	a0,a0,88
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	6f6080e7          	jalr	1782(ra) # 80000f34 <memset>
  log_write(bp);
    80003846:	854a                	mv	a0,s2
    80003848:	00001097          	auipc	ra,0x1
    8000384c:	050080e7          	jalr	80(ra) # 80004898 <log_write>
  brelse(bp);
    80003850:	854a                	mv	a0,s2
    80003852:	00000097          	auipc	ra,0x0
    80003856:	dee080e7          	jalr	-530(ra) # 80003640 <brelse>
}
    8000385a:	8526                	mv	a0,s1
    8000385c:	60e6                	ld	ra,88(sp)
    8000385e:	6446                	ld	s0,80(sp)
    80003860:	64a6                	ld	s1,72(sp)
    80003862:	6906                	ld	s2,64(sp)
    80003864:	79e2                	ld	s3,56(sp)
    80003866:	7a42                	ld	s4,48(sp)
    80003868:	7aa2                	ld	s5,40(sp)
    8000386a:	7b02                	ld	s6,32(sp)
    8000386c:	6be2                	ld	s7,24(sp)
    8000386e:	6c42                	ld	s8,16(sp)
    80003870:	6ca2                	ld	s9,8(sp)
    80003872:	6125                	add	sp,sp,96
    80003874:	8082                	ret
    brelse(bp);
    80003876:	854a                	mv	a0,s2
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	dc8080e7          	jalr	-568(ra) # 80003640 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003880:	015c87bb          	addw	a5,s9,s5
    80003884:	00078a9b          	sext.w	s5,a5
    80003888:	004b2703          	lw	a4,4(s6)
    8000388c:	06eaf163          	bgeu	s5,a4,800038ee <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003890:	41fad79b          	sraw	a5,s5,0x1f
    80003894:	0137d79b          	srlw	a5,a5,0x13
    80003898:	015787bb          	addw	a5,a5,s5
    8000389c:	40d7d79b          	sraw	a5,a5,0xd
    800038a0:	01cb2583          	lw	a1,28(s6)
    800038a4:	9dbd                	addw	a1,a1,a5
    800038a6:	855e                	mv	a0,s7
    800038a8:	00000097          	auipc	ra,0x0
    800038ac:	c68080e7          	jalr	-920(ra) # 80003510 <bread>
    800038b0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038b2:	004b2503          	lw	a0,4(s6)
    800038b6:	000a849b          	sext.w	s1,s5
    800038ba:	8762                	mv	a4,s8
    800038bc:	faa4fde3          	bgeu	s1,a0,80003876 <balloc+0xa6>
      m = 1 << (bi % 8);
    800038c0:	00777693          	and	a3,a4,7
    800038c4:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800038c8:	41f7579b          	sraw	a5,a4,0x1f
    800038cc:	01d7d79b          	srlw	a5,a5,0x1d
    800038d0:	9fb9                	addw	a5,a5,a4
    800038d2:	4037d79b          	sraw	a5,a5,0x3
    800038d6:	00f90633          	add	a2,s2,a5
    800038da:	05864603          	lbu	a2,88(a2)
    800038de:	00c6f5b3          	and	a1,a3,a2
    800038e2:	d585                	beqz	a1,8000380a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038e4:	2705                	addw	a4,a4,1
    800038e6:	2485                	addw	s1,s1,1
    800038e8:	fd471ae3          	bne	a4,s4,800038bc <balloc+0xec>
    800038ec:	b769                	j	80003876 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800038ee:	00005517          	auipc	a0,0x5
    800038f2:	c9a50513          	add	a0,a0,-870 # 80008588 <syscalls+0x118>
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	c90080e7          	jalr	-880(ra) # 80000586 <printf>
  return 0;
    800038fe:	4481                	li	s1,0
    80003900:	bfa9                	j	8000385a <balloc+0x8a>

0000000080003902 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003902:	7179                	add	sp,sp,-48
    80003904:	f406                	sd	ra,40(sp)
    80003906:	f022                	sd	s0,32(sp)
    80003908:	ec26                	sd	s1,24(sp)
    8000390a:	e84a                	sd	s2,16(sp)
    8000390c:	e44e                	sd	s3,8(sp)
    8000390e:	e052                	sd	s4,0(sp)
    80003910:	1800                	add	s0,sp,48
    80003912:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003914:	47ad                	li	a5,11
    80003916:	02b7e863          	bltu	a5,a1,80003946 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000391a:	02059793          	sll	a5,a1,0x20
    8000391e:	01e7d593          	srl	a1,a5,0x1e
    80003922:	00b504b3          	add	s1,a0,a1
    80003926:	0504a903          	lw	s2,80(s1)
    8000392a:	06091e63          	bnez	s2,800039a6 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000392e:	4108                	lw	a0,0(a0)
    80003930:	00000097          	auipc	ra,0x0
    80003934:	ea0080e7          	jalr	-352(ra) # 800037d0 <balloc>
    80003938:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000393c:	06090563          	beqz	s2,800039a6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003940:	0524a823          	sw	s2,80(s1)
    80003944:	a08d                	j	800039a6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003946:	ff45849b          	addw	s1,a1,-12
    8000394a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000394e:	0ff00793          	li	a5,255
    80003952:	08e7e563          	bltu	a5,a4,800039dc <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003956:	08052903          	lw	s2,128(a0)
    8000395a:	00091d63          	bnez	s2,80003974 <bmap+0x72>
      addr = balloc(ip->dev);
    8000395e:	4108                	lw	a0,0(a0)
    80003960:	00000097          	auipc	ra,0x0
    80003964:	e70080e7          	jalr	-400(ra) # 800037d0 <balloc>
    80003968:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000396c:	02090d63          	beqz	s2,800039a6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003970:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003974:	85ca                	mv	a1,s2
    80003976:	0009a503          	lw	a0,0(s3)
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	b96080e7          	jalr	-1130(ra) # 80003510 <bread>
    80003982:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003984:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    80003988:	02049713          	sll	a4,s1,0x20
    8000398c:	01e75593          	srl	a1,a4,0x1e
    80003990:	00b784b3          	add	s1,a5,a1
    80003994:	0004a903          	lw	s2,0(s1)
    80003998:	02090063          	beqz	s2,800039b8 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000399c:	8552                	mv	a0,s4
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	ca2080e7          	jalr	-862(ra) # 80003640 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800039a6:	854a                	mv	a0,s2
    800039a8:	70a2                	ld	ra,40(sp)
    800039aa:	7402                	ld	s0,32(sp)
    800039ac:	64e2                	ld	s1,24(sp)
    800039ae:	6942                	ld	s2,16(sp)
    800039b0:	69a2                	ld	s3,8(sp)
    800039b2:	6a02                	ld	s4,0(sp)
    800039b4:	6145                	add	sp,sp,48
    800039b6:	8082                	ret
      addr = balloc(ip->dev);
    800039b8:	0009a503          	lw	a0,0(s3)
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	e14080e7          	jalr	-492(ra) # 800037d0 <balloc>
    800039c4:	0005091b          	sext.w	s2,a0
      if(addr){
    800039c8:	fc090ae3          	beqz	s2,8000399c <bmap+0x9a>
        a[bn] = addr;
    800039cc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800039d0:	8552                	mv	a0,s4
    800039d2:	00001097          	auipc	ra,0x1
    800039d6:	ec6080e7          	jalr	-314(ra) # 80004898 <log_write>
    800039da:	b7c9                	j	8000399c <bmap+0x9a>
  panic("bmap: out of range");
    800039dc:	00005517          	auipc	a0,0x5
    800039e0:	bc450513          	add	a0,a0,-1084 # 800085a0 <syscalls+0x130>
    800039e4:	ffffd097          	auipc	ra,0xffffd
    800039e8:	b58080e7          	jalr	-1192(ra) # 8000053c <panic>

00000000800039ec <iget>:
{
    800039ec:	7179                	add	sp,sp,-48
    800039ee:	f406                	sd	ra,40(sp)
    800039f0:	f022                	sd	s0,32(sp)
    800039f2:	ec26                	sd	s1,24(sp)
    800039f4:	e84a                	sd	s2,16(sp)
    800039f6:	e44e                	sd	s3,8(sp)
    800039f8:	e052                	sd	s4,0(sp)
    800039fa:	1800                	add	s0,sp,48
    800039fc:	89aa                	mv	s3,a0
    800039fe:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a00:	0003c517          	auipc	a0,0x3c
    80003a04:	0b050513          	add	a0,a0,176 # 8003fab0 <itable>
    80003a08:	ffffd097          	auipc	ra,0xffffd
    80003a0c:	430080e7          	jalr	1072(ra) # 80000e38 <acquire>
  empty = 0;
    80003a10:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a12:	0003c497          	auipc	s1,0x3c
    80003a16:	0b648493          	add	s1,s1,182 # 8003fac8 <itable+0x18>
    80003a1a:	0003e697          	auipc	a3,0x3e
    80003a1e:	b3e68693          	add	a3,a3,-1218 # 80041558 <log>
    80003a22:	a039                	j	80003a30 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a24:	02090b63          	beqz	s2,80003a5a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a28:	08848493          	add	s1,s1,136
    80003a2c:	02d48a63          	beq	s1,a3,80003a60 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a30:	449c                	lw	a5,8(s1)
    80003a32:	fef059e3          	blez	a5,80003a24 <iget+0x38>
    80003a36:	4098                	lw	a4,0(s1)
    80003a38:	ff3716e3          	bne	a4,s3,80003a24 <iget+0x38>
    80003a3c:	40d8                	lw	a4,4(s1)
    80003a3e:	ff4713e3          	bne	a4,s4,80003a24 <iget+0x38>
      ip->ref++;
    80003a42:	2785                	addw	a5,a5,1
    80003a44:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a46:	0003c517          	auipc	a0,0x3c
    80003a4a:	06a50513          	add	a0,a0,106 # 8003fab0 <itable>
    80003a4e:	ffffd097          	auipc	ra,0xffffd
    80003a52:	49e080e7          	jalr	1182(ra) # 80000eec <release>
      return ip;
    80003a56:	8926                	mv	s2,s1
    80003a58:	a03d                	j	80003a86 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a5a:	f7f9                	bnez	a5,80003a28 <iget+0x3c>
    80003a5c:	8926                	mv	s2,s1
    80003a5e:	b7e9                	j	80003a28 <iget+0x3c>
  if(empty == 0)
    80003a60:	02090c63          	beqz	s2,80003a98 <iget+0xac>
  ip->dev = dev;
    80003a64:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a68:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a6c:	4785                	li	a5,1
    80003a6e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a72:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a76:	0003c517          	auipc	a0,0x3c
    80003a7a:	03a50513          	add	a0,a0,58 # 8003fab0 <itable>
    80003a7e:	ffffd097          	auipc	ra,0xffffd
    80003a82:	46e080e7          	jalr	1134(ra) # 80000eec <release>
}
    80003a86:	854a                	mv	a0,s2
    80003a88:	70a2                	ld	ra,40(sp)
    80003a8a:	7402                	ld	s0,32(sp)
    80003a8c:	64e2                	ld	s1,24(sp)
    80003a8e:	6942                	ld	s2,16(sp)
    80003a90:	69a2                	ld	s3,8(sp)
    80003a92:	6a02                	ld	s4,0(sp)
    80003a94:	6145                	add	sp,sp,48
    80003a96:	8082                	ret
    panic("iget: no inodes");
    80003a98:	00005517          	auipc	a0,0x5
    80003a9c:	b2050513          	add	a0,a0,-1248 # 800085b8 <syscalls+0x148>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	a9c080e7          	jalr	-1380(ra) # 8000053c <panic>

0000000080003aa8 <fsinit>:
fsinit(int dev) {
    80003aa8:	7179                	add	sp,sp,-48
    80003aaa:	f406                	sd	ra,40(sp)
    80003aac:	f022                	sd	s0,32(sp)
    80003aae:	ec26                	sd	s1,24(sp)
    80003ab0:	e84a                	sd	s2,16(sp)
    80003ab2:	e44e                	sd	s3,8(sp)
    80003ab4:	1800                	add	s0,sp,48
    80003ab6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003ab8:	4585                	li	a1,1
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	a56080e7          	jalr	-1450(ra) # 80003510 <bread>
    80003ac2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ac4:	0003c997          	auipc	s3,0x3c
    80003ac8:	fcc98993          	add	s3,s3,-52 # 8003fa90 <sb>
    80003acc:	02000613          	li	a2,32
    80003ad0:	05850593          	add	a1,a0,88
    80003ad4:	854e                	mv	a0,s3
    80003ad6:	ffffd097          	auipc	ra,0xffffd
    80003ada:	4ba080e7          	jalr	1210(ra) # 80000f90 <memmove>
  brelse(bp);
    80003ade:	8526                	mv	a0,s1
    80003ae0:	00000097          	auipc	ra,0x0
    80003ae4:	b60080e7          	jalr	-1184(ra) # 80003640 <brelse>
  if(sb.magic != FSMAGIC)
    80003ae8:	0009a703          	lw	a4,0(s3)
    80003aec:	102037b7          	lui	a5,0x10203
    80003af0:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003af4:	02f71263          	bne	a4,a5,80003b18 <fsinit+0x70>
  initlog(dev, &sb);
    80003af8:	0003c597          	auipc	a1,0x3c
    80003afc:	f9858593          	add	a1,a1,-104 # 8003fa90 <sb>
    80003b00:	854a                	mv	a0,s2
    80003b02:	00001097          	auipc	ra,0x1
    80003b06:	b2c080e7          	jalr	-1236(ra) # 8000462e <initlog>
}
    80003b0a:	70a2                	ld	ra,40(sp)
    80003b0c:	7402                	ld	s0,32(sp)
    80003b0e:	64e2                	ld	s1,24(sp)
    80003b10:	6942                	ld	s2,16(sp)
    80003b12:	69a2                	ld	s3,8(sp)
    80003b14:	6145                	add	sp,sp,48
    80003b16:	8082                	ret
    panic("invalid file system");
    80003b18:	00005517          	auipc	a0,0x5
    80003b1c:	ab050513          	add	a0,a0,-1360 # 800085c8 <syscalls+0x158>
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	a1c080e7          	jalr	-1508(ra) # 8000053c <panic>

0000000080003b28 <iinit>:
{
    80003b28:	7179                	add	sp,sp,-48
    80003b2a:	f406                	sd	ra,40(sp)
    80003b2c:	f022                	sd	s0,32(sp)
    80003b2e:	ec26                	sd	s1,24(sp)
    80003b30:	e84a                	sd	s2,16(sp)
    80003b32:	e44e                	sd	s3,8(sp)
    80003b34:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b36:	00005597          	auipc	a1,0x5
    80003b3a:	aaa58593          	add	a1,a1,-1366 # 800085e0 <syscalls+0x170>
    80003b3e:	0003c517          	auipc	a0,0x3c
    80003b42:	f7250513          	add	a0,a0,-142 # 8003fab0 <itable>
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	262080e7          	jalr	610(ra) # 80000da8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b4e:	0003c497          	auipc	s1,0x3c
    80003b52:	f8a48493          	add	s1,s1,-118 # 8003fad8 <itable+0x28>
    80003b56:	0003e997          	auipc	s3,0x3e
    80003b5a:	a1298993          	add	s3,s3,-1518 # 80041568 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b5e:	00005917          	auipc	s2,0x5
    80003b62:	a8a90913          	add	s2,s2,-1398 # 800085e8 <syscalls+0x178>
    80003b66:	85ca                	mv	a1,s2
    80003b68:	8526                	mv	a0,s1
    80003b6a:	00001097          	auipc	ra,0x1
    80003b6e:	e12080e7          	jalr	-494(ra) # 8000497c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b72:	08848493          	add	s1,s1,136
    80003b76:	ff3498e3          	bne	s1,s3,80003b66 <iinit+0x3e>
}
    80003b7a:	70a2                	ld	ra,40(sp)
    80003b7c:	7402                	ld	s0,32(sp)
    80003b7e:	64e2                	ld	s1,24(sp)
    80003b80:	6942                	ld	s2,16(sp)
    80003b82:	69a2                	ld	s3,8(sp)
    80003b84:	6145                	add	sp,sp,48
    80003b86:	8082                	ret

0000000080003b88 <ialloc>:
{
    80003b88:	7139                	add	sp,sp,-64
    80003b8a:	fc06                	sd	ra,56(sp)
    80003b8c:	f822                	sd	s0,48(sp)
    80003b8e:	f426                	sd	s1,40(sp)
    80003b90:	f04a                	sd	s2,32(sp)
    80003b92:	ec4e                	sd	s3,24(sp)
    80003b94:	e852                	sd	s4,16(sp)
    80003b96:	e456                	sd	s5,8(sp)
    80003b98:	e05a                	sd	s6,0(sp)
    80003b9a:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b9c:	0003c717          	auipc	a4,0x3c
    80003ba0:	f0072703          	lw	a4,-256(a4) # 8003fa9c <sb+0xc>
    80003ba4:	4785                	li	a5,1
    80003ba6:	04e7f863          	bgeu	a5,a4,80003bf6 <ialloc+0x6e>
    80003baa:	8aaa                	mv	s5,a0
    80003bac:	8b2e                	mv	s6,a1
    80003bae:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003bb0:	0003ca17          	auipc	s4,0x3c
    80003bb4:	ee0a0a13          	add	s4,s4,-288 # 8003fa90 <sb>
    80003bb8:	00495593          	srl	a1,s2,0x4
    80003bbc:	018a2783          	lw	a5,24(s4)
    80003bc0:	9dbd                	addw	a1,a1,a5
    80003bc2:	8556                	mv	a0,s5
    80003bc4:	00000097          	auipc	ra,0x0
    80003bc8:	94c080e7          	jalr	-1716(ra) # 80003510 <bread>
    80003bcc:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bce:	05850993          	add	s3,a0,88
    80003bd2:	00f97793          	and	a5,s2,15
    80003bd6:	079a                	sll	a5,a5,0x6
    80003bd8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bda:	00099783          	lh	a5,0(s3)
    80003bde:	cf9d                	beqz	a5,80003c1c <ialloc+0x94>
    brelse(bp);
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	a60080e7          	jalr	-1440(ra) # 80003640 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003be8:	0905                	add	s2,s2,1
    80003bea:	00ca2703          	lw	a4,12(s4)
    80003bee:	0009079b          	sext.w	a5,s2
    80003bf2:	fce7e3e3          	bltu	a5,a4,80003bb8 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003bf6:	00005517          	auipc	a0,0x5
    80003bfa:	9fa50513          	add	a0,a0,-1542 # 800085f0 <syscalls+0x180>
    80003bfe:	ffffd097          	auipc	ra,0xffffd
    80003c02:	988080e7          	jalr	-1656(ra) # 80000586 <printf>
  return 0;
    80003c06:	4501                	li	a0,0
}
    80003c08:	70e2                	ld	ra,56(sp)
    80003c0a:	7442                	ld	s0,48(sp)
    80003c0c:	74a2                	ld	s1,40(sp)
    80003c0e:	7902                	ld	s2,32(sp)
    80003c10:	69e2                	ld	s3,24(sp)
    80003c12:	6a42                	ld	s4,16(sp)
    80003c14:	6aa2                	ld	s5,8(sp)
    80003c16:	6b02                	ld	s6,0(sp)
    80003c18:	6121                	add	sp,sp,64
    80003c1a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c1c:	04000613          	li	a2,64
    80003c20:	4581                	li	a1,0
    80003c22:	854e                	mv	a0,s3
    80003c24:	ffffd097          	auipc	ra,0xffffd
    80003c28:	310080e7          	jalr	784(ra) # 80000f34 <memset>
      dip->type = type;
    80003c2c:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c30:	8526                	mv	a0,s1
    80003c32:	00001097          	auipc	ra,0x1
    80003c36:	c66080e7          	jalr	-922(ra) # 80004898 <log_write>
      brelse(bp);
    80003c3a:	8526                	mv	a0,s1
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	a04080e7          	jalr	-1532(ra) # 80003640 <brelse>
      return iget(dev, inum);
    80003c44:	0009059b          	sext.w	a1,s2
    80003c48:	8556                	mv	a0,s5
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	da2080e7          	jalr	-606(ra) # 800039ec <iget>
    80003c52:	bf5d                	j	80003c08 <ialloc+0x80>

0000000080003c54 <iupdate>:
{
    80003c54:	1101                	add	sp,sp,-32
    80003c56:	ec06                	sd	ra,24(sp)
    80003c58:	e822                	sd	s0,16(sp)
    80003c5a:	e426                	sd	s1,8(sp)
    80003c5c:	e04a                	sd	s2,0(sp)
    80003c5e:	1000                	add	s0,sp,32
    80003c60:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c62:	415c                	lw	a5,4(a0)
    80003c64:	0047d79b          	srlw	a5,a5,0x4
    80003c68:	0003c597          	auipc	a1,0x3c
    80003c6c:	e405a583          	lw	a1,-448(a1) # 8003faa8 <sb+0x18>
    80003c70:	9dbd                	addw	a1,a1,a5
    80003c72:	4108                	lw	a0,0(a0)
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	89c080e7          	jalr	-1892(ra) # 80003510 <bread>
    80003c7c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c7e:	05850793          	add	a5,a0,88
    80003c82:	40d8                	lw	a4,4(s1)
    80003c84:	8b3d                	and	a4,a4,15
    80003c86:	071a                	sll	a4,a4,0x6
    80003c88:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003c8a:	04449703          	lh	a4,68(s1)
    80003c8e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003c92:	04649703          	lh	a4,70(s1)
    80003c96:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003c9a:	04849703          	lh	a4,72(s1)
    80003c9e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003ca2:	04a49703          	lh	a4,74(s1)
    80003ca6:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003caa:	44f8                	lw	a4,76(s1)
    80003cac:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cae:	03400613          	li	a2,52
    80003cb2:	05048593          	add	a1,s1,80
    80003cb6:	00c78513          	add	a0,a5,12
    80003cba:	ffffd097          	auipc	ra,0xffffd
    80003cbe:	2d6080e7          	jalr	726(ra) # 80000f90 <memmove>
  log_write(bp);
    80003cc2:	854a                	mv	a0,s2
    80003cc4:	00001097          	auipc	ra,0x1
    80003cc8:	bd4080e7          	jalr	-1068(ra) # 80004898 <log_write>
  brelse(bp);
    80003ccc:	854a                	mv	a0,s2
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	972080e7          	jalr	-1678(ra) # 80003640 <brelse>
}
    80003cd6:	60e2                	ld	ra,24(sp)
    80003cd8:	6442                	ld	s0,16(sp)
    80003cda:	64a2                	ld	s1,8(sp)
    80003cdc:	6902                	ld	s2,0(sp)
    80003cde:	6105                	add	sp,sp,32
    80003ce0:	8082                	ret

0000000080003ce2 <idup>:
{
    80003ce2:	1101                	add	sp,sp,-32
    80003ce4:	ec06                	sd	ra,24(sp)
    80003ce6:	e822                	sd	s0,16(sp)
    80003ce8:	e426                	sd	s1,8(sp)
    80003cea:	1000                	add	s0,sp,32
    80003cec:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cee:	0003c517          	auipc	a0,0x3c
    80003cf2:	dc250513          	add	a0,a0,-574 # 8003fab0 <itable>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	142080e7          	jalr	322(ra) # 80000e38 <acquire>
  ip->ref++;
    80003cfe:	449c                	lw	a5,8(s1)
    80003d00:	2785                	addw	a5,a5,1
    80003d02:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d04:	0003c517          	auipc	a0,0x3c
    80003d08:	dac50513          	add	a0,a0,-596 # 8003fab0 <itable>
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	1e0080e7          	jalr	480(ra) # 80000eec <release>
}
    80003d14:	8526                	mv	a0,s1
    80003d16:	60e2                	ld	ra,24(sp)
    80003d18:	6442                	ld	s0,16(sp)
    80003d1a:	64a2                	ld	s1,8(sp)
    80003d1c:	6105                	add	sp,sp,32
    80003d1e:	8082                	ret

0000000080003d20 <ilock>:
{
    80003d20:	1101                	add	sp,sp,-32
    80003d22:	ec06                	sd	ra,24(sp)
    80003d24:	e822                	sd	s0,16(sp)
    80003d26:	e426                	sd	s1,8(sp)
    80003d28:	e04a                	sd	s2,0(sp)
    80003d2a:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d2c:	c115                	beqz	a0,80003d50 <ilock+0x30>
    80003d2e:	84aa                	mv	s1,a0
    80003d30:	451c                	lw	a5,8(a0)
    80003d32:	00f05f63          	blez	a5,80003d50 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d36:	0541                	add	a0,a0,16
    80003d38:	00001097          	auipc	ra,0x1
    80003d3c:	c7e080e7          	jalr	-898(ra) # 800049b6 <acquiresleep>
  if(ip->valid == 0){
    80003d40:	40bc                	lw	a5,64(s1)
    80003d42:	cf99                	beqz	a5,80003d60 <ilock+0x40>
}
    80003d44:	60e2                	ld	ra,24(sp)
    80003d46:	6442                	ld	s0,16(sp)
    80003d48:	64a2                	ld	s1,8(sp)
    80003d4a:	6902                	ld	s2,0(sp)
    80003d4c:	6105                	add	sp,sp,32
    80003d4e:	8082                	ret
    panic("ilock");
    80003d50:	00005517          	auipc	a0,0x5
    80003d54:	8b850513          	add	a0,a0,-1864 # 80008608 <syscalls+0x198>
    80003d58:	ffffc097          	auipc	ra,0xffffc
    80003d5c:	7e4080e7          	jalr	2020(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d60:	40dc                	lw	a5,4(s1)
    80003d62:	0047d79b          	srlw	a5,a5,0x4
    80003d66:	0003c597          	auipc	a1,0x3c
    80003d6a:	d425a583          	lw	a1,-702(a1) # 8003faa8 <sb+0x18>
    80003d6e:	9dbd                	addw	a1,a1,a5
    80003d70:	4088                	lw	a0,0(s1)
    80003d72:	fffff097          	auipc	ra,0xfffff
    80003d76:	79e080e7          	jalr	1950(ra) # 80003510 <bread>
    80003d7a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d7c:	05850593          	add	a1,a0,88
    80003d80:	40dc                	lw	a5,4(s1)
    80003d82:	8bbd                	and	a5,a5,15
    80003d84:	079a                	sll	a5,a5,0x6
    80003d86:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d88:	00059783          	lh	a5,0(a1)
    80003d8c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d90:	00259783          	lh	a5,2(a1)
    80003d94:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d98:	00459783          	lh	a5,4(a1)
    80003d9c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003da0:	00659783          	lh	a5,6(a1)
    80003da4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003da8:	459c                	lw	a5,8(a1)
    80003daa:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003dac:	03400613          	li	a2,52
    80003db0:	05b1                	add	a1,a1,12
    80003db2:	05048513          	add	a0,s1,80
    80003db6:	ffffd097          	auipc	ra,0xffffd
    80003dba:	1da080e7          	jalr	474(ra) # 80000f90 <memmove>
    brelse(bp);
    80003dbe:	854a                	mv	a0,s2
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	880080e7          	jalr	-1920(ra) # 80003640 <brelse>
    ip->valid = 1;
    80003dc8:	4785                	li	a5,1
    80003dca:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003dcc:	04449783          	lh	a5,68(s1)
    80003dd0:	fbb5                	bnez	a5,80003d44 <ilock+0x24>
      panic("ilock: no type");
    80003dd2:	00005517          	auipc	a0,0x5
    80003dd6:	83e50513          	add	a0,a0,-1986 # 80008610 <syscalls+0x1a0>
    80003dda:	ffffc097          	auipc	ra,0xffffc
    80003dde:	762080e7          	jalr	1890(ra) # 8000053c <panic>

0000000080003de2 <iunlock>:
{
    80003de2:	1101                	add	sp,sp,-32
    80003de4:	ec06                	sd	ra,24(sp)
    80003de6:	e822                	sd	s0,16(sp)
    80003de8:	e426                	sd	s1,8(sp)
    80003dea:	e04a                	sd	s2,0(sp)
    80003dec:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dee:	c905                	beqz	a0,80003e1e <iunlock+0x3c>
    80003df0:	84aa                	mv	s1,a0
    80003df2:	01050913          	add	s2,a0,16
    80003df6:	854a                	mv	a0,s2
    80003df8:	00001097          	auipc	ra,0x1
    80003dfc:	c58080e7          	jalr	-936(ra) # 80004a50 <holdingsleep>
    80003e00:	cd19                	beqz	a0,80003e1e <iunlock+0x3c>
    80003e02:	449c                	lw	a5,8(s1)
    80003e04:	00f05d63          	blez	a5,80003e1e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e08:	854a                	mv	a0,s2
    80003e0a:	00001097          	auipc	ra,0x1
    80003e0e:	c02080e7          	jalr	-1022(ra) # 80004a0c <releasesleep>
}
    80003e12:	60e2                	ld	ra,24(sp)
    80003e14:	6442                	ld	s0,16(sp)
    80003e16:	64a2                	ld	s1,8(sp)
    80003e18:	6902                	ld	s2,0(sp)
    80003e1a:	6105                	add	sp,sp,32
    80003e1c:	8082                	ret
    panic("iunlock");
    80003e1e:	00005517          	auipc	a0,0x5
    80003e22:	80250513          	add	a0,a0,-2046 # 80008620 <syscalls+0x1b0>
    80003e26:	ffffc097          	auipc	ra,0xffffc
    80003e2a:	716080e7          	jalr	1814(ra) # 8000053c <panic>

0000000080003e2e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e2e:	7179                	add	sp,sp,-48
    80003e30:	f406                	sd	ra,40(sp)
    80003e32:	f022                	sd	s0,32(sp)
    80003e34:	ec26                	sd	s1,24(sp)
    80003e36:	e84a                	sd	s2,16(sp)
    80003e38:	e44e                	sd	s3,8(sp)
    80003e3a:	e052                	sd	s4,0(sp)
    80003e3c:	1800                	add	s0,sp,48
    80003e3e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e40:	05050493          	add	s1,a0,80
    80003e44:	08050913          	add	s2,a0,128
    80003e48:	a021                	j	80003e50 <itrunc+0x22>
    80003e4a:	0491                	add	s1,s1,4
    80003e4c:	01248d63          	beq	s1,s2,80003e66 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e50:	408c                	lw	a1,0(s1)
    80003e52:	dde5                	beqz	a1,80003e4a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e54:	0009a503          	lw	a0,0(s3)
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	8fc080e7          	jalr	-1796(ra) # 80003754 <bfree>
      ip->addrs[i] = 0;
    80003e60:	0004a023          	sw	zero,0(s1)
    80003e64:	b7dd                	j	80003e4a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e66:	0809a583          	lw	a1,128(s3)
    80003e6a:	e185                	bnez	a1,80003e8a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e6c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e70:	854e                	mv	a0,s3
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	de2080e7          	jalr	-542(ra) # 80003c54 <iupdate>
}
    80003e7a:	70a2                	ld	ra,40(sp)
    80003e7c:	7402                	ld	s0,32(sp)
    80003e7e:	64e2                	ld	s1,24(sp)
    80003e80:	6942                	ld	s2,16(sp)
    80003e82:	69a2                	ld	s3,8(sp)
    80003e84:	6a02                	ld	s4,0(sp)
    80003e86:	6145                	add	sp,sp,48
    80003e88:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e8a:	0009a503          	lw	a0,0(s3)
    80003e8e:	fffff097          	auipc	ra,0xfffff
    80003e92:	682080e7          	jalr	1666(ra) # 80003510 <bread>
    80003e96:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e98:	05850493          	add	s1,a0,88
    80003e9c:	45850913          	add	s2,a0,1112
    80003ea0:	a021                	j	80003ea8 <itrunc+0x7a>
    80003ea2:	0491                	add	s1,s1,4
    80003ea4:	01248b63          	beq	s1,s2,80003eba <itrunc+0x8c>
      if(a[j])
    80003ea8:	408c                	lw	a1,0(s1)
    80003eaa:	dde5                	beqz	a1,80003ea2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003eac:	0009a503          	lw	a0,0(s3)
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	8a4080e7          	jalr	-1884(ra) # 80003754 <bfree>
    80003eb8:	b7ed                	j	80003ea2 <itrunc+0x74>
    brelse(bp);
    80003eba:	8552                	mv	a0,s4
    80003ebc:	fffff097          	auipc	ra,0xfffff
    80003ec0:	784080e7          	jalr	1924(ra) # 80003640 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ec4:	0809a583          	lw	a1,128(s3)
    80003ec8:	0009a503          	lw	a0,0(s3)
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	888080e7          	jalr	-1912(ra) # 80003754 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ed4:	0809a023          	sw	zero,128(s3)
    80003ed8:	bf51                	j	80003e6c <itrunc+0x3e>

0000000080003eda <iput>:
{
    80003eda:	1101                	add	sp,sp,-32
    80003edc:	ec06                	sd	ra,24(sp)
    80003ede:	e822                	sd	s0,16(sp)
    80003ee0:	e426                	sd	s1,8(sp)
    80003ee2:	e04a                	sd	s2,0(sp)
    80003ee4:	1000                	add	s0,sp,32
    80003ee6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ee8:	0003c517          	auipc	a0,0x3c
    80003eec:	bc850513          	add	a0,a0,-1080 # 8003fab0 <itable>
    80003ef0:	ffffd097          	auipc	ra,0xffffd
    80003ef4:	f48080e7          	jalr	-184(ra) # 80000e38 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ef8:	4498                	lw	a4,8(s1)
    80003efa:	4785                	li	a5,1
    80003efc:	02f70363          	beq	a4,a5,80003f22 <iput+0x48>
  ip->ref--;
    80003f00:	449c                	lw	a5,8(s1)
    80003f02:	37fd                	addw	a5,a5,-1
    80003f04:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f06:	0003c517          	auipc	a0,0x3c
    80003f0a:	baa50513          	add	a0,a0,-1110 # 8003fab0 <itable>
    80003f0e:	ffffd097          	auipc	ra,0xffffd
    80003f12:	fde080e7          	jalr	-34(ra) # 80000eec <release>
}
    80003f16:	60e2                	ld	ra,24(sp)
    80003f18:	6442                	ld	s0,16(sp)
    80003f1a:	64a2                	ld	s1,8(sp)
    80003f1c:	6902                	ld	s2,0(sp)
    80003f1e:	6105                	add	sp,sp,32
    80003f20:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f22:	40bc                	lw	a5,64(s1)
    80003f24:	dff1                	beqz	a5,80003f00 <iput+0x26>
    80003f26:	04a49783          	lh	a5,74(s1)
    80003f2a:	fbf9                	bnez	a5,80003f00 <iput+0x26>
    acquiresleep(&ip->lock);
    80003f2c:	01048913          	add	s2,s1,16
    80003f30:	854a                	mv	a0,s2
    80003f32:	00001097          	auipc	ra,0x1
    80003f36:	a84080e7          	jalr	-1404(ra) # 800049b6 <acquiresleep>
    release(&itable.lock);
    80003f3a:	0003c517          	auipc	a0,0x3c
    80003f3e:	b7650513          	add	a0,a0,-1162 # 8003fab0 <itable>
    80003f42:	ffffd097          	auipc	ra,0xffffd
    80003f46:	faa080e7          	jalr	-86(ra) # 80000eec <release>
    itrunc(ip);
    80003f4a:	8526                	mv	a0,s1
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	ee2080e7          	jalr	-286(ra) # 80003e2e <itrunc>
    ip->type = 0;
    80003f54:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f58:	8526                	mv	a0,s1
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	cfa080e7          	jalr	-774(ra) # 80003c54 <iupdate>
    ip->valid = 0;
    80003f62:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f66:	854a                	mv	a0,s2
    80003f68:	00001097          	auipc	ra,0x1
    80003f6c:	aa4080e7          	jalr	-1372(ra) # 80004a0c <releasesleep>
    acquire(&itable.lock);
    80003f70:	0003c517          	auipc	a0,0x3c
    80003f74:	b4050513          	add	a0,a0,-1216 # 8003fab0 <itable>
    80003f78:	ffffd097          	auipc	ra,0xffffd
    80003f7c:	ec0080e7          	jalr	-320(ra) # 80000e38 <acquire>
    80003f80:	b741                	j	80003f00 <iput+0x26>

0000000080003f82 <iunlockput>:
{
    80003f82:	1101                	add	sp,sp,-32
    80003f84:	ec06                	sd	ra,24(sp)
    80003f86:	e822                	sd	s0,16(sp)
    80003f88:	e426                	sd	s1,8(sp)
    80003f8a:	1000                	add	s0,sp,32
    80003f8c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	e54080e7          	jalr	-428(ra) # 80003de2 <iunlock>
  iput(ip);
    80003f96:	8526                	mv	a0,s1
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	f42080e7          	jalr	-190(ra) # 80003eda <iput>
}
    80003fa0:	60e2                	ld	ra,24(sp)
    80003fa2:	6442                	ld	s0,16(sp)
    80003fa4:	64a2                	ld	s1,8(sp)
    80003fa6:	6105                	add	sp,sp,32
    80003fa8:	8082                	ret

0000000080003faa <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003faa:	1141                	add	sp,sp,-16
    80003fac:	e422                	sd	s0,8(sp)
    80003fae:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003fb0:	411c                	lw	a5,0(a0)
    80003fb2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fb4:	415c                	lw	a5,4(a0)
    80003fb6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fb8:	04451783          	lh	a5,68(a0)
    80003fbc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fc0:	04a51783          	lh	a5,74(a0)
    80003fc4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fc8:	04c56783          	lwu	a5,76(a0)
    80003fcc:	e99c                	sd	a5,16(a1)
}
    80003fce:	6422                	ld	s0,8(sp)
    80003fd0:	0141                	add	sp,sp,16
    80003fd2:	8082                	ret

0000000080003fd4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fd4:	457c                	lw	a5,76(a0)
    80003fd6:	0ed7e963          	bltu	a5,a3,800040c8 <readi+0xf4>
{
    80003fda:	7159                	add	sp,sp,-112
    80003fdc:	f486                	sd	ra,104(sp)
    80003fde:	f0a2                	sd	s0,96(sp)
    80003fe0:	eca6                	sd	s1,88(sp)
    80003fe2:	e8ca                	sd	s2,80(sp)
    80003fe4:	e4ce                	sd	s3,72(sp)
    80003fe6:	e0d2                	sd	s4,64(sp)
    80003fe8:	fc56                	sd	s5,56(sp)
    80003fea:	f85a                	sd	s6,48(sp)
    80003fec:	f45e                	sd	s7,40(sp)
    80003fee:	f062                	sd	s8,32(sp)
    80003ff0:	ec66                	sd	s9,24(sp)
    80003ff2:	e86a                	sd	s10,16(sp)
    80003ff4:	e46e                	sd	s11,8(sp)
    80003ff6:	1880                	add	s0,sp,112
    80003ff8:	8b2a                	mv	s6,a0
    80003ffa:	8bae                	mv	s7,a1
    80003ffc:	8a32                	mv	s4,a2
    80003ffe:	84b6                	mv	s1,a3
    80004000:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004002:	9f35                	addw	a4,a4,a3
    return 0;
    80004004:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004006:	0ad76063          	bltu	a4,a3,800040a6 <readi+0xd2>
  if(off + n > ip->size)
    8000400a:	00e7f463          	bgeu	a5,a4,80004012 <readi+0x3e>
    n = ip->size - off;
    8000400e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004012:	0a0a8963          	beqz	s5,800040c4 <readi+0xf0>
    80004016:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004018:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000401c:	5c7d                	li	s8,-1
    8000401e:	a82d                	j	80004058 <readi+0x84>
    80004020:	020d1d93          	sll	s11,s10,0x20
    80004024:	020ddd93          	srl	s11,s11,0x20
    80004028:	05890613          	add	a2,s2,88
    8000402c:	86ee                	mv	a3,s11
    8000402e:	963a                	add	a2,a2,a4
    80004030:	85d2                	mv	a1,s4
    80004032:	855e                	mv	a0,s7
    80004034:	ffffe097          	auipc	ra,0xffffe
    80004038:	7b6080e7          	jalr	1974(ra) # 800027ea <either_copyout>
    8000403c:	05850d63          	beq	a0,s8,80004096 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004040:	854a                	mv	a0,s2
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	5fe080e7          	jalr	1534(ra) # 80003640 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000404a:	013d09bb          	addw	s3,s10,s3
    8000404e:	009d04bb          	addw	s1,s10,s1
    80004052:	9a6e                	add	s4,s4,s11
    80004054:	0559f763          	bgeu	s3,s5,800040a2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004058:	00a4d59b          	srlw	a1,s1,0xa
    8000405c:	855a                	mv	a0,s6
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	8a4080e7          	jalr	-1884(ra) # 80003902 <bmap>
    80004066:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000406a:	cd85                	beqz	a1,800040a2 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000406c:	000b2503          	lw	a0,0(s6)
    80004070:	fffff097          	auipc	ra,0xfffff
    80004074:	4a0080e7          	jalr	1184(ra) # 80003510 <bread>
    80004078:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000407a:	3ff4f713          	and	a4,s1,1023
    8000407e:	40ec87bb          	subw	a5,s9,a4
    80004082:	413a86bb          	subw	a3,s5,s3
    80004086:	8d3e                	mv	s10,a5
    80004088:	2781                	sext.w	a5,a5
    8000408a:	0006861b          	sext.w	a2,a3
    8000408e:	f8f679e3          	bgeu	a2,a5,80004020 <readi+0x4c>
    80004092:	8d36                	mv	s10,a3
    80004094:	b771                	j	80004020 <readi+0x4c>
      brelse(bp);
    80004096:	854a                	mv	a0,s2
    80004098:	fffff097          	auipc	ra,0xfffff
    8000409c:	5a8080e7          	jalr	1448(ra) # 80003640 <brelse>
      tot = -1;
    800040a0:	59fd                	li	s3,-1
  }
  return tot;
    800040a2:	0009851b          	sext.w	a0,s3
}
    800040a6:	70a6                	ld	ra,104(sp)
    800040a8:	7406                	ld	s0,96(sp)
    800040aa:	64e6                	ld	s1,88(sp)
    800040ac:	6946                	ld	s2,80(sp)
    800040ae:	69a6                	ld	s3,72(sp)
    800040b0:	6a06                	ld	s4,64(sp)
    800040b2:	7ae2                	ld	s5,56(sp)
    800040b4:	7b42                	ld	s6,48(sp)
    800040b6:	7ba2                	ld	s7,40(sp)
    800040b8:	7c02                	ld	s8,32(sp)
    800040ba:	6ce2                	ld	s9,24(sp)
    800040bc:	6d42                	ld	s10,16(sp)
    800040be:	6da2                	ld	s11,8(sp)
    800040c0:	6165                	add	sp,sp,112
    800040c2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040c4:	89d6                	mv	s3,s5
    800040c6:	bff1                	j	800040a2 <readi+0xce>
    return 0;
    800040c8:	4501                	li	a0,0
}
    800040ca:	8082                	ret

00000000800040cc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040cc:	457c                	lw	a5,76(a0)
    800040ce:	10d7e863          	bltu	a5,a3,800041de <writei+0x112>
{
    800040d2:	7159                	add	sp,sp,-112
    800040d4:	f486                	sd	ra,104(sp)
    800040d6:	f0a2                	sd	s0,96(sp)
    800040d8:	eca6                	sd	s1,88(sp)
    800040da:	e8ca                	sd	s2,80(sp)
    800040dc:	e4ce                	sd	s3,72(sp)
    800040de:	e0d2                	sd	s4,64(sp)
    800040e0:	fc56                	sd	s5,56(sp)
    800040e2:	f85a                	sd	s6,48(sp)
    800040e4:	f45e                	sd	s7,40(sp)
    800040e6:	f062                	sd	s8,32(sp)
    800040e8:	ec66                	sd	s9,24(sp)
    800040ea:	e86a                	sd	s10,16(sp)
    800040ec:	e46e                	sd	s11,8(sp)
    800040ee:	1880                	add	s0,sp,112
    800040f0:	8aaa                	mv	s5,a0
    800040f2:	8bae                	mv	s7,a1
    800040f4:	8a32                	mv	s4,a2
    800040f6:	8936                	mv	s2,a3
    800040f8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040fa:	00e687bb          	addw	a5,a3,a4
    800040fe:	0ed7e263          	bltu	a5,a3,800041e2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004102:	00043737          	lui	a4,0x43
    80004106:	0ef76063          	bltu	a4,a5,800041e6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000410a:	0c0b0863          	beqz	s6,800041da <writei+0x10e>
    8000410e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004110:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004114:	5c7d                	li	s8,-1
    80004116:	a091                	j	8000415a <writei+0x8e>
    80004118:	020d1d93          	sll	s11,s10,0x20
    8000411c:	020ddd93          	srl	s11,s11,0x20
    80004120:	05848513          	add	a0,s1,88
    80004124:	86ee                	mv	a3,s11
    80004126:	8652                	mv	a2,s4
    80004128:	85de                	mv	a1,s7
    8000412a:	953a                	add	a0,a0,a4
    8000412c:	ffffe097          	auipc	ra,0xffffe
    80004130:	714080e7          	jalr	1812(ra) # 80002840 <either_copyin>
    80004134:	07850263          	beq	a0,s8,80004198 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004138:	8526                	mv	a0,s1
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	75e080e7          	jalr	1886(ra) # 80004898 <log_write>
    brelse(bp);
    80004142:	8526                	mv	a0,s1
    80004144:	fffff097          	auipc	ra,0xfffff
    80004148:	4fc080e7          	jalr	1276(ra) # 80003640 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000414c:	013d09bb          	addw	s3,s10,s3
    80004150:	012d093b          	addw	s2,s10,s2
    80004154:	9a6e                	add	s4,s4,s11
    80004156:	0569f663          	bgeu	s3,s6,800041a2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000415a:	00a9559b          	srlw	a1,s2,0xa
    8000415e:	8556                	mv	a0,s5
    80004160:	fffff097          	auipc	ra,0xfffff
    80004164:	7a2080e7          	jalr	1954(ra) # 80003902 <bmap>
    80004168:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000416c:	c99d                	beqz	a1,800041a2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000416e:	000aa503          	lw	a0,0(s5)
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	39e080e7          	jalr	926(ra) # 80003510 <bread>
    8000417a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000417c:	3ff97713          	and	a4,s2,1023
    80004180:	40ec87bb          	subw	a5,s9,a4
    80004184:	413b06bb          	subw	a3,s6,s3
    80004188:	8d3e                	mv	s10,a5
    8000418a:	2781                	sext.w	a5,a5
    8000418c:	0006861b          	sext.w	a2,a3
    80004190:	f8f674e3          	bgeu	a2,a5,80004118 <writei+0x4c>
    80004194:	8d36                	mv	s10,a3
    80004196:	b749                	j	80004118 <writei+0x4c>
      brelse(bp);
    80004198:	8526                	mv	a0,s1
    8000419a:	fffff097          	auipc	ra,0xfffff
    8000419e:	4a6080e7          	jalr	1190(ra) # 80003640 <brelse>
  }

  if(off > ip->size)
    800041a2:	04caa783          	lw	a5,76(s5)
    800041a6:	0127f463          	bgeu	a5,s2,800041ae <writei+0xe2>
    ip->size = off;
    800041aa:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041ae:	8556                	mv	a0,s5
    800041b0:	00000097          	auipc	ra,0x0
    800041b4:	aa4080e7          	jalr	-1372(ra) # 80003c54 <iupdate>

  return tot;
    800041b8:	0009851b          	sext.w	a0,s3
}
    800041bc:	70a6                	ld	ra,104(sp)
    800041be:	7406                	ld	s0,96(sp)
    800041c0:	64e6                	ld	s1,88(sp)
    800041c2:	6946                	ld	s2,80(sp)
    800041c4:	69a6                	ld	s3,72(sp)
    800041c6:	6a06                	ld	s4,64(sp)
    800041c8:	7ae2                	ld	s5,56(sp)
    800041ca:	7b42                	ld	s6,48(sp)
    800041cc:	7ba2                	ld	s7,40(sp)
    800041ce:	7c02                	ld	s8,32(sp)
    800041d0:	6ce2                	ld	s9,24(sp)
    800041d2:	6d42                	ld	s10,16(sp)
    800041d4:	6da2                	ld	s11,8(sp)
    800041d6:	6165                	add	sp,sp,112
    800041d8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041da:	89da                	mv	s3,s6
    800041dc:	bfc9                	j	800041ae <writei+0xe2>
    return -1;
    800041de:	557d                	li	a0,-1
}
    800041e0:	8082                	ret
    return -1;
    800041e2:	557d                	li	a0,-1
    800041e4:	bfe1                	j	800041bc <writei+0xf0>
    return -1;
    800041e6:	557d                	li	a0,-1
    800041e8:	bfd1                	j	800041bc <writei+0xf0>

00000000800041ea <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041ea:	1141                	add	sp,sp,-16
    800041ec:	e406                	sd	ra,8(sp)
    800041ee:	e022                	sd	s0,0(sp)
    800041f0:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041f2:	4639                	li	a2,14
    800041f4:	ffffd097          	auipc	ra,0xffffd
    800041f8:	e10080e7          	jalr	-496(ra) # 80001004 <strncmp>
}
    800041fc:	60a2                	ld	ra,8(sp)
    800041fe:	6402                	ld	s0,0(sp)
    80004200:	0141                	add	sp,sp,16
    80004202:	8082                	ret

0000000080004204 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004204:	7139                	add	sp,sp,-64
    80004206:	fc06                	sd	ra,56(sp)
    80004208:	f822                	sd	s0,48(sp)
    8000420a:	f426                	sd	s1,40(sp)
    8000420c:	f04a                	sd	s2,32(sp)
    8000420e:	ec4e                	sd	s3,24(sp)
    80004210:	e852                	sd	s4,16(sp)
    80004212:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004214:	04451703          	lh	a4,68(a0)
    80004218:	4785                	li	a5,1
    8000421a:	00f71a63          	bne	a4,a5,8000422e <dirlookup+0x2a>
    8000421e:	892a                	mv	s2,a0
    80004220:	89ae                	mv	s3,a1
    80004222:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004224:	457c                	lw	a5,76(a0)
    80004226:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004228:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000422a:	e79d                	bnez	a5,80004258 <dirlookup+0x54>
    8000422c:	a8a5                	j	800042a4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000422e:	00004517          	auipc	a0,0x4
    80004232:	3fa50513          	add	a0,a0,1018 # 80008628 <syscalls+0x1b8>
    80004236:	ffffc097          	auipc	ra,0xffffc
    8000423a:	306080e7          	jalr	774(ra) # 8000053c <panic>
      panic("dirlookup read");
    8000423e:	00004517          	auipc	a0,0x4
    80004242:	40250513          	add	a0,a0,1026 # 80008640 <syscalls+0x1d0>
    80004246:	ffffc097          	auipc	ra,0xffffc
    8000424a:	2f6080e7          	jalr	758(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000424e:	24c1                	addw	s1,s1,16
    80004250:	04c92783          	lw	a5,76(s2)
    80004254:	04f4f763          	bgeu	s1,a5,800042a2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004258:	4741                	li	a4,16
    8000425a:	86a6                	mv	a3,s1
    8000425c:	fc040613          	add	a2,s0,-64
    80004260:	4581                	li	a1,0
    80004262:	854a                	mv	a0,s2
    80004264:	00000097          	auipc	ra,0x0
    80004268:	d70080e7          	jalr	-656(ra) # 80003fd4 <readi>
    8000426c:	47c1                	li	a5,16
    8000426e:	fcf518e3          	bne	a0,a5,8000423e <dirlookup+0x3a>
    if(de.inum == 0)
    80004272:	fc045783          	lhu	a5,-64(s0)
    80004276:	dfe1                	beqz	a5,8000424e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004278:	fc240593          	add	a1,s0,-62
    8000427c:	854e                	mv	a0,s3
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	f6c080e7          	jalr	-148(ra) # 800041ea <namecmp>
    80004286:	f561                	bnez	a0,8000424e <dirlookup+0x4a>
      if(poff)
    80004288:	000a0463          	beqz	s4,80004290 <dirlookup+0x8c>
        *poff = off;
    8000428c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004290:	fc045583          	lhu	a1,-64(s0)
    80004294:	00092503          	lw	a0,0(s2)
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	754080e7          	jalr	1876(ra) # 800039ec <iget>
    800042a0:	a011                	j	800042a4 <dirlookup+0xa0>
  return 0;
    800042a2:	4501                	li	a0,0
}
    800042a4:	70e2                	ld	ra,56(sp)
    800042a6:	7442                	ld	s0,48(sp)
    800042a8:	74a2                	ld	s1,40(sp)
    800042aa:	7902                	ld	s2,32(sp)
    800042ac:	69e2                	ld	s3,24(sp)
    800042ae:	6a42                	ld	s4,16(sp)
    800042b0:	6121                	add	sp,sp,64
    800042b2:	8082                	ret

00000000800042b4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042b4:	711d                	add	sp,sp,-96
    800042b6:	ec86                	sd	ra,88(sp)
    800042b8:	e8a2                	sd	s0,80(sp)
    800042ba:	e4a6                	sd	s1,72(sp)
    800042bc:	e0ca                	sd	s2,64(sp)
    800042be:	fc4e                	sd	s3,56(sp)
    800042c0:	f852                	sd	s4,48(sp)
    800042c2:	f456                	sd	s5,40(sp)
    800042c4:	f05a                	sd	s6,32(sp)
    800042c6:	ec5e                	sd	s7,24(sp)
    800042c8:	e862                	sd	s8,16(sp)
    800042ca:	e466                	sd	s9,8(sp)
    800042cc:	1080                	add	s0,sp,96
    800042ce:	84aa                	mv	s1,a0
    800042d0:	8b2e                	mv	s6,a1
    800042d2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042d4:	00054703          	lbu	a4,0(a0)
    800042d8:	02f00793          	li	a5,47
    800042dc:	02f70263          	beq	a4,a5,80004300 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042e0:	ffffe097          	auipc	ra,0xffffe
    800042e4:	924080e7          	jalr	-1756(ra) # 80001c04 <myproc>
    800042e8:	15053503          	ld	a0,336(a0)
    800042ec:	00000097          	auipc	ra,0x0
    800042f0:	9f6080e7          	jalr	-1546(ra) # 80003ce2 <idup>
    800042f4:	8a2a                	mv	s4,a0
  while(*path == '/')
    800042f6:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800042fa:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042fc:	4b85                	li	s7,1
    800042fe:	a875                	j	800043ba <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004300:	4585                	li	a1,1
    80004302:	4505                	li	a0,1
    80004304:	fffff097          	auipc	ra,0xfffff
    80004308:	6e8080e7          	jalr	1768(ra) # 800039ec <iget>
    8000430c:	8a2a                	mv	s4,a0
    8000430e:	b7e5                	j	800042f6 <namex+0x42>
      iunlockput(ip);
    80004310:	8552                	mv	a0,s4
    80004312:	00000097          	auipc	ra,0x0
    80004316:	c70080e7          	jalr	-912(ra) # 80003f82 <iunlockput>
      return 0;
    8000431a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000431c:	8552                	mv	a0,s4
    8000431e:	60e6                	ld	ra,88(sp)
    80004320:	6446                	ld	s0,80(sp)
    80004322:	64a6                	ld	s1,72(sp)
    80004324:	6906                	ld	s2,64(sp)
    80004326:	79e2                	ld	s3,56(sp)
    80004328:	7a42                	ld	s4,48(sp)
    8000432a:	7aa2                	ld	s5,40(sp)
    8000432c:	7b02                	ld	s6,32(sp)
    8000432e:	6be2                	ld	s7,24(sp)
    80004330:	6c42                	ld	s8,16(sp)
    80004332:	6ca2                	ld	s9,8(sp)
    80004334:	6125                	add	sp,sp,96
    80004336:	8082                	ret
      iunlock(ip);
    80004338:	8552                	mv	a0,s4
    8000433a:	00000097          	auipc	ra,0x0
    8000433e:	aa8080e7          	jalr	-1368(ra) # 80003de2 <iunlock>
      return ip;
    80004342:	bfe9                	j	8000431c <namex+0x68>
      iunlockput(ip);
    80004344:	8552                	mv	a0,s4
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	c3c080e7          	jalr	-964(ra) # 80003f82 <iunlockput>
      return 0;
    8000434e:	8a4e                	mv	s4,s3
    80004350:	b7f1                	j	8000431c <namex+0x68>
  len = path - s;
    80004352:	40998633          	sub	a2,s3,s1
    80004356:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000435a:	099c5863          	bge	s8,s9,800043ea <namex+0x136>
    memmove(name, s, DIRSIZ);
    8000435e:	4639                	li	a2,14
    80004360:	85a6                	mv	a1,s1
    80004362:	8556                	mv	a0,s5
    80004364:	ffffd097          	auipc	ra,0xffffd
    80004368:	c2c080e7          	jalr	-980(ra) # 80000f90 <memmove>
    8000436c:	84ce                	mv	s1,s3
  while(*path == '/')
    8000436e:	0004c783          	lbu	a5,0(s1)
    80004372:	01279763          	bne	a5,s2,80004380 <namex+0xcc>
    path++;
    80004376:	0485                	add	s1,s1,1
  while(*path == '/')
    80004378:	0004c783          	lbu	a5,0(s1)
    8000437c:	ff278de3          	beq	a5,s2,80004376 <namex+0xc2>
    ilock(ip);
    80004380:	8552                	mv	a0,s4
    80004382:	00000097          	auipc	ra,0x0
    80004386:	99e080e7          	jalr	-1634(ra) # 80003d20 <ilock>
    if(ip->type != T_DIR){
    8000438a:	044a1783          	lh	a5,68(s4)
    8000438e:	f97791e3          	bne	a5,s7,80004310 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004392:	000b0563          	beqz	s6,8000439c <namex+0xe8>
    80004396:	0004c783          	lbu	a5,0(s1)
    8000439a:	dfd9                	beqz	a5,80004338 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000439c:	4601                	li	a2,0
    8000439e:	85d6                	mv	a1,s5
    800043a0:	8552                	mv	a0,s4
    800043a2:	00000097          	auipc	ra,0x0
    800043a6:	e62080e7          	jalr	-414(ra) # 80004204 <dirlookup>
    800043aa:	89aa                	mv	s3,a0
    800043ac:	dd41                	beqz	a0,80004344 <namex+0x90>
    iunlockput(ip);
    800043ae:	8552                	mv	a0,s4
    800043b0:	00000097          	auipc	ra,0x0
    800043b4:	bd2080e7          	jalr	-1070(ra) # 80003f82 <iunlockput>
    ip = next;
    800043b8:	8a4e                	mv	s4,s3
  while(*path == '/')
    800043ba:	0004c783          	lbu	a5,0(s1)
    800043be:	01279763          	bne	a5,s2,800043cc <namex+0x118>
    path++;
    800043c2:	0485                	add	s1,s1,1
  while(*path == '/')
    800043c4:	0004c783          	lbu	a5,0(s1)
    800043c8:	ff278de3          	beq	a5,s2,800043c2 <namex+0x10e>
  if(*path == 0)
    800043cc:	cb9d                	beqz	a5,80004402 <namex+0x14e>
  while(*path != '/' && *path != 0)
    800043ce:	0004c783          	lbu	a5,0(s1)
    800043d2:	89a6                	mv	s3,s1
  len = path - s;
    800043d4:	4c81                	li	s9,0
    800043d6:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800043d8:	01278963          	beq	a5,s2,800043ea <namex+0x136>
    800043dc:	dbbd                	beqz	a5,80004352 <namex+0x9e>
    path++;
    800043de:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    800043e0:	0009c783          	lbu	a5,0(s3)
    800043e4:	ff279ce3          	bne	a5,s2,800043dc <namex+0x128>
    800043e8:	b7ad                	j	80004352 <namex+0x9e>
    memmove(name, s, len);
    800043ea:	2601                	sext.w	a2,a2
    800043ec:	85a6                	mv	a1,s1
    800043ee:	8556                	mv	a0,s5
    800043f0:	ffffd097          	auipc	ra,0xffffd
    800043f4:	ba0080e7          	jalr	-1120(ra) # 80000f90 <memmove>
    name[len] = 0;
    800043f8:	9cd6                	add	s9,s9,s5
    800043fa:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800043fe:	84ce                	mv	s1,s3
    80004400:	b7bd                	j	8000436e <namex+0xba>
  if(nameiparent){
    80004402:	f00b0de3          	beqz	s6,8000431c <namex+0x68>
    iput(ip);
    80004406:	8552                	mv	a0,s4
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	ad2080e7          	jalr	-1326(ra) # 80003eda <iput>
    return 0;
    80004410:	4a01                	li	s4,0
    80004412:	b729                	j	8000431c <namex+0x68>

0000000080004414 <dirlink>:
{
    80004414:	7139                	add	sp,sp,-64
    80004416:	fc06                	sd	ra,56(sp)
    80004418:	f822                	sd	s0,48(sp)
    8000441a:	f426                	sd	s1,40(sp)
    8000441c:	f04a                	sd	s2,32(sp)
    8000441e:	ec4e                	sd	s3,24(sp)
    80004420:	e852                	sd	s4,16(sp)
    80004422:	0080                	add	s0,sp,64
    80004424:	892a                	mv	s2,a0
    80004426:	8a2e                	mv	s4,a1
    80004428:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000442a:	4601                	li	a2,0
    8000442c:	00000097          	auipc	ra,0x0
    80004430:	dd8080e7          	jalr	-552(ra) # 80004204 <dirlookup>
    80004434:	e93d                	bnez	a0,800044aa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004436:	04c92483          	lw	s1,76(s2)
    8000443a:	c49d                	beqz	s1,80004468 <dirlink+0x54>
    8000443c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000443e:	4741                	li	a4,16
    80004440:	86a6                	mv	a3,s1
    80004442:	fc040613          	add	a2,s0,-64
    80004446:	4581                	li	a1,0
    80004448:	854a                	mv	a0,s2
    8000444a:	00000097          	auipc	ra,0x0
    8000444e:	b8a080e7          	jalr	-1142(ra) # 80003fd4 <readi>
    80004452:	47c1                	li	a5,16
    80004454:	06f51163          	bne	a0,a5,800044b6 <dirlink+0xa2>
    if(de.inum == 0)
    80004458:	fc045783          	lhu	a5,-64(s0)
    8000445c:	c791                	beqz	a5,80004468 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000445e:	24c1                	addw	s1,s1,16
    80004460:	04c92783          	lw	a5,76(s2)
    80004464:	fcf4ede3          	bltu	s1,a5,8000443e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004468:	4639                	li	a2,14
    8000446a:	85d2                	mv	a1,s4
    8000446c:	fc240513          	add	a0,s0,-62
    80004470:	ffffd097          	auipc	ra,0xffffd
    80004474:	bd0080e7          	jalr	-1072(ra) # 80001040 <strncpy>
  de.inum = inum;
    80004478:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000447c:	4741                	li	a4,16
    8000447e:	86a6                	mv	a3,s1
    80004480:	fc040613          	add	a2,s0,-64
    80004484:	4581                	li	a1,0
    80004486:	854a                	mv	a0,s2
    80004488:	00000097          	auipc	ra,0x0
    8000448c:	c44080e7          	jalr	-956(ra) # 800040cc <writei>
    80004490:	1541                	add	a0,a0,-16
    80004492:	00a03533          	snez	a0,a0
    80004496:	40a00533          	neg	a0,a0
}
    8000449a:	70e2                	ld	ra,56(sp)
    8000449c:	7442                	ld	s0,48(sp)
    8000449e:	74a2                	ld	s1,40(sp)
    800044a0:	7902                	ld	s2,32(sp)
    800044a2:	69e2                	ld	s3,24(sp)
    800044a4:	6a42                	ld	s4,16(sp)
    800044a6:	6121                	add	sp,sp,64
    800044a8:	8082                	ret
    iput(ip);
    800044aa:	00000097          	auipc	ra,0x0
    800044ae:	a30080e7          	jalr	-1488(ra) # 80003eda <iput>
    return -1;
    800044b2:	557d                	li	a0,-1
    800044b4:	b7dd                	j	8000449a <dirlink+0x86>
      panic("dirlink read");
    800044b6:	00004517          	auipc	a0,0x4
    800044ba:	19a50513          	add	a0,a0,410 # 80008650 <syscalls+0x1e0>
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	07e080e7          	jalr	126(ra) # 8000053c <panic>

00000000800044c6 <namei>:

struct inode*
namei(char *path)
{
    800044c6:	1101                	add	sp,sp,-32
    800044c8:	ec06                	sd	ra,24(sp)
    800044ca:	e822                	sd	s0,16(sp)
    800044cc:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044ce:	fe040613          	add	a2,s0,-32
    800044d2:	4581                	li	a1,0
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	de0080e7          	jalr	-544(ra) # 800042b4 <namex>
}
    800044dc:	60e2                	ld	ra,24(sp)
    800044de:	6442                	ld	s0,16(sp)
    800044e0:	6105                	add	sp,sp,32
    800044e2:	8082                	ret

00000000800044e4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044e4:	1141                	add	sp,sp,-16
    800044e6:	e406                	sd	ra,8(sp)
    800044e8:	e022                	sd	s0,0(sp)
    800044ea:	0800                	add	s0,sp,16
    800044ec:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044ee:	4585                	li	a1,1
    800044f0:	00000097          	auipc	ra,0x0
    800044f4:	dc4080e7          	jalr	-572(ra) # 800042b4 <namex>
}
    800044f8:	60a2                	ld	ra,8(sp)
    800044fa:	6402                	ld	s0,0(sp)
    800044fc:	0141                	add	sp,sp,16
    800044fe:	8082                	ret

0000000080004500 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004500:	1101                	add	sp,sp,-32
    80004502:	ec06                	sd	ra,24(sp)
    80004504:	e822                	sd	s0,16(sp)
    80004506:	e426                	sd	s1,8(sp)
    80004508:	e04a                	sd	s2,0(sp)
    8000450a:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000450c:	0003d917          	auipc	s2,0x3d
    80004510:	04c90913          	add	s2,s2,76 # 80041558 <log>
    80004514:	01892583          	lw	a1,24(s2)
    80004518:	02892503          	lw	a0,40(s2)
    8000451c:	fffff097          	auipc	ra,0xfffff
    80004520:	ff4080e7          	jalr	-12(ra) # 80003510 <bread>
    80004524:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004526:	02c92603          	lw	a2,44(s2)
    8000452a:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000452c:	00c05f63          	blez	a2,8000454a <write_head+0x4a>
    80004530:	0003d717          	auipc	a4,0x3d
    80004534:	05870713          	add	a4,a4,88 # 80041588 <log+0x30>
    80004538:	87aa                	mv	a5,a0
    8000453a:	060a                	sll	a2,a2,0x2
    8000453c:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000453e:	4314                	lw	a3,0(a4)
    80004540:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004542:	0711                	add	a4,a4,4
    80004544:	0791                	add	a5,a5,4
    80004546:	fec79ce3          	bne	a5,a2,8000453e <write_head+0x3e>
  }
  bwrite(buf);
    8000454a:	8526                	mv	a0,s1
    8000454c:	fffff097          	auipc	ra,0xfffff
    80004550:	0b6080e7          	jalr	182(ra) # 80003602 <bwrite>
  brelse(buf);
    80004554:	8526                	mv	a0,s1
    80004556:	fffff097          	auipc	ra,0xfffff
    8000455a:	0ea080e7          	jalr	234(ra) # 80003640 <brelse>
}
    8000455e:	60e2                	ld	ra,24(sp)
    80004560:	6442                	ld	s0,16(sp)
    80004562:	64a2                	ld	s1,8(sp)
    80004564:	6902                	ld	s2,0(sp)
    80004566:	6105                	add	sp,sp,32
    80004568:	8082                	ret

000000008000456a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000456a:	0003d797          	auipc	a5,0x3d
    8000456e:	01a7a783          	lw	a5,26(a5) # 80041584 <log+0x2c>
    80004572:	0af05d63          	blez	a5,8000462c <install_trans+0xc2>
{
    80004576:	7139                	add	sp,sp,-64
    80004578:	fc06                	sd	ra,56(sp)
    8000457a:	f822                	sd	s0,48(sp)
    8000457c:	f426                	sd	s1,40(sp)
    8000457e:	f04a                	sd	s2,32(sp)
    80004580:	ec4e                	sd	s3,24(sp)
    80004582:	e852                	sd	s4,16(sp)
    80004584:	e456                	sd	s5,8(sp)
    80004586:	e05a                	sd	s6,0(sp)
    80004588:	0080                	add	s0,sp,64
    8000458a:	8b2a                	mv	s6,a0
    8000458c:	0003da97          	auipc	s5,0x3d
    80004590:	ffca8a93          	add	s5,s5,-4 # 80041588 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004594:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004596:	0003d997          	auipc	s3,0x3d
    8000459a:	fc298993          	add	s3,s3,-62 # 80041558 <log>
    8000459e:	a00d                	j	800045c0 <install_trans+0x56>
    brelse(lbuf);
    800045a0:	854a                	mv	a0,s2
    800045a2:	fffff097          	auipc	ra,0xfffff
    800045a6:	09e080e7          	jalr	158(ra) # 80003640 <brelse>
    brelse(dbuf);
    800045aa:	8526                	mv	a0,s1
    800045ac:	fffff097          	auipc	ra,0xfffff
    800045b0:	094080e7          	jalr	148(ra) # 80003640 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045b4:	2a05                	addw	s4,s4,1
    800045b6:	0a91                	add	s5,s5,4
    800045b8:	02c9a783          	lw	a5,44(s3)
    800045bc:	04fa5e63          	bge	s4,a5,80004618 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045c0:	0189a583          	lw	a1,24(s3)
    800045c4:	014585bb          	addw	a1,a1,s4
    800045c8:	2585                	addw	a1,a1,1
    800045ca:	0289a503          	lw	a0,40(s3)
    800045ce:	fffff097          	auipc	ra,0xfffff
    800045d2:	f42080e7          	jalr	-190(ra) # 80003510 <bread>
    800045d6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045d8:	000aa583          	lw	a1,0(s5)
    800045dc:	0289a503          	lw	a0,40(s3)
    800045e0:	fffff097          	auipc	ra,0xfffff
    800045e4:	f30080e7          	jalr	-208(ra) # 80003510 <bread>
    800045e8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045ea:	40000613          	li	a2,1024
    800045ee:	05890593          	add	a1,s2,88
    800045f2:	05850513          	add	a0,a0,88
    800045f6:	ffffd097          	auipc	ra,0xffffd
    800045fa:	99a080e7          	jalr	-1638(ra) # 80000f90 <memmove>
    bwrite(dbuf);  // write dst to disk
    800045fe:	8526                	mv	a0,s1
    80004600:	fffff097          	auipc	ra,0xfffff
    80004604:	002080e7          	jalr	2(ra) # 80003602 <bwrite>
    if(recovering == 0)
    80004608:	f80b1ce3          	bnez	s6,800045a0 <install_trans+0x36>
      bunpin(dbuf);
    8000460c:	8526                	mv	a0,s1
    8000460e:	fffff097          	auipc	ra,0xfffff
    80004612:	10a080e7          	jalr	266(ra) # 80003718 <bunpin>
    80004616:	b769                	j	800045a0 <install_trans+0x36>
}
    80004618:	70e2                	ld	ra,56(sp)
    8000461a:	7442                	ld	s0,48(sp)
    8000461c:	74a2                	ld	s1,40(sp)
    8000461e:	7902                	ld	s2,32(sp)
    80004620:	69e2                	ld	s3,24(sp)
    80004622:	6a42                	ld	s4,16(sp)
    80004624:	6aa2                	ld	s5,8(sp)
    80004626:	6b02                	ld	s6,0(sp)
    80004628:	6121                	add	sp,sp,64
    8000462a:	8082                	ret
    8000462c:	8082                	ret

000000008000462e <initlog>:
{
    8000462e:	7179                	add	sp,sp,-48
    80004630:	f406                	sd	ra,40(sp)
    80004632:	f022                	sd	s0,32(sp)
    80004634:	ec26                	sd	s1,24(sp)
    80004636:	e84a                	sd	s2,16(sp)
    80004638:	e44e                	sd	s3,8(sp)
    8000463a:	1800                	add	s0,sp,48
    8000463c:	892a                	mv	s2,a0
    8000463e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004640:	0003d497          	auipc	s1,0x3d
    80004644:	f1848493          	add	s1,s1,-232 # 80041558 <log>
    80004648:	00004597          	auipc	a1,0x4
    8000464c:	01858593          	add	a1,a1,24 # 80008660 <syscalls+0x1f0>
    80004650:	8526                	mv	a0,s1
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	756080e7          	jalr	1878(ra) # 80000da8 <initlock>
  log.start = sb->logstart;
    8000465a:	0149a583          	lw	a1,20(s3)
    8000465e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004660:	0109a783          	lw	a5,16(s3)
    80004664:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004666:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000466a:	854a                	mv	a0,s2
    8000466c:	fffff097          	auipc	ra,0xfffff
    80004670:	ea4080e7          	jalr	-348(ra) # 80003510 <bread>
  log.lh.n = lh->n;
    80004674:	4d30                	lw	a2,88(a0)
    80004676:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004678:	00c05f63          	blez	a2,80004696 <initlog+0x68>
    8000467c:	87aa                	mv	a5,a0
    8000467e:	0003d717          	auipc	a4,0x3d
    80004682:	f0a70713          	add	a4,a4,-246 # 80041588 <log+0x30>
    80004686:	060a                	sll	a2,a2,0x2
    80004688:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    8000468a:	4ff4                	lw	a3,92(a5)
    8000468c:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000468e:	0791                	add	a5,a5,4
    80004690:	0711                	add	a4,a4,4
    80004692:	fec79ce3          	bne	a5,a2,8000468a <initlog+0x5c>
  brelse(buf);
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	faa080e7          	jalr	-86(ra) # 80003640 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000469e:	4505                	li	a0,1
    800046a0:	00000097          	auipc	ra,0x0
    800046a4:	eca080e7          	jalr	-310(ra) # 8000456a <install_trans>
  log.lh.n = 0;
    800046a8:	0003d797          	auipc	a5,0x3d
    800046ac:	ec07ae23          	sw	zero,-292(a5) # 80041584 <log+0x2c>
  write_head(); // clear the log
    800046b0:	00000097          	auipc	ra,0x0
    800046b4:	e50080e7          	jalr	-432(ra) # 80004500 <write_head>
}
    800046b8:	70a2                	ld	ra,40(sp)
    800046ba:	7402                	ld	s0,32(sp)
    800046bc:	64e2                	ld	s1,24(sp)
    800046be:	6942                	ld	s2,16(sp)
    800046c0:	69a2                	ld	s3,8(sp)
    800046c2:	6145                	add	sp,sp,48
    800046c4:	8082                	ret

00000000800046c6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046c6:	1101                	add	sp,sp,-32
    800046c8:	ec06                	sd	ra,24(sp)
    800046ca:	e822                	sd	s0,16(sp)
    800046cc:	e426                	sd	s1,8(sp)
    800046ce:	e04a                	sd	s2,0(sp)
    800046d0:	1000                	add	s0,sp,32
  acquire(&log.lock);
    800046d2:	0003d517          	auipc	a0,0x3d
    800046d6:	e8650513          	add	a0,a0,-378 # 80041558 <log>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	75e080e7          	jalr	1886(ra) # 80000e38 <acquire>
  while(1){
    if(log.committing){
    800046e2:	0003d497          	auipc	s1,0x3d
    800046e6:	e7648493          	add	s1,s1,-394 # 80041558 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046ea:	4979                	li	s2,30
    800046ec:	a039                	j	800046fa <begin_op+0x34>
      sleep(&log, &log.lock);
    800046ee:	85a6                	mv	a1,s1
    800046f0:	8526                	mv	a0,s1
    800046f2:	ffffe097          	auipc	ra,0xffffe
    800046f6:	ce4080e7          	jalr	-796(ra) # 800023d6 <sleep>
    if(log.committing){
    800046fa:	50dc                	lw	a5,36(s1)
    800046fc:	fbed                	bnez	a5,800046ee <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046fe:	5098                	lw	a4,32(s1)
    80004700:	2705                	addw	a4,a4,1
    80004702:	0027179b          	sllw	a5,a4,0x2
    80004706:	9fb9                	addw	a5,a5,a4
    80004708:	0017979b          	sllw	a5,a5,0x1
    8000470c:	54d4                	lw	a3,44(s1)
    8000470e:	9fb5                	addw	a5,a5,a3
    80004710:	00f95963          	bge	s2,a5,80004722 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004714:	85a6                	mv	a1,s1
    80004716:	8526                	mv	a0,s1
    80004718:	ffffe097          	auipc	ra,0xffffe
    8000471c:	cbe080e7          	jalr	-834(ra) # 800023d6 <sleep>
    80004720:	bfe9                	j	800046fa <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004722:	0003d517          	auipc	a0,0x3d
    80004726:	e3650513          	add	a0,a0,-458 # 80041558 <log>
    8000472a:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	7c0080e7          	jalr	1984(ra) # 80000eec <release>
      break;
    }
  }
}
    80004734:	60e2                	ld	ra,24(sp)
    80004736:	6442                	ld	s0,16(sp)
    80004738:	64a2                	ld	s1,8(sp)
    8000473a:	6902                	ld	s2,0(sp)
    8000473c:	6105                	add	sp,sp,32
    8000473e:	8082                	ret

0000000080004740 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004740:	7139                	add	sp,sp,-64
    80004742:	fc06                	sd	ra,56(sp)
    80004744:	f822                	sd	s0,48(sp)
    80004746:	f426                	sd	s1,40(sp)
    80004748:	f04a                	sd	s2,32(sp)
    8000474a:	ec4e                	sd	s3,24(sp)
    8000474c:	e852                	sd	s4,16(sp)
    8000474e:	e456                	sd	s5,8(sp)
    80004750:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004752:	0003d497          	auipc	s1,0x3d
    80004756:	e0648493          	add	s1,s1,-506 # 80041558 <log>
    8000475a:	8526                	mv	a0,s1
    8000475c:	ffffc097          	auipc	ra,0xffffc
    80004760:	6dc080e7          	jalr	1756(ra) # 80000e38 <acquire>
  log.outstanding -= 1;
    80004764:	509c                	lw	a5,32(s1)
    80004766:	37fd                	addw	a5,a5,-1
    80004768:	0007891b          	sext.w	s2,a5
    8000476c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000476e:	50dc                	lw	a5,36(s1)
    80004770:	e7b9                	bnez	a5,800047be <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004772:	04091e63          	bnez	s2,800047ce <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004776:	0003d497          	auipc	s1,0x3d
    8000477a:	de248493          	add	s1,s1,-542 # 80041558 <log>
    8000477e:	4785                	li	a5,1
    80004780:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004782:	8526                	mv	a0,s1
    80004784:	ffffc097          	auipc	ra,0xffffc
    80004788:	768080e7          	jalr	1896(ra) # 80000eec <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000478c:	54dc                	lw	a5,44(s1)
    8000478e:	06f04763          	bgtz	a5,800047fc <end_op+0xbc>
    acquire(&log.lock);
    80004792:	0003d497          	auipc	s1,0x3d
    80004796:	dc648493          	add	s1,s1,-570 # 80041558 <log>
    8000479a:	8526                	mv	a0,s1
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	69c080e7          	jalr	1692(ra) # 80000e38 <acquire>
    log.committing = 0;
    800047a4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047a8:	8526                	mv	a0,s1
    800047aa:	ffffe097          	auipc	ra,0xffffe
    800047ae:	c90080e7          	jalr	-880(ra) # 8000243a <wakeup>
    release(&log.lock);
    800047b2:	8526                	mv	a0,s1
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	738080e7          	jalr	1848(ra) # 80000eec <release>
}
    800047bc:	a03d                	j	800047ea <end_op+0xaa>
    panic("log.committing");
    800047be:	00004517          	auipc	a0,0x4
    800047c2:	eaa50513          	add	a0,a0,-342 # 80008668 <syscalls+0x1f8>
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	d76080e7          	jalr	-650(ra) # 8000053c <panic>
    wakeup(&log);
    800047ce:	0003d497          	auipc	s1,0x3d
    800047d2:	d8a48493          	add	s1,s1,-630 # 80041558 <log>
    800047d6:	8526                	mv	a0,s1
    800047d8:	ffffe097          	auipc	ra,0xffffe
    800047dc:	c62080e7          	jalr	-926(ra) # 8000243a <wakeup>
  release(&log.lock);
    800047e0:	8526                	mv	a0,s1
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	70a080e7          	jalr	1802(ra) # 80000eec <release>
}
    800047ea:	70e2                	ld	ra,56(sp)
    800047ec:	7442                	ld	s0,48(sp)
    800047ee:	74a2                	ld	s1,40(sp)
    800047f0:	7902                	ld	s2,32(sp)
    800047f2:	69e2                	ld	s3,24(sp)
    800047f4:	6a42                	ld	s4,16(sp)
    800047f6:	6aa2                	ld	s5,8(sp)
    800047f8:	6121                	add	sp,sp,64
    800047fa:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800047fc:	0003da97          	auipc	s5,0x3d
    80004800:	d8ca8a93          	add	s5,s5,-628 # 80041588 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004804:	0003da17          	auipc	s4,0x3d
    80004808:	d54a0a13          	add	s4,s4,-684 # 80041558 <log>
    8000480c:	018a2583          	lw	a1,24(s4)
    80004810:	012585bb          	addw	a1,a1,s2
    80004814:	2585                	addw	a1,a1,1
    80004816:	028a2503          	lw	a0,40(s4)
    8000481a:	fffff097          	auipc	ra,0xfffff
    8000481e:	cf6080e7          	jalr	-778(ra) # 80003510 <bread>
    80004822:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004824:	000aa583          	lw	a1,0(s5)
    80004828:	028a2503          	lw	a0,40(s4)
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	ce4080e7          	jalr	-796(ra) # 80003510 <bread>
    80004834:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004836:	40000613          	li	a2,1024
    8000483a:	05850593          	add	a1,a0,88
    8000483e:	05848513          	add	a0,s1,88
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	74e080e7          	jalr	1870(ra) # 80000f90 <memmove>
    bwrite(to);  // write the log
    8000484a:	8526                	mv	a0,s1
    8000484c:	fffff097          	auipc	ra,0xfffff
    80004850:	db6080e7          	jalr	-586(ra) # 80003602 <bwrite>
    brelse(from);
    80004854:	854e                	mv	a0,s3
    80004856:	fffff097          	auipc	ra,0xfffff
    8000485a:	dea080e7          	jalr	-534(ra) # 80003640 <brelse>
    brelse(to);
    8000485e:	8526                	mv	a0,s1
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	de0080e7          	jalr	-544(ra) # 80003640 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004868:	2905                	addw	s2,s2,1
    8000486a:	0a91                	add	s5,s5,4
    8000486c:	02ca2783          	lw	a5,44(s4)
    80004870:	f8f94ee3          	blt	s2,a5,8000480c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004874:	00000097          	auipc	ra,0x0
    80004878:	c8c080e7          	jalr	-884(ra) # 80004500 <write_head>
    install_trans(0); // Now install writes to home locations
    8000487c:	4501                	li	a0,0
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	cec080e7          	jalr	-788(ra) # 8000456a <install_trans>
    log.lh.n = 0;
    80004886:	0003d797          	auipc	a5,0x3d
    8000488a:	ce07af23          	sw	zero,-770(a5) # 80041584 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	c72080e7          	jalr	-910(ra) # 80004500 <write_head>
    80004896:	bdf5                	j	80004792 <end_op+0x52>

0000000080004898 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004898:	1101                	add	sp,sp,-32
    8000489a:	ec06                	sd	ra,24(sp)
    8000489c:	e822                	sd	s0,16(sp)
    8000489e:	e426                	sd	s1,8(sp)
    800048a0:	e04a                	sd	s2,0(sp)
    800048a2:	1000                	add	s0,sp,32
    800048a4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048a6:	0003d917          	auipc	s2,0x3d
    800048aa:	cb290913          	add	s2,s2,-846 # 80041558 <log>
    800048ae:	854a                	mv	a0,s2
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	588080e7          	jalr	1416(ra) # 80000e38 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048b8:	02c92603          	lw	a2,44(s2)
    800048bc:	47f5                	li	a5,29
    800048be:	06c7c563          	blt	a5,a2,80004928 <log_write+0x90>
    800048c2:	0003d797          	auipc	a5,0x3d
    800048c6:	cb27a783          	lw	a5,-846(a5) # 80041574 <log+0x1c>
    800048ca:	37fd                	addw	a5,a5,-1
    800048cc:	04f65e63          	bge	a2,a5,80004928 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048d0:	0003d797          	auipc	a5,0x3d
    800048d4:	ca87a783          	lw	a5,-856(a5) # 80041578 <log+0x20>
    800048d8:	06f05063          	blez	a5,80004938 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048dc:	4781                	li	a5,0
    800048de:	06c05563          	blez	a2,80004948 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048e2:	44cc                	lw	a1,12(s1)
    800048e4:	0003d717          	auipc	a4,0x3d
    800048e8:	ca470713          	add	a4,a4,-860 # 80041588 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048ec:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048ee:	4314                	lw	a3,0(a4)
    800048f0:	04b68c63          	beq	a3,a1,80004948 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800048f4:	2785                	addw	a5,a5,1
    800048f6:	0711                	add	a4,a4,4
    800048f8:	fef61be3          	bne	a2,a5,800048ee <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048fc:	0621                	add	a2,a2,8
    800048fe:	060a                	sll	a2,a2,0x2
    80004900:	0003d797          	auipc	a5,0x3d
    80004904:	c5878793          	add	a5,a5,-936 # 80041558 <log>
    80004908:	97b2                	add	a5,a5,a2
    8000490a:	44d8                	lw	a4,12(s1)
    8000490c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000490e:	8526                	mv	a0,s1
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	dcc080e7          	jalr	-564(ra) # 800036dc <bpin>
    log.lh.n++;
    80004918:	0003d717          	auipc	a4,0x3d
    8000491c:	c4070713          	add	a4,a4,-960 # 80041558 <log>
    80004920:	575c                	lw	a5,44(a4)
    80004922:	2785                	addw	a5,a5,1
    80004924:	d75c                	sw	a5,44(a4)
    80004926:	a82d                	j	80004960 <log_write+0xc8>
    panic("too big a transaction");
    80004928:	00004517          	auipc	a0,0x4
    8000492c:	d5050513          	add	a0,a0,-688 # 80008678 <syscalls+0x208>
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	c0c080e7          	jalr	-1012(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004938:	00004517          	auipc	a0,0x4
    8000493c:	d5850513          	add	a0,a0,-680 # 80008690 <syscalls+0x220>
    80004940:	ffffc097          	auipc	ra,0xffffc
    80004944:	bfc080e7          	jalr	-1028(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004948:	00878693          	add	a3,a5,8
    8000494c:	068a                	sll	a3,a3,0x2
    8000494e:	0003d717          	auipc	a4,0x3d
    80004952:	c0a70713          	add	a4,a4,-1014 # 80041558 <log>
    80004956:	9736                	add	a4,a4,a3
    80004958:	44d4                	lw	a3,12(s1)
    8000495a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000495c:	faf609e3          	beq	a2,a5,8000490e <log_write+0x76>
  }
  release(&log.lock);
    80004960:	0003d517          	auipc	a0,0x3d
    80004964:	bf850513          	add	a0,a0,-1032 # 80041558 <log>
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	584080e7          	jalr	1412(ra) # 80000eec <release>
}
    80004970:	60e2                	ld	ra,24(sp)
    80004972:	6442                	ld	s0,16(sp)
    80004974:	64a2                	ld	s1,8(sp)
    80004976:	6902                	ld	s2,0(sp)
    80004978:	6105                	add	sp,sp,32
    8000497a:	8082                	ret

000000008000497c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000497c:	1101                	add	sp,sp,-32
    8000497e:	ec06                	sd	ra,24(sp)
    80004980:	e822                	sd	s0,16(sp)
    80004982:	e426                	sd	s1,8(sp)
    80004984:	e04a                	sd	s2,0(sp)
    80004986:	1000                	add	s0,sp,32
    80004988:	84aa                	mv	s1,a0
    8000498a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000498c:	00004597          	auipc	a1,0x4
    80004990:	d2458593          	add	a1,a1,-732 # 800086b0 <syscalls+0x240>
    80004994:	0521                	add	a0,a0,8
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	412080e7          	jalr	1042(ra) # 80000da8 <initlock>
  lk->name = name;
    8000499e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049a2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049a6:	0204a423          	sw	zero,40(s1)
}
    800049aa:	60e2                	ld	ra,24(sp)
    800049ac:	6442                	ld	s0,16(sp)
    800049ae:	64a2                	ld	s1,8(sp)
    800049b0:	6902                	ld	s2,0(sp)
    800049b2:	6105                	add	sp,sp,32
    800049b4:	8082                	ret

00000000800049b6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049b6:	1101                	add	sp,sp,-32
    800049b8:	ec06                	sd	ra,24(sp)
    800049ba:	e822                	sd	s0,16(sp)
    800049bc:	e426                	sd	s1,8(sp)
    800049be:	e04a                	sd	s2,0(sp)
    800049c0:	1000                	add	s0,sp,32
    800049c2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049c4:	00850913          	add	s2,a0,8
    800049c8:	854a                	mv	a0,s2
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	46e080e7          	jalr	1134(ra) # 80000e38 <acquire>
  while (lk->locked) {
    800049d2:	409c                	lw	a5,0(s1)
    800049d4:	cb89                	beqz	a5,800049e6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049d6:	85ca                	mv	a1,s2
    800049d8:	8526                	mv	a0,s1
    800049da:	ffffe097          	auipc	ra,0xffffe
    800049de:	9fc080e7          	jalr	-1540(ra) # 800023d6 <sleep>
  while (lk->locked) {
    800049e2:	409c                	lw	a5,0(s1)
    800049e4:	fbed                	bnez	a5,800049d6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049e6:	4785                	li	a5,1
    800049e8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049ea:	ffffd097          	auipc	ra,0xffffd
    800049ee:	21a080e7          	jalr	538(ra) # 80001c04 <myproc>
    800049f2:	591c                	lw	a5,48(a0)
    800049f4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049f6:	854a                	mv	a0,s2
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	4f4080e7          	jalr	1268(ra) # 80000eec <release>
}
    80004a00:	60e2                	ld	ra,24(sp)
    80004a02:	6442                	ld	s0,16(sp)
    80004a04:	64a2                	ld	s1,8(sp)
    80004a06:	6902                	ld	s2,0(sp)
    80004a08:	6105                	add	sp,sp,32
    80004a0a:	8082                	ret

0000000080004a0c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a0c:	1101                	add	sp,sp,-32
    80004a0e:	ec06                	sd	ra,24(sp)
    80004a10:	e822                	sd	s0,16(sp)
    80004a12:	e426                	sd	s1,8(sp)
    80004a14:	e04a                	sd	s2,0(sp)
    80004a16:	1000                	add	s0,sp,32
    80004a18:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a1a:	00850913          	add	s2,a0,8
    80004a1e:	854a                	mv	a0,s2
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	418080e7          	jalr	1048(ra) # 80000e38 <acquire>
  lk->locked = 0;
    80004a28:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a2c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a30:	8526                	mv	a0,s1
    80004a32:	ffffe097          	auipc	ra,0xffffe
    80004a36:	a08080e7          	jalr	-1528(ra) # 8000243a <wakeup>
  release(&lk->lk);
    80004a3a:	854a                	mv	a0,s2
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	4b0080e7          	jalr	1200(ra) # 80000eec <release>
}
    80004a44:	60e2                	ld	ra,24(sp)
    80004a46:	6442                	ld	s0,16(sp)
    80004a48:	64a2                	ld	s1,8(sp)
    80004a4a:	6902                	ld	s2,0(sp)
    80004a4c:	6105                	add	sp,sp,32
    80004a4e:	8082                	ret

0000000080004a50 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a50:	7179                	add	sp,sp,-48
    80004a52:	f406                	sd	ra,40(sp)
    80004a54:	f022                	sd	s0,32(sp)
    80004a56:	ec26                	sd	s1,24(sp)
    80004a58:	e84a                	sd	s2,16(sp)
    80004a5a:	e44e                	sd	s3,8(sp)
    80004a5c:	1800                	add	s0,sp,48
    80004a5e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a60:	00850913          	add	s2,a0,8
    80004a64:	854a                	mv	a0,s2
    80004a66:	ffffc097          	auipc	ra,0xffffc
    80004a6a:	3d2080e7          	jalr	978(ra) # 80000e38 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a6e:	409c                	lw	a5,0(s1)
    80004a70:	ef99                	bnez	a5,80004a8e <holdingsleep+0x3e>
    80004a72:	4481                	li	s1,0
  release(&lk->lk);
    80004a74:	854a                	mv	a0,s2
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	476080e7          	jalr	1142(ra) # 80000eec <release>
  return r;
}
    80004a7e:	8526                	mv	a0,s1
    80004a80:	70a2                	ld	ra,40(sp)
    80004a82:	7402                	ld	s0,32(sp)
    80004a84:	64e2                	ld	s1,24(sp)
    80004a86:	6942                	ld	s2,16(sp)
    80004a88:	69a2                	ld	s3,8(sp)
    80004a8a:	6145                	add	sp,sp,48
    80004a8c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a8e:	0284a983          	lw	s3,40(s1)
    80004a92:	ffffd097          	auipc	ra,0xffffd
    80004a96:	172080e7          	jalr	370(ra) # 80001c04 <myproc>
    80004a9a:	5904                	lw	s1,48(a0)
    80004a9c:	413484b3          	sub	s1,s1,s3
    80004aa0:	0014b493          	seqz	s1,s1
    80004aa4:	bfc1                	j	80004a74 <holdingsleep+0x24>

0000000080004aa6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004aa6:	1141                	add	sp,sp,-16
    80004aa8:	e406                	sd	ra,8(sp)
    80004aaa:	e022                	sd	s0,0(sp)
    80004aac:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004aae:	00004597          	auipc	a1,0x4
    80004ab2:	c1258593          	add	a1,a1,-1006 # 800086c0 <syscalls+0x250>
    80004ab6:	0003d517          	auipc	a0,0x3d
    80004aba:	bea50513          	add	a0,a0,-1046 # 800416a0 <ftable>
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	2ea080e7          	jalr	746(ra) # 80000da8 <initlock>
}
    80004ac6:	60a2                	ld	ra,8(sp)
    80004ac8:	6402                	ld	s0,0(sp)
    80004aca:	0141                	add	sp,sp,16
    80004acc:	8082                	ret

0000000080004ace <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ace:	1101                	add	sp,sp,-32
    80004ad0:	ec06                	sd	ra,24(sp)
    80004ad2:	e822                	sd	s0,16(sp)
    80004ad4:	e426                	sd	s1,8(sp)
    80004ad6:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ad8:	0003d517          	auipc	a0,0x3d
    80004adc:	bc850513          	add	a0,a0,-1080 # 800416a0 <ftable>
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	358080e7          	jalr	856(ra) # 80000e38 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ae8:	0003d497          	auipc	s1,0x3d
    80004aec:	bd048493          	add	s1,s1,-1072 # 800416b8 <ftable+0x18>
    80004af0:	0003e717          	auipc	a4,0x3e
    80004af4:	b6870713          	add	a4,a4,-1176 # 80042658 <disk>
    if(f->ref == 0){
    80004af8:	40dc                	lw	a5,4(s1)
    80004afa:	cf99                	beqz	a5,80004b18 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004afc:	02848493          	add	s1,s1,40
    80004b00:	fee49ce3          	bne	s1,a4,80004af8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b04:	0003d517          	auipc	a0,0x3d
    80004b08:	b9c50513          	add	a0,a0,-1124 # 800416a0 <ftable>
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	3e0080e7          	jalr	992(ra) # 80000eec <release>
  return 0;
    80004b14:	4481                	li	s1,0
    80004b16:	a819                	j	80004b2c <filealloc+0x5e>
      f->ref = 1;
    80004b18:	4785                	li	a5,1
    80004b1a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b1c:	0003d517          	auipc	a0,0x3d
    80004b20:	b8450513          	add	a0,a0,-1148 # 800416a0 <ftable>
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	3c8080e7          	jalr	968(ra) # 80000eec <release>
}
    80004b2c:	8526                	mv	a0,s1
    80004b2e:	60e2                	ld	ra,24(sp)
    80004b30:	6442                	ld	s0,16(sp)
    80004b32:	64a2                	ld	s1,8(sp)
    80004b34:	6105                	add	sp,sp,32
    80004b36:	8082                	ret

0000000080004b38 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b38:	1101                	add	sp,sp,-32
    80004b3a:	ec06                	sd	ra,24(sp)
    80004b3c:	e822                	sd	s0,16(sp)
    80004b3e:	e426                	sd	s1,8(sp)
    80004b40:	1000                	add	s0,sp,32
    80004b42:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b44:	0003d517          	auipc	a0,0x3d
    80004b48:	b5c50513          	add	a0,a0,-1188 # 800416a0 <ftable>
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	2ec080e7          	jalr	748(ra) # 80000e38 <acquire>
  if(f->ref < 1)
    80004b54:	40dc                	lw	a5,4(s1)
    80004b56:	02f05263          	blez	a5,80004b7a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b5a:	2785                	addw	a5,a5,1
    80004b5c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b5e:	0003d517          	auipc	a0,0x3d
    80004b62:	b4250513          	add	a0,a0,-1214 # 800416a0 <ftable>
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	386080e7          	jalr	902(ra) # 80000eec <release>
  return f;
}
    80004b6e:	8526                	mv	a0,s1
    80004b70:	60e2                	ld	ra,24(sp)
    80004b72:	6442                	ld	s0,16(sp)
    80004b74:	64a2                	ld	s1,8(sp)
    80004b76:	6105                	add	sp,sp,32
    80004b78:	8082                	ret
    panic("filedup");
    80004b7a:	00004517          	auipc	a0,0x4
    80004b7e:	b4e50513          	add	a0,a0,-1202 # 800086c8 <syscalls+0x258>
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	9ba080e7          	jalr	-1606(ra) # 8000053c <panic>

0000000080004b8a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b8a:	7139                	add	sp,sp,-64
    80004b8c:	fc06                	sd	ra,56(sp)
    80004b8e:	f822                	sd	s0,48(sp)
    80004b90:	f426                	sd	s1,40(sp)
    80004b92:	f04a                	sd	s2,32(sp)
    80004b94:	ec4e                	sd	s3,24(sp)
    80004b96:	e852                	sd	s4,16(sp)
    80004b98:	e456                	sd	s5,8(sp)
    80004b9a:	0080                	add	s0,sp,64
    80004b9c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b9e:	0003d517          	auipc	a0,0x3d
    80004ba2:	b0250513          	add	a0,a0,-1278 # 800416a0 <ftable>
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	292080e7          	jalr	658(ra) # 80000e38 <acquire>
  if(f->ref < 1)
    80004bae:	40dc                	lw	a5,4(s1)
    80004bb0:	06f05163          	blez	a5,80004c12 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bb4:	37fd                	addw	a5,a5,-1
    80004bb6:	0007871b          	sext.w	a4,a5
    80004bba:	c0dc                	sw	a5,4(s1)
    80004bbc:	06e04363          	bgtz	a4,80004c22 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bc0:	0004a903          	lw	s2,0(s1)
    80004bc4:	0094ca83          	lbu	s5,9(s1)
    80004bc8:	0104ba03          	ld	s4,16(s1)
    80004bcc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bd0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bd4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bd8:	0003d517          	auipc	a0,0x3d
    80004bdc:	ac850513          	add	a0,a0,-1336 # 800416a0 <ftable>
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	30c080e7          	jalr	780(ra) # 80000eec <release>

  if(ff.type == FD_PIPE){
    80004be8:	4785                	li	a5,1
    80004bea:	04f90d63          	beq	s2,a5,80004c44 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004bee:	3979                	addw	s2,s2,-2
    80004bf0:	4785                	li	a5,1
    80004bf2:	0527e063          	bltu	a5,s2,80004c32 <fileclose+0xa8>
    begin_op();
    80004bf6:	00000097          	auipc	ra,0x0
    80004bfa:	ad0080e7          	jalr	-1328(ra) # 800046c6 <begin_op>
    iput(ff.ip);
    80004bfe:	854e                	mv	a0,s3
    80004c00:	fffff097          	auipc	ra,0xfffff
    80004c04:	2da080e7          	jalr	730(ra) # 80003eda <iput>
    end_op();
    80004c08:	00000097          	auipc	ra,0x0
    80004c0c:	b38080e7          	jalr	-1224(ra) # 80004740 <end_op>
    80004c10:	a00d                	j	80004c32 <fileclose+0xa8>
    panic("fileclose");
    80004c12:	00004517          	auipc	a0,0x4
    80004c16:	abe50513          	add	a0,a0,-1346 # 800086d0 <syscalls+0x260>
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	922080e7          	jalr	-1758(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004c22:	0003d517          	auipc	a0,0x3d
    80004c26:	a7e50513          	add	a0,a0,-1410 # 800416a0 <ftable>
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	2c2080e7          	jalr	706(ra) # 80000eec <release>
  }
}
    80004c32:	70e2                	ld	ra,56(sp)
    80004c34:	7442                	ld	s0,48(sp)
    80004c36:	74a2                	ld	s1,40(sp)
    80004c38:	7902                	ld	s2,32(sp)
    80004c3a:	69e2                	ld	s3,24(sp)
    80004c3c:	6a42                	ld	s4,16(sp)
    80004c3e:	6aa2                	ld	s5,8(sp)
    80004c40:	6121                	add	sp,sp,64
    80004c42:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c44:	85d6                	mv	a1,s5
    80004c46:	8552                	mv	a0,s4
    80004c48:	00000097          	auipc	ra,0x0
    80004c4c:	348080e7          	jalr	840(ra) # 80004f90 <pipeclose>
    80004c50:	b7cd                	j	80004c32 <fileclose+0xa8>

0000000080004c52 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c52:	715d                	add	sp,sp,-80
    80004c54:	e486                	sd	ra,72(sp)
    80004c56:	e0a2                	sd	s0,64(sp)
    80004c58:	fc26                	sd	s1,56(sp)
    80004c5a:	f84a                	sd	s2,48(sp)
    80004c5c:	f44e                	sd	s3,40(sp)
    80004c5e:	0880                	add	s0,sp,80
    80004c60:	84aa                	mv	s1,a0
    80004c62:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c64:	ffffd097          	auipc	ra,0xffffd
    80004c68:	fa0080e7          	jalr	-96(ra) # 80001c04 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c6c:	409c                	lw	a5,0(s1)
    80004c6e:	37f9                	addw	a5,a5,-2
    80004c70:	4705                	li	a4,1
    80004c72:	04f76763          	bltu	a4,a5,80004cc0 <filestat+0x6e>
    80004c76:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c78:	6c88                	ld	a0,24(s1)
    80004c7a:	fffff097          	auipc	ra,0xfffff
    80004c7e:	0a6080e7          	jalr	166(ra) # 80003d20 <ilock>
    stati(f->ip, &st);
    80004c82:	fb840593          	add	a1,s0,-72
    80004c86:	6c88                	ld	a0,24(s1)
    80004c88:	fffff097          	auipc	ra,0xfffff
    80004c8c:	322080e7          	jalr	802(ra) # 80003faa <stati>
    iunlock(f->ip);
    80004c90:	6c88                	ld	a0,24(s1)
    80004c92:	fffff097          	auipc	ra,0xfffff
    80004c96:	150080e7          	jalr	336(ra) # 80003de2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c9a:	46e1                	li	a3,24
    80004c9c:	fb840613          	add	a2,s0,-72
    80004ca0:	85ce                	mv	a1,s3
    80004ca2:	05093503          	ld	a0,80(s2)
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	c14080e7          	jalr	-1004(ra) # 800018ba <copyout>
    80004cae:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cb2:	60a6                	ld	ra,72(sp)
    80004cb4:	6406                	ld	s0,64(sp)
    80004cb6:	74e2                	ld	s1,56(sp)
    80004cb8:	7942                	ld	s2,48(sp)
    80004cba:	79a2                	ld	s3,40(sp)
    80004cbc:	6161                	add	sp,sp,80
    80004cbe:	8082                	ret
  return -1;
    80004cc0:	557d                	li	a0,-1
    80004cc2:	bfc5                	j	80004cb2 <filestat+0x60>

0000000080004cc4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004cc4:	7179                	add	sp,sp,-48
    80004cc6:	f406                	sd	ra,40(sp)
    80004cc8:	f022                	sd	s0,32(sp)
    80004cca:	ec26                	sd	s1,24(sp)
    80004ccc:	e84a                	sd	s2,16(sp)
    80004cce:	e44e                	sd	s3,8(sp)
    80004cd0:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cd2:	00854783          	lbu	a5,8(a0)
    80004cd6:	c3d5                	beqz	a5,80004d7a <fileread+0xb6>
    80004cd8:	84aa                	mv	s1,a0
    80004cda:	89ae                	mv	s3,a1
    80004cdc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cde:	411c                	lw	a5,0(a0)
    80004ce0:	4705                	li	a4,1
    80004ce2:	04e78963          	beq	a5,a4,80004d34 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ce6:	470d                	li	a4,3
    80004ce8:	04e78d63          	beq	a5,a4,80004d42 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cec:	4709                	li	a4,2
    80004cee:	06e79e63          	bne	a5,a4,80004d6a <fileread+0xa6>
    ilock(f->ip);
    80004cf2:	6d08                	ld	a0,24(a0)
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	02c080e7          	jalr	44(ra) # 80003d20 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004cfc:	874a                	mv	a4,s2
    80004cfe:	5094                	lw	a3,32(s1)
    80004d00:	864e                	mv	a2,s3
    80004d02:	4585                	li	a1,1
    80004d04:	6c88                	ld	a0,24(s1)
    80004d06:	fffff097          	auipc	ra,0xfffff
    80004d0a:	2ce080e7          	jalr	718(ra) # 80003fd4 <readi>
    80004d0e:	892a                	mv	s2,a0
    80004d10:	00a05563          	blez	a0,80004d1a <fileread+0x56>
      f->off += r;
    80004d14:	509c                	lw	a5,32(s1)
    80004d16:	9fa9                	addw	a5,a5,a0
    80004d18:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d1a:	6c88                	ld	a0,24(s1)
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	0c6080e7          	jalr	198(ra) # 80003de2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d24:	854a                	mv	a0,s2
    80004d26:	70a2                	ld	ra,40(sp)
    80004d28:	7402                	ld	s0,32(sp)
    80004d2a:	64e2                	ld	s1,24(sp)
    80004d2c:	6942                	ld	s2,16(sp)
    80004d2e:	69a2                	ld	s3,8(sp)
    80004d30:	6145                	add	sp,sp,48
    80004d32:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d34:	6908                	ld	a0,16(a0)
    80004d36:	00000097          	auipc	ra,0x0
    80004d3a:	3c2080e7          	jalr	962(ra) # 800050f8 <piperead>
    80004d3e:	892a                	mv	s2,a0
    80004d40:	b7d5                	j	80004d24 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d42:	02451783          	lh	a5,36(a0)
    80004d46:	03079693          	sll	a3,a5,0x30
    80004d4a:	92c1                	srl	a3,a3,0x30
    80004d4c:	4725                	li	a4,9
    80004d4e:	02d76863          	bltu	a4,a3,80004d7e <fileread+0xba>
    80004d52:	0792                	sll	a5,a5,0x4
    80004d54:	0003d717          	auipc	a4,0x3d
    80004d58:	8ac70713          	add	a4,a4,-1876 # 80041600 <devsw>
    80004d5c:	97ba                	add	a5,a5,a4
    80004d5e:	639c                	ld	a5,0(a5)
    80004d60:	c38d                	beqz	a5,80004d82 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d62:	4505                	li	a0,1
    80004d64:	9782                	jalr	a5
    80004d66:	892a                	mv	s2,a0
    80004d68:	bf75                	j	80004d24 <fileread+0x60>
    panic("fileread");
    80004d6a:	00004517          	auipc	a0,0x4
    80004d6e:	97650513          	add	a0,a0,-1674 # 800086e0 <syscalls+0x270>
    80004d72:	ffffb097          	auipc	ra,0xffffb
    80004d76:	7ca080e7          	jalr	1994(ra) # 8000053c <panic>
    return -1;
    80004d7a:	597d                	li	s2,-1
    80004d7c:	b765                	j	80004d24 <fileread+0x60>
      return -1;
    80004d7e:	597d                	li	s2,-1
    80004d80:	b755                	j	80004d24 <fileread+0x60>
    80004d82:	597d                	li	s2,-1
    80004d84:	b745                	j	80004d24 <fileread+0x60>

0000000080004d86 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004d86:	00954783          	lbu	a5,9(a0)
    80004d8a:	10078e63          	beqz	a5,80004ea6 <filewrite+0x120>
{
    80004d8e:	715d                	add	sp,sp,-80
    80004d90:	e486                	sd	ra,72(sp)
    80004d92:	e0a2                	sd	s0,64(sp)
    80004d94:	fc26                	sd	s1,56(sp)
    80004d96:	f84a                	sd	s2,48(sp)
    80004d98:	f44e                	sd	s3,40(sp)
    80004d9a:	f052                	sd	s4,32(sp)
    80004d9c:	ec56                	sd	s5,24(sp)
    80004d9e:	e85a                	sd	s6,16(sp)
    80004da0:	e45e                	sd	s7,8(sp)
    80004da2:	e062                	sd	s8,0(sp)
    80004da4:	0880                	add	s0,sp,80
    80004da6:	892a                	mv	s2,a0
    80004da8:	8b2e                	mv	s6,a1
    80004daa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dac:	411c                	lw	a5,0(a0)
    80004dae:	4705                	li	a4,1
    80004db0:	02e78263          	beq	a5,a4,80004dd4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004db4:	470d                	li	a4,3
    80004db6:	02e78563          	beq	a5,a4,80004de0 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dba:	4709                	li	a4,2
    80004dbc:	0ce79d63          	bne	a5,a4,80004e96 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004dc0:	0ac05b63          	blez	a2,80004e76 <filewrite+0xf0>
    int i = 0;
    80004dc4:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004dc6:	6b85                	lui	s7,0x1
    80004dc8:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004dcc:	6c05                	lui	s8,0x1
    80004dce:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004dd2:	a851                	j	80004e66 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004dd4:	6908                	ld	a0,16(a0)
    80004dd6:	00000097          	auipc	ra,0x0
    80004dda:	22a080e7          	jalr	554(ra) # 80005000 <pipewrite>
    80004dde:	a045                	j	80004e7e <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004de0:	02451783          	lh	a5,36(a0)
    80004de4:	03079693          	sll	a3,a5,0x30
    80004de8:	92c1                	srl	a3,a3,0x30
    80004dea:	4725                	li	a4,9
    80004dec:	0ad76f63          	bltu	a4,a3,80004eaa <filewrite+0x124>
    80004df0:	0792                	sll	a5,a5,0x4
    80004df2:	0003d717          	auipc	a4,0x3d
    80004df6:	80e70713          	add	a4,a4,-2034 # 80041600 <devsw>
    80004dfa:	97ba                	add	a5,a5,a4
    80004dfc:	679c                	ld	a5,8(a5)
    80004dfe:	cbc5                	beqz	a5,80004eae <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004e00:	4505                	li	a0,1
    80004e02:	9782                	jalr	a5
    80004e04:	a8ad                	j	80004e7e <filewrite+0xf8>
      if(n1 > max)
    80004e06:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004e0a:	00000097          	auipc	ra,0x0
    80004e0e:	8bc080e7          	jalr	-1860(ra) # 800046c6 <begin_op>
      ilock(f->ip);
    80004e12:	01893503          	ld	a0,24(s2)
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	f0a080e7          	jalr	-246(ra) # 80003d20 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e1e:	8756                	mv	a4,s5
    80004e20:	02092683          	lw	a3,32(s2)
    80004e24:	01698633          	add	a2,s3,s6
    80004e28:	4585                	li	a1,1
    80004e2a:	01893503          	ld	a0,24(s2)
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	29e080e7          	jalr	670(ra) # 800040cc <writei>
    80004e36:	84aa                	mv	s1,a0
    80004e38:	00a05763          	blez	a0,80004e46 <filewrite+0xc0>
        f->off += r;
    80004e3c:	02092783          	lw	a5,32(s2)
    80004e40:	9fa9                	addw	a5,a5,a0
    80004e42:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e46:	01893503          	ld	a0,24(s2)
    80004e4a:	fffff097          	auipc	ra,0xfffff
    80004e4e:	f98080e7          	jalr	-104(ra) # 80003de2 <iunlock>
      end_op();
    80004e52:	00000097          	auipc	ra,0x0
    80004e56:	8ee080e7          	jalr	-1810(ra) # 80004740 <end_op>

      if(r != n1){
    80004e5a:	009a9f63          	bne	s5,s1,80004e78 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004e5e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e62:	0149db63          	bge	s3,s4,80004e78 <filewrite+0xf2>
      int n1 = n - i;
    80004e66:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004e6a:	0004879b          	sext.w	a5,s1
    80004e6e:	f8fbdce3          	bge	s7,a5,80004e06 <filewrite+0x80>
    80004e72:	84e2                	mv	s1,s8
    80004e74:	bf49                	j	80004e06 <filewrite+0x80>
    int i = 0;
    80004e76:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e78:	033a1d63          	bne	s4,s3,80004eb2 <filewrite+0x12c>
    80004e7c:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e7e:	60a6                	ld	ra,72(sp)
    80004e80:	6406                	ld	s0,64(sp)
    80004e82:	74e2                	ld	s1,56(sp)
    80004e84:	7942                	ld	s2,48(sp)
    80004e86:	79a2                	ld	s3,40(sp)
    80004e88:	7a02                	ld	s4,32(sp)
    80004e8a:	6ae2                	ld	s5,24(sp)
    80004e8c:	6b42                	ld	s6,16(sp)
    80004e8e:	6ba2                	ld	s7,8(sp)
    80004e90:	6c02                	ld	s8,0(sp)
    80004e92:	6161                	add	sp,sp,80
    80004e94:	8082                	ret
    panic("filewrite");
    80004e96:	00004517          	auipc	a0,0x4
    80004e9a:	85a50513          	add	a0,a0,-1958 # 800086f0 <syscalls+0x280>
    80004e9e:	ffffb097          	auipc	ra,0xffffb
    80004ea2:	69e080e7          	jalr	1694(ra) # 8000053c <panic>
    return -1;
    80004ea6:	557d                	li	a0,-1
}
    80004ea8:	8082                	ret
      return -1;
    80004eaa:	557d                	li	a0,-1
    80004eac:	bfc9                	j	80004e7e <filewrite+0xf8>
    80004eae:	557d                	li	a0,-1
    80004eb0:	b7f9                	j	80004e7e <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004eb2:	557d                	li	a0,-1
    80004eb4:	b7e9                	j	80004e7e <filewrite+0xf8>

0000000080004eb6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004eb6:	7179                	add	sp,sp,-48
    80004eb8:	f406                	sd	ra,40(sp)
    80004eba:	f022                	sd	s0,32(sp)
    80004ebc:	ec26                	sd	s1,24(sp)
    80004ebe:	e84a                	sd	s2,16(sp)
    80004ec0:	e44e                	sd	s3,8(sp)
    80004ec2:	e052                	sd	s4,0(sp)
    80004ec4:	1800                	add	s0,sp,48
    80004ec6:	84aa                	mv	s1,a0
    80004ec8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004eca:	0005b023          	sd	zero,0(a1)
    80004ece:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ed2:	00000097          	auipc	ra,0x0
    80004ed6:	bfc080e7          	jalr	-1028(ra) # 80004ace <filealloc>
    80004eda:	e088                	sd	a0,0(s1)
    80004edc:	c551                	beqz	a0,80004f68 <pipealloc+0xb2>
    80004ede:	00000097          	auipc	ra,0x0
    80004ee2:	bf0080e7          	jalr	-1040(ra) # 80004ace <filealloc>
    80004ee6:	00aa3023          	sd	a0,0(s4)
    80004eea:	c92d                	beqz	a0,80004f5c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	c6c080e7          	jalr	-916(ra) # 80000b58 <kalloc>
    80004ef4:	892a                	mv	s2,a0
    80004ef6:	c125                	beqz	a0,80004f56 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ef8:	4985                	li	s3,1
    80004efa:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004efe:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f02:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f06:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f0a:	00003597          	auipc	a1,0x3
    80004f0e:	7f658593          	add	a1,a1,2038 # 80008700 <syscalls+0x290>
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	e96080e7          	jalr	-362(ra) # 80000da8 <initlock>
  (*f0)->type = FD_PIPE;
    80004f1a:	609c                	ld	a5,0(s1)
    80004f1c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f20:	609c                	ld	a5,0(s1)
    80004f22:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f26:	609c                	ld	a5,0(s1)
    80004f28:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f2c:	609c                	ld	a5,0(s1)
    80004f2e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f32:	000a3783          	ld	a5,0(s4)
    80004f36:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f3a:	000a3783          	ld	a5,0(s4)
    80004f3e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f42:	000a3783          	ld	a5,0(s4)
    80004f46:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f4a:	000a3783          	ld	a5,0(s4)
    80004f4e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f52:	4501                	li	a0,0
    80004f54:	a025                	j	80004f7c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f56:	6088                	ld	a0,0(s1)
    80004f58:	e501                	bnez	a0,80004f60 <pipealloc+0xaa>
    80004f5a:	a039                	j	80004f68 <pipealloc+0xb2>
    80004f5c:	6088                	ld	a0,0(s1)
    80004f5e:	c51d                	beqz	a0,80004f8c <pipealloc+0xd6>
    fileclose(*f0);
    80004f60:	00000097          	auipc	ra,0x0
    80004f64:	c2a080e7          	jalr	-982(ra) # 80004b8a <fileclose>
  if(*f1)
    80004f68:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f6c:	557d                	li	a0,-1
  if(*f1)
    80004f6e:	c799                	beqz	a5,80004f7c <pipealloc+0xc6>
    fileclose(*f1);
    80004f70:	853e                	mv	a0,a5
    80004f72:	00000097          	auipc	ra,0x0
    80004f76:	c18080e7          	jalr	-1000(ra) # 80004b8a <fileclose>
  return -1;
    80004f7a:	557d                	li	a0,-1
}
    80004f7c:	70a2                	ld	ra,40(sp)
    80004f7e:	7402                	ld	s0,32(sp)
    80004f80:	64e2                	ld	s1,24(sp)
    80004f82:	6942                	ld	s2,16(sp)
    80004f84:	69a2                	ld	s3,8(sp)
    80004f86:	6a02                	ld	s4,0(sp)
    80004f88:	6145                	add	sp,sp,48
    80004f8a:	8082                	ret
  return -1;
    80004f8c:	557d                	li	a0,-1
    80004f8e:	b7fd                	j	80004f7c <pipealloc+0xc6>

0000000080004f90 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f90:	1101                	add	sp,sp,-32
    80004f92:	ec06                	sd	ra,24(sp)
    80004f94:	e822                	sd	s0,16(sp)
    80004f96:	e426                	sd	s1,8(sp)
    80004f98:	e04a                	sd	s2,0(sp)
    80004f9a:	1000                	add	s0,sp,32
    80004f9c:	84aa                	mv	s1,a0
    80004f9e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	e98080e7          	jalr	-360(ra) # 80000e38 <acquire>
  if(writable){
    80004fa8:	02090d63          	beqz	s2,80004fe2 <pipeclose+0x52>
    pi->writeopen = 0;
    80004fac:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fb0:	21848513          	add	a0,s1,536
    80004fb4:	ffffd097          	auipc	ra,0xffffd
    80004fb8:	486080e7          	jalr	1158(ra) # 8000243a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fbc:	2204b783          	ld	a5,544(s1)
    80004fc0:	eb95                	bnez	a5,80004ff4 <pipeclose+0x64>
    release(&pi->lock);
    80004fc2:	8526                	mv	a0,s1
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	f28080e7          	jalr	-216(ra) # 80000eec <release>
    kfree((char*)pi);
    80004fcc:	8526                	mv	a0,s1
    80004fce:	ffffc097          	auipc	ra,0xffffc
    80004fd2:	a16080e7          	jalr	-1514(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004fd6:	60e2                	ld	ra,24(sp)
    80004fd8:	6442                	ld	s0,16(sp)
    80004fda:	64a2                	ld	s1,8(sp)
    80004fdc:	6902                	ld	s2,0(sp)
    80004fde:	6105                	add	sp,sp,32
    80004fe0:	8082                	ret
    pi->readopen = 0;
    80004fe2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004fe6:	21c48513          	add	a0,s1,540
    80004fea:	ffffd097          	auipc	ra,0xffffd
    80004fee:	450080e7          	jalr	1104(ra) # 8000243a <wakeup>
    80004ff2:	b7e9                	j	80004fbc <pipeclose+0x2c>
    release(&pi->lock);
    80004ff4:	8526                	mv	a0,s1
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	ef6080e7          	jalr	-266(ra) # 80000eec <release>
}
    80004ffe:	bfe1                	j	80004fd6 <pipeclose+0x46>

0000000080005000 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005000:	711d                	add	sp,sp,-96
    80005002:	ec86                	sd	ra,88(sp)
    80005004:	e8a2                	sd	s0,80(sp)
    80005006:	e4a6                	sd	s1,72(sp)
    80005008:	e0ca                	sd	s2,64(sp)
    8000500a:	fc4e                	sd	s3,56(sp)
    8000500c:	f852                	sd	s4,48(sp)
    8000500e:	f456                	sd	s5,40(sp)
    80005010:	f05a                	sd	s6,32(sp)
    80005012:	ec5e                	sd	s7,24(sp)
    80005014:	e862                	sd	s8,16(sp)
    80005016:	1080                	add	s0,sp,96
    80005018:	84aa                	mv	s1,a0
    8000501a:	8aae                	mv	s5,a1
    8000501c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000501e:	ffffd097          	auipc	ra,0xffffd
    80005022:	be6080e7          	jalr	-1050(ra) # 80001c04 <myproc>
    80005026:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005028:	8526                	mv	a0,s1
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	e0e080e7          	jalr	-498(ra) # 80000e38 <acquire>
  while(i < n){
    80005032:	0b405663          	blez	s4,800050de <pipewrite+0xde>
  int i = 0;
    80005036:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005038:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000503a:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000503e:	21c48b93          	add	s7,s1,540
    80005042:	a089                	j	80005084 <pipewrite+0x84>
      release(&pi->lock);
    80005044:	8526                	mv	a0,s1
    80005046:	ffffc097          	auipc	ra,0xffffc
    8000504a:	ea6080e7          	jalr	-346(ra) # 80000eec <release>
      return -1;
    8000504e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005050:	854a                	mv	a0,s2
    80005052:	60e6                	ld	ra,88(sp)
    80005054:	6446                	ld	s0,80(sp)
    80005056:	64a6                	ld	s1,72(sp)
    80005058:	6906                	ld	s2,64(sp)
    8000505a:	79e2                	ld	s3,56(sp)
    8000505c:	7a42                	ld	s4,48(sp)
    8000505e:	7aa2                	ld	s5,40(sp)
    80005060:	7b02                	ld	s6,32(sp)
    80005062:	6be2                	ld	s7,24(sp)
    80005064:	6c42                	ld	s8,16(sp)
    80005066:	6125                	add	sp,sp,96
    80005068:	8082                	ret
      wakeup(&pi->nread);
    8000506a:	8562                	mv	a0,s8
    8000506c:	ffffd097          	auipc	ra,0xffffd
    80005070:	3ce080e7          	jalr	974(ra) # 8000243a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005074:	85a6                	mv	a1,s1
    80005076:	855e                	mv	a0,s7
    80005078:	ffffd097          	auipc	ra,0xffffd
    8000507c:	35e080e7          	jalr	862(ra) # 800023d6 <sleep>
  while(i < n){
    80005080:	07495063          	bge	s2,s4,800050e0 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005084:	2204a783          	lw	a5,544(s1)
    80005088:	dfd5                	beqz	a5,80005044 <pipewrite+0x44>
    8000508a:	854e                	mv	a0,s3
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	5fe080e7          	jalr	1534(ra) # 8000268a <killed>
    80005094:	f945                	bnez	a0,80005044 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005096:	2184a783          	lw	a5,536(s1)
    8000509a:	21c4a703          	lw	a4,540(s1)
    8000509e:	2007879b          	addw	a5,a5,512
    800050a2:	fcf704e3          	beq	a4,a5,8000506a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050a6:	4685                	li	a3,1
    800050a8:	01590633          	add	a2,s2,s5
    800050ac:	faf40593          	add	a1,s0,-81
    800050b0:	0509b503          	ld	a0,80(s3)
    800050b4:	ffffd097          	auipc	ra,0xffffd
    800050b8:	89c080e7          	jalr	-1892(ra) # 80001950 <copyin>
    800050bc:	03650263          	beq	a0,s6,800050e0 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050c0:	21c4a783          	lw	a5,540(s1)
    800050c4:	0017871b          	addw	a4,a5,1
    800050c8:	20e4ae23          	sw	a4,540(s1)
    800050cc:	1ff7f793          	and	a5,a5,511
    800050d0:	97a6                	add	a5,a5,s1
    800050d2:	faf44703          	lbu	a4,-81(s0)
    800050d6:	00e78c23          	sb	a4,24(a5)
      i++;
    800050da:	2905                	addw	s2,s2,1
    800050dc:	b755                	j	80005080 <pipewrite+0x80>
  int i = 0;
    800050de:	4901                	li	s2,0
  wakeup(&pi->nread);
    800050e0:	21848513          	add	a0,s1,536
    800050e4:	ffffd097          	auipc	ra,0xffffd
    800050e8:	356080e7          	jalr	854(ra) # 8000243a <wakeup>
  release(&pi->lock);
    800050ec:	8526                	mv	a0,s1
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	dfe080e7          	jalr	-514(ra) # 80000eec <release>
  return i;
    800050f6:	bfa9                	j	80005050 <pipewrite+0x50>

00000000800050f8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800050f8:	715d                	add	sp,sp,-80
    800050fa:	e486                	sd	ra,72(sp)
    800050fc:	e0a2                	sd	s0,64(sp)
    800050fe:	fc26                	sd	s1,56(sp)
    80005100:	f84a                	sd	s2,48(sp)
    80005102:	f44e                	sd	s3,40(sp)
    80005104:	f052                	sd	s4,32(sp)
    80005106:	ec56                	sd	s5,24(sp)
    80005108:	e85a                	sd	s6,16(sp)
    8000510a:	0880                	add	s0,sp,80
    8000510c:	84aa                	mv	s1,a0
    8000510e:	892e                	mv	s2,a1
    80005110:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005112:	ffffd097          	auipc	ra,0xffffd
    80005116:	af2080e7          	jalr	-1294(ra) # 80001c04 <myproc>
    8000511a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000511c:	8526                	mv	a0,s1
    8000511e:	ffffc097          	auipc	ra,0xffffc
    80005122:	d1a080e7          	jalr	-742(ra) # 80000e38 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005126:	2184a703          	lw	a4,536(s1)
    8000512a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000512e:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005132:	02f71763          	bne	a4,a5,80005160 <piperead+0x68>
    80005136:	2244a783          	lw	a5,548(s1)
    8000513a:	c39d                	beqz	a5,80005160 <piperead+0x68>
    if(killed(pr)){
    8000513c:	8552                	mv	a0,s4
    8000513e:	ffffd097          	auipc	ra,0xffffd
    80005142:	54c080e7          	jalr	1356(ra) # 8000268a <killed>
    80005146:	e949                	bnez	a0,800051d8 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005148:	85a6                	mv	a1,s1
    8000514a:	854e                	mv	a0,s3
    8000514c:	ffffd097          	auipc	ra,0xffffd
    80005150:	28a080e7          	jalr	650(ra) # 800023d6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005154:	2184a703          	lw	a4,536(s1)
    80005158:	21c4a783          	lw	a5,540(s1)
    8000515c:	fcf70de3          	beq	a4,a5,80005136 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005160:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005162:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005164:	05505463          	blez	s5,800051ac <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005168:	2184a783          	lw	a5,536(s1)
    8000516c:	21c4a703          	lw	a4,540(s1)
    80005170:	02f70e63          	beq	a4,a5,800051ac <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005174:	0017871b          	addw	a4,a5,1
    80005178:	20e4ac23          	sw	a4,536(s1)
    8000517c:	1ff7f793          	and	a5,a5,511
    80005180:	97a6                	add	a5,a5,s1
    80005182:	0187c783          	lbu	a5,24(a5)
    80005186:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000518a:	4685                	li	a3,1
    8000518c:	fbf40613          	add	a2,s0,-65
    80005190:	85ca                	mv	a1,s2
    80005192:	050a3503          	ld	a0,80(s4)
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	724080e7          	jalr	1828(ra) # 800018ba <copyout>
    8000519e:	01650763          	beq	a0,s6,800051ac <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051a2:	2985                	addw	s3,s3,1
    800051a4:	0905                	add	s2,s2,1
    800051a6:	fd3a91e3          	bne	s5,s3,80005168 <piperead+0x70>
    800051aa:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051ac:	21c48513          	add	a0,s1,540
    800051b0:	ffffd097          	auipc	ra,0xffffd
    800051b4:	28a080e7          	jalr	650(ra) # 8000243a <wakeup>
  release(&pi->lock);
    800051b8:	8526                	mv	a0,s1
    800051ba:	ffffc097          	auipc	ra,0xffffc
    800051be:	d32080e7          	jalr	-718(ra) # 80000eec <release>
  return i;
}
    800051c2:	854e                	mv	a0,s3
    800051c4:	60a6                	ld	ra,72(sp)
    800051c6:	6406                	ld	s0,64(sp)
    800051c8:	74e2                	ld	s1,56(sp)
    800051ca:	7942                	ld	s2,48(sp)
    800051cc:	79a2                	ld	s3,40(sp)
    800051ce:	7a02                	ld	s4,32(sp)
    800051d0:	6ae2                	ld	s5,24(sp)
    800051d2:	6b42                	ld	s6,16(sp)
    800051d4:	6161                	add	sp,sp,80
    800051d6:	8082                	ret
      release(&pi->lock);
    800051d8:	8526                	mv	a0,s1
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	d12080e7          	jalr	-750(ra) # 80000eec <release>
      return -1;
    800051e2:	59fd                	li	s3,-1
    800051e4:	bff9                	j	800051c2 <piperead+0xca>

00000000800051e6 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800051e6:	1141                	add	sp,sp,-16
    800051e8:	e422                	sd	s0,8(sp)
    800051ea:	0800                	add	s0,sp,16
    800051ec:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800051ee:	8905                	and	a0,a0,1
    800051f0:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800051f2:	8b89                	and	a5,a5,2
    800051f4:	c399                	beqz	a5,800051fa <flags2perm+0x14>
      perm |= PTE_W;
    800051f6:	00456513          	or	a0,a0,4
    return perm;
}
    800051fa:	6422                	ld	s0,8(sp)
    800051fc:	0141                	add	sp,sp,16
    800051fe:	8082                	ret

0000000080005200 <exec>:

int
exec(char *path, char **argv)
{
    80005200:	df010113          	add	sp,sp,-528
    80005204:	20113423          	sd	ra,520(sp)
    80005208:	20813023          	sd	s0,512(sp)
    8000520c:	ffa6                	sd	s1,504(sp)
    8000520e:	fbca                	sd	s2,496(sp)
    80005210:	f7ce                	sd	s3,488(sp)
    80005212:	f3d2                	sd	s4,480(sp)
    80005214:	efd6                	sd	s5,472(sp)
    80005216:	ebda                	sd	s6,464(sp)
    80005218:	e7de                	sd	s7,456(sp)
    8000521a:	e3e2                	sd	s8,448(sp)
    8000521c:	ff66                	sd	s9,440(sp)
    8000521e:	fb6a                	sd	s10,432(sp)
    80005220:	f76e                	sd	s11,424(sp)
    80005222:	0c00                	add	s0,sp,528
    80005224:	892a                	mv	s2,a0
    80005226:	dea43c23          	sd	a0,-520(s0)
    8000522a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000522e:	ffffd097          	auipc	ra,0xffffd
    80005232:	9d6080e7          	jalr	-1578(ra) # 80001c04 <myproc>
    80005236:	84aa                	mv	s1,a0

  begin_op();
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	48e080e7          	jalr	1166(ra) # 800046c6 <begin_op>

  if((ip = namei(path)) == 0){
    80005240:	854a                	mv	a0,s2
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	284080e7          	jalr	644(ra) # 800044c6 <namei>
    8000524a:	c92d                	beqz	a0,800052bc <exec+0xbc>
    8000524c:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000524e:	fffff097          	auipc	ra,0xfffff
    80005252:	ad2080e7          	jalr	-1326(ra) # 80003d20 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005256:	04000713          	li	a4,64
    8000525a:	4681                	li	a3,0
    8000525c:	e5040613          	add	a2,s0,-432
    80005260:	4581                	li	a1,0
    80005262:	8552                	mv	a0,s4
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	d70080e7          	jalr	-656(ra) # 80003fd4 <readi>
    8000526c:	04000793          	li	a5,64
    80005270:	00f51a63          	bne	a0,a5,80005284 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005274:	e5042703          	lw	a4,-432(s0)
    80005278:	464c47b7          	lui	a5,0x464c4
    8000527c:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005280:	04f70463          	beq	a4,a5,800052c8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005284:	8552                	mv	a0,s4
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	cfc080e7          	jalr	-772(ra) # 80003f82 <iunlockput>
    end_op();
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	4b2080e7          	jalr	1202(ra) # 80004740 <end_op>
  }
  return -1;
    80005296:	557d                	li	a0,-1
}
    80005298:	20813083          	ld	ra,520(sp)
    8000529c:	20013403          	ld	s0,512(sp)
    800052a0:	74fe                	ld	s1,504(sp)
    800052a2:	795e                	ld	s2,496(sp)
    800052a4:	79be                	ld	s3,488(sp)
    800052a6:	7a1e                	ld	s4,480(sp)
    800052a8:	6afe                	ld	s5,472(sp)
    800052aa:	6b5e                	ld	s6,464(sp)
    800052ac:	6bbe                	ld	s7,456(sp)
    800052ae:	6c1e                	ld	s8,448(sp)
    800052b0:	7cfa                	ld	s9,440(sp)
    800052b2:	7d5a                	ld	s10,432(sp)
    800052b4:	7dba                	ld	s11,424(sp)
    800052b6:	21010113          	add	sp,sp,528
    800052ba:	8082                	ret
    end_op();
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	484080e7          	jalr	1156(ra) # 80004740 <end_op>
    return -1;
    800052c4:	557d                	li	a0,-1
    800052c6:	bfc9                	j	80005298 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800052c8:	8526                	mv	a0,s1
    800052ca:	ffffd097          	auipc	ra,0xffffd
    800052ce:	9fe080e7          	jalr	-1538(ra) # 80001cc8 <proc_pagetable>
    800052d2:	8b2a                	mv	s6,a0
    800052d4:	d945                	beqz	a0,80005284 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052d6:	e7042d03          	lw	s10,-400(s0)
    800052da:	e8845783          	lhu	a5,-376(s0)
    800052de:	10078463          	beqz	a5,800053e6 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052e2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052e4:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    800052e6:	6c85                	lui	s9,0x1
    800052e8:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    800052ec:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800052f0:	6a85                	lui	s5,0x1
    800052f2:	a0b5                	j	8000535e <exec+0x15e>
      panic("loadseg: address should exist");
    800052f4:	00003517          	auipc	a0,0x3
    800052f8:	41450513          	add	a0,a0,1044 # 80008708 <syscalls+0x298>
    800052fc:	ffffb097          	auipc	ra,0xffffb
    80005300:	240080e7          	jalr	576(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005304:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005306:	8726                	mv	a4,s1
    80005308:	012c06bb          	addw	a3,s8,s2
    8000530c:	4581                	li	a1,0
    8000530e:	8552                	mv	a0,s4
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	cc4080e7          	jalr	-828(ra) # 80003fd4 <readi>
    80005318:	2501                	sext.w	a0,a0
    8000531a:	24a49863          	bne	s1,a0,8000556a <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    8000531e:	012a893b          	addw	s2,s5,s2
    80005322:	03397563          	bgeu	s2,s3,8000534c <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005326:	02091593          	sll	a1,s2,0x20
    8000532a:	9181                	srl	a1,a1,0x20
    8000532c:	95de                	add	a1,a1,s7
    8000532e:	855a                	mv	a0,s6
    80005330:	ffffc097          	auipc	ra,0xffffc
    80005334:	f8c080e7          	jalr	-116(ra) # 800012bc <walkaddr>
    80005338:	862a                	mv	a2,a0
    if(pa == 0)
    8000533a:	dd4d                	beqz	a0,800052f4 <exec+0xf4>
    if(sz - i < PGSIZE)
    8000533c:	412984bb          	subw	s1,s3,s2
    80005340:	0004879b          	sext.w	a5,s1
    80005344:	fcfcf0e3          	bgeu	s9,a5,80005304 <exec+0x104>
    80005348:	84d6                	mv	s1,s5
    8000534a:	bf6d                	j	80005304 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000534c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005350:	2d85                	addw	s11,s11,1
    80005352:	038d0d1b          	addw	s10,s10,56
    80005356:	e8845783          	lhu	a5,-376(s0)
    8000535a:	08fdd763          	bge	s11,a5,800053e8 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000535e:	2d01                	sext.w	s10,s10
    80005360:	03800713          	li	a4,56
    80005364:	86ea                	mv	a3,s10
    80005366:	e1840613          	add	a2,s0,-488
    8000536a:	4581                	li	a1,0
    8000536c:	8552                	mv	a0,s4
    8000536e:	fffff097          	auipc	ra,0xfffff
    80005372:	c66080e7          	jalr	-922(ra) # 80003fd4 <readi>
    80005376:	03800793          	li	a5,56
    8000537a:	1ef51663          	bne	a0,a5,80005566 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    8000537e:	e1842783          	lw	a5,-488(s0)
    80005382:	4705                	li	a4,1
    80005384:	fce796e3          	bne	a5,a4,80005350 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005388:	e4043483          	ld	s1,-448(s0)
    8000538c:	e3843783          	ld	a5,-456(s0)
    80005390:	1ef4e863          	bltu	s1,a5,80005580 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005394:	e2843783          	ld	a5,-472(s0)
    80005398:	94be                	add	s1,s1,a5
    8000539a:	1ef4e663          	bltu	s1,a5,80005586 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    8000539e:	df043703          	ld	a4,-528(s0)
    800053a2:	8ff9                	and	a5,a5,a4
    800053a4:	1e079463          	bnez	a5,8000558c <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053a8:	e1c42503          	lw	a0,-484(s0)
    800053ac:	00000097          	auipc	ra,0x0
    800053b0:	e3a080e7          	jalr	-454(ra) # 800051e6 <flags2perm>
    800053b4:	86aa                	mv	a3,a0
    800053b6:	8626                	mv	a2,s1
    800053b8:	85ca                	mv	a1,s2
    800053ba:	855a                	mv	a0,s6
    800053bc:	ffffc097          	auipc	ra,0xffffc
    800053c0:	2b4080e7          	jalr	692(ra) # 80001670 <uvmalloc>
    800053c4:	e0a43423          	sd	a0,-504(s0)
    800053c8:	1c050563          	beqz	a0,80005592 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053cc:	e2843b83          	ld	s7,-472(s0)
    800053d0:	e2042c03          	lw	s8,-480(s0)
    800053d4:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053d8:	00098463          	beqz	s3,800053e0 <exec+0x1e0>
    800053dc:	4901                	li	s2,0
    800053de:	b7a1                	j	80005326 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053e0:	e0843903          	ld	s2,-504(s0)
    800053e4:	b7b5                	j	80005350 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053e6:	4901                	li	s2,0
  iunlockput(ip);
    800053e8:	8552                	mv	a0,s4
    800053ea:	fffff097          	auipc	ra,0xfffff
    800053ee:	b98080e7          	jalr	-1128(ra) # 80003f82 <iunlockput>
  end_op();
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	34e080e7          	jalr	846(ra) # 80004740 <end_op>
  p = myproc();
    800053fa:	ffffd097          	auipc	ra,0xffffd
    800053fe:	80a080e7          	jalr	-2038(ra) # 80001c04 <myproc>
    80005402:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005404:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005408:	6985                	lui	s3,0x1
    8000540a:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000540c:	99ca                	add	s3,s3,s2
    8000540e:	77fd                	lui	a5,0xfffff
    80005410:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005414:	4691                	li	a3,4
    80005416:	6609                	lui	a2,0x2
    80005418:	964e                	add	a2,a2,s3
    8000541a:	85ce                	mv	a1,s3
    8000541c:	855a                	mv	a0,s6
    8000541e:	ffffc097          	auipc	ra,0xffffc
    80005422:	252080e7          	jalr	594(ra) # 80001670 <uvmalloc>
    80005426:	892a                	mv	s2,a0
    80005428:	e0a43423          	sd	a0,-504(s0)
    8000542c:	e509                	bnez	a0,80005436 <exec+0x236>
  if(pagetable)
    8000542e:	e1343423          	sd	s3,-504(s0)
    80005432:	4a01                	li	s4,0
    80005434:	aa1d                	j	8000556a <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005436:	75f9                	lui	a1,0xffffe
    80005438:	95aa                	add	a1,a1,a0
    8000543a:	855a                	mv	a0,s6
    8000543c:	ffffc097          	auipc	ra,0xffffc
    80005440:	44c080e7          	jalr	1100(ra) # 80001888 <uvmclear>
  stackbase = sp - PGSIZE;
    80005444:	7bfd                	lui	s7,0xfffff
    80005446:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005448:	e0043783          	ld	a5,-512(s0)
    8000544c:	6388                	ld	a0,0(a5)
    8000544e:	c52d                	beqz	a0,800054b8 <exec+0x2b8>
    80005450:	e9040993          	add	s3,s0,-368
    80005454:	f9040c13          	add	s8,s0,-112
    80005458:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000545a:	ffffc097          	auipc	ra,0xffffc
    8000545e:	c54080e7          	jalr	-940(ra) # 800010ae <strlen>
    80005462:	0015079b          	addw	a5,a0,1
    80005466:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000546a:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    8000546e:	13796563          	bltu	s2,s7,80005598 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005472:	e0043d03          	ld	s10,-512(s0)
    80005476:	000d3a03          	ld	s4,0(s10)
    8000547a:	8552                	mv	a0,s4
    8000547c:	ffffc097          	auipc	ra,0xffffc
    80005480:	c32080e7          	jalr	-974(ra) # 800010ae <strlen>
    80005484:	0015069b          	addw	a3,a0,1
    80005488:	8652                	mv	a2,s4
    8000548a:	85ca                	mv	a1,s2
    8000548c:	855a                	mv	a0,s6
    8000548e:	ffffc097          	auipc	ra,0xffffc
    80005492:	42c080e7          	jalr	1068(ra) # 800018ba <copyout>
    80005496:	10054363          	bltz	a0,8000559c <exec+0x39c>
    ustack[argc] = sp;
    8000549a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000549e:	0485                	add	s1,s1,1
    800054a0:	008d0793          	add	a5,s10,8
    800054a4:	e0f43023          	sd	a5,-512(s0)
    800054a8:	008d3503          	ld	a0,8(s10)
    800054ac:	c909                	beqz	a0,800054be <exec+0x2be>
    if(argc >= MAXARG)
    800054ae:	09a1                	add	s3,s3,8
    800054b0:	fb8995e3          	bne	s3,s8,8000545a <exec+0x25a>
  ip = 0;
    800054b4:	4a01                	li	s4,0
    800054b6:	a855                	j	8000556a <exec+0x36a>
  sp = sz;
    800054b8:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800054bc:	4481                	li	s1,0
  ustack[argc] = 0;
    800054be:	00349793          	sll	a5,s1,0x3
    800054c2:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffbc7f8>
    800054c6:	97a2                	add	a5,a5,s0
    800054c8:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800054cc:	00148693          	add	a3,s1,1
    800054d0:	068e                	sll	a3,a3,0x3
    800054d2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800054d6:	ff097913          	and	s2,s2,-16
  sz = sz1;
    800054da:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800054de:	f57968e3          	bltu	s2,s7,8000542e <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800054e2:	e9040613          	add	a2,s0,-368
    800054e6:	85ca                	mv	a1,s2
    800054e8:	855a                	mv	a0,s6
    800054ea:	ffffc097          	auipc	ra,0xffffc
    800054ee:	3d0080e7          	jalr	976(ra) # 800018ba <copyout>
    800054f2:	0a054763          	bltz	a0,800055a0 <exec+0x3a0>
  p->trapframe->a1 = sp;
    800054f6:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800054fa:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800054fe:	df843783          	ld	a5,-520(s0)
    80005502:	0007c703          	lbu	a4,0(a5)
    80005506:	cf11                	beqz	a4,80005522 <exec+0x322>
    80005508:	0785                	add	a5,a5,1
    if(*s == '/')
    8000550a:	02f00693          	li	a3,47
    8000550e:	a039                	j	8000551c <exec+0x31c>
      last = s+1;
    80005510:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005514:	0785                	add	a5,a5,1
    80005516:	fff7c703          	lbu	a4,-1(a5)
    8000551a:	c701                	beqz	a4,80005522 <exec+0x322>
    if(*s == '/')
    8000551c:	fed71ce3          	bne	a4,a3,80005514 <exec+0x314>
    80005520:	bfc5                	j	80005510 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005522:	4641                	li	a2,16
    80005524:	df843583          	ld	a1,-520(s0)
    80005528:	158a8513          	add	a0,s5,344
    8000552c:	ffffc097          	auipc	ra,0xffffc
    80005530:	b50080e7          	jalr	-1200(ra) # 8000107c <safestrcpy>
  oldpagetable = p->pagetable;
    80005534:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005538:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000553c:	e0843783          	ld	a5,-504(s0)
    80005540:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005544:	058ab783          	ld	a5,88(s5)
    80005548:	e6843703          	ld	a4,-408(s0)
    8000554c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000554e:	058ab783          	ld	a5,88(s5)
    80005552:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005556:	85e6                	mv	a1,s9
    80005558:	ffffd097          	auipc	ra,0xffffd
    8000555c:	80c080e7          	jalr	-2036(ra) # 80001d64 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005560:	0004851b          	sext.w	a0,s1
    80005564:	bb15                	j	80005298 <exec+0x98>
    80005566:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000556a:	e0843583          	ld	a1,-504(s0)
    8000556e:	855a                	mv	a0,s6
    80005570:	ffffc097          	auipc	ra,0xffffc
    80005574:	7f4080e7          	jalr	2036(ra) # 80001d64 <proc_freepagetable>
  return -1;
    80005578:	557d                	li	a0,-1
  if(ip){
    8000557a:	d00a0fe3          	beqz	s4,80005298 <exec+0x98>
    8000557e:	b319                	j	80005284 <exec+0x84>
    80005580:	e1243423          	sd	s2,-504(s0)
    80005584:	b7dd                	j	8000556a <exec+0x36a>
    80005586:	e1243423          	sd	s2,-504(s0)
    8000558a:	b7c5                	j	8000556a <exec+0x36a>
    8000558c:	e1243423          	sd	s2,-504(s0)
    80005590:	bfe9                	j	8000556a <exec+0x36a>
    80005592:	e1243423          	sd	s2,-504(s0)
    80005596:	bfd1                	j	8000556a <exec+0x36a>
  ip = 0;
    80005598:	4a01                	li	s4,0
    8000559a:	bfc1                	j	8000556a <exec+0x36a>
    8000559c:	4a01                	li	s4,0
  if(pagetable)
    8000559e:	b7f1                	j	8000556a <exec+0x36a>
  sz = sz1;
    800055a0:	e0843983          	ld	s3,-504(s0)
    800055a4:	b569                	j	8000542e <exec+0x22e>

00000000800055a6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055a6:	7179                	add	sp,sp,-48
    800055a8:	f406                	sd	ra,40(sp)
    800055aa:	f022                	sd	s0,32(sp)
    800055ac:	ec26                	sd	s1,24(sp)
    800055ae:	e84a                	sd	s2,16(sp)
    800055b0:	1800                	add	s0,sp,48
    800055b2:	892e                	mv	s2,a1
    800055b4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800055b6:	fdc40593          	add	a1,s0,-36
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	ac2080e7          	jalr	-1342(ra) # 8000307c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055c2:	fdc42703          	lw	a4,-36(s0)
    800055c6:	47bd                	li	a5,15
    800055c8:	02e7eb63          	bltu	a5,a4,800055fe <argfd+0x58>
    800055cc:	ffffc097          	auipc	ra,0xffffc
    800055d0:	638080e7          	jalr	1592(ra) # 80001c04 <myproc>
    800055d4:	fdc42703          	lw	a4,-36(s0)
    800055d8:	01a70793          	add	a5,a4,26
    800055dc:	078e                	sll	a5,a5,0x3
    800055de:	953e                	add	a0,a0,a5
    800055e0:	611c                	ld	a5,0(a0)
    800055e2:	c385                	beqz	a5,80005602 <argfd+0x5c>
    return -1;
  if(pfd)
    800055e4:	00090463          	beqz	s2,800055ec <argfd+0x46>
    *pfd = fd;
    800055e8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055ec:	4501                	li	a0,0
  if(pf)
    800055ee:	c091                	beqz	s1,800055f2 <argfd+0x4c>
    *pf = f;
    800055f0:	e09c                	sd	a5,0(s1)
}
    800055f2:	70a2                	ld	ra,40(sp)
    800055f4:	7402                	ld	s0,32(sp)
    800055f6:	64e2                	ld	s1,24(sp)
    800055f8:	6942                	ld	s2,16(sp)
    800055fa:	6145                	add	sp,sp,48
    800055fc:	8082                	ret
    return -1;
    800055fe:	557d                	li	a0,-1
    80005600:	bfcd                	j	800055f2 <argfd+0x4c>
    80005602:	557d                	li	a0,-1
    80005604:	b7fd                	j	800055f2 <argfd+0x4c>

0000000080005606 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005606:	1101                	add	sp,sp,-32
    80005608:	ec06                	sd	ra,24(sp)
    8000560a:	e822                	sd	s0,16(sp)
    8000560c:	e426                	sd	s1,8(sp)
    8000560e:	1000                	add	s0,sp,32
    80005610:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005612:	ffffc097          	auipc	ra,0xffffc
    80005616:	5f2080e7          	jalr	1522(ra) # 80001c04 <myproc>
    8000561a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000561c:	0d050793          	add	a5,a0,208
    80005620:	4501                	li	a0,0
    80005622:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005624:	6398                	ld	a4,0(a5)
    80005626:	cb19                	beqz	a4,8000563c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005628:	2505                	addw	a0,a0,1
    8000562a:	07a1                	add	a5,a5,8
    8000562c:	fed51ce3          	bne	a0,a3,80005624 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005630:	557d                	li	a0,-1
}
    80005632:	60e2                	ld	ra,24(sp)
    80005634:	6442                	ld	s0,16(sp)
    80005636:	64a2                	ld	s1,8(sp)
    80005638:	6105                	add	sp,sp,32
    8000563a:	8082                	ret
      p->ofile[fd] = f;
    8000563c:	01a50793          	add	a5,a0,26
    80005640:	078e                	sll	a5,a5,0x3
    80005642:	963e                	add	a2,a2,a5
    80005644:	e204                	sd	s1,0(a2)
      return fd;
    80005646:	b7f5                	j	80005632 <fdalloc+0x2c>

0000000080005648 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005648:	715d                	add	sp,sp,-80
    8000564a:	e486                	sd	ra,72(sp)
    8000564c:	e0a2                	sd	s0,64(sp)
    8000564e:	fc26                	sd	s1,56(sp)
    80005650:	f84a                	sd	s2,48(sp)
    80005652:	f44e                	sd	s3,40(sp)
    80005654:	f052                	sd	s4,32(sp)
    80005656:	ec56                	sd	s5,24(sp)
    80005658:	e85a                	sd	s6,16(sp)
    8000565a:	0880                	add	s0,sp,80
    8000565c:	8b2e                	mv	s6,a1
    8000565e:	89b2                	mv	s3,a2
    80005660:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005662:	fb040593          	add	a1,s0,-80
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	e7e080e7          	jalr	-386(ra) # 800044e4 <nameiparent>
    8000566e:	84aa                	mv	s1,a0
    80005670:	14050b63          	beqz	a0,800057c6 <create+0x17e>
    return 0;

  ilock(dp);
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	6ac080e7          	jalr	1708(ra) # 80003d20 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000567c:	4601                	li	a2,0
    8000567e:	fb040593          	add	a1,s0,-80
    80005682:	8526                	mv	a0,s1
    80005684:	fffff097          	auipc	ra,0xfffff
    80005688:	b80080e7          	jalr	-1152(ra) # 80004204 <dirlookup>
    8000568c:	8aaa                	mv	s5,a0
    8000568e:	c921                	beqz	a0,800056de <create+0x96>
    iunlockput(dp);
    80005690:	8526                	mv	a0,s1
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	8f0080e7          	jalr	-1808(ra) # 80003f82 <iunlockput>
    ilock(ip);
    8000569a:	8556                	mv	a0,s5
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	684080e7          	jalr	1668(ra) # 80003d20 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056a4:	4789                	li	a5,2
    800056a6:	02fb1563          	bne	s6,a5,800056d0 <create+0x88>
    800056aa:	044ad783          	lhu	a5,68(s5)
    800056ae:	37f9                	addw	a5,a5,-2
    800056b0:	17c2                	sll	a5,a5,0x30
    800056b2:	93c1                	srl	a5,a5,0x30
    800056b4:	4705                	li	a4,1
    800056b6:	00f76d63          	bltu	a4,a5,800056d0 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800056ba:	8556                	mv	a0,s5
    800056bc:	60a6                	ld	ra,72(sp)
    800056be:	6406                	ld	s0,64(sp)
    800056c0:	74e2                	ld	s1,56(sp)
    800056c2:	7942                	ld	s2,48(sp)
    800056c4:	79a2                	ld	s3,40(sp)
    800056c6:	7a02                	ld	s4,32(sp)
    800056c8:	6ae2                	ld	s5,24(sp)
    800056ca:	6b42                	ld	s6,16(sp)
    800056cc:	6161                	add	sp,sp,80
    800056ce:	8082                	ret
    iunlockput(ip);
    800056d0:	8556                	mv	a0,s5
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	8b0080e7          	jalr	-1872(ra) # 80003f82 <iunlockput>
    return 0;
    800056da:	4a81                	li	s5,0
    800056dc:	bff9                	j	800056ba <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    800056de:	85da                	mv	a1,s6
    800056e0:	4088                	lw	a0,0(s1)
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	4a6080e7          	jalr	1190(ra) # 80003b88 <ialloc>
    800056ea:	8a2a                	mv	s4,a0
    800056ec:	c529                	beqz	a0,80005736 <create+0xee>
  ilock(ip);
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	632080e7          	jalr	1586(ra) # 80003d20 <ilock>
  ip->major = major;
    800056f6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800056fa:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800056fe:	4905                	li	s2,1
    80005700:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005704:	8552                	mv	a0,s4
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	54e080e7          	jalr	1358(ra) # 80003c54 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000570e:	032b0b63          	beq	s6,s2,80005744 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005712:	004a2603          	lw	a2,4(s4)
    80005716:	fb040593          	add	a1,s0,-80
    8000571a:	8526                	mv	a0,s1
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	cf8080e7          	jalr	-776(ra) # 80004414 <dirlink>
    80005724:	06054f63          	bltz	a0,800057a2 <create+0x15a>
  iunlockput(dp);
    80005728:	8526                	mv	a0,s1
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	858080e7          	jalr	-1960(ra) # 80003f82 <iunlockput>
  return ip;
    80005732:	8ad2                	mv	s5,s4
    80005734:	b759                	j	800056ba <create+0x72>
    iunlockput(dp);
    80005736:	8526                	mv	a0,s1
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	84a080e7          	jalr	-1974(ra) # 80003f82 <iunlockput>
    return 0;
    80005740:	8ad2                	mv	s5,s4
    80005742:	bfa5                	j	800056ba <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005744:	004a2603          	lw	a2,4(s4)
    80005748:	00003597          	auipc	a1,0x3
    8000574c:	fe058593          	add	a1,a1,-32 # 80008728 <syscalls+0x2b8>
    80005750:	8552                	mv	a0,s4
    80005752:	fffff097          	auipc	ra,0xfffff
    80005756:	cc2080e7          	jalr	-830(ra) # 80004414 <dirlink>
    8000575a:	04054463          	bltz	a0,800057a2 <create+0x15a>
    8000575e:	40d0                	lw	a2,4(s1)
    80005760:	00003597          	auipc	a1,0x3
    80005764:	fd058593          	add	a1,a1,-48 # 80008730 <syscalls+0x2c0>
    80005768:	8552                	mv	a0,s4
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	caa080e7          	jalr	-854(ra) # 80004414 <dirlink>
    80005772:	02054863          	bltz	a0,800057a2 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005776:	004a2603          	lw	a2,4(s4)
    8000577a:	fb040593          	add	a1,s0,-80
    8000577e:	8526                	mv	a0,s1
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	c94080e7          	jalr	-876(ra) # 80004414 <dirlink>
    80005788:	00054d63          	bltz	a0,800057a2 <create+0x15a>
    dp->nlink++;  // for ".."
    8000578c:	04a4d783          	lhu	a5,74(s1)
    80005790:	2785                	addw	a5,a5,1
    80005792:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005796:	8526                	mv	a0,s1
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	4bc080e7          	jalr	1212(ra) # 80003c54 <iupdate>
    800057a0:	b761                	j	80005728 <create+0xe0>
  ip->nlink = 0;
    800057a2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800057a6:	8552                	mv	a0,s4
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	4ac080e7          	jalr	1196(ra) # 80003c54 <iupdate>
  iunlockput(ip);
    800057b0:	8552                	mv	a0,s4
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	7d0080e7          	jalr	2000(ra) # 80003f82 <iunlockput>
  iunlockput(dp);
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	7c6080e7          	jalr	1990(ra) # 80003f82 <iunlockput>
  return 0;
    800057c4:	bddd                	j	800056ba <create+0x72>
    return 0;
    800057c6:	8aaa                	mv	s5,a0
    800057c8:	bdcd                	j	800056ba <create+0x72>

00000000800057ca <sys_dup>:
{
    800057ca:	7179                	add	sp,sp,-48
    800057cc:	f406                	sd	ra,40(sp)
    800057ce:	f022                	sd	s0,32(sp)
    800057d0:	ec26                	sd	s1,24(sp)
    800057d2:	e84a                	sd	s2,16(sp)
    800057d4:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057d6:	fd840613          	add	a2,s0,-40
    800057da:	4581                	li	a1,0
    800057dc:	4501                	li	a0,0
    800057de:	00000097          	auipc	ra,0x0
    800057e2:	dc8080e7          	jalr	-568(ra) # 800055a6 <argfd>
    return -1;
    800057e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057e8:	02054363          	bltz	a0,8000580e <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800057ec:	fd843903          	ld	s2,-40(s0)
    800057f0:	854a                	mv	a0,s2
    800057f2:	00000097          	auipc	ra,0x0
    800057f6:	e14080e7          	jalr	-492(ra) # 80005606 <fdalloc>
    800057fa:	84aa                	mv	s1,a0
    return -1;
    800057fc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057fe:	00054863          	bltz	a0,8000580e <sys_dup+0x44>
  filedup(f);
    80005802:	854a                	mv	a0,s2
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	334080e7          	jalr	820(ra) # 80004b38 <filedup>
  return fd;
    8000580c:	87a6                	mv	a5,s1
}
    8000580e:	853e                	mv	a0,a5
    80005810:	70a2                	ld	ra,40(sp)
    80005812:	7402                	ld	s0,32(sp)
    80005814:	64e2                	ld	s1,24(sp)
    80005816:	6942                	ld	s2,16(sp)
    80005818:	6145                	add	sp,sp,48
    8000581a:	8082                	ret

000000008000581c <sys_getreadcount>:
{
    8000581c:	1141                	add	sp,sp,-16
    8000581e:	e422                	sd	s0,8(sp)
    80005820:	0800                	add	s0,sp,16
}
    80005822:	00003517          	auipc	a0,0x3
    80005826:	0e252503          	lw	a0,226(a0) # 80008904 <readCount>
    8000582a:	6422                	ld	s0,8(sp)
    8000582c:	0141                	add	sp,sp,16
    8000582e:	8082                	ret

0000000080005830 <sys_read>:
{
    80005830:	7179                	add	sp,sp,-48
    80005832:	f406                	sd	ra,40(sp)
    80005834:	f022                	sd	s0,32(sp)
    80005836:	1800                	add	s0,sp,48
  readCount++;
    80005838:	00003717          	auipc	a4,0x3
    8000583c:	0cc70713          	add	a4,a4,204 # 80008904 <readCount>
    80005840:	431c                	lw	a5,0(a4)
    80005842:	2785                	addw	a5,a5,1
    80005844:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80005846:	fd840593          	add	a1,s0,-40
    8000584a:	4505                	li	a0,1
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	850080e7          	jalr	-1968(ra) # 8000309c <argaddr>
  argint(2, &n);
    80005854:	fe440593          	add	a1,s0,-28
    80005858:	4509                	li	a0,2
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	822080e7          	jalr	-2014(ra) # 8000307c <argint>
  if(argfd(0, 0, &f) < 0)
    80005862:	fe840613          	add	a2,s0,-24
    80005866:	4581                	li	a1,0
    80005868:	4501                	li	a0,0
    8000586a:	00000097          	auipc	ra,0x0
    8000586e:	d3c080e7          	jalr	-708(ra) # 800055a6 <argfd>
    80005872:	87aa                	mv	a5,a0
    return -1;
    80005874:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005876:	0007cc63          	bltz	a5,8000588e <sys_read+0x5e>
  return fileread(f, p, n);
    8000587a:	fe442603          	lw	a2,-28(s0)
    8000587e:	fd843583          	ld	a1,-40(s0)
    80005882:	fe843503          	ld	a0,-24(s0)
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	43e080e7          	jalr	1086(ra) # 80004cc4 <fileread>
}
    8000588e:	70a2                	ld	ra,40(sp)
    80005890:	7402                	ld	s0,32(sp)
    80005892:	6145                	add	sp,sp,48
    80005894:	8082                	ret

0000000080005896 <sys_write>:
{
    80005896:	7179                	add	sp,sp,-48
    80005898:	f406                	sd	ra,40(sp)
    8000589a:	f022                	sd	s0,32(sp)
    8000589c:	1800                	add	s0,sp,48
  argaddr(1, &p);
    8000589e:	fd840593          	add	a1,s0,-40
    800058a2:	4505                	li	a0,1
    800058a4:	ffffd097          	auipc	ra,0xffffd
    800058a8:	7f8080e7          	jalr	2040(ra) # 8000309c <argaddr>
  argint(2, &n);
    800058ac:	fe440593          	add	a1,s0,-28
    800058b0:	4509                	li	a0,2
    800058b2:	ffffd097          	auipc	ra,0xffffd
    800058b6:	7ca080e7          	jalr	1994(ra) # 8000307c <argint>
  if(argfd(0, 0, &f) < 0)
    800058ba:	fe840613          	add	a2,s0,-24
    800058be:	4581                	li	a1,0
    800058c0:	4501                	li	a0,0
    800058c2:	00000097          	auipc	ra,0x0
    800058c6:	ce4080e7          	jalr	-796(ra) # 800055a6 <argfd>
    800058ca:	87aa                	mv	a5,a0
    return -1;
    800058cc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058ce:	0007cc63          	bltz	a5,800058e6 <sys_write+0x50>
  return filewrite(f, p, n);
    800058d2:	fe442603          	lw	a2,-28(s0)
    800058d6:	fd843583          	ld	a1,-40(s0)
    800058da:	fe843503          	ld	a0,-24(s0)
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	4a8080e7          	jalr	1192(ra) # 80004d86 <filewrite>
}
    800058e6:	70a2                	ld	ra,40(sp)
    800058e8:	7402                	ld	s0,32(sp)
    800058ea:	6145                	add	sp,sp,48
    800058ec:	8082                	ret

00000000800058ee <sys_close>:
{
    800058ee:	1101                	add	sp,sp,-32
    800058f0:	ec06                	sd	ra,24(sp)
    800058f2:	e822                	sd	s0,16(sp)
    800058f4:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058f6:	fe040613          	add	a2,s0,-32
    800058fa:	fec40593          	add	a1,s0,-20
    800058fe:	4501                	li	a0,0
    80005900:	00000097          	auipc	ra,0x0
    80005904:	ca6080e7          	jalr	-858(ra) # 800055a6 <argfd>
    return -1;
    80005908:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000590a:	02054463          	bltz	a0,80005932 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000590e:	ffffc097          	auipc	ra,0xffffc
    80005912:	2f6080e7          	jalr	758(ra) # 80001c04 <myproc>
    80005916:	fec42783          	lw	a5,-20(s0)
    8000591a:	07e9                	add	a5,a5,26
    8000591c:	078e                	sll	a5,a5,0x3
    8000591e:	953e                	add	a0,a0,a5
    80005920:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005924:	fe043503          	ld	a0,-32(s0)
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	262080e7          	jalr	610(ra) # 80004b8a <fileclose>
  return 0;
    80005930:	4781                	li	a5,0
}
    80005932:	853e                	mv	a0,a5
    80005934:	60e2                	ld	ra,24(sp)
    80005936:	6442                	ld	s0,16(sp)
    80005938:	6105                	add	sp,sp,32
    8000593a:	8082                	ret

000000008000593c <sys_fstat>:
{
    8000593c:	1101                	add	sp,sp,-32
    8000593e:	ec06                	sd	ra,24(sp)
    80005940:	e822                	sd	s0,16(sp)
    80005942:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80005944:	fe040593          	add	a1,s0,-32
    80005948:	4505                	li	a0,1
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	752080e7          	jalr	1874(ra) # 8000309c <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005952:	fe840613          	add	a2,s0,-24
    80005956:	4581                	li	a1,0
    80005958:	4501                	li	a0,0
    8000595a:	00000097          	auipc	ra,0x0
    8000595e:	c4c080e7          	jalr	-948(ra) # 800055a6 <argfd>
    80005962:	87aa                	mv	a5,a0
    return -1;
    80005964:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005966:	0007ca63          	bltz	a5,8000597a <sys_fstat+0x3e>
  return filestat(f, st);
    8000596a:	fe043583          	ld	a1,-32(s0)
    8000596e:	fe843503          	ld	a0,-24(s0)
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	2e0080e7          	jalr	736(ra) # 80004c52 <filestat>
}
    8000597a:	60e2                	ld	ra,24(sp)
    8000597c:	6442                	ld	s0,16(sp)
    8000597e:	6105                	add	sp,sp,32
    80005980:	8082                	ret

0000000080005982 <sys_link>:
{
    80005982:	7169                	add	sp,sp,-304
    80005984:	f606                	sd	ra,296(sp)
    80005986:	f222                	sd	s0,288(sp)
    80005988:	ee26                	sd	s1,280(sp)
    8000598a:	ea4a                	sd	s2,272(sp)
    8000598c:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000598e:	08000613          	li	a2,128
    80005992:	ed040593          	add	a1,s0,-304
    80005996:	4501                	li	a0,0
    80005998:	ffffd097          	auipc	ra,0xffffd
    8000599c:	724080e7          	jalr	1828(ra) # 800030bc <argstr>
    return -1;
    800059a0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059a2:	10054e63          	bltz	a0,80005abe <sys_link+0x13c>
    800059a6:	08000613          	li	a2,128
    800059aa:	f5040593          	add	a1,s0,-176
    800059ae:	4505                	li	a0,1
    800059b0:	ffffd097          	auipc	ra,0xffffd
    800059b4:	70c080e7          	jalr	1804(ra) # 800030bc <argstr>
    return -1;
    800059b8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059ba:	10054263          	bltz	a0,80005abe <sys_link+0x13c>
  begin_op();
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	d08080e7          	jalr	-760(ra) # 800046c6 <begin_op>
  if((ip = namei(old)) == 0){
    800059c6:	ed040513          	add	a0,s0,-304
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	afc080e7          	jalr	-1284(ra) # 800044c6 <namei>
    800059d2:	84aa                	mv	s1,a0
    800059d4:	c551                	beqz	a0,80005a60 <sys_link+0xde>
  ilock(ip);
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	34a080e7          	jalr	842(ra) # 80003d20 <ilock>
  if(ip->type == T_DIR){
    800059de:	04449703          	lh	a4,68(s1)
    800059e2:	4785                	li	a5,1
    800059e4:	08f70463          	beq	a4,a5,80005a6c <sys_link+0xea>
  ip->nlink++;
    800059e8:	04a4d783          	lhu	a5,74(s1)
    800059ec:	2785                	addw	a5,a5,1
    800059ee:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059f2:	8526                	mv	a0,s1
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	260080e7          	jalr	608(ra) # 80003c54 <iupdate>
  iunlock(ip);
    800059fc:	8526                	mv	a0,s1
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	3e4080e7          	jalr	996(ra) # 80003de2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a06:	fd040593          	add	a1,s0,-48
    80005a0a:	f5040513          	add	a0,s0,-176
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	ad6080e7          	jalr	-1322(ra) # 800044e4 <nameiparent>
    80005a16:	892a                	mv	s2,a0
    80005a18:	c935                	beqz	a0,80005a8c <sys_link+0x10a>
  ilock(dp);
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	306080e7          	jalr	774(ra) # 80003d20 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a22:	00092703          	lw	a4,0(s2)
    80005a26:	409c                	lw	a5,0(s1)
    80005a28:	04f71d63          	bne	a4,a5,80005a82 <sys_link+0x100>
    80005a2c:	40d0                	lw	a2,4(s1)
    80005a2e:	fd040593          	add	a1,s0,-48
    80005a32:	854a                	mv	a0,s2
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	9e0080e7          	jalr	-1568(ra) # 80004414 <dirlink>
    80005a3c:	04054363          	bltz	a0,80005a82 <sys_link+0x100>
  iunlockput(dp);
    80005a40:	854a                	mv	a0,s2
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	540080e7          	jalr	1344(ra) # 80003f82 <iunlockput>
  iput(ip);
    80005a4a:	8526                	mv	a0,s1
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	48e080e7          	jalr	1166(ra) # 80003eda <iput>
  end_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	cec080e7          	jalr	-788(ra) # 80004740 <end_op>
  return 0;
    80005a5c:	4781                	li	a5,0
    80005a5e:	a085                	j	80005abe <sys_link+0x13c>
    end_op();
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	ce0080e7          	jalr	-800(ra) # 80004740 <end_op>
    return -1;
    80005a68:	57fd                	li	a5,-1
    80005a6a:	a891                	j	80005abe <sys_link+0x13c>
    iunlockput(ip);
    80005a6c:	8526                	mv	a0,s1
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	514080e7          	jalr	1300(ra) # 80003f82 <iunlockput>
    end_op();
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	cca080e7          	jalr	-822(ra) # 80004740 <end_op>
    return -1;
    80005a7e:	57fd                	li	a5,-1
    80005a80:	a83d                	j	80005abe <sys_link+0x13c>
    iunlockput(dp);
    80005a82:	854a                	mv	a0,s2
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	4fe080e7          	jalr	1278(ra) # 80003f82 <iunlockput>
  ilock(ip);
    80005a8c:	8526                	mv	a0,s1
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	292080e7          	jalr	658(ra) # 80003d20 <ilock>
  ip->nlink--;
    80005a96:	04a4d783          	lhu	a5,74(s1)
    80005a9a:	37fd                	addw	a5,a5,-1
    80005a9c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005aa0:	8526                	mv	a0,s1
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	1b2080e7          	jalr	434(ra) # 80003c54 <iupdate>
  iunlockput(ip);
    80005aaa:	8526                	mv	a0,s1
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	4d6080e7          	jalr	1238(ra) # 80003f82 <iunlockput>
  end_op();
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	c8c080e7          	jalr	-884(ra) # 80004740 <end_op>
  return -1;
    80005abc:	57fd                	li	a5,-1
}
    80005abe:	853e                	mv	a0,a5
    80005ac0:	70b2                	ld	ra,296(sp)
    80005ac2:	7412                	ld	s0,288(sp)
    80005ac4:	64f2                	ld	s1,280(sp)
    80005ac6:	6952                	ld	s2,272(sp)
    80005ac8:	6155                	add	sp,sp,304
    80005aca:	8082                	ret

0000000080005acc <sys_unlink>:
{
    80005acc:	7151                	add	sp,sp,-240
    80005ace:	f586                	sd	ra,232(sp)
    80005ad0:	f1a2                	sd	s0,224(sp)
    80005ad2:	eda6                	sd	s1,216(sp)
    80005ad4:	e9ca                	sd	s2,208(sp)
    80005ad6:	e5ce                	sd	s3,200(sp)
    80005ad8:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ada:	08000613          	li	a2,128
    80005ade:	f3040593          	add	a1,s0,-208
    80005ae2:	4501                	li	a0,0
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	5d8080e7          	jalr	1496(ra) # 800030bc <argstr>
    80005aec:	18054163          	bltz	a0,80005c6e <sys_unlink+0x1a2>
  begin_op();
    80005af0:	fffff097          	auipc	ra,0xfffff
    80005af4:	bd6080e7          	jalr	-1066(ra) # 800046c6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005af8:	fb040593          	add	a1,s0,-80
    80005afc:	f3040513          	add	a0,s0,-208
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	9e4080e7          	jalr	-1564(ra) # 800044e4 <nameiparent>
    80005b08:	84aa                	mv	s1,a0
    80005b0a:	c979                	beqz	a0,80005be0 <sys_unlink+0x114>
  ilock(dp);
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	214080e7          	jalr	532(ra) # 80003d20 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b14:	00003597          	auipc	a1,0x3
    80005b18:	c1458593          	add	a1,a1,-1004 # 80008728 <syscalls+0x2b8>
    80005b1c:	fb040513          	add	a0,s0,-80
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	6ca080e7          	jalr	1738(ra) # 800041ea <namecmp>
    80005b28:	14050a63          	beqz	a0,80005c7c <sys_unlink+0x1b0>
    80005b2c:	00003597          	auipc	a1,0x3
    80005b30:	c0458593          	add	a1,a1,-1020 # 80008730 <syscalls+0x2c0>
    80005b34:	fb040513          	add	a0,s0,-80
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	6b2080e7          	jalr	1714(ra) # 800041ea <namecmp>
    80005b40:	12050e63          	beqz	a0,80005c7c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b44:	f2c40613          	add	a2,s0,-212
    80005b48:	fb040593          	add	a1,s0,-80
    80005b4c:	8526                	mv	a0,s1
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	6b6080e7          	jalr	1718(ra) # 80004204 <dirlookup>
    80005b56:	892a                	mv	s2,a0
    80005b58:	12050263          	beqz	a0,80005c7c <sys_unlink+0x1b0>
  ilock(ip);
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	1c4080e7          	jalr	452(ra) # 80003d20 <ilock>
  if(ip->nlink < 1)
    80005b64:	04a91783          	lh	a5,74(s2)
    80005b68:	08f05263          	blez	a5,80005bec <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b6c:	04491703          	lh	a4,68(s2)
    80005b70:	4785                	li	a5,1
    80005b72:	08f70563          	beq	a4,a5,80005bfc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b76:	4641                	li	a2,16
    80005b78:	4581                	li	a1,0
    80005b7a:	fc040513          	add	a0,s0,-64
    80005b7e:	ffffb097          	auipc	ra,0xffffb
    80005b82:	3b6080e7          	jalr	950(ra) # 80000f34 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b86:	4741                	li	a4,16
    80005b88:	f2c42683          	lw	a3,-212(s0)
    80005b8c:	fc040613          	add	a2,s0,-64
    80005b90:	4581                	li	a1,0
    80005b92:	8526                	mv	a0,s1
    80005b94:	ffffe097          	auipc	ra,0xffffe
    80005b98:	538080e7          	jalr	1336(ra) # 800040cc <writei>
    80005b9c:	47c1                	li	a5,16
    80005b9e:	0af51563          	bne	a0,a5,80005c48 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ba2:	04491703          	lh	a4,68(s2)
    80005ba6:	4785                	li	a5,1
    80005ba8:	0af70863          	beq	a4,a5,80005c58 <sys_unlink+0x18c>
  iunlockput(dp);
    80005bac:	8526                	mv	a0,s1
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	3d4080e7          	jalr	980(ra) # 80003f82 <iunlockput>
  ip->nlink--;
    80005bb6:	04a95783          	lhu	a5,74(s2)
    80005bba:	37fd                	addw	a5,a5,-1
    80005bbc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bc0:	854a                	mv	a0,s2
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	092080e7          	jalr	146(ra) # 80003c54 <iupdate>
  iunlockput(ip);
    80005bca:	854a                	mv	a0,s2
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	3b6080e7          	jalr	950(ra) # 80003f82 <iunlockput>
  end_op();
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	b6c080e7          	jalr	-1172(ra) # 80004740 <end_op>
  return 0;
    80005bdc:	4501                	li	a0,0
    80005bde:	a84d                	j	80005c90 <sys_unlink+0x1c4>
    end_op();
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	b60080e7          	jalr	-1184(ra) # 80004740 <end_op>
    return -1;
    80005be8:	557d                	li	a0,-1
    80005bea:	a05d                	j	80005c90 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005bec:	00003517          	auipc	a0,0x3
    80005bf0:	b4c50513          	add	a0,a0,-1204 # 80008738 <syscalls+0x2c8>
    80005bf4:	ffffb097          	auipc	ra,0xffffb
    80005bf8:	948080e7          	jalr	-1720(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bfc:	04c92703          	lw	a4,76(s2)
    80005c00:	02000793          	li	a5,32
    80005c04:	f6e7f9e3          	bgeu	a5,a4,80005b76 <sys_unlink+0xaa>
    80005c08:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c0c:	4741                	li	a4,16
    80005c0e:	86ce                	mv	a3,s3
    80005c10:	f1840613          	add	a2,s0,-232
    80005c14:	4581                	li	a1,0
    80005c16:	854a                	mv	a0,s2
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	3bc080e7          	jalr	956(ra) # 80003fd4 <readi>
    80005c20:	47c1                	li	a5,16
    80005c22:	00f51b63          	bne	a0,a5,80005c38 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c26:	f1845783          	lhu	a5,-232(s0)
    80005c2a:	e7a1                	bnez	a5,80005c72 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c2c:	29c1                	addw	s3,s3,16
    80005c2e:	04c92783          	lw	a5,76(s2)
    80005c32:	fcf9ede3          	bltu	s3,a5,80005c0c <sys_unlink+0x140>
    80005c36:	b781                	j	80005b76 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c38:	00003517          	auipc	a0,0x3
    80005c3c:	b1850513          	add	a0,a0,-1256 # 80008750 <syscalls+0x2e0>
    80005c40:	ffffb097          	auipc	ra,0xffffb
    80005c44:	8fc080e7          	jalr	-1796(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005c48:	00003517          	auipc	a0,0x3
    80005c4c:	b2050513          	add	a0,a0,-1248 # 80008768 <syscalls+0x2f8>
    80005c50:	ffffb097          	auipc	ra,0xffffb
    80005c54:	8ec080e7          	jalr	-1812(ra) # 8000053c <panic>
    dp->nlink--;
    80005c58:	04a4d783          	lhu	a5,74(s1)
    80005c5c:	37fd                	addw	a5,a5,-1
    80005c5e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c62:	8526                	mv	a0,s1
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	ff0080e7          	jalr	-16(ra) # 80003c54 <iupdate>
    80005c6c:	b781                	j	80005bac <sys_unlink+0xe0>
    return -1;
    80005c6e:	557d                	li	a0,-1
    80005c70:	a005                	j	80005c90 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c72:	854a                	mv	a0,s2
    80005c74:	ffffe097          	auipc	ra,0xffffe
    80005c78:	30e080e7          	jalr	782(ra) # 80003f82 <iunlockput>
  iunlockput(dp);
    80005c7c:	8526                	mv	a0,s1
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	304080e7          	jalr	772(ra) # 80003f82 <iunlockput>
  end_op();
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	aba080e7          	jalr	-1350(ra) # 80004740 <end_op>
  return -1;
    80005c8e:	557d                	li	a0,-1
}
    80005c90:	70ae                	ld	ra,232(sp)
    80005c92:	740e                	ld	s0,224(sp)
    80005c94:	64ee                	ld	s1,216(sp)
    80005c96:	694e                	ld	s2,208(sp)
    80005c98:	69ae                	ld	s3,200(sp)
    80005c9a:	616d                	add	sp,sp,240
    80005c9c:	8082                	ret

0000000080005c9e <sys_open>:

uint64
sys_open(void)
{
    80005c9e:	7131                	add	sp,sp,-192
    80005ca0:	fd06                	sd	ra,184(sp)
    80005ca2:	f922                	sd	s0,176(sp)
    80005ca4:	f526                	sd	s1,168(sp)
    80005ca6:	f14a                	sd	s2,160(sp)
    80005ca8:	ed4e                	sd	s3,152(sp)
    80005caa:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005cac:	f4c40593          	add	a1,s0,-180
    80005cb0:	4505                	li	a0,1
    80005cb2:	ffffd097          	auipc	ra,0xffffd
    80005cb6:	3ca080e7          	jalr	970(ra) # 8000307c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cba:	08000613          	li	a2,128
    80005cbe:	f5040593          	add	a1,s0,-176
    80005cc2:	4501                	li	a0,0
    80005cc4:	ffffd097          	auipc	ra,0xffffd
    80005cc8:	3f8080e7          	jalr	1016(ra) # 800030bc <argstr>
    80005ccc:	87aa                	mv	a5,a0
    return -1;
    80005cce:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cd0:	0a07c863          	bltz	a5,80005d80 <sys_open+0xe2>

  begin_op();
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	9f2080e7          	jalr	-1550(ra) # 800046c6 <begin_op>

  if(omode & O_CREATE){
    80005cdc:	f4c42783          	lw	a5,-180(s0)
    80005ce0:	2007f793          	and	a5,a5,512
    80005ce4:	cbdd                	beqz	a5,80005d9a <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005ce6:	4681                	li	a3,0
    80005ce8:	4601                	li	a2,0
    80005cea:	4589                	li	a1,2
    80005cec:	f5040513          	add	a0,s0,-176
    80005cf0:	00000097          	auipc	ra,0x0
    80005cf4:	958080e7          	jalr	-1704(ra) # 80005648 <create>
    80005cf8:	84aa                	mv	s1,a0
    if(ip == 0){
    80005cfa:	c951                	beqz	a0,80005d8e <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cfc:	04449703          	lh	a4,68(s1)
    80005d00:	478d                	li	a5,3
    80005d02:	00f71763          	bne	a4,a5,80005d10 <sys_open+0x72>
    80005d06:	0464d703          	lhu	a4,70(s1)
    80005d0a:	47a5                	li	a5,9
    80005d0c:	0ce7ec63          	bltu	a5,a4,80005de4 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	dbe080e7          	jalr	-578(ra) # 80004ace <filealloc>
    80005d18:	892a                	mv	s2,a0
    80005d1a:	c56d                	beqz	a0,80005e04 <sys_open+0x166>
    80005d1c:	00000097          	auipc	ra,0x0
    80005d20:	8ea080e7          	jalr	-1814(ra) # 80005606 <fdalloc>
    80005d24:	89aa                	mv	s3,a0
    80005d26:	0c054a63          	bltz	a0,80005dfa <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d2a:	04449703          	lh	a4,68(s1)
    80005d2e:	478d                	li	a5,3
    80005d30:	0ef70563          	beq	a4,a5,80005e1a <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d34:	4789                	li	a5,2
    80005d36:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005d3a:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005d3e:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005d42:	f4c42783          	lw	a5,-180(s0)
    80005d46:	0017c713          	xor	a4,a5,1
    80005d4a:	8b05                	and	a4,a4,1
    80005d4c:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d50:	0037f713          	and	a4,a5,3
    80005d54:	00e03733          	snez	a4,a4
    80005d58:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d5c:	4007f793          	and	a5,a5,1024
    80005d60:	c791                	beqz	a5,80005d6c <sys_open+0xce>
    80005d62:	04449703          	lh	a4,68(s1)
    80005d66:	4789                	li	a5,2
    80005d68:	0cf70063          	beq	a4,a5,80005e28 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005d6c:	8526                	mv	a0,s1
    80005d6e:	ffffe097          	auipc	ra,0xffffe
    80005d72:	074080e7          	jalr	116(ra) # 80003de2 <iunlock>
  end_op();
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	9ca080e7          	jalr	-1590(ra) # 80004740 <end_op>

  return fd;
    80005d7e:	854e                	mv	a0,s3
}
    80005d80:	70ea                	ld	ra,184(sp)
    80005d82:	744a                	ld	s0,176(sp)
    80005d84:	74aa                	ld	s1,168(sp)
    80005d86:	790a                	ld	s2,160(sp)
    80005d88:	69ea                	ld	s3,152(sp)
    80005d8a:	6129                	add	sp,sp,192
    80005d8c:	8082                	ret
      end_op();
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	9b2080e7          	jalr	-1614(ra) # 80004740 <end_op>
      return -1;
    80005d96:	557d                	li	a0,-1
    80005d98:	b7e5                	j	80005d80 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005d9a:	f5040513          	add	a0,s0,-176
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	728080e7          	jalr	1832(ra) # 800044c6 <namei>
    80005da6:	84aa                	mv	s1,a0
    80005da8:	c905                	beqz	a0,80005dd8 <sys_open+0x13a>
    ilock(ip);
    80005daa:	ffffe097          	auipc	ra,0xffffe
    80005dae:	f76080e7          	jalr	-138(ra) # 80003d20 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005db2:	04449703          	lh	a4,68(s1)
    80005db6:	4785                	li	a5,1
    80005db8:	f4f712e3          	bne	a4,a5,80005cfc <sys_open+0x5e>
    80005dbc:	f4c42783          	lw	a5,-180(s0)
    80005dc0:	dba1                	beqz	a5,80005d10 <sys_open+0x72>
      iunlockput(ip);
    80005dc2:	8526                	mv	a0,s1
    80005dc4:	ffffe097          	auipc	ra,0xffffe
    80005dc8:	1be080e7          	jalr	446(ra) # 80003f82 <iunlockput>
      end_op();
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	974080e7          	jalr	-1676(ra) # 80004740 <end_op>
      return -1;
    80005dd4:	557d                	li	a0,-1
    80005dd6:	b76d                	j	80005d80 <sys_open+0xe2>
      end_op();
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	968080e7          	jalr	-1688(ra) # 80004740 <end_op>
      return -1;
    80005de0:	557d                	li	a0,-1
    80005de2:	bf79                	j	80005d80 <sys_open+0xe2>
    iunlockput(ip);
    80005de4:	8526                	mv	a0,s1
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	19c080e7          	jalr	412(ra) # 80003f82 <iunlockput>
    end_op();
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	952080e7          	jalr	-1710(ra) # 80004740 <end_op>
    return -1;
    80005df6:	557d                	li	a0,-1
    80005df8:	b761                	j	80005d80 <sys_open+0xe2>
      fileclose(f);
    80005dfa:	854a                	mv	a0,s2
    80005dfc:	fffff097          	auipc	ra,0xfffff
    80005e00:	d8e080e7          	jalr	-626(ra) # 80004b8a <fileclose>
    iunlockput(ip);
    80005e04:	8526                	mv	a0,s1
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	17c080e7          	jalr	380(ra) # 80003f82 <iunlockput>
    end_op();
    80005e0e:	fffff097          	auipc	ra,0xfffff
    80005e12:	932080e7          	jalr	-1742(ra) # 80004740 <end_op>
    return -1;
    80005e16:	557d                	li	a0,-1
    80005e18:	b7a5                	j	80005d80 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005e1a:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005e1e:	04649783          	lh	a5,70(s1)
    80005e22:	02f91223          	sh	a5,36(s2)
    80005e26:	bf21                	j	80005d3e <sys_open+0xa0>
    itrunc(ip);
    80005e28:	8526                	mv	a0,s1
    80005e2a:	ffffe097          	auipc	ra,0xffffe
    80005e2e:	004080e7          	jalr	4(ra) # 80003e2e <itrunc>
    80005e32:	bf2d                	j	80005d6c <sys_open+0xce>

0000000080005e34 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e34:	7175                	add	sp,sp,-144
    80005e36:	e506                	sd	ra,136(sp)
    80005e38:	e122                	sd	s0,128(sp)
    80005e3a:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e3c:	fffff097          	auipc	ra,0xfffff
    80005e40:	88a080e7          	jalr	-1910(ra) # 800046c6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e44:	08000613          	li	a2,128
    80005e48:	f7040593          	add	a1,s0,-144
    80005e4c:	4501                	li	a0,0
    80005e4e:	ffffd097          	auipc	ra,0xffffd
    80005e52:	26e080e7          	jalr	622(ra) # 800030bc <argstr>
    80005e56:	02054963          	bltz	a0,80005e88 <sys_mkdir+0x54>
    80005e5a:	4681                	li	a3,0
    80005e5c:	4601                	li	a2,0
    80005e5e:	4585                	li	a1,1
    80005e60:	f7040513          	add	a0,s0,-144
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	7e4080e7          	jalr	2020(ra) # 80005648 <create>
    80005e6c:	cd11                	beqz	a0,80005e88 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e6e:	ffffe097          	auipc	ra,0xffffe
    80005e72:	114080e7          	jalr	276(ra) # 80003f82 <iunlockput>
  end_op();
    80005e76:	fffff097          	auipc	ra,0xfffff
    80005e7a:	8ca080e7          	jalr	-1846(ra) # 80004740 <end_op>
  return 0;
    80005e7e:	4501                	li	a0,0
}
    80005e80:	60aa                	ld	ra,136(sp)
    80005e82:	640a                	ld	s0,128(sp)
    80005e84:	6149                	add	sp,sp,144
    80005e86:	8082                	ret
    end_op();
    80005e88:	fffff097          	auipc	ra,0xfffff
    80005e8c:	8b8080e7          	jalr	-1864(ra) # 80004740 <end_op>
    return -1;
    80005e90:	557d                	li	a0,-1
    80005e92:	b7fd                	j	80005e80 <sys_mkdir+0x4c>

0000000080005e94 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e94:	7135                	add	sp,sp,-160
    80005e96:	ed06                	sd	ra,152(sp)
    80005e98:	e922                	sd	s0,144(sp)
    80005e9a:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e9c:	fffff097          	auipc	ra,0xfffff
    80005ea0:	82a080e7          	jalr	-2006(ra) # 800046c6 <begin_op>
  argint(1, &major);
    80005ea4:	f6c40593          	add	a1,s0,-148
    80005ea8:	4505                	li	a0,1
    80005eaa:	ffffd097          	auipc	ra,0xffffd
    80005eae:	1d2080e7          	jalr	466(ra) # 8000307c <argint>
  argint(2, &minor);
    80005eb2:	f6840593          	add	a1,s0,-152
    80005eb6:	4509                	li	a0,2
    80005eb8:	ffffd097          	auipc	ra,0xffffd
    80005ebc:	1c4080e7          	jalr	452(ra) # 8000307c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ec0:	08000613          	li	a2,128
    80005ec4:	f7040593          	add	a1,s0,-144
    80005ec8:	4501                	li	a0,0
    80005eca:	ffffd097          	auipc	ra,0xffffd
    80005ece:	1f2080e7          	jalr	498(ra) # 800030bc <argstr>
    80005ed2:	02054b63          	bltz	a0,80005f08 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ed6:	f6841683          	lh	a3,-152(s0)
    80005eda:	f6c41603          	lh	a2,-148(s0)
    80005ede:	458d                	li	a1,3
    80005ee0:	f7040513          	add	a0,s0,-144
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	764080e7          	jalr	1892(ra) # 80005648 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005eec:	cd11                	beqz	a0,80005f08 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005eee:	ffffe097          	auipc	ra,0xffffe
    80005ef2:	094080e7          	jalr	148(ra) # 80003f82 <iunlockput>
  end_op();
    80005ef6:	fffff097          	auipc	ra,0xfffff
    80005efa:	84a080e7          	jalr	-1974(ra) # 80004740 <end_op>
  return 0;
    80005efe:	4501                	li	a0,0
}
    80005f00:	60ea                	ld	ra,152(sp)
    80005f02:	644a                	ld	s0,144(sp)
    80005f04:	610d                	add	sp,sp,160
    80005f06:	8082                	ret
    end_op();
    80005f08:	fffff097          	auipc	ra,0xfffff
    80005f0c:	838080e7          	jalr	-1992(ra) # 80004740 <end_op>
    return -1;
    80005f10:	557d                	li	a0,-1
    80005f12:	b7fd                	j	80005f00 <sys_mknod+0x6c>

0000000080005f14 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f14:	7135                	add	sp,sp,-160
    80005f16:	ed06                	sd	ra,152(sp)
    80005f18:	e922                	sd	s0,144(sp)
    80005f1a:	e526                	sd	s1,136(sp)
    80005f1c:	e14a                	sd	s2,128(sp)
    80005f1e:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f20:	ffffc097          	auipc	ra,0xffffc
    80005f24:	ce4080e7          	jalr	-796(ra) # 80001c04 <myproc>
    80005f28:	892a                	mv	s2,a0
  
  begin_op();
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	79c080e7          	jalr	1948(ra) # 800046c6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f32:	08000613          	li	a2,128
    80005f36:	f6040593          	add	a1,s0,-160
    80005f3a:	4501                	li	a0,0
    80005f3c:	ffffd097          	auipc	ra,0xffffd
    80005f40:	180080e7          	jalr	384(ra) # 800030bc <argstr>
    80005f44:	04054b63          	bltz	a0,80005f9a <sys_chdir+0x86>
    80005f48:	f6040513          	add	a0,s0,-160
    80005f4c:	ffffe097          	auipc	ra,0xffffe
    80005f50:	57a080e7          	jalr	1402(ra) # 800044c6 <namei>
    80005f54:	84aa                	mv	s1,a0
    80005f56:	c131                	beqz	a0,80005f9a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f58:	ffffe097          	auipc	ra,0xffffe
    80005f5c:	dc8080e7          	jalr	-568(ra) # 80003d20 <ilock>
  if(ip->type != T_DIR){
    80005f60:	04449703          	lh	a4,68(s1)
    80005f64:	4785                	li	a5,1
    80005f66:	04f71063          	bne	a4,a5,80005fa6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f6a:	8526                	mv	a0,s1
    80005f6c:	ffffe097          	auipc	ra,0xffffe
    80005f70:	e76080e7          	jalr	-394(ra) # 80003de2 <iunlock>
  iput(p->cwd);
    80005f74:	15093503          	ld	a0,336(s2)
    80005f78:	ffffe097          	auipc	ra,0xffffe
    80005f7c:	f62080e7          	jalr	-158(ra) # 80003eda <iput>
  end_op();
    80005f80:	ffffe097          	auipc	ra,0xffffe
    80005f84:	7c0080e7          	jalr	1984(ra) # 80004740 <end_op>
  p->cwd = ip;
    80005f88:	14993823          	sd	s1,336(s2)
  return 0;
    80005f8c:	4501                	li	a0,0
}
    80005f8e:	60ea                	ld	ra,152(sp)
    80005f90:	644a                	ld	s0,144(sp)
    80005f92:	64aa                	ld	s1,136(sp)
    80005f94:	690a                	ld	s2,128(sp)
    80005f96:	610d                	add	sp,sp,160
    80005f98:	8082                	ret
    end_op();
    80005f9a:	ffffe097          	auipc	ra,0xffffe
    80005f9e:	7a6080e7          	jalr	1958(ra) # 80004740 <end_op>
    return -1;
    80005fa2:	557d                	li	a0,-1
    80005fa4:	b7ed                	j	80005f8e <sys_chdir+0x7a>
    iunlockput(ip);
    80005fa6:	8526                	mv	a0,s1
    80005fa8:	ffffe097          	auipc	ra,0xffffe
    80005fac:	fda080e7          	jalr	-38(ra) # 80003f82 <iunlockput>
    end_op();
    80005fb0:	ffffe097          	auipc	ra,0xffffe
    80005fb4:	790080e7          	jalr	1936(ra) # 80004740 <end_op>
    return -1;
    80005fb8:	557d                	li	a0,-1
    80005fba:	bfd1                	j	80005f8e <sys_chdir+0x7a>

0000000080005fbc <sys_exec>:

uint64
sys_exec(void)
{
    80005fbc:	7121                	add	sp,sp,-448
    80005fbe:	ff06                	sd	ra,440(sp)
    80005fc0:	fb22                	sd	s0,432(sp)
    80005fc2:	f726                	sd	s1,424(sp)
    80005fc4:	f34a                	sd	s2,416(sp)
    80005fc6:	ef4e                	sd	s3,408(sp)
    80005fc8:	eb52                	sd	s4,400(sp)
    80005fca:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005fcc:	e4840593          	add	a1,s0,-440
    80005fd0:	4505                	li	a0,1
    80005fd2:	ffffd097          	auipc	ra,0xffffd
    80005fd6:	0ca080e7          	jalr	202(ra) # 8000309c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005fda:	08000613          	li	a2,128
    80005fde:	f5040593          	add	a1,s0,-176
    80005fe2:	4501                	li	a0,0
    80005fe4:	ffffd097          	auipc	ra,0xffffd
    80005fe8:	0d8080e7          	jalr	216(ra) # 800030bc <argstr>
    80005fec:	87aa                	mv	a5,a0
    return -1;
    80005fee:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ff0:	0c07c263          	bltz	a5,800060b4 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005ff4:	10000613          	li	a2,256
    80005ff8:	4581                	li	a1,0
    80005ffa:	e5040513          	add	a0,s0,-432
    80005ffe:	ffffb097          	auipc	ra,0xffffb
    80006002:	f36080e7          	jalr	-202(ra) # 80000f34 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006006:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    8000600a:	89a6                	mv	s3,s1
    8000600c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000600e:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006012:	00391513          	sll	a0,s2,0x3
    80006016:	e4040593          	add	a1,s0,-448
    8000601a:	e4843783          	ld	a5,-440(s0)
    8000601e:	953e                	add	a0,a0,a5
    80006020:	ffffd097          	auipc	ra,0xffffd
    80006024:	fbe080e7          	jalr	-66(ra) # 80002fde <fetchaddr>
    80006028:	02054a63          	bltz	a0,8000605c <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    8000602c:	e4043783          	ld	a5,-448(s0)
    80006030:	c3b9                	beqz	a5,80006076 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006032:	ffffb097          	auipc	ra,0xffffb
    80006036:	b26080e7          	jalr	-1242(ra) # 80000b58 <kalloc>
    8000603a:	85aa                	mv	a1,a0
    8000603c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006040:	cd11                	beqz	a0,8000605c <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006042:	6605                	lui	a2,0x1
    80006044:	e4043503          	ld	a0,-448(s0)
    80006048:	ffffd097          	auipc	ra,0xffffd
    8000604c:	fe8080e7          	jalr	-24(ra) # 80003030 <fetchstr>
    80006050:	00054663          	bltz	a0,8000605c <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80006054:	0905                	add	s2,s2,1
    80006056:	09a1                	add	s3,s3,8
    80006058:	fb491de3          	bne	s2,s4,80006012 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000605c:	f5040913          	add	s2,s0,-176
    80006060:	6088                	ld	a0,0(s1)
    80006062:	c921                	beqz	a0,800060b2 <sys_exec+0xf6>
    kfree(argv[i]);
    80006064:	ffffb097          	auipc	ra,0xffffb
    80006068:	980080e7          	jalr	-1664(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000606c:	04a1                	add	s1,s1,8
    8000606e:	ff2499e3          	bne	s1,s2,80006060 <sys_exec+0xa4>
  return -1;
    80006072:	557d                	li	a0,-1
    80006074:	a081                	j	800060b4 <sys_exec+0xf8>
      argv[i] = 0;
    80006076:	0009079b          	sext.w	a5,s2
    8000607a:	078e                	sll	a5,a5,0x3
    8000607c:	fd078793          	add	a5,a5,-48
    80006080:	97a2                	add	a5,a5,s0
    80006082:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80006086:	e5040593          	add	a1,s0,-432
    8000608a:	f5040513          	add	a0,s0,-176
    8000608e:	fffff097          	auipc	ra,0xfffff
    80006092:	172080e7          	jalr	370(ra) # 80005200 <exec>
    80006096:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006098:	f5040993          	add	s3,s0,-176
    8000609c:	6088                	ld	a0,0(s1)
    8000609e:	c901                	beqz	a0,800060ae <sys_exec+0xf2>
    kfree(argv[i]);
    800060a0:	ffffb097          	auipc	ra,0xffffb
    800060a4:	944080e7          	jalr	-1724(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060a8:	04a1                	add	s1,s1,8
    800060aa:	ff3499e3          	bne	s1,s3,8000609c <sys_exec+0xe0>
  return ret;
    800060ae:	854a                	mv	a0,s2
    800060b0:	a011                	j	800060b4 <sys_exec+0xf8>
  return -1;
    800060b2:	557d                	li	a0,-1
}
    800060b4:	70fa                	ld	ra,440(sp)
    800060b6:	745a                	ld	s0,432(sp)
    800060b8:	74ba                	ld	s1,424(sp)
    800060ba:	791a                	ld	s2,416(sp)
    800060bc:	69fa                	ld	s3,408(sp)
    800060be:	6a5a                	ld	s4,400(sp)
    800060c0:	6139                	add	sp,sp,448
    800060c2:	8082                	ret

00000000800060c4 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060c4:	7139                	add	sp,sp,-64
    800060c6:	fc06                	sd	ra,56(sp)
    800060c8:	f822                	sd	s0,48(sp)
    800060ca:	f426                	sd	s1,40(sp)
    800060cc:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060ce:	ffffc097          	auipc	ra,0xffffc
    800060d2:	b36080e7          	jalr	-1226(ra) # 80001c04 <myproc>
    800060d6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800060d8:	fd840593          	add	a1,s0,-40
    800060dc:	4501                	li	a0,0
    800060de:	ffffd097          	auipc	ra,0xffffd
    800060e2:	fbe080e7          	jalr	-66(ra) # 8000309c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800060e6:	fc840593          	add	a1,s0,-56
    800060ea:	fd040513          	add	a0,s0,-48
    800060ee:	fffff097          	auipc	ra,0xfffff
    800060f2:	dc8080e7          	jalr	-568(ra) # 80004eb6 <pipealloc>
    return -1;
    800060f6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060f8:	0c054463          	bltz	a0,800061c0 <sys_pipe+0xfc>
  fd0 = -1;
    800060fc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006100:	fd043503          	ld	a0,-48(s0)
    80006104:	fffff097          	auipc	ra,0xfffff
    80006108:	502080e7          	jalr	1282(ra) # 80005606 <fdalloc>
    8000610c:	fca42223          	sw	a0,-60(s0)
    80006110:	08054b63          	bltz	a0,800061a6 <sys_pipe+0xe2>
    80006114:	fc843503          	ld	a0,-56(s0)
    80006118:	fffff097          	auipc	ra,0xfffff
    8000611c:	4ee080e7          	jalr	1262(ra) # 80005606 <fdalloc>
    80006120:	fca42023          	sw	a0,-64(s0)
    80006124:	06054863          	bltz	a0,80006194 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006128:	4691                	li	a3,4
    8000612a:	fc440613          	add	a2,s0,-60
    8000612e:	fd843583          	ld	a1,-40(s0)
    80006132:	68a8                	ld	a0,80(s1)
    80006134:	ffffb097          	auipc	ra,0xffffb
    80006138:	786080e7          	jalr	1926(ra) # 800018ba <copyout>
    8000613c:	02054063          	bltz	a0,8000615c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006140:	4691                	li	a3,4
    80006142:	fc040613          	add	a2,s0,-64
    80006146:	fd843583          	ld	a1,-40(s0)
    8000614a:	0591                	add	a1,a1,4
    8000614c:	68a8                	ld	a0,80(s1)
    8000614e:	ffffb097          	auipc	ra,0xffffb
    80006152:	76c080e7          	jalr	1900(ra) # 800018ba <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006156:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006158:	06055463          	bgez	a0,800061c0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000615c:	fc442783          	lw	a5,-60(s0)
    80006160:	07e9                	add	a5,a5,26
    80006162:	078e                	sll	a5,a5,0x3
    80006164:	97a6                	add	a5,a5,s1
    80006166:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000616a:	fc042783          	lw	a5,-64(s0)
    8000616e:	07e9                	add	a5,a5,26
    80006170:	078e                	sll	a5,a5,0x3
    80006172:	94be                	add	s1,s1,a5
    80006174:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006178:	fd043503          	ld	a0,-48(s0)
    8000617c:	fffff097          	auipc	ra,0xfffff
    80006180:	a0e080e7          	jalr	-1522(ra) # 80004b8a <fileclose>
    fileclose(wf);
    80006184:	fc843503          	ld	a0,-56(s0)
    80006188:	fffff097          	auipc	ra,0xfffff
    8000618c:	a02080e7          	jalr	-1534(ra) # 80004b8a <fileclose>
    return -1;
    80006190:	57fd                	li	a5,-1
    80006192:	a03d                	j	800061c0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006194:	fc442783          	lw	a5,-60(s0)
    80006198:	0007c763          	bltz	a5,800061a6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000619c:	07e9                	add	a5,a5,26
    8000619e:	078e                	sll	a5,a5,0x3
    800061a0:	97a6                	add	a5,a5,s1
    800061a2:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800061a6:	fd043503          	ld	a0,-48(s0)
    800061aa:	fffff097          	auipc	ra,0xfffff
    800061ae:	9e0080e7          	jalr	-1568(ra) # 80004b8a <fileclose>
    fileclose(wf);
    800061b2:	fc843503          	ld	a0,-56(s0)
    800061b6:	fffff097          	auipc	ra,0xfffff
    800061ba:	9d4080e7          	jalr	-1580(ra) # 80004b8a <fileclose>
    return -1;
    800061be:	57fd                	li	a5,-1
}
    800061c0:	853e                	mv	a0,a5
    800061c2:	70e2                	ld	ra,56(sp)
    800061c4:	7442                	ld	s0,48(sp)
    800061c6:	74a2                	ld	s1,40(sp)
    800061c8:	6121                	add	sp,sp,64
    800061ca:	8082                	ret
    800061cc:	0000                	unimp
	...

00000000800061d0 <kernelvec>:
    800061d0:	7111                	add	sp,sp,-256
    800061d2:	e006                	sd	ra,0(sp)
    800061d4:	e40a                	sd	sp,8(sp)
    800061d6:	e80e                	sd	gp,16(sp)
    800061d8:	ec12                	sd	tp,24(sp)
    800061da:	f016                	sd	t0,32(sp)
    800061dc:	f41a                	sd	t1,40(sp)
    800061de:	f81e                	sd	t2,48(sp)
    800061e0:	fc22                	sd	s0,56(sp)
    800061e2:	e0a6                	sd	s1,64(sp)
    800061e4:	e4aa                	sd	a0,72(sp)
    800061e6:	e8ae                	sd	a1,80(sp)
    800061e8:	ecb2                	sd	a2,88(sp)
    800061ea:	f0b6                	sd	a3,96(sp)
    800061ec:	f4ba                	sd	a4,104(sp)
    800061ee:	f8be                	sd	a5,112(sp)
    800061f0:	fcc2                	sd	a6,120(sp)
    800061f2:	e146                	sd	a7,128(sp)
    800061f4:	e54a                	sd	s2,136(sp)
    800061f6:	e94e                	sd	s3,144(sp)
    800061f8:	ed52                	sd	s4,152(sp)
    800061fa:	f156                	sd	s5,160(sp)
    800061fc:	f55a                	sd	s6,168(sp)
    800061fe:	f95e                	sd	s7,176(sp)
    80006200:	fd62                	sd	s8,184(sp)
    80006202:	e1e6                	sd	s9,192(sp)
    80006204:	e5ea                	sd	s10,200(sp)
    80006206:	e9ee                	sd	s11,208(sp)
    80006208:	edf2                	sd	t3,216(sp)
    8000620a:	f1f6                	sd	t4,224(sp)
    8000620c:	f5fa                	sd	t5,232(sp)
    8000620e:	f9fe                	sd	t6,240(sp)
    80006210:	c9bfc0ef          	jal	80002eaa <kerneltrap>
    80006214:	6082                	ld	ra,0(sp)
    80006216:	6122                	ld	sp,8(sp)
    80006218:	61c2                	ld	gp,16(sp)
    8000621a:	7282                	ld	t0,32(sp)
    8000621c:	7322                	ld	t1,40(sp)
    8000621e:	73c2                	ld	t2,48(sp)
    80006220:	7462                	ld	s0,56(sp)
    80006222:	6486                	ld	s1,64(sp)
    80006224:	6526                	ld	a0,72(sp)
    80006226:	65c6                	ld	a1,80(sp)
    80006228:	6666                	ld	a2,88(sp)
    8000622a:	7686                	ld	a3,96(sp)
    8000622c:	7726                	ld	a4,104(sp)
    8000622e:	77c6                	ld	a5,112(sp)
    80006230:	7866                	ld	a6,120(sp)
    80006232:	688a                	ld	a7,128(sp)
    80006234:	692a                	ld	s2,136(sp)
    80006236:	69ca                	ld	s3,144(sp)
    80006238:	6a6a                	ld	s4,152(sp)
    8000623a:	7a8a                	ld	s5,160(sp)
    8000623c:	7b2a                	ld	s6,168(sp)
    8000623e:	7bca                	ld	s7,176(sp)
    80006240:	7c6a                	ld	s8,184(sp)
    80006242:	6c8e                	ld	s9,192(sp)
    80006244:	6d2e                	ld	s10,200(sp)
    80006246:	6dce                	ld	s11,208(sp)
    80006248:	6e6e                	ld	t3,216(sp)
    8000624a:	7e8e                	ld	t4,224(sp)
    8000624c:	7f2e                	ld	t5,232(sp)
    8000624e:	7fce                	ld	t6,240(sp)
    80006250:	6111                	add	sp,sp,256
    80006252:	10200073          	sret
    80006256:	00000013          	nop
    8000625a:	00000013          	nop
    8000625e:	0001                	nop

0000000080006260 <timervec>:
    80006260:	34051573          	csrrw	a0,mscratch,a0
    80006264:	e10c                	sd	a1,0(a0)
    80006266:	e510                	sd	a2,8(a0)
    80006268:	e914                	sd	a3,16(a0)
    8000626a:	6d0c                	ld	a1,24(a0)
    8000626c:	7110                	ld	a2,32(a0)
    8000626e:	6194                	ld	a3,0(a1)
    80006270:	96b2                	add	a3,a3,a2
    80006272:	e194                	sd	a3,0(a1)
    80006274:	4589                	li	a1,2
    80006276:	14459073          	csrw	sip,a1
    8000627a:	6914                	ld	a3,16(a0)
    8000627c:	6510                	ld	a2,8(a0)
    8000627e:	610c                	ld	a1,0(a0)
    80006280:	34051573          	csrrw	a0,mscratch,a0
    80006284:	30200073          	mret
	...

000000008000628a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000628a:	1141                	add	sp,sp,-16
    8000628c:	e422                	sd	s0,8(sp)
    8000628e:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006290:	0c0007b7          	lui	a5,0xc000
    80006294:	4705                	li	a4,1
    80006296:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006298:	c3d8                	sw	a4,4(a5)
}
    8000629a:	6422                	ld	s0,8(sp)
    8000629c:	0141                	add	sp,sp,16
    8000629e:	8082                	ret

00000000800062a0 <plicinithart>:

void
plicinithart(void)
{
    800062a0:	1141                	add	sp,sp,-16
    800062a2:	e406                	sd	ra,8(sp)
    800062a4:	e022                	sd	s0,0(sp)
    800062a6:	0800                	add	s0,sp,16
  int hart = cpuid();
    800062a8:	ffffc097          	auipc	ra,0xffffc
    800062ac:	930080e7          	jalr	-1744(ra) # 80001bd8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062b0:	0085171b          	sllw	a4,a0,0x8
    800062b4:	0c0027b7          	lui	a5,0xc002
    800062b8:	97ba                	add	a5,a5,a4
    800062ba:	40200713          	li	a4,1026
    800062be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062c2:	00d5151b          	sllw	a0,a0,0xd
    800062c6:	0c2017b7          	lui	a5,0xc201
    800062ca:	97aa                	add	a5,a5,a0
    800062cc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800062d0:	60a2                	ld	ra,8(sp)
    800062d2:	6402                	ld	s0,0(sp)
    800062d4:	0141                	add	sp,sp,16
    800062d6:	8082                	ret

00000000800062d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062d8:	1141                	add	sp,sp,-16
    800062da:	e406                	sd	ra,8(sp)
    800062dc:	e022                	sd	s0,0(sp)
    800062de:	0800                	add	s0,sp,16
  int hart = cpuid();
    800062e0:	ffffc097          	auipc	ra,0xffffc
    800062e4:	8f8080e7          	jalr	-1800(ra) # 80001bd8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062e8:	00d5151b          	sllw	a0,a0,0xd
    800062ec:	0c2017b7          	lui	a5,0xc201
    800062f0:	97aa                	add	a5,a5,a0
  return irq;
}
    800062f2:	43c8                	lw	a0,4(a5)
    800062f4:	60a2                	ld	ra,8(sp)
    800062f6:	6402                	ld	s0,0(sp)
    800062f8:	0141                	add	sp,sp,16
    800062fa:	8082                	ret

00000000800062fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062fc:	1101                	add	sp,sp,-32
    800062fe:	ec06                	sd	ra,24(sp)
    80006300:	e822                	sd	s0,16(sp)
    80006302:	e426                	sd	s1,8(sp)
    80006304:	1000                	add	s0,sp,32
    80006306:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006308:	ffffc097          	auipc	ra,0xffffc
    8000630c:	8d0080e7          	jalr	-1840(ra) # 80001bd8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006310:	00d5151b          	sllw	a0,a0,0xd
    80006314:	0c2017b7          	lui	a5,0xc201
    80006318:	97aa                	add	a5,a5,a0
    8000631a:	c3c4                	sw	s1,4(a5)
}
    8000631c:	60e2                	ld	ra,24(sp)
    8000631e:	6442                	ld	s0,16(sp)
    80006320:	64a2                	ld	s1,8(sp)
    80006322:	6105                	add	sp,sp,32
    80006324:	8082                	ret

0000000080006326 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006326:	1141                	add	sp,sp,-16
    80006328:	e406                	sd	ra,8(sp)
    8000632a:	e022                	sd	s0,0(sp)
    8000632c:	0800                	add	s0,sp,16
  if(i >= NUM)
    8000632e:	479d                	li	a5,7
    80006330:	04a7cc63          	blt	a5,a0,80006388 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006334:	0003c797          	auipc	a5,0x3c
    80006338:	32478793          	add	a5,a5,804 # 80042658 <disk>
    8000633c:	97aa                	add	a5,a5,a0
    8000633e:	0187c783          	lbu	a5,24(a5)
    80006342:	ebb9                	bnez	a5,80006398 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006344:	00451693          	sll	a3,a0,0x4
    80006348:	0003c797          	auipc	a5,0x3c
    8000634c:	31078793          	add	a5,a5,784 # 80042658 <disk>
    80006350:	6398                	ld	a4,0(a5)
    80006352:	9736                	add	a4,a4,a3
    80006354:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006358:	6398                	ld	a4,0(a5)
    8000635a:	9736                	add	a4,a4,a3
    8000635c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006360:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006364:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006368:	97aa                	add	a5,a5,a0
    8000636a:	4705                	li	a4,1
    8000636c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006370:	0003c517          	auipc	a0,0x3c
    80006374:	30050513          	add	a0,a0,768 # 80042670 <disk+0x18>
    80006378:	ffffc097          	auipc	ra,0xffffc
    8000637c:	0c2080e7          	jalr	194(ra) # 8000243a <wakeup>
}
    80006380:	60a2                	ld	ra,8(sp)
    80006382:	6402                	ld	s0,0(sp)
    80006384:	0141                	add	sp,sp,16
    80006386:	8082                	ret
    panic("free_desc 1");
    80006388:	00002517          	auipc	a0,0x2
    8000638c:	3f050513          	add	a0,a0,1008 # 80008778 <syscalls+0x308>
    80006390:	ffffa097          	auipc	ra,0xffffa
    80006394:	1ac080e7          	jalr	428(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006398:	00002517          	auipc	a0,0x2
    8000639c:	3f050513          	add	a0,a0,1008 # 80008788 <syscalls+0x318>
    800063a0:	ffffa097          	auipc	ra,0xffffa
    800063a4:	19c080e7          	jalr	412(ra) # 8000053c <panic>

00000000800063a8 <virtio_disk_init>:
{
    800063a8:	1101                	add	sp,sp,-32
    800063aa:	ec06                	sd	ra,24(sp)
    800063ac:	e822                	sd	s0,16(sp)
    800063ae:	e426                	sd	s1,8(sp)
    800063b0:	e04a                	sd	s2,0(sp)
    800063b2:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063b4:	00002597          	auipc	a1,0x2
    800063b8:	3e458593          	add	a1,a1,996 # 80008798 <syscalls+0x328>
    800063bc:	0003c517          	auipc	a0,0x3c
    800063c0:	3c450513          	add	a0,a0,964 # 80042780 <disk+0x128>
    800063c4:	ffffb097          	auipc	ra,0xffffb
    800063c8:	9e4080e7          	jalr	-1564(ra) # 80000da8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063cc:	100017b7          	lui	a5,0x10001
    800063d0:	4398                	lw	a4,0(a5)
    800063d2:	2701                	sext.w	a4,a4
    800063d4:	747277b7          	lui	a5,0x74727
    800063d8:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063dc:	14f71b63          	bne	a4,a5,80006532 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800063e0:	100017b7          	lui	a5,0x10001
    800063e4:	43dc                	lw	a5,4(a5)
    800063e6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063e8:	4709                	li	a4,2
    800063ea:	14e79463          	bne	a5,a4,80006532 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063ee:	100017b7          	lui	a5,0x10001
    800063f2:	479c                	lw	a5,8(a5)
    800063f4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800063f6:	12e79e63          	bne	a5,a4,80006532 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800063fa:	100017b7          	lui	a5,0x10001
    800063fe:	47d8                	lw	a4,12(a5)
    80006400:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006402:	554d47b7          	lui	a5,0x554d4
    80006406:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000640a:	12f71463          	bne	a4,a5,80006532 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000640e:	100017b7          	lui	a5,0x10001
    80006412:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006416:	4705                	li	a4,1
    80006418:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000641a:	470d                	li	a4,3
    8000641c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000641e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006420:	c7ffe6b7          	lui	a3,0xc7ffe
    80006424:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fbbfc7>
    80006428:	8f75                	and	a4,a4,a3
    8000642a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000642c:	472d                	li	a4,11
    8000642e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006430:	5bbc                	lw	a5,112(a5)
    80006432:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006436:	8ba1                	and	a5,a5,8
    80006438:	10078563          	beqz	a5,80006542 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000643c:	100017b7          	lui	a5,0x10001
    80006440:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006444:	43fc                	lw	a5,68(a5)
    80006446:	2781                	sext.w	a5,a5
    80006448:	10079563          	bnez	a5,80006552 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000644c:	100017b7          	lui	a5,0x10001
    80006450:	5bdc                	lw	a5,52(a5)
    80006452:	2781                	sext.w	a5,a5
  if(max == 0)
    80006454:	10078763          	beqz	a5,80006562 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006458:	471d                	li	a4,7
    8000645a:	10f77c63          	bgeu	a4,a5,80006572 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	6fa080e7          	jalr	1786(ra) # 80000b58 <kalloc>
    80006466:	0003c497          	auipc	s1,0x3c
    8000646a:	1f248493          	add	s1,s1,498 # 80042658 <disk>
    8000646e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006470:	ffffa097          	auipc	ra,0xffffa
    80006474:	6e8080e7          	jalr	1768(ra) # 80000b58 <kalloc>
    80006478:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	6de080e7          	jalr	1758(ra) # 80000b58 <kalloc>
    80006482:	87aa                	mv	a5,a0
    80006484:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006486:	6088                	ld	a0,0(s1)
    80006488:	cd6d                	beqz	a0,80006582 <virtio_disk_init+0x1da>
    8000648a:	0003c717          	auipc	a4,0x3c
    8000648e:	1d673703          	ld	a4,470(a4) # 80042660 <disk+0x8>
    80006492:	cb65                	beqz	a4,80006582 <virtio_disk_init+0x1da>
    80006494:	c7fd                	beqz	a5,80006582 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006496:	6605                	lui	a2,0x1
    80006498:	4581                	li	a1,0
    8000649a:	ffffb097          	auipc	ra,0xffffb
    8000649e:	a9a080e7          	jalr	-1382(ra) # 80000f34 <memset>
  memset(disk.avail, 0, PGSIZE);
    800064a2:	0003c497          	auipc	s1,0x3c
    800064a6:	1b648493          	add	s1,s1,438 # 80042658 <disk>
    800064aa:	6605                	lui	a2,0x1
    800064ac:	4581                	li	a1,0
    800064ae:	6488                	ld	a0,8(s1)
    800064b0:	ffffb097          	auipc	ra,0xffffb
    800064b4:	a84080e7          	jalr	-1404(ra) # 80000f34 <memset>
  memset(disk.used, 0, PGSIZE);
    800064b8:	6605                	lui	a2,0x1
    800064ba:	4581                	li	a1,0
    800064bc:	6888                	ld	a0,16(s1)
    800064be:	ffffb097          	auipc	ra,0xffffb
    800064c2:	a76080e7          	jalr	-1418(ra) # 80000f34 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800064c6:	100017b7          	lui	a5,0x10001
    800064ca:	4721                	li	a4,8
    800064cc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800064ce:	4098                	lw	a4,0(s1)
    800064d0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800064d4:	40d8                	lw	a4,4(s1)
    800064d6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800064da:	6498                	ld	a4,8(s1)
    800064dc:	0007069b          	sext.w	a3,a4
    800064e0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800064e4:	9701                	sra	a4,a4,0x20
    800064e6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800064ea:	6898                	ld	a4,16(s1)
    800064ec:	0007069b          	sext.w	a3,a4
    800064f0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800064f4:	9701                	sra	a4,a4,0x20
    800064f6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800064fa:	4705                	li	a4,1
    800064fc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800064fe:	00e48c23          	sb	a4,24(s1)
    80006502:	00e48ca3          	sb	a4,25(s1)
    80006506:	00e48d23          	sb	a4,26(s1)
    8000650a:	00e48da3          	sb	a4,27(s1)
    8000650e:	00e48e23          	sb	a4,28(s1)
    80006512:	00e48ea3          	sb	a4,29(s1)
    80006516:	00e48f23          	sb	a4,30(s1)
    8000651a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000651e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006522:	0727a823          	sw	s2,112(a5)
}
    80006526:	60e2                	ld	ra,24(sp)
    80006528:	6442                	ld	s0,16(sp)
    8000652a:	64a2                	ld	s1,8(sp)
    8000652c:	6902                	ld	s2,0(sp)
    8000652e:	6105                	add	sp,sp,32
    80006530:	8082                	ret
    panic("could not find virtio disk");
    80006532:	00002517          	auipc	a0,0x2
    80006536:	27650513          	add	a0,a0,630 # 800087a8 <syscalls+0x338>
    8000653a:	ffffa097          	auipc	ra,0xffffa
    8000653e:	002080e7          	jalr	2(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006542:	00002517          	auipc	a0,0x2
    80006546:	28650513          	add	a0,a0,646 # 800087c8 <syscalls+0x358>
    8000654a:	ffffa097          	auipc	ra,0xffffa
    8000654e:	ff2080e7          	jalr	-14(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006552:	00002517          	auipc	a0,0x2
    80006556:	29650513          	add	a0,a0,662 # 800087e8 <syscalls+0x378>
    8000655a:	ffffa097          	auipc	ra,0xffffa
    8000655e:	fe2080e7          	jalr	-30(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006562:	00002517          	auipc	a0,0x2
    80006566:	2a650513          	add	a0,a0,678 # 80008808 <syscalls+0x398>
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	fd2080e7          	jalr	-46(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006572:	00002517          	auipc	a0,0x2
    80006576:	2b650513          	add	a0,a0,694 # 80008828 <syscalls+0x3b8>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	fc2080e7          	jalr	-62(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006582:	00002517          	auipc	a0,0x2
    80006586:	2c650513          	add	a0,a0,710 # 80008848 <syscalls+0x3d8>
    8000658a:	ffffa097          	auipc	ra,0xffffa
    8000658e:	fb2080e7          	jalr	-78(ra) # 8000053c <panic>

0000000080006592 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006592:	7159                	add	sp,sp,-112
    80006594:	f486                	sd	ra,104(sp)
    80006596:	f0a2                	sd	s0,96(sp)
    80006598:	eca6                	sd	s1,88(sp)
    8000659a:	e8ca                	sd	s2,80(sp)
    8000659c:	e4ce                	sd	s3,72(sp)
    8000659e:	e0d2                	sd	s4,64(sp)
    800065a0:	fc56                	sd	s5,56(sp)
    800065a2:	f85a                	sd	s6,48(sp)
    800065a4:	f45e                	sd	s7,40(sp)
    800065a6:	f062                	sd	s8,32(sp)
    800065a8:	ec66                	sd	s9,24(sp)
    800065aa:	e86a                	sd	s10,16(sp)
    800065ac:	1880                	add	s0,sp,112
    800065ae:	8a2a                	mv	s4,a0
    800065b0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065b2:	00c52c83          	lw	s9,12(a0)
    800065b6:	001c9c9b          	sllw	s9,s9,0x1
    800065ba:	1c82                	sll	s9,s9,0x20
    800065bc:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800065c0:	0003c517          	auipc	a0,0x3c
    800065c4:	1c050513          	add	a0,a0,448 # 80042780 <disk+0x128>
    800065c8:	ffffb097          	auipc	ra,0xffffb
    800065cc:	870080e7          	jalr	-1936(ra) # 80000e38 <acquire>
  for(int i = 0; i < 3; i++){
    800065d0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800065d2:	44a1                	li	s1,8
      disk.free[i] = 0;
    800065d4:	0003cb17          	auipc	s6,0x3c
    800065d8:	084b0b13          	add	s6,s6,132 # 80042658 <disk>
  for(int i = 0; i < 3; i++){
    800065dc:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065de:	0003cc17          	auipc	s8,0x3c
    800065e2:	1a2c0c13          	add	s8,s8,418 # 80042780 <disk+0x128>
    800065e6:	a095                	j	8000664a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800065e8:	00fb0733          	add	a4,s6,a5
    800065ec:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800065f0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800065f2:	0207c563          	bltz	a5,8000661c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800065f6:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800065f8:	0591                	add	a1,a1,4
    800065fa:	05560d63          	beq	a2,s5,80006654 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800065fe:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006600:	0003c717          	auipc	a4,0x3c
    80006604:	05870713          	add	a4,a4,88 # 80042658 <disk>
    80006608:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000660a:	01874683          	lbu	a3,24(a4)
    8000660e:	fee9                	bnez	a3,800065e8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006610:	2785                	addw	a5,a5,1
    80006612:	0705                	add	a4,a4,1
    80006614:	fe979be3          	bne	a5,s1,8000660a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006618:	57fd                	li	a5,-1
    8000661a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000661c:	00c05e63          	blez	a2,80006638 <virtio_disk_rw+0xa6>
    80006620:	060a                	sll	a2,a2,0x2
    80006622:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006626:	0009a503          	lw	a0,0(s3)
    8000662a:	00000097          	auipc	ra,0x0
    8000662e:	cfc080e7          	jalr	-772(ra) # 80006326 <free_desc>
      for(int j = 0; j < i; j++)
    80006632:	0991                	add	s3,s3,4
    80006634:	ffa999e3          	bne	s3,s10,80006626 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006638:	85e2                	mv	a1,s8
    8000663a:	0003c517          	auipc	a0,0x3c
    8000663e:	03650513          	add	a0,a0,54 # 80042670 <disk+0x18>
    80006642:	ffffc097          	auipc	ra,0xffffc
    80006646:	d94080e7          	jalr	-620(ra) # 800023d6 <sleep>
  for(int i = 0; i < 3; i++){
    8000664a:	f9040993          	add	s3,s0,-112
{
    8000664e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006650:	864a                	mv	a2,s2
    80006652:	b775                	j	800065fe <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006654:	f9042503          	lw	a0,-112(s0)
    80006658:	00a50713          	add	a4,a0,10
    8000665c:	0712                	sll	a4,a4,0x4

  if(write)
    8000665e:	0003c797          	auipc	a5,0x3c
    80006662:	ffa78793          	add	a5,a5,-6 # 80042658 <disk>
    80006666:	00e786b3          	add	a3,a5,a4
    8000666a:	01703633          	snez	a2,s7
    8000666e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006670:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006674:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006678:	f6070613          	add	a2,a4,-160
    8000667c:	6394                	ld	a3,0(a5)
    8000667e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006680:	00870593          	add	a1,a4,8
    80006684:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006686:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006688:	0007b803          	ld	a6,0(a5)
    8000668c:	9642                	add	a2,a2,a6
    8000668e:	46c1                	li	a3,16
    80006690:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006692:	4585                	li	a1,1
    80006694:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006698:	f9442683          	lw	a3,-108(s0)
    8000669c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800066a0:	0692                	sll	a3,a3,0x4
    800066a2:	9836                	add	a6,a6,a3
    800066a4:	058a0613          	add	a2,s4,88
    800066a8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800066ac:	0007b803          	ld	a6,0(a5)
    800066b0:	96c2                	add	a3,a3,a6
    800066b2:	40000613          	li	a2,1024
    800066b6:	c690                	sw	a2,8(a3)
  if(write)
    800066b8:	001bb613          	seqz	a2,s7
    800066bc:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800066c0:	00166613          	or	a2,a2,1
    800066c4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800066c8:	f9842603          	lw	a2,-104(s0)
    800066cc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800066d0:	00250693          	add	a3,a0,2
    800066d4:	0692                	sll	a3,a3,0x4
    800066d6:	96be                	add	a3,a3,a5
    800066d8:	58fd                	li	a7,-1
    800066da:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066de:	0612                	sll	a2,a2,0x4
    800066e0:	9832                	add	a6,a6,a2
    800066e2:	f9070713          	add	a4,a4,-112
    800066e6:	973e                	add	a4,a4,a5
    800066e8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800066ec:	6398                	ld	a4,0(a5)
    800066ee:	9732                	add	a4,a4,a2
    800066f0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066f2:	4609                	li	a2,2
    800066f4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800066f8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066fc:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006700:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006704:	6794                	ld	a3,8(a5)
    80006706:	0026d703          	lhu	a4,2(a3)
    8000670a:	8b1d                	and	a4,a4,7
    8000670c:	0706                	sll	a4,a4,0x1
    8000670e:	96ba                	add	a3,a3,a4
    80006710:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006714:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006718:	6798                	ld	a4,8(a5)
    8000671a:	00275783          	lhu	a5,2(a4)
    8000671e:	2785                	addw	a5,a5,1
    80006720:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006724:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006728:	100017b7          	lui	a5,0x10001
    8000672c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006730:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006734:	0003c917          	auipc	s2,0x3c
    80006738:	04c90913          	add	s2,s2,76 # 80042780 <disk+0x128>
  while(b->disk == 1) {
    8000673c:	4485                	li	s1,1
    8000673e:	00b79c63          	bne	a5,a1,80006756 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006742:	85ca                	mv	a1,s2
    80006744:	8552                	mv	a0,s4
    80006746:	ffffc097          	auipc	ra,0xffffc
    8000674a:	c90080e7          	jalr	-880(ra) # 800023d6 <sleep>
  while(b->disk == 1) {
    8000674e:	004a2783          	lw	a5,4(s4)
    80006752:	fe9788e3          	beq	a5,s1,80006742 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006756:	f9042903          	lw	s2,-112(s0)
    8000675a:	00290713          	add	a4,s2,2
    8000675e:	0712                	sll	a4,a4,0x4
    80006760:	0003c797          	auipc	a5,0x3c
    80006764:	ef878793          	add	a5,a5,-264 # 80042658 <disk>
    80006768:	97ba                	add	a5,a5,a4
    8000676a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000676e:	0003c997          	auipc	s3,0x3c
    80006772:	eea98993          	add	s3,s3,-278 # 80042658 <disk>
    80006776:	00491713          	sll	a4,s2,0x4
    8000677a:	0009b783          	ld	a5,0(s3)
    8000677e:	97ba                	add	a5,a5,a4
    80006780:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006784:	854a                	mv	a0,s2
    80006786:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000678a:	00000097          	auipc	ra,0x0
    8000678e:	b9c080e7          	jalr	-1124(ra) # 80006326 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006792:	8885                	and	s1,s1,1
    80006794:	f0ed                	bnez	s1,80006776 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006796:	0003c517          	auipc	a0,0x3c
    8000679a:	fea50513          	add	a0,a0,-22 # 80042780 <disk+0x128>
    8000679e:	ffffa097          	auipc	ra,0xffffa
    800067a2:	74e080e7          	jalr	1870(ra) # 80000eec <release>
}
    800067a6:	70a6                	ld	ra,104(sp)
    800067a8:	7406                	ld	s0,96(sp)
    800067aa:	64e6                	ld	s1,88(sp)
    800067ac:	6946                	ld	s2,80(sp)
    800067ae:	69a6                	ld	s3,72(sp)
    800067b0:	6a06                	ld	s4,64(sp)
    800067b2:	7ae2                	ld	s5,56(sp)
    800067b4:	7b42                	ld	s6,48(sp)
    800067b6:	7ba2                	ld	s7,40(sp)
    800067b8:	7c02                	ld	s8,32(sp)
    800067ba:	6ce2                	ld	s9,24(sp)
    800067bc:	6d42                	ld	s10,16(sp)
    800067be:	6165                	add	sp,sp,112
    800067c0:	8082                	ret

00000000800067c2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067c2:	1101                	add	sp,sp,-32
    800067c4:	ec06                	sd	ra,24(sp)
    800067c6:	e822                	sd	s0,16(sp)
    800067c8:	e426                	sd	s1,8(sp)
    800067ca:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067cc:	0003c497          	auipc	s1,0x3c
    800067d0:	e8c48493          	add	s1,s1,-372 # 80042658 <disk>
    800067d4:	0003c517          	auipc	a0,0x3c
    800067d8:	fac50513          	add	a0,a0,-84 # 80042780 <disk+0x128>
    800067dc:	ffffa097          	auipc	ra,0xffffa
    800067e0:	65c080e7          	jalr	1628(ra) # 80000e38 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067e4:	10001737          	lui	a4,0x10001
    800067e8:	533c                	lw	a5,96(a4)
    800067ea:	8b8d                	and	a5,a5,3
    800067ec:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067ee:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067f2:	689c                	ld	a5,16(s1)
    800067f4:	0204d703          	lhu	a4,32(s1)
    800067f8:	0027d783          	lhu	a5,2(a5)
    800067fc:	04f70863          	beq	a4,a5,8000684c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006800:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006804:	6898                	ld	a4,16(s1)
    80006806:	0204d783          	lhu	a5,32(s1)
    8000680a:	8b9d                	and	a5,a5,7
    8000680c:	078e                	sll	a5,a5,0x3
    8000680e:	97ba                	add	a5,a5,a4
    80006810:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006812:	00278713          	add	a4,a5,2
    80006816:	0712                	sll	a4,a4,0x4
    80006818:	9726                	add	a4,a4,s1
    8000681a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000681e:	e721                	bnez	a4,80006866 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006820:	0789                	add	a5,a5,2
    80006822:	0792                	sll	a5,a5,0x4
    80006824:	97a6                	add	a5,a5,s1
    80006826:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006828:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000682c:	ffffc097          	auipc	ra,0xffffc
    80006830:	c0e080e7          	jalr	-1010(ra) # 8000243a <wakeup>

    disk.used_idx += 1;
    80006834:	0204d783          	lhu	a5,32(s1)
    80006838:	2785                	addw	a5,a5,1
    8000683a:	17c2                	sll	a5,a5,0x30
    8000683c:	93c1                	srl	a5,a5,0x30
    8000683e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006842:	6898                	ld	a4,16(s1)
    80006844:	00275703          	lhu	a4,2(a4)
    80006848:	faf71ce3          	bne	a4,a5,80006800 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000684c:	0003c517          	auipc	a0,0x3c
    80006850:	f3450513          	add	a0,a0,-204 # 80042780 <disk+0x128>
    80006854:	ffffa097          	auipc	ra,0xffffa
    80006858:	698080e7          	jalr	1688(ra) # 80000eec <release>
}
    8000685c:	60e2                	ld	ra,24(sp)
    8000685e:	6442                	ld	s0,16(sp)
    80006860:	64a2                	ld	s1,8(sp)
    80006862:	6105                	add	sp,sp,32
    80006864:	8082                	ret
      panic("virtio_disk_intr status");
    80006866:	00002517          	auipc	a0,0x2
    8000686a:	ffa50513          	add	a0,a0,-6 # 80008860 <syscalls+0x3f0>
    8000686e:	ffffa097          	auipc	ra,0xffffa
    80006872:	cce080e7          	jalr	-818(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	sll	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	sll	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
