#!/usr/bin/perl
use strict;
use warnings;

use Time::Local 'timelocal';
use JSON::XS;
use CGI qw(:standard :html3 escapeHTML);
use IO::Interface::Simple;

my $cur_time = time;
my $vardir = "/var/local/";

sub newest_file {
    my $path = shift;
    my $cur_time = shift;
    my $suffix = shift;
    $suffix = ($suffix) ? "_".$suffix : "";

    opendir my $dir, "$vardir$path" or die "Cannot open directory: $!";
    my @files = grep { /$suffix$/ } grep { !/^\./ } readdir $dir;
    closedir $dir;

    my %time = map {
            $_ =~ /^.*?(\d{4})\-(\d{2})\-(\d{2})\+(\d{2}):(\d{2}):(\d{2})$suffix$/;
            $_ => timelocal($6, $5, $4, $3, $2-1, $1)
        } @files;
    keys %time;       # reset the each iterator

    my ($newest_key, $newest_val) = each %time;
    while (my ($key, $val) = each %time) {
        if ($val > $newest_val) {
            $newest_val = $val;
            $newest_key = $key;
        }
    }
    if ( ($cur_time - $time{$newest_key}) <= 60 ) {
        return $newest_key
    }
    else {
        return undef
    }
}

sub two_latest_files {
    my $path = shift;
    my $cur_time = shift;

    opendir my $dir, "$vardir$path" or die "Cannot open directory: $!";
    my @files = grep { !/^\./ } readdir $dir;
    closedir $dir;

    my %time = map {
            $_ =~ /^.*?(\d{4})\-(\d{2})\-(\d{2})\+(\d{2}):(\d{2}):(\d{2})$/;
        $_ => timelocal($6, $5, $4, $3, $2-1, $1);
        } @files;

    my @sorted_time = sort {
        $time{$b}
            <=>
        $time{$a}
    } keys %time;

    my $newest = shift @sorted_time;
    my $almost_newest = shift @sorted_time;

    if ( ($cur_time - $time{$newest}) <= 60 ) {
        return ($newest, $almost_newest)
    }
    else {
        return undef
    }
}

#here's a stylesheet incorporated directly into the page
my $newStyle=<<END;
<!--
html {
    font-family: monospace;
    padding:0; margin:0;
}
-->
END

my $q = CGI->new;
my %headers = map { $_ => $q->http($_) } $q->http();

print $q->header('text/html; charset=UTF-8');
print $q->start_html(
        -title => 'Monitor',
        -style => {
            -code => $newStyle
        });

print $q->p(sprintf("Client adress and port: %s:%s\n",
                    $headers{"HTTP_X_REAL_IP"},
                    $headers{"HTTP_X_REAL_PORT"}));

print $q->p(sprintf("Nginx version %s on %s:%s\n",
                    $headers{"HTTP_X_NGX_VERSION"},
                    $headers{"HTTP_SERVER_HOST"},
                    $headers{"HTTP_SERVER_PORT"}));

# Get local IPs and ifaces
my @interfaces = IO::Interface::Simple->interfaces;
# my @del_indexes = grep { $interfaces[$_] eq "lo" } 0..$#interfaces;
# splice(@interfaces, $_, 1) foreach (@del_indexes);
my @ip = map { $_->address } @interfaces;

my $loadaverage = "loadaverage/";
my $loadcpu = "loadcpu/";
my $iostat = "iostat/";
my $diskfree = "diskfree/";
my $toptalkers = "top-talkers/";
my $loadnet = "loadnet/";
my $netconn = "netconn/";

