#!/usr/bin/perl -w

use strict;
use warnings;

my $ENCODED_STRING_BEGIN = '"_s_t_a_r_t_';
my $ENCODED_STRING_END =   '_e_n_d_"';

my $dquoted_str = qr/(?<!\\)".*?(?<!\\)"/;

sub decode_str {
  my ($str) = @_;
  $str =~ s{$ENCODED_STRING_BEGIN([0-9A-Fa-f]*)$ENCODED_STRING_END}{pack('H*', $1)}gseo;
  return $str;
}
sub decode_strs {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s{$ENCODED_STRING_BEGIN([0-9A-Fa-f]*)$ENCODED_STRING_END}{pack('H*', $1)}gseo;
}
sub encode_str {
  my ($str) = @_;
  $str =~ s/^"(.*)"$/$1/;
  return $ENCODED_STRING_BEGIN . unpack('H*', $str) . $ENCODED_STRING_END;
}
sub encode_strs {
  my ($filestr_ref) = @_;
  # not-escaped " .*? not-escaped "
  $$filestr_ref =~ s{($dquoted_str)}{&encode_str($1)}gseo;
}
sub newlines {
  my ($str) = @_;
  if ($str =~ m/^"/) {
    $str = '""'; # should be &encode_str($str);
  } else {
    $str =~ s|[^\n]+||gs;
  }
  return $str;
}

undef $/;
my $filestr = <STDIN>;

$filestr =~ s=(//.*?\n|/\*.*?\*/|$dquoted_str)=newlines($1)=egs;
$filestr =~ s=(^\s*\#\s*include\s*)<.+?>=$1<>=gm;
#&encode_strs(\$filestr);
#$filestr =~ s=(\s*\#\s*include\s*)<"(.+?)">=$1<$2>=g;



#&decode_strs(\$filestr);
print $filestr;
