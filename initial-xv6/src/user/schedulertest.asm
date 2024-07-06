
user/_schedulertest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:

#define NFORK 10
#define IO 5

int main()
{
   0:	7139                	add	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	0080                	add	s0,sp,64
  int n, pid;
  int wtime, rtime;
  int twtime = 0, trtime = 0;
  for (n = 0; n < NFORK; n++)
   e:	4481                	li	s1,0
  10:	4929                	li	s2,10
  {
    pid = fork();
  12:	00000097          	auipc	ra,0x0
  16:	35a080e7          	jalr	858(ra) # 36c <fork>
    if (pid < 0)
  1a:	02054063          	bltz	a0,3a <main+0x3a>
      break;
    if (pid == 0)
  1e:	c521                	beqz	a0,66 <main+0x66>
      exit(0);
      
      
    }
    else{
       set_priority(80, 9);
  20:	45a5                	li	a1,9
  22:	05000513          	li	a0,80
  26:	00000097          	auipc	ra,0x0
  2a:	3fe080e7          	jalr	1022(ra) # 424 <set_priority>
  for (n = 0; n < NFORK; n++)
  2e:	2485                	addw	s1,s1,1
  30:	ff2491e3          	bne	s1,s2,12 <main+0x12>
  34:	4901                	li	s2,0
  36:	4981                	li	s3,0
  38:	a079                	j	c6 <main+0xc6>
    }
  }
  for (; n > 0; n--)
  3a:	fe904de3          	bgtz	s1,34 <main+0x34>
  3e:	4901                	li	s2,0
  40:	4981                	li	s3,0
    {
      trtime += rtime;
      twtime += wtime;
    }
  }
  printf("Average rtime %d,  wtime %d\n", trtime / NFORK, twtime / NFORK);
  42:	45a9                	li	a1,10
  44:	02b9c63b          	divw	a2,s3,a1
  48:	02b945bb          	divw	a1,s2,a1
  4c:	00001517          	auipc	a0,0x1
  50:	86c50513          	add	a0,a0,-1940 # 8b8 <malloc+0x10c>
  54:	00000097          	auipc	ra,0x0
  58:	6a0080e7          	jalr	1696(ra) # 6f4 <printf>
  exit(0);
  5c:	4501                	li	a0,0
  5e:	00000097          	auipc	ra,0x0
  62:	316080e7          	jalr	790(ra) # 374 <exit>
      if (n < IO)
  66:	4791                	li	a5,4
  68:	0497d663          	bge	a5,s1,b4 <main+0xb4>
        for (volatile int i = 0; i < 1000000000; i++)
  6c:	fc042223          	sw	zero,-60(s0)
  70:	fc442703          	lw	a4,-60(s0)
  74:	2701                	sext.w	a4,a4
  76:	3b9ad7b7          	lui	a5,0x3b9ad
  7a:	9ff78793          	add	a5,a5,-1537 # 3b9ac9ff <base+0x3b9ab9ef>
  7e:	00e7cd63          	blt	a5,a4,98 <main+0x98>
  82:	873e                	mv	a4,a5
  84:	fc442783          	lw	a5,-60(s0)
  88:	2785                	addw	a5,a5,1
  8a:	fcf42223          	sw	a5,-60(s0)
  8e:	fc442783          	lw	a5,-60(s0)
  92:	2781                	sext.w	a5,a5
  94:	fef758e3          	bge	a4,a5,84 <main+0x84>
       printf("Process %d finished\n", n);
  98:	85a6                	mv	a1,s1
  9a:	00001517          	auipc	a0,0x1
  9e:	80650513          	add	a0,a0,-2042 # 8a0 <malloc+0xf4>
  a2:	00000097          	auipc	ra,0x0
  a6:	652080e7          	jalr	1618(ra) # 6f4 <printf>
      exit(0);
  aa:	4501                	li	a0,0
  ac:	00000097          	auipc	ra,0x0
  b0:	2c8080e7          	jalr	712(ra) # 374 <exit>
        sleep(200); // IO bound processes
  b4:	0c800513          	li	a0,200
  b8:	00000097          	auipc	ra,0x0
  bc:	34c080e7          	jalr	844(ra) # 404 <sleep>
  c0:	bfe1                	j	98 <main+0x98>
  for (; n > 0; n--)
  c2:	34fd                	addw	s1,s1,-1
  c4:	dcbd                	beqz	s1,42 <main+0x42>
    if (waitx(0, &wtime, &rtime) >= 0)
  c6:	fc840613          	add	a2,s0,-56
  ca:	fcc40593          	add	a1,s0,-52
  ce:	4501                	li	a0,0
  d0:	00000097          	auipc	ra,0x0
  d4:	344080e7          	jalr	836(ra) # 414 <waitx>
  d8:	fe0545e3          	bltz	a0,c2 <main+0xc2>
      trtime += rtime;
  dc:	fc842783          	lw	a5,-56(s0)
  e0:	0127893b          	addw	s2,a5,s2
      twtime += wtime;
  e4:	fcc42783          	lw	a5,-52(s0)
  e8:	013789bb          	addw	s3,a5,s3
  ec:	bfd9                	j	c2 <main+0xc2>

