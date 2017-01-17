
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 f0 10 00       	mov    $0x10f000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 f0 10 f0       	mov    $0xf010f000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 c0 17 10 f0       	push   $0xf01017c0
f0100050:	e8 64 08 00 00       	call   f01008b9 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 25                	jle    f0100081 <test_backtrace+0x41>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
	else
		mon_backtrace(0, 0, 0);
	cprintf("leaving test_backtrace %d\n", x);
f010006b:	83 ec 08             	sub    $0x8,%esp
f010006e:	53                   	push   %ebx
f010006f:	68 dc 17 10 f0       	push   $0xf01017dc
f0100074:	e8 40 08 00 00       	call   f01008b9 <cprintf>
}
f0100079:	83 c4 10             	add    $0x10,%esp
f010007c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010007f:	c9                   	leave  
f0100080:	c3                   	ret    
{
	cprintf("entering test_backtrace %d\n", x);
	if (x > 0)
		test_backtrace(x-1);
	else
		mon_backtrace(0, 0, 0);
f0100081:	83 ec 04             	sub    $0x4,%esp
f0100084:	6a 00                	push   $0x0
f0100086:	6a 00                	push   $0x0
f0100088:	6a 00                	push   $0x0
f010008a:	e8 a9 06 00 00       	call   f0100738 <mon_backtrace>
f010008f:	83 c4 10             	add    $0x10,%esp
f0100092:	eb d7                	jmp    f010006b <test_backtrace+0x2b>

f0100094 <i386_init>:
	cprintf("leaving test_backtrace %d\n", x);
}

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 19 11 f0       	mov    $0xf0111944,%eax
f010009f:	2d 00 13 11 f0       	sub    $0xf0111300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 13 11 f0       	push   $0xf0111300
f01000ac:	e8 c8 12 00 00       	call   f0101379 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 89 04 00 00       	call   f010053f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 f7 17 10 f0       	push   $0xf01017f7
f01000c3:	e8 f1 07 00 00       	call   f01008b9 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 61 06 00 00       	call   f0100742 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 19 11 f0 00 	cmpl   $0x0,0xf0111940
f01000f5:	74 0f                	je     f0100106 <_panic+0x20>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000f7:	83 ec 0c             	sub    $0xc,%esp
f01000fa:	6a 00                	push   $0x0
f01000fc:	e8 41 06 00 00       	call   f0100742 <monitor>
f0100101:	83 c4 10             	add    $0x10,%esp
f0100104:	eb f1                	jmp    f01000f7 <_panic+0x11>
{
	va_list ap;

	if (panicstr)
		goto dead;
	panicstr = fmt;
f0100106:	89 35 40 19 11 f0    	mov    %esi,0xf0111940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f010010c:	fa                   	cli    
f010010d:	fc                   	cld    

	va_start(ap, fmt);
f010010e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100111:	83 ec 04             	sub    $0x4,%esp
f0100114:	ff 75 0c             	pushl  0xc(%ebp)
f0100117:	ff 75 08             	pushl  0x8(%ebp)
f010011a:	68 12 18 10 f0       	push   $0xf0101812
f010011f:	e8 95 07 00 00       	call   f01008b9 <cprintf>
	vcprintf(fmt, ap);
f0100124:	83 c4 08             	add    $0x8,%esp
f0100127:	53                   	push   %ebx
f0100128:	56                   	push   %esi
f0100129:	e8 65 07 00 00       	call   f0100893 <vcprintf>
	cprintf("\n");
f010012e:	c7 04 24 4e 18 10 f0 	movl   $0xf010184e,(%esp)
f0100135:	e8 7f 07 00 00       	call   f01008b9 <cprintf>
f010013a:	83 c4 10             	add    $0x10,%esp
f010013d:	eb b8                	jmp    f01000f7 <_panic+0x11>

f010013f <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013f:	55                   	push   %ebp
f0100140:	89 e5                	mov    %esp,%ebp
f0100142:	53                   	push   %ebx
f0100143:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100146:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100149:	ff 75 0c             	pushl  0xc(%ebp)
f010014c:	ff 75 08             	pushl  0x8(%ebp)
f010014f:	68 2a 18 10 f0       	push   $0xf010182a
f0100154:	e8 60 07 00 00       	call   f01008b9 <cprintf>
	vcprintf(fmt, ap);
f0100159:	83 c4 08             	add    $0x8,%esp
f010015c:	53                   	push   %ebx
f010015d:	ff 75 10             	pushl  0x10(%ebp)
f0100160:	e8 2e 07 00 00       	call   f0100893 <vcprintf>
	cprintf("\n");
f0100165:	c7 04 24 4e 18 10 f0 	movl   $0xf010184e,(%esp)
f010016c:	e8 48 07 00 00       	call   f01008b9 <cprintf>
	va_end(ap);
}
f0100171:	83 c4 10             	add    $0x10,%esp
f0100174:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100177:	c9                   	leave  
f0100178:	c3                   	ret    
f0100179:	00 00                	add    %al,(%eax)
	...

f010017c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010017c:	55                   	push   %ebp
f010017d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100184:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100185:	a8 01                	test   $0x1,%al
f0100187:	74 0b                	je     f0100194 <serial_proc_data+0x18>
f0100189:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010018e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018f:	0f b6 c0             	movzbl %al,%eax
}
f0100192:	5d                   	pop    %ebp
f0100193:	c3                   	ret    

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100194:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100199:	eb f7                	jmp    f0100192 <serial_proc_data+0x16>

f010019b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010019b:	55                   	push   %ebp
f010019c:	89 e5                	mov    %esp,%ebp
f010019e:	53                   	push   %ebx
f010019f:	83 ec 04             	sub    $0x4,%esp
f01001a2:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001a4:	ff d3                	call   *%ebx
f01001a6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a9:	74 2d                	je     f01001d8 <cons_intr+0x3d>
		if (c == 0)
f01001ab:	85 c0                	test   %eax,%eax
f01001ad:	74 f5                	je     f01001a4 <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f01001af:	8b 0d 24 15 11 f0    	mov    0xf0111524,%ecx
f01001b5:	8d 51 01             	lea    0x1(%ecx),%edx
f01001b8:	89 15 24 15 11 f0    	mov    %edx,0xf0111524
f01001be:	88 81 20 13 11 f0    	mov    %al,-0xfeeece0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001c4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ca:	75 d8                	jne    f01001a4 <cons_intr+0x9>
			cons.wpos = 0;
f01001cc:	c7 05 24 15 11 f0 00 	movl   $0x0,0xf0111524
f01001d3:	00 00 00 
f01001d6:	eb cc                	jmp    f01001a4 <cons_intr+0x9>
	}
}
f01001d8:	83 c4 04             	add    $0x4,%esp
f01001db:	5b                   	pop    %ebx
f01001dc:	5d                   	pop    %ebp
f01001dd:	c3                   	ret    

f01001de <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001de:	55                   	push   %ebp
f01001df:	89 e5                	mov    %esp,%ebp
f01001e1:	53                   	push   %ebx
f01001e2:	83 ec 04             	sub    $0x4,%esp
f01001e5:	ba 64 00 00 00       	mov    $0x64,%edx
f01001ea:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001eb:	a8 01                	test   $0x1,%al
f01001ed:	0f 84 eb 00 00 00    	je     f01002de <kbd_proc_data+0x100>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001f3:	a8 20                	test   $0x20,%al
f01001f5:	0f 85 ea 00 00 00    	jne    f01002e5 <kbd_proc_data+0x107>
f01001fb:	ba 60 00 00 00       	mov    $0x60,%edx
f0100200:	ec                   	in     (%dx),%al
f0100201:	88 c2                	mov    %al,%dl
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100203:	3c e0                	cmp    $0xe0,%al
f0100205:	74 73                	je     f010027a <kbd_proc_data+0x9c>
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100207:	84 c0                	test   %al,%al
f0100209:	78 7d                	js     f0100288 <kbd_proc_data+0xaa>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
		shift &= ~(shiftcode[data] | E0ESC);
		return 0;
	} else if (shift & E0ESC) {
f010020b:	8b 0d 00 13 11 f0    	mov    0xf0111300,%ecx
f0100211:	f6 c1 40             	test   $0x40,%cl
f0100214:	74 0e                	je     f0100224 <kbd_proc_data+0x46>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100216:	83 c8 80             	or     $0xffffff80,%eax
f0100219:	88 c2                	mov    %al,%dl
		shift &= ~E0ESC;
f010021b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010021e:	89 0d 00 13 11 f0    	mov    %ecx,0xf0111300
	}

	shift |= shiftcode[data];
f0100224:	0f b6 d2             	movzbl %dl,%edx
f0100227:	0f b6 82 a0 19 10 f0 	movzbl -0xfefe660(%edx),%eax
f010022e:	0b 05 00 13 11 f0    	or     0xf0111300,%eax
	shift ^= togglecode[data];
f0100234:	0f b6 8a a0 18 10 f0 	movzbl -0xfefe760(%edx),%ecx
f010023b:	31 c8                	xor    %ecx,%eax
f010023d:	a3 00 13 11 f0       	mov    %eax,0xf0111300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100242:	89 c1                	mov    %eax,%ecx
f0100244:	83 e1 03             	and    $0x3,%ecx
f0100247:	8b 0c 8d 80 18 10 f0 	mov    -0xfefe780(,%ecx,4),%ecx
f010024e:	8a 14 11             	mov    (%ecx,%edx,1),%dl
f0100251:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100254:	a8 08                	test   $0x8,%al
f0100256:	74 0d                	je     f0100265 <kbd_proc_data+0x87>
		if ('a' <= c && c <= 'z')
f0100258:	89 da                	mov    %ebx,%edx
f010025a:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010025d:	83 f9 19             	cmp    $0x19,%ecx
f0100260:	77 55                	ja     f01002b7 <kbd_proc_data+0xd9>
			c += 'A' - 'a';
f0100262:	83 eb 20             	sub    $0x20,%ebx
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100265:	f7 d0                	not    %eax
f0100267:	a8 06                	test   $0x6,%al
f0100269:	75 08                	jne    f0100273 <kbd_proc_data+0x95>
f010026b:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100271:	74 51                	je     f01002c4 <kbd_proc_data+0xe6>
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100273:	89 d8                	mov    %ebx,%eax
f0100275:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100278:	c9                   	leave  
f0100279:	c3                   	ret    

	data = inb(KBDATAP);

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
f010027a:	83 0d 00 13 11 f0 40 	orl    $0x40,0xf0111300
		return 0;
