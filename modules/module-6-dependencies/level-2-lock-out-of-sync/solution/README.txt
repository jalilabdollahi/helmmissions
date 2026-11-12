ledger/      the ledger API chart (the release)
ledger-db/   the database chart, consumed from disk. version 0.4.0 added WAL retention settings; ledger now requires it.
CI runs `helm dependency build ./ledger` before every deploy.
