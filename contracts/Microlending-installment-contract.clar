;; Microlending Contract - Initial Setup
;; Error codes
(define-constant ERR_LOAN_NOT_FOUND u100)
(define-constant ERR_ACTIVE_LOAN_EXISTS u101)
(define-constant ERR_INVALID_AMOUNT u102)

;; Data Variables
(define-map loans 
    principal 
    { balance: uint, 
      repayments: uint, 
      last-repayment-block: uint })

;; Create a loan for a borrower
(define-public (create-loan (borrower principal) (amount uint))
  (let ((existing-loan (map-get? loans borrower)))
    (begin
      (asserts! (> amount u0) (err ERR_INVALID_AMOUNT))
      (asserts! (is-none existing-loan) (err ERR_ACTIVE_LOAN_EXISTS))
      (map-insert loans 
                  borrower 
                  { balance: amount,
                    repayments: u0,
                    last-repayment-block: block-height })
      (ok true))))

;; Check loan balance
(define-read-only (get-loan-balance (borrower principal))
  (let ((loan (map-get? loans borrower)))
    (if (is-some loan)
        (ok (get balance (unwrap-panic loan)))
        (err ERR_LOAN_NOT_FOUND))))

;; Microlending Contract - Basic Loan Management
;; Error codes
(define-constant ERR_LOAN_NOT_FOUND u100)
(define-constant ERR_ACTIVE_LOAN_EXISTS u101)
(define-constant ERR_INVALID_REPAYMENT u102)
(define-constant ERR_INVALID_AMOUNT u103)

;; Data Variables
(define-map loans 
    principal 
    { balance: uint, 
      repayments: uint, 
      last-repayment-block: uint })

;; Settings
(define-constant BLOCKS_PER_PAYMENT u144) ;; Approximately 1 day worth of blocks

;; Create a loan for a borrower
(define-public (create-loan (borrower principal) (amount uint))
  (let ((existing-loan (map-get? loans borrower)))
    (begin
      (asserts! (> amount u0) (err ERR_INVALID_AMOUNT))
      (asserts! (is-none existing-loan) (err ERR_ACTIVE_LOAN_EXISTS))
      (map-insert loans 
                  borrower 
                  { balance: amount,
                    repayments: u0,
                    last-repayment-block: block-height })
      (ok true))))

;; Repay an active loan
(define-public (repay-loan (amount uint))
  (let ((loan (map-get? loans tx-sender)))
    (begin
      (asserts! (is-some loan) (err ERR_LOAN_NOT_FOUND))
      (let ((loan-data (unwrap-panic loan)))
        (begin
          (asserts! (<= amount (get balance loan-data)) (err ERR_INVALID_REPAYMENT))
          (map-set loans 
                   tx-sender 
                   { balance: (- (get balance loan-data) amount),
                     repayments: (+ (get repayments loan-data) u1),
                     last-repayment-block: block-height })
          (ok true))))))

;; Check loan balance
(define-read-only (get-loan-balance (borrower principal))
  (let ((loan (map-get? loans borrower)))
    (if (is-some loan)
        (ok (get balance (unwrap-panic loan)))
        (err ERR_LOAN_NOT_FOUND))))

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