f0100281:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100286:	eb eb                	jmp    f0100273 <kbd_proc_data+0x95>
	} else if (data & 0x80) {
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100288:	8b 0d 00 13 11 f0    	mov    0xf0111300,%ecx
f010028e:	f6 c1 40             	test   $0x40,%cl
f0100291:	75 05                	jne    f0100298 <kbd_proc_data+0xba>
f0100293:	83 e0 7f             	and    $0x7f,%eax
f0100296:	88 c2                	mov    %al,%dl
		shift &= ~(shiftcode[data] | E0ESC);
f0100298:	0f b6 d2             	movzbl %dl,%edx
f010029b:	8a 82 a0 19 10 f0    	mov    -0xfefe660(%edx),%al
f01002a1:	83 c8 40             	or     $0x40,%eax
f01002a4:	0f b6 c0             	movzbl %al,%eax
f01002a7:	f7 d0                	not    %eax
f01002a9:	21 c8                	and    %ecx,%eax
f01002ab:	a3 00 13 11 f0       	mov    %eax,0xf0111300
		return 0;
f01002b0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002b5:	eb bc                	jmp    f0100273 <kbd_proc_data+0x95>

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
f01002b7:	83 ea 41             	sub    $0x41,%edx
f01002ba:	83 fa 19             	cmp    $0x19,%edx
f01002bd:	77 a6                	ja     f0100265 <kbd_proc_data+0x87>
			c += 'a' - 'A';
f01002bf:	83 c3 20             	add    $0x20,%ebx
f01002c2:	eb a1                	jmp    f0100265 <kbd_proc_data+0x87>
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
f01002c4:	83 ec 0c             	sub    $0xc,%esp
f01002c7:	68 44 18 10 f0       	push   $0xf0101844
f01002cc:	e8 e8 05 00 00       	call   f01008b9 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d1:	ba 92 00 00 00       	mov    $0x92,%edx
f01002d6:	b0 03                	mov    $0x3,%al
f01002d8:	ee                   	out    %al,(%dx)
f01002d9:	83 c4 10             	add    $0x10,%esp
f01002dc:	eb 95                	jmp    f0100273 <kbd_proc_data+0x95>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002de:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01002e3:	eb 8e                	jmp    f0100273 <kbd_proc_data+0x95>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002e5:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01002ea:	eb 87                	jmp    f0100273 <kbd_proc_data+0x95>

f01002ec <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ec:	55                   	push   %ebp
f01002ed:	89 e5                	mov    %esp,%ebp
f01002ef:	57                   	push   %edi
f01002f0:	56                   	push   %esi
f01002f1:	53                   	push   %ebx
f01002f2:	83 ec 1c             	sub    $0x1c,%esp
f01002f5:	89 c7                	mov    %eax,%edi
f01002f7:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002fc:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100301:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100306:	eb 06                	jmp    f010030e <cons_putc+0x22>
f0100308:	89 ca                	mov    %ecx,%edx
f010030a:	ec                   	in     (%dx),%al
f010030b:	ec                   	in     (%dx),%al
f010030c:	ec                   	in     (%dx),%al
f010030d:	ec                   	in     (%dx),%al
f010030e:	89 f2                	mov    %esi,%edx
f0100310:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100311:	a8 20                	test   $0x20,%al
f0100313:	75 03                	jne    f0100318 <cons_putc+0x2c>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100315:	4b                   	dec    %ebx
f0100316:	75 f0                	jne    f0100308 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100318:	89 f8                	mov    %edi,%eax
f010031a:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100322:	ee                   	out    %al,(%dx)
f0100323:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 06                	jmp    f010033a <cons_putc+0x4e>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	89 f2                	mov    %esi,%edx
f010033c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010033d:	84 c0                	test   %al,%al
f010033f:	78 03                	js     f0100344 <cons_putc+0x58>
f0100341:	4b                   	dec    %ebx
f0100342:	75 f0                	jne    f0100334 <cons_putc+0x48>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100344:	ba 78 03 00 00       	mov    $0x378,%edx
f0100349:	8a 45 e7             	mov    -0x19(%ebp),%al
f010034c:	ee                   	out    %al,(%dx)
f010034d:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100352:	b0 0d                	mov    $0xd,%al
f0100354:	ee                   	out    %al,(%dx)
f0100355:	b0 08                	mov    $0x8,%al
f0100357:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100358:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f010035e:	75 06                	jne    f0100366 <cons_putc+0x7a>
		c |= 0x0700;
f0100360:	81 cf 00 07 00 00    	or     $0x700,%edi

	switch (c & 0xff) {
f0100366:	89 f8                	mov    %edi,%eax
f0100368:	0f b6 c0             	movzbl %al,%eax
f010036b:	83 f8 09             	cmp    $0x9,%eax
f010036e:	0f 84 b1 00 00 00    	je     f0100425 <cons_putc+0x139>
f0100374:	83 f8 09             	cmp    $0x9,%eax
f0100377:	7e 70                	jle    f01003e9 <cons_putc+0xfd>
f0100379:	83 f8 0a             	cmp    $0xa,%eax
f010037c:	0f 84 96 00 00 00    	je     f0100418 <cons_putc+0x12c>
f0100382:	83 f8 0d             	cmp    $0xd,%eax
f0100385:	0f 85 d1 00 00 00    	jne    f010045c <cons_putc+0x170>
		break;
	case '\n':
		crt_pos += CRT_COLS;
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038b:	66 8b 0d 28 15 11 f0 	mov    0xf0111528,%cx
f0100392:	bb 50 00 00 00       	mov    $0x50,%ebx
f0100397:	89 c8                	mov    %ecx,%eax
f0100399:	ba 00 00 00 00       	mov    $0x0,%edx
f010039e:	66 f7 f3             	div    %bx
f01003a1:	29 d1                	sub    %edx,%ecx
f01003a3:	66 89 0d 28 15 11 f0 	mov    %cx,0xf0111528
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003aa:	66 81 3d 28 15 11 f0 	cmpw   $0x7cf,0xf0111528
f01003b1:	cf 07 
f01003b3:	0f 87 c5 00 00 00    	ja     f010047e <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003b9:	8b 0d 30 15 11 f0    	mov    0xf0111530,%ecx
f01003bf:	b0 0e                	mov    $0xe,%al
f01003c1:	89 ca                	mov    %ecx,%edx
f01003c3:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003c4:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003c7:	66 a1 28 15 11 f0    	mov    0xf0111528,%ax
f01003cd:	66 c1 e8 08          	shr    $0x8,%ax
f01003d1:	89 da                	mov    %ebx,%edx
f01003d3:	ee                   	out    %al,(%dx)
f01003d4:	b0 0f                	mov    $0xf,%al
f01003d6:	89 ca                	mov    %ecx,%edx
f01003d8:	ee                   	out    %al,(%dx)
f01003d9:	a0 28 15 11 f0       	mov    0xf0111528,%al
f01003de:	89 da                	mov    %ebx,%edx
f01003e0:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003e1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01003e4:	5b                   	pop    %ebx
f01003e5:	5e                   	pop    %esi
f01003e6:	5f                   	pop    %edi
f01003e7:	5d                   	pop    %ebp
f01003e8:	c3                   	ret    
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
		c |= 0x0700;

	switch (c & 0xff) {
f01003e9:	83 f8 08             	cmp    $0x8,%eax
f01003ec:	75 6e                	jne    f010045c <cons_putc+0x170>
	case '\b':
		if (crt_pos > 0) {
f01003ee:	66 a1 28 15 11 f0    	mov    0xf0111528,%ax
f01003f4:	66 85 c0             	test   %ax,%ax
f01003f7:	74 c0                	je     f01003b9 <cons_putc+0xcd>
			crt_pos--;
f01003f9:	48                   	dec    %eax
f01003fa:	66 a3 28 15 11 f0    	mov    %ax,0xf0111528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100400:	0f b7 c0             	movzwl %ax,%eax
f0100403:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f0100409:	83 cf 20             	or     $0x20,%edi
f010040c:	8b 15 2c 15 11 f0    	mov    0xf011152c,%edx
f0100412:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100416:	eb 92                	jmp    f01003aa <cons_putc+0xbe>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100418:	66 83 05 28 15 11 f0 	addw   $0x50,0xf0111528
f010041f:	50 
f0100420:	e9 66 ff ff ff       	jmp    f010038b <cons_putc+0x9f>
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
		break;
	case '\t':
		cons_putc(' ');
f0100425:	b8 20 00 00 00       	mov    $0x20,%eax
f010042a:	e8 bd fe ff ff       	call   f01002ec <cons_putc>
		cons_putc(' ');
f010042f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100434:	e8 b3 fe ff ff       	call   f01002ec <cons_putc>
		cons_putc(' ');
f0100439:	b8 20 00 00 00       	mov    $0x20,%eax
f010043e:	e8 a9 fe ff ff       	call   f01002ec <cons_putc>
		cons_putc(' ');
f0100443:	b8 20 00 00 00       	mov    $0x20,%eax
f0100448:	e8 9f fe ff ff       	call   f01002ec <cons_putc>
		cons_putc(' ');
f010044d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100452:	e8 95 fe ff ff       	call   f01002ec <cons_putc>
f0100457:	e9 4e ff ff ff       	jmp    f01003aa <cons_putc+0xbe>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010045c:	66 a1 28 15 11 f0    	mov    0xf0111528,%ax
f0100462:	8d 50 01             	lea    0x1(%eax),%edx
f0100465:	66 89 15 28 15 11 f0 	mov    %dx,0xf0111528
f010046c:	0f b7 c0             	movzwl %ax,%eax
f010046f:	8b 15 2c 15 11 f0    	mov    0xf011152c,%edx
f0100475:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100479:	e9 2c ff ff ff       	jmp    f01003aa <cons_putc+0xbe>

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010047e:	a1 2c 15 11 f0       	mov    0xf011152c,%eax
f0100483:	83 ec 04             	sub    $0x4,%esp
f0100486:	68 00 0f 00 00       	push   $0xf00
f010048b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100491:	52                   	push   %edx
f0100492:	50                   	push   %eax
f0100493:	e8 2e 0f 00 00       	call   f01013c6 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100498:	8b 15 2c 15 11 f0    	mov    0xf011152c,%edx
f010049e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004a4:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004aa:	83 c4 10             	add    $0x10,%esp
f01004ad:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004b2:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004b5:	39 d0                	cmp    %edx,%eax
f01004b7:	75 f4                	jne    f01004ad <cons_putc+0x1c1>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b9:	66 83 2d 28 15 11 f0 	subw   $0x50,0xf0111528
f01004c0:	50 
f01004c1:	e9 f3 fe ff ff       	jmp    f01003b9 <cons_putc+0xcd>

f01004c6 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004c6:	80 3d 34 15 11 f0 00 	cmpb   $0x0,0xf0111534
f01004cd:	75 01                	jne    f01004d0 <serial_intr+0xa>
		cons_intr(serial_proc_data);
}
f01004cf:	c3                   	ret    
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d0:	55                   	push   %ebp
f01004d1:	89 e5                	mov    %esp,%ebp
f01004d3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004d6:	b8 7c 01 10 f0       	mov    $0xf010017c,%eax
f01004db:	e8 bb fc ff ff       	call   f010019b <cons_intr>
}
f01004e0:	c9                   	leave  
f01004e1:	eb ec                	jmp    f01004cf <serial_intr+0x9>

f01004e3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e3:	55                   	push   %ebp
f01004e4:	89 e5                	mov    %esp,%ebp
f01004e6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004e9:	b8 de 01 10 f0       	mov    $0xf01001de,%eax
f01004ee:	e8 a8 fc ff ff       	call   f010019b <cons_intr>
}
f01004f3:	c9                   	leave  
f01004f4:	c3                   	ret    

f01004f5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004f5:	55                   	push   %ebp
f01004f6:	89 e5                	mov    %esp,%ebp
f01004f8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004fb:	e8 c6 ff ff ff       	call   f01004c6 <serial_intr>
	kbd_intr();
f0100500:	e8 de ff ff ff       	call   f01004e3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100505:	a1 20 15 11 f0       	mov    0xf0111520,%eax
f010050a:	3b 05 24 15 11 f0    	cmp    0xf0111524,%eax
f0100510:	74 26                	je     f0100538 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100512:	8d 50 01             	lea    0x1(%eax),%edx
f0100515:	89 15 20 15 11 f0    	mov    %edx,0xf0111520
f010051b:	0f b6 80 20 13 11 f0 	movzbl -0xfeeece0(%eax),%eax
		if (cons.rpos == CONSBUFSIZE)
f0100522:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100528:	74 02                	je     f010052c <cons_getc+0x37>
			cons.rpos = 0;
		return c;
	}
	return 0;
}
f010052a:	c9                   	leave  
f010052b:	c3                   	ret    

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f010052c:	c7 05 20 15 11 f0 00 	movl   $0x0,0xf0111520
f0100533:	00 00 00 
f0100536:	eb f2                	jmp    f010052a <cons_getc+0x35>
		return c;
	}
	return 0;
f0100538:	b8 00 00 00 00       	mov    $0x0,%eax
f010053d:	eb eb                	jmp    f010052a <cons_getc+0x35>

f010053f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010053f:	55                   	push   %ebp
f0100540:	89 e5                	mov    %esp,%ebp
f0100542:	56                   	push   %esi
f0100543:	53                   	push   %ebx
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100544:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f010054b:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100552:	5a a5 
	if (*cp != 0xA55A) {
f0100554:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f010055a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010055e:	0f 84 a2 00 00 00    	je     f0100606 <cons_init+0xc7>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100564:	c7 05 30 15 11 f0 b4 	movl   $0x3b4,0xf0111530
f010056b:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010056e:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100573:	b0 0e                	mov    $0xe,%al
f0100575:	8b 15 30 15 11 f0    	mov    0xf0111530,%edx
f010057b:	ee                   	out    %al,(%dx)
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
f010057c:	8d 4a 01             	lea    0x1(%edx),%ecx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057f:	89 ca                	mov    %ecx,%edx
f0100581:	ec                   	in     (%dx),%al
f0100582:	0f b6 c0             	movzbl %al,%eax
f0100585:	c1 e0 08             	shl    $0x8,%eax
f0100588:	89 c3                	mov    %eax,%ebx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010058a:	b0 0f                	mov    $0xf,%al
f010058c:	8b 15 30 15 11 f0    	mov    0xf0111530,%edx
f0100592:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100593:	89 ca                	mov    %ecx,%edx
f0100595:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100596:	89 35 2c 15 11 f0    	mov    %esi,0xf011152c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010059c:	0f b6 c0             	movzbl %al,%eax
f010059f:	09 d8                	or     %ebx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005a1:	66 a3 28 15 11 f0    	mov    %ax,0xf0111528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a7:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005ac:	b0 00                	mov    $0x0,%al
f01005ae:	89 f2                	mov    %esi,%edx
f01005b0:	ee                   	out    %al,(%dx)
f01005b1:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b6:	b0 80                	mov    $0x80,%al
f01005b8:	ee                   	out    %al,(%dx)
f01005b9:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005be:	b0 0c                	mov    $0xc,%al
f01005c0:	89 da                	mov    %ebx,%edx
f01005c2:	ee                   	out    %al,(%dx)
f01005c3:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c8:	b0 00                	mov    $0x0,%al
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005d0:	b0 03                	mov    $0x3,%al
f01005d2:	ee                   	out    %al,(%dx)
f01005d3:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005d8:	b0 00                	mov    $0x0,%al
f01005da:	ee                   	out    %al,(%dx)
f01005db:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005e0:	b0 01                	mov    $0x1,%al
f01005e2:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005e8:	ec                   	in     (%dx),%al
f01005e9:	88 c1                	mov    %al,%cl
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005eb:	3c ff                	cmp    $0xff,%al
f01005ed:	0f 95 05 34 15 11 f0 	setne  0xf0111534
f01005f4:	89 f2                	mov    %esi,%edx
f01005f6:	ec                   	in     (%dx),%al
f01005f7:	89 da                	mov    %ebx,%edx
f01005f9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005fa:	80 f9 ff             	cmp    $0xff,%cl
f01005fd:	74 22                	je     f0100621 <cons_init+0xe2>
		cprintf("Serial port does not exist!\n");
}
f01005ff:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5e                   	pop    %esi
f0100604:	5d                   	pop    %ebp
f0100605:	c3                   	ret    
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100606:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010060d:	c7 05 30 15 11 f0 d4 	movl   $0x3d4,0xf0111530
f0100614:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100617:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f010061c:	e9 52 ff ff ff       	jmp    f0100573 <cons_init+0x34>
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
		cprintf("Serial port does not exist!\n");
f0100621:	83 ec 0c             	sub    $0xc,%esp
f0100624:	68 50 18 10 f0       	push   $0xf0101850
f0100629:	e8 8b 02 00 00       	call   f01008b9 <cprintf>
f010062e:	83 c4 10             	add    $0x10,%esp
}
f0100631:	eb cc                	jmp    f01005ff <cons_init+0xc0>

f0100633 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100633:	55                   	push   %ebp
f0100634:	89 e5                	mov    %esp,%ebp
f0100636:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100639:	8b 45 08             	mov    0x8(%ebp),%eax
f010063c:	e8 ab fc ff ff       	call   f01002ec <cons_putc>
}
f0100641:	c9                   	leave  
f0100642:	c3                   	ret    

f0100643 <getchar>:

