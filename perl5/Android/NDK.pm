#!/usr/bin/env perl

package Android::NDK;

use warnings;
use strict;

use File::Spec;
use Android::NDK::Toolchain;

sub new {
  my ( $class, %opts ) = @_;

  die "ndk_path cannot be undef"
    unless ( $opts{ndk_path} );

  my $ndk_path = File::Spec->canonpath( $opts{ndk_path} );
  my $ndk_build = File::Spec->catfile( $ndk_path , 'ndk-build.sh' );

  my $self = {
	      'ndk_path'   => $ndk_path,
	      'ndk_build'  => $ndk_build,
	      'toolchains' => [],
	     };

  bless $self, $class;
  return $self;
}

sub get_ndk_path {
  my ( $self ) = @_;
  return $self->{ndk_path};
}

sub get_ndk_build {
  my ( $self ) = @_;
  return $self->{ndk_build};
}

sub download_ndk {
  my ( $self ) = @_;

  my $os = $^O;
  my $base_url = 'http://dl.google.com/android/ndk/';
  my $tarball;

  if ( $os =~ /linux/ ) {
    $tarball = 'android-ndk-r8d-darwin-x86.tar.bz2';
  } elsif ( $os =~ /darwin/ ) {
    $tarball = 'android-ndk-r8d-linux-x86.tar.bz2';
  } else {
    die "$os detected - not supported at this time.";
  }

  chomp ( my $wget = `which wget` ); # not reliable

  die "Could not find wget installed on the system - exiting."
      unless ( $wget );

  my $url = $base_url . $tarball;
  system( "$wget", $url, '&&', 'cp', $tarball, File::Spec->updir( $self->{ndk_path} ) );
}

sub make_toolchain {
  my ( $self, %opts ) = @_;
  my $toolchain = Android::NDK::Toolchain->new( 'ndk_path' => $self->{ndk_path}, %opts );
  push @{ $self->{toolchains} }, $toolchain;
  return $toolchain;
}

sub get_toolchains {
  my ( $self ) = @_;
  my @toolchains = @{ $self->{toolchains} };
  return @toolchains;
}

1;
