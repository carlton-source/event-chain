;; =============================================================================
;; EventChain Smart Contract - Event Ticketing System
;; =============================================================================

;; =============================================================================
;; ERROR CONSTANTS - Organized by Category
;; =============================================================================

;; 100-199: Ticket Purchase Errors
(define-constant ERR-SOLD-OUT u100)                    ;; Event has no more tickets available
(define-constant ERR-ALREADY-OWNS-TICKET u101)         ;; User already owns a ticket for this event
(define-constant ERR-PAYMENT-FAILED u102)              ;; STX transfer payment failed
(define-constant ERR-EVENT-NOT-FOUND u103)             ;; Event ID does not exist

;; 200-299: Ticket Transfer Errors
(define-constant ERR-TICKET-USED u201)                 ;; Cannot transfer a used ticket
(define-constant ERR-NO-TICKET u202)                   ;; User does not own a ticket for this event
(define-constant ERR-TRANSFER-FAILED u203)             ;; Ticket transfer operation failed
(define-constant ERR-INVALID-RECIPIENT u204)           ;; Cannot transfer ticket to yourself

;; 300-399: Check-in Errors
(define-constant ERR-TICKET-ALREADY-USED u301)         ;; Ticket has already been used for check-in
(define-constant ERR-USER-NO-TICKET u302)              ;; User does not have a ticket for this event
(define-constant ERR-NOT-EVENT-CREATOR u303)           ;; Only event creator can perform check-ins
(define-constant ERR-EVENT-NOT-FOUND-CHECKIN u304)     ;; Event not found during check-in
(define-constant ERR-TICKET-ID-NOT-FOUND u305)         ;; Ticket ID does not exist
(define-constant ERR-TICKET-OWNER-UPDATE-FAILED u306)  ;; Failed to update ticket owner information

;; 400-499: Authorization & Validation Errors
(define-constant ERR-NOT-ADMIN u401)                   ;; Only admin can perform this action
(define-constant ERR-NOT-ORGANIZER u402)              ;; Only approved organizers can create events
(define-constant ERR-INVALID-INPUT u403)               ;; Input field cannot be empty
(define-constant ERR-INVALID-TIMESTAMP u405)          ;; Event timestamp must be in the future
(define-constant ERR-INVALID-TICKET-COUNT u406)       ;; Event must have at least 1 ticket

;; 500-599: Event Management Errors
(define-constant ERR-NOT-EVENT-OWNER u501)            ;; Only event creator can cancel event
(define-constant ERR-EVENT-NOT-FOUND-CANCEL u502)     ;; Event not found during cancellation
(define-constant ERR-NO-REFUND-TICKET u504)           ;; User does not have a ticket to refund
(define-constant ERR-EVENT-NOT-FOUND-REFUND u505)     ;; Event not found during refund
(define-constant ERR-EVENT-NOT-CANCELLED u506)        ;; Event must be cancelled to get refund

;; =============================================================================
;; GLOBAL STATE VARIABLES
;; =============================================================================
(define-data-var next-event-id uint u1)
(define-data-var next-ticket-id uint u1)
(define-data-var admin principal tx-sender)

;; ---- Maps ----
;; Maps to store events and tickets
(define-map events {event-id: uint} {
    creator: principal,
    name: (string-utf8 100),
    location: (string-utf8 100),
    timestamp: uint,
    price: uint,
    total-tickets: uint,
    tickets-sold: uint,
    created-timestamp: uint,
    image: (string-utf8 100)
})

;; ticket mapping (by event-id and owner)
(define-map tickets {event-id: uint, owner: principal} {used: bool, ticket-id: uint})

;;  Reverse mapping from ticket-id to owner address for easy lookup
(define-map ticket-owners {ticket-id: uint} {
    owner: principal,
    event-id: uint,
    used: bool,
    purchase-timestamp: uint
})

(define-map organizers {organizer: principal} {is-approved: bool})
(define-map event-cancelled {event-id: uint} bool)




;; ---- Admin Function ----
(define-public (add-organizer (who principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-ADMIN))
    (map-set organizers {organizer: who} {is-approved: true})
    (ok true))
)


;; =============================================================================
;; EVENT CREATION - Create a new event
;; =============================================================================
;; @desc: Create a new event with specified details (only approved organizers can create events)
;; @param: name - Event name (cannot be empty)
;; @param: location - Event location (cannot be empty) 
;; @param: timestamp - When the event occurs (must be in the future)
;; @param: price - Price per ticket (can be 0 for free events)
;; @param: total-tickets - Total number of tickets available (must be > 0)
;; @param: image - URL/path to event image (optional, can be empty)
;; @returns: (ok event-id) on success, (err error-code) on failure

