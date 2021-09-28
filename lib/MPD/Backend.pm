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
package MPD::Backend;
use Carp qw(confess);

our $pipehandleIn = undef;
our $pipehandleOut = undef;

sub Debugger { confess "Abstract interface"; }
sub DebuggerCommands { confess "Abstract interface"; } 
sub AssemblerPath { confess "Abstract interface"; }
sub CompilerPath { confess "Abstract interface"; }
sub DebuggerPath { confess "Abstract interface"; }

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

sub autoconfigure(){
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