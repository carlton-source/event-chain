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

;; Test: Event names are never empty
(define-public (test-event-name-not-empty (event-id uint))
  (match (get-event event-id)
    event-data
    (begin
      (asserts! (> (len (get name event-data)) u0) (err u1003))
      (ok true))
    (ok true)
  )
)

;; Test: Event locations are never empty
(define-public (test-event-location-not-empty (event-id uint))
  (match (get-event event-id)
    event-data
    (begin
      (asserts! (> (len (get location event-data)) u0) (err u1004))
      (ok true))
    (ok true)
  )
)

;; Test: Total tickets must be at least 1
(define-public (test-total-tickets-positive (event-id uint))
  (match (get-event event-id)
    event-data
    (begin
      (asserts! (> (get total-tickets event-data) u0) (err u1005))
      (ok true))
    (ok true)
  )
)

;; Test: Event price is non-negative (always true for uint, but verify)
(define-public (test-price-non-negative (event-id uint))
  (match (get-event event-id)
    event-data
    (begin
      (asserts! (>= (get price event-data) u0) (err u1006))
      (ok true))
    (ok true)
  )
)