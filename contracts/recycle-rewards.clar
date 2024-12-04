;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-amount (err u102))

;; Define recycling token
(define-fungible-token recycle-token)

;; Define data variables
(define-map recycling-centers principal bool)
(define-map user-rewards principal uint)

;; Define private functions
(define-private (is-recycling-center (center principal))
    (default-to false (map-get? recycling-centers center))
)

;; Public functions

;; Add recycling center - only contract owner can add centers
(define-public (add-recycling-center (center principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set recycling-centers center true))
    )
)

;; Remove recycling center
(define-public (remove-recycling-center (center principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-delete recycling-centers center))
    )
)

;; Award tokens to recyclers
(define-public (award-tokens (recycler principal) (amount uint))
    (begin
        (asserts! (is-recycling-center tx-sender) err-not-authorized)
        (asserts! (> amount u0) err-invalid-amount)
        (try! (ft-mint? recycle-token amount recycler))
        (map-set user-rewards recycler 
            (+ (default-to u0 (map-get? user-rewards recycler)) amount)
        )
        (ok true)
    )
)

;; Transfer tokens
(define-public (transfer (amount uint) (sender principal) (recipient principal))
    (begin
        (asserts! (> amount u0) err-invalid-amount)
        (try! (ft-transfer? recycle-token amount sender recipient))
        (ok true)
    )
)

;; Read only functions

;; Get user rewards balance
(define-read-only (get-rewards-balance (user principal))
    (ok (default-to u0 (map-get? user-rewards user)))
)

;; Check if address is recycling center
(define-read-only (is-valid-center (center principal))
    (ok (is-recycling-center center))
)

;; Get token balance
(define-read-only (get-token-balance (account principal))
    (ok (ft-get-balance recycle-token account))
)