if (my $newest_loadaverage = newest_file($loadaverage, $cur_time)) {

    my @fields_loadaverage_table = (
        "1 min",
        "5 min",
        "15 min"
    );

    open(my $fh_loadaverage, '<', "$vardir$loadaverage$newest_loadaverage");
    my $line = <$fh_loadaverage>;
    close($fh_loadaverage);

    my @splitted_line = split /:/, $line;
    $splitted_line[1] =~ s/^\s+|\s+$//g;
    $splitted_line[1] =~ s/\s+/ /g;
    my @load_values = split / /, pop @splitted_line;
    my $one = $load_values[0] =~ s/,$//g;
    my $five = $load_values[1] =~ s/,$//g;
    my $fifteen = $load_values[2];

    my $table_content = [ {}, \@load_values ];

    if ($one < 10 || $five < 10 || $fifteen < 10 ||
        $one > 90 || $five > 90 || $fifteen > 90) {
        $table_content->[0] = {-bgcolor => 'red'};
    }
    elsif ( $one < 20 || $five < 20 || $fifteen < 20 ||
            $one > 80 || $five > 80 || $fifteen > 80) {
        $table_content->[0] = {-bgcolor => 'yellow'};
    }
    else {
        $table_content->[0] = {-bgcolor => 'green'};
    }

    print $q->table({ -border => 0, -style => "float:left;" },
        caption("Load average"),
        Tr({-align=>'LEFT',-valign=>'CENTER'},
            [
                $q->th(\@fields_loadaverage_table),
                $q->td(@$table_content)
            ]
            )
        );
}
else {
    print "Something goes wrong! Daemon load average is dead\n"
}

if (my $newest_loadcpu = newest_file($loadcpu, $cur_time)) {

    # Open last file and decode JSON
    open(my $fh_loadcpu, '<', "$vardir$loadcpu$newest_loadcpu");
    my $loadcpu_ref = JSON::XS->new->utf8->decode(<$fh_loadcpu>);
    close($fh_loadcpu);

    my @fields_loadcpu_table = (
        "CPU",
        "\%usr",
        "\%sys",
        "\%idle",
        "\%iowait"
    );
    my @loadcpu_lines;

    foreach (keys %$loadcpu_ref) {
        my $key = $_;
        my @loadcpu_out_array;

        foreach (@fields_loadcpu_table) {
            if ($_ eq "CPU") {
                push @loadcpu_out_array, $key
            }
            elsif ($_ eq "\%usr") {
                my $usr = $loadcpu_ref->{$key}->{$_};
                $usr =~ s/,/\./;
                my $nice = $loadcpu_ref->{$key}->{"\%nice"};
                $nice =~ s/,/\./;
                push(@loadcpu_out_array, $usr + $nice)
            }
            else {
                push @loadcpu_out_array, $loadcpu_ref->{$key}->{$_};
            }
        }
        push @loadcpu_lines, \@loadcpu_out_array;
    }

    print $q->table({ -border => 0, -style => "float:left;" },
        caption("CPU load"),
        Tr({-align=>'LEFT',-valign=>'CENTER'},
            [
                $q->th(\@fields_loadcpu_table),
                map {
                    my $idle = $_->[3];
                    $idle =~ s/,/\./;
                    my $iowait = $_->[4];
                    $iowait =~ s/,/\./;
                    if ($iowait > 90 || $idle > 90) {
                        $q->td({-bgcolor=>'red'}, \@{$_})
                    }
                    elsif ($iowait > 80 || $idle > 80) {
                        $q->td({-bgcolor=>'yellow'}, \@{$_})
                    }
                    else {
                       $q->td(\@{$_})
                    }
                } @loadcpu_lines
            ]
            )
        );
}

print $q->br({ -style => "clear:both" });
print $q->br({ -style => "clear:both" });

if (my $newest_iostat = newest_file($iostat, $cur_time)) {

    # Open last file and decode JSON
    open(my $fh_iostat, '<', "$vardir$iostat$newest_iostat");
    my $iostat_ref = JSON::XS->new->utf8->decode(<$fh_iostat>);
    close($fh_iostat);

    my @fields_iostat_table = (
        "Disk",
        "MB/s read",
        "MB/s write",
        "MB read",
        "MB write",
        "tps"
    );
    my @iostat_lines = [];

    # Going through JSON
    foreach (keys %$iostat_ref) {
        my $key = $_;
        my @iostat_out_array;

        # Got the disk name and push to output values of disk's hash
        foreach (@fields_iostat_table) {
            if ($_ eq "Disk") {
                push @iostat_out_array, $key
            }
            else {
                push @iostat_out_array, $iostat_ref->{$key}->{$_};
            }
        }
        push @iostat_lines, \@iostat_out_array;
        # print $q->span(sprintf($pattern_iostat_table, @iostat_out_array));
    }

    print $q->table({ -border => 0 },
        caption("IO stat"),
        Tr({-align=>'LEFT',-valign=>'CENTER'},
            [
               $q->th(\@fields_iostat_table),
               map {
                   $q->td(\@{$_})
               } @iostat_lines
            ]
            )
        );
}
else {
    print "Something goes wrong! Daemon iostat is dead\n"
}

