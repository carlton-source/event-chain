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