=head1 NAME

Acme::Test::Weather - Test the weather conditions for a user.

=head1 SYNOPSIS

  use Test::Weather;
  plan tests => 2;

  # You may only install something
  # when it's nice outside.

  &isnt_snowing();
  &isnt_cloudy();

  # output:

  1..2
  ok 1 - it's partly cloudy in Montreal, Canada
  not ok 2 - it's partly cloudy in Montreal, Canada
  #     Failed test (./t/mtl.t at line 5)
  #                   'Partly Cloudy'
  #           matches '(?i-xsm:\bcloudy)'
  # Looks like you failed 1 tests of 2.

=head1 DESCRIPTION

Test the weather conditions for a user.

The package determines a user's location by looking up their hostname /
IP address using the I<CAIDA::NetGeo::Client> package. 

Based on the data returned, weather conditions are polled using the 
I<Weather::Underground> package.

Because, you know, it may be important to your Perl module that it's
raining outside...

=cut

use strict;

package Acme::Test::Weather;
use base qw (Exporter);

$Acme::Test::Weather::VERSION = '0.1';

@Acme::Test::Weather::EXPORT = qw (plan

              is_sunny   isnt_sunny
              is_cloudy  isnt_cloudy
              is_snowing isnt_snowing
              is_raining isnt_raining

              eq_celsius    lt_celsius    gt_celsius
              eq_fahrenheit lt_fahrenheit gt_fahrenheit
              eq_humidity   lt_humidity   gt_humidity
              );

#

use Test::Builder;

use Sys::Hostname;
use Socket;

use CAIDA::NetGeoClient;
use Geography::Countries;
use Weather::Underground;

my $addr = gethostbyname(hostname);
my $ip   = inet_ntoa($addr);

my $test    = Test::Builder->new();

my $geo     = CAIDA::NetGeoClient->new();
my $record  = $geo->getRecord($ip);

my $city    = ucfirst(lc($record->{CITY}));

# Because things like 'Cambridge, US' cause
# wunderground.com to spazz out :-(

my $region  = ($record->{COUNTRY} eq "US") ? 
  ucfirst(lc($record->{STATE})) : country($record->{COUNTRY});

# Get the state if country eq US
my $place   = "$city, $region";

my $weather = Weather::Underground->new(place => $place);
my $data    = $weather->getweather()->[0];

use Data::Denter;
print Indent($data);

=head1 PACKAGE FUNCTIONS

=cut

=head2 &is_snowing()

=cut

sub is_snowing {
  $test->like($data->{conditions},qr/\bsnow/i,&_conditions());
};

=head2 &isnt_snowing()

=cut

sub isnt_snowing {
  $test->unlike($data->{conditions},qr/\bsnow/i,&_conditions());
};

=head2 &is_raining()

=cut

sub is_raining {
  $test->like($data->{conditions},qr/\brain/i,&_conditions());
};

=head2 &isnt_raining()

=cut

sub isnt_raining {
  $test->unlike($data->{conditions},qr/\brain/i,&_conditions());
};

=head2 &is_sunny()

=cut

sub is_sunny {
  $test->like($data->{conditions},qr/\bsun/i,&_conditions());
};

=head2 &isnt_sunny()

=cut

sub isnt_sunny {
  $test->unlike($data->{conditions},qr/\bsun/i,&_conditions());
};

=head2 &is_cloudy()

=cut

sub is_cloudy {
  $test->like($data->{conditions},qr/\bcloudy/i,&_conditions());
};

=head2 &isnt_cloudy()

=cut

sub isnt_cloudy {
  $test->unlike($data->{conditions},qr/\bcloudy/i,&_conditions());
};

=head2 &eq_celsius($int)

=cut

sub eq_celsius {
  $test->cmp_ok($data->{celsius},"==",$_[0],&_temp("celsius"));
}

=head2 &gt_celsius($int)

=cut

sub gt_celsius { 
  $test->cmp_ok($data->{celsius},">",$_[0],&_temp("celsius"));
}

=head2 &lt_celsius($int)

=cut

sub lt_celsius {
  $test->cmp_ok($data->{celsius},"<",$_[0],&_temp("celsius"));
}

=head2 &eq_fahrenheit($int)

=cut

sub eq_fahrenheit {
  $test->cmp_ok($data->{fahrenheit},"==",$_[0],&_temp("fahrenheit"));
}

=head2 &gt_fahrenheit($int)

=cut

sub gt_fahrenheit { 
  $test->cmp_ok($data->{fahrenheit},">",$_[0],&_temp("fahrenheit"));
}

=head2 &lt_fahrenheit($int)

=cut

sub lt_fahrenheit {
  $test->cmp_ok($data->{fahrenheit},"<",$_[0],&_temp("fahrenheit"));
}

=head2 &eq_humidity($int)

=cut

sub eq_humidity {
  $test->cmp_ok($data->{humidity},"==",$_[0],&_humidity());
}

=head2 &gt_humidity($int)

=cut

sub gt_humidity { 
  $test->cmp_ok($data->{humidity},">",$_[0],&_humidity());
}

=head2 &lt_humidity($int)

=cut

sub lt_humidity {
  $test->cmp_ok($data->{humidity},"<",$_[0],&_humidity());
}

sub _conditions { return "it's ".lc($data->{conditions})." in $place"; }

sub _humidity { return "the humidity in $place is $data->{humidity}"; }

sub _temp { my $m = shift; return "it $data->{$m} degrees $m in $place"; }

# Stuff I, ahem, borrowed from Test::More

sub plan {
    my(@plan) = @_;

    my $caller = caller;

    $test->exported_to($caller);

    my @imports = ();
    foreach my $idx (0..$#plan) {
        if( $plan[$idx] eq 'import' ) {
            my($tag, $imports) = splice @plan, $idx, 2;
            @imports = @$imports;
            last;
        }
    }

    $test->plan(@plan);

    __PACKAGE__->_export_to_level(1, __PACKAGE__, @imports);
}

sub _export_to_level
{
      my $pkg = shift;
      my $level = shift;
      (undef) = shift;                  # redundant arg
      my $callpkg = caller($level);
      $pkg->export($callpkg, @_);
}

=head1 VERSION

0.1

=head1 DATE

$Date: 2003/02/20 23:42:36 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

http://www.caida.org/tools/utilities/netgeo/NGAPI/index.xml

L<Weather::Underground>

http://search.cpan.org/dist/Acme

=head1 SHOUT-OUTS

It's all Kellan's fault.

=head1 BUGS

Not hard to imagine.

Please report all bugs via http://rt.cpan.org

=head1 LICENSE

Copyright (c) 2003, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself

=cut

return 1;

