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