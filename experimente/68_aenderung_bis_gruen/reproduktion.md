# Vergleich lokal wiederholen

Der Rückwärtspatch rekonstruiert die Quellfassung des Prüfers und Starters vor dem Versuch. Er wird ausschliesslich in der angelegten Arbeitskopie angewendet. Beide Installationen verwenden denselben Compiler und dasselbe unveränderte Sprach- und Operationskatalog-Pin. Die folgenden Befehle laufen im TIDE-Projektverzeichnis auf Linux x86-64.

```sh
stage=$(mktemp -d /tmp/tide68.XXXXXXXX)
exp=$PWD/experimente/68_aenderung_bis_gruen
mkdir "$stage/checkoutBefore"
cp -a Makefile tide tide.lock native apps lib workbench "$stage/checkoutBefore/"
patch -s -p1 -d "$stage/checkoutBefore" < "$exp/vorher.patch"
make -s -j3 -C "$stage/checkoutBefore" install DESTDIR="$stage/before"
make -s -j3 install DESTDIR="$stage/after"
cp -a apps/report_packages "$stage/project"
cp tide.lock "$stage/project/tide.lock"
cp -a "$exp/python" "$stage/python"
awk '/^```perl$/ {inside=1; next} /^```$/ {inside=0} inside' "$exp/reproduktion.md" > "$stage/redgreen.pl"
for mode in paired checkout; do
  bwrap --unshare-net --ro-bind / / --bind "$stage" "$stage" --dev /dev --proc /proc \
    taskset -c 24 perl "$stage/redgreen.pl" "$stage" "$mode"
done
```

Der Versuch nutzte ein tmpfs unter `/tmp`. Kern 24 muss auf dem Vergleichsrechner verfügbar sein. Die Dateien `paired.json` und `checkout.json` im temporären Verzeichnis enthalten alle gemessenen Einzelzeiten in Millisekunden. Die Perl-Standardbibliothek stellt die monotone Uhr für die externe Messung bereit. Die fachlichen Tests laufen durch den installierten TIDE-Prüfer bzw. den CPython-Vergleich.

```perl
use strict;
use warnings;
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use JSON::PP qw(decode_json encode_json);

my ($stage, $mode) = @ARGV;
my $report = "$stage/project/stream_report.tide";
my %module = (
    tide => "$stage/project/vendor/measurements/1.3.0/package.tide",
    python => "$stage/python/measurements/__init__.py",
);
my %command = (
    before => ["$stage/before/usr/local/bin/tide", "test", $report],
    after => ["$stage/after/usr/local/bin/tide", "test", $report],
    checkoutBefore => ["$stage/checkoutBefore/tide", "test", $report],
    checkoutAfter => ["$ENV{PWD}/tide", "test", $report],
);
my $python = ["/usr/bin/python3", "-E", "-S", "$stage/python/test_report.py"];
$command{pythonA} = $command{pythonB} = $python;

my (%green, %red);
for my $lang (keys %module) {
    open my $source, '<', $module{$lang} or die $!;
    local $/;
    $green{$lang} = <$source>;
    close $source or die $!;
}
%red = %green;
$red{tide} =~ s/^decode_measurement line row$/decode_measurement line (+ row 1)/m or die;
$red{python} =~ s/return decode_measurement\(raw, row\)/return decode_measurement(raw, row + 1)/ or die;

sub save_source {
    my ($path, $text) = @_;
    open my $file, '>', "$path.saving" or die $!;
    print $file $text or die $!;
    close $file or die $!;
    rename "$path.saving", $path or die $!;
}

sub run_suite {
    my ($cmd) = @_;
    my $pid = open(my $output, '-|');
    die $! unless defined $pid;
    if (!$pid) {
        open STDERR, '>&', \*STDOUT or die $!;
        exec {$cmd->[0]} @$cmd or die $!;
    }
    local $/;
    my $message = <$output>;
    close $output;
    return ($?, $message);
}

my @arms = $mode eq 'paired' ? qw(before after pythonA pythonB)
         : $mode eq 'checkout' ? qw(checkoutBefore checkoutAfter)
         : die "Expected paired or checkout";
my @samples;
for my $block (0..71) {
    my @order = map { $arms[($_ + $block) % @arms] } 0..$#arms;
    @order = reverse @order if int($block / @arms) % 2;
    for my $slot (0..$#order) {
        my $arm = $order[$slot];
        my $lang = $arm =~ /^python/ ? 'python' : 'tide';
        save_source($module{$lang}, $red{$lang});
        my ($status, $message) = run_suite($command{$arm});
        die "Missing red test: $arm $message" unless $status == 256;
        if ($lang eq 'tide') {
            my $failure = decode_json($message);
            die $message unless $failure->{example} eq 'invalid'
                && $failure->{expected}{input_line} == 2
                && $failure->{actual}{input_line} == 3;
        } else {
            die $message unless $message =~ /AssertionError/ && $message =~ /'input_line': 3/;
        }

        my $start = clock_gettime(CLOCK_MONOTONIC);
        save_source($module{$lang}, $green{$lang});
        ($status, $message) = run_suite($command{$arm});
        die "Missing green test: $arm $message" unless $status == 0 && $message eq "{\"passed\":7}\n";
        my $ms = 1000 * (clock_gettime(CLOCK_MONOTONIC) - $start);
        push @samples, {block => $block - 7, arm => $arm, order => $slot + 1,
                        ms => 0 + sprintf('%.6f', $ms)} if $block >= 8;
    }
}
open my $out, '>', "$stage/$mode.json" or die $!;
print $out encode_json(\@samples);
close $out or die $!;
```
