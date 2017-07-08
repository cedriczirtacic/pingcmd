# pingcmd
uses icmp data size to transport data. (pingcmd version C supports icmp6)

## Idea
Came from [jobertabma](https://gist.github.com/jobertabma/e9a383a8ad96baa189b65cdc8d74a845)'s gist about passing the numeric value of ASCII characters through the ICMP data size value. The process is separated in 3:
1. Sniff for ICMP packets of type *echo* (sniff.sh)
2. Send information to server (pingcmd.pl), char-by-char, via the size.
3. Stop and decode the data sizes (decode.sh). Data size 8 is treated a newline.

## Example
1. **Server-side:**
```bash
$ cd server/
$ sudo ./sniff.sh 4 lo output.cap
tcpdump: listening on lo, link-type EN10MB (Ethernet), capture size 262144 bytes
```
*Note: "4" stands for IPv4. Using pingcmd.c supports IPv6.*

2. **Sender-side:**
```bash
$ sudo perl pingcmd.pl -i lo -h localhost
(cmd)$ ls
(cmd)$ id
(cmd)$ exit
$
```
3. **Server-side:**
```bash
^C6 packets captured
12 packets received by filter
0 packets dropped by kernel
$ file output.cap
output.cap: tcpdump capture file (little-endian) - version 2.4 (Ethernet, capture length 262144)
$ ./decode.sh output.cap
ls
id

```

## pingcmd.c
Added a C version just for fun. Use the Makefile to compile (you'll need gcc). **Now supports IPv6!**
