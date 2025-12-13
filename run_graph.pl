#!/usr/bin/perl
use strict;
use warnings;
use File::Spec;
use Cwd;
use Getopt::Long;

my ($max, $urls) = (300, "urls.txt");
GetOptions(
    "max=i" => \$max,
    "urls=s" => \$urls
);

# paths
my $cwd = getcwd();
my $json_file = File::Spec->catfile($cwd, "./data/graph.json");
my $html_file = File::Spec->catfile($cwd, "graph_clustered.html");

# run the crawler
print "running crawler now\n";
system("perl crawler.pl --urls $urls --json $json_file --max $max") == 0
    or die "crawler failed, alexdebug 1 something went wrong";

# open HTML visualization in default browser
print "opening naive graph in browser, this SHOULDN'T work, but if it does great\n";

my $open_cmd = "open";

system("$open_cmd $html_file") == 0
    or warn "failed to open browser.";
