# Microlending Smart Contract

A decentralized microlending platform implemented as a Clarity smart contract for the Stacks blockchain. This contract enables secure, transparent, and automated microlending with credit scoring and incentive mechanisms.

## Features

- **Loan Management**
  - Create and track loans
  - Process repayments
  - Manage loan closure
  - Real-time balance checking

- **Credit System**
  - Dynamic credit scoring
  - Interest rate adjustment based on credit score
  - Reward system for timely payments
  - Penalty system for late payments

- **Borrower Tracking**
  - Track repayment history
  - Monitor on-time payment ratio
  - Calculate credit worthiness
  - Store historical data

## Technical Overview

### Contract Components

1. **Data Maps**
```clarity
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
```

2. **Constants**
```clarity
BLOCKS_PER_PAYMENT: u144    ; ~1 day in blocks
BASE_INTEREST_RATE: u50     ; 5% base rate
LATE_PAYMENT_PENALTY: u100  ; 10% penalty
MIN_CREDIT_SCORE: u500
MAX_CREDIT_SCORE: u1000
```

### Key Functions

#### Creating a Loan
```clarity
(define-public (create-loan (borrower principal) (amount uint))
```
Creates a new loan for a specified borrower with validation checks.

#### Making Repayments
```clarity
(define-public (repay-loan (amount uint))
```
Processes loan repayments and updates borrower statistics.

#### Checking Balances
```clarity
(define-read-only (get-loan-balance (borrower principal))
```
Retrieves current loan balance for any borrower.

## Setup and Deployment

### Prerequisites
- Clarinet installed
- Stacks blockchain environment
- Node.js and NPM (for testing)

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/microlending-contract
cd microlending-contract
```

2. Install dependencies
```bash
npm install
```

3. Run tests
```bash
clarinet test
```

### Deployment

1. Build the contract
```bash
clarinet build
```

2. Deploy using Clarinet console
```bash
clarinet console
```

## Usage Examples

### Creating a New Loan
```clarity
(contract-call? .microlending-contract create-loan tx-sender u1000)
```

### Making a Repayment
```clarity
(contract-call? .microlending-contract repay-loan u100)
```

### Checking Balance
```clarity
(contract-call? .microlending-contract get-loan-balance tx-sender)
```

## Smart Contract Design

### Credit Score Calculation
The credit score is dynamically calculated based on:
- Payment history
- On-time payment ratio
- Total amount repaid
- Length of credit history

### Interest Rate Mechanism
Interest rates are determined by:
- Base rate (5%)
- Credit score multiplier
- Market conditions
- Payment history

## Security Considerations

1. **Access Control**
   - Function-level authorization
   - Principal-based permissions
   - Protected administrative functions

2. **Data Validation**
   - Amount validation
   - Balance checks
   - Status verification

3. **Error Handling**
   - Comprehensive error codes
   - Proper error messages
   - Failed transaction handling

## Testing

Run the test suite:
```bash
clarinet test tests/microlending-test.clar
```

Test coverage includes:
- Loan creation scenarios
- Repayment processing
- Credit score updates
- Interest calculations
- Error conditions

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
