#!/usr/bin/env perl

use warnings;
use strict;

BEGIN { unshift @INC, qw(./perl5 ./perl5/Android ./perl5/Android/NDK); }

use File::Spec;
use Android::NDK;

my $ndk_path = $ARGV[0];

my $top = File::Spec->rel2abs(File::Spec->curdir());

my $pari_source = File::Spec->catdir( $top, 'pari' );

unless ( -d $pari_source ) {
  print 'Pari/GP source code not detected - preparing to fetch from git repository',"\n";
  fetch_pari_source();
} else {
  print 'Found Pari/GP source code: ' . "$pari_source","\n";
}

my $ndk = Android::NDK->new( 'ndk_path' => $ndk_path );
print 'Path to Android NDK: ' . "$ndk_path","\n";

my $pari_toolchain = gen_pari_toolchain();
print 'Path to Android/ARM Toolchain: ' . $pari_toolchain->get_install_dir(),"\n";

my $makefile_in = gen_pari_makefile();
print 'Generated Makefile.include:' . "$makefile_in","\n";

my $pari_cfg = gen_pari_cfg();
print 'Generated Pari/GP Configuration File: ' . "$pari_cfg","\n";

my $sysroot = File::Spec->catdir ( $pari_toolchain->get_install_dir(), 'sysroot' );

unless ( -d $sysroot ) {
  $pari_toolchain->build();
  print 'Extracted toolchain',"\n";
  my $target = File::Spec->catfile( $pari_toolchain->get_install_dir(), 'sysroot', 'usr', 'include', 'sys', 'termios.h' );
  unless ( -f $target ) {
    my $termios_h = File::Spec->catfile( $sysroot, 'usr', 'include', 'termios.h' );
    system( 'cp', $termios_h, $target );
    print 'Copied header termios.h to sys/termios.h under toolchain sysroot...',"\n";
  } else {
    print 'Detected sys/termios.h under toolchain sysroot...',"\n";
  }
} else {
  print 'Detected Android/ARM Toolchain - no need to rebuild',"\n";
  print 'Sysroot: ' . "$sysroot","\n";
}

configure_pari();

print 'Done.',"\n";

sub configure_pari {
  my $script_path = File::Spec->catfile( $pari_source, 'Configure' );
  my $cfg_file = File::Spec->canonpath( $pari_cfg );
  chdir ( $pari_source );
  system ( $script_path, '-l', $cfg_file );
}

sub gen_pari_makefile {
  my $makefile_path = File::Spec->catfile( $top, 'Makefile.include' );
  my $make = _gen_makefile($pari_toolchain);

  open ( my $MAKE_FH, '>', "$makefile_path" )
    or die "could not write $makefile_path: $!";

  foreach my $key ( keys %{ $make } ) {
    my ( $var, $val ) = ( uc($key), $make->{$key} );
    my $line = "$var" . '=' . "$val";
    print $MAKE_FH "$line","\n";
  }
  return $makefile_path;
}

sub _gen_makefile {

  my $make = { };

  $make->{top} = $top;
  $make->{ndk_path}  = $ndk->get_ndk_path();
  $make->{ndk_build} = $ndk->get_ndk_build();
  $make->{toolchain} = $pari_toolchain->get_install_dir();
  $make->{platform} = $pari_toolchain->get_platform();

  return $make;
}

sub gen_pari_toolchain {
  my $toolchain_install_dir = File::Spec->catdir( "$top", 'pari', 'android', 'android-toolchain' );
  return _gen_toolchain($toolchain_install_dir);
}

sub _gen_toolchain {
  my ( $install_dir ) = @_;
  my %toolchain_opts = ( 'verbose' => '1', 'install_dir' => $install_dir );
  my $toolchain = $ndk->make_toolchain( %toolchain_opts );
  return $toolchain;
}

sub build_toolchain {
  my ( $toolchain ) = @_;
  $toolchain->build();
}

sub fetch_pari_source {
  my $repo_url =  'http://pari.math.u-bordeaux.fr/git/pari.git';
  _clone_repo($repo_url);
}

sub _clone_repo {
  my ( $url ) = @_;
  system( 'git', 'clone', "$url" );
}


sub gen_pari_cfg {
  my %config = _gen_pari_config( $pari_toolchain->get_install_dir(), '/data/local' );
  my $template = File::Spec->catfile( $top, 'config', 'template.cfg' );
  my $outfile = File::Spec->catfile ( $top, 'pari', 'pari.cfg' );
  write_pari_cfg( $template, $outfile, %config );
  return $outfile;
}

