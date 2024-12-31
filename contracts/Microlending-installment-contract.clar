;; Microlending Contract
;; Error codes
(define-constant ERR_LOAN_NOT_FOUND u100)
(define-constant ERR_ACTIVE_LOAN_EXISTS u101)
(define-constant ERR_INVALID_REPAYMENT u102)
(define-constant ERR_NOT_AUTHORIZED u103)
(define-constant ERR_INVALID_AMOUNT u104)

;; Data Variables - using map instead of data-var for proper persistence
(define-map loans 
    principal 
    { balance: uint, 
      repayments: uint, 
      last-repayment-block: uint,
      interest-rate: uint })

(define-map borrowers 
    principal 
    { total-repaid: uint, 
      on-time-repayments: uint,
      credit-score: uint })

;; Settings
(define-constant BLOCKS_PER_PAYMENT u144) ;; Approximately 1 day worth of blocks
(define-constant BASE_INTEREST_RATE u50) ;; 5% represented as 50/1000
(define-constant LATE_PAYMENT_PENALTY u100) ;; 10% penalty
(define-constant MIN_CREDIT_SCORE u500)
(define-constant MAX_CREDIT_SCORE u1000)
(define-constant CREDIT_SCORE_INCREASE u10)
(define-constant CREDIT_SCORE_DECREASE u20)

;; Helper function to get minimum of two uints
(define-private (min-uint (a uint) (b uint))
  (if (<= a b) a b))

;; Helper function to get maximum of two uints
(define-private (max-uint (a uint) (b uint))
  (if (>= a b) a b))

;; Helper function to get borrower's credit score or default
(define-private (get-borrower-credit-score (borrower principal))
  (get credit-score 
       (default-to 
         { total-repaid: u0, 
           on-time-repayments: u0,
           credit-score: MIN_CREDIT_SCORE }
         (map-get? borrowers borrower))))

;; Create a loan for a borrower
(define-public (create-loan (borrower principal) (amount uint))
  (let ((existing-loan (map-get? loans borrower)))
    (begin
      ;; Check valid amount
      (asserts! (> amount u0) (err ERR_INVALID_AMOUNT))
      ;; Ensure the borrower has no active loan
      (asserts! (is-none existing-loan) (err ERR_ACTIVE_LOAN_EXISTS))
      (let ((credit-score (get-borrower-credit-score borrower)))
        (begin
          ;; Create the loan with calculated interest
          (map-insert loans 
                      borrower 
                      { balance: amount,
                        repayments: u0,
                        last-repayment-block: block-height,
                        interest-rate: (calculate-interest-rate credit-score) })
          (ok true))))))

;; Helper function to calculate interest rate based on credit score
(define-private (calculate-interest-rate (credit-score uint))
  (let ((score-factor (/ (* credit-score u1000) MAX_CREDIT_SCORE)))
    (/ (* BASE_INTEREST_RATE u1000) score-factor)))

;; Helper function to calculate new credit score
(define-private (calculate-new-credit-score (current-score uint) (on-time bool))
  (if on-time
      (min-uint (+ current-score CREDIT_SCORE_INCREASE) MAX_CREDIT_SCORE)
      (max-uint (if (>= current-score CREDIT_SCORE_DECREASE)
                    (- current-score CREDIT_SCORE_DECREASE)
                    MIN_CREDIT_SCORE)
                MIN_CREDIT_SCORE)))

;; Repay an active loan
(define-public (repay-loan (amount uint))
  (let ((loan (map-get? loans tx-sender)))
    (begin
      ;; Ensure the borrower has an active loan
      (asserts! (is-some loan) (err ERR_LOAN_NOT_FOUND))
      (let ((loan-data (unwrap-panic loan)))
        (begin
          ;; Ensure repayment amount is valid
          (asserts! (<= amount (get balance loan-data)) (err ERR_INVALID_REPAYMENT))
          ;; Check if payment is on time
          (let ((is-on-time (< (- block-height (get last-repayment-block loan-data)) 
                              BLOCKS_PER_PAYMENT)))
            (begin
              ;; Update loan balance and repayment info
              (map-set loans 
                       tx-sender 
                       { balance: (- (get balance loan-data) amount),
                         repayments: (+ (get repayments loan-data) u1),
                         last-repayment-block: block-height,
                         interest-rate: (get interest-rate loan-data) })
              ;; Update borrower stats
              (let ((borrower-data (default-to 
                                   { total-repaid: u0, 
                                     on-time-repayments: u0,
                                     credit-score: MIN_CREDIT_SCORE }
                                   (map-get? borrowers tx-sender))))
                (map-set borrowers 
                         tx-sender 
                         { total-repaid: (+ (get total-repaid borrower-data) amount),
                           on-time-repayments: (if is-on-time
                                                 (+ (get on-time-repayments borrower-data) u1)
                                                 (get on-time-repayments borrower-data)),
                           credit-score: (calculate-new-credit-score 
                                        (get credit-score borrower-data) 
                                        is-on-time) }))
              (ok true))))))))

;; Check loan balance
(define-read-only (get-loan-balance (borrower principal))
  (let ((loan (map-get? loans borrower)))
    (if (is-some loan)
        (ok (get balance (unwrap-panic loan)))
        (err ERR_LOAN_NOT_FOUND))))

;; Get borrower information
(define-read-only (get-borrower-info (borrower principal))
  (let ((info (map-get? borrowers borrower)))
    (if (is-some info)
        (ok (unwrap-panic info))
        (err ERR_LOAN_NOT_FOUND))))

;; Apply late payment penalty
(define-public (apply-late-penalty (borrower principal))
  (let ((loan (map-get? loans borrower)))
    (begin
      ;; Ensure the loan exists
      (asserts! (is-some loan) (err ERR_LOAN_NOT_FOUND))
      (let ((loan-data (unwrap-panic loan)))
        ;; Check if the repayment is overdue
        (if (> (- block-height (get last-repayment-block loan-data)) 
               BLOCKS_PER_PAYMENT)
            (begin
              ;; Apply penalty
              (map-set loans 
                       borrower 
                       { balance: (+ (get balance loan-data) 
                                   (/ (* (get balance loan-data) LATE_PAYMENT_PENALTY) 
                                      u1000)),
                         repayments: (get repayments loan-data),
                         last-repayment-block: (get last-repayment-block loan-data),
                         interest-rate: (get interest-rate loan-data) })
              (ok true))
            (ok false))))))

;; Close a fully repaid loan
(define-public (close-loan)
  (let ((loan (map-get? loans tx-sender)))
    (begin
      (asserts! (is-some loan) (err ERR_LOAN_NOT_FOUND))
      (let ((loan-data (unwrap-panic loan)))
        (begin
          (asserts! (is-eq (get balance loan-data) u0) (err ERR_INVALID_REPAYMENT))
          (map-delete loans tx-sender)
          (ok true))))))