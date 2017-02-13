#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-
# -*- tab-width: 2
# -*- indent-tabs-mode: nil

# Copyright (C) 2007 - 2017 Robert Nielsen <robert@dakota.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package dakota::rewrite;

use strict;
use warnings;
use sort 'stable';

my $gbl_prefix;
my $nl = "\n";

sub dk_prefix {
  my ($path) = @_;
  $path =~ s|//+|/|;
  $path =~ s|/\./+|/|;
  $path =~ s|^./||;
  if (-d "$path/bin" && -d "$path/lib") {
    return $path
  } elsif ($path =~ s|^(.+?)/+[^/]+$|$1|) {
    return &dk_prefix($path);
  } else {
    die "Could not determine \$prefix from executable path $0: $!\n";
  }
}
BEGIN {
  $gbl_prefix = &dk_prefix($0);
  unshift @INC, "$gbl_prefix/lib";
  use dakota::util;
};
#use Carp; $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
                 convert_dk_to_cc
              );
$main::block = qr{
                   \{
                   (?:
                     (?> [^{}]+ )         # Non-braces without backtracking
                   |
                     (??{ $main::block }) # Group with matching braces
                   )*
                   \}
               }x;

$main::block_in = qr{
                      (?:
                        (?> [^{}]+ )         # Non-braces without backtracking
                      |
                        (??{ $main::block }) # Group with matching braces
                      )*
                  }x;

$main::list = qr{
                  \(
                  (?:
                    (?> [^()]+ )         # Non-parens without backtracking
                  |
                    (??{ $main::list }) # Group with matching parens
                  )*
                  \)
              }x;

$main::list_in = qr{
                     (?:
                       (?> [^()]+ )         # Non-parens without backtracking
                     |
                       (??{ $main::list }) # Group with matching parens
                     )*
                 }x;

$main::seq = qr{
                 \[
                 (?:
                   (?> [^\[\]]+ )         # Non-parens without backtracking
                 |
                   (??{ $main::seq }) # Group with matching parens
                 )*
                 \]
             }x;

my $colon = ':'; # key/item delim only
my $k = qr/[\w-]/;
my $t = qr/[_A-Za-z0-9-\+\/\*()\[\].,: ]/;
my $stmt_boundry = qr/\{|\}|\)|:|;/s;
my ($id,  $mid,  $bid,  $tid,
   $rid, $rmid, $rbid, $rtid, $uint) = &ident_regex();
my $msig_type = &method_sig_type_regex();
my $msig = &method_sig_regex();
my $sqstr = &sqstr_regex();
$main::list_body = qr{
                       (?:
                         (?> [^()]+ )         # Non-parens without backtracking
                       |
                         (??{ $main::list }) # Group with matching parens
                       )*
                   }x;

my $rewrite_compound_literal_names = {
                                      'pair' =>     undef,
                                      'sequence' => undef,
                                      'super' =>    undef,
                                      'vector' =>   undef,
                                     };

