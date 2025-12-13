#!/usr/bin/perl
use strict;
use warnings;

use URI;
use LWP::UserAgent;
use Getopt::Long;
use Digest::MD5 qw(md5_hex);
use JSON;
use Time::HiRes qw(gettimeofday tv_interval);

# default cli config
my ($url_file, $json_file, $max_pages) = ("urls.txt", "graph.json", 150);

# parse cli contents if passed in
GetOptions(
    "urls=s" => \$url_file,
    "json=s" => \$json_file,
    "max=i"  => \$max_pages,
);

# open file with starting urls
open(my $uf, "<", $url_file) or die "can't open $url_file";
my @seed_urls = map { chomp; $_ } <$uf>;
close($uf);

my %visited;
my %queued;
my %nodes;
my @all_links;
my %queues;

sub domain_of {
    my $raw = shift;
    my $u = eval { URI->new($raw) };
    return "unknown"
        unless $u && $u->scheme && ($u->scheme eq "http" || $u->scheme eq "https");
    my $h = eval { $u->host };
    return $h || "unknown";
}

sub normalize_url {
    my ($base, $link) = @_;
    return unless defined $link;
    $link =~ s/^\s+|\s+$//g;
    return if $link eq '';
    return if $link =~ /^(javascript|mailto|tel|data):/i;
    $link = "http:$link" if $link =~ m{^//};
    my $uri = eval { URI->new_abs($link, $base) };
    return unless $uri && $uri->scheme =~ /^https?$/i;
    $uri->fragment(undef);
    $uri->query(undef);
    return $uri->as_string;
}

sub color_for_domain {
    my ($d) = @_;
    my $hash = hex(substr(md5_hex($d), 0, 6));
    my $hue  = $hash % 360;
    return "hsl($hue,70%,60%)";
}

for my $u (@seed_urls) {
    next unless defined $u && $u ne '';
    my $d = domain_of($u);
    push @{ $queues{$d} }, $u;
    $queued{$u} = 1;
}

my $ua = LWP::UserAgent->new(
    timeout => 8,
    agent   => "Mozilla/5.0"
);

my $pages_crawled = 0;

DOMAIN:
while ($pages_crawled < $max_pages) {
    for my $domain (sort keys %queues) {
        next unless @{ $queues{$domain} };
        my $url = shift @{ $queues{$domain} };
        next unless defined $url;
        next if $visited{$url}++;
        next if $url =~ /\.(css|json|ico|png|jpg|jpeg|gif|svg|webp)$/i;

        $pages_crawled++;
        print "[$pages_crawled/$max_pages] Crawling: $url\n";

        $nodes{$url} = {
            id => $url,
            name => $url,
            group => $domain,
            color => color_for_domain($domain),
            playcount => 1,
            status => "unknown",
            http_code => undef,
            response_time_ms => undef
        };

        my $start = [gettimeofday()];
        my $res = eval { $ua->get($url) };
        my $elapsed = tv_interval($start);
        my $rt_ms = int($elapsed * 1000);

        if (!$res) {
            $nodes{$url}{status} = "dead";
            $nodes{$url}{http_code} = 0;
            $nodes{$url}{response_time_ms} = $rt_ms;
            warn "request failed for $url\n";
            next;
        }

        $nodes{$url}{http_code} = $res->code;
        $nodes{$url}{response_time_ms} = $rt_ms;
        my $code = $res->code;

        if ($code >= 200 && $code < 400) {
            $nodes{$url}{status} = "alive";

            # Only extract links for 200–299 pages
            if ($code >= 200 && $code < 300) {
                my $html = $res->decoded_content;
                my @found = ($html =~ /href=["']([^"']+)["']/g);

                for my $f (@found) {
                    my $abs = normalize_url($url, $f);
                    next unless $abs;
                    next if $abs =~ /\.(pdf|js|ico|png|jpg|jpeg|gif|svg|webp|css|json)$/i;
                    my $d2 = domain_of($abs);
                    push @{ $queues{$d2} }, $abs
                        unless $visited{$abs} || $queued{$abs};
                    $queued{$abs} = 1;
                    push @all_links, { source => $url, target => $abs };
                }
            }
        }
        elsif ($code >= 400 && $code < 500) {
            $nodes{$url}{status} = "dead";
        }
        elsif ($code >= 500) {
            $nodes{$url}{status} = "server_error";
        }
        else {
            $nodes{$url}{status} = "dead";
            warn "HTTP $code for $url\n";
        }

        last DOMAIN if $pages_crawled >= $max_pages;
    }
}

my @links = grep {
    exists $nodes{$_->{source}} && exists $nodes{$_->{target}}
} @all_links;

my %seen_links;
@links = grep {
    !$seen_links{ $_->{source} . "|" . $_->{target} }++
} @links;

for my $node (values %nodes) {
    $node->{playcount} = scalar(
        grep { $_->{source} eq $node->{id} } @links
    );
    $node->{playcount} = 1 if $node->{playcount} == 0;
}

my $json_obj = {
    nodes => [ values %nodes ],
    links => \@links
};

open(my $jf, ">", $json_file) or die "Cannot write $json_file";
print $jf encode_json($json_obj);
close($jf);

print "\nJSON graph successfully saved to $json_file\n";
print "nodes: " . scalar(keys %nodes) . "\n";
print "links: " . scalar(@links) . "\n";