print $q->br();

if (my $newest_diskfree = newest_file($diskfree, $cur_time)) {

    open(my $fh_diskfree, '<', "$vardir$diskfree$newest_diskfree");
    my $line = <$fh_diskfree>;
    my @diskfree_lines;

    $line =~ s/^\s+|\s+$//g;
    $line =~ s/\s+/ /g;
    my @fields_diskfree_table = split / /, $line;

    while ($line = <$fh_diskfree>) {
        $line =~ s/^\s+|\s+$//g;
        $line =~ s/\s+/ /g;
        my @diskfree_out_array = split / /, $line;
        push @diskfree_lines, \@diskfree_out_array;
    }
    close($fh_diskfree);

    print $q->table({ -border => 0 },
        caption("Disk stat"),
        Tr({-align=>'LEFT',-valign=>'CENTER'},
            [
                $q->th(\@fields_diskfree_table),
                map {
                    my $inode_usage = @{$_}[4];
                    $inode_usage =~ s/%//;
                    my $block_usage = @{$_}[7];
                    $block_usage =~ s/%//;
                    if ($inode_usage > 90 || $block_usage > 90) {
                        $q->td({-bgcolor=>'red'}, \@{$_})
                    }
                    elsif ($inode_usage > 80 || $block_usage > 80) {
                        $q->td({-bgcolor=>'yellow'}, \@{$_})
                    }
                    else {
                       $q->td(\@{$_})
                    }
               } @diskfree_lines
            ]
            )
        );

}
else {
    print "Something goes wrong! Daemon diskfree is dead\n"
}

print $q->br();

