use strict;
use warnings;

package Dist::Zilla::Role::BundleDeps;

# ABSTRACT: Automatically add all plugins in a bundle as dependencies

=head1 SYNOPSIS

    package blahblahblah;
    use Moose;
    ...
    with 'Dist::Zilla::Role::PluginBundle';
    with 'Dist::Zilla::Role::BundleDeps';

Dependencies appear now for all plugins returned.

=cut

=head1 DESCRIPTION

This role attempts to solve the problem of communicating dependencies to META.* from bundles
in a different way.

My first attempt was L<< C<[Prereqs::Plugins]>|Dist::Zilla::Plugins::Prereqs::Plugins >>, which added
all values that are seen in the C<dist.ini> to dependencies.

However, that was inherently limited, as the C<:version> specifier
is lost before the plugins appear on C<< $zilla->plugins >>

This Role however, can see any declarations of C<:version> your bundle advertises,
by standing between your C<bundle_config> method and C<Dist::Zilla>

=cut

use Moose::Role;

sub _bundle_alias {
  my ($self) = @_;
  my $ns = $self->meta->name;
  if ( $ns =~ /\ADist::Zilla::PluginBundle::(.*\z)/msx ) {
    return q[@] . $1;
  }
  return $ns;
}

around bundle_config => sub {
  my ( $orig, $self, $section, @rest ) = @_;
  my $myconf;
  for my $param (qw( phase relation )) {
    my $field = 'bundledeps_' . $param;
    next unless exists $section->{payload}->{$field};
    $myconf->{$param} = delete $section->{payload}->{$field};
  }
  $myconf->{phase}    = 'develop'  unless exists $myconf->{phase};
  $myconf->{relation} = 'requires' unless exists $myconf->{relation};
  my (@config) = $self->$orig($section);
  require CPAN::Meta::Requirements;
  my $reqs = CPAN::Meta::Requirements->new();
  for my $item (@config) {
    my ( $name, $module, $conf ) = @{$item};
    my $version = 0;
    $version = $conf->{':version'} if exists $conf->{':version'};
    $reqs->add_string_requirement( $module, $version );
  }
  push @config,
    [
    $self->_bundle_alias . '/::Role::BundleDeps',
    'Dist::Zilla::Plugin::Prereqs',
    {
      '-phase'        => $myconf->{phase},
      '-relationship' => $myconf->{relation},
      %{ $reqs->as_string_hash }
    }
    ];
  return @config;
};

no Moose::Role;

1;
