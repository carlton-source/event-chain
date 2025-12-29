;; =============================================================================
;; EventChain Rendezvous Fuzz Tests
;; =============================================================================


;; =============================================================================
;; PROPERTY-BASED TESTS
;; =============================================================================
;; These test properties that should always hold true for any valid input

;; Test: Tickets sold never exceeds total tickets
(define-public (test-tickets-sold-within-limit (event-id uint))
  (match (get-event event-id)
    event-data
    (begin
      (asserts! (<= (get tickets-sold event-data) (get total-tickets event-data))
                (err u1000))
      (ok true))
    (ok true) ;; Event doesn't exist, test passes
  )
)

;; Test: Event IDs are monotonically increasing
(define-public (test-event-id-sequential (event-id uint))
  (begin
    (if (is-some (get-event event-id))
      (asserts! (< event-id (get-next-event-id)) (err u1001))
      true)
    (ok true)
  )
)

;; Test: Ticket IDs are monotonically increasing
(define-public (test-ticket-id-sequential (ticket-id uint))
  (begin
    (if (is-some (get-ticket-owner ticket-id))
      (asserts! (< ticket-id (get-next-ticket-id)) (err u1002))
      true)
    (ok true)
  )
)