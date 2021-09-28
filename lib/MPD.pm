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

use Gtk3 -init;
use strict;
use File::Spec;
use autodie;

#
# Predeclarations
#

sub showDefaultDialog($$);

use constant {
	EDITION_MUPEN64PLUS => 1,
	EDITION_COMMUNITY => 2,
	EDITION_ALL_IN_ONE => 3,
	EDITION_LEGENDARY => 7
};

my %Backends = (
	'mupen64plus' => 'MPD::Backend::Mupen64plus',
	'gdb-x86-64' => 'MPD::Backend::GDBX86',
	'gdb-qemu-avr' => 'MPD::Backend::GDBQEMUAVR'
);

our $EDITION = EDITION_MUPEN64PLUS;

our $ROM = undef;
our $BACKEND = undef;

my $DBG_PID = undef;

our %Settings = (
	backend => 'mupen64plus',
	debugger => undef,
	compiler => undef,
	assembler => undef,
	lastOpenedRom => undef,
	patchfileDir => undef, #directory for fun runtime-patches to apply
);

# Debugging related
sub _view_symbols_of_pkg{
	my $pkg = shift;
	my @k =  sort keys %$pkg::;
	print Dumper(\@k);
}

my $config_file = File::Spec->catfile($ENV{HOME},".mpdrc");

my $toplevel = undef;
my $builder = undef;

sub loadBackend($){
	my $backend = shift;
	autoload $backend;
	my $test_backend = undef;
	eval { $test_backend = Debugger() };
	unless(defined $test_backend){
		showDefaultDialog "Error", "Backend error\n[$backend]\n";
	}
}

sub loadConfig(){
	unless(! -e $config_file){
		open my $fh, "<", $config_file;
		while(<$fh>){
			for my $k(keys %Settings){
				if(/^$k:(.+?)$/){
					$Settings{$k} = $1;
				}
			}
		}
		close $fh;
	}
}

sub storeConfig(){
	open my $fh, ">", $config_file;
	for(keys %Settings){
		print $fh $_ . ":" . $Settings{$_} . "\n" if defined $Settings{$_};
	}
	close $fh;
}

sub initMPD(){
	if($EDITION == EDITION_MUPEN64PLUS){
		loadBackend("MPD::Backend::Mupen64plus");
	}
	loadConfig;

	$builder = Gtk3::Builder->new;
	$builder->add_from_file("res/gui.glade");


	$toplevel = $builder->get_object("toplevel");

	# enable toolbar buttons

	my $startTool = $builder->get_object("RUN");
	#$startTool->enable(1);

	my $cssprovider = Gtk3::CssProvider->new;
	$cssprovider->load_from_path("res/style.css");
	Gtk3::StyleContext::add_provider_for_screen(Gtk3::Gdk::Screen::get_default(), $cssprovider, Gtk3::STYLE_PROVIDER_PRIORITY_APPLICATION);


	$builder->connect_signals(undef);

	$toplevel->signal_connect("destroy", \&quit);
	return $toplevel;

}

# Show and start main loop

sub mainMPD(){
	initMPD->show;
	Gtk3->main;
}

#
# Generic signals
#

sub response($){
	my $w = shift;
	print "Response function\n";
	$w->destroy;
}

sub closeDialog{
	shift()->hide;
	return 1;
}

#
# Helpers
#

sub runDialog(&$$){
	my $code = shift;
	my $title = shift;
	my $message = shift;
	my $dialog = Gtk3::Dialog->new($title, $toplevel, "GTK_DIALOG_MODAL",
		Ok => 1,
	);
	my $label = Gtk3::Label->new();
	$label->set_text($message);
	my $box = $dialog->get_content_area;
	$box->add($label);
	$label->show;
	$dialog->signal_connect("response", $code);
	$dialog->run;
}

sub showDefaultDialog($$){
	runDialog {
		my $w = shift;
		$w->destroy;
	} shift, shift;
}

sub getTextOf($){
	my $wname = shift;
	my $buff = $builder->get_object($wname)->get_buffer();
	return $buff->get_text($buff->get_start_iter(),$buff->get_end_iter(),0);
}

sub setTextOf($$){
	my $wname = shift;
	my $buff = $builder->get_object($wname)->get_buffer();
	$buff->set_text(shift);
}

sub openDebuggerCLI{
	if(defined $ROM and -f $ROM){
		my $pid = open2(my $chldin, my $chldout, "mupen64plus","--debug",$ROM);
		$DBG_PID = $pid;
		return ($chldin, $chldout);
	}else{
		showDefaultDialog("Error","No ROM specified.\nPlease select a ROM first.");
	}
}

#
# Dialogs
#

sub showAbout{
	my $about = $builder->get_object("about");
	$about->signal_connect("close", \&closeDialog);
	$about->signal_connect("response", \&closeDialog);
	$about->show;
}

sub showSettings{
	my $w = shift;
	my $settings = $builder->get_object("settings_window");
	$settings->signal_connect("destroy", \&closeDialog);
	$settings->show;
}

#
# Tool related
#

sub toolRun{
	print "Pressed\n";
	my ($dbgin, $dbgout) = openDebuggerCLI;
	#setTextOf("mips_as", "Text test\nMore lines\nand modreline");
	my $text = getTextOf("mips_as");
}

sub toolStep{
	die "not implemented\n";
}

sub toolPause{
	die "not implemented\n";
}

sub toolStop{
	die "not implemented\n";
}

sub menuOpen{
	my $fc = Gtk3::FileChooserNative->new("Open ROM", $toplevel,  "GTK_FILE_CHOOSER_ACTION_OPEN", "Open", "Cancel");
	my $filter = Gtk3::FileFilter->new;
	$filter->add_pattern("*.z64");
	$filter->add_pattern("*.n64");
	$fc->set_filter($filter);
	my $r = $fc->run;
	if($r == -3){
		# File selected
		my $file = $fc->get_filename;
		print "File:$file\n";
	}elsif($r == -6){
		print "No file selected\n";
	}
}


#
# Console
#

sub dbgConsole{
	my $w = shift;
	my $c = shift()->keyval;
	my $text = getTextOf("dbg_console");
	print "got:$c\n";
	# if($c == 65293 or $c == Gtk3::Gdk::KEY_ENTER){
	if($c == Gtk3::Gdk::KEY_Return){
		# Enter key
		# my @k =  grep {m/KEY_/} sort keys %Gtk3::Gdk::;
		# my $info = Dumper(\@k);
		my $cmd = getTextOf("dbg_console");
		$cmd = ($cmd =~ m/\n(.*?)$/)[0];
		print $cmd . "\n";
		use MPD::Backend::Stub;
		$BACKEND = "MPD::Backend::Stub";
		my $exeCommand = $BACKEND . "::exeCommand";
		no strict 'refs';
		my $ret = &$exeCommand($cmd);
		use strict 'refs';
		setTextOf("dbg_console", $ret);
		return 1;
	}
	return 0;
}

#
# Quit and other functions
#

sub quit{
	Gtk3::main_quit;
	wait;
	storeConfig;
	exit 0;
}

1;
