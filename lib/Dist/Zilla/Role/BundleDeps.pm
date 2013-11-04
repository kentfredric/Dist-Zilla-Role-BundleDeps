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

sub _extract_plugin_prereqs {
  my ( $self, @config ) = @_;
  require CPAN::Meta::Requirements;
  my $reqs = CPAN::Meta::Requirements->new();
  for my $item (@config) {
    my ( $name, $module, $conf ) = @{$item};
    my $version = 0;
    $version = $conf->{':version'} if exists $conf->{':version'};
    $reqs->add_string_requirement( $module, $version );
  }
  return $reqs;
}

sub _create_prereq_plugin {
  my ( $self, $reqs, $config ) = @_;
  my $plugin_conf = { %{$config}, %{ $reqs->as_string_hash } };
  my $prereq = [];
  push @{$prereq}, $self->_bundle_alias . '/::Role::BundleDeps';
  push @{$prereq}, 'Dist::Zilla::Plugin::Prereqs';
  push @{$prereq}, $plugin_conf;
  return $prereq;
}

sub bundledeps_defaults {
    return {
        -phase => 'develop',
        -relationship => 'requires',
    };
}

around bundle_config => sub {
  my ( $orig, $self, $section, @rest ) = @_;
  my $myconf = $self->bundledeps_defaults;
  for my $param (qw( phase relationship )) {
    my $field = 'bundledeps_' . $param;
    next unless exists $section->{payload}->{$field};
    $myconf->{ '-' . $param } = delete $section->{payload}->{$field};
  }
  my (@config) = $self->$orig($section);
  my $reqs = $self->_extract_plugin_prereqs(@config);
  return ( @config, $self->_create_prereq_plugin( $reqs => $myconf ) );
};

no Moose::Role;

1;
