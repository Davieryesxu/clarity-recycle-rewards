;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101)) 
(define-constant err-invalid-amount (err u102))
(define-constant err-invalid-tier (err u103))
(define-constant err-unauthorized-transfer (err u104))
(define-constant err-self-award (err u105))
(define-constant err-max-supply (err u106))
(define-constant max-supply u1000000000) ;; 1 billion tokens

;; Define recycling token
(define-fungible-token recycle-token)

;; Define data variables 
(define-map recycling-centers principal bool)
(define-map user-rewards principal uint)
(define-map user-tiers principal uint)
(define-map tier-multipliers uint uint)
(define-data-var total-supply uint u0)

;; Define private functions
(define-private (is-recycling-center (center principal))
    (default-to false (map-get? recycling-centers center))
)

(define-private (get-tier-multiplier (tier uint))
    (asserts! (and (> tier u0) (<= tier u4)) err-invalid-tier)
    (default-to u100 (map-get? tier-multipliers tier))
)

(define-private (increase-supply (amount uint))
    (let ((new-supply (+ (var-get total-supply) amount)))
        (asserts! (<= new-supply max-supply) err-max-supply)
        (var-set total-supply new-supply)
    )
)

;; Initialize tier multipliers
(begin
    (map-set tier-multipliers u1 u100) ;; Base tier: 1x
    (map-set tier-multipliers u2 u125) ;; Silver tier: 1.25x
    (map-set tier-multipliers u3 u150) ;; Gold tier: 1.5x
    (map-set tier-multipliers u4 u200) ;; Platinum tier: 2x
)

;; Public functions

(define-public (add-recycling-center (center principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (print {event: "center-added", center: center})
        (ok (map-set recycling-centers center true))
    )
)

(define-public (remove-recycling-center (center principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (print {event: "center-removed", center: center})
        (ok (map-delete recycling-centers center))
    )
)

(define-public (set-user-tier (user principal) (tier uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (and (> tier u0) (<= tier u4)) err-invalid-tier)
        (print {event: "tier-changed", user: user, tier: tier})
        (ok (map-set user-tiers user tier))
    )
)

(define-public (award-tokens (recycler principal) (base-amount uint))
    (begin
        (asserts! (is-recycling-center tx-sender) err-not-authorized)
        (asserts! (> base-amount u0) err-invalid-amount)
        (asserts! (not (is-eq recycler tx-sender)) err-self-award)
        (let (
            (user-tier (default-to u1 (map-get? user-tiers recycler)))
            (multiplier (get-tier-multiplier user-tier))
            (final-amount (/ (* base-amount multiplier) u100))
        )
            (try! (ft-mint? recycle-token final-amount recycler))
            (increase-supply final-amount)
            (map-set user-rewards recycler 
                (+ (default-to u0 (map-get? user-rewards recycler)) final-amount)
            )
            (print {event: "tokens-awarded", recipient: recycler, amount: final-amount})
            (ok true)
        )
    )
)

(define-public (transfer (amount uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) err-unauthorized-transfer)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (not (is-eq recipient sender)) err-invalid-amount)
        (try! (ft-transfer? recycle-token amount sender recipient))
        (print {event: "tokens-transferred", sender: sender, recipient: recipient, amount: amount})
        (ok true)
    )
)

;; Read only functions remain unchanged...