int
getchar(void)
{
f0100643:	55                   	push   %ebp
f0100644:	89 e5                	mov    %esp,%ebp
f0100646:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100649:	e8 a7 fe ff ff       	call   f01004f5 <cons_getc>
f010064e:	85 c0                	test   %eax,%eax
f0100650:	74 f7                	je     f0100649 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100652:	c9                   	leave  
f0100653:	c3                   	ret    

f0100654 <iscons>:

int
iscons(int fdnum)
{
f0100654:	55                   	push   %ebp
f0100655:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100657:	b8 01 00 00 00       	mov    $0x1,%eax
f010065c:	5d                   	pop    %ebp
f010065d:	c3                   	ret    
	...

f0100660 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100660:	55                   	push   %ebp
f0100661:	89 e5                	mov    %esp,%ebp
f0100663:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100666:	68 a0 1a 10 f0       	push   $0xf0101aa0
f010066b:	68 be 1a 10 f0       	push   $0xf0101abe
f0100670:	68 c3 1a 10 f0       	push   $0xf0101ac3
f0100675:	e8 3f 02 00 00       	call   f01008b9 <cprintf>
f010067a:	83 c4 0c             	add    $0xc,%esp
f010067d:	68 2c 1b 10 f0       	push   $0xf0101b2c
f0100682:	68 cc 1a 10 f0       	push   $0xf0101acc
f0100687:	68 c3 1a 10 f0       	push   $0xf0101ac3
f010068c:	e8 28 02 00 00       	call   f01008b9 <cprintf>
	return 0;
}
f0100691:	b8 00 00 00 00       	mov    $0x0,%eax
f0100696:	c9                   	leave  
f0100697:	c3                   	ret    

f0100698 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100698:	55                   	push   %ebp
f0100699:	89 e5                	mov    %esp,%ebp
f010069b:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010069e:	68 d5 1a 10 f0       	push   $0xf0101ad5
f01006a3:	e8 11 02 00 00       	call   f01008b9 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a8:	83 c4 08             	add    $0x8,%esp
f01006ab:	68 0c 00 10 00       	push   $0x10000c
f01006b0:	68 54 1b 10 f0       	push   $0xf0101b54
f01006b5:	e8 ff 01 00 00       	call   f01008b9 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006ba:	83 c4 0c             	add    $0xc,%esp
f01006bd:	68 0c 00 10 00       	push   $0x10000c
f01006c2:	68 0c 00 10 f0       	push   $0xf010000c
f01006c7:	68 7c 1b 10 f0       	push   $0xf0101b7c
f01006cc:	e8 e8 01 00 00       	call   f01008b9 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d1:	83 c4 0c             	add    $0xc,%esp
f01006d4:	68 a8 17 10 00       	push   $0x1017a8
f01006d9:	68 a8 17 10 f0       	push   $0xf01017a8
f01006de:	68 a0 1b 10 f0       	push   $0xf0101ba0
f01006e3:	e8 d1 01 00 00       	call   f01008b9 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006e8:	83 c4 0c             	add    $0xc,%esp
f01006eb:	68 00 13 11 00       	push   $0x111300
f01006f0:	68 00 13 11 f0       	push   $0xf0111300
f01006f5:	68 c4 1b 10 f0       	push   $0xf0101bc4
f01006fa:	e8 ba 01 00 00       	call   f01008b9 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ff:	83 c4 0c             	add    $0xc,%esp
f0100702:	68 44 19 11 00       	push   $0x111944
f0100707:	68 44 19 11 f0       	push   $0xf0111944
f010070c:	68 e8 1b 10 f0       	push   $0xf0101be8
f0100711:	e8 a3 01 00 00       	call   f01008b9 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100716:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100719:	b8 43 1d 11 f0       	mov    $0xf0111d43,%eax
f010071e:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100723:	c1 f8 0a             	sar    $0xa,%eax
f0100726:	50                   	push   %eax
f0100727:	68 0c 1c 10 f0       	push   $0xf0101c0c
f010072c:	e8 88 01 00 00       	call   f01008b9 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100731:	b8 00 00 00 00       	mov    $0x0,%eax
f0100736:	c9                   	leave  
f0100737:	c3                   	ret    

f0100738 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100738:	55                   	push   %ebp
f0100739:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010073b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100740:	5d                   	pop    %ebp
f0100741:	c3                   	ret    

f0100742 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100742:	55                   	push   %ebp
f0100743:	89 e5                	mov    %esp,%ebp
f0100745:	57                   	push   %edi
f0100746:	56                   	push   %esi
f0100747:	53                   	push   %ebx
f0100748:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010074b:	68 38 1c 10 f0       	push   $0xf0101c38
f0100750:	e8 64 01 00 00       	call   f01008b9 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100755:	c7 04 24 5c 1c 10 f0 	movl   $0xf0101c5c,(%esp)
f010075c:	e8 58 01 00 00       	call   f01008b9 <cprintf>
f0100761:	83 c4 10             	add    $0x10,%esp
f0100764:	eb 47                	jmp    f01007ad <monitor+0x6b>
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100766:	83 ec 08             	sub    $0x8,%esp
f0100769:	0f be c0             	movsbl %al,%eax
f010076c:	50                   	push   %eax
f010076d:	68 f2 1a 10 f0       	push   $0xf0101af2
f0100772:	e8 cd 0b 00 00       	call   f0101344 <strchr>
f0100777:	83 c4 10             	add    $0x10,%esp
f010077a:	85 c0                	test   %eax,%eax
f010077c:	74 0a                	je     f0100788 <monitor+0x46>
			*buf++ = 0;
f010077e:	c6 03 00             	movb   $0x0,(%ebx)
f0100781:	89 f7                	mov    %esi,%edi
f0100783:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100786:	eb 68                	jmp    f01007f0 <monitor+0xae>
		if (*buf == 0)
f0100788:	80 3b 00             	cmpb   $0x0,(%ebx)
f010078b:	74 6f                	je     f01007fc <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010078d:	83 fe 0f             	cmp    $0xf,%esi
f0100790:	74 09                	je     f010079b <monitor+0x59>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
f0100792:	8d 7e 01             	lea    0x1(%esi),%edi
f0100795:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100799:	eb 37                	jmp    f01007d2 <monitor+0x90>
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010079b:	83 ec 08             	sub    $0x8,%esp
f010079e:	6a 10                	push   $0x10
f01007a0:	68 f7 1a 10 f0       	push   $0xf0101af7
f01007a5:	e8 0f 01 00 00       	call   f01008b9 <cprintf>
f01007aa:	83 c4 10             	add    $0x10,%esp
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f01007ad:	83 ec 0c             	sub    $0xc,%esp
f01007b0:	68 ee 1a 10 f0       	push   $0xf0101aee
f01007b5:	e8 7e 09 00 00       	call   f0101138 <readline>
f01007ba:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007bc:	83 c4 10             	add    $0x10,%esp
f01007bf:	85 c0                	test   %eax,%eax
f01007c1:	74 ea                	je     f01007ad <monitor+0x6b>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007c3:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007ca:	be 00 00 00 00       	mov    $0x0,%esi
f01007cf:	eb 21                	jmp    f01007f2 <monitor+0xb0>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007d1:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007d2:	8a 03                	mov    (%ebx),%al
f01007d4:	84 c0                	test   %al,%al
f01007d6:	74 18                	je     f01007f0 <monitor+0xae>
f01007d8:	83 ec 08             	sub    $0x8,%esp
f01007db:	0f be c0             	movsbl %al,%eax
f01007de:	50                   	push   %eax
f01007df:	68 f2 1a 10 f0       	push   $0xf0101af2
f01007e4:	e8 5b 0b 00 00       	call   f0101344 <strchr>
f01007e9:	83 c4 10             	add    $0x10,%esp
f01007ec:	85 c0                	test   %eax,%eax
f01007ee:	74 e1                	je     f01007d1 <monitor+0x8f>
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007f0:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007f2:	8a 03                	mov    (%ebx),%al
f01007f4:	84 c0                	test   %al,%al
f01007f6:	0f 85 6a ff ff ff    	jne    f0100766 <monitor+0x24>
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;
f01007fc:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100803:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100804:	85 f6                	test   %esi,%esi
f0100806:	74 a5                	je     f01007ad <monitor+0x6b>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100808:	83 ec 08             	sub    $0x8,%esp
f010080b:	68 be 1a 10 f0       	push   $0xf0101abe
f0100810:	ff 75 a8             	pushl  -0x58(%ebp)
f0100813:	e8 d8 0a 00 00       	call   f01012f0 <strcmp>
f0100818:	83 c4 10             	add    $0x10,%esp
f010081b:	85 c0                	test   %eax,%eax
f010081d:	74 34                	je     f0100853 <monitor+0x111>
f010081f:	83 ec 08             	sub    $0x8,%esp
f0100822:	68 cc 1a 10 f0       	push   $0xf0101acc
f0100827:	ff 75 a8             	pushl  -0x58(%ebp)
f010082a:	e8 c1 0a 00 00       	call   f01012f0 <strcmp>
f010082f:	83 c4 10             	add    $0x10,%esp
f0100832:	85 c0                	test   %eax,%eax
f0100834:	74 18                	je     f010084e <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100836:	83 ec 08             	sub    $0x8,%esp
f0100839:	ff 75 a8             	pushl  -0x58(%ebp)
f010083c:	68 14 1b 10 f0       	push   $0xf0101b14
f0100841:	e8 73 00 00 00       	call   f01008b9 <cprintf>
f0100846:	83 c4 10             	add    $0x10,%esp
f0100849:	e9 5f ff ff ff       	jmp    f01007ad <monitor+0x6b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010084e:	b8 01 00 00 00       	mov    $0x1,%eax
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f0100853:	83 ec 04             	sub    $0x4,%esp
f0100856:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100859:	01 d0                	add    %edx,%eax
f010085b:	ff 75 08             	pushl  0x8(%ebp)
f010085e:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100861:	51                   	push   %ecx
f0100862:	56                   	push   %esi
f0100863:	ff 14 85 8c 1c 10 f0 	call   *-0xfefe374(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010086a:	83 c4 10             	add    $0x10,%esp
f010086d:	85 c0                	test   %eax,%eax
f010086f:	0f 89 38 ff ff ff    	jns    f01007ad <monitor+0x6b>
				break;
	}
}
f0100875:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100878:	5b                   	pop    %ebx
f0100879:	5e                   	pop    %esi
f010087a:	5f                   	pop    %edi
f010087b:	5d                   	pop    %ebp
f010087c:	c3                   	ret    
f010087d:	00 00                	add    %al,(%eax)
	...

f0100880 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100880:	55                   	push   %ebp
f0100881:	89 e5                	mov    %esp,%ebp
f0100883:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100886:	ff 75 08             	pushl  0x8(%ebp)
f0100889:	e8 a5 fd ff ff       	call   f0100633 <cputchar>
	*cnt++;
}
f010088e:	83 c4 10             	add    $0x10,%esp
f0100891:	c9                   	leave  
f0100892:	c3                   	ret    

f0100893 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100893:	55                   	push   %ebp
f0100894:	89 e5                	mov    %esp,%ebp
f0100896:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100899:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008a0:	ff 75 0c             	pushl  0xc(%ebp)
f01008a3:	ff 75 08             	pushl  0x8(%ebp)
f01008a6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01008a9:	50                   	push   %eax
f01008aa:	68 80 08 10 f0       	push   $0xf0100880
f01008af:	e8 de 03 00 00       	call   f0100c92 <vprintfmt>
	return cnt;
}
f01008b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008b7:	c9                   	leave  
f01008b8:	c3                   	ret    

f01008b9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01008b9:	55                   	push   %ebp
f01008ba:	89 e5                	mov    %esp,%ebp
f01008bc:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01008bf:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01008c2:	50                   	push   %eax
f01008c3:	ff 75 08             	pushl  0x8(%ebp)
f01008c6:	e8 c8 ff ff ff       	call   f0100893 <vcprintf>
	va_end(ap);

	return cnt;
}
f01008cb:	c9                   	leave  
f01008cc:	c3                   	ret    
f01008cd:	00 00                	add    %al,(%eax)
	...

f01008d0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01008d0:	55                   	push   %ebp
f01008d1:	89 e5                	mov    %esp,%ebp
f01008d3:	57                   	push   %edi
f01008d4:	56                   	push   %esi
f01008d5:	53                   	push   %ebx
f01008d6:	83 ec 14             	sub    $0x14,%esp
f01008d9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01008dc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01008df:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01008e2:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01008e5:	8b 1a                	mov    (%edx),%ebx
f01008e7:	8b 01                	mov    (%ecx),%eax
f01008e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01008ec:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01008f3:	eb 34                	jmp    f0100929 <stab_binsearch+0x59>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01008f5:	48                   	dec    %eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01008f6:	39 c3                	cmp    %eax,%ebx
f01008f8:	7f 2c                	jg     f0100926 <stab_binsearch+0x56>
f01008fa:	0f b6 0a             	movzbl (%edx),%ecx
f01008fd:	83 ea 0c             	sub    $0xc,%edx
f0100900:	39 f9                	cmp    %edi,%ecx
f0100902:	75 f1                	jne    f01008f5 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100904:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100907:	01 c2                	add    %eax,%edx
f0100909:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010090c:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100910:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100913:	76 37                	jbe    f010094c <stab_binsearch+0x7c>
			*region_left = m;
f0100915:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100918:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010091a:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010091d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100924:	eb 03                	jmp    f0100929 <stab_binsearch+0x59>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100926:	8d 5e 01             	lea    0x1(%esi),%ebx
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100929:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010092c:	7f 48                	jg     f0100976 <stab_binsearch+0xa6>
		int true_m = (l + r) / 2, m = true_m;
f010092e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100931:	01 d8                	add    %ebx,%eax
f0100933:	89 c6                	mov    %eax,%esi
f0100935:	c1 ee 1f             	shr    $0x1f,%esi
f0100938:	01 c6                	add    %eax,%esi
f010093a:	d1 fe                	sar    %esi
f010093c:	8d 04 36             	lea    (%esi,%esi,1),%eax
f010093f:	01 f0                	add    %esi,%eax
f0100941:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100944:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100948:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010094a:	eb aa                	jmp    f01008f6 <stab_binsearch+0x26>
		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010094c:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010094f:	73 12                	jae    f0100963 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100951:	48                   	dec    %eax
f0100952:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100955:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100958:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010095a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100961:	eb c6                	jmp    f0100929 <stab_binsearch+0x59>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100963:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100966:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100968:	ff 45 0c             	incl   0xc(%ebp)
f010096b:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010096d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100974:	eb b3                	jmp    f0100929 <stab_binsearch+0x59>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100976:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010097a:	74 18                	je     f0100994 <stab_binsearch+0xc4>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010097c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010097f:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100981:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100984:	8b 0e                	mov    (%esi),%ecx
f0100986:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100989:	01 c2                	add    %eax,%edx
f010098b:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010098e:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100992:	eb 0e                	jmp    f01009a2 <stab_binsearch+0xd2>
			addr++;
		}
	}

	if (!any_matches)
		*region_right = *region_left - 1;
f0100994:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100997:	8b 00                	mov    (%eax),%eax
f0100999:	48                   	dec    %eax
f010099a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010099d:	89 07                	mov    %eax,(%edi)
f010099f:	eb 14                	jmp    f01009b5 <stab_binsearch+0xe5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01009a1:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009a2:	39 c8                	cmp    %ecx,%eax
f01009a4:	7e 0a                	jle    f01009b0 <stab_binsearch+0xe0>
		     l > *region_left && stabs[l].n_type != type;
f01009a6:	0f b6 1a             	movzbl (%edx),%ebx
f01009a9:	83 ea 0c             	sub    $0xc,%edx
f01009ac:	39 df                	cmp    %ebx,%edi
f01009ae:	75 f1                	jne    f01009a1 <stab_binsearch+0xd1>
		     l--)
			/* do nothing */;
		*region_left = l;
f01009b0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01009b3:	89 07                	mov    %eax,(%edi)
	}
}
f01009b5:	83 c4 14             	add    $0x14,%esp
f01009b8:	5b                   	pop    %ebx
f01009b9:	5e                   	pop    %esi
f01009ba:	5f                   	pop    %edi
f01009bb:	5d                   	pop    %ebp
f01009bc:	c3                   	ret    

f01009bd <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01009bd:	55                   	push   %ebp
f01009be:	89 e5                	mov    %esp,%ebp
f01009c0:	57                   	push   %edi
f01009c1:	56                   	push   %esi
f01009c2:	53                   	push   %ebx
f01009c3:	83 ec 1c             	sub    $0x1c,%esp
f01009c6:	8b 7d 08             	mov    0x8(%ebp),%edi
f01009c9:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01009cc:	c7 06 9c 1c 10 f0    	movl   $0xf0101c9c,(%esi)
	info->eip_line = 0;
f01009d2:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01009d9:	c7 46 08 9c 1c 10 f0 	movl   $0xf0101c9c,0x8(%esi)
	info->eip_fn_namelen = 9;
