<?php
// Anket süreleri: create_poll, get_active_poll ve cleanup_polls ortak kullanır.
// Anketin açık olup olmadığı polls.ends_at'ten anlaşılır (erken bitirilince şimdi olur).

// Süre gönderilmezse (1.2.0 ve öncesi) anket 24 saat açık kalır
const POLL_DEFAULT_HOURS = 24;
const POLL_MAX_HOURS = 24 * 7;
// Biten anket sonuçlarıyla bu kadar süre daha görünür, sonra cron siler
const POLL_RESULT_HOURS = 24;