my $use_compound_literals = 1;
$use_compound_literals = 0 if $ENV{'DK_NO_COMPOUND_LITERALS'};
sub rewrite_compound_literal {
  my ($filestr_ref) = @_;
  foreach my $name (keys %$rewrite_compound_literal_names) {
    if ($use_compound_literals) {
      $$filestr_ref =~ s|(?<!$k)($name)(\s*)\(($main::list_body)\)|cast($1::slots-t) $2\{$3\}|gx;
    } else {
      $$filestr_ref =~ s|(?<!$k)($name)(\s*)\(($main::list_body)\)|     $1::construct$2 ($3 )|gx;
    }
  }
}
sub rewrite_compound_literal_cstring {
  my ($filestr_ref) = @_;
  my $name = 'cstring';

  if ($use_compound_literals) {
    $$filestr_ref =~ s|(?<!$k)($name)(\s*)\((\".*?\")\)|cast($1::slots-t) $2\{$3, sizeof($3) - 1\}|gx;
  } else {
    $$filestr_ref =~ s|(?<!$k)($name)(\s*)\((\".*?\")\)|     $1::construct$2 ($3, sizeof($3) - 1 )|gx;
  }
}
sub rewrite_compound_literal_cstring_null {
  my ($filestr_ref) = @_;
  my $name = 'cstring';

  if ($use_compound_literals) {
    $$filestr_ref =~ s|($name)-null|cast($1::slots-t) \{nullptr, 0\}|gx;
  } else {
    $$filestr_ref =~ s|($name)-null|     $1::construct (nullptr, 0 )|gx;
  }
}
sub nest_namespaces {
  my ($filestr_ref) = @_;
  my $tbl = {
    'klass' =>     'KLASS-NS',
    'trait' =>     'TRAIT-NS',
    'KLASS-NS' =>  'KLASS-NS',
    'TRAIT-NS' =>  'TRAIT-NS',
    'namespace' => 'namespace',
  };
  foreach my $kind (keys %$tbl) {
    while ($$filestr_ref =~ s/$kind(\s+)(::)?($id)::($rid)(\s*)($main::block)/namespace $3 { $kind$1$4$5$6 }/gs) { # intentionally omitted $2
    }
  }
}
sub rewrite_klass_decl {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s=^     (klass|trait)\s+($rid)\s*;=uc($1) . "($2);"=gemx;
  $$filestr_ref =~ s=^(\s+)(klass|trait)\s+($rid)\s*;=$1 . uc($2) . "($3);"=gemx;
}
sub rewrite_klass_defn {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/^                 (\s*)(klass|trait)(\s+$rid\s*)(\{)/$1 . uc($2) . "-NS" . $3 . $4/gemx;
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)(klass|trait)(\s+$rid\s*)(\{)/$1 . uc($2) . "-NS" . $3 . $4/gemx;
}
sub rewrite_signatures {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(?<!$k)(signature        \s*\(\s*$rid)(\?|\!)   /&rewrite_selsig_replacement($1, $2)/gex;
  $$filestr_ref =~ s/(?<!$k)(signature        \s*\(.*?)(\()          /$1,$2/gx;
  $$filestr_ref =~ s/(?<!$k)(signature        \s*\(\s*$rid)\s*,\s*,  /$1,  /gx; # hackhack

  $$filestr_ref =~ s/(?<!$k)(KW-ARGS-METHOD-SIGNATURE\s*\(\s*$rid)(\?|\!)   /&rewrite_selsig_replacement($1, $2)/gex;
  $$filestr_ref =~ s/(?<!$k)(KW-ARGS-METHOD-SIGNATURE\s*\(\s*$rid)\s*,\s*,  /$1,  /gx; # hackhack
  $$filestr_ref =~ s/(?<!$k)(KW-ARGS-METHOD-SIGNATURE\s*\(.*?)(\()          /$1,$2/gx;

  $$filestr_ref =~ s/(?<!$k)(SLOTS-METHOD-SIGNATURE  \s*\(\s*$rid)(\?|\!)   /&rewrite_selsig_replacement($1, $2)/gex;
  $$filestr_ref =~ s/(?<!$k)(SLOTS-METHOD-SIGNATURE  \s*\(\s*$rid)\s*,\s*,  /$1,  /gx; # hackhack
  $$filestr_ref =~ s/(?<!$k)(SLOTS-METHOD-SIGNATURE  \s*\(.*?)(\()          /$1,$2/gx;
}
sub rewrite_selectors {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(?<!$k)(  GENERIC-FUNC-PTR-PTR\s*\(\s*$rid)(\?|\!) /&rewrite_selsig_replacement($1, $2)/gex;
  $$filestr_ref =~ s/(?<!$k)(  GENERIC-FUNC-PTR-PTR\s*\(\s*$rid)\s*,\s*,/$1,  /gx; # hackhack
  $$filestr_ref =~ s/(?<!$k)(  GENERIC-FUNC-PTR-PTR\s*\(.*?)(\()        /$1,$2/gx;
  ###
  $$filestr_ref =~ s/(?<!$k)(  GENERIC-FUNC-PTR\s*\(\s*$rid)(\?|\!) /&rewrite_selsig_replacement($1, $2)/gex;
  $$filestr_ref =~ s/(?<!$k)(  GENERIC-FUNC-PTR\s*\(\s*$rid)\s*,\s*,/$1,  /gx; # hackhack
  $$filestr_ref =~ s/(?<!$k)(  GENERIC-FUNC-PTR\s*\(.*?)(\()        /$1,$2/gx;
  ###
  $$filestr_ref =~ s/(?<!$k)(  SELECTOR-PTR\s*\(\s*$rid)(\?|\!) /&rewrite_selsig_replacement($1, $2)/gex;
  $$filestr_ref =~ s/(?<!$k)(  SELECTOR-PTR\s*\(\s*$rid)\s*,\s*,/$1,  /gx; # hackhack
  $$filestr_ref =~ s/(?<!$k)(  SELECTOR-PTR\s*\(.*?)(\()        /$1,$2/gx;
  ###
  $$filestr_ref =~ s/(?<!$k)(  selector\s*\(\s*$rid)(\?|\!) /&rewrite_selsig_replacement($1, $2)/gex;
  $$filestr_ref =~ s/(?<!$k)(  selector\s*\(\s*$rid)\s*,\s*,/$1,  /gx; # hackhack
  $$filestr_ref =~ s/(?<!$k)(  selector\s*\(.*?)(\()        /$1,$2/gx;
  ###
  $$filestr_ref =~ s/(?<!$k)(__selector\s*\(\s*$rid)(\?|\!) /&rewrite_selsig_replacement($1, $2)/gex;
  $$filestr_ref =~ s/(?<!$k)(__selector\s*\(\s*$rid)\s*,\s*,/$1,  /gx; # hackhack
  $$filestr_ref =~ s/(?<!$k)(__selector\s*\(.*?)(\()        /$1,$2/gx;
}
sub rewrite_selsig_replacement {
  my ($aa, $bb) = @_;
  my $result = $aa . &encode_char($bb);
  return $result;
}
sub rewrite_declarations {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s|(?<=$stmt_boundry)(\s*)interpose \s+([^;])+\s*;|$1INTERPOSE($2);|gsx;
  $$filestr_ref =~ s|(?<=$stmt_boundry)(\s*)superklass\s+($rid) \s*;|$1SUPERKLASS($2);|gsx;
  $$filestr_ref =~ s|(?<=$stmt_boundry)(\s*)klass     \s+($rid) \s*;|$1KLASS($2);|gsx;
  $$filestr_ref =~ s|(?<=$stmt_boundry)(\s*)trait     \s+($rid) \s*;|$1TRAIT($2);|gsx;
  $$filestr_ref =~ s|(?<=$stmt_boundry)(\s*)traits    \s+($rid(\s*,\s*$rid)*)\s*;|$1TRAIT($2);|gsx;
  $$filestr_ref =~ s|(?<=$stmt_boundry)(\s*)require   \s+($rid) \s*;|$1REQUIRE($2);|gsx;
 #$$filestr_ref =~ s|(?<=$stmt_boundry)(\s*)provide   \s+($rid) \s*;|$1PROVIDE($2);|gsx;
}

my $use_catch_macros = 0;
my $catch_block =  qr/catch\s*\(\s*$rid?::(_klass_|klass\(\))\s*$k*\s*\)\s*($main::block)/;
my $catch_object = qr/\}(\s*$catch_block)+/;
sub rewrite_catch_block {
  my ($str_in) = @_;
  my $str_out = '';

  while (1) {
    if ($str_in =~ m/\Gcatch\s*\(\s*($rid?::(_klass_|klass\(\)))\s*($k*)\s*\)(\s*)\{/gc) {
      if ($use_catch_macros) {
        $str_out .= "DKT-CATCH($1, _exception_)$4\{ object-t $3 = _exception_;";
      } else {
        $str_out .= "else if (\$instance?(_exception_, $1))$4\{ object-t $3 = _exception_;";
      }
    } elsif ($str_in =~ m/\G(.)/gc) {
      $str_out .= $1;
    } elsif ($str_in =~ m/\G(\n)/gc) {
      $str_out .= $1;
    } else {
      last;
    }
  }
  return $str_out;
}
sub rewrite_finally {
  my ($filestr_ref) = @_;
  # hackhack: added extra single space in case $1 is empty
  #$$filestr_ref =~ s/finally(\s*)($main::block);?/finally$1 __finally([&] $2);/gs;

  $$filestr_ref =~ s/finally(\s*)($main::block);?/DKT-FINALLY($2);/gs;
  return $filestr_ref
}
sub rewrite_catch_object {
  my ($str_in) = @_;
  my $str_out = '';

  while (1) {
    if ($str_in =~ m/\G($catch_block)/gc) {
      $str_out .= &rewrite_catch_block($1);
    } elsif ($str_in =~ m/\G(.)/gc) {
      $str_out .= $1;
    } elsif ($str_in =~ m/\G(\n)/gc) {
      $str_out .= $1;
    } else {
      last;
    }
  }
  if ($use_catch_macros) {
    $str_out =~ s/^\}/\} DKT-CATCH-BEGIN(_exception_)/;
    $str_out =~ s/\}$/\} DKT-CATCH-END(_exception_)/;
  } else {
    $str_out =~ s/^\}/\} catch (object-t _exception_) { if (0) {}/;
    $str_out =~ s/\}$/\} else { throw; } }/;
  }
  return $str_out;
}
sub rewrite_exceptions_replacement {
  my ($ws, $block) = @_;
  my $linear_block = $block =~ s/\n/ /gr;
  $linear_block =~ s/\s\s+/ /g;
  my $result = 'else ' . $linear_block . '}' . $ws . 'catch (...) ' . $block;
  return $result;
}
sub rewrite_exceptions {
  my ($filestr_ref) = @_;
  # $ws else { throw ; } }     catch ( ... ) $block
  # =>
  #     else   $block    } $ws catch ( ... ) $block
  $$filestr_ref =~ s/($catch_object)/&rewrite_catch_object($1)/eg;
  $$filestr_ref =~ s/else\s*\{\s*throw\s*;\s*\}\s*\}([ \n]*)catch\s*\(\s*\.\.\.\s*\)\s*($main::block)/&rewrite_exceptions_replacement($1, $2)/egmsx;
}
sub convert_dash_syntax {
  my ($str1, $str2) = @_;
  if (!$ENV{'DK_NO_CONVERT_DASH_SYNTAX'}) {
    $str2 =~ s/-/_/g;
  }
  return "$str1$str2";
}
sub rewrite_syntax {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/($id)(\?)/$1 . &encode_char($2)/ge;
  $$filestr_ref =~ s/($id)(\!)/$1 . &encode_char($2)/ge;

  $$filestr_ref =~ s/([a-zA-Z0-9])(-+)(?=[a-zA-Z0-9])/&convert_dash_syntax($1, $2)/ge;
}
sub vars_from_defn {
  my ($defn, $name, $params, $kw_arg_generics) = @_;
  my $result = '';
  $result .= $defn;

  $params =~ s|\s+| |gs;

  if (0) {
    $result .= "//";
  }

  if (exists $$kw_arg_generics{$name}) { # hackhack
    # replace kw args with va-list-t
    $params =~ s|,[^,]+?/\*$colon.*?\*/||g;
    $params .= ", va-list-t";
    $result .= " static const signature-t* __method__ = KW-ARGS-METHOD-SIGNATURE(va::$name,($params)); USE(__method__);";
  } else {
    $result .= " static const signature-t* __method__ = signature($name,($params)); USE(__method__);";
  }
  return $result;
}
sub rewrite_methods {
  my ($filestr_ref, $kw_arg_generics) = @_;
  $$filestr_ref =~ s/((\[\[.+?\]\])?\s*method\s+($rmid)\((object-t self.*?)\)\s*->\s*([^(;|\{)]+?)\s*\{)/&vars_from_defn($1, $3, $4, $kw_arg_generics)/ges;
  $$filestr_ref =~ s|(?<=$stmt_boundry)(\s*)\[\[alias\((.+?)\)\]\](\s*)method(\s+)|$1ALIAS($2)$3METHOD$4|gs;
  $$filestr_ref =~ s|(?<=$stmt_boundry)(\s*)(\s*(\[\[.+?\]\])*)(\s*)method(\s+)($id)|$1$2$4METHOD$5$6|gs; #hackhack
  $$filestr_ref =~ s|(?<=$stmt_boundry)(\s*)method(\s+)($id)|$1METHOD$2$3|gs; #hackhack

  $$filestr_ref =~ s/klass method/klass_method/gs;           #hackhack
  $$filestr_ref =~ s/namespace method/namespace_method/gs;   #hackhack

  #$$filestr_ref =~ s|(?<!\[\[export\]\])(\s+)(method)(\s*)|$1METHOD$3 |gm;

  $$filestr_ref =~ s/klass_method/klass method/gs;           #hackhack
  $$filestr_ref =~ s/namespace_method/namespace method/gs;   #hackhack
}
sub arglist_members {
  my ($arglist, $i) = @_;
  my $result = [];
  my $tkn = '';
  my $is_bracketed = 0;
  my $chars = [split(//, $arglist)];
  if (!$i) { $i = 0; }
  #print STDERR scalar @$chars . $nl;

  while (scalar @$chars > $i) {
    if (!$is_bracketed) {
      if (',' eq $$chars[$i]) {
        &add_last($result, $tkn); $tkn = '';
        $i++; # eat comma
        while ($$chars[$i] =~ m/(\s|\n)/) { $i++; } # eat whitespace
      } elsif (')' eq $$chars[$i]) {
        print STDERR "warning: &arglist_members() argument unbalenced: close token at offset $i\n";
        last;
      }
    }
    if ($$chars[$i] =~ m/\{|\(/) {
      $is_bracketed++;
    } elsif ($$chars[$i] =~ m/\)|\}/ && $is_bracketed) {
      $is_bracketed--;
    }
    $tkn .= $$chars[$i];
    $i++;
  }
  if ($tkn) {
    &add_last($result, $tkn);
  }
  return [ $i , $result ];
}
sub rewrite_throws {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)throw((\s|\().+?);/$1\{ dkt-throw-src = \{ __FILE__, __LINE__ \}; THROW$2; \}/gsx;
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)throw(\s*);       /$1\{ dkt-throw-src = \{ __FILE__, __LINE__ \}; THROW$2; \}/gsx;
}
sub rewrite_slots_typealias {
  my ($ws1, $ws2, $tkns, $ws3) = @_;
  return "${ws1}typealias slots-t =$ws2$tkns$ws3;";
}
sub rewrite_slots {
  my ($filestr_ref) = @_;
  #$$filestr_ref =~ s{(import|export|noexport)(\s+)(slots\s+)}{/*$1*/$2$3}g;
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)slots(\s+)(struct|union)(            \s*$main::block)/$1$3$2\[\[dkt-typeinfo\]\] slots-t$4;/gsx;
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)slots(\s+)(struct|union)(\s*);                       /$1$3$2\[\[dkt-typeinfo\]\] slots-t$4;/gsx;
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)slots(\s+)(type-enum)   (\s*:\s*$rtid\s*$main::block)/$1enum struct$2\[\[dkt-typeinfo\]\] slots-t$4;/gsx;
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)slots(\s+)(type-enum)   (\s*:\s*$rtid\s*);           /$1enum struct$2\[\[dkt-typeinfo\]\] slots-t$4;/gsx; # forward decl
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)slots(\s+)(type-enum)   (\s*$main::block)            /$1enum struct$2\[\[dkt-typeinfo\]\] slots-t$4;/gsx;
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)slots(\s+)(type-enum)   (\s*);                       /$1enum struct$2\[\[dkt-typeinfo\]\] slots-t$4;/gsx; # forward decl
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)slots(\s+)(enum)        (\s*:\s*$rtid\s*$main::block)/$1$3$2\[\[dkt-typeinfo\]\] slots-t$4;/gsx;
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)slots(\s+)(enum)        (\s*:\s*$rtid\s*);           /$1$3$2\[\[dkt-typeinfo\]\] slots-t$4;/gsx; # forward decl
 #$$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)slots(\s+)func(\s|\()/$1slots$2$3/gsx; # lose 'func' when preceeded by 'slots'
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)slots(\s+)(\w+.*?)(\s*);/&rewrite_slots_typealias($1, $2, $3, $4)/egs;
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*)slots(\s*\(\s*\*\s*\)\s*$main::list\s*->\s*.+?);/$1typealias slots-t = func$2;/gs;
}
sub rewrite_set_literal {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/\#\{(.*?)\}/&rewrite_set_literal_both_replacement($1)/ge;
}
sub rewrite_set_literal_both_replacement {
  my ($body) = @_;
  if ($body =~ m|(?<!$colon)$colon(?!$colon)|) {
    return &rewrite_table_literal_replacement($body);
  } else {
    return &rewrite_list_literal_replacement($body, 'SET');
  }
}
sub trim {
  my ($str) = @_;
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  return $str;
}
sub rewrite_objects_replacement {
  my ($block_in) = @_;
  my $result = "#objects$colon cast(object-t[]){";
  my $objects = [split(/\s*,\s*/, $block_in)]; # bugbug: this will fail if a pointer to a func with two or more args
  foreach my $item (@$objects) {
    $item = &trim($item);
    if ($item =~ m/^\#/ || $item =~ m/^__symbol::/) {
      $result .= " symbol::box($item),";
    } elsif ($item =~ m/^\"/) {
      $result .= " str::box($item),";
    } else {
      $result .= " box($item),";
    }
  }
  $result .= ' nullptr }';
  return $result;
}
sub rewrite_objects {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/\#objects\s*$colon\s*\{($main::block_in)\}/&rewrite_objects_replacement($1)/egs;
}
sub rewrite_table_literal_replacement {
  my ($body) = @_;
  my $result = '';
  $result .= "\$make(DEFAULT-TABLE-KLASS";
  my $pairs = [split /,/, $body];

  if (0 != @$pairs && '' ne $$pairs[0]) {
    $result .= ", #objects$colon cast(object-t[]){ ";
    foreach my $pair (@$pairs) {
      my ($first, $last) = split /(?<!$colon)$colon(?!$colon)/, $pair;
      $first = &trim($first);
      $last = &trim($last);
      if ($first && $last) {
      #print STDERR "first=$first, last=$last\n";

      # first
      if ($first =~ m/^\#/ || $first =~ m/^__symbol::/) {
        $result .= "pair::box({symbol::box($first), ";
      } elsif ($first =~ m/^\"/) {
        $result .= "pair::box({str::box($first), ";
      } else {
        $result .= "pair::box({box($first), ";
      }

      # last
      if ($last =~ m/^\#/ || $last =~ m/^__symbol::/) {
        $result .= "symbol::box($last)}), ";
      } elsif ($last =~ m/^\"/) {
        $result .= "str::box($last)}), ";
      } else {
        $result .= "box($last)}), ";
      }
      }
    }
    $result .= "nullptr }";
  }
  $result .= ", nullptr)";
  return $result;
}
sub rewrite_sequence_literal {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/\#\[(.*?)\]/&rewrite_list_literal_replacement($1, 'SEQUENCE')/ge;
}
sub rewrite_list_literal_replacement {
  my ($body, $type) = @_;
  my $result = '';
  $result .= "\$make(DEFAULT-$type-KLASS";
  my $pairs = [split /,/, $body];
  $pairs = [map {&trim($_)} @$pairs];

  if (0 != @$pairs && '' ne $$pairs[0]) {
    $result .= ", #objects$colon cast(object-t[]){ ";

    foreach my $pair (@$pairs) {
      $result .= "box($pair), ";
    }
    $result .= "nullptr }";
  }
  $result .= ", nullptr)";
  return $result;
}
sub rewrite_enums {
  # does not deal with comments containing '{' or '}' between the { }
  my ($filestr_ref) = @_;
  #$$filestr_ref =~ s{(?<!/\*)(import|export|noexport)(\s+)(enum[^\w-])}{/*$1*/$2$3}g;
  $$filestr_ref =~ s/(?<!slots)(\s+enum(\s+$id)?\s*$main::block)/$1;/gs;
}
sub rewrite_const {
  # does not deal with comments containing '{' or '}' between the { }
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s|\b\[\[export\]\](\s+const.*?;)|/*\[\[export\]\]*/$1|g;
}
sub rewrite_array_types {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/($tid)(\s*)($main::seq)(\s*)($mid)/$1$2$4$5$3/gm;
  $$filestr_ref =~ s/(\[\])(\s*)($mid)(\s*=)/$2$3$1$4/gm;
}
sub symbol {
  my ($symbol) = @_;
  my $ident = &dk_mangle($symbol);
  return "__symbol::$ident";
}
sub rewrite_symbols {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/\#($mid)/&symbol($1)/ge;
  $$filestr_ref =~ s/\#\|(.*?(?<!\\))\|/&symbol($1)/ge;
}
sub literal_str {
  my ($string) = @_;
  my $ident = &dk_mangle($string);
  return "__literal::__str::$ident";
}
sub rewrite_literal_strs {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(\#"(.*?)")/&literal_str($2)/ge;
}
sub literal_int {
  my ($val) = @_;
  my $ident = &dk_mangle($val);
  return "__literal::__int::$ident";
}
sub rewrite_literal_ints {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(#($uint))/&literal_int($2)/ge;
  # '' multibyte char
}
# 'a'
# '\\'
# '\''
# '\0'
sub literal_char {
  my ($val) = @_;
  $val =~ s|^\'||;  # strip leading  single-quote
  $val =~ s|\'$||;  # strip trailing single-quote
  my $ident = &dk_mangle($val);
  return "__literal::__char::$ident";
}
sub rewrite_literal_chars {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(?<!\\)\#($sqstr)/&literal_char($1)/ge;
}
sub rewrite_literal_booles {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(\#(false|true))\b/__literal::__boole::_$2_/g;
}
sub rewrite_boxes {
  my ($filestr_ref) = @_;
  # #[   as(size)   3,   as(uint64)   5 ]
  # or
  # #[ cast(size-t) 3, cast(uint64-t) 5 ]

  #$$filestr_ref =~ s/(?<!::)box\(\s*as\s*\(($rid)\)\s*(.+?)\s*\)/$1::box($1::construct($2))/g;

  if ($use_compound_literals) {
    $$filestr_ref =~ s/($id)::box\((\s*\{.*?\}\s*)\)/$1::box(cast($1::slots-t)$2)/g;
  } else {
    $$filestr_ref =~ s/($id)::box\(\s*\{(.*?)\}\s*\)/$1::box($1::construct($2))/g;
  }
  # <non-colon>box($foo)  =>  symbol::box($foo)
  $$filestr_ref =~ s/(?<!::)(box\s*\(\s*\#$id        \))/symbol::$1/g;
  $$filestr_ref =~ s/(?<!::)(box\s*\(\s*__symbol::.+?\))/symbol::$1/g;

  # box(cast(ssize-t)0)  =>  ssize::box(cast(ssize-t)0)
  $$filestr_ref =~ s/(?<!::)(box\s*\(\s*cast\s*\(\s*(.+?)-t\s*\))/$2::$1/g;
}
sub rewrite_unless {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(\Wunless)\s+\(/$1(/g;
}
sub rewrite_unboxes_replacement {
  my ($type_eq, $name, $func) = @_;
  my $result = "$type_eq$func";

  if ('object' ne $name && 'slots' ne $name) {
    $result = "$type_eq$name\::$func";
  }
  return $result;
}
sub rewrite_unboxes {
  my ($filestr_ref) = @_;
  # foo::slots-t* foo = unbox(bar)
  # becomes
  # foo::slots-t* foo = foo::unbox(bar)
  $$filestr_ref =~ s/(($id)::slots-t\s*\*?\s*$id\s*=\s*\*?)(unbox)(?=\()/&rewrite_unboxes_replacement($1, $2, $3)/ge;

  # foo::slots-t& foo = *unbox(bar)
  # becomes
  # foo::slots-t& foo = *foo::unbox(bar)
  $$filestr_ref =~ s/(($id)::slots-t\s*\&?\s*$id\s*=\s*\*?)(unbox)(?=\()/&rewrite_unboxes_replacement($1, $2, $3)/ge;

  # foo-t* foo = unbox(bar)
  # becomes
  # foo-t* foo = foo::unbox(bar)
  #$$filestr_ref =~ s/(($k+?)-t\s*\*?\s*$id\s*=\s*\*?)(unbox)(?=\()/&rewrite_unboxes_replacement($1, $2, $3)/ge;

  # foo-t& foo = *unbox(bar)
  # becomes
  # foo-t& foo = *foo::unbox(bar)
  #$$filestr_ref =~ s/(($k+?)-t\s*\&?\s*$id\s*=\s*\*?)(unbox)(?=\()/&rewrite_unboxes_replacement($1, $2, $3)/ge;
}
sub rewrite_creates {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/($id)::create\((\s*\{.*?\}\s*)\)/$1::create(($1::slots-t)$2)/g;
}
sub rewrite_supers_in_klass {
  my ($type, $name, $block) = @_;
  $block =~ s/(\$va::$mid|\$$mid)\s*\(\s*super\b(?!\()/$1(super(self, _klass_)/g; # klass()
  return $type . ' ' . $name . ' ' . $block;
}
sub rewrite_supers_in_trait {
  my ($type, $name, $block) = @_;
  $block =~ s/(\$va::$mid|\$$mid)\s*\(\s*super\b(?!\()/$1(super(self, klass(self))/g;
  return $type . ' ' . $name . ' ' . $block;
}
sub rewrite_supers {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/\b(klass)\s+($rid)\s*(.*?$main::block)/&rewrite_supers_in_klass($1, $2, $3)/egs;
  $$filestr_ref =~ s/\b(trait)\s+($rid)\s*(.*?$main::block)/&rewrite_supers_in_trait($1, $2, $3)/egs;
}
#sub rewrite_makes
#{
#    my ($filestr_ref) = @_;
#    ## regex should be (:)?(\w+:)*\w+ ?
#    $$filestr_ref =~ s/make\(([_a-z0-9:-]+)/\$init(\$alloc($1)/g;
#}
my $dir2method_name = {
  'forward'  => 'forward-iterator-context',
  'backward' => 'backward-iterator-context',
};
sub rewrite_for_in_replacement {
  my ($dir, $type, $item, $sequence, $ws1, $open_brace, $ws2, $stmt, $ws3) = @_;
  $dir = 'forward' if !$dir;
  my $method_name = $$dir2method_name{$dir};
  my $first_stmt = '';
  my $result = "for (iterator-context-t _context = \$$method_name($sequence);";

  if ('object-t' eq $type) {
    $result .= " object-t $item = _context.next(_context.iter);";
    $result .= " /**/)";
    if (!$open_brace) { # $ws2 will be undefined
      $first_stmt .= "$ws1$stmt$ws3";
    } else {
      $first_stmt .= "$ws1\{$ws2$stmt$ws3";
    }
  } elsif ('slots-t*' eq $type) {
    $result .= " object-t $item = _context.next(_context.iter);";
    $result .= " /**/)";

    if (!$open_brace) { # $ws2 will be undefined
      $first_stmt .= "$ws1\{ $type $item = mutable-unbox(_item_); $stmt \}$ws3";
    } else {
      $first_stmt .= "$ws1\{$ws2$type $item = mutable-unbox(_item_); $stmt$ws3";
    }
  } elsif ($type =~ m|($tid)|) {
    my $klass_name = $1;
    $result .= " object-t _item_ = _context.next(_context.iter);";
    $result .= " /**/)";
    $klass_name =~ s/-t$//;

    if (!$open_brace) { # $ws2 will be undefined
      $first_stmt .= "$ws1\{ $type $item = $klass_name\::mutable-unbox(_item_); $stmt \}$ws3";
    } else {
      $first_stmt .= "$ws1\{$ws2$type $item = $klass_name\::mutable-unbox(_item_); $stmt$ws3";
    }
  } else {
    die __FILE__, ":", __LINE__, ": error: type: $type\n";
  }
  $result .= $first_stmt;
  return $result;
}
sub rewrite_for_in {
  my ($filestr_ref) = @_;
  # for ( object-t xx : yy )
  # for ( pair-t& xx : yy )
  $$filestr_ref =~ s=(?:for|loop)\s*(forward|backward)?\s*\(\s*($id(\*|&)?)\s*($id)\s+in\s+(.*?)\s*\)(\s*)(\{?)(\s*)(.*?;)(\s*)=&rewrite_for_in_replacement($1, $2, $4, $5, $6, $7, $8, $9, $10)=gse;
}
sub rewrite_slot_access {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/self\./mutable-unbox(self)./g;
}
sub hash {
  my ($keyword) = @_;
  $keyword =~ s|^\'||;  # strip leading  single-quote
  $keyword =~ s|\'$||;  # strip trailing single-quote
  my $stmt = "dk-hash(\"$keyword\")";
  &encode_strings(\$stmt);
  return $stmt;
}
sub encode_str {
  my ($str) = @_;
  $str =~ s/^#\|(.+?)\|$/#$1/;
  $str =~ s/^#//;
  my $qstr = "\"$str\"";
  &encode_strings(\$qstr);
  return $qstr;
}
sub rewrite_switch_replacement {
  my ($expr, $body) = @_;
  if ($body =~ m/\bcase\s*(".*?"|\#$mid|\#\|.+?\||dk-hash\s*$main::list)\s*:/g) {
    $expr =~ s/^(\s*)(.+)$/$1(dk-hash-switch$2)/s;
    $body =~ s/(\bcase\s*)(".*?")(\s*:)/$1 . 'dk-hash(' .             $2 . ')' . $3/egsx;
    $body =~ s/(\bcase\s*)(\#.+?)(\s*:)/$1 . 'dk-hash(' . &encode_str($2) .')' . $3/egsx; # __hash::_abc_def
  }
  return "switch$expr$body";
}
sub rewrite_switch_recursive {
  my ($expr, $body) = @_;
  $body =~ s/\bswitch(.*?$main::list)(.*?$main::block)/&rewrite_switch_recursive($1, $2)/egs;
  return &rewrite_switch_replacement($expr, $body);
}
sub rewrite_switch {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/\bswitch(.*?$main::list)(.*?$main::block)/&rewrite_switch_recursive($1, $2)/egs;
}
sub exported_slots_body {
  my ($a, $b, $c, $d, $e, $f) = @_;
  #my $d = &remove_non_newlines($c);
  if ($e) {
    $e =~ s/^\s*:\s*($id)\s*$/$1, /;
  }
  return "SLOTS($c,$d$e$f);";
}
sub rewrite_module_statement {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s|\bmodule\s+($id)\s*;|MODULE($1);|gs;
  $$filestr_ref =~ s|\bimport\s+($id)\s*\{($main::block_in)\}|MODULE-IMPORT($1, $2);|gs;
  $$filestr_ref =~ s|\bexport\s+($id)\s*\{($main::block_in)\}|MODULE-EXPORT($1, $2);|gs;
}
sub add_implied_slots_struct {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*slots)(\s*\{)/$1 struct$2/gs;
  $$filestr_ref =~ s/(?<=$stmt_boundry)(\s*slots)(\s*;)/$1 struct$2/gs;
}
sub remove_exported_slots {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s=(\[\[export\]\])(\s+slots\s+)=/*$1*/$2=gs;
  $$filestr_ref =~ s=(slots)(\s+)(struct|union|type-enum|enum)(\s*)([^;]*?)(\{.*?\})=&exported_slots_body($1, $2, $3, $4, $5, $6)=gse;
}
sub exported_enum_body {
  my ($a, $b, $c, $d, $e) = @_;
  return "/*$a$b$c$d$e*/";
}
sub remove_exported_enum {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(\[\[export\]\])(\s+enum)(\s*$k*)(.*?)(\{.*?\}\s*;?)/&exported_enum_body($1, $2, $3, $4, $5)/gse;
}
# method init( ... , object-t #arg1, object-t #arg2 = ...) {|;
# method init( ... , object-t  arg1, object-t  arg2      ) {|;

# $init(...,        #arg1 =      ...,         #arg2 =      ...)
# $init(..., SYMBOL(_arg1) , ARG(...), SYMBOL(_arg2) , ARG(...), nullptr)
sub rewrite_keyword_syntax_list {
  my ($arg1, $arg2, $arg3) = @_;
  my $list = $arg3;

  if ($arg3 =~ m/(?<!$colon)$colon(?!$colon)/g) {
    #print STDERR "$arg1$arg2$list\n";

    # remove the leading and trailing parens
    # so we can remove balenced parens and
    # everything in between
    $list =~ s/^\(//;
    $list =~ s/\)$//;
    $list =~ s/($rid*$main::list)/&remove_non_newlines($1)/ges;
    $list =~ s/($rid*$main::block)/&remove_non_newlines($1)/ges;
    $list = "($list)";

    $list =~ s{($mid\s*)((?<!$colon)$colon(?!$colon)\s*.*?)(\s*,|\))}{$1 $3}gx;
    $list =~ s{($id \s*)((?<!$colon)$colon(?!$colon)\s*.*?)(\s*,|\))}{$1 $3}gx;
    #print STDERR "$arg1$arg2$list\n";
  }
  return "$arg1$arg2$list";
}
sub keyword_use {
  my ($arg1, $arg2) = @_;
  my $arg1_ident = &dk_mangle($arg1);
  return "&__keyword::$arg1_ident$arg2,cast(intptr-t)";
}
sub rewrite_keyword_use {
  my ($arg1, $arg2) = @_;
  my $list = $arg2;

  #print STDERR "$arg1$list\n";
  $list =~ s/\#?($mid)(\s*)(?<!$colon)$colon(?!$colon)/&keyword_use($1, $2)/ge;
  $list =~ s/\#?($id)(\s*)(?<!$colon)$colon(?!$colon)/&keyword_use($1, $2)/ge;
  $list =~ s/\)$/, SENTINEL-PTR\)/g;
  $list =~ s/(cast\(.+?\))(\s+)/$2$1/g;
  #print STDERR "$arg1$list\n";
  return "$arg1$list";
}
sub rewrite_keyword_syntax {
  my ($filestr_ref, $kw_arg_generics) = @_;
  foreach my $name (keys %$kw_arg_generics) {
    $$filestr_ref =~ s/(method.*?)($name)($main::list)/&rewrite_keyword_syntax_list($1, $2, $3)/ge;
    $$filestr_ref =~ s/(\$$name)($main::list)/&rewrite_keyword_use($1, $2)/ge;
  }
  $$filestr_ref =~ s|\$make(\([^\)]+?\.\.\.\))|__MAKE__$1|gs;
  $$filestr_ref =~ s/(\$make)($main::list)/&rewrite_keyword_use($1, $2)/ge;
  $$filestr_ref =~ s|__MAKE__|\$make|gs;
}
sub rewrite_sentinel_generic_uses_sub {
  my ($name, $arg_list, $kw_arg_generics) = @_;
  &rewrite_sentinel_generic_uses(\$arg_list, $kw_arg_generics);
  if (1) {
    $arg_list =~ s/$/, SENTINEL-PTR/g;
    $arg_list =~ s/,\s*SENTINEL-PTR\s*,\s*SENTINEL-PTR\s*$/, SENTINEL-PTR/g;
    $arg_list =~ s/^(\s*(object-t|super-t)\s*.*?),\s*SENTINEL-PTR\s*$/$1/g;
  }
  return "$name\($arg_list\)";
}
sub rewrite_sentinel_generic_uses {
  my ($filestr_ref, $kw_arg_generics) = @_;
  $$kw_arg_generics{'make'} = undef;
  foreach my $name (sort keys %$kw_arg_generics) {
    if ('make' ne $name && $name !~ m/^\$/) {
      $name = "\$$name";
    }
    $$filestr_ref =~ s/\b($name)\s*\(($main::list_in)\)/&rewrite_sentinel_generic_uses_sub($1, $2, $kw_arg_generics)/egms;
  }
  delete $$kw_arg_generics{'make'};
}
sub wrapped_rewrite {
  my ($filestr_ref, $lhs, $rhs) = @_;
  my $sst = &sst::make($$filestr_ref, undef);

  &rewrite($sst, $lhs, $rhs);

  my $filestr = &sst::filestr($sst);
  $$filestr_ref = $filestr;
}
sub rewrite {
  my ($sst, $lhs, $rhs) = @_;
  my $sst_cursor = &sst_cursor::make($sst);
  my $size = &sst_cursor::size($sst_cursor);
  my $all_matches = [];
  for (my $i = 0; $i < $size - @$lhs; $i++) {
    my $first_index = $$sst_cursor{'first-token-index'} || 0;
    my $last_index = $$sst_cursor{'last-token-index'} || undef;
    my $new_sst_cursor = &sst_cursor::make($$sst_cursor{'sst'}, $first_index + $i, $last_index);
    my ($range, $matches) = &sst_cursor::match_pattern_seq($new_sst_cursor, $lhs);

    if ($range) {
      $$range[0] += $first_index + $i;
      $$range[1] += $first_index + $i;

      # why add_first()?  Because we want to iterate over the 
      # results in reverse order (so we don't have to adjust the range
      # after every splice
      &add_first($all_matches, [$range, $matches]);
    }
  }
  if (0 != @$all_matches) {
    foreach my $match (@$all_matches) {
      my $result = [];
      foreach my $tkn (@$rhs) {
        if ($tkn =~ m/^\?/) {
          my $seq = $$match[1]{$tkn};
          foreach my $seq_tkn (@$seq) {
            &add_last($result, $seq_tkn);
          }
        } else {
          &add_last($result, $tkn);
        }
      }
      my $index = $$match[0][0];
      my $length = $$match[0][1] - $$match[0][0] + 1;
      &sst::splice($sst, $index, $length, $result);
    }
  }
}
sub export_method_rhs {
  my ($a, $b, $c, $sig_min) = @_;
  #$c =~ s/(\bnoexport\b)(\s+\bmethod\b.*?$sig_min\s*$main::list\s*;)/$1/gm;
  #$c =~ s/(\bnoexport\b)(\s+\bmethod\b.*?$sig_min\s*$main::list\s*$main::block)/$1/gm;

  $c =~ s/(\bmethod\b.*?$sig_min\s*$main::list\s*(;|$main::block))/\[\[export\]\] $1/gm;

  #print STDERR "$a$b\{ ... method ... $sig_min \( ... \) { ... } ... \}\n";
  #print STDERR "$c\n";
  return "$a$b$c";
}
sub rewrite_export_method {
  my ($filestr_ref, $exports) = @_;
  if (0 == keys %$exports) {
    #print STDERR "path=$path, exports={}\n";
  }
  #print STDERR &Dumper($exports);

  while (my ($module_name, $symbol_tbl) = each (%$exports)) {
    foreach my $symbol (sort keys %$symbol_tbl) {
      #print STDERR "$symbol\n";
      if ($symbol =~ m/($id)::($msig)/) {
        my $klass_name = $1;
        my $sig = $2;
        if ($sig !~ m/-t$/) {
          my $sig_min = $sig;
          $sig_min =~ s/\(.*?\)$//;
          $$filestr_ref =~ s/(klass|trait)(\s+$klass_name\s*)($main::block)/&export_method_rhs($1, $2, $3, $sig_min)/ges;
        }
      }
    }
  }
}
sub rewrite_include_fors {
  my ($filestr_ref) = @_;
  my $h =  &header_file_regex();
  $$filestr_ref =~ s=^include-for(\s*)(<$h+>|"$h+")(.*?);=# include$1$2 /*$3 */=gsm;
}
#                     weak-object-t <ident> =
# =>
# object-t _<ident>_; weak-object-t <ident> = _<ident>_ =
sub rewrite_weak_objects {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/\[\[\s*weak\s*\]\](\s*)object-t/$1weak-object-t/g;
  $$filestr_ref =~ s/(weak-object-t\s+($id)\s*=)/object-t _$2_; $1 _$2_ =/g;
}
#sub convert_types_to_include {
#  my ($filestr_ref) = @_;
#  $$filestr_ref =~ s/((?:klass|trait)\s+$rid\s+\{\s*)types(\s*(?:".+?"|<.+?>)\s*);([^\n]*)\n(\s*)/# include$2$3$4\n$1/gs;
#}
sub rewrite_method_aliases {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(\s+)method\s+((va::)?$mid\s*\(\s*\))\s*=>\s*((va::)?$mid\s*$main::list)\s*;/$1METHOD-ALIAS($2, $4);/gs
}
sub rewrite_multi_char_consts {
  my ($filestr_ref) = @_;
  my $c = ' ';
  $$filestr_ref =~ s/'([^'\\])([^'\\])([^'\\])'/'$1$2$3$c'/g;
  $$filestr_ref =~ s/'([^'\\])([^'\\])'/'$1$2$c$c'/g;
}
sub rewrite_map {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(map\s*\($rid\s*,\s*)\{/$1\[=\](object-t _) -> object-t {/g;
}
sub rewrite_func {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/(\s)func(\s+$rmid\s*\()/$1FUNC$2/g;
  $$filestr_ref =~ s/(\s)func(\s+\$$rmid\s*\()/$1FUNC$2/g;
  $$filestr_ref =~ s/(\s)func(\s+va::$rmid\s*\()/$1FUNC$2/g;
  $$filestr_ref =~ s/(\s)func(\s+\$va::$rmid\s*\()/$1FUNC$2/g;
  $$filestr_ref =~ s/\bfunc(\s*\(\s*\*\s*\))/FUNC$1/g;
  $$filestr_ref =~ s/\bfunc(\s*\(\s*\*\s*$mid\s*\))/FUNC$1/g;
  $$filestr_ref =~ s/\bfunc(\s*\(\s*\*\s*\$$mid\s*\))/FUNC$1/g;
  $$filestr_ref =~ s/\bcast(\s*)\((\s*)func(\s+|\()/cast$1($2FUNC$3/g;
  $$filestr_ref =~ s/\bstatic(\s+)func(\s+)/static$1FUNC$2/g;
}
sub rewrite_method_chaining_replacement {
  my ($func, $leading_expr, $args) = @_;

  if ($leading_expr =~ /^\s*(\(\s*)+\s*(\s*\))+\s*$/) {
    print STDERR "warning: leading-expr empty; rewrite will not compile.\n";
  }
  if ($args =~ /^\s*$/) {
    return "$func($leading_expr)"
  } else {
    return "$func($leading_expr, $args)"
  }
}
sub rewrite_method_chaining {
  my ($filestr_ref) = @_;
  my $gf = qr/(?:\$|\$va::)/;
  my $leading_expr = qr/(?:$gf?$id(?:::$id)*(?:$main::list|$main::seq+)?(?:\s*(?:\.|->)\s*$gf?$id(?:$main::list|$main::seq+)?)*|$main::list)/s;

  while ($$filestr_ref =~
           # intentionally not capturing the dot (.)
           s/($leading_expr(?:\s*\.\s*$gf$mid\($main::list_in\)\s*)+\s*)\.(\s*$gf$mid)\(($main::list_in)\)/
             # $1: leading-expr, $2: func-name, $3: args
             &rewrite_method_chaining_replacement($2, $1, $3)/egs) {}
  $$filestr_ref =~
    # intentionally not capturing the dot (.)
    s/($leading_expr\s*)\.(\s*$gf$mid)\(($main::list_in)\)/
      # $1: leading-expr, $2: func-name, $3: args
      &rewrite_method_chaining_replacement($2, $1, $3)/egs;
}
sub rewrite_xsymbol_syntax {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/#\|($mid)\|/#$1/g;
}
sub convert_dk_to_cc {
  my ($filestr_ref, $kw_arg_generics, $remove) = @_;
  &rewrite_literal_strs($filestr_ref);
  &encode_strings($filestr_ref);
  my $parts = &encode_comments($filestr_ref);
  &rewrite_method_chaining($filestr_ref);
  #&rewrite_method_aliases($filestr_ref);

  &rewrite_include_fors($filestr_ref);
  &rewrite_weak_objects($filestr_ref);
  &rewrite_xsymbol_syntax($filestr_ref);
 #&convert_types_to_include($filestr_ref);
  &rewrite_literal_booles($filestr_ref);
  &rewrite_literal_chars($filestr_ref);
  &rewrite_literal_ints($filestr_ref);
  &rewrite_scoped_int_uint($filestr_ref);
  &rewrite_switch($filestr_ref);

  &rewrite_objects($filestr_ref); # must be before line removing leading #
  $$filestr_ref =~ s/\#($mid\s*$colon)/$1/g; # just remove leading #, rnielsen
  #&wrapped_rewrite($filestr_ref, [ '?literal-squoted-cstring' ], [ 'DKT-SYMBOL', '(', '?literal-squoted-cstring', ')' ]);
  &rewrite_symbols($filestr_ref);

  &rewrite_multi_char_consts($filestr_ref);
  &rewrite_module_statement($filestr_ref);

  &rewrite_klass_decl($filestr_ref);
  &rewrite_klass_defn_with_implicit_metaklass_defn($filestr_ref);
  &add_implied_slots_struct($filestr_ref);
  if ($remove) {
    &remove_exported_slots($filestr_ref);
  }
  #&wrapped_rewrite($filestr_ref, [ '[[export]]', 'slots', '?block' ], [ ]);

  if ($remove) {
    &remove_exported_enum($filestr_ref);
  }
  #&wrapped_rewrite($filestr_ref, [ '[[export]]', 'enum',           '?block' ], [ ]);
  #&wrapped_rewrite($filestr_ref, [ '[[export]]', 'enum', '?ident', '?block' ], [ ]);

  &rewrite_set_literal($filestr_ref);
  &rewrite_sequence_literal($filestr_ref);

  if ($$filestr_ref =~ m/\Wcatch\W/g) {
    &rewrite_exceptions($filestr_ref);
  }
  &rewrite_finally($filestr_ref);
  &rewrite_throws($filestr_ref);
  #&wrapped_rewrite($filestr_ref, [ 'throw', 'make' ], [ 'throw', '*', 'dkt-current-exception', '(', ')', '=', 'make' ]);
  #&wrapped_rewrite($filestr_ref, [ 'throw', '?literal-cstring' ], [ 'throw', '*', 'dkt-current-exception-cstring', '(', ')', '=', '?literal-cstring' ]);

  # [?klass-type is 'klass' xor 'trait']
  # using ?klass-type ?qual-ident;
  # ?klass-type ?ident = ?qual-ident;
  $$filestr_ref =~ s/\b(using\s+)(klass|trait)(\s+)/$1 . uc($2) . "-NS" . $3/ge;

  #&nest_generics($filestr_ref);
  &rewrite_slots($filestr_ref);
  &rewrite_enums($filestr_ref);
  &rewrite_const($filestr_ref);

  &rewrite_signatures($filestr_ref);
  &rewrite_selectors($filestr_ref);
  &rewrite_keyword_syntax($filestr_ref, $kw_arg_generics);
  &rewrite_sentinel_generic_uses($filestr_ref, $kw_arg_generics);
  &rewrite_array_types($filestr_ref);
  &rewrite_methods($filestr_ref, $kw_arg_generics);
  &rewrite_map($filestr_ref);
  &rewrite_for_in($filestr_ref);
  &rewrite_unboxes($filestr_ref);
  &rewrite_func($filestr_ref);

  &rewrite_slot_access($filestr_ref);
  #&wrapped_rewrite($filestr_ref, [ 'self', '.', '?ident' ], [ 'unbox', '(', 'self', ')', '->', '?ident' ]);

  &rewrite_boxes($filestr_ref);
  &rewrite_unless($filestr_ref);
  &rewrite_creates($filestr_ref);
  &rewrite_supers($filestr_ref);
  &rewrite_compound_literal_cstring_null($filestr_ref);
  &rewrite_compound_literal_cstring($filestr_ref);
  &rewrite_compound_literal($filestr_ref);
  &rewrite_klass_defn($filestr_ref);
  &nest_namespaces($filestr_ref);
  &rewrite_syntax($filestr_ref);
  $$filestr_ref =~ s|\$(make[^\w-])|$1|g; #hackhack
  &rewrite_declarations($filestr_ref);

  $$filestr_ref =~ s/else[_-]if/else if/gs;

  $$filestr_ref =~ s/,(\s*\})/$1/gs; # remove harmless trailing comma
  $$filestr_ref =~ s|;;|;|g;

  &decode_comments($filestr_ref, $parts);
  &decode_strings($filestr_ref);
  return $filestr_ref;
}
sub dakota_lang_user_data_old {
  my $kw_arg_generics;
  if ($ENV{'DKT_KW_ARGS_GENERICS'}) {
    $kw_arg_generics = do $ENV{'DKT_KW_ARGS_GENERICS'} or die "do $ENV{'DKT_KW_ARGS_GENERICS'} failed: $!\n";
  } elsif ($gbl_prefix) {
    $kw_arg_generics = do "$gbl_prefix/src/kw-arg-generics.pl" or die "do $gbl_prefix/src/kw-arg-generics.pl failed: $!\n";
  } else {
    die;
  }

  my $user_data = { 'kw-arg-generics' => $kw_arg_generics };
  return $user_data;
}
sub start {
  my ($argv) = @_;
  my $user_data = &dakota_lang_user_data_old();

  foreach my $arg (@$argv) {
    my $filestr = &filestr_from_file($arg);

    &convert_dk_to_cc(\$filestr, $$user_data{'kw-arg-generics'});
    print $filestr;
  }
}
unless (caller) {
  &start(\@ARGV);
}
1;