if (my $newest_toptalkers = newest_file($toptalkers, $cur_time)) {


    open(my $fh_toptalkers, '<', "$vardir$toptalkers$newest_toptalkers");
    my $toptalkers_ref = JSON::XS->new->utf8->decode(<$fh_toptalkers>);
    close($fh_toptalkers);

    # ----------------------------------------------------------------------- #
    # ----------------------- top talkers by protocol ----------------------- #
    # ----------------------------------------------------------------------- #

    my @proto_array = (
        "TCP",
        "UDP",
        "ICMP"
    );

    my %proto_toptalkers_fields = (
        "TCP" => [
            "foreign_ip",
            "percentage"
        ],
        "UDP" => [
            "foreign_ip",
            "percentage"
        ],
        "ICMP" => [
            "foreign_ip",
            "percentage"
        ]
    );

    my %proto_toptalkers_hash = (
        "TCP" => {},
        "UDP" => {},
        "ICMP" => {}
    );
    my %proto_toptalkers_overall = (
        "TCP" => 0,
        "UDP" => 0,
        "ICMP" => 0
    );

    foreach (keys %$toptalkers_ref) {
        my $ip_src = $toptalkers_ref->{$_}->{"ip_src"};
        my $ip_dst = $toptalkers_ref->{$_}->{"ip_dst"};
        my $proto = $toptalkers_ref->{$_}->{"proto"};
        my $ip_to_add;

        $proto_toptalkers_overall{$proto}++;

        if (! grep {$_ eq $ip_src} @ip) {
            $ip_to_add = $ip_src;
        }
        elsif (! grep {$_ eq $ip_dst} @ip) {
            $ip_to_add = $ip_dst;
        }
        else {
            next
        }

        if (! $proto_toptalkers_hash{$proto}{$ip_to_add}) {
            $proto_toptalkers_hash{$proto}{$ip_to_add} = 1
        }
        else {
            $proto_toptalkers_hash{$proto}{$ip_to_add}++
        }
    }

    my $table_content_proto = {};

    foreach my $proto (@proto_array) {
        my %hash = map {
            my $percentage = sprintf("%.2f", 100 * $proto_toptalkers_hash{$proto}{$_} / $proto_toptalkers_overall{$proto});
            $_ => $percentage
        } keys %{$proto_toptalkers_hash{$proto}};
        $table_content_proto->{$proto} = \%hash;
    }

    foreach (@proto_array) {
        my $proto = $_;
        my @sorted_ip = sort {
            $table_content_proto->{$proto}->{$b}
                <=>
            $table_content_proto->{$proto}->{$a}
        } keys %{$table_content_proto->{$proto}};

        print $q->table({ -border => 0, -style => "float:left;" },
            caption("<b>$proto</b> 10 top talkers"),
            Tr({-align=>'LEFT',-valign=>'CENTER'},
                [
                    $q->th($proto_toptalkers_fields{$proto}),
                    map {
                        $q->td([$_, $table_content_proto->{$proto}->{$_}])
                    } @sorted_ip
                ]
                )
            );
    }

    print $q->br({ -style => "clear:both" });
    print $q->br({ -style => "clear:both" });

    # ----------------------------------------------------------------------- #
    # ----------------------- top talkers by packages ----------------------- #
    # ----------------------------------------------------------------------- #

    my @pack_toptalkers_fields = (
        "src/dst ip",
        "src/dst port",
        "protocol",
        "packages per session"
    );

    my %pack_toptalkers_hash;
    my @pack_toptalkers_out;

    foreach (keys %$toptalkers_ref) {
        my $ip_src = $toptalkers_ref->{$_}->{"ip_src"};
        my $ip_dst = $toptalkers_ref->{$_}->{"ip_dst"};
        my $port_src = $toptalkers_ref->{$_}->{"port_src"};
        my $port_dst = $toptalkers_ref->{$_}->{"port_dst"};
        my $proto = $toptalkers_ref->{$_}->{"proto"};
        my $ip_to_add;
        my $port_to_add = "";

        if (! grep {$_ eq $ip_src} @ip) {
            $ip_to_add = $ip_src;
            if ($port_src) {
                $port_to_add = $port_src;
            }
        }
        elsif (! grep {$_ eq $ip_dst} @ip) {
            $ip_to_add = $ip_dst;
            if ($port_dst) {
                $port_to_add = $port_dst;
            }
        }
        else {
            next
        }

        if (! $pack_toptalkers_hash{$ip_to_add}->{$port_to_add}->{$proto}) {
            $pack_toptalkers_hash{$ip_to_add}->{$port_to_add}->{$proto} = 1
        }
        else {
            $pack_toptalkers_hash{$ip_to_add}->{$port_to_add}->{$proto}++
        }
    }

    foreach (keys %pack_toptalkers_hash) {
        my $ip = $_;
        foreach (keys %{$pack_toptalkers_hash{$ip}}) {
            my $port = $_;
            foreach (keys %{$pack_toptalkers_hash{$ip}->{$port}}) {
                my $proto = $_;
                my $packs = $pack_toptalkers_hash{$ip}->{$port}->{$proto};
                my $packs_array_out_ref = [
                    $ip,
                    $port,
                    $proto,
                    $packs
                ];
                push @pack_toptalkers_out, $packs_array_out_ref
            }
        }
    }

    my @pack_toptalkers_out_sorted = sort {
        $b->[3]
            <=>
        $a->[3]
    } @pack_toptalkers_out;
    splice @pack_toptalkers_out_sorted, 10;

    print $q->table({ -border => 0, -style => "float:left;"},
        caption("<b>Packages</b> 10 top talkers"),
        Tr({-align=>'LEFT',-valign=>'CENTER'},
            [
                $q->th(\@pack_toptalkers_fields),
                map {
                    $q->td($_)
                } @pack_toptalkers_out_sorted
            ]
            )
        );

    # ----------------------------------------------------------------------- #
    # ------------------------- top talkers by data ------------------------- #
    # ----------------------------------------------------------------------- #

    my @data_toptalkers_fields = (
        "src/dst ip",
        "src/dst port",
        "protocol",
        "bytes per session"
    );

    my %data_toptalkers_hash;
    my @data_toptalkers_out;

    foreach (keys %$toptalkers_ref) {
        my $ip_src = $toptalkers_ref->{$_}->{"ip_src"};
        my $ip_dst = $toptalkers_ref->{$_}->{"ip_dst"};
        my $port_src = $toptalkers_ref->{$_}->{"port_src"};
        my $port_dst = $toptalkers_ref->{$_}->{"port_dst"};
        my $proto = $toptalkers_ref->{$_}->{"proto"};
        my $length = $toptalkers_ref->{$_}->{"length"};
        my $ip_to_add;
        my $port_to_add = "";

        if (! grep {$_ eq $ip_src} @ip) {
            $ip_to_add = $ip_src;
            if ($port_src) {
                $port_to_add = $port_src;
            }
        }
        elsif (! grep {$_ eq $ip_dst} @ip) {
            $ip_to_add = $ip_dst;
            if ($port_dst) {
                $port_to_add = $port_dst;
            }
        }
        else {
            next
        }

        # if (! $data_toptalkers_hash{$ip_to_add}->{$port_to_add}->{$proto}) {
            $data_toptalkers_hash{$ip_to_add}->{$port_to_add}->{$proto} += $length;
        # }
        # else {
        #     $data_toptalkers_hash{$ip_to_add}->{$port_to_add}->{$proto}++
        # }
    }

    foreach (keys %data_toptalkers_hash) {
        my $ip = $_;
        foreach (keys %{$data_toptalkers_hash{$ip}}) {
            my $port = $_;
            foreach (keys %{$data_toptalkers_hash{$ip}->{$port}}) {
                my $proto = $_;
                my $data = $data_toptalkers_hash{$ip}->{$port}->{$proto};
                my $data_array_out_ref = [
                    $ip,
                    $port,
                    $proto,
                    $data
                ];
                push @data_toptalkers_out, $data_array_out_ref
            }
        }
    }

    my @data_toptalkers_out_sorted = sort {
        $b->[3]
            <=>
        $a->[3]
    } @data_toptalkers_out;
    splice @data_toptalkers_out_sorted, 10;

    print $q->table({ -border => 0, -style => "float:left;"},
        caption("<b>Datum</b> 10 top talkers"),
        Tr({-align=>'LEFT',-valign=>'CENTER'},
            [
                $q->th(\@data_toptalkers_fields),
                map {
                    $q->td($_)
                } @data_toptalkers_out_sorted
            ]
            )
        );


    print $q->br({ -style => "clear:both" });
    print $q->br({ -style => "clear:both" });
}
else {
    print "Something goes wrong! Daemon top-talkers is dead\n"
}