f01009e0:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01009e7:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01009ea:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01009f1:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01009f7:	0f 86 f8 00 00 00    	jbe    f0100af5 <debuginfo_eip+0x138>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01009fd:	b8 4e 6f 10 f0       	mov    $0xf0106f4e,%eax
f0100a02:	3d cd 56 10 f0       	cmp    $0xf01056cd,%eax
f0100a07:	0f 86 73 01 00 00    	jbe    f0100b80 <debuginfo_eip+0x1c3>
f0100a0d:	80 3d 4d 6f 10 f0 00 	cmpb   $0x0,0xf0106f4d
f0100a14:	0f 85 6d 01 00 00    	jne    f0100b87 <debuginfo_eip+0x1ca>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a1a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a21:	ba cc 56 10 f0       	mov    $0xf01056cc,%edx
f0100a26:	81 ea d4 1e 10 f0    	sub    $0xf0101ed4,%edx
f0100a2c:	c1 fa 02             	sar    $0x2,%edx
f0100a2f:	8d 04 92             	lea    (%edx,%edx,4),%eax
f0100a32:	8d 04 82             	lea    (%edx,%eax,4),%eax
f0100a35:	8d 04 82             	lea    (%edx,%eax,4),%eax
f0100a38:	89 c1                	mov    %eax,%ecx
f0100a3a:	c1 e1 08             	shl    $0x8,%ecx
f0100a3d:	01 c8                	add    %ecx,%eax
f0100a3f:	89 c1                	mov    %eax,%ecx
f0100a41:	c1 e1 10             	shl    $0x10,%ecx
f0100a44:	01 c8                	add    %ecx,%eax
f0100a46:	01 c0                	add    %eax,%eax
f0100a48:	8d 44 02 ff          	lea    -0x1(%edx,%eax,1),%eax
f0100a4c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100a4f:	83 ec 08             	sub    $0x8,%esp
f0100a52:	57                   	push   %edi
f0100a53:	6a 64                	push   $0x64
f0100a55:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100a58:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100a5b:	b8 d4 1e 10 f0       	mov    $0xf0101ed4,%eax
f0100a60:	e8 6b fe ff ff       	call   f01008d0 <stab_binsearch>
	if (lfile == 0)
f0100a65:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a68:	83 c4 10             	add    $0x10,%esp
f0100a6b:	85 c0                	test   %eax,%eax
f0100a6d:	0f 84 1b 01 00 00    	je     f0100b8e <debuginfo_eip+0x1d1>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100a73:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100a76:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a79:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100a7c:	83 ec 08             	sub    $0x8,%esp
f0100a7f:	57                   	push   %edi
f0100a80:	6a 24                	push   $0x24
f0100a82:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100a85:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a88:	b8 d4 1e 10 f0       	mov    $0xf0101ed4,%eax
f0100a8d:	e8 3e fe ff ff       	call   f01008d0 <stab_binsearch>

	if (lfun <= rfun) {
f0100a92:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100a95:	83 c4 10             	add    $0x10,%esp
f0100a98:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100a9b:	7f 6c                	jg     f0100b09 <debuginfo_eip+0x14c>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100a9d:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
f0100aa0:	01 d8                	add    %ebx,%eax
f0100aa2:	c1 e0 02             	shl    $0x2,%eax
f0100aa5:	8d 90 d4 1e 10 f0    	lea    -0xfefe12c(%eax),%edx
f0100aab:	8b 88 d4 1e 10 f0    	mov    -0xfefe12c(%eax),%ecx
f0100ab1:	b8 4e 6f 10 f0       	mov    $0xf0106f4e,%eax
f0100ab6:	2d cd 56 10 f0       	sub    $0xf01056cd,%eax
f0100abb:	39 c1                	cmp    %eax,%ecx
f0100abd:	73 09                	jae    f0100ac8 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100abf:	81 c1 cd 56 10 f0    	add    $0xf01056cd,%ecx
f0100ac5:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ac8:	8b 42 08             	mov    0x8(%edx),%eax
f0100acb:	89 46 10             	mov    %eax,0x10(%esi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100ace:	83 ec 08             	sub    $0x8,%esp
f0100ad1:	6a 3a                	push   $0x3a
f0100ad3:	ff 76 08             	pushl  0x8(%esi)
f0100ad6:	e8 86 08 00 00       	call   f0101361 <strfind>
f0100adb:	2b 46 08             	sub    0x8(%esi),%eax
f0100ade:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ae1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ae4:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
f0100ae7:	01 d8                	add    %ebx,%eax
f0100ae9:	8d 04 85 d8 1e 10 f0 	lea    -0xfefe128(,%eax,4),%eax
f0100af0:	83 c4 10             	add    $0x10,%esp
f0100af3:	eb 20                	jmp    f0100b15 <debuginfo_eip+0x158>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100af5:	83 ec 04             	sub    $0x4,%esp
f0100af8:	68 a6 1c 10 f0       	push   $0xf0101ca6
f0100afd:	6a 7f                	push   $0x7f
f0100aff:	68 b3 1c 10 f0       	push   $0xf0101cb3
f0100b04:	e8 dd f5 ff ff       	call   f01000e6 <_panic>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b09:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100b0c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100b0f:	eb bd                	jmp    f0100ace <debuginfo_eip+0x111>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b11:	4b                   	dec    %ebx
f0100b12:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b15:	39 fb                	cmp    %edi,%ebx
f0100b17:	7c 34                	jl     f0100b4d <debuginfo_eip+0x190>
	       && stabs[lline].n_type != N_SOL
f0100b19:	8a 10                	mov    (%eax),%dl
f0100b1b:	80 fa 84             	cmp    $0x84,%dl
f0100b1e:	74 0b                	je     f0100b2b <debuginfo_eip+0x16e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b20:	80 fa 64             	cmp    $0x64,%dl
f0100b23:	75 ec                	jne    f0100b11 <debuginfo_eip+0x154>
f0100b25:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100b29:	74 e6                	je     f0100b11 <debuginfo_eip+0x154>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b2b:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
f0100b2e:	01 c3                	add    %eax,%ebx
f0100b30:	8b 14 9d d4 1e 10 f0 	mov    -0xfefe12c(,%ebx,4),%edx
f0100b37:	b8 4e 6f 10 f0       	mov    $0xf0106f4e,%eax
f0100b3c:	2d cd 56 10 f0       	sub    $0xf01056cd,%eax
f0100b41:	39 c2                	cmp    %eax,%edx
f0100b43:	73 08                	jae    f0100b4d <debuginfo_eip+0x190>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b45:	81 c2 cd 56 10 f0    	add    $0xf01056cd,%edx
f0100b4b:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b4d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b50:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100b53:	39 c8                	cmp    %ecx,%eax
f0100b55:	7d 3e                	jge    f0100b95 <debuginfo_eip+0x1d8>
		for (lline = lfun + 1;
f0100b57:	8d 50 01             	lea    0x1(%eax),%edx
f0100b5a:	8d 1c 00             	lea    (%eax,%eax,1),%ebx
f0100b5d:	01 d8                	add    %ebx,%eax
f0100b5f:	8d 04 85 e4 1e 10 f0 	lea    -0xfefe11c(,%eax,4),%eax
f0100b66:	eb 04                	jmp    f0100b6c <debuginfo_eip+0x1af>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100b68:	ff 46 14             	incl   0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100b6b:	42                   	inc    %edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100b6c:	39 ca                	cmp    %ecx,%edx
f0100b6e:	74 32                	je     f0100ba2 <debuginfo_eip+0x1e5>
f0100b70:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100b73:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100b77:	74 ef                	je     f0100b68 <debuginfo_eip+0x1ab>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b79:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b7e:	eb 1a                	jmp    f0100b9a <debuginfo_eip+0x1dd>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100b80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b85:	eb 13                	jmp    f0100b9a <debuginfo_eip+0x1dd>
f0100b87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b8c:	eb 0c                	jmp    f0100b9a <debuginfo_eip+0x1dd>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100b8e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b93:	eb 05                	jmp    f0100b9a <debuginfo_eip+0x1dd>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b95:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100b9a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100b9d:	5b                   	pop    %ebx
f0100b9e:	5e                   	pop    %esi
f0100b9f:	5f                   	pop    %edi
f0100ba0:	5d                   	pop    %ebp
f0100ba1:	c3                   	ret    
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ba2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ba7:	eb f1                	jmp    f0100b9a <debuginfo_eip+0x1dd>
f0100ba9:	00 00                	add    %al,(%eax)
	...

f0100bac <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100bac:	55                   	push   %ebp
f0100bad:	89 e5                	mov    %esp,%ebp
f0100baf:	57                   	push   %edi
f0100bb0:	56                   	push   %esi
f0100bb1:	53                   	push   %ebx
f0100bb2:	83 ec 1c             	sub    $0x1c,%esp
f0100bb5:	89 c7                	mov    %eax,%edi
f0100bb7:	89 d6                	mov    %edx,%esi
f0100bb9:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bbc:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100bbf:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100bc2:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100bc5:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100bc8:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100bcd:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100bd0:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100bd3:	39 d3                	cmp    %edx,%ebx
f0100bd5:	72 05                	jb     f0100bdc <printnum+0x30>
f0100bd7:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100bda:	77 78                	ja     f0100c54 <printnum+0xa8>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100bdc:	83 ec 0c             	sub    $0xc,%esp
f0100bdf:	ff 75 18             	pushl  0x18(%ebp)
f0100be2:	8b 45 14             	mov    0x14(%ebp),%eax
f0100be5:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100be8:	53                   	push   %ebx
f0100be9:	ff 75 10             	pushl  0x10(%ebp)
f0100bec:	83 ec 08             	sub    $0x8,%esp
f0100bef:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100bf2:	ff 75 e0             	pushl  -0x20(%ebp)
f0100bf5:	ff 75 dc             	pushl  -0x24(%ebp)
f0100bf8:	ff 75 d8             	pushl  -0x28(%ebp)
f0100bfb:	e8 5c 09 00 00       	call   f010155c <__udivdi3>
f0100c00:	83 c4 18             	add    $0x18,%esp
f0100c03:	52                   	push   %edx
f0100c04:	50                   	push   %eax
f0100c05:	89 f2                	mov    %esi,%edx
f0100c07:	89 f8                	mov    %edi,%eax
f0100c09:	e8 9e ff ff ff       	call   f0100bac <printnum>
f0100c0e:	83 c4 20             	add    $0x20,%esp
f0100c11:	eb 11                	jmp    f0100c24 <printnum+0x78>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c13:	83 ec 08             	sub    $0x8,%esp
f0100c16:	56                   	push   %esi
f0100c17:	ff 75 18             	pushl  0x18(%ebp)
f0100c1a:	ff d7                	call   *%edi
f0100c1c:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c1f:	4b                   	dec    %ebx
f0100c20:	85 db                	test   %ebx,%ebx
f0100c22:	7f ef                	jg     f0100c13 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c24:	83 ec 08             	sub    $0x8,%esp
f0100c27:	56                   	push   %esi
f0100c28:	83 ec 04             	sub    $0x4,%esp
f0100c2b:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c2e:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c31:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c34:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c37:	e8 30 0a 00 00       	call   f010166c <__umoddi3>
f0100c3c:	83 c4 14             	add    $0x14,%esp
f0100c3f:	0f be 80 c1 1c 10 f0 	movsbl -0xfefe33f(%eax),%eax
f0100c46:	50                   	push   %eax
f0100c47:	ff d7                	call   *%edi
}
f0100c49:	83 c4 10             	add    $0x10,%esp
f0100c4c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c4f:	5b                   	pop    %ebx
f0100c50:	5e                   	pop    %esi
f0100c51:	5f                   	pop    %edi
f0100c52:	5d                   	pop    %ebp
f0100c53:	c3                   	ret    
f0100c54:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100c57:	eb c6                	jmp    f0100c1f <printnum+0x73>

f0100c59 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100c59:	55                   	push   %ebp
f0100c5a:	89 e5                	mov    %esp,%ebp
f0100c5c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100c5f:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0100c62:	8b 10                	mov    (%eax),%edx
f0100c64:	3b 50 04             	cmp    0x4(%eax),%edx
f0100c67:	73 0a                	jae    f0100c73 <sprintputch+0x1a>
		*b->buf++ = ch;
f0100c69:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100c6c:	89 08                	mov    %ecx,(%eax)
f0100c6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c71:	88 02                	mov    %al,(%edx)
}
f0100c73:	5d                   	pop    %ebp
f0100c74:	c3                   	ret    

f0100c75 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100c75:	55                   	push   %ebp
f0100c76:	89 e5                	mov    %esp,%ebp
f0100c78:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100c7b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100c7e:	50                   	push   %eax
f0100c7f:	ff 75 10             	pushl  0x10(%ebp)
f0100c82:	ff 75 0c             	pushl  0xc(%ebp)
f0100c85:	ff 75 08             	pushl  0x8(%ebp)
f0100c88:	e8 05 00 00 00       	call   f0100c92 <vprintfmt>
	va_end(ap);
}
f0100c8d:	83 c4 10             	add    $0x10,%esp
f0100c90:	c9                   	leave  
f0100c91:	c3                   	ret    

f0100c92 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100c92:	55                   	push   %ebp
f0100c93:	89 e5                	mov    %esp,%ebp
f0100c95:	57                   	push   %edi
f0100c96:	56                   	push   %esi
f0100c97:	53                   	push   %ebx
f0100c98:	83 ec 2c             	sub    $0x2c,%esp
f0100c9b:	8b 75 08             	mov    0x8(%ebp),%esi
f0100c9e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ca1:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100ca4:	e9 79 03 00 00       	jmp    f0101022 <vprintfmt+0x390>
f0100ca9:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100cad:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100cb4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100cbb:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100cc2:	b9 00 00 00 00       	mov    $0x0,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100cc7:	8d 47 01             	lea    0x1(%edi),%eax
f0100cca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ccd:	8a 17                	mov    (%edi),%dl
f0100ccf:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100cd2:	3c 55                	cmp    $0x55,%al
f0100cd4:	0f 87 c9 03 00 00    	ja     f01010a3 <vprintfmt+0x411>
f0100cda:	0f b6 c0             	movzbl %al,%eax
f0100cdd:	ff 24 85 50 1d 10 f0 	jmp    *-0xfefe2b0(,%eax,4)
f0100ce4:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100ce7:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100ceb:	eb da                	jmp    f0100cc7 <vprintfmt+0x35>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ced:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100cf0:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100cf4:	eb d1                	jmp    f0100cc7 <vprintfmt+0x35>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100cf6:	0f b6 d2             	movzbl %dl,%edx
f0100cf9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100cfc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d01:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100d04:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100d07:	01 c0                	add    %eax,%eax
f0100d09:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
				ch = *fmt;
f0100d0d:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100d10:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100d13:	83 f9 09             	cmp    $0x9,%ecx
f0100d16:	77 52                	ja     f0100d6a <vprintfmt+0xd8>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100d18:	47                   	inc    %edi
				precision = precision * 10 + ch - '0';
f0100d19:	eb e9                	jmp    f0100d04 <vprintfmt+0x72>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100d1b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d1e:	8b 00                	mov    (%eax),%eax
f0100d20:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d23:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d26:	8d 40 04             	lea    0x4(%eax),%eax
f0100d29:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d2c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100d2f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100d33:	79 92                	jns    f0100cc7 <vprintfmt+0x35>
				width = precision, precision = -1;