00000000000000ee <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  ee:	1141                	add	sp,sp,-16
  f0:	e406                	sd	ra,8(sp)
  f2:	e022                	sd	s0,0(sp)
  f4:	0800                	add	s0,sp,16
  extern int main();
  main();
  f6:	00000097          	auipc	ra,0x0
  fa:	f0a080e7          	jalr	-246(ra) # 0 <main>
  exit(0);
  fe:	4501                	li	a0,0
 100:	00000097          	auipc	ra,0x0
 104:	274080e7          	jalr	628(ra) # 374 <exit>

0000000000000108 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 108:	1141                	add	sp,sp,-16
 10a:	e422                	sd	s0,8(sp)
 10c:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 10e:	87aa                	mv	a5,a0
 110:	0585                	add	a1,a1,1
 112:	0785                	add	a5,a5,1
 114:	fff5c703          	lbu	a4,-1(a1)
 118:	fee78fa3          	sb	a4,-1(a5)
 11c:	fb75                	bnez	a4,110 <strcpy+0x8>
    ;
  return os;
}
 11e:	6422                	ld	s0,8(sp)
 120:	0141                	add	sp,sp,16
 122:	8082                	ret

0000000000000124 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 124:	1141                	add	sp,sp,-16
 126:	e422                	sd	s0,8(sp)
 128:	0800                	add	s0,sp,16
  while(*p && *p == *q)
 12a:	00054783          	lbu	a5,0(a0)
 12e:	cb91                	beqz	a5,142 <strcmp+0x1e>
 130:	0005c703          	lbu	a4,0(a1)
 134:	00f71763          	bne	a4,a5,142 <strcmp+0x1e>
    p++, q++;
 138:	0505                	add	a0,a0,1
 13a:	0585                	add	a1,a1,1
  while(*p && *p == *q)
 13c:	00054783          	lbu	a5,0(a0)
 140:	fbe5                	bnez	a5,130 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 142:	0005c503          	lbu	a0,0(a1)
}
 146:	40a7853b          	subw	a0,a5,a0
 14a:	6422                	ld	s0,8(sp)
 14c:	0141                	add	sp,sp,16
 14e:	8082                	ret

0000000000000150 <strlen>:

uint
strlen(const char *s)
{
 150:	1141                	add	sp,sp,-16
 152:	e422                	sd	s0,8(sp)
 154:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 156:	00054783          	lbu	a5,0(a0)
 15a:	cf91                	beqz	a5,176 <strlen+0x26>
 15c:	0505                	add	a0,a0,1
 15e:	87aa                	mv	a5,a0
 160:	86be                	mv	a3,a5
 162:	0785                	add	a5,a5,1
 164:	fff7c703          	lbu	a4,-1(a5)
 168:	ff65                	bnez	a4,160 <strlen+0x10>
 16a:	40a6853b          	subw	a0,a3,a0
 16e:	2505                	addw	a0,a0,1
    ;
  return n;
}
 170:	6422                	ld	s0,8(sp)
 172:	0141                	add	sp,sp,16
 174:	8082                	ret
  for(n = 0; s[n]; n++)
 176:	4501                	li	a0,0
 178:	bfe5                	j	170 <strlen+0x20>

000000000000017a <memset>:

void*
memset(void *dst, int c, uint n)
{
 17a:	1141                	add	sp,sp,-16
 17c:	e422                	sd	s0,8(sp)
 17e:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 180:	ca19                	beqz	a2,196 <memset+0x1c>
 182:	87aa                	mv	a5,a0
 184:	1602                	sll	a2,a2,0x20
 186:	9201                	srl	a2,a2,0x20
 188:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 18c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 190:	0785                	add	a5,a5,1
 192:	fee79de3          	bne	a5,a4,18c <memset+0x12>
  }
  return dst;
}
 196:	6422                	ld	s0,8(sp)
 198:	0141                	add	sp,sp,16
 19a:	8082                	ret

000000000000019c <strchr>:

char*
strchr(const char *s, char c)
{
 19c:	1141                	add	sp,sp,-16
 19e:	e422                	sd	s0,8(sp)
 1a0:	0800                	add	s0,sp,16
  for(; *s; s++)
 1a2:	00054783          	lbu	a5,0(a0)
 1a6:	cb99                	beqz	a5,1bc <strchr+0x20>
    if(*s == c)
 1a8:	00f58763          	beq	a1,a5,1b6 <strchr+0x1a>
  for(; *s; s++)
 1ac:	0505                	add	a0,a0,1
 1ae:	00054783          	lbu	a5,0(a0)
 1b2:	fbfd                	bnez	a5,1a8 <strchr+0xc>
      return (char*)s;
  return 0;
 1b4:	4501                	li	a0,0
}
 1b6:	6422                	ld	s0,8(sp)
 1b8:	0141                	add	sp,sp,16
 1ba:	8082                	ret
  return 0;
 1bc:	4501                	li	a0,0
 1be:	bfe5                	j	1b6 <strchr+0x1a>

00000000000001c0 <gets>:

