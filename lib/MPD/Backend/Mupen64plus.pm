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

package MPD::Backend::Mupen64plus;
use base 'MPD::Backend';
use strict;
use warnings FATAL => "all";
use Exporter qw(import);

our $pipehandleIn = undef;
our $pipehandleOut = undef;

our @EXPORT_OK = qw(
  Debugger
  DebuggerCommands
);

use constant {
  Debugger => ['mupen64plus', '--debug'],
  DebuggerCommands => {
    registers => ["res"],
    memory => ["mem"],
    disassemble => ["asm", "<ADDR>", "<COUNT>"],
    stack => []
  }
};

1;