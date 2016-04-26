#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use feature 'say';
use lib '/secure/Common/src/cpan';

use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long;
use Data::Dumper;
use LWP::UserAgent;
use File::Path;
use File::Slurp qw/read_file write_file/;

binmode(STDOUT, ':encoding(utf8)');

my $ua = LWP::UserAgent->new;
my %opts = (
    savedir => 'gfonts'
);
GetOptions (\%opts, 'savedir=s', 'help|h') or &usage;
&usage if $opts{help} or ! @ARGV;

localify ($_) for (@ARGV);
#localify("http://fonts.useso.com/css?family=Open+Sans:300,400,400italic,600,600italic,700,700italic");

sub usage {
print<<EOF
Usage:
    $0 http://fonts.useso.com/css?family=Open+Sans:300,400,400italic,600,600italic,700,700italic

Options:
    --savedir directory_name
              specify output directory name, defaults to gfonts

EOF
;
    exit;
}

sub localify {
    my ($url) = @_;
    my @fonts;

    say STDERR "Saving files to ", $opts{savedir};
    mkpath $opts{savedir} unless -d $opts{savedir};

    my $resp  = $ua->get ($url);
    if ($resp->is_success) {
        my $css = $resp->decoded_content;

        for (split /\n/, $css) {
            push @fonts, $1 if /url\(([^)]+)\)/;
        }

        for my $font (@fonts) {
            (my $name = $font) =~ s/.*\///;
            say STDERR ">> Downloading $font";
            URLDownloadToFile ($font, $opts{savedir} . '/' . $name);

            $css =~ s#$font#$name#;
        }
        
        write_file $opts{savedir} . '/main.css', $css;
        say STDERR 'Wrote main.css';
    } else {
        die "request error: " . $resp->status_line . "\n";
    }
}

sub URLDownloadToFile {
    my ($url, $file) = @_;
    my $resp = $ua->get ($url);
    if ($resp->is_success) {
        write_file ($file, $resp->decoded_content);
    } else {
        die "request error: " . $resp->status_line . "\n";
    }
}
