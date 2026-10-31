#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/verify.sh"
LAB_NUM=00
echo "Lab 00: hello pipeline"

spans_in()   { eq "$(selfmetric otelcol_receiver_accepted_spans)" 20; }
points_in()  { eq "$(selfmetric otelcol_receiver_accepted_metric_points)" 10; }
logs_in()    { eq "$(selfmetric otelcol_receiver_accepted_log_records)" 10; }
spans_out()  { eq "$(selfmetric otelcol_exporter_sent_spans 'exporter="debug')" 20; }
points_out() { eq "$(selfmetric otelcol_exporter_sent_metric_points 'exporter="debug')" 10; }
logs_out()   { eq "$(selfmetric otelcol_exporter_sent_log_records 'exporter="debug')" 10; }
limiter()    { ge "$(selfmetric otelcol_processor_incoming_items 'processor="memory_limiter"')" 1; }
batched()    { ge "$(selfmetric otelcol_processor_batch_batch_send_size_count)" 1; }

eventually 10 "OTLP receiver accepted 20 spans"            spans_in
eventually 10 "OTLP receiver accepted 10 metric points"    points_in
eventually 10 "OTLP receiver accepted 10 log records"      logs_in
eventually 10 "debug exporter sent 20 spans"               spans_out
eventually 10 "debug exporter sent 10 metric points"       points_out
eventually 10 "debug exporter sent 10 log records"         logs_out
check         "memory_limiter processor is in a pipeline"  limiter
check         "batch processor is in a pipeline"           batched
summary