char*
gets(char *buf, int max)
{
 1c0:	711d                	add	sp,sp,-96
 1c2:	ec86                	sd	ra,88(sp)
 1c4:	e8a2                	sd	s0,80(sp)
 1c6:	e4a6                	sd	s1,72(sp)
 1c8:	e0ca                	sd	s2,64(sp)
 1ca:	fc4e                	sd	s3,56(sp)
 1cc:	f852                	sd	s4,48(sp)
 1ce:	f456                	sd	s5,40(sp)
 1d0:	f05a                	sd	s6,32(sp)
 1d2:	ec5e                	sd	s7,24(sp)
 1d4:	1080                	add	s0,sp,96
 1d6:	8baa                	mv	s7,a0
 1d8:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1da:	892a                	mv	s2,a0
 1dc:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1de:	4aa9                	li	s5,10
 1e0:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1e2:	89a6                	mv	s3,s1
 1e4:	2485                	addw	s1,s1,1
 1e6:	0344d863          	bge	s1,s4,216 <gets+0x56>
    cc = read(0, &c, 1);
 1ea:	4605                	li	a2,1
 1ec:	faf40593          	add	a1,s0,-81
 1f0:	4501                	li	a0,0
 1f2:	00000097          	auipc	ra,0x0
 1f6:	19a080e7          	jalr	410(ra) # 38c <read>
    if(cc < 1)
 1fa:	00a05e63          	blez	a0,216 <gets+0x56>
    buf[i++] = c;
 1fe:	faf44783          	lbu	a5,-81(s0)
 202:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 206:	01578763          	beq	a5,s5,214 <gets+0x54>
 20a:	0905                	add	s2,s2,1
 20c:	fd679be3          	bne	a5,s6,1e2 <gets+0x22>
  for(i=0; i+1 < max; ){
 210:	89a6                	mv	s3,s1
 212:	a011                	j	216 <gets+0x56>
 214:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 216:	99de                	add	s3,s3,s7
 218:	00098023          	sb	zero,0(s3)
  return buf;
}
 21c:	855e                	mv	a0,s7
 21e:	60e6                	ld	ra,88(sp)
 220:	6446                	ld	s0,80(sp)
 222:	64a6                	ld	s1,72(sp)
 224:	6906                	ld	s2,64(sp)
 226:	79e2                	ld	s3,56(sp)
 228:	7a42                	ld	s4,48(sp)
 22a:	7aa2                	ld	s5,40(sp)
 22c:	7b02                	ld	s6,32(sp)
 22e:	6be2                	ld	s7,24(sp)
 230:	6125                	add	sp,sp,96
 232:	8082                	ret

0000000000000234 <stat>:

int
stat(const char *n, struct stat *st)
{
 234:	1101                	add	sp,sp,-32
 236:	ec06                	sd	ra,24(sp)
 238:	e822                	sd	s0,16(sp)
 23a:	e426                	sd	s1,8(sp)
 23c:	e04a                	sd	s2,0(sp)
 23e:	1000                	add	s0,sp,32
 240:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 242:	4581                	li	a1,0
 244:	00000097          	auipc	ra,0x0
 248:	170080e7          	jalr	368(ra) # 3b4 <open>
  if(fd < 0)
 24c:	02054563          	bltz	a0,276 <stat+0x42>
 250:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 252:	85ca                	mv	a1,s2
 254:	00000097          	auipc	ra,0x0
 258:	178080e7          	jalr	376(ra) # 3cc <fstat>
 25c:	892a                	mv	s2,a0
  close(fd);
 25e:	8526                	mv	a0,s1
 260:	00000097          	auipc	ra,0x0
 264:	13c080e7          	jalr	316(ra) # 39c <close>
  return r;
}
 268:	854a                	mv	a0,s2
 26a:	60e2                	ld	ra,24(sp)
 26c:	6442                	ld	s0,16(sp)
 26e:	64a2                	ld	s1,8(sp)
 270:	6902                	ld	s2,0(sp)
 272:	6105                	add	sp,sp,32
 274:	8082                	ret
    return -1;
 276:	597d                	li	s2,-1
 278:	bfc5                	j	268 <stat+0x34>

000000000000027a <atoi>:

int
atoi(const char *s)
{
 27a:	1141                	add	sp,sp,-16
 27c:	e422                	sd	s0,8(sp)
 27e:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 280:	00054683          	lbu	a3,0(a0)
 284:	fd06879b          	addw	a5,a3,-48
 288:	0ff7f793          	zext.b	a5,a5
 28c:	4625                	li	a2,9
 28e:	02f66863          	bltu	a2,a5,2be <atoi+0x44>
 292:	872a                	mv	a4,a0
  n = 0;
 294:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 296:	0705                	add	a4,a4,1
 298:	0025179b          	sllw	a5,a0,0x2
 29c:	9fa9                	addw	a5,a5,a0
 29e:	0017979b          	sllw	a5,a5,0x1
 2a2:	9fb5                	addw	a5,a5,a3
 2a4:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2a8:	00074683          	lbu	a3,0(a4)
 2ac:	fd06879b          	addw	a5,a3,-48
 2b0:	0ff7f793          	zext.b	a5,a5
 2b4:	fef671e3          	bgeu	a2,a5,296 <atoi+0x1c>
  return n;
}
 2b8:	6422                	ld	s0,8(sp)
 2ba:	0141                	add	sp,sp,16
 2bc:	8082                	ret
  n = 0;
 2be:	4501                	li	a0,0
 2c0:	bfe5                	j	2b8 <atoi+0x3e>

00000000000002c2 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2c2:	1141                	add	sp,sp,-16
 2c4:	e422                	sd	s0,8(sp)
 2c6:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2c8:	02b57463          	bgeu	a0,a1,2f0 <memmove+0x2e>
    while(n-- > 0)
 2cc:	00c05f63          	blez	a2,2ea <memmove+0x28>
 2d0:	1602                	sll	a2,a2,0x20
 2d2:	9201                	srl	a2,a2,0x20
 2d4:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2d8:	872a                	mv	a4,a0
      *dst++ = *src++;
 2da:	0585                	add	a1,a1,1
 2dc:	0705                	add	a4,a4,1
 2de:	fff5c683          	lbu	a3,-1(a1)
 2e2:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2e6:	fee79ae3          	bne	a5,a4,2da <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2ea:	6422                	ld	s0,8(sp)
 2ec:	0141                	add	sp,sp,16
 2ee:	8082                	ret
    dst += n;
 2f0:	00c50733          	add	a4,a0,a2
    src += n;
 2f4:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2f6:	fec05ae3          	blez	a2,2ea <memmove+0x28>
 2fa:	fff6079b          	addw	a5,a2,-1
 2fe:	1782                	sll	a5,a5,0x20
 300:	9381                	srl	a5,a5,0x20
 302:	fff7c793          	not	a5,a5
 306:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 308:	15fd                	add	a1,a1,-1
 30a:	177d                	add	a4,a4,-1
 30c:	0005c683          	lbu	a3,0(a1)
 310:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 314:	fee79ae3          	bne	a5,a4,308 <memmove+0x46>
 318:	bfc9                	j	2ea <memmove+0x28>

000000000000031a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 31a:	1141                	add	sp,sp,-16
 31c:	e422                	sd	s0,8(sp)
 31e:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 320:	ca05                	beqz	a2,350 <memcmp+0x36>
 322:	fff6069b          	addw	a3,a2,-1
 326:	1682                	sll	a3,a3,0x20
 328:	9281                	srl	a3,a3,0x20
 32a:	0685                	add	a3,a3,1
 32c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 32e:	00054783          	lbu	a5,0(a0)
 332:	0005c703          	lbu	a4,0(a1)
 336:	00e79863          	bne	a5,a4,346 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 33a:	0505                	add	a0,a0,1
    p2++;
 33c:	0585                	add	a1,a1,1
  while (n-- > 0) {
 33e:	fed518e3          	bne	a0,a3,32e <memcmp+0x14>
  }
  return 0;
 342:	4501                	li	a0,0
 344:	a019                	j	34a <memcmp+0x30>
      return *p1 - *p2;
 346:	40e7853b          	subw	a0,a5,a4
}
 34a:	6422                	ld	s0,8(sp)
 34c:	0141                	add	sp,sp,16
 34e:	8082                	ret
  return 0;
 350:	4501                	li	a0,0
 352:	bfe5                	j	34a <memcmp+0x30>