f0100d35:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100d38:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d3b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100d42:	eb 83                	jmp    f0100cc7 <vprintfmt+0x35>
f0100d44:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100d48:	78 08                	js     f0100d52 <vprintfmt+0xc0>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d4a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d4d:	e9 75 ff ff ff       	jmp    f0100cc7 <vprintfmt+0x35>
f0100d52:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100d59:	eb ef                	jmp    f0100d4a <vprintfmt+0xb8>
f0100d5b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100d5e:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100d65:	e9 5d ff ff ff       	jmp    f0100cc7 <vprintfmt+0x35>
f0100d6a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d6d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d70:	eb bd                	jmp    f0100d2f <vprintfmt+0x9d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100d72:	41                   	inc    %ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d73:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100d76:	e9 4c ff ff ff       	jmp    f0100cc7 <vprintfmt+0x35>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100d7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d7e:	8d 78 04             	lea    0x4(%eax),%edi
f0100d81:	83 ec 08             	sub    $0x8,%esp
f0100d84:	53                   	push   %ebx
f0100d85:	ff 30                	pushl  (%eax)
f0100d87:	ff d6                	call   *%esi
			break;
f0100d89:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100d8c:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0100d8f:	e9 8b 02 00 00       	jmp    f010101f <vprintfmt+0x38d>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100d94:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d97:	8d 78 04             	lea    0x4(%eax),%edi
f0100d9a:	8b 00                	mov    (%eax),%eax
f0100d9c:	85 c0                	test   %eax,%eax
f0100d9e:	78 2a                	js     f0100dca <vprintfmt+0x138>
f0100da0:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100da2:	83 f8 06             	cmp    $0x6,%eax
f0100da5:	7f 27                	jg     f0100dce <vprintfmt+0x13c>
f0100da7:	8b 04 85 a8 1e 10 f0 	mov    -0xfefe158(,%eax,4),%eax
f0100dae:	85 c0                	test   %eax,%eax
f0100db0:	74 1c                	je     f0100dce <vprintfmt+0x13c>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0100db2:	50                   	push   %eax
f0100db3:	68 e2 1c 10 f0       	push   $0xf0101ce2
f0100db8:	53                   	push   %ebx
f0100db9:	56                   	push   %esi
f0100dba:	e8 b6 fe ff ff       	call   f0100c75 <printfmt>
f0100dbf:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100dc2:	89 7d 14             	mov    %edi,0x14(%ebp)
f0100dc5:	e9 55 02 00 00       	jmp    f010101f <vprintfmt+0x38d>
f0100dca:	f7 d8                	neg    %eax
f0100dcc:	eb d2                	jmp    f0100da0 <vprintfmt+0x10e>
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100dce:	52                   	push   %edx
f0100dcf:	68 d9 1c 10 f0       	push   $0xf0101cd9
f0100dd4:	53                   	push   %ebx
f0100dd5:	56                   	push   %esi
f0100dd6:	e8 9a fe ff ff       	call   f0100c75 <printfmt>
f0100ddb:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100dde:	89 7d 14             	mov    %edi,0x14(%ebp)
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100de1:	e9 39 02 00 00       	jmp    f010101f <vprintfmt+0x38d>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100de6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100de9:	83 c0 04             	add    $0x4,%eax
f0100dec:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100def:	8b 45 14             	mov    0x14(%ebp),%eax
f0100df2:	8b 38                	mov    (%eax),%edi
f0100df4:	85 ff                	test   %edi,%edi
f0100df6:	74 39                	je     f0100e31 <vprintfmt+0x19f>
				p = "(null)";
			if (width > 0 && padc != '-')
f0100df8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100dfc:	0f 8e a9 00 00 00    	jle    f0100eab <vprintfmt+0x219>
f0100e02:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100e06:	0f 84 a7 00 00 00    	je     f0100eb3 <vprintfmt+0x221>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e0c:	83 ec 08             	sub    $0x8,%esp
f0100e0f:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e12:	57                   	push   %edi
f0100e13:	e8 1e 04 00 00       	call   f0101236 <strnlen>
f0100e18:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e1b:	29 c1                	sub    %eax,%ecx
f0100e1d:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100e20:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100e23:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100e27:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e2a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100e2d:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e2f:	eb 14                	jmp    f0100e45 <vprintfmt+0x1b3>
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
f0100e31:	bf d2 1c 10 f0       	mov    $0xf0101cd2,%edi
f0100e36:	eb c0                	jmp    f0100df8 <vprintfmt+0x166>
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
f0100e38:	83 ec 08             	sub    $0x8,%esp
f0100e3b:	53                   	push   %ebx
f0100e3c:	ff 75 e0             	pushl  -0x20(%ebp)
f0100e3f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e41:	4f                   	dec    %edi
f0100e42:	83 c4 10             	add    $0x10,%esp
f0100e45:	85 ff                	test   %edi,%edi
f0100e47:	7f ef                	jg     f0100e38 <vprintfmt+0x1a6>
f0100e49:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100e4c:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0100e4f:	89 c8                	mov    %ecx,%eax
f0100e51:	85 c9                	test   %ecx,%ecx
f0100e53:	78 10                	js     f0100e65 <vprintfmt+0x1d3>
f0100e55:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0100e58:	29 c1                	sub    %eax,%ecx
f0100e5a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100e5d:	89 75 08             	mov    %esi,0x8(%ebp)
f0100e60:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100e63:	eb 15                	jmp    f0100e7a <vprintfmt+0x1e8>
f0100e65:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e6a:	eb e9                	jmp    f0100e55 <vprintfmt+0x1c3>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
f0100e6c:	83 ec 08             	sub    $0x8,%esp
f0100e6f:	53                   	push   %ebx
f0100e70:	52                   	push   %edx
f0100e71:	ff 55 08             	call   *0x8(%ebp)
f0100e74:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100e77:	ff 4d e0             	decl   -0x20(%ebp)
f0100e7a:	47                   	inc    %edi
f0100e7b:	8a 47 ff             	mov    -0x1(%edi),%al
f0100e7e:	0f be d0             	movsbl %al,%edx
f0100e81:	85 d2                	test   %edx,%edx
f0100e83:	74 59                	je     f0100ede <vprintfmt+0x24c>
f0100e85:	85 f6                	test   %esi,%esi
f0100e87:	78 03                	js     f0100e8c <vprintfmt+0x1fa>
f0100e89:	4e                   	dec    %esi
f0100e8a:	78 2f                	js     f0100ebb <vprintfmt+0x229>
				if (altflag && (ch < ' ' || ch > '~'))
f0100e8c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100e90:	74 da                	je     f0100e6c <vprintfmt+0x1da>
f0100e92:	0f be c0             	movsbl %al,%eax
f0100e95:	83 e8 20             	sub    $0x20,%eax
f0100e98:	83 f8 5e             	cmp    $0x5e,%eax
f0100e9b:	76 cf                	jbe    f0100e6c <vprintfmt+0x1da>
					putch('?', putdat);
f0100e9d:	83 ec 08             	sub    $0x8,%esp
f0100ea0:	53                   	push   %ebx
f0100ea1:	6a 3f                	push   $0x3f
f0100ea3:	ff 55 08             	call   *0x8(%ebp)
f0100ea6:	83 c4 10             	add    $0x10,%esp
f0100ea9:	eb cc                	jmp    f0100e77 <vprintfmt+0x1e5>
f0100eab:	89 75 08             	mov    %esi,0x8(%ebp)
f0100eae:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100eb1:	eb c7                	jmp    f0100e7a <vprintfmt+0x1e8>
f0100eb3:	89 75 08             	mov    %esi,0x8(%ebp)
f0100eb6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100eb9:	eb bf                	jmp    f0100e7a <vprintfmt+0x1e8>
f0100ebb:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ebe:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100ec1:	eb 0c                	jmp    f0100ecf <vprintfmt+0x23d>
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100ec3:	83 ec 08             	sub    $0x8,%esp
f0100ec6:	53                   	push   %ebx
f0100ec7:	6a 20                	push   $0x20
f0100ec9:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100ecb:	4f                   	dec    %edi
f0100ecc:	83 c4 10             	add    $0x10,%esp
f0100ecf:	85 ff                	test   %edi,%edi
f0100ed1:	7f f0                	jg     f0100ec3 <vprintfmt+0x231>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100ed3:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100ed6:	89 45 14             	mov    %eax,0x14(%ebp)
f0100ed9:	e9 41 01 00 00       	jmp    f010101f <vprintfmt+0x38d>
f0100ede:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100ee1:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ee4:	eb e9                	jmp    f0100ecf <vprintfmt+0x23d>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100ee6:	83 f9 01             	cmp    $0x1,%ecx
f0100ee9:	7f 1f                	jg     f0100f0a <vprintfmt+0x278>
		return va_arg(*ap, long long);
	else if (lflag)
f0100eeb:	85 c9                	test   %ecx,%ecx
f0100eed:	75 48                	jne    f0100f37 <vprintfmt+0x2a5>
		return va_arg(*ap, long);
	else
		return va_arg(*ap, int);
f0100eef:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ef2:	8b 00                	mov    (%eax),%eax
f0100ef4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ef7:	89 c1                	mov    %eax,%ecx
f0100ef9:	c1 f9 1f             	sar    $0x1f,%ecx
f0100efc:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100eff:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f02:	8d 40 04             	lea    0x4(%eax),%eax
f0100f05:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f08:	eb 17                	jmp    f0100f21 <vprintfmt+0x28f>
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, long long);
f0100f0a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f0d:	8b 50 04             	mov    0x4(%eax),%edx
f0100f10:	8b 00                	mov    (%eax),%eax
f0100f12:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f15:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100f18:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f1b:	8d 40 08             	lea    0x8(%eax),%eax
f0100f1e:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0100f21:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100f24:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
f0100f27:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f2b:	78 25                	js     f0100f52 <vprintfmt+0x2c0>
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0100f2d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100f32:	e9 ce 00 00 00       	jmp    f0101005 <vprintfmt+0x373>
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, long long);
	else if (lflag)
		return va_arg(*ap, long);
f0100f37:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f3a:	8b 00                	mov    (%eax),%eax
f0100f3c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f3f:	89 c1                	mov    %eax,%ecx
f0100f41:	c1 f9 1f             	sar    $0x1f,%ecx
f0100f44:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100f47:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f4a:	8d 40 04             	lea    0x4(%eax),%eax
f0100f4d:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f50:	eb cf                	jmp    f0100f21 <vprintfmt+0x28f>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f0100f52:	83 ec 08             	sub    $0x8,%esp
f0100f55:	53                   	push   %ebx
f0100f56:	6a 2d                	push   $0x2d
f0100f58:	ff d6                	call   *%esi
				num = -(long long) num;
f0100f5a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100f5d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f60:	f7 da                	neg    %edx
f0100f62:	83 d1 00             	adc    $0x0,%ecx
f0100f65:	f7 d9                	neg    %ecx
f0100f67:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0100f6a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100f6f:	e9 91 00 00 00       	jmp    f0101005 <vprintfmt+0x373>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100f74:	83 f9 01             	cmp    $0x1,%ecx
f0100f77:	7f 1b                	jg     f0100f94 <vprintfmt+0x302>
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0100f79:	85 c9                	test   %ecx,%ecx
f0100f7b:	75 2c                	jne    f0100fa9 <vprintfmt+0x317>
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0100f7d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f80:	8b 10                	mov    (%eax),%edx
f0100f82:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f87:	8d 40 04             	lea    0x4(%eax),%eax
f0100f8a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0100f8d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100f92:	eb 71                	jmp    f0101005 <vprintfmt+0x373>
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
f0100f94:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f97:	8b 10                	mov    (%eax),%edx
f0100f99:	8b 48 04             	mov    0x4(%eax),%ecx
f0100f9c:	8d 40 08             	lea    0x8(%eax),%eax
f0100f9f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0100fa2:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fa7:	eb 5c                	jmp    f0101005 <vprintfmt+0x373>
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
f0100fa9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fac:	8b 10                	mov    (%eax),%edx
f0100fae:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fb3:	8d 40 04             	lea    0x4(%eax),%eax
f0100fb6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0100fb9:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fbe:	eb 45                	jmp    f0101005 <vprintfmt+0x373>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0100fc0:	83 ec 08             	sub    $0x8,%esp
f0100fc3:	53                   	push   %ebx
f0100fc4:	6a 58                	push   $0x58
f0100fc6:	ff d6                	call   *%esi
			putch('X', putdat);
f0100fc8:	83 c4 08             	add    $0x8,%esp
f0100fcb:	53                   	push   %ebx
f0100fcc:	6a 58                	push   $0x58
f0100fce:	ff d6                	call   *%esi
			putch('X', putdat);
f0100fd0:	83 c4 08             	add    $0x8,%esp
f0100fd3:	53                   	push   %ebx
f0100fd4:	6a 58                	push   $0x58
f0100fd6:	ff d6                	call   *%esi
			break;
f0100fd8:	83 c4 10             	add    $0x10,%esp
f0100fdb:	eb 42                	jmp    f010101f <vprintfmt+0x38d>

		// pointer
		case 'p':
			putch('0', putdat);
f0100fdd:	83 ec 08             	sub    $0x8,%esp
f0100fe0:	53                   	push   %ebx
f0100fe1:	6a 30                	push   $0x30
f0100fe3:	ff d6                	call   *%esi
			putch('x', putdat);
f0100fe5:	83 c4 08             	add    $0x8,%esp
f0100fe8:	53                   	push   %ebx
f0100fe9:	6a 78                	push   $0x78
f0100feb:	ff d6                	call   *%esi
			num = (unsigned long long)
f0100fed:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff0:	8b 10                	mov    (%eax),%edx
f0100ff2:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0100ff7:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0100ffa:	8d 40 04             	lea    0x4(%eax),%eax
f0100ffd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101000:	b8 10 00 00 00       	mov    $0x10,%eax
		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101005:	83 ec 0c             	sub    $0xc,%esp
f0101008:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010100c:	57                   	push   %edi
f010100d:	ff 75 e0             	pushl  -0x20(%ebp)
f0101010:	50                   	push   %eax
f0101011:	51                   	push   %ecx
f0101012:	52                   	push   %edx
f0101013:	89 da                	mov    %ebx,%edx
f0101015:	89 f0                	mov    %esi,%eax
f0101017:	e8 90 fb ff ff       	call   f0100bac <printnum>
			break;
f010101c:	83 c4 20             	add    $0x20,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f010101f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101022:	47                   	inc    %edi
f0101023:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101027:	83 f8 25             	cmp    $0x25,%eax
f010102a:	0f 84 79 fc ff ff    	je     f0100ca9 <vprintfmt+0x17>
			if (ch == '\0')
f0101030:	85 c0                	test   %eax,%eax
f0101032:	0f 84 89 00 00 00    	je     f01010c1 <vprintfmt+0x42f>
				return;
			putch(ch, putdat);
