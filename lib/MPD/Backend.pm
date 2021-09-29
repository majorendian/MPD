# Author: Ernest Deak
# License: GPLv3

# This file is part of MPD.
# 
# MPD is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# MPD is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with MPD.  If not, see <https://www.gnu.org/licenses/>.

# NOTE: This package is to be treated as purely virtual
# One just uses this as base for the backends and these
# inherited functions will generate an error if one is not
# implemented as expected. It also provides common routines
# to handle autoconfiguration so that the user doesnt have
# to configure everything himself.
# Naturally threre is room for error so we provide a simple
# settings interface (not in this file)

package MPD::Backend;
use Carp qw(confess);

our $pipehandleIn = undef;
our $pipehandleOut = undef;

sub Debugger { confess "Abstract interface"; }
sub DebuggerCommands { confess "Abstract interface"; } 
sub AssemblerPath { confess "Abstract interface"; }
sub CompilerPath { confess "Abstract interface"; }
sub DebuggerPath { confess "Abstract interface"; }

sub instance(){
  my $pkg = shift;
  blessed;
}

sub bprint(@){
  print __PACKAGE__ . ": " . join " | ", @_ . "\n";
}

sub setInputOutput($$){
  $pipehandleIn = shift;  
  $pipehandleOut = shift;
}

sub exeCommand($){
  my $cmd = shift;
  print $pipehandleOut $cmd;
  local $/ = undef;
  return <$pipehandleIn>; #could block?
}

sub commandCheck(){
  my $r = system(@{Debugger()});
  $r <<= 8;
  if($r == 0){
    return 1;
  }else{
    return 0;
  }
}

sub unixAutoconfig($$){
  my $cmd = shift;
  my $packageParam = shift;
  my $exepath = qx/whereis $cmd/;
  $exepath =~ s/.+:\s//;
  chomp $exepath;
  $__PACKAGE__{$packageParam} = sub { return $exepath; };
  return $exepath;
}


sub win32Autoconfig($$){
  confess "Autoconfiguration is not implemented for windows";
}

sub autoconfigure(){
  if($^O =~ m/unix|linux/){
    unixAutoconfig(Debugger()->[0], 'DebuggerPath');
    unixAutoconfig(Assembler()->[0], 'AssemblerPath');
    unixAutoconfig(Compiler()->[0], 'CompilerPath');
  }elsif($^O =~ m/win32|windows/){
    win32Autoconfig(Debugger()->[0], 'DebuggerPath');
    win32Autoconfig(Assembler()->[0], 'AssemblerPath');
    win32Autoconfig(Compiler()->[0], 'CompilerPath');
  }
  if(-e DebuggerPath()){
    bprint "Found debbuger [".DebuggerPath()."]...";
  }else{
    bprint "ERROR: Debugger not found [".DebuggerPath()."]", "Please configure one in the settings window";
  }
  if(-e AssemblerPath()){
    bprint "Assembler found [".AssemblerPath()."]";
  }else{
    bprint "Warning: Assembler for backend has not been found, 'patch' feature will be disabled";
  }
  if(-e CompilerPath()){
    bprint "Compiler found [".CompilerPath()."]";
  }else{
    bprint "Warning: Compiler for backend has not beend found, 'compile C to patch' feature will be disabled";
  }
  return {
    backend => __PACKAGE__,
    assembler => AssemblerPath() // undef,
    debugger => DebuggerPath() // undef,
    compiler => CompilerPath() // undef,
  };
}
1;