0000000000000354 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 354:	1141                	add	sp,sp,-16
 356:	e406                	sd	ra,8(sp)
 358:	e022                	sd	s0,0(sp)
 35a:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 35c:	00000097          	auipc	ra,0x0
 360:	f66080e7          	jalr	-154(ra) # 2c2 <memmove>
}
 364:	60a2                	ld	ra,8(sp)
 366:	6402                	ld	s0,0(sp)
 368:	0141                	add	sp,sp,16
 36a:	8082                	ret

000000000000036c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 36c:	4885                	li	a7,1
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <exit>:
.global exit
exit:
 li a7, SYS_exit
 374:	4889                	li	a7,2
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <wait>:
.global wait
wait:
 li a7, SYS_wait
 37c:	488d                	li	a7,3
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 384:	4891                	li	a7,4
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <read>:
.global read
read:
 li a7, SYS_read
 38c:	4895                	li	a7,5
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <write>:
.global write
write:
 li a7, SYS_write
 394:	48c1                	li	a7,16
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <close>:
.global close
close:
 li a7, SYS_close
 39c:	48d5                	li	a7,21
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <kill>:
.global kill
kill:
 li a7, SYS_kill
 3a4:	4899                	li	a7,6
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <exec>:
.global exec
exec:
 li a7, SYS_exec
 3ac:	489d                	li	a7,7
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <open>:
.global open
open:
 li a7, SYS_open
 3b4:	48bd                	li	a7,15
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3bc:	48c5                	li	a7,17
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3c4:	48c9                	li	a7,18
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3cc:	48a1                	li	a7,8
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <link>:
.global link
link:
 li a7, SYS_link
 3d4:	48cd                	li	a7,19
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3dc:	48d1                	li	a7,20
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3e4:	48a5                	li	a7,9
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <dup>:
.global dup
dup:
 li a7, SYS_dup
 3ec:	48a9                	li	a7,10
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3f4:	48ad                	li	a7,11
 ecall
 3f6:	00000073          	ecall
 ret
 3fa:	8082                	ret

00000000000003fc <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3fc:	48b1                	li	a7,12
 ecall
 3fe:	00000073          	ecall
 ret
 402:	8082                	ret

0000000000000404 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 404:	48b5                	li	a7,13
 ecall
 406:	00000073          	ecall
 ret
 40a:	8082                	ret

000000000000040c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 40c:	48b9                	li	a7,14
 ecall
 40e:	00000073          	ecall
 ret
 412:	8082                	ret

0000000000000414 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 414:	48d9                	li	a7,22
 ecall
 416:	00000073          	ecall
 ret
 41a:	8082                	ret

000000000000041c <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 41c:	48dd                	li	a7,23
 ecall
 41e:	00000073          	ecall
 ret
 422:	8082                	ret

0000000000000424 <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 424:	48e1                	li	a7,24
 ecall
 426:	00000073          	ecall
 ret
 42a:	8082                	ret