f0101038:	83 ec 08             	sub    $0x8,%esp
f010103b:	53                   	push   %ebx
f010103c:	50                   	push   %eax
f010103d:	ff d6                	call   *%esi
f010103f:	83 c4 10             	add    $0x10,%esp
f0101042:	eb de                	jmp    f0101022 <vprintfmt+0x390>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101044:	83 f9 01             	cmp    $0x1,%ecx
f0101047:	7f 1b                	jg     f0101064 <vprintfmt+0x3d2>
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101049:	85 c9                	test   %ecx,%ecx
f010104b:	75 2c                	jne    f0101079 <vprintfmt+0x3e7>
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f010104d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101050:	8b 10                	mov    (%eax),%edx
f0101052:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101057:	8d 40 04             	lea    0x4(%eax),%eax
f010105a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010105d:	b8 10 00 00 00       	mov    $0x10,%eax
f0101062:	eb a1                	jmp    f0101005 <vprintfmt+0x373>
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
f0101064:	8b 45 14             	mov    0x14(%ebp),%eax
f0101067:	8b 10                	mov    (%eax),%edx
f0101069:	8b 48 04             	mov    0x4(%eax),%ecx
f010106c:	8d 40 08             	lea    0x8(%eax),%eax
f010106f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101072:	b8 10 00 00 00       	mov    $0x10,%eax
f0101077:	eb 8c                	jmp    f0101005 <vprintfmt+0x373>
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
f0101079:	8b 45 14             	mov    0x14(%ebp),%eax
f010107c:	8b 10                	mov    (%eax),%edx
f010107e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101083:	8d 40 04             	lea    0x4(%eax),%eax
f0101086:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101089:	b8 10 00 00 00       	mov    $0x10,%eax
f010108e:	e9 72 ff ff ff       	jmp    f0101005 <vprintfmt+0x373>
			printnum(putch, putdat, num, base, width, padc);
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101093:	83 ec 08             	sub    $0x8,%esp
f0101096:	53                   	push   %ebx
f0101097:	6a 25                	push   $0x25
f0101099:	ff d6                	call   *%esi
			break;
f010109b:	83 c4 10             	add    $0x10,%esp
f010109e:	e9 7c ff ff ff       	jmp    f010101f <vprintfmt+0x38d>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01010a3:	83 ec 08             	sub    $0x8,%esp
f01010a6:	53                   	push   %ebx
f01010a7:	6a 25                	push   $0x25
f01010a9:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01010ab:	83 c4 10             	add    $0x10,%esp
f01010ae:	89 f8                	mov    %edi,%eax
f01010b0:	eb 01                	jmp    f01010b3 <vprintfmt+0x421>
f01010b2:	48                   	dec    %eax
f01010b3:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01010b7:	75 f9                	jne    f01010b2 <vprintfmt+0x420>
f01010b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010bc:	e9 5e ff ff ff       	jmp    f010101f <vprintfmt+0x38d>
				/* do nothing */;
			break;
		}
	}
}
f01010c1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010c4:	5b                   	pop    %ebx
f01010c5:	5e                   	pop    %esi
f01010c6:	5f                   	pop    %edi
f01010c7:	5d                   	pop    %ebp
f01010c8:	c3                   	ret    

f01010c9 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01010c9:	55                   	push   %ebp
f01010ca:	89 e5                	mov    %esp,%ebp
f01010cc:	83 ec 18             	sub    $0x18,%esp
f01010cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01010d2:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01010d5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01010d8:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01010dc:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01010df:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01010e6:	85 c0                	test   %eax,%eax
f01010e8:	74 26                	je     f0101110 <vsnprintf+0x47>
f01010ea:	85 d2                	test   %edx,%edx
f01010ec:	7e 29                	jle    f0101117 <vsnprintf+0x4e>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01010ee:	ff 75 14             	pushl  0x14(%ebp)
f01010f1:	ff 75 10             	pushl  0x10(%ebp)
f01010f4:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01010f7:	50                   	push   %eax
f01010f8:	68 59 0c 10 f0       	push   $0xf0100c59
f01010fd:	e8 90 fb ff ff       	call   f0100c92 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101102:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101105:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101108:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010110b:	83 c4 10             	add    $0x10,%esp
}
f010110e:	c9                   	leave  
f010110f:	c3                   	ret    
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101110:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101115:	eb f7                	jmp    f010110e <vsnprintf+0x45>
f0101117:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010111c:	eb f0                	jmp    f010110e <vsnprintf+0x45>

f010111e <snprintf>:
	return b.cnt;
}

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010111e:	55                   	push   %ebp
f010111f:	89 e5                	mov    %esp,%ebp
f0101121:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101124:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101127:	50                   	push   %eax
f0101128:	ff 75 10             	pushl  0x10(%ebp)
f010112b:	ff 75 0c             	pushl  0xc(%ebp)
f010112e:	ff 75 08             	pushl  0x8(%ebp)
f0101131:	e8 93 ff ff ff       	call   f01010c9 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101136:	c9                   	leave  
f0101137:	c3                   	ret    

f0101138 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101138:	55                   	push   %ebp
f0101139:	89 e5                	mov    %esp,%ebp
f010113b:	57                   	push   %edi
f010113c:	56                   	push   %esi
f010113d:	53                   	push   %ebx
f010113e:	83 ec 0c             	sub    $0xc,%esp
f0101141:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101144:	85 c0                	test   %eax,%eax
f0101146:	74 11                	je     f0101159 <readline+0x21>
		cprintf("%s", prompt);
f0101148:	83 ec 08             	sub    $0x8,%esp
f010114b:	50                   	push   %eax
f010114c:	68 e2 1c 10 f0       	push   $0xf0101ce2
f0101151:	e8 63 f7 ff ff       	call   f01008b9 <cprintf>
f0101156:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101159:	83 ec 0c             	sub    $0xc,%esp
f010115c:	6a 00                	push   $0x0
f010115e:	e8 f1 f4 ff ff       	call   f0100654 <iscons>
f0101163:	89 c7                	mov    %eax,%edi
f0101165:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101168:	be 00 00 00 00       	mov    $0x0,%esi
f010116d:	eb 6f                	jmp    f01011de <readline+0xa6>
	echoing = iscons(0);
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f010116f:	83 ec 08             	sub    $0x8,%esp
f0101172:	50                   	push   %eax
f0101173:	68 c4 1e 10 f0       	push   $0xf0101ec4
f0101178:	e8 3c f7 ff ff       	call   f01008b9 <cprintf>
			return NULL;
f010117d:	83 c4 10             	add    $0x10,%esp
f0101180:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101185:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101188:	5b                   	pop    %ebx
f0101189:	5e                   	pop    %esi
f010118a:	5f                   	pop    %edi
f010118b:	5d                   	pop    %ebp
f010118c:	c3                   	ret    
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
			if (echoing)
				cputchar('\b');
f010118d:	83 ec 0c             	sub    $0xc,%esp
f0101190:	6a 08                	push   $0x8
f0101192:	e8 9c f4 ff ff       	call   f0100633 <cputchar>
f0101197:	83 c4 10             	add    $0x10,%esp
f010119a:	eb 41                	jmp    f01011dd <readline+0xa5>
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
f010119c:	83 ec 0c             	sub    $0xc,%esp
f010119f:	53                   	push   %ebx
f01011a0:	e8 8e f4 ff ff       	call   f0100633 <cputchar>
f01011a5:	83 c4 10             	add    $0x10,%esp
f01011a8:	eb 5a                	jmp    f0101204 <readline+0xcc>
			buf[i++] = c;
		} else if (c == '\n' || c == '\r') {
f01011aa:	83 fb 0a             	cmp    $0xa,%ebx
f01011ad:	74 05                	je     f01011b4 <readline+0x7c>
f01011af:	83 fb 0d             	cmp    $0xd,%ebx
f01011b2:	75 2a                	jne    f01011de <readline+0xa6>
			if (echoing)
f01011b4:	85 ff                	test   %edi,%edi
f01011b6:	75 0e                	jne    f01011c6 <readline+0x8e>
				cputchar('\n');
			buf[i] = 0;
f01011b8:	c6 86 40 15 11 f0 00 	movb   $0x0,-0xfeeeac0(%esi)
			return buf;
f01011bf:	b8 40 15 11 f0       	mov    $0xf0111540,%eax
f01011c4:	eb bf                	jmp    f0101185 <readline+0x4d>
			if (echoing)
				cputchar(c);
			buf[i++] = c;
		} else if (c == '\n' || c == '\r') {
			if (echoing)
				cputchar('\n');
f01011c6:	83 ec 0c             	sub    $0xc,%esp
f01011c9:	6a 0a                	push   $0xa
f01011cb:	e8 63 f4 ff ff       	call   f0100633 <cputchar>
f01011d0:	83 c4 10             	add    $0x10,%esp
f01011d3:	eb e3                	jmp    f01011b8 <readline+0x80>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01011d5:	85 f6                	test   %esi,%esi
f01011d7:	7e 3c                	jle    f0101215 <readline+0xdd>
			if (echoing)
f01011d9:	85 ff                	test   %edi,%edi
f01011db:	75 b0                	jne    f010118d <readline+0x55>
				cputchar('\b');
			i--;
f01011dd:	4e                   	dec    %esi
		cprintf("%s", prompt);

	i = 0;
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01011de:	e8 60 f4 ff ff       	call   f0100643 <getchar>
f01011e3:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01011e5:	85 c0                	test   %eax,%eax
f01011e7:	78 86                	js     f010116f <readline+0x37>
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01011e9:	83 f8 08             	cmp    $0x8,%eax
f01011ec:	74 21                	je     f010120f <readline+0xd7>
f01011ee:	83 f8 7f             	cmp    $0x7f,%eax
f01011f1:	74 e2                	je     f01011d5 <readline+0x9d>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f01011f3:	83 f8 1f             	cmp    $0x1f,%eax
f01011f6:	7e b2                	jle    f01011aa <readline+0x72>
f01011f8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01011fe:	7f aa                	jg     f01011aa <readline+0x72>
			if (echoing)
f0101200:	85 ff                	test   %edi,%edi
f0101202:	75 98                	jne    f010119c <readline+0x64>
				cputchar(c);
			buf[i++] = c;
f0101204:	88 9e 40 15 11 f0    	mov    %bl,-0xfeeeac0(%esi)
f010120a:	8d 76 01             	lea    0x1(%esi),%esi
f010120d:	eb cf                	jmp    f01011de <readline+0xa6>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010120f:	85 f6                	test   %esi,%esi
f0101211:	7f c6                	jg     f01011d9 <readline+0xa1>
f0101213:	eb c9                	jmp    f01011de <readline+0xa6>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101215:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010121b:	7e e3                	jle    f0101200 <readline+0xc8>
f010121d:	eb bf                	jmp    f01011de <readline+0xa6>
	...

f0101220 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101220:	55                   	push   %ebp
f0101221:	89 e5                	mov    %esp,%ebp
f0101223:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101226:	b8 00 00 00 00       	mov    $0x0,%eax
f010122b:	eb 01                	jmp    f010122e <strlen+0xe>
		n++;
f010122d:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010122e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101232:	75 f9                	jne    f010122d <strlen+0xd>
		n++;
	return n;
}
f0101234:	5d                   	pop    %ebp
f0101235:	c3                   	ret    

f0101236 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101236:	55                   	push   %ebp
f0101237:	89 e5                	mov    %esp,%ebp
f0101239:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010123c:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010123f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101244:	eb 01                	jmp    f0101247 <strnlen+0x11>
		n++;
f0101246:	40                   	inc    %eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101247:	39 d0                	cmp    %edx,%eax
f0101249:	74 06                	je     f0101251 <strnlen+0x1b>
f010124b:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010124f:	75 f5                	jne    f0101246 <strnlen+0x10>
		n++;
	return n;
}
f0101251:	5d                   	pop    %ebp
f0101252:	c3                   	ret    

f0101253 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101253:	55                   	push   %ebp
f0101254:	89 e5                	mov    %esp,%ebp
f0101256:	53                   	push   %ebx
f0101257:	8b 45 08             	mov    0x8(%ebp),%eax
f010125a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010125d:	89 c2                	mov    %eax,%edx
f010125f:	42                   	inc    %edx
f0101260:	41                   	inc    %ecx
f0101261:	8a 59 ff             	mov    -0x1(%ecx),%bl
f0101264:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101267:	84 db                	test   %bl,%bl
f0101269:	75 f4                	jne    f010125f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010126b:	5b                   	pop    %ebx
f010126c:	5d                   	pop    %ebp
f010126d:	c3                   	ret    

f010126e <strcat>:

char *
strcat(char *dst, const char *src)
{
f010126e:	55                   	push   %ebp
f010126f:	89 e5                	mov    %esp,%ebp
f0101271:	53                   	push   %ebx
f0101272:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101275:	53                   	push   %ebx
f0101276:	e8 a5 ff ff ff       	call   f0101220 <strlen>
f010127b:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010127e:	ff 75 0c             	pushl  0xc(%ebp)
f0101281:	01 d8                	add    %ebx,%eax
f0101283:	50                   	push   %eax
f0101284:	e8 ca ff ff ff       	call   f0101253 <strcpy>
	return dst;
}
f0101289:	89 d8                	mov    %ebx,%eax
f010128b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010128e:	c9                   	leave  
f010128f:	c3                   	ret    

f0101290 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101290:	55                   	push   %ebp
f0101291:	89 e5                	mov    %esp,%ebp
f0101293:	56                   	push   %esi
f0101294:	53                   	push   %ebx
f0101295:	8b 75 08             	mov    0x8(%ebp),%esi
f0101298:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010129b:	89 f3                	mov    %esi,%ebx
f010129d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012a0:	89 f2                	mov    %esi,%edx
f01012a2:	eb 0c                	jmp    f01012b0 <strncpy+0x20>
		*dst++ = *src;
f01012a4:	42                   	inc    %edx
f01012a5:	8a 01                	mov    (%ecx),%al
f01012a7:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01012aa:	80 39 01             	cmpb   $0x1,(%ecx)
f01012ad:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012b0:	39 da                	cmp    %ebx,%edx
f01012b2:	75 f0                	jne    f01012a4 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01012b4:	89 f0                	mov    %esi,%eax
f01012b6:	5b                   	pop    %ebx
f01012b7:	5e                   	pop    %esi
f01012b8:	5d                   	pop    %ebp
f01012b9:	c3                   	ret    

f01012ba <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01012ba:	55                   	push   %ebp
f01012bb:	89 e5                	mov    %esp,%ebp
f01012bd:	56                   	push   %esi
f01012be:	53                   	push   %ebx
f01012bf:	8b 75 08             	mov    0x8(%ebp),%esi
f01012c2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01012c5:	8b 45 10             	mov    0x10(%ebp),%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01012c8:	85 c0                	test   %eax,%eax
f01012ca:	74 20                	je     f01012ec <strlcpy+0x32>
f01012cc:	8d 5c 06 ff          	lea    -0x1(%esi,%eax,1),%ebx
f01012d0:	89 f0                	mov    %esi,%eax
f01012d2:	eb 05                	jmp    f01012d9 <strlcpy+0x1f>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01012d4:	40                   	inc    %eax
f01012d5:	42                   	inc    %edx
f01012d6:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01012d9:	39 d8                	cmp    %ebx,%eax
f01012db:	74 06                	je     f01012e3 <strlcpy+0x29>
f01012dd:	8a 0a                	mov    (%edx),%cl
f01012df:	84 c9                	test   %cl,%cl
f01012e1:	75 f1                	jne    f01012d4 <strlcpy+0x1a>
			*dst++ = *src++;
		*dst = '\0';