sub _gen_pari_config {

  my ( $toolchain, $prefix ) = @_;

  my $cc = $pari_toolchain->get_cc();
  my $modules = get_modules_build( $toolchain );

  my %config = (
		'shell_q' => '',
		'pari_release' => '2.6.0',
		'pari_release_verbose' => '2.6.0 (DEVELOPMENT VERSION)',
		'version' => '2.6',
		'libpari_base' => 'pari',
		'static' => 'n',
		'objdir' => 'Oandroid-arm',
		'arch' => 'arm',
		'asmarch' => 'none',
		'osname' => 'android',
		'pretty' => 'arm-linux-androideabi (portable C/GMP-5.0.1 kernel) 32-bit version',
		'kernlvl0' => 'none',
		'kernlvl1' => 'none',
		'DL_LIBS' => '-ldl',
		'LIBS' => '-lm',
		'dir_sep' => ':',
		'runpath' => '"/usr/lib"',
		'runpathprefix' => '-rpath ',
		'LDDYN' => '-lpari',
		'RUNTEST' => '/bin/true',
		'ranlib' => '/usr/bin/ranlib',
		'gzip' => '/bin/gzip',
		'zcat' => '/bin/zcat',
		'perl' => '/usr/bin/perl',
		'ln_s' => 'ln -s',
		'make_sh' => '/bin/sh',
		'sizeof_long' => '4',
		'doubleformat' => '1',
		'enable_tls' => '',
		'test_extra_out' => 'ploth',
		'test_extra' => '',
		'test_basic' => '',
		'top_test_extra' => '',
		'top_dotest_extra' => '',
		'prefix' => $prefix,
		'share_prefix' => $prefix . '/share',
		'bindir' => $prefix . '/bin',
		'datadir' => $prefix . '/bin/share/pari',
		'includedir' => $toolchain . '/sysroot/usr/include',
		'libdir' => $prefix . '/lib',
		'mandir' => '',
		'sysdatadir' => $prefix . '/lib/pari',
		'add_funclist' => '../src/funclist',
		'__gnuc__' => '4.4.3 (arm-linux-androideabi, GNU/Linux) ',
		'CC' => $cc,
		'CFLAGS' => '-g -O3 -Wall -fomit-frame-pointer -fno-strict-aliasing',
		'optimization' => 'full',
		'DBGFLAGS' => '-g -Wall',
		'OPTFLAGS' => '-O3 -Wall -fno-strict-aliasing -fomit-frame-pointer',
		'exe_suff' => '',
		'suffix' => '',
		'ASMINLINE' => 'yes',
		'LD' => $cc,
		'LDFLAGS' => '-g -O3 -fomit-frame-pointer -fno-strict-aliasing -Wl,--export-dynamic ',
		'LIBS' => '-lm',
		'runpathprexix' => '',
		'LDneedsWl' => 'yes',
		'LDused' => 'ld',
		'GNULDused' => 'yes',
		'DLCFLAGS' => '-fPIC',
		'DL_DFLT_NAME' => 'NULL',
		'DLLD' => $cc,
		'DLLDFLAGS' => '-shared $(CFLAGS) $(DLCFLAGS) -Wl,-shared,-soname=$(LIBPARI_SONAME)',
		'EXTRADLLDFLAGS' => '-lc ${LIBS}',
		'DLSUFFIX' => 'so',
		'soname' => '',
		'sodest' => '',
		'which_graphic_lib' => 'none',
		'X11' => '',
		'X11_INC' => '',
		'X11_LIBS' => '',
		'FLTKDIR' => '',
		'FLTK_LIBS' => '',
		'QTDIR' => '',
		'QTLIB' => '',
		'EXTRAMODLDFLAGS' => '-lc -lm -L ' . $toolchain . '/sysroot/usr/lib -lpari',
		'MODLD' => $cc,
		'MODLDFLAGS' => '-shared $(CFLAGS) $(DLCFLAGS) -Wl,-shared ',
		'modules_build' => $modules,
		'readline' => '',
		'readline_version' => '',
		'readline_enabledp' => '',
		'CPPF_defined' => '',
		'rl_library_version' => '',
		'rl_history' => '',
		'rl_refresh_line_oldproto' => '',
		'rl_appendchar' => '',
		'rl_message' => '',
		'rl_save_prompt' => '',
		'rl_fake_save_prompt' => '',
		'_rl_save_promptrl_genericbind' => '',
		'rl_bind_key_in_map' => '',
		'rl_attempted_completion_over' => '',
		'rl_completion_query_items' => '',
		'rl_completion_matches' => '',
		'rl_completion_func_t' => '',
		'RLINCLUDE' => '',
		'RLLIBS' => '',
		'gmp' => '',
		'GMPLIBS' => '',
		'GMPINCLUDE' => '',
		'has_exp2' => 'no',
		'has_log2' => 'no',
		'has_strftime' => 'yes',
		'has_getrusage' => 'yes',
		'has_sigaction' => 'yes',
		'has_TIOCGWINSZ' => 'yes',
		'has_getrlimit' => 'yes',
		'has_stat' => 'yes',
		'has_vsnprintf' => 'yes',
		'has_waitpid' => 'yes',
		'has_setsid' => 'yes',
		'has_getenv' => 'yes',
		'has_isatty' => 'yes',
		'has_alarm' => 'yes',
		'has_dlopen' => 'yes',
	       );

  return %config;
}

sub get_modules_build {
my ( $toolchain )  = @_;

my $cc = $pari_toolchain->get_cc();

my @compile = (
	       "$cc",
	       '-c -o %s.o -g -O3 -Wall -fomit-frame-pointer -fno-strict-aliasing -fPIC',
	       '-I"' . "$toolchain" . '/sysroot/usr/include"',
	       '%s.c && cc -o %s.so -shared -g -O3 -Wall -fomit-frame-pointer -fno-strict-aliasing -fPIC',
	       '-Wl,-shared %s.o -lc -lm -L' . "$toolchain" . '/sysroot/usr/lib -lpari',
	      );

my $modules_build = join( ' ', @compile );

return $modules_build;
}


sub write_pari_cfg {
  my ( $template, $outfile, %pari_config ) = @_;

  open ( my $IN, '<', $template )
    or die "open $template: $!";

  open ( my $OUT, '>', $outfile )
    or die "open $outfile: $!";

  while ( <$IN> ) {
    my $line = $_;
    chomp($line);
    $line =~ s/\=$//;
    if ( exists $pari_config{$line} ) {
      my ( $key, $value ) = ( $line, $pari_config{$line} );
      if ( $key eq 'shell_q' ) {
	print $OUT qw/shell_q="'"/,"\n";
      } else {
	print $OUT "$key" . '=' . "\'" . "$value" . "\'","\n";
      }
    }
  }
}