if ( (my $newest, my $almost_newest) = two_latest_files($loadnet, $cur_time)) {

    my %loadnet_table_fields = (
        "Recieve" => [
            "bytes",
            "packs",
            "errs",
            "drop",
            "fifo",
            "frame",
            "compr",
            "mcast"
        ],
        "Transmit" => [
            "bytes",
            "packs",
            "errs",
            "drop",
            "fifo",
            "colls",
            "carr",
            "compr"
        ]
    );
    my %translation_hash = (
        "packs" => "packets",
        "compr" => "compressed",
        "mcast" => "multicast",
        "carr"  => "carrier"

    );
    my @loadnet_table_header = (
        "Recieve",
        "Transmit"
    );

    my ($if, $dir, $field) = ();

    # Open last file and decode JSON
    open(my $fh_loadnet_newest, '<', "$vardir$loadnet$newest");
    my $loadnet_new_ref = JSON::XS->new->utf8->decode(<$fh_loadnet_newest>);
    close($fh_loadnet_newest);

    # Open last file and decode JSON
    open(my $fh_loadnet_almost, '<', "$vardir$loadnet$almost_newest");
    my $loadnet_almost_ref = JSON::XS->new->utf8->decode(<$fh_loadnet_almost>);
    close($fh_loadnet_almost);

    my $loadnet_hash_ref;

    foreach (keys %$loadnet_new_ref) {
        $if = $_;
        foreach (keys %{$loadnet_new_ref->{$if}}) {
            $dir = $_;
            foreach (keys %{$loadnet_new_ref->{$if}->{$dir}}) {
                $field = $_;
                $loadnet_hash_ref->{$if}->{$dir}->{$field} =
                    $loadnet_new_ref->{$if}->{$dir}->{$field} -
                    $loadnet_almost_ref->{$if}->{$dir}->{$field}
            }
        }
    }

    print $q->table({ -border => 0, -style => "float:left;"},
        caption("Net load on ifaces"),
        $q->thead(
            $q->td(),
            map {
                $q->th({
                    -class   => "span",
                    -colspan => "8",
                    -scope   => "colgroup",
                    -align   => "left"
                }, $_)
            } @loadnet_table_header
            ),
        $q->tbody(
            $q->Tr(
                $q->td(),
                map {
                    map {
                        $q->th({
                            -scope =>"col"
                        }, $_)
                    } @{$loadnet_table_fields{$_}}
                } @loadnet_table_header
            ),
            map {
                $if = $_;
                $q->Tr(
                    $q->th({-align => "right"}, $if),
                    map {
                        $dir = $_;
                        map {
                            $field = ($translation_hash{$_}) ? $translation_hash{$_} : $_;
                            $q->td({
                                -align => "left"
                            }, $loadnet_hash_ref->{$if}->{$dir}->{$field})
                        } @{$loadnet_table_fields{$dir}}
                    } @loadnet_table_header
                )
            } sort keys %$loadnet_hash_ref
        )
    );
}
else {
    $q->p("Something wen wrong! Daemon loadnet is dead")
}

