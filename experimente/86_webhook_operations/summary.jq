# Numeric fields are generated internally. Identifiers and UTC timestamps contain no commas.
def rows: split("\n")[1:] | map(select(length>0) | split(","));
def observed($name): any($events[]; .event==$name);
($samples | rows | map({
    slot:(.[0]|tonumber),utc:.[1],ms:(.[2]|tonumber),pid:(.[3]|tonumber),
    rss:(.[5]|tonumber),hwm:(.[6]|tonumber),ticks:(.[7]|tonumber),
    fds:(.[8]|tonumber),threads:(.[9]|tonumber),pg_pss:(.[10]|tonumber),
    db:(.[11]|tonumber),connections:(.[12]|tonumber)
})) as $s |
($requests | rows | map(select(.[3]|startswith("pulse-")) |
    {id:.[3],status:.[4],ms:((.[5]|tonumber)*1000)})) as $probes |
([$s[]|{pid,ticks}] + [$retiring[]|{pid,ticks:.cpu_ticks}] |
    group_by(.pid) | map(map(.ticks)|max) | add / $run[0].clock_ticks_per_second) as $cpu |
([range(1; $s|length) as $i | $s[$i].ms - $s[$i-1].ms] | max // 0) as $gap |
([$events[] | select(.event=="completed")][0]) as $end |
{
    state:$status[0].state, started_utc:$run[0].started_utc,
    last_sample_utc:$s[-1].utc, finished_utc:($end.utc // null),
    elapsed_seconds:(($end.elapsed_ms // $s[-1].ms)/1000), samples:($s|length),
    max_sample_gap_seconds:($gap/1000),
    probe_creates:([$probes[]|select(.status=="201")]|length),
    probe_replays:([$probes[]|select(.status=="200")]|length),
    probe_p95_ms:($probes|map(.ms)|sort|.[((length*0.95|ceil)-1)]),
    webhook:{
        observed_processes:(([$s[].pid]+[$retiring[].pid])|unique|length),
        total_observed_cpu_seconds:$cpu, first_rss_kib:$s[0].rss,last_rss_kib:$s[-1].rss,
        peak_sampled_rss_kib:($s|map(.rss)|max),max_observed_hwm_kib:($s|map(.hwm)|max),
        max_sampled_fds:($s|map(.fds)|max),max_sampled_threads:($s|map(.threads)|max)
    },
    postgres:{
        peak_sampled_pss_kib:($s|map(.pg_pss)|max),
        first_database_bytes:$s[0].db,final_database_bytes:$s[-1].db,
        max_sampled_app_sessions:($s|map(.connections)|max)
    },
    interrupted_upgrade:observed("upgrade_killed_before_confirmation"),
    recovered_previous:observed("recovered_previous"),
    confirmed_upgrade:observed("candidate_confirmed"),
    database_outage:([$events[]|select(.event=="database_offline")|.detail][0]),
    database_recovery:([$events[]|select(.event=="database_recovered")|.detail][0]),
    final_database_check:$end.detail,
    verified_24_hours:(
        $status[0].state=="complete" and $end.elapsed_ms>=86400000 and $s[-1].ms>=86400000 and
        ($s | map(.slot))==[range(0;1441)] and $gap<=90000 and
        ($probes | map(.id) | unique)==([range(0;1441) | "pulse-\(.)"]|sort) and
        ($probes | group_by(.id) | all(.[];map(.status)==["201","200"])) and
        observed("rolled_back_to_previous") and observed("upgrade_killed_before_confirmation") and
        observed("recovered_previous") and observed("candidate_confirmed") and
        any($events[]; .event=="database_offline" and .detail.ready_status==503 and
            .detail.postgres_accepting==false and .detail.reply.error=="dependency_unavailable") and
        observed("database_recovered") and
        $end.detail.events_positions_quantity_value_cents=="1443,1443,4329,541125" and
        $end.detail.key_or_value_mismatches==0
    )
}
