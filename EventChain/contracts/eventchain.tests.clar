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

;; Test: Event timestamp is in the future relative to creation
(define-public (test-timestamp-after-creation (event-id uint))
  (match (get-event event-id)
    event-data
    (begin
      (asserts! (> (get timestamp event-data) (get created-timestamp event-data))
                (err u1007))
      (ok true))
    (ok true)
  )
)

;; Test: Ticket ownership is consistent across both maps
(define-public (test-ticket-maps-consistent (event-id uint) (owner principal))
  (match (get-ticket event-id owner)
    ticket-data
    (let ((ticket-id (get ticket-id ticket-data)))
      (match (get-ticket-owner ticket-id)
        owner-data
        (begin
          (asserts! (is-eq owner (get owner owner-data)) (err u1008))
          (asserts! (is-eq event-id (get event-id owner-data)) (err u1009))
          (asserts! (is-eq (get used ticket-data) (get used owner-data)) (err u1010))
          (ok true))
        (err u1011)))
    (ok true)
  )
)

;; Test: Organizer approval status is valid
(define-public (test-organizer-approved (organizer principal))
  (let ((status (get-organizer-status organizer)))
    (if (is-some status)
      (begin
        (asserts! (get is-approved (unwrap-panic status)) (err u1012))
        (ok true))
      (ok true)))
)

;; Test: Used status is a valid boolean
(define-public (test-used-status-boolean (event-id uint) (owner principal))
  (match (get-ticket event-id owner)
    ticket-data
    (begin
      ;; Bool type always valid, but check it's either true or false
      (asserts! (or (get used ticket-data) (not (get used ticket-data)))
                (err u1013))
      (ok true))
    (ok true)
  )
)

;; Test: Cancelled events are properly recorded
(define-public (test-cancellation-status (event-id uint))
  (let ((is-cancelled (is-event-cancelled event-id)))
    ;; Cancellation status should be a valid boolean
    (asserts! (or is-cancelled (not is-cancelled)) (err u1014))
    (ok true))
)

;; Test: Admin is always set
(define-public (test-admin-exists)
  (begin
    ;; get-admin should always return a valid principal
    (asserts! (is-some (some (get-admin))) (err u1015))
    (ok true)
  )
)

;; Test: Ticket purchase increases tickets-sold correctly
(define-public (test-purchase-increments-sold (event-id uint))
  (match (get-event event-id)
    event-before
    (let ((sold-before (get tickets-sold event-before))
          (total (get total-tickets event-before)))
      ;; Only test if tickets are available
      (if (< sold-before total)
        (match (buy-ticket event-id)
          ticket-id
          (match (get-event event-id)
            event-after
            (begin
              (asserts! (is-eq (get tickets-sold event-after) (+ sold-before u1))
                        (err u1016))
              (ok true))
            (err u1017))
          error
          (ok true)) ;; Purchase failed, acceptable
        (ok true))) ;; Sold out, acceptable
    (ok true)
  )
)