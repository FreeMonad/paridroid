#!/usr/bin/env perl

package Android::NDK::Toolchain;

use warnings;
use strict;

use File::Spec;

sub new {
  my ( $class, %opts ) = @_;

  my $ndk_path = File::Spec->canonpath( $opts{ndk_path} );
  my $install_dir;

  if ( $opts{install_dir} ) {
    $install_dir = File::Spec->canonpath( $opts{install_dir} );
  } else {
    $install_dir = File::Spec->canonpath ( '/tmp/android-toolchain' );
  }

  my $self = {
	      'ndk_path'     => $ndk_path,
	      'install_dir'  => $install_dir,
	      'llvm_version' => $opts{llvm_version} || undef,
	      'platform'     => $opts{platform} || 'android-3',
	      'arch'         => $opts{arch} || 'arm',
	      'verbose'      => $opts{verbose} || undef,
	      'mutable'      => '1',
	     };

  bless $self, $class;
  return $self;
}

sub get_platform {
  my ( $self ) = @_;
  return $self->{platform}
}

sub set_platform {
  my ( $self, $platform ) = @_;
  if ( $self->{mutable} ) {
    $self->{platform} = $platform;
  }
}

sub get_install_dir {
  my ( $self ) = @_;
  return $self->{install_dir};
}

sub set_install_dir {
  my ( $self, $path ) = @_;
  if ( $self->{mutable} ) {
    my $install_dir = File::Spec->canonpath( $path );
    $self->{install_dir} = $install_dir;
  }
}

sub is_mutable {
  my ( $self ) = @_;
  return $self->{mutable};
}

sub build {
  my ( $self ) = @_;

  my $script_path = $self->{ndk_path} . '/build/tools/make-standalone-toolchain.sh';

  my @cmd = ( "$script_path",
	      '--arch='.$self->{arch},
	      '--install-dir='.$self->{install_dir},
	      '--platform='.$self->{platform}
	    );

  if ( $self->{llvm_vers} ) {
    my $llvm_arg = '--llvm-vers='.$self->{llvm_vers};
    push @cmd, $llvm_arg;
  }

  if ( $self->{verbose} ) {
    my $verbose_arg = '--verbose';
    push @cmd, $verbose_arg;
  }

  system(@cmd);
  $self->{mutable} = '0';
}

1;