f01012e3:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01012e6:	29 f0                	sub    %esi,%eax
}
f01012e8:	5b                   	pop    %ebx
f01012e9:	5e                   	pop    %esi
f01012ea:	5d                   	pop    %ebp
f01012eb:	c3                   	ret    
f01012ec:	89 f0                	mov    %esi,%eax
f01012ee:	eb f6                	jmp    f01012e6 <strlcpy+0x2c>

f01012f0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01012f0:	55                   	push   %ebp
f01012f1:	89 e5                	mov    %esp,%ebp
f01012f3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012f6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01012f9:	eb 02                	jmp    f01012fd <strcmp+0xd>
		p++, q++;
f01012fb:	41                   	inc    %ecx
f01012fc:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01012fd:	8a 01                	mov    (%ecx),%al
f01012ff:	84 c0                	test   %al,%al
f0101301:	74 04                	je     f0101307 <strcmp+0x17>
f0101303:	3a 02                	cmp    (%edx),%al
f0101305:	74 f4                	je     f01012fb <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101307:	0f b6 c0             	movzbl %al,%eax
f010130a:	0f b6 12             	movzbl (%edx),%edx
f010130d:	29 d0                	sub    %edx,%eax
}
f010130f:	5d                   	pop    %ebp
f0101310:	c3                   	ret    

f0101311 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101311:	55                   	push   %ebp
f0101312:	89 e5                	mov    %esp,%ebp
f0101314:	53                   	push   %ebx
f0101315:	8b 45 08             	mov    0x8(%ebp),%eax
f0101318:	8b 55 0c             	mov    0xc(%ebp),%edx
f010131b:	89 c3                	mov    %eax,%ebx
f010131d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101320:	eb 02                	jmp    f0101324 <strncmp+0x13>
		n--, p++, q++;
f0101322:	40                   	inc    %eax
f0101323:	42                   	inc    %edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101324:	39 d8                	cmp    %ebx,%eax
f0101326:	74 15                	je     f010133d <strncmp+0x2c>
f0101328:	8a 08                	mov    (%eax),%cl
f010132a:	84 c9                	test   %cl,%cl
f010132c:	74 04                	je     f0101332 <strncmp+0x21>
f010132e:	3a 0a                	cmp    (%edx),%cl
f0101330:	74 f0                	je     f0101322 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101332:	0f b6 00             	movzbl (%eax),%eax
f0101335:	0f b6 12             	movzbl (%edx),%edx
f0101338:	29 d0                	sub    %edx,%eax
}
f010133a:	5b                   	pop    %ebx
f010133b:	5d                   	pop    %ebp
f010133c:	c3                   	ret    
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010133d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101342:	eb f6                	jmp    f010133a <strncmp+0x29>

f0101344 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101344:	55                   	push   %ebp
f0101345:	89 e5                	mov    %esp,%ebp
f0101347:	8b 45 08             	mov    0x8(%ebp),%eax
f010134a:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010134d:	8a 10                	mov    (%eax),%dl
f010134f:	84 d2                	test   %dl,%dl
f0101351:	74 07                	je     f010135a <strchr+0x16>
		if (*s == c)
f0101353:	38 ca                	cmp    %cl,%dl
f0101355:	74 08                	je     f010135f <strchr+0x1b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101357:	40                   	inc    %eax
f0101358:	eb f3                	jmp    f010134d <strchr+0x9>
		if (*s == c)
			return (char *) s;
	return 0;
f010135a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010135f:	5d                   	pop    %ebp
f0101360:	c3                   	ret    

f0101361 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101361:	55                   	push   %ebp
f0101362:	89 e5                	mov    %esp,%ebp
f0101364:	8b 45 08             	mov    0x8(%ebp),%eax
f0101367:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010136a:	8a 10                	mov    (%eax),%dl
f010136c:	84 d2                	test   %dl,%dl
f010136e:	74 07                	je     f0101377 <strfind+0x16>
		if (*s == c)
f0101370:	38 ca                	cmp    %cl,%dl
f0101372:	74 03                	je     f0101377 <strfind+0x16>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101374:	40                   	inc    %eax
f0101375:	eb f3                	jmp    f010136a <strfind+0x9>
		if (*s == c)
			break;
	return (char *) s;
}
f0101377:	5d                   	pop    %ebp
f0101378:	c3                   	ret    

f0101379 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101379:	55                   	push   %ebp
f010137a:	89 e5                	mov    %esp,%ebp
f010137c:	57                   	push   %edi
f010137d:	56                   	push   %esi
f010137e:	53                   	push   %ebx
f010137f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101382:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101385:	85 c9                	test   %ecx,%ecx
f0101387:	74 13                	je     f010139c <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101389:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010138f:	75 05                	jne    f0101396 <memset+0x1d>
f0101391:	f6 c1 03             	test   $0x3,%cl
f0101394:	74 0d                	je     f01013a3 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101396:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101399:	fc                   	cld    
f010139a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010139c:	89 f8                	mov    %edi,%eax
f010139e:	5b                   	pop    %ebx
f010139f:	5e                   	pop    %esi
f01013a0:	5f                   	pop    %edi
f01013a1:	5d                   	pop    %ebp
f01013a2:	c3                   	ret    
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
f01013a3:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01013a7:	89 d3                	mov    %edx,%ebx
f01013a9:	c1 e3 08             	shl    $0x8,%ebx
f01013ac:	89 d0                	mov    %edx,%eax
f01013ae:	c1 e0 18             	shl    $0x18,%eax
f01013b1:	89 d6                	mov    %edx,%esi
f01013b3:	c1 e6 10             	shl    $0x10,%esi
f01013b6:	09 f0                	or     %esi,%eax
f01013b8:	09 c2                	or     %eax,%edx
f01013ba:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01013bc:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01013bf:	89 d0                	mov    %edx,%eax
f01013c1:	fc                   	cld    
f01013c2:	f3 ab                	rep stos %eax,%es:(%edi)
f01013c4:	eb d6                	jmp    f010139c <memset+0x23>

f01013c6 <memmove>:
	return v;
}

void *
memmove(void *dst, const void *src, size_t n)
{
f01013c6:	55                   	push   %ebp
f01013c7:	89 e5                	mov    %esp,%ebp
f01013c9:	57                   	push   %edi
f01013ca:	56                   	push   %esi
f01013cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ce:	8b 75 0c             	mov    0xc(%ebp),%esi
f01013d1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01013d4:	39 c6                	cmp    %eax,%esi
f01013d6:	73 33                	jae    f010140b <memmove+0x45>
f01013d8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01013db:	39 d0                	cmp    %edx,%eax
f01013dd:	73 2c                	jae    f010140b <memmove+0x45>
		s += n;
		d += n;
f01013df:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01013e2:	89 d6                	mov    %edx,%esi
f01013e4:	09 fe                	or     %edi,%esi
f01013e6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01013ec:	75 13                	jne    f0101401 <memmove+0x3b>
f01013ee:	f6 c1 03             	test   $0x3,%cl
f01013f1:	75 0e                	jne    f0101401 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01013f3:	83 ef 04             	sub    $0x4,%edi
f01013f6:	8d 72 fc             	lea    -0x4(%edx),%esi
f01013f9:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01013fc:	fd                   	std    
f01013fd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01013ff:	eb 07                	jmp    f0101408 <memmove+0x42>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101401:	4f                   	dec    %edi
f0101402:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101405:	fd                   	std    
f0101406:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101408:	fc                   	cld    
f0101409:	eb 13                	jmp    f010141e <memmove+0x58>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010140b:	89 f2                	mov    %esi,%edx
f010140d:	09 c2                	or     %eax,%edx
f010140f:	f6 c2 03             	test   $0x3,%dl
f0101412:	75 05                	jne    f0101419 <memmove+0x53>
f0101414:	f6 c1 03             	test   $0x3,%cl
f0101417:	74 09                	je     f0101422 <memmove+0x5c>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101419:	89 c7                	mov    %eax,%edi
f010141b:	fc                   	cld    
f010141c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010141e:	5e                   	pop    %esi
f010141f:	5f                   	pop    %edi
f0101420:	5d                   	pop    %ebp
f0101421:	c3                   	ret    
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101422:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101425:	89 c7                	mov    %eax,%edi
f0101427:	fc                   	cld    
f0101428:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010142a:	eb f2                	jmp    f010141e <memmove+0x58>

f010142c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010142c:	55                   	push   %ebp
f010142d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010142f:	ff 75 10             	pushl  0x10(%ebp)
f0101432:	ff 75 0c             	pushl  0xc(%ebp)
f0101435:	ff 75 08             	pushl  0x8(%ebp)
f0101438:	e8 89 ff ff ff       	call   f01013c6 <memmove>
}
f010143d:	c9                   	leave  
f010143e:	c3                   	ret    

f010143f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010143f:	55                   	push   %ebp
f0101440:	89 e5                	mov    %esp,%ebp
f0101442:	56                   	push   %esi
f0101443:	53                   	push   %ebx
f0101444:	8b 45 08             	mov    0x8(%ebp),%eax
f0101447:	89 c6                	mov    %eax,%esi
f0101449:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;
f010144c:	8b 55 0c             	mov    0xc(%ebp),%edx

	while (n-- > 0) {
f010144f:	39 f0                	cmp    %esi,%eax
f0101451:	74 16                	je     f0101469 <memcmp+0x2a>
		if (*s1 != *s2)
f0101453:	8a 08                	mov    (%eax),%cl
f0101455:	8a 1a                	mov    (%edx),%bl
f0101457:	38 d9                	cmp    %bl,%cl
f0101459:	75 04                	jne    f010145f <memcmp+0x20>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010145b:	40                   	inc    %eax
f010145c:	42                   	inc    %edx
f010145d:	eb f0                	jmp    f010144f <memcmp+0x10>
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
f010145f:	0f b6 c1             	movzbl %cl,%eax
f0101462:	0f b6 db             	movzbl %bl,%ebx
f0101465:	29 d8                	sub    %ebx,%eax
f0101467:	eb 05                	jmp    f010146e <memcmp+0x2f>
		s1++, s2++;
	}

	return 0;
f0101469:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010146e:	5b                   	pop    %ebx
f010146f:	5e                   	pop    %esi
f0101470:	5d                   	pop    %ebp
f0101471:	c3                   	ret    

f0101472 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101472:	55                   	push   %ebp
f0101473:	89 e5                	mov    %esp,%ebp
f0101475:	8b 45 08             	mov    0x8(%ebp),%eax
f0101478:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010147b:	89 c2                	mov    %eax,%edx
f010147d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101480:	39 d0                	cmp    %edx,%eax
f0101482:	73 07                	jae    f010148b <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101484:	38 08                	cmp    %cl,(%eax)
f0101486:	74 03                	je     f010148b <memfind+0x19>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101488:	40                   	inc    %eax
f0101489:	eb f5                	jmp    f0101480 <memfind+0xe>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010148b:	5d                   	pop    %ebp
f010148c:	c3                   	ret    

f010148d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010148d:	55                   	push   %ebp
f010148e:	89 e5                	mov    %esp,%ebp
f0101490:	57                   	push   %edi
f0101491:	56                   	push   %esi
f0101492:	53                   	push   %ebx
f0101493:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101496:	eb 01                	jmp    f0101499 <strtol+0xc>
		s++;
f0101498:	41                   	inc    %ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101499:	8a 01                	mov    (%ecx),%al
f010149b:	3c 20                	cmp    $0x20,%al
f010149d:	74 f9                	je     f0101498 <strtol+0xb>
f010149f:	3c 09                	cmp    $0x9,%al
f01014a1:	74 f5                	je     f0101498 <strtol+0xb>
		s++;

	// plus/minus sign
	if (*s == '+')
f01014a3:	3c 2b                	cmp    $0x2b,%al
f01014a5:	74 2b                	je     f01014d2 <strtol+0x45>
		s++;
	else if (*s == '-')
f01014a7:	3c 2d                	cmp    $0x2d,%al
f01014a9:	74 2f                	je     f01014da <strtol+0x4d>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01014ab:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01014b0:	f7 45 10 ef ff ff ff 	testl  $0xffffffef,0x10(%ebp)
f01014b7:	75 12                	jne    f01014cb <strtol+0x3e>
f01014b9:	80 39 30             	cmpb   $0x30,(%ecx)
f01014bc:	74 24                	je     f01014e2 <strtol+0x55>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01014be:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01014c2:	75 07                	jne    f01014cb <strtol+0x3e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01014c4:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)
f01014cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01014d0:	eb 4e                	jmp    f0101520 <strtol+0x93>
	while (*s == ' ' || *s == '\t')
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
f01014d2:	41                   	inc    %ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01014d3:	bf 00 00 00 00       	mov    $0x0,%edi
f01014d8:	eb d6                	jmp    f01014b0 <strtol+0x23>

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
		s++, neg = 1;
f01014da:	41                   	inc    %ecx
f01014db:	bf 01 00 00 00       	mov    $0x1,%edi
f01014e0:	eb ce                	jmp    f01014b0 <strtol+0x23>

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01014e2:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01014e6:	74 10                	je     f01014f8 <strtol+0x6b>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01014e8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01014ec:	75 dd                	jne    f01014cb <strtol+0x3e>
		s++, base = 8;
f01014ee:	41                   	inc    %ecx
f01014ef:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f01014f6:	eb d3                	jmp    f01014cb <strtol+0x3e>
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
f01014f8:	83 c1 02             	add    $0x2,%ecx
f01014fb:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f0101502:	eb c7                	jmp    f01014cb <strtol+0x3e>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101504:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101507:	89 f3                	mov    %esi,%ebx
f0101509:	80 fb 19             	cmp    $0x19,%bl
f010150c:	77 24                	ja     f0101532 <strtol+0xa5>
			dig = *s - 'a' + 10;
f010150e:	0f be d2             	movsbl %dl,%edx
f0101511:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101514:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101517:	7d 2b                	jge    f0101544 <strtol+0xb7>
			break;
		s++, val = (val * base) + dig;
f0101519:	41                   	inc    %ecx
f010151a:	0f af 45 10          	imul   0x10(%ebp),%eax
f010151e:	01 d0                	add    %edx,%eax

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101520:	8a 11                	mov    (%ecx),%dl
f0101522:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0101525:	80 fb 09             	cmp    $0x9,%bl
f0101528:	77 da                	ja     f0101504 <strtol+0x77>
			dig = *s - '0';
f010152a:	0f be d2             	movsbl %dl,%edx
f010152d:	83 ea 30             	sub    $0x30,%edx
f0101530:	eb e2                	jmp    f0101514 <strtol+0x87>
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101532:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101535:	89 f3                	mov    %esi,%ebx
f0101537:	80 fb 19             	cmp    $0x19,%bl
f010153a:	77 08                	ja     f0101544 <strtol+0xb7>
			dig = *s - 'A' + 10;