(define-public (create-event
    (name (string-utf8 100))
    (location (string-utf8 100))
    (timestamp uint)
    (price uint)
    (total-tickets uint)
    (image (string-utf8 100))
  )
  (begin
    ;; Validate organizer authorization first
    (asserts! (is-some (map-get? organizers {organizer: tx-sender})) (err ERR-NOT-ORGANIZER))
    
    ;; Validate all input parameters to prevent untrusted input
    (asserts! (> (len name) u0) (err ERR-INVALID-INPUT))
    (asserts! (> (len location) u0) (err ERR-INVALID-INPUT))
    (asserts! (> timestamp stacks-block-height) (err ERR-INVALID-TIMESTAMP))
    (asserts! (> total-tickets u0) (err ERR-INVALID-TICKET-COUNT))
    ;; NB: price can be 0 for free events, so no validation needed
    
    ;; Create the event record
    (let ((event-id (var-get next-event-id)))
      (map-set events
        (tuple (event-id event-id))
        (tuple
          (creator tx-sender)
          (name name)
          (location location)
          (timestamp timestamp)
          (price price)
          (total-tickets total-tickets)
          (tickets-sold u0)
          (created-timestamp stacks-block-height)
          (image image)))
      
      ;; Increment event counter
      (var-set next-event-id (+ event-id u1))
      
      ;; Return the new event ID
      (ok event-id)
    )
  )
)

;; =============================================================================
;; TICKET PURCHASE - Purchase a ticket for an event
;; =============================================================================
;; @desc: Purchase a ticket for an event, returns unique ticket ID on success
;; @param: event-id - The ID of the event to purchase a ticket for
;; @returns: (ok ticket-id) on success, (err error-code) on failure

(define-public (buy-ticket (event-id uint))
  (match (map-get? events (tuple (event-id event-id)))
    event-data
    (let (
      (ticket-price (get price event-data))
      (tickets-sold (get tickets-sold event-data))
      (total-tickets (get total-tickets event-data))
      (new-ticket-id (var-get next-ticket-id))
      (event-creator (get creator event-data))
    )
      ;; Input validation and business logic checks
      (asserts! (< tickets-sold total-tickets) (err ERR-SOLD-OUT))
      (asserts! (is-none (map-get? tickets (tuple (event-id event-id) (owner tx-sender)))) 
                (err ERR-ALREADY-OWNS-TICKET))
      
      ;; Process payment 
      (try! (stx-transfer? ticket-price tx-sender event-creator))
      
      ;; Create ticket records atomically
      (map-set tickets (tuple (event-id event-id) (owner tx-sender))
        (tuple (used false) (ticket-id new-ticket-id)))
      
      (map-set ticket-owners (tuple (ticket-id new-ticket-id))
        (tuple 
          (owner tx-sender)
          (event-id event-id)
          (used false)
          (purchase-timestamp stacks-block-height)))
      
      ;; Update counters
      (var-set next-ticket-id (+ new-ticket-id u1))
      (map-set events (tuple (event-id event-id))
        (merge event-data (tuple (tickets-sold (+ tickets-sold u1)))))
      
      ;; Return the new ticket ID
      (ok new-ticket-id)
    )
    (err ERR-EVENT-NOT-FOUND)
  )
)


;; =============================================================================
;; TICKET TRANSFER - Transfer a ticket to another user
;; =============================================================================
;; @desc: Transfer ownership of a ticket to another user (ticket must be unused)
;; @param: event-id - The ID of the event 
;; @param: to - The principal address to transfer the ticket to
;; @returns: (ok true) on successful transfer, (err error-code) on failure

(define-public (transfer-ticket (event-id uint) (recipient principal))
  ;; Get ticket data and validate user owns the ticket
  (let ((ticket-data (unwrap! (map-get? tickets (tuple (event-id event-id) (owner tx-sender)))
                               (err ERR-NO-TICKET))))
    
    ;; Extract ticket details
    (let ((ticket-id (get ticket-id ticket-data)))
      
      ;; Validate transfer conditions
      (asserts! (not (get used ticket-data)) (err ERR-TICKET-USED))
      (asserts! (not (is-eq tx-sender recipient)) (err ERR-INVALID-RECIPIENT))
      
      ;; Get ticket owner data for reverse mapping update
      (let ((ticket-owner-data (unwrap! (map-get? ticket-owners {ticket-id: ticket-id})
                                        (err ERR-TRANSFER-FAILED))))
        
        ;; Update primary ticket mapping - transfer ownership
        (map-delete tickets (tuple (event-id event-id) (owner tx-sender)))
        (map-set tickets (tuple (event-id event-id) (owner recipient))
          (tuple (used false) (ticket-id ticket-id)))
        
        ;; Update reverse ticket mapping - change owner
        (map-set ticket-owners (tuple (ticket-id ticket-id))
          (merge ticket-owner-data (tuple (owner recipient))))
        
        ;; Return success
        (ok true)
      )
    )
  )
)