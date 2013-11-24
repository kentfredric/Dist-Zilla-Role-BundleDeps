
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4202"
  },
  "configure_requires" => {
    "Module::Build" => "0.4202"
  },
  "dist_abstract" => "Automatically add all plugins in a bundle as dependencies",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Dist-Zilla-Role-BundleDeps",
  "dist_version" => "0.001001",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Role::BundleDeps",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "CPAN::Meta::Requirements" => 0,
    "Moose::Role" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Dist::Zilla::Role::PluginBundle" => 0,
    "Moose" => 0,
    "Test::More" => "1.001002"
  }
);


my %fallback_build_requires = (
  "Dist::Zilla::Role::PluginBundle" => 0,
  "Module::Build" => "0.4202",
  "Moose" => 0,
  "Test::More" => "1.001002"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
