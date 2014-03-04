#!/usr/bin/perl -w

undef $/;

my $k  = qr/[_A-Za-z0-9-]/;
my $wk = qr/[_A-Za-z]$k*[A-Za-z0-9_]/; # dakota identifier
my $ak = qr/::?$k+/;   # absolute scoped dakota identifier
my $rk = qr/$k+$ak*/;  # relative scoped dakota identifier

my $filestr = <STDIN>;

sub strip_to_sig
{
    my ($str, $sig) = @_;

    print "$str __unused static const signature-t* _signature_ = __signature($sig);";
    print "\n";
    return "$str __unused static const signature-t* _signature_ = __signature($sig);";
}

$filestr =~ s/(__method\s+[^(]*?($rk\(object-t self.*?\))\s*\{)/&strip_to_sig($1, $2)/ges;
#print $filestr;