000000000000042c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 42c:	1101                	add	sp,sp,-32
 42e:	ec06                	sd	ra,24(sp)
 430:	e822                	sd	s0,16(sp)
 432:	1000                	add	s0,sp,32
 434:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 438:	4605                	li	a2,1
 43a:	fef40593          	add	a1,s0,-17
 43e:	00000097          	auipc	ra,0x0
 442:	f56080e7          	jalr	-170(ra) # 394 <write>
}
 446:	60e2                	ld	ra,24(sp)
 448:	6442                	ld	s0,16(sp)
 44a:	6105                	add	sp,sp,32
 44c:	8082                	ret

000000000000044e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 44e:	7139                	add	sp,sp,-64
 450:	fc06                	sd	ra,56(sp)
 452:	f822                	sd	s0,48(sp)
 454:	f426                	sd	s1,40(sp)
 456:	f04a                	sd	s2,32(sp)
 458:	ec4e                	sd	s3,24(sp)
 45a:	0080                	add	s0,sp,64
 45c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 45e:	c299                	beqz	a3,464 <printint+0x16>
 460:	0805c963          	bltz	a1,4f2 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 464:	2581                	sext.w	a1,a1
  neg = 0;
 466:	4881                	li	a7,0
 468:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 46c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 46e:	2601                	sext.w	a2,a2
 470:	00000517          	auipc	a0,0x0
 474:	4c850513          	add	a0,a0,1224 # 938 <digits>
 478:	883a                	mv	a6,a4
 47a:	2705                	addw	a4,a4,1
 47c:	02c5f7bb          	remuw	a5,a1,a2
 480:	1782                	sll	a5,a5,0x20
 482:	9381                	srl	a5,a5,0x20
 484:	97aa                	add	a5,a5,a0
 486:	0007c783          	lbu	a5,0(a5)
 48a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 48e:	0005879b          	sext.w	a5,a1
 492:	02c5d5bb          	divuw	a1,a1,a2
 496:	0685                	add	a3,a3,1
 498:	fec7f0e3          	bgeu	a5,a2,478 <printint+0x2a>
  if(neg)
 49c:	00088c63          	beqz	a7,4b4 <printint+0x66>
    buf[i++] = '-';
 4a0:	fd070793          	add	a5,a4,-48
 4a4:	00878733          	add	a4,a5,s0
 4a8:	02d00793          	li	a5,45
 4ac:	fef70823          	sb	a5,-16(a4)
 4b0:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 4b4:	02e05863          	blez	a4,4e4 <printint+0x96>
 4b8:	fc040793          	add	a5,s0,-64
 4bc:	00e78933          	add	s2,a5,a4
 4c0:	fff78993          	add	s3,a5,-1
 4c4:	99ba                	add	s3,s3,a4
 4c6:	377d                	addw	a4,a4,-1
 4c8:	1702                	sll	a4,a4,0x20
 4ca:	9301                	srl	a4,a4,0x20
 4cc:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4d0:	fff94583          	lbu	a1,-1(s2)
 4d4:	8526                	mv	a0,s1
 4d6:	00000097          	auipc	ra,0x0
 4da:	f56080e7          	jalr	-170(ra) # 42c <putc>
  while(--i >= 0)
 4de:	197d                	add	s2,s2,-1
 4e0:	ff3918e3          	bne	s2,s3,4d0 <printint+0x82>
}
 4e4:	70e2                	ld	ra,56(sp)
 4e6:	7442                	ld	s0,48(sp)
 4e8:	74a2                	ld	s1,40(sp)
 4ea:	7902                	ld	s2,32(sp)
 4ec:	69e2                	ld	s3,24(sp)
 4ee:	6121                	add	sp,sp,64
 4f0:	8082                	ret
    x = -xx;
 4f2:	40b005bb          	negw	a1,a1
    neg = 1;
 4f6:	4885                	li	a7,1
    x = -xx;
 4f8:	bf85                	j	468 <printint+0x1a>

