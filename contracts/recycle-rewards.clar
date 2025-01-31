;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101)) 
(define-constant err-invalid-amount (err u102))
(define-constant err-invalid-tier (err u103))

;; Define recycling token
(define-fungible-token recycle-token)

;; Define data variables 
(define-map recycling-centers principal bool)
(define-map user-rewards principal uint)
(define-map user-tiers principal uint) ;; New: Track user tiers
(define-map tier-multipliers uint uint) ;; New: Tier reward multipliers

;; Define private functions
(define-private (is-recycling-center (center principal))
    (default-to false (map-get? recycling-centers center))
)

(define-private (get-tier-multiplier (tier uint))
    (default-to u100 (map-get? tier-multipliers tier))
)

;; Initialize tier multipliers
(begin
    (map-set tier-multipliers u1 u100) ;; Base tier: 1x
    (map-set tier-multipliers u2 u125) ;; Silver tier: 1.25x
    (map-set tier-multipliers u3 u150) ;; Gold tier: 1.5x
    (map-set tier-multipliers u4 u200) ;; Platinum tier: 2x
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

;; Set user tier - only contract owner can set tiers
(define-public (set-user-tier (user principal) (tier uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= tier u4) err-invalid-tier)
        (ok (map-set user-tiers user tier))
    )
)

;; Award tokens to recyclers with tier multiplier
(define-public (award-tokens (recycler principal) (base-amount uint))
    (begin
        (asserts! (is-recycling-center tx-sender) err-not-authorized)
        (asserts! (> base-amount u0) err-invalid-amount)
        (let (
            (user-tier (default-to u1 (map-get? user-tiers recycler)))
            (multiplier (get-tier-multiplier user-tier))
            (final-amount (/ (* base-amount multiplier) u100))
        )
            (try! (ft-mint? recycle-token final-amount recycler))
            (map-set user-rewards recycler 
                (+ (default-to u0 (map-get? user-rewards recycler)) final-amount)
            )
            (ok true)
        )
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

;; Get user tier
(define-read-only (get-user-tier (user principal))
    (ok (default-to u1 (map-get? user-tiers user)))
)

;; Get tier multiplier
(define-read-only (get-tier-multiplier-info (tier uint))
    (ok (get-tier-multiplier tier))
)
