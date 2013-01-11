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

  my ( $test_basic, $test_extra, $top_test_extra, $top_dotest_extra ) = get_tests();

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
		'test_extra' => $test_extra,
		'test_basic' => $test_basic,
		'top_test_extra' => $top_test_extra,
		'top_dotest_extra' => $top_dotest_extra,
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
		'CC' => $toolchain . '/bin/arm-linux-androideabi-gcc',
		'CFLAGS' => '-g -O3 -Wall -fomit-frame-pointer -fno-strict-aliasing',
		'optimization' => 'full',
		'DBGFLAGS' => '-g -Wall',
		'OPTFLAGS' => '-O3 -Wall -fno-strict-aliasing -fomit-frame-pointer',
		'exe_suff' => '',
		'suffix' => '',
		'ASMINLINE' => 'yes',
		'LD' => $toolchain . '/bin/arm-linux-androideabi-gcc',
		'LDFLAGS' => '-g -O3 -fomit-frame-pointer -fno-strict-aliasing -Wl,--export-dynamic ',
		'LIBS' => '-lm',
		'runpathprexix' => '',
		'LDneedsWl' => 'yes',
		'LDused' => 'ld',
		'GNULDused' => 'yes',
		'DLCFLAGS' => '-fPIC',
		'DL_DFLT_NAME' => 'NULL',
		'DLLD' => $toolchain . '/bin/arm-linux-androideabi-gcc',
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
		'MODLD' => $toolchain . '/bin/arm-linux-androideabi-gcc',
		'MODLDFLAGS' => '-shared $(CFLAGS) $(DLCFLAGS) -Wl,-shared ',
		'modules_build' => $toolchain . '/bin/arm-linux-androideabi-gcc -c -o %s.o -g -O3 -Wall -fomit-frame-pointer -fno-strict-aliasing -fPIC -I"' . $toolchain . '/sysroot/usr/include" %s.c && cc -o %s.so -shared -g -O3 -Wall -fomit-frame-pointer -fno-strict-aliasing -fPIC -Wl,-shared %s.o -lc -lm -L' . $toolchain . '/sysroot/usr/lib -lpari',
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

sub get_tests {

  my $test_basic = 'objets analyz number polyser linear elliptic sumiter graph program trans nfields_20';

  my $test_extra = 'addprimes analyz apply aurifeuille bezout bnfisintnorm bnr charpoly combinat compat contfrac cxtrigo debugger det diffop ell
		    ellglobalred elliptic ellsea ellweilpairing err exact0 extract ff ffisom galois galoisinit graph ideal idealappr idealramgroups
		    intformal intnum ispower krasner linear list lll mat matsnf member modpr multivar-mul nf nffactor nfhilbert nfields nfrootsof1
		    number objets partition polchebyshev polmod polred polyser printf program qf qfbsolve quad quadclassunit quadray random resultant
		    rfrac rnf rnfkummer round4 select stark subcyclo subfields sumiter thue trans zetak zn';

  my $top_test_extra = 'test-addprimes test-analyz test-apply test-aurifeuille test-bezout test-bnfisintnorm test-bnr test-charpoly test-combinat test-compat
			test-contfrac test-cxtrigo test-debugger test-det test-diffop test-ell test-ellglobalred test-elliptic test-ellsea test-ellweilpairing
			test-err test-exact0 test-extract test-ff test-ffisom test-galois test-galoisinit test-graph test-ideal test-idealappr test-idealramgroups
			test-intformal test-intnum test-ispower test-krasner test-linear test-list test-lll test-mat test-matsnf test-member test-modpr
			test-multivar-mul test-nf test-nffactor test-nfhilbert test-nfields test-nfrootsof1 test-number test-objets test-partition test-polchebyshev
			test-polmod test-polred test-polyser test-printf test-program test-qf test-qfbsolve test-quad test-quadclassunit test-quadray test-random
			test-resultant test-rfrac test-rnf test-rnfkummer test-round4 test-select test-stark test-subcyclo test-subfields test-sumiter test-thue
			test-trans test-zetak test-zn test-ploth';

  my $top_dotest_extra = 'dotest-addprimes dotest-analyz dotest-apply dotest-aurifeuille dotest-bezout dotest-bnfisintnorm dotest-bnr dotest-charpoly dotest-combinat
			  dotest-compat dotest-contfrac dotest-cxtrigo dotest-debugger dotest-det dotest-diffop dotest-ell dotest-ellglobalred dotest-elliptic dotest-ellsea
			  dotest-ellweilpairing dotest-err dotest-exact0 dotest-extract dotest-ff dotest-ffisom dotest-galois dotest-galoisinit dotest-graph dotest-ideal
			  dotest-idealappr dotest-idealramgroups dotest-intformal dotest-intnum dotest-ispower dotest-krasner dotest-linear dotest-list dotest-lll dotest-mat
			  dotest-matsnf dotest-member dotest-modpr dotest-multivar-mul dotest-nf dotest-nffactor dotest-nfhilbert dotest-nfields dotest-nfrootsof1 dotest-number
			  dotest-objets dotest-partition dotest-polchebyshev dotest-polmod dotest-polred dotest-polyser dotest-printf dotest-program dotest-qf dotest-qfbsolve
			  dotest-quad dotest-quadclassunit dotest-quadray dotest-random dotest-resultant dotest-rfrac dotest-rnf dotest-rnfkummer dotest-round4 dotest-select
			  dotest-stark dotest-subcyclo dotest-subfields dotest-sumiter dotest-thue dotest-trans dotest-zetak dotest-zn dotest-ploth';

  return ( $test_basic, $test_extra, $top_test_extra, $top_dotest_extra );
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