00000000000004fa <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4fa:	715d                	add	sp,sp,-80
 4fc:	e486                	sd	ra,72(sp)
 4fe:	e0a2                	sd	s0,64(sp)
 500:	fc26                	sd	s1,56(sp)
 502:	f84a                	sd	s2,48(sp)
 504:	f44e                	sd	s3,40(sp)
 506:	f052                	sd	s4,32(sp)
 508:	ec56                	sd	s5,24(sp)
 50a:	e85a                	sd	s6,16(sp)
 50c:	e45e                	sd	s7,8(sp)
 50e:	e062                	sd	s8,0(sp)
 510:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 512:	0005c903          	lbu	s2,0(a1)
 516:	18090c63          	beqz	s2,6ae <vprintf+0x1b4>
 51a:	8aaa                	mv	s5,a0
 51c:	8bb2                	mv	s7,a2
 51e:	00158493          	add	s1,a1,1
  state = 0;
 522:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 524:	02500a13          	li	s4,37
 528:	4b55                	li	s6,21
 52a:	a839                	j	548 <vprintf+0x4e>
        putc(fd, c);
 52c:	85ca                	mv	a1,s2
 52e:	8556                	mv	a0,s5
 530:	00000097          	auipc	ra,0x0
 534:	efc080e7          	jalr	-260(ra) # 42c <putc>
 538:	a019                	j	53e <vprintf+0x44>
    } else if(state == '%'){
 53a:	01498d63          	beq	s3,s4,554 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 53e:	0485                	add	s1,s1,1
 540:	fff4c903          	lbu	s2,-1(s1)
 544:	16090563          	beqz	s2,6ae <vprintf+0x1b4>
    if(state == 0){
 548:	fe0999e3          	bnez	s3,53a <vprintf+0x40>
      if(c == '%'){
 54c:	ff4910e3          	bne	s2,s4,52c <vprintf+0x32>
        state = '%';
 550:	89d2                	mv	s3,s4
 552:	b7f5                	j	53e <vprintf+0x44>
      if(c == 'd'){
 554:	13490263          	beq	s2,s4,678 <vprintf+0x17e>
 558:	f9d9079b          	addw	a5,s2,-99
 55c:	0ff7f793          	zext.b	a5,a5
 560:	12fb6563          	bltu	s6,a5,68a <vprintf+0x190>
 564:	f9d9079b          	addw	a5,s2,-99
 568:	0ff7f713          	zext.b	a4,a5
 56c:	10eb6f63          	bltu	s6,a4,68a <vprintf+0x190>
 570:	00271793          	sll	a5,a4,0x2
 574:	00000717          	auipc	a4,0x0
 578:	36c70713          	add	a4,a4,876 # 8e0 <malloc+0x134>
 57c:	97ba                	add	a5,a5,a4
 57e:	439c                	lw	a5,0(a5)
 580:	97ba                	add	a5,a5,a4
 582:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 584:	008b8913          	add	s2,s7,8
 588:	4685                	li	a3,1
 58a:	4629                	li	a2,10
 58c:	000ba583          	lw	a1,0(s7)
 590:	8556                	mv	a0,s5
 592:	00000097          	auipc	ra,0x0
 596:	ebc080e7          	jalr	-324(ra) # 44e <printint>
 59a:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 59c:	4981                	li	s3,0
 59e:	b745                	j	53e <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5a0:	008b8913          	add	s2,s7,8
 5a4:	4681                	li	a3,0
 5a6:	4629                	li	a2,10
 5a8:	000ba583          	lw	a1,0(s7)
 5ac:	8556                	mv	a0,s5
 5ae:	00000097          	auipc	ra,0x0
 5b2:	ea0080e7          	jalr	-352(ra) # 44e <printint>
 5b6:	8bca                	mv	s7,s2
      state = 0;
 5b8:	4981                	li	s3,0
 5ba:	b751                	j	53e <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 5bc:	008b8913          	add	s2,s7,8
 5c0:	4681                	li	a3,0
 5c2:	4641                	li	a2,16
 5c4:	000ba583          	lw	a1,0(s7)
 5c8:	8556                	mv	a0,s5
 5ca:	00000097          	auipc	ra,0x0
 5ce:	e84080e7          	jalr	-380(ra) # 44e <printint>
 5d2:	8bca                	mv	s7,s2
      state = 0;
 5d4:	4981                	li	s3,0
 5d6:	b7a5                	j	53e <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 5d8:	008b8c13          	add	s8,s7,8
 5dc:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 5e0:	03000593          	li	a1,48
 5e4:	8556                	mv	a0,s5
 5e6:	00000097          	auipc	ra,0x0
 5ea:	e46080e7          	jalr	-442(ra) # 42c <putc>
  putc(fd, 'x');
 5ee:	07800593          	li	a1,120
 5f2:	8556                	mv	a0,s5
 5f4:	00000097          	auipc	ra,0x0
 5f8:	e38080e7          	jalr	-456(ra) # 42c <putc>
 5fc:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5fe:	00000b97          	auipc	s7,0x0
 602:	33ab8b93          	add	s7,s7,826 # 938 <digits>
 606:	03c9d793          	srl	a5,s3,0x3c
 60a:	97de                	add	a5,a5,s7
 60c:	0007c583          	lbu	a1,0(a5)
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	e1a080e7          	jalr	-486(ra) # 42c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 61a:	0992                	sll	s3,s3,0x4
 61c:	397d                	addw	s2,s2,-1
 61e:	fe0914e3          	bnez	s2,606 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 622:	8be2                	mv	s7,s8
      state = 0;
 624:	4981                	li	s3,0
 626:	bf21                	j	53e <vprintf+0x44>
        s = va_arg(ap, char*);
 628:	008b8993          	add	s3,s7,8
 62c:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 630:	02090163          	beqz	s2,652 <vprintf+0x158>
        while(*s != 0){
 634:	00094583          	lbu	a1,0(s2)
 638:	c9a5                	beqz	a1,6a8 <vprintf+0x1ae>
          putc(fd, *s);
 63a:	8556                	mv	a0,s5
 63c:	00000097          	auipc	ra,0x0
 640:	df0080e7          	jalr	-528(ra) # 42c <putc>
          s++;
 644:	0905                	add	s2,s2,1
        while(*s != 0){
 646:	00094583          	lbu	a1,0(s2)
 64a:	f9e5                	bnez	a1,63a <vprintf+0x140>
        s = va_arg(ap, char*);
 64c:	8bce                	mv	s7,s3
      state = 0;
 64e:	4981                	li	s3,0
 650:	b5fd                	j	53e <vprintf+0x44>
          s = "(null)";
 652:	00000917          	auipc	s2,0x0
 656:	28690913          	add	s2,s2,646 # 8d8 <malloc+0x12c>
        while(*s != 0){
 65a:	02800593          	li	a1,40
 65e:	bff1                	j	63a <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 660:	008b8913          	add	s2,s7,8
 664:	000bc583          	lbu	a1,0(s7)
 668:	8556                	mv	a0,s5
 66a:	00000097          	auipc	ra,0x0
 66e:	dc2080e7          	jalr	-574(ra) # 42c <putc>
 672:	8bca                	mv	s7,s2
      state = 0;
 674:	4981                	li	s3,0
 676:	b5e1                	j	53e <vprintf+0x44>
        putc(fd, c);
 678:	02500593          	li	a1,37
 67c:	8556                	mv	a0,s5
 67e:	00000097          	auipc	ra,0x0
 682:	dae080e7          	jalr	-594(ra) # 42c <putc>
      state = 0;
 686:	4981                	li	s3,0
 688:	bd5d                	j	53e <vprintf+0x44>
        putc(fd, '%');
 68a:	02500593          	li	a1,37
 68e:	8556                	mv	a0,s5
 690:	00000097          	auipc	ra,0x0
 694:	d9c080e7          	jalr	-612(ra) # 42c <putc>
        putc(fd, c);
 698:	85ca                	mv	a1,s2
 69a:	8556                	mv	a0,s5
 69c:	00000097          	auipc	ra,0x0
 6a0:	d90080e7          	jalr	-624(ra) # 42c <putc>
      state = 0;
 6a4:	4981                	li	s3,0
 6a6:	bd61                	j	53e <vprintf+0x44>
        s = va_arg(ap, char*);
 6a8:	8bce                	mv	s7,s3
      state = 0;
 6aa:	4981                	li	s3,0
 6ac:	bd49                	j	53e <vprintf+0x44>
    }
  }
}
 6ae:	60a6                	ld	ra,72(sp)
 6b0:	6406                	ld	s0,64(sp)
 6b2:	74e2                	ld	s1,56(sp)
 6b4:	7942                	ld	s2,48(sp)
 6b6:	79a2                	ld	s3,40(sp)
 6b8:	7a02                	ld	s4,32(sp)
 6ba:	6ae2                	ld	s5,24(sp)
 6bc:	6b42                	ld	s6,16(sp)
 6be:	6ba2                	ld	s7,8(sp)
 6c0:	6c02                	ld	s8,0(sp)
 6c2:	6161                	add	sp,sp,80
 6c4:	8082                	ret

00000000000006c6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6c6:	715d                	add	sp,sp,-80
 6c8:	ec06                	sd	ra,24(sp)
 6ca:	e822                	sd	s0,16(sp)
 6cc:	1000                	add	s0,sp,32
 6ce:	e010                	sd	a2,0(s0)
 6d0:	e414                	sd	a3,8(s0)
 6d2:	e818                	sd	a4,16(s0)
 6d4:	ec1c                	sd	a5,24(s0)
 6d6:	03043023          	sd	a6,32(s0)
 6da:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6de:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6e2:	8622                	mv	a2,s0
 6e4:	00000097          	auipc	ra,0x0
 6e8:	e16080e7          	jalr	-490(ra) # 4fa <vprintf>
}
 6ec:	60e2                	ld	ra,24(sp)
 6ee:	6442                	ld	s0,16(sp)
 6f0:	6161                	add	sp,sp,80
 6f2:	8082                	ret

00000000000006f4 <printf>:

void
printf(const char *fmt, ...)
{
 6f4:	711d                	add	sp,sp,-96
 6f6:	ec06                	sd	ra,24(sp)
 6f8:	e822                	sd	s0,16(sp)
 6fa:	1000                	add	s0,sp,32
 6fc:	e40c                	sd	a1,8(s0)
 6fe:	e810                	sd	a2,16(s0)
 700:	ec14                	sd	a3,24(s0)
 702:	f018                	sd	a4,32(s0)
 704:	f41c                	sd	a5,40(s0)
 706:	03043823          	sd	a6,48(s0)
 70a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 70e:	00840613          	add	a2,s0,8
 712:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 716:	85aa                	mv	a1,a0
 718:	4505                	li	a0,1
 71a:	00000097          	auipc	ra,0x0
 71e:	de0080e7          	jalr	-544(ra) # 4fa <vprintf>
}
 722:	60e2                	ld	ra,24(sp)
 724:	6442                	ld	s0,16(sp)
 726:	6125                	add	sp,sp,96
 728:	8082                	ret

000000000000072a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 72a:	1141                	add	sp,sp,-16
 72c:	e422                	sd	s0,8(sp)
 72e:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 730:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 734:	00001797          	auipc	a5,0x1
 738:	8cc7b783          	ld	a5,-1844(a5) # 1000 <freep>
 73c:	a02d                	j	766 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 73e:	4618                	lw	a4,8(a2)
 740:	9f2d                	addw	a4,a4,a1
 742:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 746:	6398                	ld	a4,0(a5)
 748:	6310                	ld	a2,0(a4)
 74a:	a83d                	j	788 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 74c:	ff852703          	lw	a4,-8(a0)
 750:	9f31                	addw	a4,a4,a2
 752:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 754:	ff053683          	ld	a3,-16(a0)
 758:	a091                	j	79c <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 75a:	6398                	ld	a4,0(a5)
 75c:	00e7e463          	bltu	a5,a4,764 <free+0x3a>
 760:	00e6ea63          	bltu	a3,a4,774 <free+0x4a>
{
 764:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 766:	fed7fae3          	bgeu	a5,a3,75a <free+0x30>
 76a:	6398                	ld	a4,0(a5)
 76c:	00e6e463          	bltu	a3,a4,774 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 770:	fee7eae3          	bltu	a5,a4,764 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 774:	ff852583          	lw	a1,-8(a0)
 778:	6390                	ld	a2,0(a5)
 77a:	02059813          	sll	a6,a1,0x20
 77e:	01c85713          	srl	a4,a6,0x1c
 782:	9736                	add	a4,a4,a3
 784:	fae60de3          	beq	a2,a4,73e <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 788:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 78c:	4790                	lw	a2,8(a5)
 78e:	02061593          	sll	a1,a2,0x20
 792:	01c5d713          	srl	a4,a1,0x1c
 796:	973e                	add	a4,a4,a5
 798:	fae68ae3          	beq	a3,a4,74c <free+0x22>
    p->s.ptr = bp->s.ptr;
 79c:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 79e:	00001717          	auipc	a4,0x1
 7a2:	86f73123          	sd	a5,-1950(a4) # 1000 <freep>
}
 7a6:	6422                	ld	s0,8(sp)
 7a8:	0141                	add	sp,sp,16
 7aa:	8082                	ret

00000000000007ac <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7ac:	7139                	add	sp,sp,-64
 7ae:	fc06                	sd	ra,56(sp)
 7b0:	f822                	sd	s0,48(sp)
 7b2:	f426                	sd	s1,40(sp)
 7b4:	f04a                	sd	s2,32(sp)
 7b6:	ec4e                	sd	s3,24(sp)
 7b8:	e852                	sd	s4,16(sp)
 7ba:	e456                	sd	s5,8(sp)
 7bc:	e05a                	sd	s6,0(sp)
 7be:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7c0:	02051493          	sll	s1,a0,0x20
 7c4:	9081                	srl	s1,s1,0x20
 7c6:	04bd                	add	s1,s1,15
 7c8:	8091                	srl	s1,s1,0x4
 7ca:	0014899b          	addw	s3,s1,1
 7ce:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 7d0:	00001517          	auipc	a0,0x1
 7d4:	83053503          	ld	a0,-2000(a0) # 1000 <freep>
 7d8:	c515                	beqz	a0,804 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7da:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7dc:	4798                	lw	a4,8(a5)
 7de:	02977f63          	bgeu	a4,s1,81c <malloc+0x70>
  if(nu < 4096)
 7e2:	8a4e                	mv	s4,s3
 7e4:	0009871b          	sext.w	a4,s3
 7e8:	6685                	lui	a3,0x1
 7ea:	00d77363          	bgeu	a4,a3,7f0 <malloc+0x44>
 7ee:	6a05                	lui	s4,0x1
 7f0:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7f4:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7f8:	00001917          	auipc	s2,0x1
 7fc:	80890913          	add	s2,s2,-2040 # 1000 <freep>
  if(p == (char*)-1)
 800:	5afd                	li	s5,-1
 802:	a895                	j	876 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 804:	00001797          	auipc	a5,0x1
 808:	80c78793          	add	a5,a5,-2036 # 1010 <base>
 80c:	00000717          	auipc	a4,0x0
 810:	7ef73a23          	sd	a5,2036(a4) # 1000 <freep>
 814:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 816:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 81a:	b7e1                	j	7e2 <malloc+0x36>
      if(p->s.size == nunits)
 81c:	02e48c63          	beq	s1,a4,854 <malloc+0xa8>
        p->s.size -= nunits;
 820:	4137073b          	subw	a4,a4,s3
 824:	c798                	sw	a4,8(a5)
        p += p->s.size;
 826:	02071693          	sll	a3,a4,0x20
 82a:	01c6d713          	srl	a4,a3,0x1c
 82e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 830:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 834:	00000717          	auipc	a4,0x0
 838:	7ca73623          	sd	a0,1996(a4) # 1000 <freep>
      return (void*)(p + 1);
 83c:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 840:	70e2                	ld	ra,56(sp)
 842:	7442                	ld	s0,48(sp)
 844:	74a2                	ld	s1,40(sp)
 846:	7902                	ld	s2,32(sp)
 848:	69e2                	ld	s3,24(sp)
 84a:	6a42                	ld	s4,16(sp)
 84c:	6aa2                	ld	s5,8(sp)
 84e:	6b02                	ld	s6,0(sp)
 850:	6121                	add	sp,sp,64
 852:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 854:	6398                	ld	a4,0(a5)
 856:	e118                	sd	a4,0(a0)
 858:	bff1                	j	834 <malloc+0x88>
  hp->s.size = nu;
 85a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 85e:	0541                	add	a0,a0,16
 860:	00000097          	auipc	ra,0x0
 864:	eca080e7          	jalr	-310(ra) # 72a <free>
  return freep;
 868:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 86c:	d971                	beqz	a0,840 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 86e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 870:	4798                	lw	a4,8(a5)
 872:	fa9775e3          	bgeu	a4,s1,81c <malloc+0x70>
    if(p == freep)
 876:	00093703          	ld	a4,0(s2)
 87a:	853e                	mv	a0,a5
 87c:	fef719e3          	bne	a4,a5,86e <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 880:	8552                	mv	a0,s4
 882:	00000097          	auipc	ra,0x0
 886:	b7a080e7          	jalr	-1158(ra) # 3fc <sbrk>
  if(p == (char*)-1)
 88a:	fd5518e3          	bne	a0,s5,85a <malloc+0xae>
        return 0;
 88e:	4501                	li	a0,0
 890:	bf45                	j	840 <malloc+0x94>