print $q->br({ -style => "clear:both" });
print $q->br({ -style => "clear:both" });

my $netstat_file = newest_file($netconn, $cur_time, "netstat");
my $ss_file = newest_file($netconn, $cur_time, "ss");
if ($ss_file && $netstat_file) {

    my @netconn_ss_header = (
        "port",
        "proto",
        "state"
    );
    my @netconn_netstat_header = (
        "local_port",
        "foreign_port",
        "proto",
        "state"
    );
    my %states_hash;
    my $num;
    my $proto;
    my $state;

    # Open last file and decode JSON
    open(my $fh_netstat, '<', "$vardir$netconn$netstat_file");
    my $netconn_netstat_ref = JSON::XS->new->utf8->decode(<$fh_netstat>);
    close($fh_netstat);

    # Open last file and decode JSON
    open(my $fh_ss, '<', "$vardir$netconn$ss_file");
    my $netconn_ss_ref = JSON::XS->new->utf8->decode(<$fh_ss>);
    close($fh_ss);

    foreach (keys %$netconn_netstat_ref) {
        $proto = $netconn_netstat_ref->{$_}->{"proto"};
        $state = $netconn_netstat_ref->{$_}->{"state"};
        if ($proto eq "tcp") {
            if (! $states_hash{$state}) {
                $states_hash{$state} = 1
            }
            else {
                $states_hash{$state}++
            }
        }
    }

    print $q->table({ -border => 0, -style => "float:left;"},
        caption("Listening ports"),
        $q->thead(
            map {
                $q->th({ -align => "left"}, $_)
            } @netconn_ss_header
        ),
        $q->tbody(
            map {
                $num = $_;
                $q->Tr(
                    map {
                        $q->td($netconn_ss_ref->{$num}->{$_})
                    } @netconn_ss_header
                )
            } sort {
                $netconn_ss_ref->{$a}->{"port"}
                    <=>
                $netconn_ss_ref->{$b}->{"port"}
            } keys %$netconn_ss_ref
        )
    );

    my @sorted_keys_netstat = sort {
        $netconn_netstat_ref->{$a}->{"local_port"}
            <=>
        $netconn_netstat_ref->{$b}->{"local_port"}
    } keys %$netconn_netstat_ref;

    my @netconn_netstat_body = map {
        $num = $_;
        $q->Tr(
            $q->td(),
            map {
                $q->td($netconn_netstat_ref->{$num}->{$_})
            } @netconn_netstat_header
        )
    } @sorted_keys_netstat;
    push @netconn_netstat_body, map {
        $q->Tr(
            $q->th({ -align => "right" }, $_),
            $q->td("$states_hash{$_} connections"),
        )
    } keys %states_hash;

    print $q->table({ -border => 0, -style => "float:left;"},
        caption("Port states"),
        $q->thead(
            $q->th(),
            map {
                $q->th({ -align => "left"}, $_)
            } @netconn_netstat_header
        ),
        $q->tbody(
            @netconn_netstat_body
        )
    )
}
else {

}

print $q->end_html;                  # end the HTML