f010153c:	0f be d2             	movsbl %dl,%edx
f010153f:	83 ea 37             	sub    $0x37,%edx
f0101542:	eb d0                	jmp    f0101514 <strtol+0x87>
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101544:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101548:	74 05                	je     f010154f <strtol+0xc2>
		*endptr = (char *) s;
f010154a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010154d:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010154f:	85 ff                	test   %edi,%edi
f0101551:	74 02                	je     f0101555 <strtol+0xc8>
f0101553:	f7 d8                	neg    %eax
}
f0101555:	5b                   	pop    %ebx
f0101556:	5e                   	pop    %esi
f0101557:	5f                   	pop    %edi
f0101558:	5d                   	pop    %ebp
f0101559:	c3                   	ret    
	...

f010155c <__udivdi3>:
f010155c:	55                   	push   %ebp
f010155d:	57                   	push   %edi
f010155e:	56                   	push   %esi
f010155f:	53                   	push   %ebx
f0101560:	83 ec 1c             	sub    $0x1c,%esp
f0101563:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0101567:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f010156b:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010156f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101573:	89 ca                	mov    %ecx,%edx
f0101575:	89 f8                	mov    %edi,%eax
f0101577:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010157b:	85 f6                	test   %esi,%esi
f010157d:	75 2d                	jne    f01015ac <__udivdi3+0x50>
f010157f:	39 cf                	cmp    %ecx,%edi
f0101581:	77 65                	ja     f01015e8 <__udivdi3+0x8c>
f0101583:	89 fd                	mov    %edi,%ebp
f0101585:	85 ff                	test   %edi,%edi
f0101587:	75 0b                	jne    f0101594 <__udivdi3+0x38>
f0101589:	b8 01 00 00 00       	mov    $0x1,%eax
f010158e:	31 d2                	xor    %edx,%edx
f0101590:	f7 f7                	div    %edi
f0101592:	89 c5                	mov    %eax,%ebp
f0101594:	31 d2                	xor    %edx,%edx
f0101596:	89 c8                	mov    %ecx,%eax
f0101598:	f7 f5                	div    %ebp
f010159a:	89 c1                	mov    %eax,%ecx
f010159c:	89 d8                	mov    %ebx,%eax
f010159e:	f7 f5                	div    %ebp
f01015a0:	89 cf                	mov    %ecx,%edi
f01015a2:	89 fa                	mov    %edi,%edx
f01015a4:	83 c4 1c             	add    $0x1c,%esp
f01015a7:	5b                   	pop    %ebx
f01015a8:	5e                   	pop    %esi
f01015a9:	5f                   	pop    %edi
f01015aa:	5d                   	pop    %ebp
f01015ab:	c3                   	ret    
f01015ac:	39 ce                	cmp    %ecx,%esi
f01015ae:	77 28                	ja     f01015d8 <__udivdi3+0x7c>
f01015b0:	0f bd fe             	bsr    %esi,%edi
f01015b3:	83 f7 1f             	xor    $0x1f,%edi
f01015b6:	75 40                	jne    f01015f8 <__udivdi3+0x9c>
f01015b8:	39 ce                	cmp    %ecx,%esi
f01015ba:	72 0a                	jb     f01015c6 <__udivdi3+0x6a>
f01015bc:	3b 44 24 04          	cmp    0x4(%esp),%eax
f01015c0:	0f 87 9e 00 00 00    	ja     f0101664 <__udivdi3+0x108>
f01015c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01015cb:	89 fa                	mov    %edi,%edx
f01015cd:	83 c4 1c             	add    $0x1c,%esp
f01015d0:	5b                   	pop    %ebx
f01015d1:	5e                   	pop    %esi
f01015d2:	5f                   	pop    %edi
f01015d3:	5d                   	pop    %ebp
f01015d4:	c3                   	ret    
f01015d5:	8d 76 00             	lea    0x0(%esi),%esi
f01015d8:	31 ff                	xor    %edi,%edi
f01015da:	31 c0                	xor    %eax,%eax
f01015dc:	89 fa                	mov    %edi,%edx
f01015de:	83 c4 1c             	add    $0x1c,%esp
f01015e1:	5b                   	pop    %ebx
f01015e2:	5e                   	pop    %esi
f01015e3:	5f                   	pop    %edi
f01015e4:	5d                   	pop    %ebp
f01015e5:	c3                   	ret    
f01015e6:	66 90                	xchg   %ax,%ax
f01015e8:	89 d8                	mov    %ebx,%eax
f01015ea:	f7 f7                	div    %edi
f01015ec:	31 ff                	xor    %edi,%edi
f01015ee:	89 fa                	mov    %edi,%edx
f01015f0:	83 c4 1c             	add    $0x1c,%esp
f01015f3:	5b                   	pop    %ebx
f01015f4:	5e                   	pop    %esi
f01015f5:	5f                   	pop    %edi
f01015f6:	5d                   	pop    %ebp
f01015f7:	c3                   	ret    
f01015f8:	bd 20 00 00 00       	mov    $0x20,%ebp
f01015fd:	29 fd                	sub    %edi,%ebp
f01015ff:	89 f9                	mov    %edi,%ecx
f0101601:	d3 e6                	shl    %cl,%esi
f0101603:	89 c3                	mov    %eax,%ebx
f0101605:	89 e9                	mov    %ebp,%ecx
f0101607:	d3 eb                	shr    %cl,%ebx
f0101609:	89 d9                	mov    %ebx,%ecx
f010160b:	09 f1                	or     %esi,%ecx
f010160d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101611:	89 f9                	mov    %edi,%ecx
f0101613:	d3 e0                	shl    %cl,%eax
f0101615:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101619:	89 d6                	mov    %edx,%esi
f010161b:	89 e9                	mov    %ebp,%ecx
f010161d:	d3 ee                	shr    %cl,%esi
f010161f:	89 f9                	mov    %edi,%ecx
f0101621:	d3 e2                	shl    %cl,%edx
f0101623:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101627:	89 e9                	mov    %ebp,%ecx
f0101629:	d3 eb                	shr    %cl,%ebx
f010162b:	09 da                	or     %ebx,%edx
f010162d:	89 d0                	mov    %edx,%eax
f010162f:	89 f2                	mov    %esi,%edx
f0101631:	f7 74 24 08          	divl   0x8(%esp)
f0101635:	89 d6                	mov    %edx,%esi
f0101637:	89 c3                	mov    %eax,%ebx
f0101639:	f7 64 24 0c          	mull   0xc(%esp)
f010163d:	39 d6                	cmp    %edx,%esi
f010163f:	72 17                	jb     f0101658 <__udivdi3+0xfc>
f0101641:	74 09                	je     f010164c <__udivdi3+0xf0>
f0101643:	89 d8                	mov    %ebx,%eax
f0101645:	31 ff                	xor    %edi,%edi
f0101647:	e9 56 ff ff ff       	jmp    f01015a2 <__udivdi3+0x46>
f010164c:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101650:	89 f9                	mov    %edi,%ecx
f0101652:	d3 e2                	shl    %cl,%edx
f0101654:	39 c2                	cmp    %eax,%edx
f0101656:	73 eb                	jae    f0101643 <__udivdi3+0xe7>
f0101658:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010165b:	31 ff                	xor    %edi,%edi
f010165d:	e9 40 ff ff ff       	jmp    f01015a2 <__udivdi3+0x46>
f0101662:	66 90                	xchg   %ax,%ax
f0101664:	31 c0                	xor    %eax,%eax
f0101666:	e9 37 ff ff ff       	jmp    f01015a2 <__udivdi3+0x46>
	...

f010166c <__umoddi3>:
f010166c:	55                   	push   %ebp
f010166d:	57                   	push   %edi
f010166e:	56                   	push   %esi
f010166f:	53                   	push   %ebx
f0101670:	83 ec 1c             	sub    $0x1c,%esp
f0101673:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0101677:	8b 74 24 34          	mov    0x34(%esp),%esi
f010167b:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010167f:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0101683:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101687:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010168b:	89 3c 24             	mov    %edi,(%esp)
f010168e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101692:	89 f2                	mov    %esi,%edx
f0101694:	85 c0                	test   %eax,%eax
f0101696:	75 18                	jne    f01016b0 <__umoddi3+0x44>
f0101698:	39 f7                	cmp    %esi,%edi
f010169a:	0f 86 a0 00 00 00    	jbe    f0101740 <__umoddi3+0xd4>
f01016a0:	89 c8                	mov    %ecx,%eax
f01016a2:	f7 f7                	div    %edi
f01016a4:	89 d0                	mov    %edx,%eax
f01016a6:	31 d2                	xor    %edx,%edx
f01016a8:	83 c4 1c             	add    $0x1c,%esp
f01016ab:	5b                   	pop    %ebx
f01016ac:	5e                   	pop    %esi
f01016ad:	5f                   	pop    %edi
f01016ae:	5d                   	pop    %ebp
f01016af:	c3                   	ret    
f01016b0:	89 f3                	mov    %esi,%ebx
f01016b2:	39 f0                	cmp    %esi,%eax
f01016b4:	0f 87 a6 00 00 00    	ja     f0101760 <__umoddi3+0xf4>
f01016ba:	0f bd e8             	bsr    %eax,%ebp
f01016bd:	83 f5 1f             	xor    $0x1f,%ebp
f01016c0:	0f 84 a6 00 00 00    	je     f010176c <__umoddi3+0x100>
f01016c6:	bf 20 00 00 00       	mov    $0x20,%edi
f01016cb:	29 ef                	sub    %ebp,%edi
f01016cd:	89 e9                	mov    %ebp,%ecx
f01016cf:	d3 e0                	shl    %cl,%eax
f01016d1:	8b 34 24             	mov    (%esp),%esi
f01016d4:	89 f2                	mov    %esi,%edx
f01016d6:	89 f9                	mov    %edi,%ecx
f01016d8:	d3 ea                	shr    %cl,%edx
f01016da:	09 c2                	or     %eax,%edx
f01016dc:	89 14 24             	mov    %edx,(%esp)
f01016df:	89 f2                	mov    %esi,%edx
f01016e1:	89 e9                	mov    %ebp,%ecx
f01016e3:	d3 e2                	shl    %cl,%edx
f01016e5:	89 54 24 04          	mov    %edx,0x4(%esp)
f01016e9:	89 de                	mov    %ebx,%esi
f01016eb:	89 f9                	mov    %edi,%ecx
f01016ed:	d3 ee                	shr    %cl,%esi
f01016ef:	89 e9                	mov    %ebp,%ecx
f01016f1:	d3 e3                	shl    %cl,%ebx
f01016f3:	8b 54 24 08          	mov    0x8(%esp),%edx
f01016f7:	89 d0                	mov    %edx,%eax
f01016f9:	89 f9                	mov    %edi,%ecx
f01016fb:	d3 e8                	shr    %cl,%eax
f01016fd:	09 d8                	or     %ebx,%eax
f01016ff:	89 d3                	mov    %edx,%ebx
f0101701:	89 e9                	mov    %ebp,%ecx
f0101703:	d3 e3                	shl    %cl,%ebx
f0101705:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101709:	89 f2                	mov    %esi,%edx
f010170b:	f7 34 24             	divl   (%esp)
f010170e:	89 d6                	mov    %edx,%esi
f0101710:	f7 64 24 04          	mull   0x4(%esp)
f0101714:	89 c3                	mov    %eax,%ebx
f0101716:	89 d1                	mov    %edx,%ecx
f0101718:	39 d6                	cmp    %edx,%esi
f010171a:	72 7c                	jb     f0101798 <__umoddi3+0x12c>
f010171c:	74 72                	je     f0101790 <__umoddi3+0x124>
f010171e:	8b 54 24 08          	mov    0x8(%esp),%edx
f0101722:	29 da                	sub    %ebx,%edx
f0101724:	19 ce                	sbb    %ecx,%esi
f0101726:	89 f0                	mov    %esi,%eax
f0101728:	89 f9                	mov    %edi,%ecx
f010172a:	d3 e0                	shl    %cl,%eax
f010172c:	89 e9                	mov    %ebp,%ecx
f010172e:	d3 ea                	shr    %cl,%edx
f0101730:	09 d0                	or     %edx,%eax
f0101732:	89 e9                	mov    %ebp,%ecx
f0101734:	d3 ee                	shr    %cl,%esi
f0101736:	89 f2                	mov    %esi,%edx
f0101738:	83 c4 1c             	add    $0x1c,%esp
f010173b:	5b                   	pop    %ebx
f010173c:	5e                   	pop    %esi
f010173d:	5f                   	pop    %edi
f010173e:	5d                   	pop    %ebp
f010173f:	c3                   	ret    
f0101740:	89 fd                	mov    %edi,%ebp
f0101742:	85 ff                	test   %edi,%edi
f0101744:	75 0b                	jne    f0101751 <__umoddi3+0xe5>
f0101746:	b8 01 00 00 00       	mov    $0x1,%eax
f010174b:	31 d2                	xor    %edx,%edx
f010174d:	f7 f7                	div    %edi
f010174f:	89 c5                	mov    %eax,%ebp
f0101751:	89 f0                	mov    %esi,%eax
f0101753:	31 d2                	xor    %edx,%edx
f0101755:	f7 f5                	div    %ebp
f0101757:	89 c8                	mov    %ecx,%eax
f0101759:	f7 f5                	div    %ebp
f010175b:	e9 44 ff ff ff       	jmp    f01016a4 <__umoddi3+0x38>
f0101760:	89 c8                	mov    %ecx,%eax
f0101762:	89 f2                	mov    %esi,%edx
f0101764:	83 c4 1c             	add    $0x1c,%esp
f0101767:	5b                   	pop    %ebx
f0101768:	5e                   	pop    %esi
f0101769:	5f                   	pop    %edi
f010176a:	5d                   	pop    %ebp
f010176b:	c3                   	ret    
f010176c:	39 f0                	cmp    %esi,%eax
f010176e:	72 05                	jb     f0101775 <__umoddi3+0x109>
f0101770:	39 0c 24             	cmp    %ecx,(%esp)
f0101773:	77 0c                	ja     f0101781 <__umoddi3+0x115>
f0101775:	89 f2                	mov    %esi,%edx
f0101777:	29 f9                	sub    %edi,%ecx
f0101779:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f010177d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101781:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101785:	83 c4 1c             	add    $0x1c,%esp
f0101788:	5b                   	pop    %ebx
f0101789:	5e                   	pop    %esi
f010178a:	5f                   	pop    %edi
f010178b:	5d                   	pop    %ebp
f010178c:	c3                   	ret    
f010178d:	8d 76 00             	lea    0x0(%esi),%esi
f0101790:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101794:	73 88                	jae    f010171e <__umoddi3+0xb2>
f0101796:	66 90                	xchg   %ax,%ax
f0101798:	2b 44 24 04          	sub    0x4(%esp),%eax
f010179c:	1b 14 24             	sbb    (%esp),%edx
f010179f:	89 d1                	mov    %edx,%ecx
f01017a1:	89 c3                	mov    %eax,%ebx
f01017a3:	e9 76 ff ff ff       	jmp    f010171e <__umoddi3+0xb2>
